%% PARAMETROS DEL FURUTA QUBE-SERVO 3  (archivo central, usar como PreLoadFcn/InitFcn)
%  Gemelo Digital - todos los parametros identificados/validados en un solo lugar.
%  Convencion: alpha = 0 en el equilibrio SUPERIOR (pendulo invertido).
%  Unidades SI (rad, kg, m, N*m, A, V, s).
% --------------------------------------------------------------------------
% NOTA: los marcados con (CONFIRMAR) deben verificarse contra el manual / CAD /
% el propio modelo Simscape antes de la entrega. Jr y Lr conviene leerlos del
% Simscape validado (ver derivar_modelo_furuta_EKF.m, opcion linearize).

p = struct();

% --- Gravedad local (Cuenca) ---
p.g   = 9.7807;        % m/s^2  gravedad local (valor de registro). OJO: fijar el MISMO valor en el
                       %        MechanismConfiguration del Model3d_Furuta_Pendulum y en el C-Script (gg).

% --- Pendulo (grado de libertad alpha) - VALIDADO ---
p.mp  = 0.024;         % kg     masa del pendulo (manual QUBE-3, Tabla 2.2)
p.Lp  = 0.12865;       % m      longitud del pendulo (calibrador)
p.lp  = p.Lp/2;        % m      pivote -> centro de masa
p.Jp_cm = (1/12)*p.mp*p.Lp^2;          % kg*m^2  inercia del pendulo respecto a su CoM
p.Jp_piv = p.Jp_cm + p.mp*p.lp^2;      % = (1/3) mp Lp^2  (respecto al pivote)
% Disipacion de alpha: Coulomb (no viscosa). T_C = 6.1e-6 MEDIDO en el ensayo de oscilacion libre
% (envolvente lineal R2=0.987 > exp 0.941 -> domina Coulomb; Amortiguamiento_alpha.m). Espejo del
% Rotational Friction (Col_trq) del Model3d. Antes 5.5e-6 (tuneo previo del 3D).
p.Tc_alpha = 6.1e-6;   % N*m    Coulomb en alpha (= Rotational Friction del Model3d, Col_trq)
p.Dp  = 0;             % N*m*s/rad  viscoso del pendulo (despreciable; f_visc~1.3e-5 no incluido)

% --- Brazo rotatorio (grado de libertad theta) ---
p.Lr  = 0.086;         % m      longitud del brazo (como en Quanser; = r del simulador.m)
p.mr  = 0.053;         % kg     masa del brazo (CONFIRMAR: el manual lista 0.095; simulador.m usa 0.053)
% Jr = inercia del brazo SOLO respecto al eje del motor (varilla uniforme sobre un
% extremo, (1/3)mr Lr^2) + rotor. El termino mp*Lr^2 (pendulo cargado en la punta)
% lo anade M11 dentro del script de derivacion -> NO incluirlo aqui (evita doble conteo).
% Preferible: leer la inercia real del eje theta del Simscape validado / CAD.
p.Jr  = 1.38e-4;       % kg*m^2  brazo+hub+disco+rotor respecto al eje del motor.
                       % Estimado del CAD (Jr_desde_CAD.m): 1.38e-4; coincide con
                       % (1/3)mr Lr^2 + rotor = 1.32e-4. M11(0)=Jr+mp Lr^2 ~ 3.1e-4 (= Jr_eq del simulador.m).
p.Dr  = 3.975e-4;      % N*m*s/rad  viscoso MECANICO del brazo/motor. Identificado por ajuste del
                       %  transitorio de retorno (param_cable_enc.m): b~8.24e-4 con k=2.384e-3 (la
                       %  respuesta es ligeramente subamortiguada, zeta~0.72; un solo sobrepaso pequeno).
                       %  Valor de operacion = 0.48*b tras calibracion via Model3d (Revolute1 DampingCoefficient);
                       %  absorbe la disipacion de theta antes repartida con Tdry_th.
                       %  La parte de fcem (kt*km/Rm) la anade el modelo del motor en f -> NO sumarla aqui.

% --- Motor DC (QUBE-Servo 3) ---
p.Rm  = 7.5;           % Ohm    resistencia de armadura (manual)
p.kt  = 0.0422;        % N*m/A  constante de par (manual)
p.km  = 0.0422;        % V*s/rad constante de fcem (= kt)
p.Jm  = 1.4e-6;        % kg*m^2 inercia del ROTOR solo (manual; el hub/disco van en el CAD)
p.Tc_motor = 2.91e-5;  % N*m    Coulomb del motor (tu ensayo tipo blog Quanser)

% --- Cable del encoder en theta (recalibrado contra el real via Model3d, jun-2026) ---
% Valores tomados del Model3d_Furuta_Pendulum tuneado (junta Revolute1 = theta), que
% reproduce los mismos vaivenes y curvas theta/alpha del QUBE real:
%   SpringStiffness = 2*1.192e-3 (histeresis) ; DampingCoefficient = 0.48*8.24e-4 (transitorio)
p.kc      = 2.384e-3;  % N*m/rad  rigidez torsional del cable (= 2*1.192e-3; antes 1.19e-3)
p.theta0  = 0;         % rad      reposo del cable (offset = artefacto de cero -> 0)
p.Tdry_th = 0;         % N*m      friccion seca sobre theta: ELIMINADA (antes 0.71e-3).
                       %          El Model3d no lleva friccion seca en theta: el termino
                       %          de Coulomb del cable metia oscilaciones que el real no
                       %          tiene -> se representa la disipacion de theta SOLO como
                       %          viscoso (p.Dr). OJO: al cambiar esto hay que REGENERAR
                       %          furuta_f_aug/_Fc/_f_param (derivar_modelo_furuta_EKF.m);
                       %          afecta la prediccion del EKF (ver nota al final).

% --- Tiempos de muestreo ---
p.Ts  = 0.002;         % s   paso de QUARC (500 Hz). Antes 0.004 (250 Hz).

% --- Resolucion de encoders (para R del EKF) ---
p.q_alpha = 2*pi/2048; % rad/cuenta  (2048 cuentas/rev) -> 0.00307 rad
p.q_theta = 2*pi/2048; % rad/cuenta  (CONFIRMAR resolucion del encoder del motor)

assignin('base','p',p);
fprintf('Parametros Furuta cargados (struct p).\n');
