function T = comparar_controladores(lista, col)
% COMPARAR_CONTROLADORES  Compara el desempeNo de varios controladores del banco a partir
%   de sus logs (uno por controlador). Tabula metricas de balanceo sobre el MISMO gemelo/real.
%
%   T = comparar_controladores(lista, col)
%     lista : cell Nx2 = {nombre, archivo_log; ...}  p.ej.
%             {'PD','log_pd.mat';'LQR','log_lqr.mat';'LQI','log_lqi.mat'}
%     col   : (opcional) indices de fila del log. Defecto = layout final:
%             col.t=1 col.alpha_real=3 col.alpha_hat=5 col.Vm=9 col.mode=10
%             (alpha_hat = x_hat(2) en la fila 5; ajustar si el layout difiere)
%   Devuelve una tabla T y la imprime. Metricas (en BALANCEO):
%     std_alpha[deg], RMSE_alpha[deg], esfuerzo=∫Vm^2 dt, Vm_rms, t_captura[s].

    if nargin<2 || isempty(col)
        col.t=1; col.alpha_real=3; col.alpha_hat=5; col.Vm=9; col.mode=10;
    end
    here=fileparts(mfilename('fullpath')); addpath(here);   % los logs se resuelven por el path (setup_paths)
    wrap=@(a) atan2(sin(a),cos(a)); d2=180/pi;

    n=size(lista,1); nombre=cell(n,1);
    std_alpha=zeros(n,1); rmse_alpha=zeros(n,1); esfuerzo=zeros(n,1); vm_rms=zeros(n,1); t_cap=zeros(n,1);
    for i=1:n
        nombre{i}=lista{i,1};
        D=cargar_log_quarc(lista{i,2});
        t=D(col.t,:); ar=D(col.alpha_real,:); Vm=D(col.Vm,:); Ts=median(diff(t));
        if isfield(col,'mode') && size(D,1)>=col.mode, md=D(col.mode,:); else, md=ones(size(t)); end
        % balanceo: mode==1 y |alpha|<10 deg sostenido
        bal = (md>0.5) & (abs(wrap(ar))<10*pi/180);
        % captura: primer instante de balanceo sostenido (>1 s)
        run=0; kc=NaN;
        for k=1:numel(bal), if bal(k),run=run+1; else,run=0; end; if run>=round(1/Ts), kc=k-run+1; break; end; end
        ba = false(size(t)); if ~isnan(kc), ba(kc:end)=true; end; ba=ba & bal;
        if ~any(ba), ba=bal; end
        aw=wrap(ar(ba));
        std_alpha(i)=std(aw)*d2;
        rmse_alpha(i)=sqrt(mean(aw.^2))*d2;
        esfuerzo(i)=sum(Vm(ba).^2)*Ts;
        vm_rms(i)=sqrt(mean(Vm(ba).^2));
        t_cap(i)=(~isnan(kc))*( (kc-1)*Ts ) + isnan(kc)*NaN;
    end
    T=table(nombre, std_alpha, rmse_alpha, vm_rms, esfuerzo, t_cap, ...
        'VariableNames',{'Controlador','std_alpha_deg','RMSE_alpha_deg','Vm_rms_V','esfuerzo_V2s','t_captura_s'});
    disp(' '); disp('=== COMPARACION DE CONTROLADORES (balanceo) ==='); disp(T);
    fprintf('Menor std_alpha = mas preciso; menor esfuerzo = mas eficiente; menor t_captura = mas rapido.\n');
end
