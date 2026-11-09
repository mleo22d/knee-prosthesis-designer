import numpy as np
from .geometry_utils import compute_ABCD_from_parameters

# ---------------- utilidades geométricas ---------------- #

def vertical(p1, p2):
    """
    Distancia vertical entre p1 y p2 (en metros).
    p1, p2: array-like [x_mm, y_mm]
    """
    p1 = np.asarray(p1, dtype=float)
    p2 = np.asarray(p2, dtype=float)
    return -(p2[1] - p1[1]) / 1000.0


def horizontal(p1, p2):
    """
    Distancia horizontal entre p1 y p2 (en metros).
    p1, p2: array-like [x_mm, y_mm]
    """
    p1 = np.asarray(p1, dtype=float)
    p2 = np.asarray(p2, dtype=float)
    return (p2[0] - p1[0]) / 1000.0


# ------------- cálculo de reacciones -------------------- #

def compute_reactions_from_icr_parameters(params, bottom, top, EKJC, F):
    """
    Entrada:
        params = salida de icr_synthesis (objeto Pivots)
        bottom, top = puntos de aplicación de la fuerza ISO (en mm)
        F = fuerza ISO
    
    Salida:
        reacciones, momento en C
    """

    # 1. Obtener geometría base desde los parámetros
    A, B, C, D, R = compute_ABCD_from_parameters(params, translate_to_C=True)

    # obtener la rodilla anatómica

    A_t = EKJC + A
    B_t = EKJC + B
    C_t = EKJC + C  # igual que MATLAB
    D_t = EKJC + D

    R = (A_t + B_t) / 2.0
    # 2. Calcular reacciones ISO
    reac, moment_C = compute_iso10328_reactions(
        A_t, B_t, C_t, D_t, R,
        bottom=np.array(bottom),
        top=np.array(top),
        F=F
    )

    return reac, moment_C

def compute_iso10328_reactions(A, B, C, D, R, bottom, top, F):
    """
    Calcula las reacciones Ax, Ay, Bx, By, Cx, Cy, Dx, Dy y Rx
    para la configuración ISO 10328.

    A,B,C,D,R,bottom,top : [x_mm, y_mm]
    F : valor de la fuerza axial [N]

    Devuelve:
        reac : np.ndarray de tamaño (9,)
               [Ax, Ay, Bx, By, Cx, Cy, Dx, Dy, Rx]
        moment_C : chequeo del equilibrio de momentos en C
    """
    A = np.asarray(A, float)
    B = np.asarray(B, float)
    C = np.asarray(C, float)
    D = np.asarray(D, float)
    R = np.asarray(R, float)
    bottom = np.asarray(bottom, float)
    top = np.asarray(top, float)

    # Fuerza ISO a lo largo de la línea bottom–top
    direction = top - bottom
    u = direction / np.linalg.norm(direction)
    F_bottom = F * u
    F_top = -F * u

    # Ángulo de la barra AB (para descomponer Rx)
    theta2 = np.arctan(abs(B[1] - A[1]) / abs(B[0] - A[0]))

    # --- Momentos cuerpo 1 (entre A y D, cargado en bottom) ---
    ADy = vertical(A, D)
    ADx = horizontal(A, D)
    eq1_3 = np.array([ADy, ADx])

    AOy = vertical(A, bottom)
    AOx = horizontal(A, bottom)
    ctte1_3 = F_bottom[0] * AOy + F_bottom[1] * AOx

    # --- Momentos cuerpo 2 (entre A, B y R) ---
    eq2_3 = np.array([
        vertical(R, B),
        horizontal(R, B),
        -vertical(R, A),
        -horizontal(R, A),
    ])
    ctte2_3 = 0.0

    # --- Momentos cuerpo 3 (entre C y D, conectado al resto y a top) ---
    eq3_3 = np.array([vertical(D, C), horizontal(D, C)])
    ctte3_3 = 0.0

    # --------- Fuerzas en x / y de cada cuerpo --------- #
    # Cuerpo 1: Ax + Dx = Fx_bottom ;  Ay + Dy = Fy_bottom
    eq1_1 = np.array([1.0, 1.0])
    ctte1_1 = F_bottom[0]

    eq1_2 = np.array([1.0, 1.0])
    ctte1_2 = F_bottom[1]

    # Cuerpo 2: Ax, Bx, Rx ; Ay, By, Rx
    eq2_1 = np.array([-1.0, 1.0, -np.sin(theta2)])
    ctte2_1 = 0.0

    eq2_2 = np.array([-1.0, 1.0, -np.cos(theta2)])
    ctte2_2 = 0.0

    # Cuerpo 3: Cx - Dx = 0 ; Cy - Dy = 0
    eq3_1 = np.array([1.0, -1.0])
    ctte3_1 = 0.0

    eq3_2 = np.array([1.0, -1.0])
    ctte3_2 = 0.0

    # --------------------------------------------------- #
    # Vector de incógnitas: [Ax, Ay, Bx, By, Cx, Cy, Dx, Dy, Rx]
    # Matriz de coeficientes (igual a la de MATLAB)
    coef = np.array([
        [eq1_1[0], 0,         0,         0,         0,         0,         eq1_1[1], 0,         0],
        [0,         eq1_2[0], 0,         0,         0,         0,         0,         eq1_2[1], 0],
        [0,         0,         0,         0,         0,         0,         eq1_3[0], eq1_3[1], 0],  # M cuerpo 1
        [eq2_1[0], 0,         eq2_1[1], 0,         0,         0,         0,         0,         eq2_1[2]],
        [0,         eq2_2[0], 0,         eq2_2[1], 0,         0,         0,         0,         eq2_2[2]],
        [eq2_3[0],  eq2_3[1], eq2_3[2], eq2_3[3], 0,         0,         0,         0,         0],  # M cuerpo 2
        [0,         0,         0,         0,         eq3_1[0], 0,         eq3_1[1], 0,         0],
        [0,         0,         0,         0,         0,         eq3_2[0], 0,         eq3_2[1], 0],
        [0,         0,         0,         0,         eq3_3[0], eq3_3[1], 0,         0,         0],  # M cuerpo 3
    ], dtype=float)
    constantes = -np.array([
        ctte1_1, ctte1_2, ctte1_3,
        ctte2_1, ctte2_2, ctte2_3,
        ctte3_1, ctte3_2, ctte3_3
    ], dtype=float)

    # Resolver el sistema lineal
    reac = np.linalg.solve(coef, constantes)

    # ----- chequeo de momentos en C (igual que en MATLAB) ----- #
    dfx = vertical(C, top)
    Mfx = F_top[0] * dfx

    dbx = vertical(C, B)
    MBx = reac[2] * dbx  # Bx

    dr = vertical(C, R)
    MR = reac[8] * dr * np.sin(theta2)

    dr2 = horizontal(C, R)
    MR2 = reac[8] * dr2 * np.cos(theta2)

    dFy = horizontal(C, top)
    MFy = F_top[1] * dFy

    dBy = horizontal(C, B)
    MBy = reac[3] * dBy  # By

    moment_C = Mfx - MBx + abs(MR) + MFy - MBy + MR2

    return reac, moment_C
