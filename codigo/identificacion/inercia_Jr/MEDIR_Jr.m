%% MEDIR Jr POR EL ENSAYO DEL BRAZO BLOQUEADO (sobre el modelo digital Simscape)
%  Mide la inercia del eje theta aplicando un par CONOCIDO con el pendulo BLOQUEADO,
%  midiendo la aceleracion angular:   J_theta = tau / theta_ddot
%  y de ahi  Jr = J_theta - mp*Lr^2   (el pendulo bloqueado en alpha=0 aporta ~mp*Lr^2).
%  No depende del polo inestable ni del punto de operacion -> robusto.
%
% =========================  MONTAJE DEL ENSAYO  ===========================
%  Sobre una copia del modelo de balance:
%   1) BLOQUEA el pendulo: en el Revolute de alpha, Actuation > Motion = "Provided by
%      Input" y conecta una constante 0 (posicion prescrita = pendulo soldado a alpha=0).
%      (alternativa: un Weld Joint temporal en esa junta).
%   2) DESACTIVA disipacion/resorte para que theta_ddot sea limpio y constante:
%      cable kc = 0, Tdry = 0 (Rotational Friction de theta), friccion del motor = 0,
%      DampingCoefficient del Revolute theta = 0.
%   3) Aplica un ESCALON de voltaje Vm pequeno-medio (p.ej. 1-2 V) al motor.
%   4) Registra al workspace:  t_log, theta_log  (y opcional Im_log).
%   5) Corre POCO tiempo (p.ej. 0.3 s): solo necesitas el arranque, antes de que
%      la fcem (km*theta_dot) reduzca el par.
% =========================================================================

run('parametros_furuta.m');

%% --- Cargar los datos del ensayo ---
% Se espera: t_log [s], theta_log [rad], Vm_step [V] (escalon aplicado).
% Ejemplo desde un .mat:  load('ensayo_Jr.mat','t_log','theta_log','Vm_step');
Vm_step = 1.5;                 % voltaje del escalon aplicado [V]
 t_log = out.DATA_THETA(1); theta_log = out.DATA_THETA(2);   % vectores del ensayo (t, theta)

assert(exist('t_log','var')==1 && exist('theta_log','var')==1, ...
    'Carga t_log y theta_log del ensayo antes de correr.');

%% --- Par aplicado (valido mientras theta_dot ~ 0, arranque) ---
tau = p.kt*Vm_step/p.Rm;       % N*m  (en reposo: Im = Vm/Rm, tau = kt*Im)

%% --- Ajustar theta_ddot en la ventana inicial (theta ~ 0.5*a*t^2) ---
% Usa solo el inicio, donde theta_dot es pequeno (fcem despreciable).
win =   (t_log >= 0.1046)  && (t_log <= 0.3);           % ventana de ajuste [s] (segun la corrida)
c = polyfit(t_log(win), theta_log(win), 2);   % theta ~ c1*t^2 + c2*t + c3
theta_ddot = 2*c(1);           % aceleracion angular constante

J_theta = tau/theta_ddot;      % inercia total del eje theta (con pendulo bloqueado)
Jr      = J_theta - p.mp*p.Lr^2;

fprintf('Par aplicado tau        = %.4e N*m  (Vm=%.2f V)\n', tau, Vm_step);
fprintf('theta_ddot (ajuste)     = %.4f rad/s^2\n', theta_ddot);
fprintf('J_theta (eje, pend bloq)= %.4e kg*m^2   [= Jr + mp*Lr^2]\n', J_theta);
fprintf('mp*Lr^2                 = %.4e kg*m^2\n', p.mp*p.Lr^2);
fprintf('==> Jr (brazo+hub+rotor) = %.4e kg*m^2\n', Jr);
fprintf('   (placeholder actual en parametros_furuta.m: %.4e)\n', p.Jr);

%% --- Verificacion: el ajuste cuadratico debe pegar bien (R^2 ~ 1) ---
yfit = polyval(c, t_log(win));
R2 = 1 - sum((theta_log(win)-yfit).^2)/sum((theta_log(win)-mean(theta_log(win))).^2);
fprintf('R^2 del ajuste cuadratico = %.4f  (debe ser ~1; si no, reduce la ventana)\n', R2);

figure('Color','w'); plot(t_log, theta_log, 'b', t_log(win), yfit, 'r--','LineWidth',1.3);
xlabel('t [s]'); ylabel('\theta [rad]'); legend('ensayo','ajuste 0.5 a t^2','Location','northwest');
title(sprintf('Brazo bloqueado: \\theta_{ddot}=%.3f rad/s^2  ->  J_\\theta=%.2e', theta_ddot, J_theta)); grid on;

fprintf('\n>> Pon p.Jr = %.4e en parametros_furuta.m y re-corre derivar_modelo_furuta_EKF.m\n', Jr);