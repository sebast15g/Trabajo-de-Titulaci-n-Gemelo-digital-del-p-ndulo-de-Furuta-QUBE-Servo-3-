function P = setup_swingup()
% SETUP_SWINGUP  Parametros del swing-up hibrido (energia) + balance, tomados del
%   q_qube2_swingup.slx de Quanser (QUBE-Servo 2 rotary pendulum). Fuente unica de
%   verdad para las 3 modalidades (sim/QUARC/RT Box) y para los #define del C-Script
%   controlador (guia_E3_swingup_hibrido.md). Espeja setup_swingup_quanser.m + los
%   valores del bloque "Energy-Based Swing-Up Control".
%
%   P = setup_swingup();  -> struct con todos los parametros.

    % --- fisica (parametros_rotpen_quanser.m) ---
    P.Rm = 7.5;  P.kt = 0.0422;  P.km = 0.0422;      % motor
    P.mr = 0.095; P.r = 0.085;                        % brazo (valores Quanser del swing-up)
    P.mp = 0.024; P.Lp = 0.12865; P.l = P.Lp/2;       % pendulo
    P.g  = 9.78;
    P.Jp_cm = P.mp*P.Lp^2/12;                         % inercia pendulo respecto CoM (para la energia)

    % --- swing-up de energia (valores por defecto de Quanser: 50 / 30 / 6) ---
    P.ke    = 50;                                     % [m/s/J] ganancia de energia ("mu")
    P.Er_mJ = 30;                                     % [mJ] energia de referencia (= 2*mp*g*l = 30.2 mJ)
    P.Er    = P.Er_mJ/1000;                           % [J]
    P.u_max = 6;                                      % [m/s^2] limite de aceleracion del swing-up
    % ganancia aceleracion->voltaje: Vm = (Rm/kt)*(mr*r)*u_acc
    P.K_acc2V = (P.Rm/P.kt)*(P.mr*P.r);               % ~1.435 V por (m/s^2)

    % --- conmutacion a balance ---
    P.catch_deg = 20;                                 % [deg] |alpha desde invertido| < 20 -> balance
    P.catch_rad = P.catch_deg*pi/180;

    % --- balance LQR de Quanser (u = -K*x, x=[theta alpha theta_dot alpha_dot]) ---
    P.K_bal = [-2 35 -1.5 3];

    % --- saturacion del actuador ---
    P.Vsat = 10;                                      % [V]

    fprintf('setup_swingup: ke=%g m/s/J  Er=%g mJ (2mgl=%.2f mJ)  u_max=%g m/s^2  catch=%g deg\n', ...
            P.ke, P.Er_mJ, 2*P.mp*P.g*P.l*1000, P.u_max, P.catch_deg);
    fprintf('  K_acc2V=%.4f V/(m/s^2)   K_bal=[%g %g %g %g]\n', P.K_acc2V, P.K_bal);
end
