# knee_designer/plotting_utils.py

import matplotlib.pyplot as plt
import numpy as np
from .icr_synthesis import Pivots
from .geometry_utils import fourbar_icr_trajectory

def plot_icr_trajectory(Pdes: np.ndarray, xf: np.ndarray, yf: np.ndarray):
    """Genera la figura de comparación ICR deseado vs. ajustado."""
    plt.figure()
    plt.plot(Pdes[:, 0], Pdes[:, 1], "o", label="ICR deseado")
    plt.plot(xf, yf, "-x", label="ICR ajustado")
    plt.gca().set_aspect("equal", adjustable="box")
    plt.grid(True)
    plt.xlabel("X [mm]")
    plt.ylabel("Y [mm]")
    plt.legend(loc="upper right")
    plt.title("Trayectoria ICR: deseado vs ajustado")
    xmin, xmax = plt.xlim()
    margin = 40
    plt.xlim(xmin - margin, xmax + margin)

def plot_mechanism_pose(pivots: Pivots, K: np.ndarray):
    """Genera la figura del mecanismo en la primera pose."""
    # Reconstruir la trayectoria para obtener B y C en todas las poses
    xf, yf, geom = fourbar_icr_trajectory(
        pivots.lengths["AB"], pivots.lengths["BC"], pivots.lengths["CD"],
        pivots.lengths["DA"], pivots.A, pivots.phiAD, pivots.kappa0, K
    )
    
    valid = np.isfinite(xf)
    if not np.any(valid):
        print("No hay poses válidas para dibujar el mecanismo.")
        return

    # Se usa la primera pose válida para dibujar
    idx0 = np.where(valid)[0][0]
    B0 = geom["B"][idx0, :]
    C0 = geom["C"][idx0, :]
    P0 = np.array([xf[idx0], yf[idx0]])
    A = geom["A"]
    D = geom["D"]

    plt.figure()    
    plt.plot(
        [A[0], B0[0], C0[0], D[0], A[0]],
        [A[1], B0[1], C0[1], D[1], A[1]],
        "o-",
        linewidth=2,
        label="4-barras",
    )
    plt.scatter(P0[0], P0[1], s=80, label="ICR (pose inicial)")
    plt.text(P0[0], P0[1], "  ICR", weight="bold")
    plt.gca().set_aspect("equal", adjustable="box")
    plt.grid(True)
    plt.xlabel("X [mm]")
    plt.ylabel("Y [mm]")
    plt.title("Mecanismo 4-barras en la pose inicial")
    plt.legend(loc="upper right")
    xmin, xmax = plt.xlim()
    margin = 40
    plt.xlim(xmin - margin, xmax + margin)