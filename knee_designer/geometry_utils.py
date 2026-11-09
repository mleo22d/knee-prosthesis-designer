import numpy as np


def wrap_to_pi(ang: np.ndarray) -> np.ndarray:
    ang = np.asarray(ang, float)
    return (ang + np.pi) % (2.0 * np.pi) - np.pi

def fourbar_icr_trajectory(
    a: float,
    b: float,
    c: float,
    d: float,
    A: np.ndarray,
    phiAD: float,
    kappa0: float,
    K: np.ndarray,
):
    """
    Calcula la trayectoria del ICR para un mecanismo de 4 barras
    definido por (a,b,c,d, A, phiAD, kappa0) a lo largo de
    los ángulos de flexión de rodilla K (en radianes).

    Parameters
    ----------
    a,b,c,d : float
        Longitudes de las barras AB, BC, CD, DA (mm).
    A : (2,) array
        Coordenadas del pivote A [Ax, Ay] (mm).
    phiAD : float
        Ángulo de la barra AD respecto al eje X (rad).
    kappa0 : float
        Offset inicial (rad) tal que θ3 = phiAD + kappa0 + K.
    K : (N,) array
        Flexión de rodilla (rad) para cada pose.

    Returns
    -------
    xf, yf : (N,) arrays
        Coordenadas del ICR ajustado en cada pose.
    geom : dict
        Geometría útil (A, B_all, C_all, D, phiAD, kappa0).
    """
    A = np.asarray(A, float).ravel()
    K = np.asarray(K, float)
    N = K.size

    xf = np.full(N, np.nan, dtype=float)
    yf = np.full(N, np.nan, dtype=float)
    B_all = np.full((N, 2), np.nan, dtype=float)
    C_all = np.full((N, 2), np.nan, dtype=float)

    uAD = np.array([np.cos(phiAD), np.sin(phiAD)])
    D = A + d * uAD

    th2_prev = None

    for i in range(N):
        th3 = phiAD + kappa0 + K[i]
        u3 = np.array([np.cos(th3), np.sin(th3)])

        # Misma cinemática que en residual_vec_raw
        S = (D - A) - b * u3
        rS = np.linalg.norm(S)
        if rS < 1e-12:
            continue  # se queda como NaN

        alpha = np.arctan2(S[1], S[0])
        cosDel = (a**2 + rS**2 - c**2) / (2.0 * a * rS)
        if abs(cosDel) > 1.0:
            continue

        delta = np.arccos(np.clip(cosDel, -1.0, 1.0))
        th2c = np.array([alpha + delta, alpha - delta])

        # Selección de rama continua
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
            continue

        xf[i], yf[i] = P
        B_all[i, :] = B
        C_all[i, :] = C

    geom = {
        "A": A,
        "B": B_all,
        "C": C_all,
        "D": D,
        "phiAD": phiAD,
        "kappa0": kappa0,
    }
    return xf, yf, geom

def compute_ABCD_from_parameters(params, knee_flex_deg: float = 0.0,
                                 translate_to_C: bool = False):
    a = params.lengths["AB"]
    b = params.lengths["BC"]
    c = params.lengths["CD"]
    d = params.lengths["DA"]

    phiAD = float(params.phiAD)
    kappa0 = float(params.kappa0)
    A = np.array(params.A, dtype=float)

    K = np.array([np.deg2rad(knee_flex_deg)], dtype=float)

    _, _, geom = fourbar_icr_trajectory(
        a=a, b=b, c=c, d=d,
        A=A, phiAD=phiAD, kappa0=kappa0, K=K,
    )

    A0 = np.asarray(geom["A"], float)       # (2,)
    B0 = np.asarray(geom["B"], float)[-1]   # (2,)
    C0 = np.asarray(geom["C"], float)[-1]   # (2,)
    D0 = np.asarray(geom["D"], float)       # (2,)

    if translate_to_C:
        T = -C0
        A0 = A0 + T
        B0 = B0 + T
        C0 = np.array([0.0, 0.0])
        D0 = D0 + T

    R0 = (A0 + B0) / 2.0
    return A0, B0, C0, D0, R0
