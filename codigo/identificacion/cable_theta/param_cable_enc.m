% =========================================================================
% Identificacion del amortiguamiento del cable del encoder (junta theta)
% Furuta QUBE-Servo 3 - Gemelo Digital
%
% La respuesta libre del brazo (llevado a ~90 deg y liberado, sin voltaje) es
% no oscilatoria: retorna sin sobrepaso y queda retenida por la friccion seca
% dentro de la banda muerta del cable. En ese regimen sobreamortiguado el
% decremento logaritmico no es aplicable, de modo que el amortiguamiento se
% obtiene ajustando el transitorio de retorno a un modelo de segundo orden con
% la rigidez torsional del modelo. El valor de operacion se fija despues por
% calibracion contra la respuesta del sistema real.
% =========================================================================

% --- Parametros del modelo ---
J_arm       = 1.38e-4;     % inercia del brazo sobre theta (kg*m^2) = p.Jr del CAD (archivo central)
k_c         = 2.384e-3;    % rigidez torsional del cable adoptada (N*m/rad)
Dr_adoptado = 3.975e-4;    % amortiguamiento de operacion tras calibracion (N*m*s/rad)

% --- Datos ---
datos = readmatrix('cable_data_ang_2.csv');
t = datos(:,1); theta = datos(:,2);

% --- Aislar el transitorio de retorno (deteccion robusta de la liberacion) ---
[P, ip] = max(theta);                             % pico (~+90 deg) tras llevar el brazo
rel = find(t > t(ip) & theta < 0.9*P, 1, 'first');% liberacion = inicio del descenso
if isempty(rel), rel = ip; end
fin = find(t >= t(rel) + 1.3, 1, 'first');        % fin del retorno dominante (~1.3 s)
if isempty(fin), fin = numel(t); end
seg = rel:fin;  ts = t(seg) - t(seg(1));
eq  = mean(theta(t >= t(end) - 2));               % reposo: promedio de los ultimos 2 s
y   = theta(seg) - eq;  th0 = y(1);

% --- Ajuste del amortiguamiento (segundo orden, rigidez fija) ---
% Respuesta libre del sistema J*th'' + b*th' + k*th = 0, th(0)=th0, th'(0)=0.
sim2o = @(b) arrayfun(@(tt) [1 0]*expm([0 1; -k_c/J_arm, -b/J_arm]*tt)*[th0;0], ts);
cost  = @(b) sum((sim2o(b) - y).^2);
b_fit = fminbnd(cost, 1e-5, 3e-3);

zeta   = b_fit / (2*sqrt(k_c*J_arm));
rmse   = sqrt(cost(b_fit)/numel(ts));
factor = Dr_adoptado / b_fit;

% --- Reporte ---
fprintf('--- AMORTIGUAMIENTO DEL CABLE (ajuste de transitorio de retorno) ---\n');
fprintf('  b identificado        : %.4e N*m*s/rad   (zeta = %.2f, RMSE = %.4f rad)\n', b_fit, zeta, rmse);
fprintf('  Dr de operacion       : %.4e N*m*s/rad\n', Dr_adoptado);
fprintf('  factor de calibracion : %.2f   (Dr = factor * b_identificado)\n', factor);
fprintf('-------------------------------------------------------------------\n');

% --- Figura de validacion ---
yh   = sim2o(b_fit);
segP = rel:min(rel+1200, numel(t));   % ventana ampliada para mostrar el asentamiento
tsP  = t(segP) - t(segP(1));
f = figure('Color','w','Position',[200 200 700 400]);
plot(tsP, theta(segP), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Datos experimentales'); hold on;
plot(ts,  yh + eq,     'k--','LineWidth', 1.5, 'DisplayName', 'Ajuste de 2do orden');
yline(eq, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2, 'DisplayName', 'Reposo');
xlabel('Tiempo tras la liberacion [s]'); ylabel('Angulo del brazo \theta [rad]');
legend('Location', 'northeast'); grid on;
exportgraphics(f, 'cable_respuesta_libre.png', 'Resolution', 200);
