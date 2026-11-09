import numpy as np

import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from knee_designer.reaction_analysis import compute_iso10328_reactions

ua = 80.0
uk = 420.0 + ua
ut = 150.0 + uk

ft = 82.0
fk = 52.0
fa = -32.0
fb = -48.0

bottom = np.array([fb, 0.0])
top    = np.array([ft, ut])

EKJC = np.array([0.0, uk])

A = EKJC + np.array([-14.8, -43.4])
B = EKJC + np.array([-19.8, -11.4])
C = EKJC + np.array([0.0,   0.0])   # igual que MATLAB
D = EKJC + np.array([14.0, -46.7])

R = (A + B) / 2.0
F = 4480.0

reac, M = compute_iso10328_reactions(A, B, C, D, R, bottom, top, F)
print("coef debería coincidir con MATLAB (ya se imprime dentro)")
print("reac =", reac)
print("M =", M)
