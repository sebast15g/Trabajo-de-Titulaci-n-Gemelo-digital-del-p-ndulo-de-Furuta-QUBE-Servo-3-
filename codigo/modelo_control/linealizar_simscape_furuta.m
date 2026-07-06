%% LINEALIZACION DEL MODELO SIMSCAPE DEL FURUTA EN EL EQUILIBRIO SUPERIOR
%  Gemelo Digital - obtiene A,B del modelo digital validado para confirmar Jr
%  y disenar el LQR sobre el modelo real-equivalente.
%  Requiere Simulink Control Design.  Ver instrucciones_linealizacion_simscape.md
%
%  Adaptar los nombres marcados con <...> al modelo propio. Usar el .slx que inicializa
%  cerca del equilibrio superior (balance/LQR/PD), no el de swing-up.
% --------------------------------------------------------------------------
run('parametros_furuta.m');

mdl = 'Ensamblaje_pendulo_furuta_multibody_v4';        % modelo a linealizar (ej. 'control_modelo_digital_pendulo')
load_system(mdl);

%% 1) Punto de operacion = equilibrio superior EXACTO (alpha = 0 arriba, reposo)
% IMPORTANTE: el equilibrio es alpha = 0 EXACTO (par neto nulo). El offset de +-10..20 deg
% que se usa como condicion inicial para que el balance atrape el pendulo NO es el punto
% de operacion: ahi alpha_ddot ~= 0, no es equilibrio, y linealizar alli SESGA A,B.
%
% Opcion A (recomendada si el balance estabiliza en sim): deja que el controlador lleve
% el pendulo a upright y tomar el snapshot cuando ya este quieto (estado asentado = equilibrio).
op = findop(mdl, 0);          % snapshot (con el pendulo ya balanceado y quieto)
%
% Opcion B (trim analitico): forzar alpha = 0 y derivadas = 0 (estado estacionario).
%   opspec = operspec(mdl);
%   % fijar la salida/estado alpha = 0 (Known) y SteadyState = true; findop resuelve Vm
%   op = findop(mdl, opspec);
%
% Opcion C: si fijas la condicion inicial del revolute EXACTAMENTE en 0 (= arriba):
%   op = findop(mdl, 0);      % snapshot en t = 0 (valido SOLO si la IC es 0 exacto)

%% 2) Puntos de analisis lineal (marcas en senales; NO son bloques; no se desconecta nada)
% 'openinput' = inyecta la entrada Y abre el lazo en esa misma senal (un solo punto).
% Ubicarlo en la senal que ENTRA a la planta (salida del controlador / Manual Switch -> motor).
%io(1) = linio([mdl '/<senal_Vm_a_la_planta>'], 1, 'openinput');  % entrada + apertura del lazo
%io(2) = linio([mdl '/<senal_theta>'], 1, 'output');             % salida theta
%io(3) = linio([mdl '/<senal_alpha>'], 1, 'output');             % salida alpha
% io(4) = linio([mdl '/<senal_theta_dot>'], 1, 'output');       % (si existe)
% io(5) = linio([mdl '/<senal_alpha_dot>'], 1, 'output');       % (si existe)
io = getlinio(mdl);
%% 3) Linealizar la planta en lazo abierto en ese punto de operacion
linsys = linearize(mdl, op, io);
%% 4) Resultados al workspace
A_sim = linsys.A;  B_sim = linsys.B;  C_sim = linsys.C;  D_sim = linsys.D;
assignin('base','linsys',linsys);
fprintf('Nro de estados del linsys: %d\n', size(A_sim,1));
fprintf('Autovalores Simscape (debe aparecer el inestable ~ +13.6):\n'); disp(eig(A_sim).');

%% 5) Comparar con el modelo analitico
if isfile('modelo_furuta_EKF.mat')
    S = load('modelo_furuta_EKF.mat','A','B');
    fprintf('Autovalores analiticos:\n'); disp(eig(S.A).');
    fprintf('-> Si el polo inestable coincide, Jr esta bien; si no, usar el de Simscape.\n');
end

%% 6) (Opcional) Diseno del LQR sobre el modelo Simscape
% Si linsys es limpio de 4 estados [theta, alpha, dtheta, dalpha]:
   Qc = diag([1 10 0.1 0.1]); Rc = 1;
   K_sim = lqr(A_sim, B_sim, Qc, Rc)
% Si tiene estados extra (motor electrico, cuaternion): reducir antes
%   sysr = minreal(linsys);   % o balred(...)
%   y verificar que queden los 4 estados mecanicos.
