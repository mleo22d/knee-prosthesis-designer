clc;
clear varaibles;
close all;

% ---------- COORDENADAS ------------

ua=80;
uk=420+ua;
ut=150+uk;

ft=82;
%ot=-79;
fk=52;
%ok=-50;
fa=-32;
%oa=30;
fb=-48;
%ob=45;

bottom=[fb, 0];
ankle=[fa, ua];
knee=[fk, uk];
top=[ft, ut];

EKJC=[0, uk];

%  ------ COORDENADAS MECANISMO -------
% Locales respecto a EKJC - OJO RESPECTO A QUIEN ES EL SISTEMA LOCAL !!!!!
Axl= -14.8;
Ayl= -43.4;
Bxl= -19.8;
Byl= -11.4;
Cxl= 0;
Cyl= 0;
Dxl= 14;
Dyl= -46.7;

A=EKJC+[Axl Ayl];
B=EKJC+[Bxl Byl];
C=EKJC+[Cxl Cyl];
D=EKJC+[Dxl Dyl];

R=(A+B)/2; % ASUMIENDO R EN LA MITAD de AB


% --------- FUERZA ------------------
F = 4480; % [N] 

% Vector dirección (de bottom a top)
dir = top - bottom;

% Vector unitario
u = dir / norm(dir);

% Vector fuerza aplicado en bottom y top
F_bottom =  F * u;   % en bottom
F_top    = -F * u;



theta2=atan(abs(B(2)-A(2))/abs(B(1)-A(1)));

% --------------------------- CALCULOS -------------------------------------
%  --- Momentos ---
% Cuerpo 1: Momentos en A
%        FDx          FDy
eq1_3=[vertical(A,D) horizontal(A,D)]; 
ADy=vertical(A,D);
ADx=horizontal(A,D);

%             Fx*AOy                       Fy*AOx
ctte1_3=F_bottom(1)*vertical(A,bottom)+F_bottom(2)*horizontal(A,bottom);
AOy=vertical(A,bottom);
AOx=horizontal(A,bottom);

% Cuerpo 2: Momentos en R
%          FBx          FBy             FAx             FAy
eq2_3=[vertical(R,B) horizontal(R,B) (-1)*vertical(R,A) (-1)*horizontal(R,A)];
ctte2_3=0;

RBy=vertical(R,B);
RBx=horizontal(R,B); 
RAy=vertical(R,A);
RAx=horizontal(R,A);

% Cuerpo 3: Momentos en D
%      FCx                 FCy
eq3_3=[vertical(D,C) horizontal(D,C)];
CDy=vertical(D,C) 
CDx=horizontal(D,C)
ctte3_3=0;

% ----- Fuerzas ----
% Cuerpo 1
%   FAx FDx 
eq1_1=[1 1];
ctte1_1=F_bottom(1);
%    FAy FDy
eq1_2=[1 1];
ctte1_2=F_bottom(2);

% Cuerpo 2
%  FAx FBx FRx  
eq2_1=[-1 1 -sin(theta2)];
ctte2_1=0;
%  FAy FBy          % SI CONSIDERAMOS REACCION EN Y, AÑADIR AQUI!!!!!!!!!
eq2_2=[-1 1 -cos(theta2)];
ctte2_2=0;

% Cuerpo 3
%    FCx FDx
eq3_1=[1 -1];
ctte3_1=0;
%    FCy  FDy
eq3_2=[1 -1];
ctte3_2=0;


% Ax Ay Bx By Cx Cy Dx Dy Rx
coef=[eq1_1(1) 0 0 0 0 0 eq1_1(2) 0 0;
    0 eq1_2(1) 0 0 0 0 0 eq1_2(2) 0;
    0 0 0 0 0 0 eq1_3(1) eq1_3(2) 0; % Momento de cuerpo 1
    eq2_1(1) 0 eq2_1(2) 0 0 0 0 0 eq2_1(3);
    0 eq2_2(1) 0 eq2_2(2) 0 0 0 0 eq2_2(3);
    eq2_3(1) eq2_3(2) eq2_3(3) eq2_3(4) 0 0 0 0 0; % Momento cuerpo 2
    0 0 0 0 eq3_1(1) 0 eq3_1(2) 0 0;
    0 0 0 0 0 eq3_2(1) 0 eq3_2(2) 0;
    0 0 0 0 eq3_3(1) eq3_3(2) 0 0 0;]

constantes= -[ctte1_1; ctte1_2; ctte1_3; ctte2_1; ctte2_2; ctte2_3; ctte3_1; ctte3_2; ctte3_3];

reac=coef\constantes

% Comprobación!

dfx=vertical(C,top);
Mfx=F_top(1)*dfx;

dbx=vertical(C,B);
MBx=reac(3)*dbx;

dr=vertical(C,R);
MR=reac(9)*dr*sin(theta2);

dr2=horizontal(C,R);
MR2=reac(9)*dr2*cos(theta2);


dFy=horizontal(C,top);
MFy=F_top(2)*dFy;

dBy=horizontal(C,B);
MBy=reac(4)*dBy;

MOMENTOSc=Mfx-MBx+abs(MR)+MFy-(MBy)+MR2
% MOMENTOSc=

                                % ref, fuerza
function [dy] = vertical(p1, p2)
% VERTICAL_DISTANCE calcula la diferencia vertical (en y)
% entre dos puntos 2D: p1 = [x1 y1], p2 = [x2 y2]
    
    dy = -(p2(2) - p1(2))/1000;
end

function [dx] = horizontal(p1, p2)
% HORIZONTAL_DISTANCE calcula la diferencia horizontal (en x)
% entre dos puntos 2D: p1 = [x1 y1], p2 = [x2 y2]
    dx = (p2(1) - p1(1))/1000;
end


