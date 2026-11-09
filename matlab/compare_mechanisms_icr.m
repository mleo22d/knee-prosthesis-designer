% ============================================================
% Grafica y compara 3 mecanismos de 4 barras en la pose inicial (KneeFlex=0°),
% mostrando pivotes A-B-C-D y el ICR inicial en subplots lado a lado, con el
% RMSE de cada mecanismo anotado en un recuadro.
% ============================================================

%% ================== CONFIGURACIÓN INICIAL ==================
clear; clc; close all;

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


% Helper
deg2rad = @(x) pi/180.*x;

%% ============ OBTENER GEOMETRÍA EN POSICIÓN INICIAL (KneeFlex = 0) ============
for i = 1:numel(mech)
    a = mech(i).a; b = mech(i).b; c = mech(i).c; d = mech(i).d;
    A = mech(i).A;
    phiAD = deg2rad(mech(i).phiAD_deg);
    kappa0 = deg2rad(mech(i).k0_deg);

    % >>> Cambia esta línea para capturar también el ICR:
    [xICR,yICR,geom] = fourbar_icr_plot(a,b,c,d,[], ...
        'KneeFlex', 0, ...
        'Kappa0', kappa0, ...
        'A', A, ...
        'PhiAD', phiAD, ...
        'ShowPlot', false, ...
        'ShowAngles', false);

    % Guardamos los puntos
    mech(i).Axy = geom.A;
    mech(i).Bxy = geom.B;
    mech(i).Cxy = geom.C;
    mech(i).Dxy = geom.D;

    % >>> Guarda el ICR inicial (primer y único punto con KneeFlex=0)
    mech(i).Pxy = [xICR(1), yICR(1)];
end


%% ================= FIGURA PROFESIONAL (3 CUADROS LADO A LADO) =================
cols = [ 0 0 0;   % azul
         0 0 0;   % naranja
         0 0 0]; % verde

% ====== Límites globales (mismo encuadre para los 3) ======
allX = []; allY = [];
for i=1:numel(mech)
    allX = [allX; mech(i).Axy(1); mech(i).Bxy(1); mech(i).Cxy(1); mech(i).Dxy(1)];
    allY = [allY; mech(i).Axy(2); mech(i).Bxy(2); mech(i).Cxy(2); mech(i).Dxy(2)];
end
rx = max(allX) - min(allX); ry = max(allY) - min(allY);
pad = 0.15*max(rx,ry);
xlims = [min(allX)-3*pad, max(allX)+3*pad];
ylims = [min(allY)-2*pad,   max(allY)+10*pad];

% ====== Layout en fila ======
fig = figure('Color','w','Position',[120 80 1100 480]);
tlo = tiledlayout(fig,1,3,'Padding','compact','TileSpacing','compact');

lwLink = 1.6;   % grosor de eslabones
mkJoint = 28;   % tamaño de marcadores de juntas


for i = 1:numel(mech)
    ax = nexttile(tlo,i); hold(ax,'on'); axis(ax,'equal'); grid(ax,'on'); box(ax,'on');
    col = cols(i,:);

    % Polígono A-B-C-D-A
    X = [mech(i).Axy(1), mech(i).Bxy(1), mech(i).Cxy(1), mech(i).Dxy(1), mech(i).Axy(1)];
    Y = [mech(i).Axy(2), mech(i).Bxy(2), mech(i).Cxy(2), mech(i).Dxy(2), mech(i).Axy(2)];
    plot(ax, X, Y, '-', 'Color', col, 'LineWidth', lwLink);

    % Juntas
    scatter(ax, [mech(i).Axy(1), mech(i).Bxy(1), mech(i).Cxy(1), mech(i).Dxy(1)], ...
                [mech(i).Axy(2), mech(i).Bxy(2), mech(i).Cxy(2), mech(i).Dxy(2)], ...
                mkJoint, 'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', 'LineWidth', 0.6);

    % >>> ICR inicial
    scatter(ax, mech(i).Pxy(1), mech(i).Pxy(2), 70, 'o', ... 
            'MarkerFaceColor', 'k','MarkerEdgeColor', 'k', 'LineWidth', 0.6);
    text(ax, mech(i).Pxy(1), mech(i).Pxy(2), '  ICR', 'FontWeight','bold');

    % (Opcional) Prolongaciones de AB y DC para visualizar el ICR:
    v2 = mech(i).Bxy - mech(i).Axy; v4 = mech(i).Cxy - mech(i).Dxy;
    L  = 5*max([mech(i).a, mech(i).b, mech(i).c, mech(i).d, 1]);
    if norm(v2)>0
      AB = [mech(i).Axy - L*v2/norm(v2); mech(i).Axy + L*v2/norm(v2)];
      plot(ax, AB(:,1), AB(:,2), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
    end
    if norm(v4)>0
      DC = [mech(i).Dxy - L*v4/norm(v4); mech(i).Dxy + L*v4/norm(v4)];
      plot(ax, DC(:,1), DC(:,2), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
    end

    title(ax, sprintf('%s', mech(i).name));
    xlabel(ax,'x [mm]'); ylabel(ax,'y [mm]');
    xlim(ax, xlims); ylim(ax, ylims);

    if isfield(mech(i),'err') && isfinite(mech(i).err)
        err_val = mech(i).err;
    else
        err_val = 0.1;
    end
    str = sprintf('RMSE: %.1f mm', err_val);

    text(ax, 0.95, 0.9, str, ...
        'Units','normalized', ...           % posición relativa al eje
        'HorizontalAlignment','right', ...
        'VerticalAlignment','bottom', ...
        'BackgroundColor','w', ...
        'EdgeColor','k', ...
        'LineWidth',0.8, ...
        'Margin',5, ...
        'FontSize',9);

end

%% ================== PLOT 4-BARRAS (con Kappa0) ===========================
function [xICR,yICR,geom] = fourbar_icr_plot(a,b,c,d,theta2,varargin)
p = inputParser;
p.addParameter('KneeFlex', [], @(x) isempty(x) || isnumeric(x));
p.addParameter('Kappa0', 0, @(x) isscalar(x));
p.addParameter('Branch','auto', @(s) any(strcmpi(s,{'auto','open','crossed'})));
p.addParameter('Theta4', [], @(x) isempty(x) || isnumeric(x));
p.addParameter('A', [0 0], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('D', [d 0], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('PhiAD', [], @(x) isempty(x) || isscalar(x));
p.addParameter('ShowPlot', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('ShowAngles', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('AngleRadius', [], @(x) isempty(x) || isscalar(x));
p.parse(varargin{:});

kneeFlex = p.Results.KneeFlex; kappa0 = p.Results.Kappa0;
branchOpt = lower(p.Results.Branch);
th4_user  = p.Results.Theta4;   A = p.Results.A(:)';

if isempty(p.Results.PhiAD)
    D = p.Results.D(:)'; phiAD = atan2(D(2)-A(2), D(1)-A(1));
else
    phiAD = p.Results.PhiAD; D = A' + d*[cos(phiAD); sin(phiAD)]; D=D(:)';
end
doPlot = logical(p.Results.ShowPlot); showAng = logical(p.Results.ShowAngles);

if ~isempty(kneeFlex)
    theta3 = (phiAD + kappa0 + kneeFlex(:)') ;
    N = numel(theta3); theta2 = nan(1,N);
    for k = 1:N
        th3 = theta3(k);
        u3  = [cos(th3) sin(th3)];
        S   = (D - A) - b*u3; r = norm(S); if r<1e-12, continue; end
        alpha = atan2(S(2),S(1));
        cosDel = (a^2 + r^2 - c^2)/(2*a*r);
        if abs(cosDel)>1, continue; end
        delta = acos(max(-1,min(1,cosDel)));
        th2c = [alpha+delta, alpha-delta];
        if k>1 && ~isnan(theta2(k-1)) && strcmp(branchOpt,'auto')
            [~,ix]=min(abs(wrapToPi_local(th2c - theta2(k-1))));
            theta2(k)=th2c(ix);
        else
            theta2(k)=th2c(1);
        end
    end
else
    theta2 = theta2(:)';  
end

N = numel(theta2);
xICR=nan(1,N); yICR=nan(1,N); theta4=nan(1,N); theta3=nan(1,N);
B_all=nan(N,2); C_all=nan(N,2);

for k=1:N
    th2 = theta2(k);
    if ~isempty(kneeFlex)
        th3 = (phiAD + kappa0 + kneeFlex(min(k,numel(kneeFlex))));
        B = A + a*[cos(th2) sin(th2)];
        C = B + b*[cos(th3) sin(th3)];
        v4 = C - D; theta4(k)=atan2(v4(2),v4(1));
    else
        if isempty(th4_user)
            [th4a,th4b] = solve_theta4_two_roots(a,b,c,d,th2);
            B = A + a*[cos(th2) sin(th2)];
            Ca = D + c*[cos(th4a) sin(th4a)];
            Cb = D + c*[cos(th4b) sin(th4b)];
            [~,idx] = min([abs(norm(B-Ca)-b), abs(norm(B-Cb)-b)]);
            if idx==1, th4=th4a; C=Ca; else, th4=th4b; C=Cb; end
            theta4(k)=th4;
        else
            th4 = th4_user(min(k,numel(th4_user)));
            B = A + a*[cos(th2) sin(th2)];
            C = D + c*[cos(th4) sin(th4)];
            theta4(k)=th4;
        end
        th3 = atan2(C(2)-B(2), C(1)-B(1));
    end
    if isempty(kneeFlex), theta3(k)=th3; else, theta3(k)=(phiAD + kappa0 + kneeFlex(k)); end
    r2 = B - A; r4 = C - D; ts = [r2(:) -r4(:)] \ (D(:) - A(:));
    P  = A + ts(1)*r2; xICR(k)=P(1); yICR(k)=P(2);
    B_all(k,:)=B; C_all(k,:)=C;
end

if doPlot && N>=1
    k=1; B=B_all(k,:); C=C_all(k,:); th2=theta2(k); th3=theta3(k);
    P=[xICR(k) yICR(k)];
    figure; hold on; axis equal; grid on
    plot([A(1) B(1) C(1) D(1) A(1)], [A(2) B(2) C(2) D(2) A(2)], 'o-','LineWidth',2);
    L=5*max([a,b,c,d,1]);
    if norm(B-A)>0, AB=[A - L*(B-A)/norm(B-A); A + L*(B-A)/norm(B-A)]; plot(AB(:,1),AB(:,2),'--'); end
    if norm(C-D)>0, DC=[D - L*(C-D)/norm(C-D); D + L*(C-D)/norm(C-D)]; plot(DC(:,1),DC(:,2),'--'); end
    scatter(P(1),P(2),70,'filled'); text(P(1),P(2),'  ICR','FontWeight','bold');
    text(A(1),A(2),'  A'); text(B(1),B(2),'  B'); text(C(1),C(2),'  C'); text(D(1),D(2),'  D');
    theta_knee = wrapToPi_local(th3 - (phiAD + kappa0));
    title(sprintf(['a=%.2f, b=%.2f, c=%.2f, d=%.2f | ' ...
        '\\phi_{AD}=%.2f° | \\kappa_0=%.2f° | Flexión=%.2f°'], ...
        a,b,c,d, rad2deg(phiAD), rad2deg(kappa0), rad2deg(theta_knee)));
    xlabel('X'); ylabel('Y');
    legend({'AB-BC-CD-DA','Recta AB','Recta DC','ICR'},'Location','best');
end

geom = struct('A',A,'B',B_all(end,:),'C',C_all(end,:),'D',D,'theta2',theta2, ...
              'theta3',theta3,'theta4',theta4,'phiAD',phiAD,'kappa0',kappa0);
end
