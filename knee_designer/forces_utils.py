import numpy as np

# ================================================================
#  Cálculo de fuerzas estáticas en eje solidario (A, B, C, D, R)
# ================================================================
def compute_static_values(forces_static, theta2, theta4, N_AB, N_CD):
    """
    forces_static = {
        "A": (Fx0, Fy0),
        "B": (Fx0, Fy0),
        "C": (Fx0, Fy0),
        "D": (Fx0, Fy0),
        "R":  R0
    }
    """

    # --- A ---
    FxA, FyA, FA = fuerzas_sistema_solidario(
        forces_static["A"][0], forces_static["A"][1], -theta2, N_AB
    )
    # --- B ---
    FxB, FyB, FB = fuerzas_sistema_solidario(
        forces_static["B"][0], forces_static["B"][1], -theta2, N_AB
    )
    # --- C ---
    FxC, FyC, FC = fuerzas_sistema_solidario(
        forces_static["C"][0], forces_static["C"][1], -theta4, N_CD
    )
    # --- D ---
    FxD, FyD, FD = fuerzas_sistema_solidario(
        forces_static["D"][0], forces_static["D"][1], -theta4, N_CD
    )

    # Reacción repartida en AB
    R0 = forces_static["R"]
    Ry = R0 / N_AB
    Rx = 0.0

    valores = np.array([
        FxA, FyA, FA,
        FxB, FyB, FB,
        FxC, FyC, FC,
        FxD, FyD, FD,
        Rx,  Ry
    ])

    return valores


# ================================================================
#  Cálculo de amplitud y media para cargas de fatiga
# ================================================================
def compute_fatigue_values(forces_min, forces_max, theta2, theta4, N_AB, N_CD):
    """
    forces_min / forces_max = {
        "A": (Fx0_min, Fy0_min),
        "B": (Fx0_min, Fy0_min),
        "C": (Fx0_min, Fy0_min),
        "D": (Fx0_min, Fy0_min),
        "R":  R_min
    }
    """

    # ---- Convertir a sistema solidario (MÍNIMOS) ----
    FxA_min, FyA_min, FA_min = fuerzas_sistema_solidario(
        forces_min["A"][0], forces_min["A"][1], -theta2, N_AB
    )
    FxB_min, FyB_min, FB_min = fuerzas_sistema_solidario(
        forces_min["B"][0], forces_min["B"][1], -theta2, N_AB
    )
    FxC_min, FyC_min, FC_min = fuerzas_sistema_solidario(
        forces_min["C"][0], forces_min["C"][1], -theta4, N_CD
    )
    FxD_min, FyD_min, FD_min = fuerzas_sistema_solidario(
        forces_min["D"][0], forces_min["D"][1], -theta4, N_CD
    )
    Ry_min = forces_min["R"] / N_AB
    Rx_min = 0.0

    # ---- Convertir a sistema solidario (MÁXIMOS) ----
    FxA_max, FyA_max, FA_max = fuerzas_sistema_solidario(
        forces_max["A"][0], forces_max["A"][1], -theta2, N_AB
    )
    FxB_max, FyB_max, FB_max = fuerzas_sistema_solidario(
        forces_max["B"][0], forces_max["B"][1], -theta2, N_AB
    )
    FxC_max, FyC_max, FC_max = fuerzas_sistema_solidario(
        forces_max["C"][0], forces_max["C"][1], -theta4, N_CD
    )
    FxD_max, FyD_max, FD_max = fuerzas_sistema_solidario(
        forces_max["D"][0], forces_max["D"][1], -theta4, N_CD
    )
    Ry_max = forces_max["R"] / N_AB
    Rx_max = 0.0

    # ---- Amplitud y media ----
    FxA_a, FxA_m = fuerzas_amplitud_media(FxA_max, FxA_min)
    FyA_a, FyA_m = fuerzas_amplitud_media(FyA_max, FyA_min)
    FA_a,  FA_m  = fuerzas_amplitud_media(FA_max, FA_min)

    FxB_a, FxB_m = fuerzas_amplitud_media(FxB_max, FxB_min)
    FyB_a, FyB_m = fuerzas_amplitud_media(FyB_max, FyB_min)
    FB_a,  FB_m  = fuerzas_amplitud_media(FB_max, FB_min)

    FxC_a, FxC_m = fuerzas_amplitud_media(FxC_max, FxC_min)
    FyC_a, FyC_m = fuerzas_amplitud_media(FyC_max, FyC_min)
    FC_a,  FC_m  = fuerzas_amplitud_media(FC_max, FC_min)

    FxD_a, FxD_m = fuerzas_amplitud_media(FxD_max, FxD_min)
    FyD_a, FyD_m = fuerzas_amplitud_media(FyD_max, FyD_min)
    FD_a,  FD_m  = fuerzas_amplitud_media(FD_max, FD_min)

    Rx_a, Rx_m = fuerzas_amplitud_media(Rx_max, Rx_min)
    Ry_a, Ry_m = fuerzas_amplitud_media(Ry_max, Ry_min)

    valores_a = np.array([
        FxA_a, FyA_a, FA_a,
        FxB_a, FyB_a, FB_a,
        FxC_a, FyC_a, FC_a,
        FxD_a, FyD_a, FD_a,
        Rx_a,  Ry_a
    ])

    valores_m = np.array([
        FxA_m, FyA_m, FA_m,
        FxB_m, FyB_m, FB_m,
        FxC_m, FyC_m, FC_m,
        FxD_m, FyD_m, FD_m,
        Rx_m,  Ry_m
    ])

    return valores_a, valores_m


# ---------------------------------------------------------
# Transformación a sistema solidario de la barra
# (equivalente a fuerzas_sistema_solidario de MATLAB)
# ---------------------------------------------------------
def fuerzas_sistema_solidario(Fx0, Fy0, theta_deg, n_barras):
    """
    Transforma una fuerza (Fx0, Fy0) del sistema global al
    sistema solidario de la barra rotado un ángulo theta_deg (grados),
    y la divide entre el número de barras (n_barras).

    Devuelve:
        Fx, Fy, F  (todas positivas por el abs, como en MATLAB)
    """
    theta = np.deg2rad(theta_deg)

    # Rotación estándar 2D:
    # [Fx'] =  cosθ * Fx0 - sinθ * Fy0
    # [Fy'] =  sinθ * Fx0 + cosθ * Fy0
    Fx = np.cos(theta) * Fx0 - np.sin(theta) * Fy0
    Fy = np.sin(theta) * Fx0 + np.cos(theta) * Fy0

    # Igual que en MATLAB: se toma el valor absoluto y se reparte entre barras
    Fx = abs(Fx) / n_barras
    Fy = abs(Fy) / n_barras

    F = np.hypot(Fx, Fy)
    return Fx, Fy, F


# ---------------------------------------------------------
# Amplitud y media (equivalente a fuerzas_amplitud_media)
# ---------------------------------------------------------
def fuerzas_amplitud_media(F_max, F_min):
    """
    Calcula la fuerza de amplitud y la fuerza media
    a partir de F_max y F_min.

    Devuelve:
        F_a, F_m
    """
    F_m = 0.5 * (F_max + F_min)
    F_a = 0.5 * (F_max - F_min)
    return F_a, F_m
