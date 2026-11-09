# knee_pipeline.py
import sys, os
import numpy as np
import matplotlib.pyplot as plt

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.append(ROOT)

from knee_designer.icr_synthesis import icr_to_pivots, Pivots
from knee_designer.geometry_utils import fourbar_icr_trajectory  
from knee_designer.plotting_utils import plot_icr_trajectory, plot_mechanism_pose
from knee_designer.reaction_analysis import compute_reactions_from_icr_parameters
from knee_designer.forces_utils import compute_static_values, compute_fatigue_values
from knee_designer.pin_design import pin_diameter_design, safety_factor_pin
from knee_designer.ab_bar_design import design_bar_AB, check_bar_AB
from knee_designer.cd_bar_design import design_bar_CD, check_bar_CD
from knee_designer.update_knee_cad import update_knee_prosthesis_assembly


def run_pipeline_from_icr(x_icr_deseado, y_icr_deseado, result_name="knee_design_gui"):

    Pdes = np.column_stack([x_icr_deseado, y_icr_deseado])
    N = Pdes.shape[0]

    # Flexión asociada a cada punto (0–90°)
    Kdeg = np.linspace(0.0, 90.0, N)
    K = np.deg2rad(Kdeg)

    # Pesos del usuario (por ahora todos = 1)
    w_user = np.ones(N)

    opts = {
        "num_starts": 20,
        "maxIt": 100,
        "mu0": 1e-3,
        "huber_delta": 150.0,   # mm
        "line_search": True,
        "LMINv": [30, 20, 25, 25],
        "LMAXv": [100, 90, 80, 100],
        "kappa0_min": np.deg2rad(25),
        "kappa0_max": np.deg2rad(45),
        "padA": 100.0,
        "phiAD_min": np.deg2rad(-15),
        "phiAD_max": np.deg2rad(-5),
    }


    # ----- Ajuste del 4-barras -------------------------------------------
    pivots, info = icr_to_pivots(Pdes, K=K, w_user=w_user, opts=opts)
    p_opt = info["p_opt"]
    a, b, c, d, phiAD, kappa0, Ax, Ay = p_opt
    A = np.array([Ax, Ay])

    print("\n=== Parámetros óptimos del 4-barras ===")
    print(f"a = {a:.3f} mm")
    print(f"b = {b:.3f} mm")
    print(f"c = {c:.3f} mm")
    print(f"d = {d:.3f} mm")
    print(f"phiAD  = {np.rad2deg(phiAD):.3f} deg")
    print(f"kappa0 = {np.rad2deg(kappa0):.3f} deg")
    print(f"theta3_0 = {np.rad2deg(phiAD + kappa0):.3f} deg")
    print(f"A = ({Ax:.3f}, {Ay:.3f})")
    print(f"Best residual norm = {info['best_residual_norm']:.4f}")
    print(f"Iterations (best)  = {info['iterations']}")

    # ----- Trayectoria ICR ajustada --------------------------------------
    xf, yf, geom = fourbar_icr_trajectory(a, b, c, d, A, phiAD, kappa0, K)

    # ----- Métricas de error ----------------------------
    dx = xf - x_icr_deseado
    dy = yf - y_icr_deseado
    err = np.hypot(dx, dy)
    mask = np.isfinite(err)

    rmse = np.sqrt(np.mean(err[mask] ** 2))
    mae = np.mean(np.abs(err[mask]))
    emax = np.max(err[mask])
    Nval = np.sum(mask)

    dx_range = x_icr_deseado.max() - x_icr_deseado.min()
    dy_range = y_icr_deseado.max() - y_icr_deseado.min()
    L_range = max(dx_range, dy_range)

    # diámetro del conjunto deseado
    L_diam = 0.0
    for i in range(N):
        for j in range(i + 1, N):
            dij = np.hypot(
                Pdes[i, 0] - Pdes[j, 0],
                Pdes[i, 1] - Pdes[j, 1],
            )
            if dij > L_diam:
                L_diam = dij

    rmse_pct_range = 100.0 * rmse / L_range
    rmse_pct_diam = 100.0 * rmse / L_diam

    print("\n=== Error ICR (ajustado vs deseado) ===")
    print(f"RMSE = {rmse:.3f} mm | MAE = {mae:.3f} mm | MaxErr = {emax:.3f} mm | N = {Nval}")
    print(f"RMSE% (rango)   = {rmse_pct_range:.2f} %")
    print(f"RMSE% (diámetro)= {rmse_pct_diam:.2f} %")

    # ----- Plot 1: Trayectoria ICR deseada vs ajustada -------------------
    # Llamamos a las funciones del nuevo módulo:
    plot_icr_trajectory(Pdes, xf, yf)
    plot_mechanism_pose(pivots, K) # Necesita K para calcular todas las poses
    
    #plt.show()

    ### REACCIONES EN LOS PIVOTES SEGUN NORMA ISO 10328 ###

    # ---- Crear versión redondeada para el diseño mecánico ----
    params = Pivots(
        A=np.round(pivots.A, 1),
        B=np.round(pivots.B, 1),
        C=np.round(pivots.C, 1),
        D=np.round(pivots.D, 1),
        lengths={name: round(L, 1) for name, L in pivots.lengths.items()},
        # Angulos en radianes
        phiAD=round(pivots.phiAD, 3),
        kappa0=round(pivots.kappa0, 3),
    )

    print(params)
    
    ua = 80.0
    uk = 420.0 + ua
    ut = 150.0 + uk

    ft = 82.0
    fk = 52.0
    fa = -32.0
    fb = -48.0

    bottom = np.array([fb, 0.0])
    top    = np.array([ft, ut])
    F_static = 4480
    F_min = 50
    F_max = 1330
    EKJC = np.array([0.0, uk])

    reac_static, M_static = compute_reactions_from_icr_parameters(params, bottom, top, EKJC, F_static)
    print(reac_static)
    print(M_static)

    reac_min, M_min = compute_reactions_from_icr_parameters(params, bottom, top, EKJC, F_min)
    print(reac_min)
    print(M_min)

    reac_max, M_max = compute_reactions_from_icr_parameters(params, bottom, top, EKJC, F_max)
    print(reac_max)
    print(M_max)
    
    # -------------------------
    # Entradas del caso estático
    # -------------------------

    forces_static = {
        "A": (reac_static[0], reac_static[1]),
        "B": (reac_static[2], reac_static[3]),
        "C": (reac_static[4], reac_static[5]),
        "D": (reac_static[6], reac_static[7]),
        "R": reac_static[8]      # siempre es solo en Y
    }

    static_values = compute_static_values(
        forces_static,
        theta2=98.2057, 
        theta4=106.1989,
        N_AB=2, N_CD=2
    )
    print("VALORES ESTÁTICOS:\n", static_values)

    ### DISENÑO MECANICO DEL PIN - DIAMETRO ###
    # -----------------------------
    # Extraer fuerzas en los pines
    idx_A, idx_B, idx_C, idx_D = 2, 5, 8, 11

    F_A = static_values[idx_A]
    F_B = static_values[idx_B]
    F_C = static_values[idx_C]
    F_D = static_values[idx_D]
    print(F_A)
    n_factor = 1.2
    S_y = 215
    S_sy = S_y/np.sqrt(3)

    # -----------------------------
    # 1) Diseñar diámetro de pines
    # -----------------------------
    d_min, d_req, d_eg = pin_diameter_design(
        F_A, F_B, F_C, F_D,
        n_factor,
        S_sy
    )

    print("Diámetros mínimos (mm):", d_min)
    print("Diámetro requerido crítico (mm):", d_req)
    print("Diámetro escogido común (mm):", d_eg)

    # -----------------------------
    # 2) Factores de seguridad con d_eg
    # -----------------------------
    n_pines = safety_factor_pin(
        F_A, F_B, F_C, F_D,
        d_eg,
        S_sy
    )

    print("Factores de seguridad por pin:", n_pines)

    # Ejemplo: usar fuerzas en C
    F_x_A = static_values[0]  # componente en x de la fuerza en la barra AB
    F_y_A = static_values[1]  # componente en y de la fuerza en la barra AB
    print(F_x_A)
    l_a = 32.4
    result_ab = design_bar_AB(F_x_A, F_y_A, l_a, 12, 1.2, 465)
    w_AB = result_ab["w"]
    t_AB = result_ab["t"]

    print("Barra AB -> w =", w_AB, "mm, t =", t_AB, "mm")

    # Verificación con algún w,t comercial que elijas (por ejemplo redondeando)
    w_AB_eg = np.ceil(w_AB)   # o al par más cercano, etc.
    t_AB_eg = np.ceil(t_AB*2)/2.0  # ejemplo: redondeo a múltiplos de 0.5 mm

    sigma_AB, n_AB = check_bar_AB(F_x_A, F_y_A, l_a, 12, w_AB_eg, t_AB_eg, 465)

    print("Verificación AB: sigma =", sigma_AB, "MPa, n =", n_AB)


    # Ejemplo: usar fuerzas en C
    F_D = static_values[11]  # componente en x de la fuerza en la barra CD
    print(F_D)

    result_cd = design_bar_CD(F_D, 12, 1.2, 465)
    w_CD = result_cd["w"]
    t_CD = result_cd["t"]

    print("Barra CD -> w =", w_CD, "mm, t =", t_CD, "mm")

    # Verificación con algún w,t comercial que elijas (por ejemplo redondeando)
    w_CD_eg = np.ceil(w_CD)   # o al par más cercano, etc.
    t_CD_eg = np.ceil(t_CD*2)/2.0  # ejemplo: redondeo a múltiplos de 0.5 mm

    sigma_CD, n_CD = check_bar_CD(F_D, 12, w_CD_eg, t_CD_eg, 465)

    print("Verificación CD: sigma =", sigma_CD, "MPa, n =", n_CD)


    # ================================
    # PARÁMETROS PARA EL MODELO CAD
    # ================================

    # Diámetro de agujero (pines)
    d_hole = float(np.round(d_eg, 2))

    # Longitudes de barras desde la síntesis de ICR
    l_a = float(np.round(params.lengths["AB"], 2))  # barra AB
    l_c = float(np.round(params.lengths["CD"], 2))  # barra CD

    # Ancho y espesor de barras desde el diseño mecánico (redondeados)
    w_ab = float(w_AB_eg)
    t_ab = float(t_AB_eg)

    w_cd = float(w_CD_eg)
    t_cd = float(t_CD_eg)

    # Geometría base AD y BC
    # phiAD y kappa0 están en radianes dentro de params
    phi_AD = float(np.round(np.rad2deg(params.phiAD),2)) # orientación de AD
    theta_4 = float(np.round((angle_segment_deg(params.D, params.C)) % 360.0, 2))
    theta_3 = float(angle_segment_deg(params.B, params.C))  
    # Longitud AD (distancia entre A y D)
    l_d = float(np.round(np.linalg.norm(params.D - params.A), 2))

    # Longitud BC
    l_b = float(np.round(np.linalg.norm(params.C - params.B), 2))

    print("\n=== Parámetros para CAD ===")
    print("d_hole   =", d_hole)
    print("l_a      =", l_a, "mm")
    print("w_ab, t_ab  =", w_ab, t_ab, "mm")
    print("l_c      =", l_c, "mm")
    print("w_cd, t_cd  =", w_cd, t_cd, "mm")
    print("theta_4  =", theta_4, "deg")
    print("l_d      =", l_d, "mm")
    print("theta_3  =", theta_3, "deg")
    print("l_b      =", l_b, "mm")

    update_knee_prosthesis_assembly(
        d_hole, l_a, w_ab, t_ab,
        l_c, w_cd, t_cd,
        theta_4, l_d, phi_AD, theta_3, l_b,
        result_name=result_name,
    )


def angle_segment_deg(P, Q):
    """
    Ángulo (en grados) del segmento P→Q medido desde +X,
    usando atan2 para manejar todos los cuadrantes.
    """
    vx = Q[0] - P[0]
    vy = Q[1] - P[1]
    return np.degrees(np.arctan2(vy, vx))
