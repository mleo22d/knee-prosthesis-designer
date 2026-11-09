% ============================================================
% Calcula el ICR de un mecanismo de 4 barras en flexiones específicas (0–110°)
% ============================================================

%% ==== ICR en ángulos específicos (sin plot) ====
clear; clc;

% ------- Parámetros del mecanismo (ejemplo: los tuyos) -------
a=32.4; 
b=22.9; 
c=48.7; 
d=29.0;
A=[38.3 -21.3];
phiAD=deg2rad(-6.5); 
k0=deg2rad(36.4);


% ------- Lista de flexiones de rodilla a evaluar (en grados) -------
angles_deg = linspace(0,110,15);

% ------- Cálculo de ICR para esos ángulos -------
[xICR, yICR, theta2_list, ok_flags] = icr_for_angles(a,b,c,d,A,phiAD,k0,angles_deg);

% ------- Resultados en el workspace -------
disp('xICR ='); disp(xICR);
disp('yICR ='); disp(yICR);


% (Opcional) guardar a .mat
% save('ICR_muestras.mat','xICR','yICR','angles_deg','theta2_list','ok_flags');

plot(xICR,yICR);axis equal;

%% ===== Función principal: ICR para una lista de ángulos de flexión =====
function [xICR,yICR,theta2_list,ok_flags] = icr_for_angles(a,b,c,d,A,phiAD,k0,angles_deg)
    % Acepta flexiones de rodilla en grados respecto a (phiAD + k0).
    % Devuelve ICR en esos instantes, más la lista de θ2 y flags de cierre.

    A = A(:)';                               % asegurar fila
    D = A + d*[cos(phiAD) sin(phiAD)];       % punto D desde A y phiAD

    K = deg2rad(angles_deg(:));              % flexiones a rad
    N = numel(K);

    xICR = nan(1,N); 
    yICR = nan(1,N);
    theta2_list = nan(1,N);
    ok_flags = false(1,N);

    th2_prev = NaN;                          % para continuidad de rama

    for i = 1:N
        th3 = phiAD + k0 + K(i);             % orientación de BC
        u3  = [cos(th3) sin(th3)];
        S   = (D - A) - b*u3;
        rS  = norm(S);

        if rS < 1e-12
            % Degenerado
            continue;
        end

        alpha  = atan2(S(2), S(1));
        cosDel = (a^2 + rS^2 - c^2)/(2*a*rS);

        if abs(cosDel) > 1+1e-12
            % No hay cierre geométrico
            continue;
        end

        cosDel = max(-1, min(1, cosDel));
        delta  = acos(cosDel);

        % Candidatos para θ2 y elección por continuidad ("auto")
        th2c = [alpha + delta, alpha - delta];
        if ~isnan(th2_prev)
            [~,ix] = min(abs( angleDiff(th2c, th2_prev) ));
        else
            ix = 1; % por defecto el primero en la primera pose
        end
        th2 = th2c(ix); 
        th2_prev = th2;

        % Puntos B y C
        B = A + a*[cos(th2) sin(th2)];
        C = B + b*u3;

        % Intersección de rectas AB y DC -> ICR
        r2 = B - A;
        r4 = C - D;

        M = [r2(:), -r4(:)];                 % 2x2
        rhs = (D(:) - A(:));

        if abs(det(M)) < 1e-12
            % Rectas casi paralelas -> mal condicionado
            continue;
        end

        ts = M \ rhs;
        P  = A + ts(1)*r2;

        xICR(i) = P(1);
        yICR(i) = P(2);
        theta2_list(i) = th2;
        ok_flags(i) = true;
    end
end

%% ===== Helper: diferencia angular con envoltura [-π,π] =====
function d = angleDiff(angVec, ref)
    angVec = wrapToPi_local(angVec);
    ref    = wrapToPi_local(ref);
    d      = wrapToPi_local(angVec - ref);
end

function ang = wrapToPi_local(ang)
    ang = mod(ang + pi, 2*pi) - pi;
end
