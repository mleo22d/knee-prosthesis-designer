import sys, os
import numpy as np
import matplotlib.pyplot as plt

# --- Añadir raíz del proyecto (para knee_designer/*) ---
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.append(ROOT)

from knee_designer.knee_pipeline import run_pipeline_from_icr


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

    run_pipeline_from_icr(x_icr_deseado, y_icr_deseado, result_name="test13")

if __name__ == "__main__":
    main()
