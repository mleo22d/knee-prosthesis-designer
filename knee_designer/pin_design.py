import math

# ---------------------------------------------------------
# Diseño estático de pines: cálculo de diámetros mínimos
# y selección de un diámetro comercial común (par, hacia arriba)
# ---------------------------------------------------------

def pin_diameter_design(F_A, F_B, F_C, F_D, n, S_xy_steel):
    """
    Calcula el diámetro mínimo para cada pin (A, B, C, D)
    y escoge un diámetro común basándose en el pin más crítico.

    Parámetros
    ----------
    F_A, F_B, F_C, F_D : float
        Fuerzas en cada pin [N].
    n : float
        Factor de seguridad deseado (estático).
    S_xy_steel : float
        Esfuerzo cortante permisible del acero [MPa o N/mm^2].

    Retorna
    -------
    d_min : dict
        Diámetros mínimos por pin (mm).
    d_req : float
        Diámetro requerido del pin crítico (mm).
    d_eg : float
        Diámetro escogido (mm), redondeado al par inmediato superior.
    """
    d_A_min = math.sqrt(4.0 * F_A * n / (math.pi * S_xy_steel))
    d_B_min = math.sqrt(4.0 * F_B * n / (math.pi * S_xy_steel))
    d_C_min = math.sqrt(4.0 * F_C * n / (math.pi * S_xy_steel))
    d_D_min = math.sqrt(4.0 * F_D * n / (math.pi * S_xy_steel))

    d_min = {
        "A": d_A_min,
        "B": d_B_min,
        "C": d_C_min,
        "D": d_D_min,
    }

    # Se diseña con el pin que pide mayor diámetro (más crítico)
    d_req = max(d_min.values())

    # Llevar al inmediato superior par (ej: 6.5 -> 8 mm)
    d_eg = 2.0 * math.ceil(d_req / 2.0)

    return d_min, d_req, d_eg


# ---------------------------------------------------------
# Cálculo de factor de seguridad para cada pin con d_eg
# ---------------------------------------------------------

def safety_factor_pin(F_A, F_B, F_C, F_D, d_eg, S_xy_steel):
    """
    Calcula el factor de seguridad estático en cortante para cada pin
    usando el mismo diámetro escogido d_eg.

    Retorna
    -------
    n_pines : dict
        Factor de seguridad para cada pin {"A": n_A, ...}.
    """
    n_A = (d_eg**2) * math.pi * S_xy_steel / (4.0 * F_A)
    n_B = (d_eg**2) * math.pi * S_xy_steel / (4.0 * F_B)
    n_C = (d_eg**2) * math.pi * S_xy_steel / (4.0 * F_C)
    n_D = (d_eg**2) * math.pi * S_xy_steel / (4.0 * F_D)

    return {"A": n_A, "B": n_B, "C": n_C, "D": n_D}
