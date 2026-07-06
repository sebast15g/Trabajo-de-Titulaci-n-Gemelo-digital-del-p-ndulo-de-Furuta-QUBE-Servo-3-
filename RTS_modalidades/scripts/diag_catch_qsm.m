% DIAG_CATCH_QSM  Por que la conmutacion a balance en QSM llega un vaiven tarde.
% La captura se decide con |alpha_hat| < 17 (EKF), NO con la alpha fisica. Compara
% alpha verdadera, alpha medida y alpha_hat (todas como desviacion de arriba) cerca
% de la captura, y marca cuando conmuta el modo.
clear;
out=fullfile(repo_root,'RTS_modalidades','comparacion');   % figuras de salida dentro del repo
S=load('fid_E3_qsm.mat'); f=fieldnames(S); D=S.(f{1}); if size(D,1)>size(D,2),D=D.';end
t=D(1,:); al=D(4,:); alm=D(8,:); alh=D(11,:); mode=D(16,:); nis=D(15,:);
w=@(x) atan2(sin(x),cos(x))*180/pi;   % desviacion de arriba en grados (0=arriba)
alw=w(al); almw=w(alm); alhw=w(alh);
ic=find(mode>0.5,1); tcatch=t(ic);
fprintf('QSM catch en t=%.3fs\n',tcatch);
% picos (minimos de |alpha|) por vaiven cerca de la captura -> ve cual entra a la banda
fprintf('en la captura: alpha_true=%.1f  alpha_meas=%.1f  alpha_hat=%.1f deg  (umbral 17)\n', alw(ic),almw(ic),alhw(ic));
% min|.| en el vaiven previo (t in [tcatch-0.6, tcatch-0.15])
m=t> (tcatch-0.65) & t< (tcatch-0.12);
fprintf('vaiven PREVIO (el que "deberia" capturar): min|alpha_true|=%.1f  min|alpha_hat|=%.1f deg\n', ...
        min(abs(alw(m))), min(abs(alhw(m))));
fprintf('NIS medio en swing-up=%.2f (alto => EKF inconsistente en swing-up)\n', mean(nis(t<tcatch & nis>0)));

f=figure('Color','w','Position',[60 60 1000 560]); ax=axes(f); hold(ax,'on');
h1=plot(ax,t,alw,'Color',[0 0.2 0.9],'LineWidth',1.4);
h2=plot(ax,t,almw,'Color',[0.9 0.5 0],'LineWidth',1.0,'LineStyle',':');
h3=plot(ax,t,alhw,'Color',[0.1 0.6 0.1],'LineWidth',1.2,'LineStyle','--');
yl=yline(ax,17,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
yl=yline(ax,-17,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
xl=xline(ax,tcatch,'r','LineWidth',1.2); xl.Annotation.LegendInformation.IconDisplayStyle='off';
grid(ax,'on'); xlim(ax,[1.5 3.4]); ylim(ax,[-60 60]);
xlabel(ax,'t [s]'); ylabel(ax,'\alpha (desv. de arriba) [deg]');
legend(ax,[h1 h2 h3],{'\alpha verdadera','\alpha medida','\alpha_{hat} (EKF, decide captura)'},'Location','southwest');
title(ax,sprintf('QSM E3 — captura por |\\alpha_{hat}|<17° (línea roja=conmutación a balance, t=%.2fs)',tcatch));
exportgraphics(f,fullfile(out,'diag_catch_qsm.png'),'Resolution',140); close(f);
disp('figura -> diag_catch_qsm.png');
