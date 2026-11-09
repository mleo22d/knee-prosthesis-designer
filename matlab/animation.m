% ============================================================
% Genera la trayectoria del ICR de un mecanismo de 4 barras al barrer la
% flexión de rodilla (0–110°), mostrando una animación y exportando el ICR
% y la flexión equivalente para análisis/validación del diseño.
% ============================================================

%% ===== Ejemplo de uso (animación por flexión) =====
clear; close all; clc;

a=32.371;
b=22.887;
c=48.720;
d=28.959;
phiAD=deg2rad(-6.528);
k0=deg2rad(36.417);
A=[38.269,-21.303];

% Barrer flexión de rodilla 0→110° en 60 pasos y animar
KneeFlex = deg2rad(linspace(0,110,60));
[xICR,yICR,geom] = fourbar_icr_plot(a,b,c,d,[], 'A',A,'PhiAD',phiAD, ...
    'KneeFlex',KneeFlex,'K0',k0,'Branch','auto','AngleRadius',15, ...
    'Animate',true,'FramePause',0.03, ...
    'SaveMAT','');  % p.ej.: 'icr_trayectoria.mat'

disp(xICR);
disp(yICR)

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

    r2 = B - A; r4 = C - D;
    ts = [r2(:) -r4(:)] \ (D(:) - A(:));
    P  = A + ts(1)*r2;

    theta3(k) = th3;
    xICR(k) = P(1);  yICR(k) = P(2);
    B_all(k,:) = B;  C_all(k,:) = C;
end

% -------- estilos de dibujo (finos/pro) --------
Rbase = 0.25*max([a,b,c,d]); Rg = 0.18*max([a,b,c,d]); R3 = 0.22*max([a,b,c,d]);
if ~isempty(p.Results.AngleRadius), Rbase=p.Results.AngleRadius; Rg=0.72*Rbase; R3=0.88*Rbase; end
lwLink = 1.0; lwAux = 0.8; lwArc = 0.9; mkICR = 5;

if doPlot && N>=1
    if animate && N>1
        % --- ANIMACIÓN (una figura, handles) ---
        pts = [repmat(A,N,1); B_all; C_all; repmat(D,N,1); [xICR(:) yICR(:)]];
        minx = min(pts(:,1)); maxx = max(pts(:,1));
        miny = min(pts(:,2)); maxy = max(pts(:,2));
        pad = 0.2*max([a,b,c,d]);

        fig = figure('Color','w','Position',[140 80 960 640]);
        ax  = axes('Parent',fig); hold(ax,'on'); axis(ax,'equal'); box(ax,'on');
        grid(ax,'on'); ax.XMinorGrid='on'; ax.YMinorGrid='on';
        set(ax,'LineWidth',1.0,'FontName','Helvetica','FontSize',11, ...
               'TickDir','out','GridAlpha',0.15,'MinorGridAlpha',0.10);
        xlim(ax,[minx-2*pad, maxx+2*pad]); ylim(ax,[miny-pad, maxy+pad]);

        k = 1;
        B = B_all(k,:); C = C_all(k,:); P = [xICR(k) yICR(k)];
        hLinks = plot(ax,[A(1) B(1) C(1) D(1) A(1)], [A(2) B(2) C(2) D(2) A(2)], ...
                      'o-','LineWidth',lwLink,'Color',[0 0 0]);
        L = 5*max([a,b,c,d,1]);
        AB_line = [A - L*(B-A)/norm(B-A); A + L*(B-A)/norm(B-A)];
        DC_line = [D - L*(C-D)/norm(C-D); D + L*(C-D)/norm(C-D)];
        hAB = plot(ax, AB_line(:,1), AB_line(:,2), '--','Color',[.3 .3 .3],'LineWidth',lwAux);
        hDC = plot(ax, DC_line(:,1), DC_line(:,2), '--','Color',[.3 .3 .3],'LineWidth',lwAux);
        hICR = plot(ax, P(1),P(2),'o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor','none','MarkerSize',mkICR);

        htA = text(A(1),A(2),'  A','Parent',ax);
        htB = text(B(1),B(2),'  B','Parent',ax);
        htC = text(C(1),C(2),'  C','Parent',ax);
        htD = text(D(1),D(2),'  D','Parent',ax);

        hArc2 = plot(ax, nan, nan, 'k-','LineWidth',lwArc);
        hArcAD= plot(ax, nan, nan, 'k-','LineWidth',lwAux);
        hArc3 = plot(ax, nan, nan, 'k-','LineWidth',lwArc);

        xlabel(ax,'X [mm]'); ylabel(ax,'Y [mm]');
        lg = legend(ax,[hLinks,hAB,hDC,hICR],{'AB-BC-CD-DA','Recta AB','Recta DC','ICR'}, ...
                    'Location','northeast','Box','on');
        lg.EdgeColor = [0.25 0.25 0.25];

        for k = 1:N
            B = B_all(k,:); C = C_all(k,:); P = [xICR(k) yICR(k)];
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
            set(htB,'Position',[B(1) B(2) 0]); set(htC,'Position',[C(1) C(2) 0]);

            if ~isnan(th2)
                phi = linspace(0, th2, 120);
                set(hArc2,'XData',A(1)+Rbase*cos(phi),'YData',A(2)+Rbase*sin(phi));
            else, set(hArc2,'XData',nan,'YData',nan); end
            ph = linspace(0, phiAD, 80);
            set(hArcAD,'XData',A(1)+Rg*cos(ph),'YData',A(2)+Rg*sin(ph));

            if ~isnan(th3)
                phi3 = linspace(0, th3, 120);
                set(hArc3,'XData',B(1)+R3*cos(phi3),'YData',B(2)+R3*sin(phi3));
            else, set(hArc3,'XData',nan,'YData',nan); end

            theta_knee = wrapToPi_local(th3 - (phiAD + k0));
            title(ax, sprintf(['a=%.1f, b=%.1f, c=%.1f, d=%.1f | ' ...
                '\\theta_2=%.1f°, \\phi_{AD}=%.1f° | k_0=%.1f° | Flexión=%.1f°'], ...
                a,b,c,d, rad2deg(th2), rad2deg(phiAD), rad2deg(k0), rad2deg(theta_knee)));

            drawnow; if dt_frame>0, pause(dt_frame); end
        end

    else
        % --- PLOT ESTÁTICO (última pose) ---
        k = N; B = B_all(k,:); C = C_all(k,:); th2 = theta2(k); th3 = theta3(k);
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
        text(A(1),A(2),'  A'); text(B(1),B(2),'  B'); text(C(1),C(2),'  C'); text(D(1),D(2),'  D');

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
            '\\theta_2=%.1f°, \\phi_{AD}=%.1f° | k_0=%.1f° | Flexión=%.1f°'], ...
            a,b,c,d, rad2deg(th2), rad2deg(phiAD), rad2deg(k0), rad2deg(theta_knee)));

        lg = legend(ax,{'AB-BC-CD-DA','Recta AB','Recta DC','ICR'}, ...
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

if ~isempty(saveMatFn)
    try
        KneeFlex_rad = theta_knee_series(:);
        save(saveMatFn,'xICR','yICR','KneeFlex_deg','KneeFlex_rad');
    catch ME
        warning('No se pudo guardar %s: %s', saveMatFn, ME.message);
    end
end

geom = struct('A',A,'B',B_all(end,:),'C',C_all(end,:),'D',D, ...
              'theta2',theta2,'theta3',theta3,'theta4',theta4,'phiAD',phiAD, ...
              'k0',k0,'theta_knee', theta_knee_series, ...
              'xICR', xICR(:), 'yICR', yICR(:), 'KneeFlex_deg', KneeFlex_deg(:));
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
