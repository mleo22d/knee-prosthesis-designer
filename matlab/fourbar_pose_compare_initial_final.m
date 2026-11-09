% ============================================================
% Compara el mecanismo de 4 barras en dos poses (flexión inicial y final),
% calculando el ICR en cada caso y generando una figura lado a lado para
% visualizar la configuración y las rectas AB/DC con su intersección.
% ============================================================

%% ================== CONFIGURACIÓN INICIAL ==================
clear; clc;

% ---- Mejor mecanismo (usa también A, phiAD y k0 del caso 2) ----
a=32.4; 
b=22.9; 
c=48.7; 
d=29.0;
A=[38.3 -21.3];
phiAD_deg=deg2rad(-6.5); 
k0_deg=deg2rad(36.4);

% Ángulos de flexión (inicial y final)
K_init_deg  = 0;
K_final_deg = 110;

%deg2rad = @(x) pi/180.*x;

% ---- Geometrías (inicial/final) e ICRs ----
[x0,y0,g0] = fourbar_icr_plot(a,b,c,d,[], ...
    'KneeFlex', K_init_deg*pi/180, ...
    'Kappa0',   (k0_deg), ...
    'A',        A, ...
    'PhiAD',    (phiAD_deg), ...
    'ShowPlot', false, 'ShowAngles', false);

[xf,yf,gf] = fourbar_icr_plot(a,b,c,d,[], ...
    'KneeFlex', K_final_deg*pi/180, ...
    'Kappa0',   (k0_deg), ...
    'A',        A, ...
    'PhiAD',    (phiAD_deg), ...
    'ShowPlot', false, 'ShowAngles', false);

% Guardar ICRs y juntas
P0 = [x0(1) y0(1)]; Pf = [xf(end) yf(end)];
A0=g0.A; B0=g0.B; C0=g0.C; D0=g0.D;
Af=gf.A; Bf=gf.B; Cf=gf.C; Df=gf.D;

%% ================= FIGURA: IZQ=INICIAL, DER=FINAL ============
col = [0 0 0];        % negro
lwLink = 1.6;         % grosor de eslabones
mkJoint = 28;         % tamaño de juntas
mkICR   = 70;

% Límites comunes (considera ambas poses)
allX = [A0(1);B0(1);C0(1);D0(1); Af(1);Bf(1);Cf(1);Df(1); P0(1); Pf(1)];
allY = [A0(2);B0(2);C0(2);D0(2); Af(2);Bf(2);Cf(2);Df(2); P0(2); Pf(2)];
rx = max(allX)-min(allX); ry = max(allY)-min(allY);
pad = 0.15*max(rx,ry);
xlims = [min(allX)-2*pad, max(allX)+2*pad];
ylims = [min(allY)-pad,   max(allY)+pad];

fig = figure('Color','w','Position',[120 80 700 440]);
tlo = tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');

% ---------- Tile 1: Inicial ----------
ax1 = nexttile(tlo,1); hold(ax1,'on'); axis(ax1,'equal'); grid(ax1,'on'); box(ax1,'on');
X = [A0(1) B0(1) C0(1) D0(1) A0(1)];
Y = [A0(2) B0(2) C0(2) D0(2) A0(2)];
plot(ax1, X, Y, '-', 'Color', col, 'LineWidth', lwLink);
scatter(ax1, [A0(1) B0(1) C0(1) D0(1)], [A0(2) B0(2) C0(2) D0(2)], ...
        mkJoint, 'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', 'LineWidth',0.6);
scatter(ax1, P0(1), P0(2), mkICR, 'o', 'MarkerFaceColor','k', 'MarkerEdgeColor','k');
text(ax1, P0(1), P0(2), '  ICR', 'FontWeight','bold');

% Prolongaciones AB y DC
v2 = B0 - A0; v4 = C0 - D0; L = 5*max([a,b,c,d,1]);
if norm(v2)>0
    AB = [A0 - L*v2/norm(v2); A0 + L*v2/norm(v2)];
    plot(ax1, AB(:,1), AB(:,2), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
end
if norm(v4)>0
    DC = [D0 - L*v4/norm(v4); D0 + L*v4/norm(v4)];
    plot(ax1, DC(:,1), DC(:,2), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
end

title(ax1, sprintf('(a) Posición inicial (\\kappa = %d^\\circ)', K_init_deg));
xlabel(ax1,'x [mm]'); ylabel(ax1,'y [mm]');
xlim(ax1, xlims); ylim(ax1, ylims);

% ---------- Tile 2: Final ----------
ax2 = nexttile(tlo,2); hold(ax2,'on'); axis(ax2,'equal'); grid(ax2,'on'); box(ax2,'on');
X = [Af(1) Bf(1) Cf(1) Df(1) Af(1)];
Y = [Af(2) Bf(2) Cf(2) Df(2) Af(2)];
plot(ax2, X, Y, '-', 'Color', col, 'LineWidth', lwLink);
scatter(ax2, [Af(1) Bf(1) Cf(1) Df(1)], [Af(2) Bf(2) Cf(2) Df(2)], ...
        mkJoint, 'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', 'LineWidth',0.6);
scatter(ax2, Pf(1), Pf(2), mkICR, 'o', 'MarkerFaceColor','k', 'MarkerEdgeColor','k');
text(ax2, Pf(1), Pf(2), '  ICR', 'FontWeight','bold');

v2 = Bf - Af; v4 = Cf - Df;
if norm(v2)>0
    AB = [Af - L*v2/norm(v2); Af + L*v2/norm(v2)];
    plot(ax2, AB(:,1), AB(:,2), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
end
if norm(v4)>0
    DC = [Df - L*v4/norm(v4); Df + L*v4/norm(v4)];
    plot(ax2, DC(:,1), DC(:,2), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
end

title(ax2, sprintf('(b) Posición final (\\kappa = %d^\\circ)', K_final_deg));
xlabel(ax2,'x [mm]'); ylabel(ax2,'y [mm]');
xlim(ax2, xlims); ylim(ax2, ylims);



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
