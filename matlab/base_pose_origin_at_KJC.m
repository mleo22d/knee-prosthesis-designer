% ============================================================
% Obtiene la pose base (κ=0°) del mecanismo de 4 barras, traslada el sistema
% para fijar el origen en el pivote C y genera una figura con coordenadas de
% los pivotes (A,B,D) respecto a C, incluyendo los ángulos de cada eslabón.
% ============================================================

%% ================== CONFIGURACIÓN INICIAL ==================
clear; clc; close all;

% ---- Geometría del mecanismo (caso 2) ----

a=32.4;
b=22.9;
c=48.7;
d=29.0;
phiAD_deg=deg2rad(-6.5);
k0_deg=deg2rad(36.4);
A=[38.3,-21.3];

% ---- Estado base (k = 0°) ----
K_base_deg = 0;

[~,~,geom] = fourbar_icr_plot(a,b,c,d,[], ...
    'KneeFlex', deg2rad(K_base_deg), ...
    'Kappa0',   (k0_deg), ...
    'A',        A, ...
    'PhiAD',    (phiAD_deg), ...
    'ShowPlot', false);

% Pivotes en marco original (pose base)
A0 = geom.A; B0 = geom.B; C0 = geom.C; D0 = geom.D;

% ==========> TRASLADAR SISTEMA: nuevo origen en C (0,0) <==========
T = -C0;
A0 = A0 + T; B0 = B0 + T; C0 = [0 0]; D0 = D0 + T;

%% ================== FIGURA PROFESIONAL =====================
fig = figure('Color','w','Position',[100 100 650 500]);
ax = axes(fig); hold(ax,'on'); axis(ax,'equal'); grid(ax,'on'); box(ax,'on');

% Limites automáticos
allX = [A0(1);B0(1);C0(1);D0(1)];
allY = [A0(2);B0(2);C0(2);D0(2)];
rx = max(allX)-min(allX); ry = max(allY)-min(allY);
pad = 0.2*max(rx,ry);
xlims = [min(allX)-2*pad, max(allX)+2*pad];
ylims = [min(allY)-pad, max(allY)+pad];

% Dibujar mecanismo
plot(ax,[A0(1) B0(1) C0(1) D0(1) A0(1)], ...
        [A0(2) B0(2) C0(2) D0(2) A0(2)], ...
        '-k','LineWidth',1.8);

% Dibujar pivotes
pivotes = [A0; B0; C0; D0];
names   = {'A','B','C','D'};
scatter(ax,pivotes(:,1),pivotes(:,2),90,'k','filled','MarkerEdgeColor','w');

% Etiquetas con coordenadas (respecto a C)
for i=1:4
    if i ~= 3
        txt = sprintf('%s(%.1f, %.1f)',names{i},pivotes(i,1),pivotes(i,2));
        offs = (i==2) * [-15 2] + (i~=2) * [5 2];
        text(pivotes(i,1)+offs(1),pivotes(i,2)+offs(2),txt,'FontWeight','bold','FontSize',10);
    end
end

% Marcar C como origen
scatter(ax,0,0,70,'o','MarkerFaceColor',[0 0.45 0.74],'MarkerEdgeColor',[0 0.45 0.74],'LineWidth',1.8);
text(8,0,'  C (0,0)','FontWeight','bold','Color',[0 0.45 0.74],'FontSize',11);

% Ejes y título
xlabel(ax,'x [mm]'); ylabel(ax,'y [mm]');
title(ax,sprintf('Posición base (\\kappa = %d^\\circ) con origen en C',K_base_deg), ...
      'FontWeight','bold','FontSize',12);
legend(ax,{'4-barras','Pivotes','EKJC'},'Location','northeastoutside');

xlim(ax,xlims); ylim(ax,ylims);

theta_1 = rad2deg(atan((D0(2)-A0(2))/(D0(1)-A0(1))))
theta_2 = 180+rad2deg(atan((B0(2)-A0(2))/(B0(1)-A0(1))))
theta_3 = rad2deg(atan((C0(2)-B0(2))/(C0(1)-B0(1))))
theta_4 = 180+rad2deg(atan((C0(2)-D0(2))/(C0(1)-D0(1))))


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
p.parse(varargin{:});

kneeFlex = p.Results.KneeFlex; kappa0 = p.Results.Kappa0;
branchOpt = lower(p.Results.Branch);
th4_user  = p.Results.Theta4;   A = p.Results.A(:)';

if isempty(p.Results.PhiAD)
    D = p.Results.D(:)'; phiAD = atan2(D(2)-A(2), D(1)-A(1));
else
    phiAD = p.Results.PhiAD; D = A' + d*[cos(phiAD); sin(phiAD)]; D=D(:)';
end
doPlot = logical(p.Results.ShowPlot);

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
            [~,ix]=min(abs(angdiff(th2c, theta2(k-1))));
            theta2(k)=th2c(ix);
        else
            theta2(k)=th2c(1);
        end
    end
else
    theta2 = theta2(:)';  
end

N = numel(theta2);
xICR=nan(1,N); yICR=nan(1,N);
B_all=nan(N,2); C_all=nan(N,2);

for k=1:N
    th2 = theta2(k);
    if ~isempty(kneeFlex)
        th3 = (phiAD + kappa0 + kneeFlex(min(k,numel(kneeFlex))));
        B = A + a*[cos(th2) sin(th2)];
        C = B + b*[cos(th3) sin(th3)];
    else
        if isempty(th4_user)
            [th4a,th4b] = solve_theta4_two_roots(a,b,c,d,th2);
            B = A + a*[cos(th2) sin(th2)];
            Ca = D + c*[cos(th4a) sin(th4a)];
            Cb = D + c*[cos(th4b) sin(th4b)];
            [~,idx] = min([abs(norm(B-Ca)-b), abs(norm(B-Cb)-b)]); %#ok<NODEF>
            if idx==1, C=Ca; else, C=Cb; end
        else
            th4 = th4_user(min(k,numel(th4_user)));
            B = A + a*[cos(th2) sin(th2)];
            C = D + c*[cos(th4) sin(th4)];
        end
    end
    r2 = B - A; r4 = C - D; ts = [r2(:) -r4(:)] \ (D(:) - A(:));
    P  = A + ts(1)*r2; xICR(k)=P(1); yICR(k)=P(2);
    B_all(k,:)=B; C_all(k,:)=C;
end

geom = struct('A',A,'B',B_all(end,:),'C',C_all(end,:),'D',D);
end

% ===== Utilidad: diferencia de ángulos en [-pi,pi]
function d = angdiff(a,b)
d = atan2(sin(a-b), cos(a-b));
end
