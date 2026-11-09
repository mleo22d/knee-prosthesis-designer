% ============================================================
% Calcula la “zona de estabilidad” como la intersección de las líneas de
% acción de la GRF en talón y puntera durante stance, y grafica esa zona
% junto con la trayectoria del ICR trasladada al sistema global (pie+rodilla).
% ============================================================

%% Zona de estabilidad X definida por GRF en stance + nueva trayectoria ICR
clc; clear; close all;

% --- Parámetros ---
knee_height = 500;   % mm
foot_length = 250;   % mm
heel_x = 0;          % talón en x=0
toe_x  = foot_length; % punta del pie en x=250

% Ángulos GRF (referencia paper)
theta_heel = 75;   % deg, GRF en talón
theta_toe  = 105;  % deg, GRF en puntera

% Escala longitud de vector de GRF
F_len = 800; % mm

% --- Coordenadas líneas de acción ---
% GRF en talón
x1 = heel_x + [0  cosd(theta_heel)]*F_len;
y1 = [0  sind(theta_heel)]*F_len;

% GRF en puntera
x2 = toe_x + [0  cosd(theta_toe)]*F_len;
y2 = [0  sind(theta_toe)]*F_len;

% --- Intersección de las dos GRF (centro de la X) ---
P1 = [heel_x 0];  v1 = [cosd(theta_heel) sind(theta_heel)];
P2 = [toe_x 0];   v2 = [cosd(theta_toe)  sind(theta_toe)];

A = [v1' -v2'];  b = (P2-P1)';  
sol = A\b;       
Xc = P1(1) + sol(1)*v1(1);
Yc = P1(2) + sol(1)*v1(2);

% --- Nuevos datos del ICR (respecto al centro de la rodilla) ---
ICR_x_local = [31.4948957297351	32.4547582575868	33.4116504084021	34.3686021528680	35.3292089225237	36.2976802170100	37.2788973718845	38.2784829580715	39.3028847532187	40.3594777914611	41.4566886869204	42.6041472665457	43.8128715701768	45.0954935085708	46.4665339327096	47.9427375552402	49.5434800214816	51.2912612960739	53.2123010634769	55.3372523336623	57.7020475533982	60.3488847503607	63.3273450361023	66.6955990190864	70.5215939379124	74.8839905848854	79.8723967344875	85.5860516239649	92.1294447589187	99.6022492096822];

ICR_y_local = [-158.699090290262	-157.511298041637	-156.333790932371	-155.169173599961	-154.020054776078	-152.889048430463	-151.778781916520	-150.691912362946	-149.631152886745	-148.599310679508	-147.599339694265	-146.634411608356	-145.708010061435	-144.824055012129	-143.987066628141	-143.202381716658	-142.476440734849	-141.817170494215	-141.234497642571	-140.741042082625	-140.353059352961	-140.091728951308	-139.984924609025	-140.069656194907	-140.395444692616	-141.028982803718	-142.060537815210	-143.612643861878	-145.851633231458	-149.002292128722];

% --- Trasladar al sistema global (rodilla en foot_length/2, knee_height) ---
knee_x = foot_length/2;
ICR_x = knee_x + ICR_x_local;
ICR_y = knee_height + ICR_y_local;

% --- Graficar ---
figure('Color','w'); hold on; axis equal;
xlabel('X (mm)'); ylabel('Y (mm)');
title('Zona de estabilidad y nueva trayectoria del ICR');

% Suelo
plot([-100 400],[0 0],'k-','LineWidth',2);

% Pie
fill([0 foot_length foot_length 0],[0 0 30 30],[0.85 0.85 0.85],'EdgeColor','k');

% GRF talón
plot(x1,y1,'b-','LineWidth',2);
quiver(heel_x,0,cosd(theta_heel)*200,sind(theta_heel)*200, ...
    'b','LineWidth',2,'MaxHeadSize',2);

% GRF puntera
plot(x2,y2,'r-','LineWidth',2);
quiver(toe_x,0,cosd(theta_toe)*200,sind(theta_toe)*200, ...
    'r','LineWidth',2,'MaxHeadSize',2);

% Marcar intersección (X de estabilidad)
plot(Xc,Yc,'ko','MarkerSize',8,'MarkerFaceColor','y');
text(Xc+10,Yc,'Zona de estabilidad','FontSize',9,'Color','k');

% Rodilla
plot(knee_x,knee_height,'ks','MarkerSize',8,'MarkerFaceColor','g');
text(knee_x+10,knee_height,'Knee','FontSize',9,'Color','g');

% Trayectoria ICR
plot(ICR_x,ICR_y,'m-o','LineWidth',1.5,'MarkerSize',4,'DisplayName','ICR path');

ylim([0 700]); xlim([-100 400]);
grid on;
legend('Suelo','Pie','GRF talón','GRF puntera','Centro X (estabilidad)','Knee','ICR path','Location','northeastoutside');