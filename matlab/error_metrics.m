% ============================================================
% Evalúa y compara el ajuste de varios mecanismos de 4 barras frente a una
% trayectoria ICR deseada, calculando RMSE/MAE/MaxErr y errores relativos (%)
% normalizados por rango y por diámetro de la trayectoria.
% ============================================================

clear; close all; clc

%% ===== Trayectoria ICR deseada (11 puntos) =====
x_icr_deseado = [6.13490347474404	62.2695231098297	70.9468789169059	72.4182357498424	71.8532509929859	70.6471623831769	69.2492168917742	67.8076441690706	66.3641980882459	64.9217623960490	63.4699836641558	61.9956297888261	60.4870493638864	58.9362585880450	57.3400137415931];
y_icr_deseado = [170.661103495049	75.1911775800121	45.6019614604225	29.8671566238485	20.2735695261008	13.9822971780635	9.65313908609947	6.56941303991253	4.31487915235749	2.63172757602255	1.35112198593117	0.356603244319228	-0.436275672803053	-1.09171905071370	-1.66061807622522];

x_des = x_icr_deseado(:);
y_des = y_icr_deseado(:);

% Ángulos asociados a esos 11 puntos
angles_spec_deg = linspace(0,110,15);

%% ===== Mecanismos (3 casos) =====
% Campos: a b c d A=[Ax Ay] phiAD_deg k0_deg
mech = struct([]);

% Mecanismo 1 (original)
mech(1).name = 'Mecanismo 1';
mech(1).a = 39.978; mech(1).b = 39.978; mech(1).c = 54.991; mech(1).d = 20.642;
mech(1).A = [44.146, -26.149]; mech(1).phiAD_deg = -6.989; mech(1).k0_deg = 46.811;

% Mecanismo 2
mech(2).name = 'Mecanismo 2';
mech(2).a = 89.242; mech(2).b = 26.303; mech(2).c = 85.837; mech(2).d = 45.790;
mech(2).A = [-27.916, -101.619]; mech(2).phiAD_deg = 4.136; mech(2).k0_deg = -1.387;

% Mecanismo 3
mech(3).name = 'Mecanismo 3';
mech(3).a = 73.649; mech(3).b = 35.112; mech(3).c = 83.015; mech(3).d = 59.174;
mech(3).A = [-28.680, -84.860]; mech(3).phiAD_deg = -11.167; mech(3).k0_deg = 9.465;

%% ===== Escalas de referencia de la trayectoria deseada =====
% 1) Escala por rango (máx(ΔX, ΔY))
dx_range = max(x_des) - min(x_des);
dy_range = max(y_des) - min(y_des);
L_range  = max(dx_range, dy_range);

% 2) Escala por distancia máxima entre puntos (diámetro del conjunto)
Pdes = [x_des y_des];
N    = size(Pdes,1);
L_diam = 0;
for i = 1:N
    for j = i+1:N
        dij = hypot(Pdes(i,1)-Pdes(j,1), Pdes(i,2)-Pdes(j,2));
        if dij > L_diam, L_diam = dij; end
    end
end

% Umbral objetivo (porcentaje aceptable de error relativo)
pct_target = 5;   % 5 %

%% ===== Cálculo de error respecto a la trayectoria deseada =====
for i = 1:numel(mech)
    a=mech(i).a; b=mech(i).b; c=mech(i).c; d=mech(i).d;
    A=mech(i).A;
    phiAD = deg2rad(mech(i).phiAD_deg);
    k0    = deg2rad(mech(i).k0_deg);

    % ICR predicho por el mecanismo en los ángulos de la trayectoria deseada
    [x_pred, y_pred, ~, ok] = icr_for_angles(a,b,c,d,A,phiAD,k0,angles_spec_deg);

    % Error punto a punto (mm)
    dx = x_pred(:) - x_des;
    dy = y_pred(:) - y_des;
    err_pt = hypot(dx, dy);        % norma euclídea

    % Ignorar puntos sin cierre (ok=false) en los agregados
    mask = ok(:) & ~isnan(err_pt);

    % Métricas absolutas (mm)
    rmse   = sqrt(mean(err_pt(mask).^2));
    mae    = mean(abs(err_pt(mask)));
    emax   = max(err_pt(mask));
    nvalid = sum(mask);

    % Métricas relativas (%)
    rmse_pct_diam  = 100 * rmse / L_diam;    % respecto al diámetro
    rmse_pct_range = 100 * rmse / L_range;   % respecto a max(ΔX,ΔY)

    % ¿Cumple el umbral objetivo?
    ok_diam  = rmse_pct_diam  <= pct_target;
    ok_range = rmse_pct_range <= pct_target;

    % Guardar en la estructura
    mech(i).angles_deg   = angles_spec_deg(:);
    mech(i).x_pred       = x_pred(:);
    mech(i).y_pred       = y_pred(:);
    mech(i).ok           = ok(:);
    mech(i).err_dx       = dx;
    mech(i).err_dy       = dy;
    mech(i).err_norm     = err_pt;
    mech(i).rmse_mm      = rmse;
    mech(i).mae_mm       = mae;
    mech(i).maxerr_mm    = emax;
    mech(i).n_valid      = nvalid;
    mech(i).rmse_pct_diam  = rmse_pct_diam;
    mech(i).rmse_pct_range = rmse_pct_range;
    mech(i).meets_5pct_diam  = ok_diam;
    mech(i).meets_5pct_range = ok_range;

    % Reporte en consola
    fprintf('%s -> RMSE = %.2f mm | MAE = %.2f mm | MaxErr = %.2f mm | válidos = %d/%d\n', ...
        mech(i).name, rmse, mae, emax, nvalid, numel(angles_spec_deg));
    fprintf('            RMSE%% (distancia máxima) = %.2f%%  [%s]  |  RMSE%% (rango) = %.2f%%  [%s]\n', ...
        rmse_pct_diam,  ternary(ok_diam,'OK','NO-OK'), ...
        rmse_pct_range, ternary(ok_range,'OK','NO-OK'));
end

% Variables útiles al workspace (opcional)
assignin('base','mech_err',mech);
assignin('base','ICR_deseado_xy',[x_des y_des]);
assignin('base','angles_spec_deg',angles_spec_deg(:));
assignin('base','L_range',L_range);
assignin('base','L_diam',L_diam);
assignin('base','pct_target',pct_target);

%% ===== Umbrales en mm equivalentes al 5% (al final) =====
rmse_mm_5pct_diam  = (pct_target/100) * L_diam;
rmse_mm_5pct_range = (pct_target/100) * L_range;
fprintf('\n=== Umbral del %.1f%% convertido a RMSE (mm) ===\n', pct_target);
fprintf('• Escala distancia máxima (diámetro): %.3f mm\n', rmse_mm_5pct_diam);
fprintf('• Escala rango (max(ΔX,ΔY))        : %.3f mm\n\n', rmse_mm_5pct_range);

%% ===== Función: ICR para lista de ángulos (usa radianes internamente) ====
function [xICR,yICR,theta2_list,ok_flags] = icr_for_angles(a,b,c,d,A,phiAD,k0,angles_deg)
    A = A(:)';
    D = A + d*[cos(phiAD) sin(phiAD)];

    K = deg2rad(angles_deg(:));
    N = numel(K);

    xICR = nan(1,N); yICR = nan(1,N);
    theta2_list = nan(1,N); ok_flags = false(1,N);
    th2_prev = NaN;

    for i=1:N
        th3 = phiAD + k0 + K(i);
        u3  = [cos(th3) sin(th3)];
        S   = (D - A) - b*u3;
        rS  = norm(S);
        if rS < 1e-12, continue; end

        alpha  = atan2(S(2), S(1));
        cosDel = (a^2 + rS^2 - c^2)/(2*a*rS);
        if abs(cosDel) > 1+1e-12, continue; end
        cosDel = max(-1, min(1, cosDel));
        delta  = acos(cosDel);

        th2c = [alpha + delta, alpha - delta];
        if ~isnan(th2_prev)
            [~,ix] = min(abs( angleDiff(th2c, th2_prev) ));
        else
            ix = 1;
        end
        th2 = th2c(ix); th2_prev = th2;

        B = A + a*[cos(th2) sin(th2)];
        C = B + b*u3;

        r2 = B - A; r4 = C - D;
        M = [r2(:), -r4(:)]; rhs = (D(:) - A(:));
        if abs(det(M)) < 1e-12, continue; end

        ts = M \ rhs;
        P  = A + ts(1)*r2;

        xICR(i) = P(1); yICR(i) = P(2);
        theta2_list(i) = th2; ok_flags(i) = true;
    end
end

function d = angleDiff(angVec, ref)
    angVec = wrapToPi_local(angVec);
    ref    = wrapToPi_local(ref);
    d      = wrapToPi_local(angVec - ref);
end

function ang = wrapToPi_local(ang)
    ang = mod(ang + pi, 2*pi) - pi;
end

function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end
