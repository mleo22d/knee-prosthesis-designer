import numpy as np

import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from knee_designer.forces_utils import (
    compute_static_values,
    compute_fatigue_values
)

# -------------------------
# Entradas del caso estático
# -------------------------
forces_static = {
    "A": (3630.839, -4787.680),
    "B": (1997.283, 5667.074),
    "C": (2752.239, -9180.682),
    "D": (-2752.239, 9180.685),
    "R": 5696.411
}

valores = compute_static_values(
    forces_static,
    theta2=98.2057,
    theta4=106.1989,
    N_AB=2, N_CD=2
)
print("VALORES ESTÁTICOS:\n", valores)

# -------------------------
# Entradas de fatiga
# -------------------------
forces_min = {
    "A": (40.5228,  -53.4340),
    "B": (22.2911,   63.2486),
    "C": (30.7169, -102.4630),
    "D": (-30.7169, 102.4630),
    "R": 63.5760
}
forces_max = {    
    "A": (1077.9053,  -1421.3426),
    "B": (592.9435,    1682.4127),
    "C": (817.0708,   -2725.5149),
    "D": (-817.0708,   2725.5149),
    "R": 1691.1219
}

valores_a, valores_m = compute_fatigue_values(
    forces_min, forces_max,
    theta2=98.2057,
    theta4=106.1989,
    N_AB=2, N_CD=2
)

print("AMPLITUD\n",valores_a)
print("MEDIA\n",valores_m)
