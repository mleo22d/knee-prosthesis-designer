import numpy as np

import numpy as np

def design_bar_CD(F, d, n, S_y,
                  k_t=2.18,
                  w_factor_min=1.5,
                  w_factor_max=3.0,
                  w_step=2.0,
                  t_min_geom=4.0):
    """
    Diseña la barra CD iterando sobre w, con un espesor mínimo geométrico.
    """

    best = None

    w_values = np.arange(w_factor_min * d,
                         w_factor_max * d + 1e-6,
                         w_step)
    print(w_values)
    for w in w_values:
        if w <= d:
            continue

        t_min_c = (n / S_y) * ((k_t * F) / (w - d))

        # espesor final respetando mínimo geométrico
        t_req = max(t_min_c, t_min_geom)

        A = w * t_req

        if best is None or A < best["A"]:
            best = {
                "w": w,
                "t": t_req,
                "t_min_c": t_min_c,
                "A": A
            }

    if best is None:
        raise ValueError("No se encontró ninguna combinación válida de w; revisa los rangos.")

    return best


def check_bar_CD(F, d, w_eg, t_eg, S_y, k_t=2.18):
    """
    Verifica el factor de seguridad de una barra CD ya escogida (w_eg, t_eg)
    usando el caso crítico en el agujero (como tu ejemplo de CD).
    """
    # Solo tracción en el neto con concentración (similar a tu sigma_CD_tension)
    sigma_tension = F / (t_eg * (w_eg - d))
    sigma_eq = k_t * sigma_tension

    n_bar = S_y / sigma_eq
    return sigma_eq, n_bar
