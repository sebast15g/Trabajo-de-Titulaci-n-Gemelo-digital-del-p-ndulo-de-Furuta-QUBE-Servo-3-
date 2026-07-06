function C = comparar_ekf_ukf(logfile, t_eval)
% COMPARAR_EKF_UKF  Corre EKF y UKF OFFLINE sobre el MISMO log real y compara
%   consistencia (NIS) y seguimiento. Valida el salto a UKF (alta fidelidad, [30])
%   sobre el modelo YA enriquecido (cable resorte + fricción seca/viscosa + d̂).
%
%   C = comparar_ekf_ukf(archivo[, [t0 t1]])
%
%   Ambos usan el mismo modelo (furuta_f_aug/_Fc/_meas) y las mismas Q,R.
%   El UKF (unscentedKalmanFilter, Control System Toolbox) propaga sigma-points
%   por la f no lineal (sin jacobiano) -> mejor con las no linealidades (tanh Coulomb).
%   Requiere: cargar_log_quarc, furuta_f_aug/_Fc/_meas/_Hjac, Control System Toolbox.

    if nargin<1||isempty(logfile), logfile='log_simscape_E53.mat'; end
    if nargin<2, t_eval=[]; end
    here=fileparts(mfilename('fullpath')); addpath(genpath(here));
    D=cargar_log_quarc(logfile); t=D(1,:); thm=D(2,:); alraw=D(3,:); xh=D(4:7,:); Ts=median(diff(t)); N=numel(t);
    % Vm = fila no binaria/no constante de mayor rango
    ex=8:size(D,1); isb=arrayfun(@(r) isequal(unique(D(r,:)),[0 1]),ex); isc=arrayfun(@(r) std(D(r,:))<1e-9,ex);
    rest=ex(~isb&~isc); [~,iv]=max(arrayfun(@(r) max(abs(D(r,:))),rest)); Vm=D(rest(iv),:);

    % medida de alpha en convención del EKF: wrap(alpha_raw) y signo que case con α̂ logueado
    alm=atan2(sin(alraw),cos(alraw));
    if mean(abs(atan2(sin(alm-xh(2,:)),cos(alm-xh(2,:))))) > mean(abs(atan2(sin(-alm-xh(2,:)),cos(-alm-xh(2,:)))))
        alm=-alm; end
    Y=[thm; alm];

    Q=diag([1e-7 1e-7 1e-5 1e-5 1e-4]); R=diag([7.84e-7 7.84e-7]);

    % ---------- EKF ----------
    xa=[Y(1,1);Y(2,1);0;0;0]; P=diag([0.02 0.02 1 1 1e-6]); I=eye(5);
    xe=zeros(5,N); nisE=nan(1,N);
    for k=1:N
        u=Vm(k); y=Y(:,k);
        F=I+Ts*furuta_Fc(xa,u); xp=xa+Ts*furuta_f_aug(xa,u); Pp=F*P*F.'+Q;
        H=furuta_Hjac(xp,u); yh=furuta_meas(xp,u); S=H*Pp*H.'+R;
        if ~all(isfinite(xp))||rcond(S)<1e-14, break; end
        inn=y-yh; nisE(k)=inn.'*(S\inn); Kk=Pp*H.'/S; xa=xp+Kk*inn; P=(I-Kk*H)*Pp; xe(:,k)=xa;
    end

    % ---------- UKF (con sub-pasos: el Coulomb-tanh es rígido, Euler a Ts es inestable) ----------
    nsub=8; Tsub=Ts/nsub;                     % Tsub=0.25ms < 0.5ms -> Euler estable para el modo de fricción
    fme=@(x,u) furuta_meas(x,u);
    ukf=unscentedKalmanFilter(@furuta_step_sub,fme,[Y(1,1);Y(2,1);0;0;0]);
    ukf.ProcessNoise=Q; ukf.MeasurementNoise=R; ukf.StateCovariance=diag([0.02 0.02 1 1 1e-6]);
    xu=zeros(5,N); nisU=nan(1,N);
    for k=1:N
        u=Vm(k);
        predict(ukf,u,Tsub,nsub);
        [res,Sk]=residual(ukf,Y(:,k),u); nisU(k)=res.'*(Sk\res);
        correct(ukf,Y(:,k),u); xu(:,k)=ukf.State;
    end

    % ---------- comparación (régimen de balanceo) ----------
    if isempty(t_eval)
        aw=atan2(sin(xh(2,:)),cos(xh(2,:))); bal=abs(aw)<deg2rad(15);
        dd=diff([0 bal 0]); s=find(dd==1); e=find(dd==-1)-1; [~,k]=max(t(e)-t(s));
        ini=find(t>=t(s(k))+1,1); reg=false(1,N); reg(ini:e(k))=true;
    else, reg=t>=t_eval(1)&t<=t_eval(2); end
    lo=0.0506; hi=7.378;
    fprintf('=== EKF vs UKF — %s (régimen balanceo) ===\n', logfile);
    fprintf('             NIS mediana   NIS media   %%en95\n');
    fprintf('  EKF        %8.2f    %8.2f    %5.1f%%\n', median(nisE(reg),'omitnan'),mean(nisE(reg),'omitnan'),100*mean(nisE(reg)>=lo&nisE(reg)<=hi));
    fprintf('  UKF        %8.2f    %8.2f    %5.1f%%\n', median(nisU(reg),'omitnan'),mean(nisU(reg),'omitnan'),100*mean(nisU(reg)>=lo&nisU(reg)<=hi));
    fprintf('  RMS(x̂_UKF − x̂_EKF) régimen: θ=%.2e α=%.2e θ̇=%.2e α̇=%.2e\n', ...
        rms(xu(1,reg)-xe(1,reg)),rms(xu(2,reg)-xe(2,reg)),rms(xu(3,reg)-xe(3,reg)),rms(xu(4,reg)-xe(4,reg)));
    C.nisE=median(nisE(reg),'omitnan'); C.nisU=median(nisU(reg),'omitnan');

    figure('Name','EKF vs UKF','Color','w','Position',[60 60 1000 640]);
    subplot(2,1,1); plot(t,nisE,'b',t,nisU,'r'); grid on; ylabel('NIS'); ylim([0 min(30,1.1*max([nisE(reg) nisU(reg)]))]);
        legend('EKF','UKF','Location','best'); title('Consistencia (NIS) — EKF vs UKF'); yline(2,'k:');
    subplot(2,1,2); plot(t,xe(3,:),'b',t,xu(3,:),'r--'); grid on; xlabel('t [s]'); ylabel('\thetȧ̂ [rad/s]');
        legend('EKF','UKF','Location','best'); title('velocidad estimada: EKF vs UKF')
    if any(reg), for q=1:2, subplot(2,1,q); hold on; yl=ylim; tt=t(reg);
        patch([tt(1) tt(end) tt(end) tt(1)],[yl(1) yl(1) yl(2) yl(2)],'y','FaceAlpha',0.06,'EdgeColor','none'); end, end
end

function xn=furuta_step_sub(x,u,Tsub,nsub)
% transición de estado discreta con sub-pasos de Euler (estabiliza el modo rígido del Coulomb)
    xn=x; for i=1:nsub, xn=xn+Tsub*furuta_f_aug(xn,u); end
end
