%% EVALUAR EL EKF SOBRE UN LOG DEL SIMSCAPE (etapa 2: Simscape = "verdad")
%  Corre el EKF analitico (4+1 estados) sobre datos registrados del modelo Simscape
%  de alta fidelidad (con cable y friccion). Mide el desajuste modelo-planta antes
%  del tiempo real. Version offline: se ejecuta el Simscape y se guarda el log,
%  este script corre el EKF encima y compara.
%
%  ENTRADA esperada (.mat 'log_simscape.mat') con vectores columna del mismo largo:
%     t, Vm, theta_m, alpha_m, Im_m      (medidas; theta/alpha en convencion ARRIBA=0)
%  OPCIONAL (si registraste la verdad del Simscape para comparar):
%     theta_t, alpha_t, dtheta_t, dalpha_t
%  (Se obtienen registrando en Simulink theta, alpha de los Revolute, la corriente
%   del Current Sensor y Vm, todos a Ts; guardar con save('log_simscape.mat',...).)
% --------------------------------------------------------------------------
run('parametros_furuta.m');
lf='log_simscape.mat';                 % log de alta fidelidad (Simscape 3D con cable y friccion)
L = load(lf);
t = L.t(:); Vm = L.Vm(:); y = [L.theta_m(:) L.alpha_m(:)].';   % solo encoders (Im no se usa)
N = numel(t); Ts = median(diff(t));
have_truth = all(isfield(L,{'theta_t','alpha_t','dtheta_t','dalpha_t'}));

%% EKF (mismo nucleo que ekf_step.m, en bucle offline)
Q = diag([1e-7 1e-7 1e-5 1e-5 1e-4]);      % Q desplegada (= ekf_step.m); fila de d grande para que varie
R = diag([7.84e-7 7.84e-7]);               % R = q^2/12 (cuantizacion del encoder)
xa = [y(1,1); y(2,1); (y(1,2)-y(1,1))/Ts; (y(2,2)-y(2,1))/Ts; 0];  % init vel por diferencia finita
P  = diag([0.02 0.02 1 1 1e-6]);
Xh = zeros(5,N); NIS = zeros(1,N);
for k = 1:N
    u = Vm(k);
    F = eye(5)+Ts*furuta_Fc(xa,u);
    xp = xa + Ts*furuta_f_aug(xa,u);  Pp = F*P*F'+Q;
    H = furuta_Hjac(xp,u);  yh = furuta_meas(xp,u);
    Sk = H*Pp*H'+R;  Kk = Pp*H'/Sk;  innov = y(:,k)-yh;
    xa = xp + Kk*innov;  P = (eye(5)-Kk*H)*Pp;
    Xh(:,k)=xa; NIS(k)=innov'/Sk*innov;
end
fprintf('NIS medio = %.2f  (ideal ~ dim(y)=2)\n', mean(NIS));

%% Graficas
figure('Color','w','Position',[60 60 1000 600]);
subplot(3,2,1); plot(t,rad2deg(y(1,:)),'b'); hold on; plot(t,rad2deg(Xh(1,:)),'r--');
ylabel('\theta [deg]'); legend('medida','EKF'); grid on;
subplot(3,2,2); plot(t,rad2deg(y(2,:)),'b'); hold on; plot(t,rad2deg(Xh(2,:)),'r--');
ylabel('\alpha [deg]'); grid on;
subplot(3,2,3); plot(t,Xh(3,:),'r'); ylabel('\theta dot [rad/s]'); grid on;
subplot(3,2,4); plot(t,Xh(4,:),'r'); ylabel('\alpha dot [rad/s]'); grid on;
subplot(3,2,5); plot(t,Xh(5,:)*1e3,'r'); ylabel('d_{hat} [mN\cdotm]'); xlabel('t [s]'); grid on; ylim([-3 3]);
subplot(3,2,6); plot(t,NIS,'b'); yline(2,'r--'); ylabel('NIS'); xlabel('t [s]'); grid on; ylim([0 20]);

if have_truth
    Xt = [L.theta_t(:) L.alpha_t(:) L.dtheta_t(:) L.dalpha_t(:)].';
    rmse = sqrt(mean((Xt - Xh(1:4,:)).^2, 2));
    fprintf('RMSE vs verdad Simscape: theta=%.3e alpha=%.3e dtheta=%.3e dalpha=%.3e\n', rmse);
    subplot(3,2,1); plot(t,rad2deg(Xt(1,:)),'k:'); legend('medida','EKF','verdad');
    subplot(3,2,2); plot(t,rad2deg(Xt(2,:)),'k:');
    subplot(3,2,3); hold on; plot(t,Xt(3,:),'k:');
    subplot(3,2,4); hold on; plot(t,Xt(4,:),'k:');
end
exportgraphics(gcf,'ekf_sobre_log.png','Resolution',150);
fprintf('Figura guardada: ekf_sobre_log.png\n');
