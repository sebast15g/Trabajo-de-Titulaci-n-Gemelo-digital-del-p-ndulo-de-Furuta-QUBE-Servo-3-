function P = calibrar_modelo(logfiles)
% CALIBRAR_MODELO  Calibra los parámetros de fricción/cable del BRAZO contra el real,
%   regresando la perturbación d̂ del EKF (= par del brazo no modelado) sobre los
%   efectos físicos. Fundamento: d̂ es el sesgo del modelo [6]; su parte correlada
%   con (θ−θ0), tanh(θ̇), θ̇ son errores de parámetro [13]; lo que reste es estocástico.
%
%   P = calibrar_modelo                      usa 'log_simscape_E53*.mat'
%   P = calibrar_modelo({'a.mat','b.mat'})   lista de logs (BALANCEO; idealmente con excitación)
%
%   Modelo: τ_brazo incluye  −kc(θ−θ0) − Tdry·tanh(θ̇/ep) − Dr·θ̇ + d̂.
%   Devuelve P con kc, Tdry_th, Dr calibrados. Requiere: cargar_log_quarc, modelo_furuta_EKF.mat.

    ddir=fullfile(repo_root,'datos','calibracion_voltaje');   % logs de balanceo (E53)
    mdir=fullfile(repo_root,'datos','modelo_control');        % modelo_furuta_EKF.mat
    if nargin<1||isempty(logfiles), d=dir(fullfile(ddir,'log_simscape_E53*.mat')); logfiles={d.name}; end
    if ischar(logfiles)||isstring(logfiles), logfiles=cellstr(logfiles); end
    S=load(fullfile(mdir,'modelo_furuta_EKF.mat'),'p'); p=S.p; ep=1e-3; th0=p.theta0;

    % --- juntar el tramo de balanceo de todos los logs ---
    TH=[]; DTH=[]; DH=[];
    for i=1:numel(logfiles)
        fp=logfiles{i}; if ~isfile(fp), fp=fullfile(ddir,logfiles{i}); end
        D=cargar_log_quarc(fp); t=D(1,:); xh=D(4:7,:); dh=D(8,:); N=size(D,2);
        aw=atan2(sin(xh(2,:)),cos(xh(2,:))); bal=abs(aw)<deg2rad(15);
        dd=diff([0 bal 0]); s=find(dd==1); e=find(dd==-1)-1; [~,k]=max(t(e)-t(s));
        ini=find(t>=t(s(k))+1,1); reg=ini:e(k);
        TH=[TH xh(1,reg)]; DTH=[DTH xh(3,reg)]; DH=[DH dh(reg)]; %#ok
        fprintf('  %-26s : %d muestras de balanceo\n', logfiles{i}, numel(reg));
    end
    fprintf('Total muestras: %d\n', numel(DH));

    % --- regresión: d̂ = −[δkc·(θ−θ0) + δTdry·tanh(θ̇/ep) + δDr·θ̇] ---
    Phi=[(TH(:)-th0), tanh(DTH(:)/ep), DTH(:)];
    fprintf('Excitación (cond del regresor)=%.1f  (alto = poca excitación -> calibración pobre)\n', cond(Phi));
    beta = Phi\DH(:);                                  % ajuste d̂ ≈ Phi*beta
    delta = -beta;                                     % corrección de parámetros [δkc; δTdry; δDr]
    res = DH(:) - Phi*beta;                            % residual del ajuste por mínimos cuadrados
    fprintf('\nd̂ RMS antes=%.4f N·m | residual tras calibrar=%.4f N·m | explicado=%.0f%%\n', ...
        rms(DH), rms(res), 100*(1-rms(res)/rms(DH)));

    P.kc      = p.kc      + delta(1);
    P.Tdry_th = p.Tdry_th + delta(2);
    P.Dr      = p.Dr      + delta(3);
    fprintf('\n           actual        calibrado     Δ\n');
    fprintf('  kc      %9.3e   %9.3e   %+.2e\n', p.kc,      P.kc,      delta(1));
    fprintf('  Tdry_th %9.3e   %9.3e   %+.2e\n', p.Tdry_th, P.Tdry_th, delta(2));
    fprintf('  Dr      %9.3e   %9.3e   %+.2e\n', p.Dr,      P.Dr,      delta(3));
    fprintf('\nDÓNDE ajustar:\n');
    fprintf('  1) parametros_furuta.m -> p.kc=%.4g; p.Tdry_th=%.4g; p.Dr=%.4g;\n', P.kc,P.Tdry_th,P.Dr);
    fprintf('  2) re-correr derivar_modelo_furuta_EKF.m (re-hornea f_aug/Fc con los nuevos params)\n');
    fprintf('  3) modelo 3D/Simscape: el bloque Rotational Friction del brazo y el resorte del cable\n');
    fprintf('     deben usar los MISMOS valores (Coulomb=Tdry_th, viscoso=Dr, rigidez=kc).\n');
    fprintf('  (Motor: Rm,kt,km del manual no se calibran aquí; su fricción mecánica va dentro de Tdry_th.)\n');

    figure('Name','Calibración (d̂ vs ajuste)','Color','w','Position',[80 80 950 420]);
    plot(DH,'b'); hold on; plot(-(Phi*(-delta)),'r'); grid on; legend('d̂ (real)','ajuste físico','Location','best');
    ylabel('par brazo [N·m]'); title('d̂ del EKF y la parte explicada por fricción/cable (el resto es estocástico)');
end
