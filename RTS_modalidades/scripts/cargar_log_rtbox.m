function S = cargar_log_rtbox(fid_file, rt_file, Ts_cmp, Ts_model)
% CARGAR_LOG_RTBOX  Carga los .mat de la RT Box (fidelidad + tiempo real).
%   TIEMPO-MODELO = seq x Ts_model (por defecto 2e-3). Es la reconstruccion
%   CORRECTA: el C-Script loguea cada subtarea (subTaskPeriod[0]=4 x paso base
%   0.5 ms => 2 ms de MODELO por muestra), confirmado en el .c generado
%   (tesis_E*_RTBOX.c). El wall-clock NO define el paso del modelo: la box
%   corrio a RTF~=2 (avanza 2 ms de modelo por ~1 ms de pared), asi que usar el
%   reloj de pared para el eje temporal producia un factor 2 fantasma (la vieja
%   "box 2x off"). El wall-clock se conserva SOLO como diagnostico de RTS
%   (RTF, jitter, span), no para el tiempo del modelo.
%
%   S = cargar_log_rtbox(fid_file, rt_file [, Ts_cmp] [, Ts_model])
%     Ts_cmp   = malla de comparacion [s] (p.ej. 2e-3). Como la box ya loguea a
%                2 ms de modelo, con Ts_cmp=2e-3 la decimacion es identidad.
%     Ts_model = paso de modelo por muestra logueada [s] (def. 2e-3).
%
%   Layouts de filas admitidos (E1/E2, lazo abierto):
%     sin t_model (recomendado): fid=[seq, theta, alpha, dth, dal, th_meas, al_meas, Vm]  (8 filas)
%                                rt =[seq, yy, MM, dd, hh, mm, ss, us]                     (8 filas)
%     con t_model (layout viejo): fid=[seq, t_model, theta, ...]                           (9 filas)
%                                rt =[seq, t_model, yy, MM, ...]                           (9 filas)
%   E3 (lazo cerrado): fid=[seq, theta, alpha, dth, dal, th_meas, al_meas, Vm, ...] (16 filas).

    if nargin<3, Ts_cmp   = []; end
    if nargin<4, Ts_model = 2e-3; end
    f = load_mat_matrix(fid_file);
    r = load_mat_matrix(rt_file);

    % --- autodeteccion del layout por el numero de filas ---
    % 9 filas en E1/E2 => trae t_model; 8 => no. En E3 (16) no hay t_model.
    has_tmodel = (size(f,1) == 9);
    o = double(has_tmodel);              % offset: 1 si hay t_model, 0 si no

    seq  = f(1,:);
    gaps = sum(diff(seq)~=1);

    % --- TIEMPO-MODELO (autoritativo): seq x Ts_model ---
    t = (seq - seq(1)) * Ts_model;

    % --- Wall Clock del rt (SOLO diagnostico de RTS): yy MM dd hh mm ss us ---
    b = 2 + o;                           % 1a fila del wall clock (yy)
    RTF = NaN; jitter = NaN; twall = []; Ts_wall = NaN; fecha = '';
    if size(r,1) >= b+6
        hh=r(b+3,:); mm=r(b+4,:); ss=r(b+5,:); us=r(b+6,:);
        twall = hh*3600 + mm*60 + ss + us*1e-6;  twall = twall - twall(1);
        if twall(end) > 0
            Ts_wall = twall(end)/(numel(seq)-1);         % pared por muestra
            RTF     = t(end)/twall(end);                 % modelo / pared (~2)
            jitter  = std(diff(twall) - median(diff(twall)));
        end
        yy=r(b,:); MM=r(b+1,:); dd=r(b+2,:);
        fecha = sprintf('%04d-%02d-%02d %02d:%02d:%06.3f', yy(1),MM(1),dd(1),hh(1),mm(1),ss(1)+us(1)*1e-6);
    end

    % --- senales fisicas del fid (empiezan tras seq[,t_model]) ---
    c = 2 + o;                           % 1a fila fisica (theta)
    S = struct();
    S.t=t; S.seq=seq; S.Ts_log=Ts_model; S.gaps=gaps; S.N=numel(t); S.has_tmodel=has_tmodel;
    S.theta=f(c,:); S.alpha=f(c+1,:); S.dtheta=f(c+2,:); S.dalpha=f(c+3,:);
    S.theta_meas=f(c+4,:); S.alpha_meas=f(c+5,:); S.Vm=f(c+6,:);
    S.twall=twall; S.jitter=jitter; S.RTF=RTF; S.Ts_wall=Ts_wall; S.fecha=fecha;
    S.D = [t; S.theta; S.alpha; S.dtheta; S.dalpha; S.theta_meas; S.alpha_meas; S.Vm];
    % Si es E3 (16 filas), adjuntar el resto del vector de fidelidad
    if size(f,1) >= 16
        S.theta_hat=f(c+7,:); S.alpha_hat=f(c+8,:); S.dtheta_hat=f(c+9,:); S.dalpha_hat=f(c+10,:);
        S.dhat=f(c+11,:); S.nis=f(c+12,:); S.mode=f(c+13,:); S.E=f(c+14,:);
    end

    fprintf('cargar_log_rtbox: N=%d  Ts_model=%.4g s (%.0f us, seq x2e-3)  t_model_row=%d  muestras_perdidas=%d\n', ...
            S.N, Ts_model, Ts_model*1e6, has_tmodel, gaps);
    if isfinite(RTF)
        fprintf('  [RTS diag] wall span=%.3f s | Ts_wall=%.0f us/muestra | RTF(model/wall)=%.3f  (box corrio a ~%.1fx tiempo real)\n', ...
                twall(end), Ts_wall*1e6, RTF, RTF);
    end
    if gaps>0, warning('cargar_log_rtbox:gaps','Hay %d saltos de seq (muestras perdidas).', gaps); end

    % --- decimacion opcional a la malla de comparacion (identidad si Ts_cmp=Ts_model) ---
    if ~isempty(Ts_cmp)
        ratio = Ts_cmp / Ts_model;  d = round(ratio);
        if abs(ratio - d) > 1e-6 || d < 1
            warning('cargar_log_rtbox:decim','Ts_cmp=%.4g no es multiplo entero de Ts_model=%.4g; no se decima.', Ts_cmp, Ts_model);
        else
            S.d=d; S.Ts_cmp=Ts_cmp;
            S.t2=S.t(1:d:end); S.D2=S.D(:,1:d:end); S.seq_2=S.seq(1:d:end);
            S.theta_2=S.theta(1:d:end); S.alpha_2=S.alpha(1:d:end);
            S.dtheta_2=S.dtheta(1:d:end); S.dalpha_2=S.dalpha(1:d:end);
            S.theta_meas_2=S.theta_meas(1:d:end); S.alpha_meas_2=S.alpha_meas(1:d:end); S.Vm_2=S.Vm(1:d:end);
            if d==1
                fprintf('  malla de comparacion = %.4g s (la box ya loguea a esa malla; decimacion identidad).\n', Ts_cmp);
            else
                fprintf('  decimado x%d -> malla %.4g s, N2=%d\n', d, Ts_cmp, numel(S.t2));
            end
        end
    end
end

function M = load_mat_matrix(fp)
    D = load(fp); fn = fieldnames(D); M = D.(fn{1});
    if size(M,1) > size(M,2), M = M.'; end
end
