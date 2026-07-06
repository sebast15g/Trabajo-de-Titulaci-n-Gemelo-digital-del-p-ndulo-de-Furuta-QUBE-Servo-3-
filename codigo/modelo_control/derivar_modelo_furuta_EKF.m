%% DERIVACION DEL MODELO + LQR + JACOBIANOS DEL EKF  (Furuta QUBE-Servo 3)
%  Gemelo Digital - genera de forma consistente:
%    - EOM no lineales (por Lagrange: sin transcripcion manual de signos)
%    - f(x,u) continuo
%    - Linealizacion en el equilibrio superior -> A, B  y  K = lqr(...)
%    - Modelo aumentado con la perturbacion del cable d -> f_aug, F_c (jacobiano)
%    - Medidas h(x) y su jacobiano H   (incluye la corriente I_m como medida de theta_dot)
%    - Exporta funciones para el bloque MATLAB Function del EKF en Simulink
%    - Deja planteadas Q y R
%
%  Requiere: Symbolic Math Toolbox y Control System Toolbox (lqr).
%  Convencion: alpha = 0 en el equilibrio SUPERIOR (invertido).
%
%  VERIFICACION OBLIGATORIA antes de confiar en f: comparar la respuesta de f
%  contra el modelo Simscape validado (misma entrada/condicion inicial). Para A,B
%  se recomienda ademas linealizar el propio Simscape (ver bloque al final).
% --------------------------------------------------------------------------
clear; clc;
run('parametros_furuta.m');     % carga struct p
ep = 1e-3;                       % suavizado de Coulomb (tanh) para diferenciabilidad

%% 1) Coordenadas y cinematica (alpha desde la vertical superior) -------------
syms th al dth dal ddth dda Vm dcab real     % estados, entrada y perturbacion del cable

rhat = [cos(th); sin(th); 0];                 % radial (eje del brazo)
that = [-sin(th); cos(th); 0];                % tangencial
zhat = [0; 0; 1];                             % vertical

% Posicion del CoM del pendulo: punta del brazo + brazo del pendulo (bisagra radial)
pcm  = p.Lr*rhat + p.lp*( sin(al)*that + cos(al)*zhat );
vcm  = jacobian(pcm, [th; al]) * [dth; dal]; % velocidad del CoM

omega_p = dth*zhat + dal*rhat;               % vel. angular del pendulo (arm spin + hinge spin)
ehat    = sin(al)*that + cos(al)*zhat;        % eje longitudinal del pendulo (varilla delgada)

%% 2) Energias y Lagrangiano --------------------------------------------------
KE = 1/2*p.Jr*dth^2 ...                                   % brazo (incluye rotor+hub)
   + 1/2*p.mp*(vcm.'*vcm) ...                             % traslacion del pendulo
   + 1/2*p.Jp_cm*( (omega_p.'*omega_p) - (omega_p.'*ehat)^2 ); % rotacion del pendulo (rod)
PE = p.mp*p.g*p.lp*cos(al);                               % altura del CoM = lp cos(al)
Lag = KE - PE;

%% 3) Euler-Lagrange ----------------------------------------------------------
q = [th; al]; dq = [dth; dal]; ddq = [ddth; dda];
dL_ddq = jacobian(Lag, dq).';
ddt    = jacobian(dL_ddq, q)*dq + jacobian(dL_ddq, dq)*ddq;   % d/dt (∂L/∂q̇)
EL     = simplify( ddt - jacobian(Lag, q).' );               % = fuerzas generalizadas

M = simplify(jacobian(EL, ddq));          % matriz de inercia (EL es lineal en ddq)
hvec = simplify(subs(EL, ddq, [0;0]));    % terminos Coriolis + gravedad

%% 4) Fuerzas generalizadas y f(x,u) -----------------------------------------
tau_mot = p.kt*(Vm - p.km*dth)/p.Rm;      % par del motor DC (sin inductancia)

% (a) Modelo LIMPIO para el LQR (sin cable ni Coulomb; el cable es perturbacion)
Qc_gen = [ tau_mot - p.Dr*dth ; -p.Dp*dal ];
ddq_clean = M \ (Qc_gen - hvec);
f_clean = [dth; dal; ddq_clean];

% (b) Modelo del EKF (cable determinista + perturbacion d + Coulomb de alpha)
tau_cable = p.kc*(th - p.theta0) + p.Tdry_th*tanh(dth/ep);
Qe_gen = [ tau_mot - p.Dr*dth - tau_cable + dcab ; ...
           -p.Dp*dal - p.Tc_alpha*tanh(dal/ep) ];
ddq_ekf = M \ (Qe_gen - hvec);
f_aug = [dth; dal; ddq_ekf; 0];           % estado aumentado: d con dinamica de paseo aleatorio (ḋ=0)

%% 5) Linealizacion en el equilibrio superior -> A, B, K ----------------------
xeq = [th 0; al 0; dth 0; dal 0; Vm 0];   % equilibrio: alpha=0 (arriba), reposo, V=0
A = double(subs(jacobian(f_clean,[th;al;dth;dal]), xeq(:,1), xeq(:,2)));
B = double(subs(jacobian(f_clean, Vm),             xeq(:,1), xeq(:,2)));

fprintf('\nA =\n'); disp(A);
fprintf('B =\n'); disp(B);
fprintf('Autovalores en lazo abierto (debe haber uno inestable, parte real > 0):\n'); disp(eig(A).');

% Pesos LQR (ajustar): penaliza mas alpha; poco esfuerzo
Qc = diag([1, 10, 0.1, 0.1]);     % [theta, alpha, dtheta, dalpha]
Rc = 1;                            % esfuerzo de control (voltaje)
if license('test','Control_Toolbox')
    K = lqr(A,B,Qc,Rc);
    fprintf('K = lqr(A,B,Qc,Rc) =\n'); disp(K);
    fprintf('Autovalores en lazo cerrado (todos parte real < 0):\n'); disp(eig(A-B*K).');
else
    warning('Sin Control System Toolbox: usar place() o calcular K aparte.');
    K = [];
end

%% 6) Jacobianos del EKF (estado aumentado) ----------------------------------
xa = [th; al; dth; dal; dcab];
Fc = jacobian(f_aug, xa);                 % jacobiano continuo  ∂f/∂x_aug
% Medidas: SOLO encoders theta, alpha. (La corriente se descarta: el DC Motor de
% Simscape tiene inductancia y la relacion algebraica Im=(Vm-km*dth)/Rm no la captura,
% lo que metia un transitorio enorme. Con theta,alpha el estado y d siguen observables.)
hmeas = [ th ; al ];
H = jacobian(hmeas, xa);                  % H = [1 0 0 0 0 ; 0 1 0 0 0]
fprintf('\nH (constante) =\n'); disp(double(subs(H, xa, zeros(5,1))));

%% 7) Exportar funciones para el bloque MATLAB Function del EKF ---------------
% f_aug(x,Vm), Fc(x,Vm), h(x,Vm), H : usadas en predict/update a paso Ts
% Nombres SIN colision de mayus/minus (Windows es case-insensitive: h vs H chocan)
matlabFunction(f_aug, 'File','furuta_f_aug','Vars',{xa, Vm},'Optimize',true);
matlabFunction(Fc,    'File','furuta_Fc',   'Vars',{xa, Vm},'Optimize',true);
matlabFunction(hmeas, 'File','furuta_meas', 'Vars',{xa, Vm},'Optimize',true);  % medida h(x)
matlabFunction(H,     'File','furuta_Hjac', 'Vars',{xa, Vm},'Optimize',true);  % jacobiano H
fprintf('Exportadas: furuta_f_aug.m, furuta_Fc.m, furuta_meas.m, furuta_Hjac.m\n');

%% 8) Matrices de ruido del EKF (Q, R) - PLANTEAMIENTO -----------------------
% R: ruido de medida. Encoders dominados por cuantizacion (sigma^2 = q^2/12).
sig_th = p.q_theta/sqrt(12);  sig_al = p.q_alpha/sqrt(12);
R = diag([sig_th^2, sig_al^2]);
% Q: ruido de proceso. Pequeno en estados bien modelados; mayor en d (perturbacion
%    que debe poder variar). Ajustar por consistencia de la innovacion (blancura/NIS).
Q = diag([1e-8, 1e-8, 1e-6, 1e-6, (1e-4)^2]);   % [th, al, dth, dal, d]
fprintf('\nR =\n'); disp(R); fprintf('Q =\n'); disp(Q);

save('modelo_furuta_EKF.mat','A','B','K','Q','R','Qc','Rc','p');
fprintf('\nGuardado modelo_furuta_EKF.mat\n');

%% --- ALTERNATIVA RECOMENDADA para A,B: linealizar el Simscape validado ------
%  Mas consistente con la fisica ya validada. Descomentar y adaptar nombres:
%  io(1) = linio('TU_MODELO/Vm', 1, 'input');
%  io(2) = linio('TU_MODELO/theta', 1, 'output'); ... etc
%  sys = linearize('TU_MODELO', io, op);   % op = punto de operacion en alpha=0
%  A = sys.A; B = sys.B;   % y comparar con las A,B analiticas de arriba
