% ============================================================
% Ajuste robusto de un mecanismo de 4 barras a una trayectoria
% objetivo del Centro Instantáneo de Rotación (ICR) usando IRLS
% con pérdida Huber y estrategia multistart.
% ============================================================

%% ==== Ajuste de 4-barras a ICR deseado (IRLS + multistart, con pesos) ====
clear; close all; clc

% ----- Datos del ICR objetivo --------------------------------------------
x_icr_deseado = [6.13490347474404	62.2695231098297	70.9468789169059	72.4182357498424	71.8532509929859	70.6471623831769	69.2492168917742	67.8076441690706	66.3641980882459	64.9217623960490	63.4699836641558	61.9956297888261	60.4870493638864	58.9362585880450	57.3400137415931];
y_icr_deseado = [170.661103495049	75.1911775800121	45.6019614604225	29.8671566238485	20.2735695261008	13.9822971780635	9.65313908609947	6.56941303991253	4.31487915235749	2.63172757602255	1.35112198593117	0.356603244319228	-0.436275672803053	-1.09171905071370	-1.66061807622522];

Pdes = [x_icr_deseado(:), y_icr_deseado(:)];
N    = size(Pdes,1);

% ----- Flexión asociada a cada punto -------------------------------------
Kdeg = linspace(0,90,N);
K    = deg2rad(Kdeg(:));           % κ_i

% ----- PESOS DEL USUARIO (priorizar primeros 5 puntos) -------------------
w_user = ones(N,1);
%w_user(1:5) = 3.0;

% ----- Semilla p0 ---------------------------------------------------------
A0 = [40 -20];
kappa0_0 = deg2rad(35.07);
p0 = [32.9, 22.5, 49.1, 29.7, deg2rad(-7.95), kappa0_0, A0];   % [a b c d phiAD kappa0 Ax Ay]

% ----- Opciones de optimización ------------------------------------------
opts.num_starts      = 10;
opts.maxIt           = 10;
opts.mu0             = 1e-3;
opts.huber_delta     = 150.0;     % mm
opts.line_search     = true;

% Límites individuales por barra [a b c d] (mm)
opts.LMINv = [30 20 45 25];
opts.LMAXv = [35 25 55 35];

opts.kappa0_min      = deg2rad(25);
opts.kappa0_max      = deg2rad(45);
opts.padA            = 100;

% Límites para φ_AD
opts.phiAD_min = deg2rad(-15);
opts.phiAD_max = deg2rad(-5);

% ----- Ajuste robusto multistart -----------------------------------------
[p_opt, best] = fit_fourbar_icr_ms(Pdes, K, p0, opts, w_user);

% ----- Reporte -----------------------------------------------------------
a=p_opt(1); b=p_opt(2); c=p_opt(3); d=p_opt(4);
phiAD=p_opt(5); kappa0=p_opt(6); A=[p_opt(7) p_opt(8)];
fprintf(['a=%.3f, b=%.3f, c=%.3f, d=%.3f, phiAD=%.3f°,' ...
         ' kappa0=%.3f° (θ3_0=%.3f°), A=(%.3f, %.3f)\n'], ...
        a,b,c,d, rad2deg(phiAD), rad2deg(kappa0), rad2deg(phiAD+kappa0), A(1),A(2));

% ----- Validación visual -------------------------------------------------
[xf,yf] = fourbar_icr_plot(a,b,c,d,[], 'A',A,'PhiAD',phiAD, ...
    'KneeFlex',K,'Kappa0',kappa0,'Branch','auto','ShowPlot',false);
figure; hold on; axis equal; grid on
plot(x_icr_deseado, y_icr_deseado, 'o','MarkerSize',6,'DisplayName','ICR deseado');
plot(xf, yf, '-x','LineWidth',1.4,'DisplayName','ICR ajustado');
xlabel('X [mm]'); ylabel('Y [mm]'); legend('Location','best');
title('Trayectoria ICR: deseado vs ajustado (pesos 3× en 5 primeros)')

% ----- Mecanismo en la POSE INICIAL --------------------------------------
fourbar_icr_plot(a,b,c,d,[], 'A',A,'PhiAD',phiAD,'KneeFlex',K,'Kappa0',kappa0, ...
    'Branch','auto','AngleRadius',12,'ShowPlot',true);

%% ===== Métricas de error vs trayectoria deseada ==========================
% Error punto a punto (mm)
dx = xf(:) - x_icr_deseado(:);
dy = yf(:) - y_icr_deseado(:);
err = hypot(dx, dy);
mask = isfinite(err);

% Métricas absolutas
rmse = sqrt(mean(err(mask).^2));
mae  = mean(abs(err(mask)));
emax = max(err(mask));
Nval = sum(mask);

% Escalas de referencia del conjunto deseado
dx_range = max(x_icr_deseado) - min(x_icr_deseado);
dy_range = max(y_icr_deseado) - min(y_icr_deseado);
L_range  = max(dx_range, dy_range);

Pdes = [x_icr_deseado(:) y_icr_deseado(:)];
L_diam = 0;
for ii = 1:size(Pdes,1)
    for jj = ii+1:size(Pdes,1)
        dij = hypot(Pdes(ii,1)-Pdes(jj,1), Pdes(ii,2)-Pdes(jj,2));
        if dij > L_diam, L_diam = dij; end
    end
end

% Métricas relativas (%)
rmse_pct_range = 100 * rmse / L_range;
rmse_pct_diam  = 100 * rmse / L_diam;

% Reporte
fprintf('\n=== Error ICR (ajustado vs deseado) ===\n');
fprintf('RMSE = %.3f mm | MAE = %.3f mm | MaxErr = %.3f mm | N = %d\n', rmse, mae, emax, Nval);
fprintf('RMSE%%%% (rango) = %.2f%%%% | RMSE%%%% (diámetro) = %.2f%%%%\n', rmse_pct_range, rmse_pct_diam);

%% ================== MULTISTART ==========================================
function [p_best, best] = fit_fourbar_icr_ms(Pdes, K, p0, opts, w_user)
    pad  = opts.padA;
    boxA = [min(Pdes(:,1))-pad, max(Pdes(:,1))+pad, ...
            min(Pdes(:,2))-pad, max(Pdes(:,2))+pad];

    best.rn = inf; best.it = 0; p_best = p0;

    for s=1:opts.num_starts
        if s==1
            p_init = p0;
        else
            % Semilla aleatoria dentro de límites
            p_init = p0;
            p_init(1:4) = opts.LMINv + (opts.LMAXv - opts.LMINv).*rand(1,4);
            p_init(5)   = opts.phiAD_min + (opts.phiAD_max - opts.phiAD_min)*rand;  % φAD en rango
            p_init(6) = min(max(p0(6) + deg2rad(15)*(2*rand-1), opts.kappa0_min), opts.kappa0_max);
            p_init(7:8) = p0(7:8) + 40*(2*rand(1,2)-1);                               % A perturbado
        end

        % Recorte de salvaguarda (todas las variables)
        p_init = project_bounds(p_init, opts.LMINv, opts.LMAXv, opts.kappa0_min, opts.kappa0_max, boxA, opts.phiAD_min, opts.phiAD_max);

        [p_loc, hist] = fit_fourbar_icr(Pdes, K, p_init, opts, boxA, w_user);
        if hist.rn < best.rn
            best = hist; p_best = p_loc;
        end
    end
end

%% === LM + IRLS (Huber) con line-search y escalado =======================
% p = [a b c d phiAD kappa0 Ax Ay]
function [p_opt, hist] = fit_fourbar_icr(Pdes, K, p0, opts, boxA, w_user)
    if nargin<5
        pad=100; boxA=[min(Pdes(:,1))-pad,max(Pdes(:,1))+pad,min(Pdes(:,2))-pad,max(Pdes(:,2))+pad];
    end

    dx = max(Pdes(:,1)) - min(Pdes(:,1));
    dy = max(Pdes(:,2)) - min(Pdes(:,2));
    scaleXY = max([dx, dy]); if scaleXY<=0, scaleXY=1; end

    p  = p0(:)'; 
    mu = opts.mu0;

    % Recorte inicial
    p  = project_bounds(p, opts.LMINv, opts.LMAXv, opts.kappa0_min, opts.kappa0_max, boxA, opts.phiAD_min, opts.phiAD_max);

    best = struct('p',p,'rn',inf,'it',0);

    for it=1:opts.maxIt
        % --- IRLS con pesos de usuario -----------------------------------
        e  = residual_vec_raw(p, K, Pdes);                 % 2N x 1 (mm)
        [w_sqrt, r] = weight_and_residual(e, scaleXY, opts.huber_delta, w_user);

        % Jacobiano con pesos congelados
        funW = @(pp) weight_vec(w_sqrt) .* residual_vec_raw(pp, K, Pdes) / scaleXY;
        J = fd_jacobian(funW, p);

        % Paso LM
        H = J.'*J + mu*eye(numel(p));
        g = J.'*r;
        dp_full = (-H \ g).';

        % Line-search
        improved = false; alpha_used = 1;
        for alpha = [1, 0.5, 0.25, 0.1, 0.05, 0.02]
            p_try = project_bounds(p + alpha*dp_full, opts.LMINv, opts.LMAXv, ...
                                   opts.kappa0_min, opts.kappa0_max, boxA, opts.phiAD_min, opts.phiAD_max);
            e_try   = residual_vec_raw(p_try, K, Pdes);
            [~, r_try] = weight_and_residual(e_try, scaleXY, opts.huber_delta, w_user);
            if norm(r_try) < norm(r)
                p = p_try; mu = max(mu/3, 1e-9); improved = true; alpha_used = alpha;
                if norm(r_try) < best.rn, best = struct('p',p,'rn',norm(r_try),'it',it); end
                break
            end
        end
        if ~improved, mu = mu*3; end
        if norm(alpha_used*dp_full) < 1e-8*(1+norm(p)), break; end
    end
    p_opt = best.p; hist = best;
end

% ---- Huber IRLS × pesos de usuario --------------------------------------
function [w_sqrt, r] = weight_and_residual(e, scaleXY, huber_delta_mm, w_user)
    N  = numel(e)/2;
    E  = reshape(e,2,N).';
    d  = sqrt(sum(E.^2,2));
    del = huber_delta_mm;

    % Peso Huber
    w_h = ones(N,1);
    big = d > del;
    w_h(big) = del ./ d(big);           % 0<w_h<=1

    % Peso total = Huber × usuario (normalizado para no cambiar escala)
    w_tot = w_h .* w_user;
    w_tot = w_tot / mean(w_tot);

    w_sqrt = sqrt(w_tot);
    Ew = E .* w_sqrt;
    r  = Ew(:) / scaleXY;               % 2N x 1
end

% Expandir sqrt(w_i) a vector 2N (x,y)
function Wv = weight_vec(w_sqrt)
    Wv = reshape([w_sqrt.'; w_sqrt.'], [], 1);
end

% ---- Residuales “crudos” (cinemática) -----------------------------------
function r = residual_vec_raw(p, K, Pdes)
    a=p(1); b=p(2); c=p(3); d=p(4); phiAD=p(5); kappa0=p(6); A=[p(7) p(8)];
    N = numel(K); r = zeros(2*N,1);
    uAD = [cos(phiAD) sin(phiAD)]; D = A + d*uAD;
    th2_prev = NaN;
    for i=1:N
        th3 = phiAD + kappa0 + K(i);
        u3  = [cos(th3) sin(th3)];
        S   = (D - A) - b*u3; rS = norm(S);
        if rS < 1e-12
            P = [1e6 1e6];
        else
            alpha  = atan2(S(2),S(1));
            cosDel = (a^2 + rS^2 - c^2)/(2*a*rS);
            if abs(cosDel)>1
                P = [1e4 1e4];
            else
                delta = acos(max(-1,min(1,cosDel)));
                th2c  = [alpha+delta, alpha-delta];
                if i>1 && ~isnan(th2_prev)
                    [~,ix]=min(abs(wrapToPi_local(th2c - th2_prev)));
                else
                    ix = 1;
                end
                th2 = th2c(ix); th2_prev=th2;
                B = A + a*[cos(th2) sin(th2)];
                C = B + b*u3;
                r2 = B - A; r4 = C - D;
                ts = [r2(:) -r4(:)] \ (D(:) - A(:));
                P  = A + ts(1)*r2;
            end
        end
        r(2*i-1:2*i) = (P(:) - Pdes(i,:).');  % mm
    end
end

% ---- Jacobiano por diferencias finitas ----------------------------------
function J = fd_jacobian(fun, p)
    r0 = fun(p); m = numel(r0); n = numel(p);
    J = zeros(m,n);
    for j=1:n
        pj = p; pj = pj(:)';
        epsj = 1e-6 * max(1,abs(pj(j)));
        pj(j) = pj(j) + epsj;
        J(:,j) = (fun(pj) - r0) / epsj;
    end
end

% ---- Proyección en límites (acepta escalares o vectores de 1x4) --------
function p = project_bounds(p, LMINv, LMAXv, K0MIN, K0MAX, boxA, phiAD_min, phiAD_max)
    LMINv = LMINv(:)'; if isscalar(LMINv), LMINv = repmat(LMINv,1,4); end
    LMAXv = LMAXv(:)'; if isscalar(LMAXv), LMAXv = repmat(LMAXv,1,4); end

    % a,b,c,d
    p(1:4) = min(max(p(1:4), LMINv), LMAXv);

    % φAD envuelto a (-π,π] y luego acotado
    phi = atan2(sin(p(5)), cos(p(5)));
    p(5) = min(max(phi, phiAD_min), phiAD_max);

    % κ0
    p(6) = min(max(p(6), K0MIN), K0MAX);

    % Ax, Ay
    p(7) = min(max(p(7), boxA(1)), boxA(2));
    p(8) = min(max(p(8), boxA(3)), boxA(4));
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
            [~,ix]=min(abs(wrapToPi_local(th2c - theta2(k-1)))); theta2(k)=th2c(ix);
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

function [th4a,th4b] = solve_theta4_two_roots(a,b,c,d,th2)
k1=d/a; k2=d/c; k3=(a^2 + c^2 + d^2 - b^2)/(2*a*c);
Aeq = k3 - k1 + (k2 - 1)*cos(th2); Beq = -2*sin(th2);
Ceq = k3 + k1 + (k2 + 1)*cos(th2);
disc = max(Beq.^2 - 4*Aeq.*Ceq, 0);
t1 = (-Beq + sqrt(disc))/(2*Aeq); t2 = (-Beq - sqrt(disc))/(2*Aeq);
th4a = 2*atan(t1); th4b = 2*atan(t2);
end

function ang = wrapToPi_local(ang)
if exist('wrapToPi','file') == 2, ang = wrapToPi(ang);
else, ang = mod(ang + pi, 2*pi) - pi;
end
end
