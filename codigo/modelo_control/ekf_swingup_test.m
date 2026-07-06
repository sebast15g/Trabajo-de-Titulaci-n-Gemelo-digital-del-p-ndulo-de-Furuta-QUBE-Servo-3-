%% VERIFICACION DEL EKF EN SWING-UP + BALANCEO (con unwrap de alpha)
%  El swing-up lleva alpha por abajo (±180), donde la convencion convertida da el
%  salto de wrap. El EKF es continuo, asi que se DESENVUELVE alpha (unwrap) antes de
%  entrar. Verifica que el filtro aguanta toda la maniobra y como queda d_hat.
%  (En tiempo real el unwrap se hace incremental; aqui, offline, con unwrap().)
run('parametros_furuta.m');
fn='log_simscape_swing_balance.mat';
lf=fn;   % en datos/modelo_control, resuelto por el path (setup_paths)
L=load(lf);
t=L.t(:); Vm=L.Vm(:); th_m=L.theta_m(:); al_m=L.alpha_m(:);
N=numel(t); Ts=median(diff(t));

% Desenvolver angulos (continuos para el EKF)
th_u=unwrap(th_m); al_u=unwrap(al_m);
fprintf('N=%d Ts=%.5f Tf=%.2f s\n', N, Ts, t(end));
fprintf('alpha medida [%.0f,%.0f]deg -> desenvuelta [%.0f,%.0f]deg\n', ...
    rad2deg(min(al_m)),rad2deg(max(al_m)),rad2deg(min(al_u)),rad2deg(max(al_u)));

Q=diag([1e-7 1e-7 1e-5 1e-5 1e-7]);
sth=p.q_theta/sqrt(12); sal=p.q_alpha/sqrt(12); R=diag([sth^2 sal^2]);
xa=[th_u(1); al_u(1); (th_u(2)-th_u(1))/Ts; (al_u(2)-al_u(1))/Ts; 0];
P=diag([0.02 0.02 1 1 1e-6]);
Xh=zeros(5,N); NIS=zeros(1,N);
for k=1:N
  u=Vm(k);
  F=eye(5)+Ts*furuta_Fc(xa,u); xp=xa+Ts*furuta_f_aug(xa,u); Pp=F*P*F'+Q;
  H=furuta_Hjac(xp,u); yh=furuta_meas(xp,u); Sk=H*Pp*H'+R; Kk=Pp*H'/Sk;
  innov=[th_u(k);al_u(k)]-yh; xa=xp+Kk*innov; P=(eye(5)-Kk*H)*Pp;
  Xh(:,k)=xa; NIS(k)=innov'/Sk*innov;
end
i0=max(2,round(0.3/Ts));
rmse_th=sqrt(mean((th_u-Xh(1,:)').^2)); rmse_al=sqrt(mean((al_u-Xh(2,:)').^2));
fprintf('NIS(>0.3s)=%.2f | RMSE theta=%.4f deg, alpha=%.4f deg | max|estados| finito=%d\n', ...
    mean(NIS(i0:end)), rad2deg(rmse_th), rad2deg(rmse_al), all(isfinite(Xh(:))));

figure('Color','w','Position',[60 60 1000 600]);
subplot(3,2,1); plot(t,rad2deg(al_u),'b',t,rad2deg(Xh(2,:)),'r--'); ylabel('\alpha desenv.[deg]'); legend('medida','EKF'); grid on;
subplot(3,2,2); plot(t,rad2deg(th_u),'b',t,rad2deg(Xh(1,:)),'r--'); ylabel('\theta[deg]'); grid on;
subplot(3,2,3); plot(t,Xh(4,:),'r'); ylabel('\alpha dot[rad/s]'); grid on;
subplot(3,2,4); plot(t,Xh(3,:),'r'); ylabel('\theta dot[rad/s]'); grid on;
subplot(3,2,5); plot(t,Xh(5,:)*1e3,'r'); ylabel('d_{hat}[mN m]'); xlabel('t[s]'); grid on;
subplot(3,2,6); plot(t,NIS,'b'); yline(2,'r--'); ylabel('NIS'); xlabel('t[s]'); grid on;
sgtitle('EKF en swing-up + balanceo (alpha desenvuelta)');
exportgraphics(gcf,'ekf_swingup_test.png','Resolution',150);
fprintf('Figura: ekf_swingup_test.png\n');
