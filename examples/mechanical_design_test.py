import numpy as np
import matplotlib.pyplot as plt

import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from knee_designer.pin_design import (
    pin_diameter_design,   # antes diseno_pines_diametro
    safety_factor_pin      # antes factores_segurisdad_pines
)
from knee_designer.ab_bar_design import (
    design_bar_AB,   # antes diseno_pines_diametro
    check_bar_AB      # antes factores_seguridad_pines
)
from knee_designer.cd_bar_design import (
    design_bar_CD,   # antes diseno_pines_diametro
    check_bar_CD      # antes factores_seguridad_pines
)

# -----------------------------
# Arreglos de resultados (ejemplo)
# -----------------------------
valores_estaticos = np.array([
    2636.94212311, 1482.82088775, 3025.26388036, 2691.08726148,
    1382.12549969, 3025.26388036, 4804.26242508,   67.10998788,
    4804.73112667, 4804.26242508,   67.10998788, 4804.73112667,
       0.        , 2865.45799113
])

amplitud = np.array([
    376.70601759, 211.83155539, 432.18055434, 384.44103735,
    197.44649996, 432.18055434, 686.32320358,   9.58714113,
    686.39016095, 686.32320358,   9.58714113, 686.39016095,
      0.        , 409.35114159
])

media = np.array([
    406.13617521, 228.38089566, 465.94466014, 414.4754934 ,
    212.87200777, 465.94466014, 739.94220386,  10.33613653,
    740.01439228, 739.94220386,  10.33613653, 740.01439228,
      0.        , 441.33169953
])

# -----------------------------
# Extraer fuerzas en los pines
# F_A, F_B, F_C, F_D = elementos 3, 6, 9, 12 (MATLAB)
# En Python -> índices 2, 5, 8, 11
# -----------------------------
idx_A, idx_B, idx_C, idx_D = 2, 5, 8, 11

F_A = valores_estaticos[idx_A]
F_B = valores_estaticos[idx_B]
F_C = valores_estaticos[idx_C]
F_D = valores_estaticos[idx_D]
print(F_A)
# -----------------------------
# Parámetros de diseño (ya los debes tener definidos antes)
# -----------------------------
# n = factor de seguridad estático deseado
# S_xy_steel = esfuerzo cortante permisible [MPa = N/mm^2]

# -----------------------------
# 1) Diseñar diámetro de pines
# -----------------------------
d_min, d_req, d_eg = pin_diameter_design(
    F_A, F_B, F_C, F_D,
    1.2,
    215/np.sqrt(3)
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
    215/np.sqrt(3)
)

print("Factores de seguridad por pin:", n_pines)

# Ejemplo: usar fuerzas en C
F_x_A = valores_estaticos[0]  # componente en x de la fuerza en la barra AB
F_y_A = valores_estaticos[1]  # componente en y de la fuerza en la barra AB
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
F_D = valores_estaticos[11]  # componente en x de la fuerza en la barra CD
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

