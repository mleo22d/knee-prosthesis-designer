% ============================================================
% Anima un mecanismo de 4 barras conducido por la flexión (θ3),
% resolviendo el cierre cinemático para θ2 y simulando un slider
% con amortiguador de longitud fija durante el movimiento.
% ============================================================

clc;
clear variables;
close all;

a=32.4;
b=22.9;
c=48.7;
d=29.0;
phiAD=deg2rad(-6.5);
k0=deg2rad(36.4);
A=[0,0];

% Barrer flexión de rodilla 0→110° en 60 pasos y animar
KneeFlex = deg2rad(linspace(0,110,60));
KneeFlexd = rad2deg(KneeFlex);

[xICR,yICR,geom] = fourbar_icr_plot(a,b,c,d,[], 'A',A,'PhiAD',phiAD, ...
    'KneeFlex',KneeFlex,'K0',k0,'Branch','auto','AngleRadius',15, ...
    'Animate',true,'FramePause',0.03, ...
    'SaveMAT','');  % p.ej.: 'icr_trayectoria.mat'

disp(xICR);
disp(yICR);

% === Plot de |MK| y marcado del mínimo ===
minPoint = findMinPoint(KneeFlexd, geom.MK_length);   % usar MK_length desde geom
figure;
plot(KneeFlexd, geom.MK_length); hold on;
plot(minPoint(1), minPoint(2), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
xlabel('Flexión de rodilla [°]');
ylabel('|MK| [mm]');
title('Longitud de MK vs flexión de rodilla');
grid on; box on; hold off;

% === Nuevo: Ángulo de MK vs Flexión de rodilla ===
fig = figure('Color','w','Position',[120 80 900 650]);
ax  = axes('Parent',fig); hold(ax,'on'); box(ax,'on'); grid(ax,'on');

plot(ax, KneeFlexd, geom.MK_angle_deg, '-', ...
    'Color',[0 0 0], 'LineWidth',1.6, ...
    'DisplayName','\angle(MK) respecto al eje horizontal');

xlabel(ax,'Flexión de rodilla, KneeFlexd [°]');
ylabel(ax,'Ángulo de MK [°]');
title(ax,'Ángulo del vector MK vs. flexión de rodilla');
legend(ax,'Location','best');


%% ===== Función principal (misma lógica + animación opcional) =====
function [xICR,yICR,geom] = fourbar_icr_plot(a,b,c,d,theta2,varargin)
% (… descripción igual …)

% -------- parsing --------
p = inputParser;
p.addParameter('KneeFlex', [], @(x) isempty(x) || isnumeric(x));
p.addParameter('Branch','auto', @(s) any(strcmpi(s,{'auto','open','crossed'})));
p.addParameter('Theta4', [], @(x) isempty(x) || isnumeric(x));
p.addParameter('A', [0 0], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('D', [d 0], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('PhiAD', [], @(x) isempty(x) || isscalar(x));
p.addParameter('ShowPlot', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('ShowAngles', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('AngleRadius', [], @(x) isempty(x) || isscalar(x));
p.addParameter('K0', 0, @(x) isscalar(x) && isfinite(x));
p.addParameter('Theta3Offset', [], @(x) isempty(x) || isscalar(x));
p.addParameter('Animate', false, @(x) islogical(x) || isnumeric(x));
p.addParameter('FramePause', 0.03, @(x) isscalar(x) && x>=0);
p.addParameter('SaveMAT','', @(s) ischar(s) || isstring(s));
p.parse(varargin{:});

kneeFlex = p.Results.KneeFlex;
branchOpt = lower(p.Results.Branch);
th4_user  = p.Results.Theta4;
A         = p.Results.A(:)';
saveMatFn = char(p.Results.SaveMAT);

k0 = p.Results.K0;
if ~isempty(p.Results.Theta3Offset), k0 = p.Results.Theta3Offset; end

if isempty(p.Results.PhiAD)
    D = p.Results.D(:)';  phiAD = atan2(D(2)-A(2), D(1)-A(1));
else
    phiAD = p.Results.PhiAD;
    D = A' + d*[cos(phiAD); sin(phiAD)]; D=D(:)';
end

doPlot   = logical(p.Results.ShowPlot);
showAng  = logical(p.Results.ShowAngles);
animate  = logical(p.Results.Animate);
dt_frame = p.Results.FramePause;

% --- cierre (igual que antes) ---
if ~isempty(kneeFlex)
    theta3 = (phiAD + k0 + kneeFlex(:)') ;
    N = numel(theta3);
    theta2 = nan(1,N);
    for k = 1:N
        th3 = theta3(k);
        u3  = [cos(th3) sin(th3)];
        S   = (D - A) - b*u3;  r = norm(S);
        if r < 1e-12, warning('Geometría degenerada: r ~ 0 para k=%d',k); continue; end
        alpha = atan2(S(2), S(1));
        cosDel = (a^2 + r^2 - c^2)/(2*a*r);
        if abs(cosDel) > 1+1e-12, warning('No hay cierre para flexión k=%d',k); continue; end
        cosDel = max(-1,min(1,cosDel));
        delta = acos(cosDel);
        th2_candidates = [alpha + delta, alpha - delta];
        if k>1 && ~isnan(theta2(k-1)) && strcmp(branchOpt,'auto')
            [~,ix] = min(abs( angleDiff(th2_candidates, theta2(k-1)) ));
            theta2(k) = th2_candidates(ix);
        elseif strcmp(branchOpt,'open')
            theta2(k) = th2_candidates(1);
        elseif strcmp(branchOpt,'crossed')
            theta2(k) = th2_candidates(2);
        else
            theta2(k) = th2_candidates(1);
        end
    end
else
    theta2 = theta2(:)';  
end

N = numel(theta2);
xICR   = nan(1,N); yICR   = nan(1,N);
theta4 = nan(1,N); theta3 = nan(1,N);
B_all  = nan(N,2); C_all  = nan(N,2);
K_all  = nan(N,2);              % almacenar posiciones del punto K
MK_length = nan(1,N);           % almacenar longitud MK
MK_angle_rad = nan(1,N);        % almacenar ángulo MK (rad)

% Definir punto M (ajusta según tu geometría)
M = [A(1), A(2) - 105 + 27.5];

for k=1:N
    th2 = theta2(k);
    if ~isempty(kneeFlex)
        th3 = (phiAD + k0 + kneeFlex(min(k,numel(kneeFlex))));
        B = A + a*[cos(th2) sin(th2)];
        C = B + b*[cos(th3) sin(th3)];
        v4 = C - D;
        if norm(v4) < 1e-9, theta4(k) = NaN; else, theta4(k) = atan2(v4(2), v4(1)); end
    else
        if isempty(th4_user)
            [th4a,th4b] = solve_theta4_two_roots(a,b,c,d,th2);
            B = A + a*[cos(th2) sin(th2)];
            Ca = D + c*[cos(th4a) sin(th4a)];
            Cb = D + c*[cos(th4b) sin(th4b)];
            [~,idx] = min([abs(norm(B-Ca)-b), abs(norm(B-Cb)-b)]);
            if idx==1, th4=th4a; C=Ca; else, th4=th4b; C=Cb; end
            theta4(k) = th4;
        else
            th4 = th4_user(min(k,numel(th4_user)));
            B = A + a*[cos(th2) sin(th2)];
            C = D + c*[cos(th4) sin(th4)];
            theta4(k) = th4;
        end
        th3 = atan2(C(2)-B(2), C(1)-B(1));
    end

    % Intersección de rectas AB y DC => ICR
    r2 = B - A; r4 = C - D;
    ts = [r2(:) -r4(:)] \ (D(:) - A(:));
    P  = A + ts(1)*r2;
    
    theta3(k) = th3;
    xICR(k) = P(1);  yICR(k) = P(2);
    B_all(k,:) = B;  C_all(k,:) = C;
    
    % === POSICIÓN DE K (offset dado, rotado con BC) ===
    theta_5 = 68;
    K_x = 12*sind(theta_5);
    K_y = K_x/tand(theta_5);

    K_offset = [-K_x K_y];
    R = [cos(th3) -sin(th3); sin(th3) cos(th3)];
    K_rotated = (R * K_offset')';
    K_all(k,:) = B + K_rotated;
    
    % === Longitud y ángulo de MK ===
    MK_length(k)    = norm(K_all(k,:) - M);
    MK_angle_rad(k) = atan2(K_all(k,2) - M(2), K_all(k,1) - M(1)); % ángulo respecto a +x
end

% -------- estilos de dibujo --------
Rbase = 0.25*max([a,b,c,d]); Rg = 0.18*max([a,b,c,d]); R3 = 0.22*max([a,b,c,d]);
if ~isempty(p.Results.AngleRadius), Rbase=p.Results.AngleRadius; Rg=0.72*Rbase; R3=0.88*Rbase; end
lwLink = 1.0; lwAux = 0.8; lwArc = 0.9; mkICR = 5;

% Convertir ángulo MK a grados (serie completa)
MK_angle_deg = rad2deg(MK_angle_rad);

if doPlot && N>=1
    if animate && N>1
        % --- ANIMACIÓN ---
        pts = [repmat(A,N,1); B_all; C_all; repmat(D,N,1); [xICR(:) yICR(:)]; K_all; repmat(M,N,1)];
        minx = min(pts(:,1)); maxx = max(pts(:,1));
        miny = min(pts(:,2)); maxy = max(pts(:,2));
        pad = 0.2*max([a,b,c,d]);

        fig = figure('Color','w','Position',[140 80 960 640]);
        ax  = axes('Parent',fig); hold(ax,'on'); axis(ax,'equal'); box(ax,'on');
        grid(ax,'on'); ax.XMinorGrid='on'; ax.YMinorGrid='on';
        set(ax,'LineWidth',1.0,'FontName','Helvetica','FontSize',11, ...
               'TickDir','out','GridAlpha',0.15,'MinorGridAlpha',0.10);
        xlim(ax,[minx-2*1.5*pad, maxx+2*2*pad]); 
        ylim(ax,[miny-pad,maxy+pad]);

        k = 1;
        B = B_all(k,:); C = C_all(k,:); P = [xICR(k) yICR(k)]; K = K_all(k,:);
        hLinks = plot(ax,[A(1) B(1) C(1) D(1) A(1)], [A(2) B(2) C(2) D(2) A(2)], ...
                      'o-','LineWidth',lwLink,'Color',[0 0 0]);
        L = 5*max([a,b,c,d,1]);
        AB_line = [A - L*(B-A)/norm(B-A); A + L*(B-A)/norm(B-A)];
        DC_line = [D - L*(C-D)/norm(C-D); D + L*(C-D)/norm(C-D)];
        hAB = plot(ax, AB_line(:,1), AB_line(:,2), '--','Color',[.3 .3 .3],'LineWidth',lwAux);
        hDC = plot(ax, DC_line(:,1), DC_line(:,2), '--','Color',[.3 .3 .3],'LineWidth',lwAux);
        hICR = plot(ax, P(1),P(2),'o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor','none','MarkerSize',mkICR);
        hK = plot(ax, K(1), K(2), 's','MarkerFaceColor',[1 0 0],'MarkerEdgeColor','none','MarkerSize',6);
        hM = plot(ax, M(1), M(2), 'd','MarkerFaceColor',[0 0.5 0],'MarkerEdgeColor','none','MarkerSize',7);
        hMK = plot(ax, [M(1) K(1)], [M(2) K(2)], '-','Color',[0.8 0.2 0.8],'LineWidth',1.2);

        circle_radius = 8;
        theta_circle = linspace(0, 2*pi, 100);
        x_circle = D(1) + circle_radius * cos(theta_circle);
        y_circle = D(2) + circle_radius * sin(theta_circle);
        hCircle = plot(ax, x_circle, y_circle, '--','Color',[0.2 0.6 0.8],'LineWidth',1.5);

        htA = text(ax, A(1),A(2),'  A');
        htB = text(ax, B(1),B(2),'  B');
        htC = text(ax, C(1),C(2),'  C');
        htD = text(ax, D(1),D(2),'  D');
        htK = text(ax, K(1),K(2),'  K','Color',[1 0 0]);
        htM = text(ax, M(1),M(2),'  M','Color',[0 0.5 0]);

        hArc2 = plot(ax, nan, nan, 'k-','LineWidth',lwArc);
        hArcAD= plot(ax, nan, nan, 'k-','LineWidth',lwAux);
        hArc3 = plot(ax, nan, nan, 'k-','LineWidth',lwArc);

        xlabel(ax,'X [mm]'); ylabel(ax,'Y [mm]');
        lg = legend(ax,[hLinks,hAB,hDC,hICR,hK,hM,hMK,hCircle],{'AB-BC-CD-DA','Recta AB','Recta DC','ICR','Punto K','Punto M','Línea MK','Círculo D (8mm)'}, ...
                    'Location','northeast','Box','on');
        lg.EdgeColor = [0.25 0.25 0.25];

        for k = 1:N
            B = B_all(k,:); C = C_all(k,:); P = [xICR(k) yICR(k)]; K = K_all(k,:);
            th2 = theta2(k); th3 = theta3(k);

            set(hLinks,'XData',[A(1) B(1) C(1) D(1) A(1)],'YData',[A(2) B(2) C(2) D(2) A(2)]);
            if norm(B-A)>0
                AB_line = [A - L*(B-A)/norm(B-A); A + L*(B-A)/norm(B-A)];
                set(hAB,'XData',AB_line(:,1),'YData',AB_line(:,2));
            end
            if norm(C-D)>0
                DC_line = [D - L*(C-D)/norm(C-D); D + L*(C-D)/norm(C-D)];
                set(hDC,'XData',DC_line(:,1),'YData',DC_line(:,2));
            end
            set(hICR,'XData',P(1),'YData',P(2));
            set(hK,'XData',K(1),'YData',K(2));
            set(hMK,'XData',[M(1) K(1)],'YData',[M(2) K(2)]);
            set(htB,'Position',[B(1) B(2) 0]); set(htC,'Position',[C(1) C(2) 0]);
            set(htK,'Position',[K(1) K(2) 0]);

            if ~isnan(th2)
                phi = linspace(0, th2, 120);
                set(hArc2,'XData',A(1)+Rbase*cos(phi),'YData',A(2)+Rbase*sin(phi));
            else, set(hArc2,'XData',nan,'YData',nan); 
            end
            ph = linspace(0, phiAD, 80);
            set(hArcAD,'XData',A(1)+Rg*cos(ph),'YData',A(2)+Rg*sin(ph));

            if ~isnan(th3)
                phi3 = linspace(0, th3, 120);
                set(hArc3,'XData',B(1)+R3*cos(phi3),'YData',B(2)+R3*sin(phi3));
            else, set(hArc3,'XData',nan,'YData',nan);
            end

            drawnow; if dt_frame>0, pause(dt_frame); end
        end

    else
        % --- PLOT ESTÁTICO (última pose) ---
        k = N; B = B_all(k,:); C = C_all(k,:); th2 = theta2(k); th3 = theta3(k); K = K_all(k,:);
        P = [xICR(k) yICR(k)];

        fig = figure('Color','w','Position',[140 80 960 640]);
        ax  = axes('Parent',fig); hold(ax,'on'); axis(ax,'equal'); box(ax,'on');
        grid(ax,'on'); ax.XMinorGrid='on'; ax.YMinorGrid='on';
        set(ax,'LineWidth',1.0,'FontName','Helvetica','FontSize',11, ...
               'TickDir','out','GridAlpha',0.12,'MinorGridAlpha',0.10);

        plot([A(1) B(1) C(1) D(1) A(1)],[A(2) B(2) C(2) D(2) A(2)], ...
             'o-','LineWidth',lwLink,'Color',[0 0 0]);

        L = 5*max([a,b,c,d,1]);
        if norm(B-A) > 0
            AB_line = [A - L*(B-A)/norm(B-A); A + L*(B-A)/norm(B-A)];
            plot(AB_line(:,1), AB_line(:,2), '--','Color',[.3 .3 .3],'LineWidth',lwAux);
        end
        if norm(C-D) > 0
            DC_line = [D - L*(C-D)/norm(C-D); D + L*(C-D)/norm(C-D)];
            plot(DC_line(:,1), DC_line(:,2), '--','Color',[.3 .3 .3],'LineWidth',lwAux);
        end

        scatter(P(1),P(2),55,'filled','MarkerFaceColor',[0 0 0],'MarkerEdgeColor','none');
        scatter(K(1),K(2),40,'filled','MarkerFaceColor',[1 0 0],'MarkerEdgeColor','none');
        scatter(M(1),M(2),45,'filled','MarkerFaceColor',[0 0.5 0],'MarkerEdgeColor','none');
        plot([M(1) K(1)], [M(2) K(2)], '-','Color',[0.8 0.2 0.8],'LineWidth',1.2);

        circle_radius = 4;
        theta_circle = linspace(0, 2*pi, 100);
        x_circle = D(1) + circle_radius * cos(theta_circle);
        y_circle = D(2) + circle_radius * sin(theta_circle);
        plot(x_circle, y_circle, '--','Color',[0.2 0.6 0.8],'LineWidth',1.5);
        
        text(A(1),A(2),'  A'); text(B(1),B(2),'  B'); text(C(1),C(2),'  C'); text(D(1),D(2),'  D');
        text(K(1),K(2),'  K','Color',[1 0 0]);
        text(M(1),M(2),'  M','Color',[0 0.5 0]);

        if ~isnan(th2)
            phi = linspace(0, th2, 120);
            plot(A(1)+Rbase*cos(phi), A(2)+Rbase*sin(phi), 'k-','LineWidth',lwArc);
            plot([A(1) A(1)+Rbase],[A(2) A(2)],'k:');
            tpos = A + 1.05*Rbase*[cos(th2/2) sin(th2/2)];
            text(tpos(1),tpos(2),'\theta_2','FontWeight','bold');
        end
        ph = linspace(0, phiAD, 80);
        plot(A(1)+Rg*cos(ph), A(2)+Rg*sin(ph), 'k-','LineWidth',lwAux);
        plot([A(1) A(1)+Rg],[A(2) A(2)],'k:');
        if ~isnan(th3)
            phi3 = linspace(0, th3, 120);
            plot(B(1)+R3*cos(phi3), B(2)+R3*sin(phi3), 'k-','LineWidth',lwArc);
        end

        theta_knee = wrapToPi_local(th3 - (phiAD + k0));
        title(ax, sprintf(['a=%.1f, b=%.1f, c=%.1f, d=%.1f | ' ...
            '\\theta_2=%.1f°, \\phi_{AD}=%.1f° | k_0=%.1f° | Flexión=%.1f° | MK=%.2f mm'], ...
            a,b,c,d, rad2deg(th2), rad2deg(phiAD), rad2deg(k0), rad2deg(theta_knee), MK_length(k)));

        lg = legend(ax,{'AB-BC-CD-DA','Recta AB','Recta DC','ICR','Punto K','Punto M','Línea MK','Círculo D (8mm)'}, ...
                    'Location','northeast','Box','on');
        lg.EdgeColor = [0.25 0.25 0.25];
        xlabel(ax,'X [mm]'); ylabel(ax,'Y [mm]');
    end
end

% -------- salida / exportación de ICR (igual) --------
theta_knee_series = wrapToPi_local(theta3 - (phiAD + k0));
KneeFlex_deg = rad2deg(theta_knee_series);
assignin('base','ICR_x', xICR(:));
assignin('base','ICR_y', yICR(:));
assignin('base','ICR_xy', [xICR(:), yICR(:)]);
assignin('base','KneeFlex_deg', KneeFlex_deg(:));

% Exportar MK (longitud y ángulo) al workspace
assignin('base','MK_length',    MK_length(:));
assignin('base','MK_angle_deg', rad2deg(MK_angle_rad(:)));

if ~isempty(saveMatFn)
    try
        KneeFlex_rad = theta_knee_series(:);
        MK_angle_deg = rad2deg(MK_angle_rad(:)); %#ok<NASGU>
        save(saveMatFn,'xICR','yICR','KneeFlex_deg','KneeFlex_rad','MK_length','MK_angle_deg');
    catch ME
        warning('No se pudo guardar %s: %s', saveMatFn, ME.message);
    end
end

geom = struct('A',A,'B',B_all(end,:),'C',C_all(end,:),'D',D, ...
              'theta2',theta2,'theta3',theta3,'theta4',theta4,'phiAD',phiAD, ...
              'k0',k0,'theta_knee', theta_knee_series, ...
              'xICR', xICR(:), 'yICR', yICR(:), 'KneeFlex_deg', KneeFlex_deg(:), ...
              'M',M,'MK_length',MK_length(:), ...
              'MK_angle_deg', rad2deg(MK_angle_rad(:)));  % <-- NUEVO
end

%% ===== Helpers =====
function [th4a,th4b] = solve_theta4_two_roots(a,b,c,d,th2)
k1=d/a; k2=d/c; k3=(a^2 + c^2 + d^2 - b^2)/(2*a*c);
Aeq = k3 - k1 + (k2 - 1)*cos(th2); Beq = -2*sin(th2);
Ceq = k3 + k1 + (k2 + 1)*cos(th2);
disc = max(Beq.^2 - 4*Aeq.*Ceq, 0);
t1 = (-Beq + sqrt(disc))/(2*Aeq); t2 = (-Beq - sqrt(disc))/(2*Aeq);
th4a = 2*atan(t1); th4b = 2*atan(t2);
end

function d = angleDiff(angVec, ref)
angVec = wrapToPi_local(angVec); ref = wrapToPi_local(ref);
d = wrapToPi_local(angVec - ref);
end

function ang = wrapToPi_local(ang)
if exist('wrapToPi','file') == 2, ang = wrapToPi(ang);
else, ang = mod(ang + pi, 2*pi) - pi; end
end


%% ===== mínimo =====
function minPoint = findMinPoint(x, y)
% findMinPoint  Returns coordinates of the minimum value in y
%
%   minPoint = findMinPoint(x, y)
%
%   Inputs:
%       x - array of x values
%       y - array of y values (same length as x)
%
%   Output:
%       minPoint - [x_min, y_min], where y_min = min(y)

    % Validate input sizes
    if numel(x) ~= numel(y)
        error('x and y must be the same length.');
    end

    % Find index of minimum y
    [y_min, idx_min] = min(y(:), [], 'omitnan');

    % Get corresponding x value
    x_min = x(idx_min);

    % Return as a row vector
    minPoint = [x_min, y_min];
end