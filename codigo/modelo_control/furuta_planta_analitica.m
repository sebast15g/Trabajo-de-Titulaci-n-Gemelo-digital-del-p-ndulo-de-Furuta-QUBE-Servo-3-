function [theta, alpha, dtheta, dalpha, theta_meas, alpha_meas] = ...
         furuta_planta_analitica(Vm, x0, Ts, nsub)
%#codegen
% FURUTA_PLANTA_ANALITICA  Planta analitica (modelo M1) del pendulo de Furuta
% como integrador discreto autocontenido (RK4 con subpasos), CON tope mecanico
% en theta y CON emulacion de encoder. Pensada para un bloque MATLAB Function en
% Simulink, reutilizable en simulacion normal, QUARC (RTS) y RT box (todos a paso
% fijo).
%
% ES LA TRANSCRIPCION LITERAL DEL C-SCRIPT "PLANTA" DE LA RT BOX
% (guia_cscripts_plecs.md sec 1). La dinamica base (sec 1.4), el tope (sec 1.2) y
% la emulacion de encoder (sec 1.5) estan copiados uno a uno, con los MISMOS
% parametros #define (params actuales, g=9.7807). Verificado contra furuta_f_aug.m
% (params horneados actuales): error 1.14e-13. NO usa furuta_f_param.m, que quedo
% con g=9.77 horneada (desactualizada) y por eso divergia ~0.29% en aceleraciones.
%
% CONVENCION (NO cambiar): alpha = 0 en el equilibrio SUPERIOR (invertido),
% identica al C-Script, a furuta_f_aug y al EKF. El bloque NO aplica bias ni la
% correccion alpha_real<->pi-alpha_modelo en sus salidas: esas van en post-proceso.
%
% ENTRADAS (4 puertos; NO requiere Ports and Data Manager)
%   Vm   : tension de armadura [V] (E1: Constant 0; E2: excitacion; E3: control).
%   x0   : [theta0; alpha0; dtheta0; dalpha0] condicion inicial (solo en t=0).
%          E1: [0;0.05;0;0]   E2/E3: [0;pi;0;0]
%   Ts   : paso de muestreo [s] (0.002 = 500 Hz).
%   nsub : nro de subpasos RK4 por paso. nsub=4 -> h=5e-4 = paso base de la RT Box.
%
% SALIDAS (6, mismo orden que el C-Script PLANTA):
%   theta, alpha, dtheta, dalpha  : verdad de la planta.
%   theta_meas, alpha_meas        : medida emulada del encoder (cuantizada 2pi/2048,
%                                   alpha UNWRAPPED como el encoder incremental real); lo que ve el control.

    persistent x init
    if isempty(init)
        x    = x0(:);
        init = true;
    end

    h = Ts / nsub;
    for s = 1:nsub
        k1 = f_con_tope(x,          Vm);
        k2 = f_con_tope(x + h/2*k1, Vm);
        k3 = f_con_tope(x + h/2*k2, Vm);
        k4 = f_con_tope(x + h*k3,   Vm);
        x  = x + (h/6)*(k1 + 2*k2 + 2*k3 + k4);
    end

    theta  = x(1);
    alpha  = x(2);
    dtheta = x(3);
    dalpha = x(4);

    % ===== EMULACION DEL ENCODER (espejo del Output function del C-Script, sec 1.5)
    QUANT_EN = true;           % 1=cuantiza como el encoder real; 0=medida ideal
    Q = 2.0*pi/2048.0;         % Q_TH = Q_AL
    if QUANT_EN
        thq        = Q*floor(theta/Q + 0.5);
        alq        = Q*floor(alpha/Q + 0.5);
        theta_meas = thq;
        alpha_meas = alq;                         % UNWRAPPED (encoder incremental, como el real): solo cuantiza, NO envuelve
    else
        theta_meas = theta;
        alpha_meas = alpha;
    end
end


function xd = f_con_tope(x, Vm)
%#codegen
% Derivada del estado = dinamica analitica (C-Script sec 1.4) + par del tope en theta.

    % ===== PARAMETROS FISICOS (identicos a los #define del C-Script PLANTA) =====
    Jr     = 1.38e-4;      % inercia brazo+hub+rotor [kg m^2]
    mp     = 0.024;        % masa pendulo [kg]
    Lr     = 0.086;        % longitud brazo [m]
    lp     = 0.064325;     % pivote->CoM pendulo [m] (=Lp/2)
    Jp_cm  = 3.3101645e-5; % inercia pendulo respecto CoM [kg m^2]
    gg     = 9.7807;       % gravedad local (Cuenca) [m/s^2]  (= C-Script, = MechanismConfig 3D)
    kt     = 0.0422;       % constante de par [N m/A]
    km     = 0.0422;       % constante de fcem [V s/rad]
    Rm     = 7.5;          % resistencia armadura [Ohm]
    Dr     = 3.975e-4;     % viscoso mecanico brazo/motor [N m s/rad]
    Dp     = 0.0;          % viscoso pendulo (despreciable)
    kc     = 2.384e-3;     % rigidez torsional cable [N m/rad]
    theta0 = 0.0;          % reposo del cable [rad]
    Tdry   = 0.0;          % friccion seca en theta (eliminada)
    Tc_al  = 6.1e-6;       % Coulomb del pendulo [N m] (medido)
    EPSC   = 1.0e-3;       % suavizado tanh del Coulomb

    % ===== TOPE MECANICO theta = +-135 deg (calc_contact_limit.m, ensayo de impacto)
    th_max  = 2.3561944901923448;  % 135 deg en rad
    k_stop  = 50.0;                % N*m/rad   rigidez de penalizacion
    b_stop  = 0.037351;            % N*m*s/rad amortiguamiento (e~0.573 medido)
    J_theta = 2.2879e-4;           % kg*m^2    inercia con que se dedujo b_stop

    th = x(1); al = x(2); dth = x(3); dal = x(4);

    % --- dinamica base (Lagrangiano 2-DOF, identica al C-Script sec 1.4) ---
    c  = cos(al);
    s2 = sin(2.0*al);
    M11 = Jp_cm + Jr + Lr*Lr*mp + lp*lp*mp - Jp_cm*c*c - lp*lp*mp*c*c;
    M12 = Lr*lp*mp*c;
    M22 = Jp_cm + lp*lp*mp;
    h1  =  Jp_cm*dal*dth*s2 - Lr*dal*dal*lp*mp*sin(al) + dal*dth*lp*lp*mp*s2;
    h2  = -0.5*Jp_cm*dth*dth*s2 - gg*lp*mp*sin(al) - 0.5*dth*dth*lp*lp*mp*s2;
    tau_mot = kt*(Vm - km*dth)/Rm;
    tau_cab = kc*(th - theta0) + Tdry*tanh(dth/EPSC);
    Q1  = tau_mot - Dr*dth - tau_cab;   % planta: SIN perturbacion ficticia (d=0)
    Q2  = -Dp*dal - Tc_al*tanh(dal/EPSC);
    det = M11*M22 - M12*M12;

    ddth = ( M22*(Q1 - h1) - M12*(Q2 - h2))/det;
    ddal = (-M12*(Q1 - h1) + M11*(Q2 - h2))/det;

    % --- tope mecanico theta=+-135 deg: unilateral, solo empuja hacia adentro ---
    tau = 0.0;
    if th > th_max
        tau = -(k_stop*(th - th_max) + b_stop*dth);
        if tau > 0.0, tau = 0.0; end        % nunca tira hacia el centro
    elseif th < -th_max
        tau = -(k_stop*(th + th_max) + b_stop*dth);
        if tau < 0.0, tau = 0.0; end
    end
    ddth = ddth + tau/J_theta;

    xd = [dth; dal; ddth; ddal];
end
