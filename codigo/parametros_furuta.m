%% PARAMETROS DEL FURUTA QUBE-SERVO 3  (archivo central de parametros)
%  Reune los parametros fisicos identificados y validados del gemelo digital en un
%  unico lugar. Se carga como PreLoadFcn/InitFcn de los modelos y desde setup_paths.
%  Convencion: alpha = 0 en el equilibrio SUPERIOR (pendulo invertido).
%  Unidades SI (rad, kg, m, N*m, A, V, s).
%
%   Entradas      : —  (script sin argumentos)
%   Salidas       : struct 'p' en el workspace base (assignin)
%   Dependencias  : —
%   Referencia    : §4.3 (identificacion de parametros) de la tesis.
%
%  Los valores marcados "verificar" conviene contrastarlos con el manual del
%  QUBE-Servo 3, el CAD o el modelo Simscape validado (Jr y Lr pueden leerse del
%  Simscape; ver derivar_modelo_furuta_EKF.m, opcion linearize).
% --------------------------------------------------------------------------

p = struct();

% --- Gravedad local (Cuenca) ---
p.g   = 9.7807;        % m/s^2  gravedad local (valor de registro). Debe coincidir con el
                       %        MechanismConfiguration del Model3d_Furuta_Pendulum y con el C-Script (gg).

% --- Pendulo (grado de libertad alpha) - validado ---
p.mp  = 0.024;         % kg     masa del pendulo (manual QUBE-3, Tabla 2.2)
p.Lp  = 0.12865;       % m      longitud del pendulo (medida con calibrador)
p.lp  = p.Lp/2;        % m      pivote -> centro de masa
p.Jp_cm = (1/12)*p.mp*p.Lp^2;          % kg*m^2  inercia del pendulo respecto a su CoM
p.Jp_piv = p.Jp_cm + p.mp*p.lp^2;      % = (1/3) mp Lp^2  (respecto al pivote)
% Disipacion de alpha: Coulomb (no viscosa). T_C = 6.1e-6 medido en el ensayo de oscilacion
% libre (envolvente lineal R2=0.987 > exp 0.941 -> domina Coulomb; Amortiguamiento_alpha.m).
% Corresponde al Rotational Friction (Col_trq) del Model3d.
p.Tc_alpha = 6.1e-6;   % N*m    Coulomb en alpha (= Rotational Friction del Model3d, Col_trq)
p.Dp  = 0;             % N*m*s/rad  viscoso del pendulo (despreciable; f_visc~1.3e-5 no incluido)

% --- Brazo rotatorio (grado de libertad theta) ---
p.Lr  = 0.086;         % m      longitud del brazo (valor Quanser; = r del simulador)
p.mr  = 0.053;         % kg     masa del brazo (verificar: el manual lista 0.095; el simulador usa 0.053)
% Jr = inercia del brazo respecto al eje del motor (varilla uniforme sobre un extremo,
% (1/3)mr Lr^2, mas rotor). El termino mp*Lr^2 (pendulo en la punta) lo aporta M11 en el
% script de derivacion -> no incluirlo aqui para evitar doble conteo. Preferible leer la
% inercia real del eje theta del Simscape validado / CAD.
p.Jr  = 1.38e-4;       % kg*m^2  brazo+hub+disco+rotor respecto al eje del motor. Estimado del
                       %         CAD: 1.38e-4; coincide con (1/3)mr Lr^2 + rotor = 1.32e-4.
                       %         M11(0)=Jr+mp Lr^2 ~ 3.1e-4 (= Jr_eq del simulador).
p.Dr  = 3.975e-4;      % N*m*s/rad  viscoso mecanico del brazo/motor. Identificado por ajuste del
                       %         transitorio de retorno (param_cable_enc.m): b~7.49e-4 con
                       %         k=2.384e-3 (respuesta no oscilatoria; el decremento logaritmico
                       %         no aplica). Valor de operacion = 0.53*b tras calibracion via
                       %         Model3d (Revolute1 DampingCoefficient); absorbe la disipacion de
                       %         theta antes repartida con Tdry_th. La parte de fcem (kt*km/Rm) la
                       %         aporta el modelo del motor en f -> no sumarla aqui.

% --- Motor DC (QUBE-Servo 3) ---
p.Rm  = 7.5;           % Ohm    resistencia de armadura (manual)
p.kt  = 0.0422;        % N*m/A  constante de par (manual)
p.km  = 0.0422;        % V*s/rad constante de fcem (= kt)
p.Jm  = 1.4e-6;        % kg*m^2 inercia del rotor solo (manual; hub/disco van en el CAD)
p.Tc_motor = 2.91e-5;  % N*m    Coulomb del motor (ensayo de barrido par-velocidad, calc_friction.m)

% --- Cable del encoder en theta (recalibrado contra el real via Model3d) ---
% Valores tomados del Model3d_Furuta_Pendulum calibrado (junta Revolute1 = theta), que
% reproduce los vaivenes y curvas theta/alpha del QUBE real:
%   SpringStiffness = 2*1.192e-3 (histeresis) ; DampingCoefficient = 0.53*7.49e-4 (transitorio)
p.kc      = 2.384e-3;  % N*m/rad  rigidez torsional del cable (= 2*1.192e-3)
p.theta0  = 0;         % rad      reposo del cable (offset = artefacto de cero -> 0)
p.Tdry_th = 0;         % N*m      friccion seca sobre theta: no incluida. El Model3d no lleva
                       %          friccion seca en theta (el termino de Coulomb del cable
                       %          introducia oscilaciones ausentes en el real); la disipacion de
                       %          theta se representa solo como viscoso (p.Dr). Al cambiar este
                       %          valor debe regenerarse furuta_f_aug/_Fc/_f_param
                       %          (derivar_modelo_furuta_EKF.m); afecta la prediccion del EKF.

% --- Tiempo de muestreo ---
p.Ts  = 0.002;         % s   paso de QUARC (500 Hz). Antes 0.004 (250 Hz).

% --- Resolucion de encoders (para R del EKF) ---
p.q_alpha = 2*pi/2048; % rad/cuenta  (2048 cuentas/rev) -> 0.00307 rad
p.q_theta = 2*pi/2048; % rad/cuenta  (verificar resolucion del encoder del motor)

assignin('base','p',p);
fprintf('Parametros Furuta cargados (struct p).\n');
