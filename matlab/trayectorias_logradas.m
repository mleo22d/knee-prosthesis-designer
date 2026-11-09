% ============================================================
% Compara la trayectoria ICR deseada con 3 mecanismos de 4 barras
% ============================================================

clear; close all; clc

%% ===== Trayectoria ICR deseada (11 puntos) =====
x_icr_deseado = [6.13490347474404	62.2695231098297	70.9468789169059	72.4182357498424	71.8532509929859	70.6471623831769	69.2492168917742	67.8076441690706	66.3641980882459	64.9217623960490	63.4699836641558	61.9956297888261	60.4870493638864	58.9362585880450	57.3400137415931];
y_icr_deseado = [170.661103495049	75.1911775800121	45.6019614604225	29.8671566238485	20.2735695261008	13.9822971780635	9.65313908609947	6.56941303991253	4.31487915235749	2.63172757602255	1.35112198593117	0.356603244319228	-0.436275672803053	-1.09171905071370	-1.66061807622522];

x_des = x_icr_deseado(:);
y_des = y_icr_deseado(:);

% Ángulos que quieres resaltar
angles_spec_deg = linspace(0,110,15);

% Malla para curvas completas (≈60 puntos)
flex_grid_deg = linspace(0,110,60);

%% ===== Mecanismos (3 casos) =====
% Formato: [a b c d Ax Ay phiAD_deg k0_deg]
mech = struct([]);

mech(1).name = '(a) Mecanismo 1';
mech(1).a = 32.614; mech(1).b = 20.000; mech(1).c = 39.315; mech(1).d = 22.48;
mech(1).flex = 0;
mech(1).A = [45.438, -23.348]; mech(1).phiAD_deg = 17.943; mech(1).k0_deg = (20.219+mech(1).flex);
mech(1).err = 1.683;

mech(2).name = '(b) Mecanismo 2'; %%EL QUE VAMOS A USAR
mech(2).a = 32.371; mech(2).b = 22.887; mech(2).c = 48.720; mech(2).d = 28.959;
mech(2).flex = 0;
mech(2).A = [38.269, -21.303]; mech(2).phiAD_deg = -6.528; mech(2).k0_deg = (36.417+mech(2).flex);
mech(2).err = 3.018;

mech(3).name = '(c) Mecanismo 3';
mech(3).a = 30.011; mech(3).b = 23.438; mech(3).c = 45.000; mech(3).d = 26.267;
mech(3).flex = 0;
mech(3).A = [44.214, -19.596]; mech(3).phiAD_deg = 4.435; mech(3).k0_deg = (36.334+mech(3).flex);
mech(3).err = 2.825;

% Colores para los 3 casos
cols = [ 0.00 0.45 0.74;   % azul
         0.85 0.33 0.10;   % naranja
         0.49 0.18 0.56 ]; % morado

% Cálculo de trayectorias
for i = 1:numel(mech)
    a=mech(i).a; b=mech(i).b; c=mech(i).c; d=mech(i).d;
    A=mech(i).A; phiAD=deg2rad(mech(i).phiAD_deg); k0=deg2rad(mech(i).k0_deg);

    % Curva completa (malla de 60 puntos)
    [xg, yg] = icr_for_angles(a,b,c,d,A,phiAD,k0,flex_grid_deg);
    mech(i).x_grid = xg(:); mech(i).y_grid = yg(:);

    % Puntos a resaltar (ángulos específicos)
    [xs, ys] = icr_for_angles(a,b,c,d,A,phiAD,k0,angles_spec_deg);
    mech(i).x_spec = xs(:); mech(i).y_spec = ys(:);
end

%% ===== Figura profesional (líneas finas + leyenda a la derecha, 4 ítems) =====
fig = figure('Color','w','Position',[120 80 1000 640]);   % un poco más ancha
ax  = axes(fig); hold(ax,'on'); axis(ax,'equal'); grid(ax,'on'); box(ax,'on');

% Estilos más finos
lwDes = 1.2;  mkDes = 5;     % deseada
lwFit = 1.0;  mkFit = 4.5;   % mecanismos

% 1) Trayectoria deseada (discreta)
pDes = plot(ax, x_des, y_des, '-o', ...
    'Color',[0 0 0], 'LineWidth', lwDes, 'MarkerSize', mkDes, ...
    'DisplayName','ICR deseado');

% 2) Curvas de los mecanismos + marcadores en ángulos específicos
hCurve = gobjects(1,numel(mech));   % guarda handles de las curvas
for i = 1:numel(mech)
    col = cols(i,:);
    % curva completa (más fina)
    hCurve(i) = plot(ax, mech(i).x_grid, mech(i).y_grid, '-', ...
        'Color', col, 'LineWidth', lwFit, ...
        'DisplayName', sprintf('Mecanismo %d', i));
    % puntos especiales (sin aparecer en la leyenda)
    scatter(ax, mech(i).x_spec, mech(i).y_spec, 36, ...
        'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', 'LineWidth', 0.6, ...
        'HandleVisibility','off');
end

% Ejes y título
xlabel(ax,'x [mm]'); 
ylabel(ax,'y [mm]');

% Límites con margen (igual que antes)
allX = x_des(:); allY = y_des(:);
for i=1:numel(mech)
    allX = [allX; mech(i).x_grid(:); mech(i).x_spec(:)];
    allY = [allY; mech(i).y_grid(:); mech(i).y_spec(:)];
end
mask = ~isnan(allX) & ~isnan(allY);
rx = max(allX(mask)) - min(allX(mask));
ry = max(allY(mask)) - min(allY(mask));
pad = 0.15*max(rx,ry);
xlim(ax,[min(allX(mask))-pad*1.5, max(allX(mask))+pad*1.5]);
ylim(ax,[min(allY(mask))-pad, max(allY(mask))+pad]);

% === Leyenda DENTRO del eje, con marco y SOLO 4 nombres ===
lg = legend(ax, [pDes, hCurve], ...
    {'ICR deseado','Mecanismo 1','Mecanismo 2','Mecanismo 3'}, ...
    'Location','northeast', ...   % dentro del recuadro de ejes
    'Box','on', ...               % con borde
    'NumColumns',1);
lg.EdgeColor = [0.25 0.25 0.25];  % color del borde (opcional)
lg.Color     = [1 1 1];           % fondo blanco (opcional)



%% ======== Funciones ========

function [xICR,yICR,theta2_list,ok_flags] = icr_for_angles(a,b,c,d,A,phiAD,k0,angles_deg)
    % ICR para lista de flexiones (grados) respecto a (phiAD + k0)
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
