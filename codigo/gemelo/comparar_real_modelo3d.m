function comparar_real_modelo3d(log_real, log_modelo)
% COMPARAR_REAL_MODELO3D  Verificacion de construccion (§4.8): corre en paralelo
%   el equipo REAL y el gemelo 3D (Simscape), cada uno con su propio EKF + control
%   y los MISMOS parametros, y compara theta, alpha y Vm. Es un chequeo CUALITATIVO
%   de que el gemelo se comporta como el real bajo el mismo control; la fidelidad
%   cuantitativa (metricas de la Metodologia) se reporta en Resultados.
%
%   Ambos logs: matriz [t; theta_m; alpha_m; Vm; xhat(4)] (convencion alpha=0 arriba).
%   El gemelo 3D suele quedar en ESPEJO DE CONVENCION (theta,alpha con signo opuesto);
%   el script lo detecta por correlacion y lo corrige automaticamente.
%
%   USO: comparar_real_modelo3d                 % nombres por defecto
%        comparar_real_modelo3d('log_simscape_comp_real.mat','log_simscape_comp_modelo.mat')

    if nargin<1, log_real  ='log_simscape_comp_real.mat';   end
    if nargin<2, log_modelo='log_simscape_comp_modelo.mat'; end
    gv=@(f) getfield(load(f), char(fieldnames(load(f)))); %#ok<GFLD>
    R=gv(log_real); M=gv(log_modelo);
    if size(R,1)>size(R,2), R=R.'; end
    if size(M,1)>size(M,2), M=M.'; end

    t=R(1,:); thR=R(2,:); alR=R(3,:); VmR=R(4,:);
    thM=M(2,:); alM=M(3,:); VmM=M(4,:);
    wrap=@(x) mod(x+pi,2*pi)-pi;

    % --- correccion automatica de signo (espejo de convencion del 3D) ---
    if corr(thR.',thM.') < 0, thM=-thM; end
    if corr(wrap(alR).',wrap(alM).') < corr(wrap(alR).',wrap(-alM).'), alM=-alM; end
    alRw=wrap(alR); alMw=wrap(alM); dg=@(x) x*180/pi;

    % --- metricas de comportamiento (cualitativas) ---
    sut=@(al) local_sut(t,wrap(al));
    tR=sut(alR); tM=sut(alM);
    bR=abs(alRw)<deg2rad(20); bM=abs(alMw)<deg2rad(20);
    fprintf('--- Verificacion de construccion: real vs gemelo 3D ---\n');
    fprintf('  t_swingup  : real %.2f s | modelo %.2f s\n', tR, tM);
    fprintf('  alpha balance RMS: real %.2f deg | modelo %.2f deg\n', dg(rms(alRw(bR))), dg(rms(alMw(bM))));
    fprintf('  Vm RMS: real %.3f V | modelo %.3f V   (Vm max: %.2f / %.2f V)\n', ...
            rms(VmR), rms(VmM), max(abs(VmR)), max(abs(VmM)));

    % --- figura ---
    f=figure('Color','w','Position',[60 60 1000 720]);
    subplot(3,1,1); hold on; grid on;
    plot(t,dg(thR),'b','LineWidth',1.4,'DisplayName','real (M0)');
    plot(t,dg(thM),'r--','LineWidth',1.2,'DisplayName','modelo 3D (M2)');
    ylabel('\theta [deg]'); legend('Location','best');
    title('Verificacion de construccion: real y gemelo 3D en paralelo (lazos independientes, mismo control)');
    subplot(3,1,2); hold on; grid on;
    plot(t,dg(alRw),'b','LineWidth',1.4,'DisplayName','real');
    plot(t,dg(alMw),'r--','LineWidth',1.2,'DisplayName','modelo 3D');
    ylabel('\alpha [deg]'); legend('Location','best');
    subplot(3,1,3); hold on; grid on;
    plot(t,VmR,'b','LineWidth',1.0,'DisplayName','real');
    plot(t,VmM,'r--','LineWidth',1.0,'DisplayName','modelo 3D');
    ylabel('V_m [V]'); xlabel('t [s]'); legend('Location','best');
    try, exportgraphics(f,'verificacion_construccion.png','Resolution',140); catch, end
end

function ts=local_sut(t,alw)
    idx=find(abs(alw)<deg2rad(20) & t>0.3, 1);
    if isempty(idx), ts=NaN; else, ts=t(idx); end
end
