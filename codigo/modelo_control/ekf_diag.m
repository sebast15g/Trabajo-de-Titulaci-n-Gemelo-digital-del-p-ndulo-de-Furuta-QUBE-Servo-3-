%% DIAGNOSTICO DEL EKF SOBRE EL LOG: retardo y NIS vs Q (y mejor inicializacion)
clear; clc;
run('parametros_furuta.m');
lf='log_simscape.mat';   % en datos/modelo_control, resuelto por el path (setup_paths)
L = load(lf);
t = L.t(:); Vm = L.Vm(:); y = [L.theta_m(:) L.alpha_m(:)].';
N = numel(t); Ts = median(diff(t));
fprintf('N=%d  Ts=%.5f s  Tf=%.2f s | theta[%.1f,%.1f]deg  alpha[%.1f,%.1f]deg\n', ...
    N, Ts, t(end), rad2deg(min(y(1,:))), rad2deg(max(y(1,:))), rad2deg(min(y(2,:))), rad2deg(max(y(2,:))));
fprintf('dt min/max = %.5f / %.5f  (¿paso fijo?)\n\n', min(diff(t)), max(diff(t)));

R = diag([7.84e-7 7.84e-7]);  Q0 = diag([1e-8 1e-8 1e-6 1e-6 1e-8]);
i0 = max(2,round(0.3/Ts));    % excluir 0.3 s de arranque del NIS

fprintf('  qs   NIS(full)  NIS(>0.3s)  retardo_alpha[ms]\n');
best=struct('lag',inf);
for qs = [1 10 100 1000]
  Q = Q0*qs;
  xa = [y(1,1); y(2,1); (y(1,2)-y(1,1))/Ts; (y(2,2)-y(2,1))/Ts; 0];  % init vel por dif. finita
  P  = diag([0.02 0.02 1 1 1e-6]);                                   % mas incertidumbre inicial en vel
  Xh = zeros(5,N); NIS = zeros(1,N);
  for k=1:N
    u=Vm(k);
    F=eye(5)+Ts*furuta_Fc(xa,u); xp=xa+Ts*furuta_f_aug(xa,u); Pp=F*P*F'+Q;
    H=furuta_Hjac(xp,u); yh=furuta_meas(xp,u); Sk=H*Pp*H'+R; Kk=Pp*H'/Sk;
    innov=y(:,k)-yh; xa=xp+Kk*innov; P=(eye(5)-Kk*H)*Pp;
    Xh(:,k)=xa; NIS(k)=innov'/Sk*innov;
  end
  lag = finddelay(y(2,:), Xh(2,:));
  fprintf('%5d  %9.2f  %9.2f  %12.1f\n', qs, mean(NIS), mean(NIS(i0:end)), lag*Ts*1e3);
  if abs(lag) < abs(best.lag), best.lag=lag; best.qs=qs; best.Xh=Xh; best.NIS=NIS; end
end

%% Grafica con la mejor qs
Xh=best.Xh;
figure('Color','w','Position',[60 60 1000 500]);
subplot(2,2,1); plot(t,rad2deg(y(1,:)),'b',t,rad2deg(Xh(1,:)),'r--'); ylabel('\theta[deg]'); legend('medida','EKF'); grid on; xlim([0 2]);
subplot(2,2,2); plot(t,rad2deg(y(2,:)),'b',t,rad2deg(Xh(2,:)),'r--'); ylabel('\alpha[deg]'); grid on; xlim([0 2]);
subplot(2,2,3); plot(t,Xh(5,:)*1e3,'r'); ylabel('d_{hat}[mN m]'); xlabel('t[s]'); grid on;
subplot(2,2,4); plot(t,best.NIS,'b'); yline(3,'r--'); ylabel('NIS'); xlabel('t[s]'); grid on; ylim([0 30]);
sgtitle(sprintf('Diagnostico EKF (mejor qs=%d, retardo=%d muestras)', best.qs, best.lag));
exportgraphics(gcf,'ekf_diag.png','Resolution',150);
fprintf('\nFigura: ekf_diag.png  | mejor qs=%d\n', best.qs);
