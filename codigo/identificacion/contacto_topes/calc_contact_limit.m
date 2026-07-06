% CALC_CONTACT_LIMIT  Amortiguamiento del tope mecanico (b_stop) del brazo.
%   Estima el coeficiente de restitucion e a partir del ensayo de impacto
%   (velocidades de entrada y salida del rebote) y lo mapea al amortiguamiento
%   viscoso equivalente de Simscape mediante el modelo de Hunt-Crossley.
%
%   Entradas      : contact_limit.csv (t, ..., w, theta).
%   Salidas       : e, zeta, b_stop (consola) + figura del rebote.
%   Referencia    : seccion 4.3 (contacto en los topes +/-135 grados).

clc; clear; close all;

% 1. Cargar datos (saltando la primera fila defectuosa del CSV)
filename = 'contact_limit.csv';
data = readmatrix(filename, 'NumHeaderLines', 1);

t = data(:,1);       % Tiempo (s)
w = data(:,4);       % Vel. Angular (rad/s)
theta = data(:,5);   % Ángulo (rad)

% 2. Identificar el punto exacto del impacto
% El impacto ocurre cuando el encoder registra la penetración máxima
[theta_max, idx_impact] = max(theta);
t_impacto = t(idx_impact);

% v_in: Velocidad un instante justo antes de tocar el tope
v_in = w(idx_impact - 1); 

% v_out: Buscamos el rebote (el primer valor claramente negativo tras el impacto)
idx_out = idx_impact + 1;
while w(idx_out) >= 0 && (idx_out - idx_impact) < 10
    idx_out = idx_out + 1;
end
v_out = w(idx_out);

% 3. Cálculos físicos
% Coeficiente de restitución empírico (e)
e = abs(v_out) / abs(v_in);

% Factor de amortiguamiento (zeta) usando el modelo de Hunt-Crossley
zeta = -log(e) / sqrt(pi^2 + (log(e))^2);

% --- PARÁMETROS DE LA PLANTA ---
k_stop = 50; % N*m/rad (Valor de penalización rígida de la Fase 2)
J_theta = 2.2879e-4; % inercia validada del eje theta [kg*m^2] (p.Jr del archivo central)

% Amortiguamiento viscoso equivalente para Simscape
b_stop = 2 * zeta * sqrt(k_stop * J_theta);

% Ancho de transición (Fase 4)
tr_width = 0.001; % rad (Ajustado por debajo de la resolución del encoder)

% 4. Reporte en consola
fprintf('\n=== FASES 3 Y 4: CARACTERIZACIÓN DEL TOPE ===\n');
fprintf('Velocidad de entrada (v_in): %.2f rad/s\n', v_in);
fprintf('Velocidad de salida (v_out): %.2f rad/s\n', v_out);
fprintf('Coeficiente de restitución (e): %.4f (Devuelve el %.1f%% de la velocidad)\n', e, e*100);
fprintf('Factor de amortiguamiento deducido (zeta): %.4f\n', zeta);
fprintf('\n=== VALORES ABSOLUTOS PARA SIMSCAPE ===\n');
fprintf('Spring Stiffness (k_stop) : %.1f N*m/rad\n', k_stop);
fprintf('Damping Coeff (b_stop)    : %.6f N*m*s/rad\n', b_stop);
fprintf('Transition Region         : %.4f rad\n', tr_width);

% 5. Gráfica demostrativa para el documento de tesis
figure('Name', 'Perfil de Impacto', 'Color', 'w', 'Position', [100 100 800 400]);
plot(t, w, 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410]); hold on;

% Marcadores de entrada y salida
plot(t(idx_impact-1), v_in, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [0.4660 0.6740 0.1880], 'MarkerEdgeColor', 'k');
plot(t(idx_out), v_out, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [0.8500 0.3250 0.0980], 'MarkerEdgeColor', 'k');
yline(0, '--k', 'Color', [0.5 0.5 0.5]);

% Zoom en la zona de interés
xlim([t_impacto - 0.15, t_impacto + 0.15]);
xlabel('Tiempo (s)', 'FontWeight', 'bold');
ylabel('Velocidad Angular (rad/s)', 'FontWeight', 'bold');
title('Dinámica del Rebote Mecánico: Velocidad vs Tiempo', 'FontSize', 12);
legend('Velocidad del Brazo', sprintf('Impacto (%.2f rad/s)', v_in), sprintf('Rebote (%.2f rad/s)', v_out), 'Location', 'northeast');
grid on;