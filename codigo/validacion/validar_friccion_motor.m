%% validar_friccion_motor.m
%  Validacion del modelo de friccion del motor (NO recalibra; solo comprueba).
%  Superpone la curva par-velocidad del MODELO (friction_model.slx con los
%  parametros finales) sobre la del REAL (friction_2.csv) y reporta el error.
%
%  COMO GENERAR LA CORRIDA DEL MODELO:
%    1) Abrir friction_model.slx. Verificar que el bloque DC Motor / Rotational
%       Friction usa los valores finales de parametros_furuta.m:
%         T_brk = 4.10e-5 N*m, T_C = 2.92e-5 N*m, b = 4.34e-6 N*m*s/rad,
%         w_brk = 1.08e-2 rad/s.
%    2) Aplicar el MISMO barrido de Vm que el ensayo real (rampa lenta en ambos
%       sentidos, para barrer la velocidad).
%    3) Loguear t, Vm, Im, w y exportar a 'friction_model_out.csv'
%       con columnas [t, Vm, Im, w] (mismo formato que friction_2.csv).
%  Luego correr este script.

kt         = 0.0422;                 % constante de par [N*m/A]
arch_real  = 'friction_2.csv';
arch_model = 'friction_model_out.csv';

% El modelo exporta la corriente con polaridad OPUESTA al banco real
% (Vm<0 -> Im>0): se invierte el par del modelo para igualar convenciones.
flip_modelo = true;

[w_r, tau_r] = cargar_barrido(arch_real,  kt);
[w_m, tau_m] = cargar_barrido(arch_model, kt);
if flip_modelo, tau_m = -tau_m; end

[wr_s, tr_s] = curva_pv(w_r, tau_r);     % curva suavizada real
[wm_s, tm_s] = curva_pv(w_m, tau_m);     % curva suavizada modelo

% error solo en el rango de velocidad comun (sin extrapolar: fuera -> NaN)
tm_on_r = interp1(wm_s, tm_s, wr_s, 'linear');
val  = isfinite(tm_on_r);
rmse = sqrt(mean((tm_on_r(val) - tr_s(val)).^2));
fprintf('--- VALIDACION FRICCION MOTOR ---\n');
fprintf('  Rango omega comun = [%.1f, %.1f] rad/s  (%d puntos)\n', ...
        min(wr_s(val)), max(wr_s(val)), nnz(val));
fprintf('  RMSE par modelo-vs-real (curva p-v) = %.3e N*m\n', rmse);

f = figure('Color','w','Position',[100 100 900 600]); hold on; grid on;
scatter(w_r, tau_r, 5,'filled','MarkerFaceAlpha',0.12, ...
        'MarkerFaceColor',[.6 .6 .6],'DisplayName','Real (crudo)');
plot(wr_s, tr_s,'-','LineWidth',2.5,'Color',[0 .25 .7],'DisplayName','Real (curva)');
plot(wm_s, tm_s,'--','LineWidth',2.5,'Color',[.85 .1 .1],'DisplayName','Modelo calibrado');
xlabel('Velocidad angular \omega_m [rad/s]'); ylabel('Par \tau_m [N\cdotm]');
ylim(1.6*max(abs([tr_s; tm_s]))*[-1 1]);     % escala a las curvas, no a los outliers
legend('Location','best');
% sin titulo: en la tesis el caption cumple esa funcion (RMSE va en consola/caption)
exportgraphics(f,'friccion_validacion.png','Resolution',200);

function [w, tau] = cargar_barrido(arch, kt)
    opts = detectImportOptions(arch); opts.DataLines=[2 Inf]; opts.VariableNamesLine=0;
    D = readmatrix(arch, opts);
    t=D(:,1); Im=D(:,3); w=D(:,4);
    ok = isfinite(t)&isfinite(Im)&isfinite(w);
    w = w(ok); tau = kt*Im(ok);
end

function [ws, ts] = curva_pv(w, tau)
    wf = movmean(w,20); tf = movmean(tau,20);
    [wsrt,is] = sort(wf); tsrt = movmean(tf(is), max(20, floor(numel(wsrt)/20)));
    % colapsa velocidades repetidas (promedio del par) -> puntos unicos para interp1
    [ws, ~, ic] = unique(wsrt);
    ts = accumarray(ic, tsrt, [], @mean);
end
