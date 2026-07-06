function R = procesar_rtbox()
% PROCESAR_RTBOX  Post-proceso de la modalidad RT Box (E1/E2/E3).
% Carga fidelidad + tiempo real, extrae metricas (fidelidad y RTS) y genera
% graficas limpias para redaccion.
%
% TIEMPO-MODELO = seq x 2e-3 (CORREGIDO). El C-Script loguea cada subtarea
% (subTaskPeriod[0]=4 x paso base 0.5 ms => 2 ms de MODELO por muestra),
% confirmado en tesis_E*_RTBOX.c. NO se usa el wall-clock para el eje temporal
% (la box corrio a RTF~=2: avanza 2 ms de modelo por ~1 ms de pared; usar el
% reloj de pared daba el factor 2 fantasma de la vieja "box 2x off"). El
% wall-clock se conserva SOLO como diagnostico de RTS (RTF).
%
% Set de datos DEFINITIVO (nombres canonicos, verificados por contenido):
%   E1: fid_E1_rtbox.mat / rt_rtbox_E1.mat   (Vm=0, caida libre)
%   E2: fid_E2_rtbox.mat / rt_rtbox_E2.mat   (RATIO=1, Vm arranca en t=1.0 s)
%   E3: fid_E3_rtbox.mat / rt_rtbox_E3.mat   (lazo cerrado, 16 filas)
%
% Estilo de graficas (tesis): un solo plot -> SIN titulo (el caption sera el
% titulo). Varios subplots -> cada subplot con su titulo, SIN titulo general.
% Ejes en grados para theta/alpha. exportgraphics a 140 dpi, fondo blanco.
%
% Salidas en RTS_SIM_RTBOX1/procesado/: *.png y un resumen R (struct) +
% metricas_rtbox.mat.

    Ts = 2e-3;                              % paso de modelo por muestra logueada
    here = fileparts(mfilename('fullpath'));
    root = fileparts(here);                 % RTS_SIM_RTBOX1
    out  = here;
    R = struct();

    % ================= E1 (caida libre, lazo abierto) =================
    D  = ldmat(fullfile(root,'E1_data','fid_E1_rtbox.mat'));    % 8 filas
    Rr = ldmat(fullfile(root,'E1_data','rt_rtbox_E1.mat'));
    [t, dg] = tiempo(D(1,:), Rr, Ts);
    th=D(2,:); al=D(3,:); Vm=D(8,:);
    [fn,ze] = fn_zeta(t, al);
    R.E1 = struct('fn',fn,'zeta',ze,'alpha_reposo',mean(al(end-500:end)), ...
                  'N',numel(t),'dur',t(end),'Vm_max',max(abs(Vm)), ...
                  'RTF',dg.RTF,'Ts_wall_us',dg.Ts_wall*1e6);
    f=figure('Color','w','Position',[80 80 900 520]); tiledlayout(2,1,'Padding','compact');
    nexttile; plot(t,al*180/pi,'LineWidth',1.1); grid on; ylabel('\alpha [deg]'); title('\alpha (péndulo)');
    nexttile; plot(t,th*180/pi,'LineWidth',1.1); grid on; ylabel('\theta [deg]'); xlabel('t [s]'); title('\theta (brazo)');
    savefig_clean(f, fullfile(out,'E1_rtbox_senales.png'));

    % ================= E2 (respuesta forzada, lazo abierto) =================
    D  = ldmat(fullfile(root,'E2_data','fid_E2_rtbox.mat'));    % 8 filas, RATIO=1
    Rr = ldmat(fullfile(root,'E2_data','rt_rtbox_E2.mat'));
    [t, dg] = tiempo(D(1,:), Rr, Ts);
    th=D(2,:); al=D(3,:); Vm=D(8,:);
    ion = find(abs(Vm)>0.05,1,'first');
    R.E2 = struct('theta_max_deg',max(abs(th))*180/pi,'alpha_range_deg',[min(al) max(al)]*180/pi, ...
                  'Vm_max',max(abs(Vm)),'Vm_onset_s',(ion-1)*Ts,'N',numel(t),'dur',t(end), ...
                  'RTF',dg.RTF,'Ts_wall_us',dg.Ts_wall*1e6);
    f=figure('Color','w','Position',[80 80 900 680]); tiledlayout(3,1,'Padding','compact');
    nexttile; plot(t,th*180/pi,'LineWidth',1.0); grid on; ylabel('\theta [deg]'); yline(135,':k'); yline(-135,':k'); title('\theta (brazo), topa en \pm135°');
    nexttile; plot(t,al*180/pi,'LineWidth',1.0); grid on; ylabel('\alpha [deg]'); title('\alpha (péndulo)');
    nexttile; plot(t,Vm,'k','LineWidth',1.0); grid on; ylabel('V_m [V]'); xlabel('t [s]'); title('Excitación V_m');
    savefig_clean(f, fullfile(out,'E2_rtbox_senales.png'));

    % ================= E3 (lazo cerrado: swing-up + balance + EKF) =================
    D  = ldmat(fullfile(root,'E3_data','fid_E3_rtbox.mat'));    % 16 filas
    Rr = ldmat(fullfile(root,'E3_data','rt_rtbox_E3.mat'));
    [t, dg] = tiempo(D(1,:), Rr, Ts);
    th=D(2,:); al=D(3,:); Vm=D(8,:); nis=D(14,:); mode=D(15,:); E=D(16,:);
    al = fix_alpha_convention(al, mode);   % ultimo vaiven antes de capturar desde el lado positivo
    icatch = find(mode>0.5,1,'first'); tcatch = t(icatch);
    bal = mode>0.5;
    R.E3 = struct('t_catch',tcatch,'balance_pct',100*mean(bal), ...
                  'alpha_std_bal_deg',std(al(bal))*180/pi,'theta_std_bal_deg',std(th(bal))*180/pi, ...
                  'nis_mean_bal',mean(nis(bal)),'Vm2_int',trapz(t,Vm.^2),'E_max_mJ',max(E)*1e3, ...
                  'N',numel(t),'dur',t(end),'RTF',dg.RTF,'Ts_wall_us',dg.Ts_wall*1e6);
    f=figure('Color','w','Position',[80 60 950 760]); tiledlayout(4,1,'Padding','compact');
    nexttile; plot(t,al*180/pi,'LineWidth',1.0); grid on; ylabel('\alpha [deg]'); yline(0,':k'); xline(tcatch,'r'); title('\alpha (arriba=0): swing-up y captura');
    nexttile; plot(t,th*180/pi,'LineWidth',1.0); grid on; ylabel('\theta [deg]'); xline(tcatch,'r'); title('\theta (brazo)');
    nexttile; plot(t,Vm,'k','LineWidth',1.0); grid on; ylabel('V_m [V]'); xline(tcatch,'r'); title('V_m de control');
    nexttile; yyaxis left; plot(t,E*1e3,'LineWidth',1.0); ylabel('E [mJ]'); yyaxis right; plot(t,mode,'LineWidth',1.0); ylabel('mode'); grid on; xlabel('t [s]'); title('Energía y conmutación (0=swing-up, 1=balance)');
    savefig_clean(f, fullfile(out,'E3_rtbox_senales.png'));
    % grafica sola de alpha (un solo plot, SIN titulo) -> caption en la tesis
    f=figure('Color','w','Position',[80 80 900 340]); plot(t,al*180/pi,'LineWidth',1.1); grid on;
    xlabel('t [s]'); ylabel('\alpha [deg]'); yline(0,':k');
    savefig_clean(f, fullfile(out,'E3_rtbox_alpha.png'));

    % ================= RTS: barridos de paso (open E2 / closed E3) =================
    R.sweep_open  = plot_sweep(fullfile(root,'E2_data','rts_sweep_openloop_E2.csv'),  fullfile(out,'rtbox_barrido_openloop.png'),  'lazo abierto (E1/E2)');
    R.sweep_close = plot_sweep(fullfile(root,'E3_data','rts_sweep_closedloop_E3.csv'), fullfile(out,'rtbox_barrido_closedloop.png'),'lazo cerrado (E3)');

    % resumen a consola
    fprintf('\n==== RESUMEN RT Box (tiempo-modelo = seq x 2 ms) ====\n');
    fprintf('E1: f_n=%.3f Hz  zeta=%.4f  dur=%.1fs  RTF=%.2f\n', R.E1.fn, R.E1.zeta, R.E1.dur, R.E1.RTF);
    fprintf('E2: theta_max=%.1f deg  alpha=[%.1f, %.1f] deg  Vm_onset=%.3fs  dur=%.1fs  RTF=%.2f\n', ...
            R.E2.theta_max_deg, R.E2.alpha_range_deg(1), R.E2.alpha_range_deg(2), R.E2.Vm_onset_s, R.E2.dur, R.E2.RTF);
    fprintf('E3: t_catch=%.3fs  balance=%.1f%%  alpha_std=%.2f deg  theta_std=%.2f deg  NIS=%.2f  intVm2=%.2f  Emax=%.1f mJ  RTF=%.2f\n', ...
            R.E3.t_catch, R.E3.balance_pct, R.E3.alpha_std_bal_deg, R.E3.theta_std_bal_deg, ...
            R.E3.nis_mean_bal, R.E3.Vm2_int, R.E3.E_max_mJ, R.E3.RTF);
    save(fullfile(out,'metricas_rtbox.mat'),'-struct','R');
    fprintf('OK. Graficas y metricas en %s\n', out);
end

% ---------- helpers ----------
function M = ldmat(fp)
    S=load(fp); fn=fieldnames(S); M=S.(fn{1}); if size(M,1)>size(M,2), M=M.'; end
end
function [t, diag] = tiempo(seq, Rr, Ts)
    % TIEMPO-MODELO autoritativo: seq x Ts (Ts=2e-3, del .c). El wall-clock es
    % SOLO diagnostico de RTS (RTF, Ts_wall).
    if nargin<3, Ts = 2e-3; end
    t = (seq - seq(1)) * Ts;
    diag = struct('RTF',NaN,'Ts_wall',NaN,'span_wall',NaN);
    % Solo computa el RTF si el rt casa en N con el fid (mismo run). Si no
    % (p.ej. E2, cuyo rt de la corrida buena no se conservo), RTF=NaN: el
    % hallazgo RTF~=2 queda establecido por E1 y E3 (mismo sustrato).
    if nargin>1 && ~isempty(Rr) && size(Rr,1)>=8 && size(Rr,2)==numel(seq)
        hh=Rr(5,:); mm=Rr(6,:); ss=Rr(7,:); us=Rr(8,:);   % rt=[seq,yy,MM,dd,hh,mm,ss,us]
        tw = hh*3600+mm*60+ss+us*1e-6; tw = tw - tw(1);
        if tw(end) > 0
            diag.span_wall = tw(end);
            diag.Ts_wall   = tw(end)/(numel(seq)-1);
            diag.RTF       = t(end)/tw(end);
        end
    end
end
function [fn,ze] = fn_zeta(t,a)
    fn=NaN; ze=0; a=a(:).'; t=t(:).'; n=numel(a);
    s=a-mean(a(max(1,n-round(0.1*n)):end));
    amp=max(abs(s(1:min(n,round(0.3*n))))); if amp<=0, return; end
    h=0.15*amp;                             % histeresis: evita doble-conteo por rizo
    zc=[]; armed=false;
    for i=1:n
        if s(i) < -h, armed=true; end
        if armed && s(i) > 0, zc(end+1)=i; armed=false; end %#ok<AGROW>
    end
    if numel(zc)<3, return; end
    fn=1/median(diff(t(zc)));
    Ts=median(diff(t)); minsep=max(1,round(0.6/fn/Ts)); last=-inf; pk=[];
    for i=2:numel(s)-1, if s(i)>s(i-1)&&s(i)>=s(i+1)&&s(i)>0&&(i-last)>=minsep, pk(end+1)=s(i); last=i; end; end %#ok<AGROW>
    if numel(pk)>=2, r=pk(1:end-1)./pk(2:end); r=r(r>0&isfinite(r)); d=median(log(r)); ze=d/sqrt(4*pi^2+d^2); end
end
function a = fix_alpha_convention(a, mode)
    ic = find(mode>0.5,1,'first'); if isempty(ic)||ic<50, return; end
    seg = a(max(1,ic-200):ic-1);
    [~,im] = max(abs(seg));
    if seg(im) < 0, a = -a; end
end
function T = plot_sweep(csv, png, etiqueta)
    T = readtable(csv);
    step = T.cpu_step_us; tet = T.tet_box_max_us; carga = T.carga_pct; over = T.overruns;
    [step,ix]=sort(step,'descend'); tet=tet(ix); carga=carga(ix); over=over(ix);
    f=figure('Color','w','Position',[80 80 950 560]); tiledlayout(2,1,'Padding','compact');
    nexttile; semilogx(step,tet,'o-','LineWidth',1.4); hold on; semilogx(step,step,'--'); grid on;
    set(gca,'XDir','reverse'); ylabel('TET / paso [\mus]'); legend('TET_{max}','paso base','Location','northwest');
    title(sprintf('TET vs paso base — %s', etiqueta));
    nexttile; yyaxis left; semilogx(step,carga,'s-','LineWidth',1.4); ylabel('carga [%]');
    yyaxis right; semilogx(step,over,'^-','LineWidth',1.4); ylabel('overruns'); grid on;
    set(gca,'XDir','reverse'); xlabel('paso base [\mus]'); title('Carga y overruns vs paso base');
    savefig_clean(f, png);
end
function savefig_clean(f, png)
    exportgraphics(f, png, 'Resolution', 140); close(f);
end
