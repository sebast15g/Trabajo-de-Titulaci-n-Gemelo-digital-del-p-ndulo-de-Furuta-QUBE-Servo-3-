%% validar_cable_libre.m  (v2)
%  Validacion de rigidez/amortiguamiento del cable (NO recalibra; solo comprueba).
%  Superpone la respuesta libre de theta del MODELO sobre la del REAL y reporta
%  el RMSE del retorno. Deteccion de liberacion robusta y alineacion de signo,
%  para no depender de en que sentido (+90 o -90) se solto en cada corrida.
%
%  COMO GENERAR LA CORRIDA DEL MODELO:
%    1) Abrir cable_identification_1.slx (o el modelo 3D). Fijar kc = 2.384e-3,
%       Dr = 3.975e-4 y, para este ensayo, la friccion seca Tdry_th activada.
%    2) Soltar el brazo desde ~90 deg (cualquier sentido) con motor sin voltaje.
%       Pendulo en su equilibrio estable de abajo (alpha = pi, alpha_dot = 0).
%    3) Loguear t, theta y exportar 'cable_libre_model_out.csv'  [t, theta] (rad).

clear; clc;
[tr0, thr0, eqr] = cargar_retorno('cable_data_ang_2.csv');      % REAL
[tm0, thm0, eqm] = cargar_retorno('cable_libre_model_out.csv'); % MODELO

% --- error en malla temporal comun ---
tg   = linspace(0, min(tr0(end), tm0(end)), 500);
ir   = interp1(tr0, thr0, tg);
im   = interp1(tm0, thm0, tg);
rmse = sqrt(mean((im - ir).^2));
fprintf('--- VALIDACION CABLE (retorno libre) ---\n');
fprintf('  Reposo  real = %.4f rad (%.2f deg) | modelo = %.4f rad (%.2f deg)\n', ...
        eqr, rad2deg(eqr), eqm, rad2deg(eqm));
fprintf('  RMSE theta modelo-vs-real = %.4f rad (%.2f deg)\n', rmse, rad2deg(rmse));

f = figure('Color','w','Position',[200 200 760 430]); hold on; grid on;
plot(tr0, thr0, 'b-','LineWidth',1.6,'DisplayName','Real');
plot(tm0, thm0, 'r--','LineWidth',1.6,'DisplayName','Modelo calibrado');
yline(eqr, ':','Color',[.5 .5 .5],'LineWidth',1.2,'DisplayName','Reposo real');
xlabel('Tiempo tras la liberacion [s]'); ylabel('Angulo del brazo \theta [rad]');
legend('Location','northeast');
% sin titulo: en la tesis el caption cumple esa funcion (RMSE va en consola/caption)
exportgraphics(f,'cable_validacion.png','Resolution',200);

function [tt, th, eqv] = cargar_retorno(arch)
%  Aisla el RETORNO tras la liberacion y lo deja con t=0 en la suelta.
%  Alinea el signo para que la excursion grande sea siempre hacia +90 deg.
    D = readmatrix(arch); t = D(:,1); x = D(:,2);
    ok = isfinite(t) & isfinite(x); t = t(ok); x = x(ok);  % descarta relleno NaN del export (To File)
    if abs(min(x)) > abs(max(x)), x = -x; end          % excursion -> positiva
    [P, ip] = max(x);                                   % pico (~+pi/2)
    idesc = find(t > t(ip) & x < 0.9*P, 1, 'first');    % inicio del descenso = suelta
    if isempty(idesc), idesc = ip; end
    tt = t(idesc:end) - t(idesc);  th = x(idesc:end);
    eqv = mean(th(tt >= 0.7*tt(end)));                  % reposo: tramo final
end
