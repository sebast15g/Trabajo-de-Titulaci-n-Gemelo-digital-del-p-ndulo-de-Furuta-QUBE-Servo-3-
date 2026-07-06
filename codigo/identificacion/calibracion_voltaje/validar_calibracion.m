function P = validar_calibracion(logfile, t_fit, optimizar)
% VALIDAR_CALIBRACION  Calibra/valida el modelo por ERROR DE SALIDA contra una
%   corrida de excitación (péndulo colgando -> estable -> la simulación no diverge).
%   Simula furuta_f_param con el Vm logueado y ajusta [Dr, Tdry_th, kc] minimizando
%   el error en θ. Fundamento: identificación grey-box / output-error [13].
%
%   P = validar_calibracion(archivo[, [t0 t1]][, optimizar])
%     t_fit: ventana de ajuste (default [2 20] s). optimizar: true (default) o false (solo línea base).
%
%   Log esperado (variable Vm_theta_alpha): filas 1=t, 2=Vm, 3=theta, 4=alpha
%   (alpha no se usa aqui: la calibracion por error de salida se ajusta en theta).
%   Requiere: cargar_log_quarc, furuta_f_param, modelo_furuta_EKF.mat.

    if nargin<1||isempty(logfile), logfile='log_simscape_E6_calibrat.mat'; end
    if nargin<2||isempty(t_fit), t_fit=[2 20]; end
    if nargin<3, optimizar=true; end
    mdir=fullfile(repo_root,'datos','modelo_control');        % modelo_furuta_EKF.mat
    D=cargar_log_quarc(logfile); t=D(1,:); Vm=D(2,:); thm=D(3,:); Ts=median(diff(t));
    S=load(fullfile(mdir,'modelo_furuta_EKF.mat'),'p'); p=S.p;
    p0=[p.Dr; p.Tdry_th; p.kc];                       % parámetros a calibrar
    fijo=[p.theta0; p.Tc_alpha; p.Dp; p.Jr];          % no se calibran aquí
    Vmf=griddedInterpolant(t,Vm,'previous');
    x0=[thm(1); pi; 0; 0];                            % reposo, péndulo COLGANDO (α=π)
    msk=t>=t_fit(1)&t<=t_fit(2);

    cost=@(pr) rmse_theta(abs(pr), fijo, Vmf, t, thm, x0, Ts, msk);
    rmse0=cost(p0);
    fprintf('=== Calibración por error de salida — %s ===\n', logfile);
    fprintf('Ventana de ajuste: [%.1f, %.1f] s\n', t_fit(1),t_fit(2));
    fprintf('RMSE(θ) con parámetros ACTUALES = %.3f°\n', rmse0*180/pi);

    P=struct('Dr',p.Dr,'Tdry_th',p.Tdry_th,'kc',p.kc,'rmse0_deg',rmse0*180/pi);
    if optimizar
        opt=optimset('Display','iter','MaxIter',120,'MaxFunEvals',300,'TolX',1e-9);
        pc=fminsearch(@(pr) cost(abs(pr)), p0, opt); pc=abs(pc);
        rmsec=cost(pc);
        fprintf('\nRMSE(θ) CALIBRADO = %.3f°   (mejora %.0f%%)\n', rmsec*180/pi, 100*(1-rmsec/rmse0));
        fprintf('\n           actual       calibrado\n');
        fprintf('  Dr      %9.3e   %9.3e\n', p.Dr, pc(1));
        fprintf('  Tdry_th %9.3e   %9.3e\n', p.Tdry_th, pc(2));
        fprintf('  kc      %9.3e   %9.3e\n', p.kc, pc(3));
        fprintf('\nDÓNDE: parametros_furuta.m (p.Dr,p.Tdry_th,p.kc) -> re-derivar -> mismos en Simscape/3D.\n');
        P.Dr=pc(1); P.Tdry_th=pc(2); P.kc=pc(3); P.rmsec_deg=rmsec*180/pi;
        prdraw=pc;
    else, prdraw=p0; end

    % --- figura: θ medido vs simulado (actual y calibrado) ---
    [~,thsim0]=rmse_theta(p0,fijo,Vmf,t,thm,x0,Ts,true(size(t)));
    [~,thsimc]=rmse_theta(prdraw,fijo,Vmf,t,thm,x0,Ts,true(size(t)));
    figure('Name','Calibración (θ medido vs modelo)','Color','w','Position',[60 60 1050 520]);
    plot(t,thm*180/pi,'b',t,thsim0*180/pi,'r--',t,thsimc*180/pi,'g-.'); grid on
    xlabel('t [s]'); ylabel('\theta [°]'); legend('real','modelo actual','modelo calibrado','Location','best');
    hold on; yl=ylim; patch([t_fit(1) t_fit(2) t_fit(2) t_fit(1)],[yl(1) yl(1) yl(2) yl(2)],'y','FaceAlpha',0.06,'EdgeColor','none');
    title('θ: real vs modelo (zona sombreada = ajuste; resto = validación)')
end

function [r, thsim] = rmse_theta(pr, fijo, Vmf, t, thm, x0, Ts, msk)
    prm=[pr(1);pr(2);pr(3);fijo(1);fijo(2);fijo(3);fijo(4)];   % [Dr;Tdry;kc;th0;Tcal;Dp;Jr]
    N=numel(t); X=zeros(4,N); X(:,1)=x0; nsub=4; h=Ts/nsub;
    for k=1:N-1
        x=X(:,k); u=Vmf(t(k));
        for s=1:nsub                                   % RK4 sub-pasos (estable con fricción rígida)
            k1=furuta_f_param(x,u,prm); k2=furuta_f_param(x+h/2*k1,u,prm);
            k3=furuta_f_param(x+h/2*k2,u,prm); k4=furuta_f_param(x+h*k3,u,prm);
            x=x+h/6*(k1+2*k2+2*k3+k4);
        end
        if ~all(isfinite(x)), X(:,k+1:end)=1e3; break; end
        X(:,k+1)=x;
    end
    thsim=X(1,:); e=thsim(msk)-thm(msk); r=sqrt(mean(e.^2));
end
