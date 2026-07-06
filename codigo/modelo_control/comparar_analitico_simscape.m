%% comparar_analitico_simscape.m
%  Figura M1 (modelo analitico, ODE) vs M2 (Simscape 3D) ante la MISMA entrada Vm.
%  Alimenta la ODE furuta_f_param con el Vm logueado de una corrida de Simscape y
%  superpone theta y alpha; reporta el RMSE por estado.
%
%  COMO GENERAR LA CORRIDA DE SIMSCAPE (M2):
%   1) Correr el modelo 3D (Model3d_Furuta_Pendulum.slx o Ensamblaje_..._v4) en lazo
%      ABIERTO con una excitacion de Vm (p.ej. la de excitacion_Vm.mat o un chirp suave).
%      El pendulo puede arrancar cerca de alpha=0 (arriba) o colgando, segun lo que
%      se quiera mostrar; lo importante es que la entrada Vm sea la misma para ambos.
%   2) Loguear t, Vm, theta, alpha y exportar 'sim3d_run.csv' con columnas
%      [t, Vm, theta, alpha] (theta y alpha en rad).
%  Luego correr este script.

clear; clc;
run('parametros_furuta.m');                          % carga struct p
prm = [p.Dr; p.Tdry_th; p.kc; p.theta0; p.Tc_alpha; p.Dp; p.Jr];

D  = readmatrix('sim3d_run.csv');                    % [t, Vm, theta, alpha]
t  = D(:,1); Vm = D(:,2); th2 = D(:,3); al2 = D(:,4);
% El modelo 3D mide alpha con el cero en la posicion COLGANTE y signo opuesto;
% se convierte a la convencion analitica (alpha=0 ARRIBA): alpha_a = pi - alpha_s.
al2 = pi - al2;
Ts = median(diff(t)); N = numel(t);
Vmf = griddedInterpolant(t, Vm, 'previous');

% --- simular M1 (analitico) con el mismo Vm y la condicion inicial del log ---
X = zeros(4,N); X(:,1) = [th2(1); al2(1); 0; 0];
nsub = 4; h = Ts/nsub;                                % sub-pasos RK4 (fricciondura rigida)
for k = 1:N-1
    x = X(:,k); u = Vmf(t(k));
    for s = 1:nsub
        k1 = furuta_f_param(x,      u, prm);
        k2 = furuta_f_param(x+h/2*k1,u, prm);
        k3 = furuta_f_param(x+h/2*k2,u, prm);
        k4 = furuta_f_param(x+h*k3,  u, prm);
        x  = x + h/6*(k1+2*k2+2*k3+k4);
    end
    if ~all(isfinite(x)), X(:,k+1:end) = NaN; break; end
    X(:,k+1) = x;
end
th1 = X(1,:).'; al1 = X(2,:).';

rmse_th = sqrt(mean((th1-th2).^2,'omitnan'));
rmse_al = sqrt(mean((al1-al2).^2,'omitnan'));
fprintf('--- M1 (analitico) vs M2 (Simscape 3D) ---\n');
fprintf('  RMSE theta = %.3f deg | RMSE alpha = %.3f deg\n', rad2deg(rmse_th), rad2deg(rmse_al));

f = figure('Color','w','Position',[100 100 900 620]);
subplot(2,1,1); hold on; grid on;
plot(t, rad2deg(th2),'b-', 'LineWidth',1.6,'DisplayName','Simscape 3D (M2)');
plot(t, rad2deg(th1),'r--','LineWidth',1.6,'DisplayName','Analitico (M1)');
ylabel('\theta [deg]'); legend('Location','best');
subplot(2,1,2); hold on; grid on;
plot(t, rad2deg(al2),'b-', 'LineWidth',1.6,'DisplayName','Simscape 3D (M2)');
plot(t, rad2deg(al1),'r--','LineWidth',1.6,'DisplayName','Analitico (M1)');
xlabel('Tiempo [s]'); ylabel('\alpha [deg]'); legend('Location','best');
% sin titulo: en la tesis el caption cumple esa funcion (RMSE va en consola/caption)
exportgraphics(f,'analitico_vs_simscape.png','Resolution',200);
