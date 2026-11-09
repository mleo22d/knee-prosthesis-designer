import numpy as np
import matplotlib.pyplot as plt

import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from knee_designer.icr_synthesis import icr_to_pivots
from knee_designer.geometry_utils import fourbar_icr_trajectory   # <-- ESTE
from knee_designer.plotting_utils import plot_icr_trajectory, plot_mechanism_pose

def main():
    # ----- Datos del ICR objetivo (igual que en MATLAB) -------------------
    x_icr_deseado = np.array([
        6.13490347474404, 62.2695231098297, 70.9468789169059,
        72.4182357498424, 71.8532509929859, 70.6471623831769,
        69.2492168917742, 67.8076441690706, 66.3641980882459,
        64.9217623960490, 63.4699836641558, 61.9956297888261,
        60.4870493638864, 58.9362585880450, 57.3400137415931
    ])

    y_icr_deseado = np.array([
        170.661103495049, 75.1911775800121, 45.6019614604225,
        29.8671566238485, 20.2735695261008, 13.9822971780635,
        9.65313908609947, 6.56941303991253, 4.31487915235749,
        2.63172757602255, 1.35112198593117, 0.356603244319228,
        -0.436275672803053, -1.09171905071370, -1.66061807622522
    ])

    Pdes = np.column_stack([x_icr_deseado, y_icr_deseado])
    N = Pdes.shape[0]

    # ----- Flexión asociada a cada punto (0–90°) --------------------------
    Kdeg = np.linspace(0.0, 90.0, N)
    K = np.deg2rad(Kdeg)

    # ----- Pesos del usuario (aquí todos =1, puedes cambiarlos) ----------
    w_user = np.ones(N)

    # ----- Opciones (coinciden con las de MATLAB) -------------------------
    opts = {
        "num_starts": 20,
        "maxIt": 10,
        "mu0": 1e-3,
        "huber_delta": 150.0,   # mm
        "line_search": True,
        "LMINv": [30, 20, 45, 25],
        "LMAXv": [35, 25, 55, 35],
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

    # ----- Métricas de error (como en MATLAB) ----------------------------
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
    
    plt.show()

    print(pivots)

if __name__ == "__main__":
    main()
