% OVERLAY_QHW_RTB  Overlays QHW (real, M0) vs RTB (RT Box) para E1/E2/E3,
% para comprobar visualmente que la box corregida (seq x2ms) reproduce al real.
outdir=fullfile(repo_root,'RTS_modalidades','comparacion');   % figuras de salida dentro del repo

% ============ E1: caida libre ============
% RTB(8): seq,th,al,...   QHW(6): t,seq,tmod,th,al,Vm
Rb=ld('fid_E1_rtbox.mat'); tb=(Rb(1,:)-Rb(1,1))*2e-3; alb=Rb(3,:);
Qh=ld('fid_E1_qhw.mat');     tq=Qh(1,:);                 alq=Qh(5,:);
% QHW: recortar el tramo sostenido ARRIBA (al~0) antes de soltar
low=alq<0.4; dd=diff([0 low 0]); s0=find(dd==1); e0=find(dd==-1)-1;
[~,mi]=max(e0-s0); irel=e0(mi);                 % soltada = fin del hold mas largo
tq=tq-tq(irel);                                  % t=0 en la soltada
% alinear ambos por el 1er cruce ascendente de pi (colgado)
tb=tb-tcross(tb,alb); tq=tq-tcross(tq,alq);
f=figure('Color','w','Position',[80 80 950 420]);
plot(tq,alq*180/pi,'b','LineWidth',1.3); hold on; plot(tb,alb*180/pi,'r--','LineWidth',1.3); grid on;
xlim([0 10]); yline(180,':k'); xlabel('t desde el colgado [s]'); ylabel('\alpha [deg]');
legend('QHW (real M0)','RTB (RT Box)','Location','northeast');
title('E1 caída libre — \alpha: real vs RT Box (f_n 1.82 vs 1.76 Hz)');
sv(f,fullfile(outdir,'overlay_E1_qhw_vs_rtbox.png'));

% ============ E2: respuesta forzada (misma excitacion, onset 1 s) ============
Rb=ld('fid_E2_rtbox.mat'); tb=(Rb(1,:)-Rb(1,1))*2e-3; alb=Rb(3,:); thb=Rb(2,:);
Qh=ld('fid_E2_qhw.mat');     tq=Qh(1,:);                 alq=Qh(5,:); thq=Qh(4,:);
f=figure('Color','w','Position',[80 80 950 620]); tiledlayout(2,1,'Padding','compact');
nexttile; plot(tq,alq*180/pi,'b','LineWidth',1.0); hold on; plot(tb,alb*180/pi,'r--','LineWidth',1.0); grid on;
xlim([0 35]); ylabel('\alpha [deg]'); legend('QHW (real M0)','RTB','Location','northeast'); title('\alpha (péndulo)');
nexttile; plot(tq,thq*180/pi,'b','LineWidth',1.0); hold on; plot(tb,thb*180/pi,'r--','LineWidth',1.0); grid on;
xlim([0 35]); yline(135,':k'); yline(-135,':k'); ylabel('\theta [deg]'); xlabel('t [s]'); title('\theta (brazo), tope \pm135°');
sv(f,fullfile(outdir,'overlay_E2_qhw_vs_rtbox.png'));

% ============ E3: lazo cerrado (swing-up + balance) ============
% alpha respecto a ARRIBA (wrapToPi): up=0, colgado=+-180
Rb=ld('fid_E3_rtbox.mat'); tb=(Rb(1,:)-Rb(1,1))*2e-3; alb=wrp(Rb(3,:)); thb=Rb(2,:);
Qh=ld('fid_E3_qhw.mat');     tq=Qh(1,:);                 alq=wrp(Qh(4,:)); thq=Qh(3,:);
% que ambos hagan el ultimo vaiven previo a la captura desde el mismo lado
if sign_prebalance(alb,Rb(15,:))<0, alb=-alb; end
if sign_prebalance(alq,Qh(12,:))<0, alq=-alq; end
f=figure('Color','w','Position',[80 80 950 620]); tiledlayout(2,1,'Padding','compact');
nexttile; plot(tq,alq*180/pi,'b','LineWidth',1.0); hold on; plot(tb,alb*180/pi,'r--','LineWidth',1.1); grid on;
xlim([0 8]); yline(0,':k'); ylabel('\alpha [deg] (arriba=0)'); legend('QHW (real M0)','RTB','Location','northeast');
title('\alpha: swing-up y balance (captura ~2.7 s)');
nexttile; plot(tq,thq*180/pi,'b','LineWidth',1.0); hold on; plot(tb,thb*180/pi,'r--','LineWidth',1.0); grid on;
xlim([0 8]); ylabel('\theta [deg]'); xlabel('t [s]'); title('\theta (brazo)');
sv(f,fullfile(outdir,'overlay_E3_qhw_vs_rtbox.png'));

fprintf('OK: overlay_E1/E2/E3_qhw_vs_rtbox.png en %s\n', outdir);

% ---- helpers ----
function M=ld(fp), S=load(fp); fn=fieldnames(S); M=S.(fn{1}); if size(M,1)>size(M,2),M=M.';end; end
function t0=tcross(t,al)
  % primer cruce ascendente de pi (colgado); si no, t(1)
  i=find(al(1:end-1)<pi & al(2:end)>=pi,1); if isempty(i),t0=t(1);else,t0=t(i);end
end
function y=wrp(a), y=atan2(sin(a),cos(a)); end
function s=sign_prebalance(al,mode)
  ic=find(mode>0.5,1); if isempty(ic)||ic<50,s=1;return; end
  seg=al(max(1,ic-200):ic-1); [~,im]=max(abs(seg)); s=sign(seg(im)); if s==0,s=1;end
end
function sv(f,png), exportgraphics(f,png,'Resolution',140); close(f); end
