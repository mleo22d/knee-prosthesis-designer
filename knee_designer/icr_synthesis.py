from dataclasses import dataclass
from typing import Dict, Tuple, Optional
import numpy as np

# ---------------------------------------------------------------------
# Dataclass de salida: pivotes + parámetros importantes
# ---------------------------------------------------------------------
@dataclass
class Pivots:
    A: np.ndarray
    B: np.ndarray
    C: np.ndarray
    D: np.ndarray
    lengths: Dict[str, float]
    phiAD: float
    kappa0: float

# ---------------------------------------------------------------------
# Función principal: ICR deseado -> Pivots
# ---------------------------------------------------------------------
def icr_to_pivots(
    Pdes: np.ndarray,
    K: Optional[np.ndarray] = None,
    w_user: Optional[np.ndarray] = None,
    opts: Optional[dict] = None
) -> Tuple[Pivots, dict]:
    """
    Ajusta un mecanismo de 4 barras a una trayectoria de ICR deseada.

    Parameters
    ----------
    Pdes : (N,2) ndarray
        Puntos (x,y) del ICR deseado en mm.
    K : (N,) ndarray, optional
        Flexión de rodilla en radianes asociada a cada punto.
        Si es None, se asume 0–90° linealmente.
    w_user : (N,) ndarray, optional
        Pesos del usuario. Si es None, todos 1.
    opts : dict, optional
        Opciones del ajuste (límites, num_starts, etc.).

    Returns
    -------
    pivots : Pivots
        Geometría de la 4 barras ajustada.
    info : dict
        Info del ajuste (p_opt, error, iteraciones).
    """
    Pdes = np.asarray(Pdes, dtype=float)
    assert Pdes.ndim == 2 and Pdes.shape[1] == 2, "Pdes debe ser (N,2)"
    N = Pdes.shape[0]

    # Si no te dan K, asumimos 0–90° repartido
    if K is None:
        Kdeg = np.linspace(0.0, 90.0, N)
        K = np.deg2rad(Kdeg)
    else:
        K = np.asarray(K, dtype=float)
        assert K.shape == (N,), "K debe tener dimensión (N,)"

    # Pesos de usuario
    if w_user is None:
        w_user = np.ones(N, dtype=float)
    else:
        w_user = np.asarray(w_user, dtype=float)
        assert w_user.shape == (N,), "w_user debe tener dimensión (N,)"

    # ---------------- Opciones por defecto (basadas en tu script) ---------
    if opts is None:
        opts = {}
    num_starts   = opts.get("num_starts", 10)
    maxIt        = opts.get("maxIt", 10)
    mu0          = opts.get("mu0", 1e-3)
    huber_delta  = opts.get("huber_delta", 150.0)
    line_search  = opts.get("line_search", True)
    LMINv        = np.array(opts.get("LMINv", [30, 20, 45, 25]), dtype=float)
    LMAXv        = np.array(opts.get("LMAXv", [35, 25, 55, 35]), dtype=float)
    kappa0_min   = float(opts.get("kappa0_min", np.deg2rad(25)))
    kappa0_max   = float(opts.get("kappa0_max", np.deg2rad(45)))
    padA         = float(opts.get("padA", 100.0))
    phiAD_min    = float(opts.get("phiAD_min", np.deg2rad(-15)))
    phiAD_max    = float(opts.get("phiAD_max", np.deg2rad(-5)))

    # Semilla p0 (igual que tu script por ahora)
    A0 = np.array([40.0, -20.0])
    kappa0_0 = np.deg2rad(35.07)
    p0 = np.array([
        32.9, 22.5, 49.1, 29.7,          # a b c d
        np.deg2rad(-7.95),               # phiAD
        kappa0_0,                        # kappa0
        A0[0], A0[1]                     # Ax Ay
    ])

    # Caja donde puede moverse A
    pad = padA
    boxA = np.array([
        Pdes[:, 0].min() - pad,
        Pdes[:, 0].max() + pad,
        Pdes[:, 1].min() - pad,
        Pdes[:, 1].max() + pad,
    ])

    # --------- Multistart IRLS + LM (traducción directa de MATLAB) -------
    p_best, best = fit_fourbar_icr_ms(
        Pdes, K, p0,
        num_starts=num_starts,
        maxIt=maxIt,
        mu0=mu0,
        huber_delta=huber_delta,
        line_search=line_search,
        LMINv=LMINv,
        LMAXv=LMAXv,
        kappa0_min=kappa0_min,
        kappa0_max=kappa0_max,
        boxA=boxA,
        phiAD_min=phiAD_min,
        phiAD_max=phiAD_max,
        w_user=w_user,
    )

    # ---------------- Construir Pivots a partir de p_best -----------------
    a, b, c, d, phiAD, kappa0, Ax, Ay = p_best
    A = np.array([Ax, Ay])
    uAD = np.array([np.cos(phiAD), np.sin(phiAD)])
    D = A + d * uAD

    # Pose inicial para B y C (primer K)
    th3_0 = phiAD + kappa0 + K[0]
    B, C = compute_BC_from_geometry(a, b, c, d, A, D, th3_0)

    lengths = {
        "AB": float(np.linalg.norm(B - A)),
        "BC": float(np.linalg.norm(C - B)),
        "CD": float(np.linalg.norm(D - C)),
        "DA": float(np.linalg.norm(A - D)),
    }

    pivots = Pivots(
        A=A, B=B, C=C, D=D,
        lengths=lengths,
        phiAD=phiAD,
        kappa0=kappa0
    )

    info = {
        "p_opt": p_best,
        "best_residual_norm": best["rn"],
        "iterations": best["it"],
    }
    return pivots, info

# ---------------------------------------------------------------------
#  Multistart
# ---------------------------------------------------------------------
def fit_fourbar_icr_ms(
    Pdes: np.ndarray,
    K: np.ndarray,
    p0: np.ndarray,
    *,
    num_starts: int,
    maxIt: int,
    mu0: float,
    huber_delta: float,
    line_search: bool,
    LMINv: np.ndarray,
    LMAXv: np.ndarray,
    kappa0_min: float,
    kappa0_max: float,
    boxA: np.ndarray,
    phiAD_min: float,
    phiAD_max: float,
    w_user: np.ndarray
):
    best_rn = np.inf
    best_it = 0
    p_best = p0.copy()

    for s in range(num_starts):
        if s == 0:
            p_init = p0.copy()
        else:
            p_init = p0.copy()
            # Semillas aleatorias
            p_init[0:4] = LMINv + (LMAXv - LMINv) * np.random.rand(4)
            p_init[4] = phiAD_min + (phiAD_max - phiAD_min) * np.random.rand()
            # kappa0 perturbado
            perturb = np.deg2rad(15.0) * (2.0 * np.random.rand() - 1.0)
            p_init[5] = np.clip(p0[5] + perturb, kappa0_min, kappa0_max)
            # A perturbado
            p_init[6:8] = p0[6:8] + 40.0 * (2.0 * np.random.rand(2) - 1.0)

        p_init = project_bounds(p_init, LMINv, LMAXv,
                                kappa0_min, kappa0_max,
                                boxA, phiAD_min, phiAD_max)

        p_loc, hist = fit_fourbar_icr(
            Pdes, K, p_init,
            maxIt=maxIt,
            mu0=mu0,
            huber_delta=huber_delta,
            line_search=line_search,
            LMINv=LMINv,
            LMAXv=LMAXv,
            kappa0_min=kappa0_min,
            kappa0_max=kappa0_max,
            boxA=boxA,
            phiAD_min=phiAD_min,
            phiAD_max=phiAD_max,
            w_user=w_user
        )

        if hist["rn"] < best_rn:
            best_rn = hist["rn"]
            best_it = hist["it"]
            p_best = p_loc

    best = {"rn": best_rn, "it": best_it}
    return p_best, best

# ---------------------------------------------------------------------
#  LM + IRLS (Huber)
# ---------------------------------------------------------------------
def fit_fourbar_icr(
    Pdes: np.ndarray,
    K: np.ndarray,
    p0: np.ndarray,
    *,
    maxIt: int,
    mu0: float,
    huber_delta: float,
    line_search: bool,
    LMINv: np.ndarray,
    LMAXv: np.ndarray,
    kappa0_min: float,
    kappa0_max: float,
    boxA: np.ndarray,
    phiAD_min: float,
    phiAD_max: float,
    w_user: np.ndarray
):
    Pdes = np.asarray(Pdes, float)
    K = np.asarray(K, float)

    dx = Pdes[:, 0].max() - Pdes[:, 0].min()
    dy = Pdes[:, 1].max() - Pdes[:, 1].min()
    scaleXY = max(dx, dy) or 1.0

    p = p0.copy()
    mu = mu0

    p = project_bounds(p, LMINv, LMAXv, kappa0_min, kappa0_max,
                       boxA, phiAD_min, phiAD_max)

    best_p = p.copy()
    best_rn = np.inf
    best_it = 0

    for it in range(1, maxIt + 1):
        e = residual_vec_raw(p, K, Pdes)
        w_sqrt, r = weight_and_residual(e, scaleXY, huber_delta, w_user)

        funW = lambda pp: weight_vec(w_sqrt) * residual_vec_raw(pp, K, Pdes) / scaleXY
        J = fd_jacobian(funW, p)

        H = J.T @ J + mu * np.eye(len(p))
        g = J.T @ r
        dp_full = -np.linalg.solve(H, g)

        improved = False
        alpha_used = 1.0

        if line_search:
            for alpha in [1.0, 0.5, 0.25, 0.1, 0.05, 0.02]:
                p_try = project_bounds(
                    p + alpha * dp_full,
                    LMINv, LMAXv,
                    kappa0_min, kappa0_max, boxA,
                    phiAD_min, phiAD_max
                )
                e_try = residual_vec_raw(p_try, K, Pdes)
                _, r_try = weight_and_residual(e_try, scaleXY, huber_delta, w_user)

                if np.linalg.norm(r_try) < np.linalg.norm(r):
                    p = p_try
                    mu = max(mu / 3.0, 1e-9)
                    improved = True
                    alpha_used = alpha
                    if np.linalg.norm(r_try) < best_rn:
                        best_p = p.copy()
                        best_rn = float(np.linalg.norm(r_try))
                        best_it = it
                    break
            if not improved:
                mu *= 3.0
        else:
            p_try = project_bounds(
                p + dp_full,
                LMINv, LMAXv,
                kappa0_min, kappa0_max, boxA,
                phiAD_min, phiAD_max
            )
            e_try = residual_vec_raw(p_try, K, Pdes)
            _, r_try = weight_and_residual(e_try, scaleXY, huber_delta, w_user)
            if np.linalg.norm(r_try) < np.linalg.norm(r):
                p = p_try
                mu = max(mu / 3.0, 1e-9)
                improved = True
                if np.linalg.norm(r_try) < best_rn:
                    best_p = p.copy()
                    best_rn = float(np.linalg.norm(r_try))
                    best_it = it
            else:
                mu *= 3.0

        if np.linalg.norm(alpha_used * dp_full) < 1e-8 * (1.0 + np.linalg.norm(p)):
            break

    hist = {"p": best_p, "rn": best_rn, "it": best_it}
    return best_p, hist

# ---------------------------------------------------------------------
#  Pesos Huber + usuario
# ---------------------------------------------------------------------
def weight_and_residual(
    e: np.ndarray,
    scaleXY: float,
    huber_delta_mm: float,
    w_user: np.ndarray
):
    e = np.asarray(e, float)
    N2 = e.size
    assert N2 % 2 == 0
    N = N2 // 2
    E = e.reshape(N, 2)
    d = np.linalg.norm(E, axis=1)
    delta = huber_delta_mm

    w_h = np.ones(N, dtype=float)
    big = d > delta
    w_h[big] = delta / d[big]

    w_tot = w_h * w_user
    w_tot /= w_tot.mean()

    w_sqrt = np.sqrt(w_tot)
    Ew = E * w_sqrt[:, None]
    r = Ew.ravel() / scaleXY
    return w_sqrt, r

def weight_vec(w_sqrt: np.ndarray) -> np.ndarray:
    return np.repeat(np.asarray(w_sqrt, float), 2)

# ---------------------------------------------------------------------
#  Residuales cinemáticos (p -> ICR vs Pdes)
# ---------------------------------------------------------------------
def residual_vec_raw(
    p: np.ndarray,
    K: np.ndarray,
    Pdes: np.ndarray
) -> np.ndarray:
    a, b, c, d, phiAD, kappa0, Ax, Ay = p
    A = np.array([Ax, Ay])
    N = K.size
    r = np.zeros(2 * N, dtype=float)

    uAD = np.array([np.cos(phiAD), np.sin(phiAD)])
    D = A + d * uAD
    th2_prev = None

    for i in range(N):
        th3 = phiAD + kappa0 + K[i]
        u3 = np.array([np.cos(th3), np.sin(th3)])
        S = (D - A) - b * u3
        rS = np.linalg.norm(S)

        if rS < 1e-12:
            P = np.array([1e6, 1e6])
        else:
            alpha = np.arctan2(S[1], S[0])
            cosDel = (a**2 + rS**2 - c**2) / (2.0 * a * rS)
            if abs(cosDel) > 1.0:
                P = np.array([1e4, 1e4])
            else:
                delta = np.arccos(np.clip(cosDel, -1.0, 1.0))
                th2c = np.array([alpha + delta, alpha - delta])

                if i > 0 and th2_prev is not None:
                    diff = wrap_to_pi(th2c - th2_prev)
                    ix = np.argmin(np.abs(diff))
                else:
                    ix = 0

                th2 = th2c[ix]
                th2_prev = th2

                B = A + a * np.array([np.cos(th2), np.sin(th2)])
                C = B + b * u3
                r2 = B - A
                r4 = C - D
                M = np.column_stack([r2, -r4])
                rhs = (D - A)
                try:
                    ts = np.linalg.lstsq(M, rhs, rcond=None)[0]
                    P = A + ts[0] * r2
                except np.linalg.LinAlgError:
                    P = np.array([1e5, 1e5])

        r[2 * i:2 * i + 2] = P - Pdes[i, :]
    return r

# ---------------------------------------------------------------------
#  Jacobiano por diferencias finitas
# ---------------------------------------------------------------------
def fd_jacobian(fun, p: np.ndarray) -> np.ndarray:
    p = np.asarray(p, float)
    r0 = fun(p)
    m = r0.size
    n = p.size
    J = np.zeros((m, n), dtype=float)

    for j in range(n):
        pj = p.copy()
        epsj = 1e-6 * max(1.0, abs(pj[j]))
        pj[j] += epsj
        J[:, j] = (fun(pj) - r0) / epsj
    return J

# ---------------------------------------------------------------------
#  Proyección en límites
# ---------------------------------------------------------------------
def project_bounds(
    p: np.ndarray,
    LMINv: np.ndarray,
    LMAXv: np.ndarray,
    K0MIN: float,
    K0MAX: float,
    boxA: np.ndarray,
    phiAD_min: float,
    phiAD_max: float
) -> np.ndarray:
    p = np.asarray(p, float)
    LMINv = np.asarray(LMINv, float).ravel()
    LMAXv = np.asarray(LMAXv, float).ravel()
    if LMINv.size == 1:
        LMINv = np.repeat(LMINv, 4)
    if LMAXv.size == 1:
        LMAXv = np.repeat(LMAXv, 4)

    p[0:4] = np.clip(p[0:4], LMINv, LMAXv)

    phi = np.arctan2(np.sin(p[4]), np.cos(p[4]))
    p[4] = np.clip(phi, phiAD_min, phiAD_max)

    p[5] = np.clip(p[5], K0MIN, K0MAX)
    p[6] = np.clip(p[6], boxA[0], boxA[1])
    p[7] = np.clip(p[7], boxA[2], boxA[3])
    return p

def wrap_to_pi(ang: np.ndarray) -> np.ndarray:
    ang = np.asarray(ang, float)
    return (ang + np.pi) % (2.0 * np.pi) - np.pi

# ---------------------------------------------------------------------
#  Para construir B y C a partir de la geometría + th3
# ---------------------------------------------------------------------
def compute_BC_from_geometry(
    a: float, b: float, c: float, d: float,
    A: np.ndarray, D: np.ndarray,
    th3: float
):
    u3 = np.array([np.cos(th3), np.sin(th3)])
    S = (D - A) - b * u3
    rS = np.linalg.norm(S)
    if rS < 1e-12:
        return A.copy(), D.copy()
    alpha = np.arctan2(S[1], S[0])
    cosDel = (a**2 + rS**2 - c**2) / (2.0 * a * rS)
    if abs(cosDel) > 1.0:
        return A.copy(), D.copy()
    delta = np.arccos(np.clip(cosDel, -1.0, 1.0))
    th2 = alpha + delta     # escogemos una rama
    B = A + a * np.array([np.cos(th2), np.sin(th2)])
    C = B + b * u3
    return B, C

