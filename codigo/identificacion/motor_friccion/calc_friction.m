%% Identificacion experimental de la friccion del motor - QUBE-Servo 3
%  Estima la friccion del eje del motor (breakaway, Coulomb y viscosa) a partir
%  de un barrido par-velocidad. El par se obtiene de la corriente medida
%  (tau = kt*Im); las componentes de Coulomb y viscosa se ajustan a la recta
%  tau = Tc + b*w en la region de alta velocidad, y el par de breakaway se toma
%  como el maximo del par a baja velocidad.
%  Entrada : friction_2.csv  (columnas: t, Vm, Im, w)
%  Salida  : parametros identificados (consola) y figura par-velocidad.

clear; clc;

%% Parametros y carga de datos
kt = 0.0422;                         % constante de par del motor [N*m/A]
archivo = 'friction_2.csv';

opts = detectImportOptions(archivo);
opts.DataLines = [2 Inf];            % omite el encabezado
opts.VariableNamesLine = 0;
datos = readmatrix(archivo, opts);

t  = datos(:,1);                     % tiempo [s]
Vm = datos(:,2);                     % voltaje [V]
Im = datos(:,3);                     % corriente [A]
Wm = datos(:,4);                     % velocidad angular [rad/s]

% Descarta muestras no finitas
ok = isfinite(t) & isfinite(Vm) & isfinite(Im) & isfinite(Wm);
t = t(ok); Vm = Vm(ok); Im = Im(ok); Wm = Wm(ok);

%% Par electromagnetico y filtrado
tau_m = kt .* Im;                    % par [N*m]
ventana = 20;
Wm_f  = movmean(Wm, ventana);
tau_f = movmean(tau_m, ventana);

%% Friccion de breakaway: maximo del par a baja velocidad
idx_brk = abs(Wm_f) < 0.5 & abs(Wm_f) > 0.01;
if any(idx_brk)
    T_brk = prctile(abs(tau_f(idx_brk)), 95);          % percentil robusto al ruido
    idx_peak = find(abs(tau_f) >= T_brk & idx_brk, 1, 'first');
    if isempty(idx_peak), v_brk = 0.05; else, v_brk = abs(Wm_f(idx_peak)); end
else
    T_brk = 0; v_brk = 0.05;
end

%% Friccion de Coulomb y viscosa: ajuste lineal a alta velocidad
lim_vel  = prctile(abs(Wm_f), 80);
idx_alta = abs(Wm_f) > lim_vel;
p = polyfit(Wm_f(idx_alta), tau_f(idx_alta), 1);       % tau = b*w + Tc
b_viscous = p(1);
T_c_raw   = p(2);
T_c = abs(T_c_raw);
if b_viscous < 0, b_viscous = 0; end                   % coef. viscoso no negativo

%% Resultados
fprintf('Par de breakaway        : %e N*m\n',          T_brk);
fprintf('Velocidad de breakaway  : %e rad/s\n',        v_brk);
fprintf('Par de Coulomb          : %e N*m\n',          T_c);
fprintf('Coeficiente viscoso     : %e N*m/(rad/s)\n',  b_viscous);

%% Figura: par frente a velocidad angular
figure('Color','w','Position',[100 100 900 600]); hold on; grid on;

scatter(Wm, tau_m, 5, 'filled', 'MarkerFaceAlpha', 0.20, ...
        'MarkerFaceColor', [0.5 0.5 0.5], 'DisplayName', 'Datos crudos');

[Wm_s, is] = sort(Wm_f);
tau_s = movmean(tau_f(is), max(20, floor(numel(Wm_s)/20)));
plot(Wm_s, tau_s, 'LineWidth', 2.5, 'Color', [0 0.25 0.7], ...
     'DisplayName', 'Curva experimental');

w_plot = linspace(min(Wm_f), max(Wm_f), 300);
plot(w_plot, b_viscous*w_plot + T_c_raw, 'm-', 'LineWidth', 2.5, ...
     'DisplayName', 'Modelo viscoso');

yline( T_c,  'r--', 'LineWidth', 1.5, 'DisplayName', 'Coulomb');
yline(-T_c,  'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
yline( T_brk,'g--', 'LineWidth', 1.5, 'DisplayName', 'Breakaway');
yline(-T_brk,'g--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

xlabel('Velocidad angular \omega_m [rad/s]');
ylabel('Par \tau_m [N\cdotm]');
legend('Location', 'best');
