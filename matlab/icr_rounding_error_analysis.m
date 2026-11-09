% ============================================================
% Compara la trayectoria ICR del mecanismo optimizado vs una versión
% redondeada (fabricable), calculando RMSE por ángulos específicos y
% graficando ambas curvas con segmentos de error y tabla de diferencias.
% ============================================================

clear; close all; clc

% ---- Angulos de interes ----
angles_spec_deg = [0 8 15 20 30 40 60 70 90 100 110]';  % columna
flex_grid_deg   = linspace(0,110,200);   % malla para curvas

% ---- Caso 1: original vs redondeado ----
% Original (con decimales)
m1o.a=32.371; m1o.b=22.887; m1o.c=48.720; m1o.d=28.959;
m1o.A=[38.269 -21.303]; m1o.phiAD_deg=-6.528; m1o.k0_deg=36.417;

% Redondeado (fabricable)
m1r.a=32.4; m1r.b=22.9; m1r.c=48.7; m1r.d=29.0;
m1r.A=[38.3 -21.3]; m1r.phiAD_deg=-6.5; m1r.k0_deg=36.4;

toRad = @(x) (pi/180).*x;

% ---- Trayectorias (malla fina y puntos en angulos) ----
[xg_o, yg_o] = icr_for_angles(m1o.a,m1o.b,m1o.c,m1o.d, m1o.A, toRad(m1o.phiAD_deg), toRad(m1o.k0_deg), flex_grid_deg);
[xs_o, ys_o] = icr_for_angles(m1o.a,m1o.b,m1o.c,m1o.d, m1o.A, toRad(m1o.phiAD_deg), toRad(m1o.k0_deg), angles_spec_deg);

[xg_r, yg_r] = icr_for_angles(m1r.a,m1r.b,m1r.c,m1r.d, m1r.A, toRad(m1r.phiAD_deg), toRad(m1r.k0_deg), flex_grid_deg);
[xs_r, ys_r] = icr_for_angles(m1r.a,m1r.b,m1r.c,m1r.d, m1r.A, toRad(m1r.phiAD_deg), toRad(m1r.k0_deg), angles_spec_deg);

% ---- Errores punto a punto ----
dx = xs_r - xs_o; dy = ys_r - ys_o; err = hypot(dx,dy);
rmse = sqrt(mean(err.^2));

% Diametro del conjunto original (para RMSE%)
P = [xs_o ys_o];
L_diam = 0;
for i = 1:numel(angles_spec_deg)
  for j = i+1:numel(angles_spec_deg)
    dij = hypot(P(i,1)-P(j,1), P(i,2)-P(j,2));
    if dij > L_diam, L_diam = dij; end
  end
end
rmse_pct = 100*rmse/L_diam;

fprintf('\n=== Caso 1: redondeado vs original ===\n');
fprintf('RMSE = %.3f mm\n', rmse);
fprintf('RMSE%% (normalizado por diametro = %.3f mm) = %.2f %%\n', L_diam, rmse_pct);

% ---- Figura ----
fig = figure('Color','w','Position',[80 80 980 640]);
ax  = axes(fig); hold(ax,'on'); axis(ax,'equal'); grid(ax,'on'); box(ax,'on');

p1 = plot(ax, xg_o, yg_o, '-', 'Color',[0 0 0], 'LineWidth',1.2, 'DisplayName','Optimizado');
p2 = plot(ax, xg_r, yg_r, '-', 'Color',[0.00 0.45 0.74], 'LineWidth',1.2, 'DisplayName','Aproximado');

s1 = scatter(ax, xs_o, ys_o, 42, 'k', 'filled', 'DisplayName','Angulos (orig)');
s2 = scatter(ax, xs_r, ys_r, 42, [0.00 0.45 0.74], 'filled', 'DisplayName','Angulos (red)');

% Barras de error como segmentos
for k=1:numel(angles_spec_deg)
    plot(ax, [xs_r(k) xs_o(k)], [ys_r(k) ys_o(k)], '-', 'Color',[.5 .5 .5], 'LineWidth',0.9, 'HandleVisibility','off');
end

xlabel(ax,'x [mm]'); ylabel(ax,'y [mm]');
% --- Ocultar de la leyenda los puntos y barras de error ---
% --- Ocultar de la leyenda los puntos y barras de error ---
set([s1 s2], 'HandleVisibility','off');

% --- Leyenda SOLO con Original y Redondeado; RMSE debajo de "Redondeado" ---
labelRed = sprintf('Aproximado\n  RMSE = %.2f mm', rmse);
lg = legend(ax, [p1 p2], {'Optimizado', labelRed}, ...
    'Location','northeast', 'Box','on', 'Interpreter','tex');  % '\n' necesita 'tex'
lg.EdgeColor = [0.25 0.25 0.25];


allX = [xg_o(:); xg_r(:); xs_o(:); xs_r(:)];
allY = [yg_o(:); yg_r(:); ys_o(:); ys_r(:)];
pad  = 0.12*max(range(allX), range(allY));
xlim([min(allX)-2*pad, max(allX)+2*pad]);
ylim([min(allY)-pad,   max(allY)+pad]);

%% === Etiquetas de ángulo (formato profesional) ===
% Usamos los puntos del caso redondeado (xs_r, ys_r) y los ángulos angles_spec_deg.
N = numel(angles_spec_deg);
degChar = char(176);   % símbolo ° seguro en MATLAB

% Escala del desplazamiento en función del tamaño de la figura
rangeX = max(allX) - min(allX);
rangeY = max(allY) - min(allY);
s = 0.06 * max(rangeX, rangeY);   % tamaño del offset

% Etiquetar 1..6 y el último (como en tu snippet)
idx_label = unique([1:min(6,N), N]);

for ii = 1:numel(idx_label)
    i = idx_label(ii);

    % Tangente local en el conjunto de puntos discretos
    if i == 1
        t = [xs_r(2)-xs_r(1), ys_r(2)-ys_r(1)];
    elseif i == N
        t = [xs_r(N)-xs_r(N-1), ys_r(N)-ys_r(N-1)];
    else
        t = [xs_r(i+1)-xs_r(i-1), ys_r(i+1)-ys_r(i-1)];
    end

    % Normal unitaria (perpendicular)
    n = [-t(2), t(1)];
    if norm(n) < 1e-12
        n = [1, 0];
    else
        n = n / norm(n);
    end
    off = s * n;

    % Texto con cajita
    text(xs_r(i)+off(1), ys_r(i)+off(2), ...
        sprintf('%.0f%s', angles_spec_deg(i), degChar), ...
        'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1], ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'BackgroundColor', 'w', 'Margin', 2, 'EdgeColor', [0.8 0.8 0.8]);
end

% ---- Tabla de errores por angulo ----
T = table(angles_spec_deg, xs_o, ys_o, xs_r, ys_r, err, ...
    'VariableNames', {'angulo_deg','x_orig','y_orig','x_red','y_red','error_mm'});
disp(T);

% ================== FUNCIONES ==================
function [xICR,yICR,theta2_list,ok_flags] = icr_for_angles(a,b,c,d,A,phiAD,k0,angles_deg)
    A = A(:)';                           
    D = A + d*[cos(phiAD) sin(phiAD)];
    K = (pi/180).*angles_deg(:);
    N = numel(K);
    xICR = nan(N,1); yICR = nan(N,1);
    theta2_list = nan(N,1); ok_flags = false(N,1);
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
            dd = wrap_pi(th2c - th2_prev);
            [~,ix] = min(abs(dd));
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

function ang = wrap_pi(ang)
    ang = mod(ang + pi, 2*pi) - pi;
end
