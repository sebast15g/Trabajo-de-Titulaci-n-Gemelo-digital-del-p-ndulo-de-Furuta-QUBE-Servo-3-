% DIAG_SWINGUP  Por que QSM (modelo analitico) hace un vaiven de mas en el swing-up.
% Compara alpha (continua, referenciada a balance=0, SIN voltear), Vm y energia de
% RTB / QSM / QHW en la fase de swing-up. Marca el umbral de captura (17 deg).
clear;
out=fullfile(repo_root,'RTS_modalidades','comparacion');   % figuras de salida dentro del repo
M={'RTB','fid_E3_rtbox.mat',3,8,16,15;   % {mod,fp, al_row, Vm_row, E_row, mode_row}
   'QSM','fid_E3_qsm.mat',4,9,17,16;
   'QHW','fid_E3_qhw.mat',4,5,13,12};
Cm={[0.85 0.1 0.1],[0.1 0.55 0.1],[0 0.2 0.9]}; Lm={'--','-.','-'}; Nm={'RTB','QSM','QHW (real)'};
DAT=cell(3,1);
fprintf('%-6s %8s %8s %10s %12s\n','mod','catch[s]','#vaiv','Vm0(signo)','min|a| prev.catch[deg]');
for k=1:3
  S=load(M{k,2}); f=fieldnames(S); D=S.(f{1}); if size(D,1)>size(D,2),D=D.';end
  if strcmp(M{k,1},'RTB'), t=(D(1,:)-D(1,1))*2e-3; else, t=D(1,:); end
  al=D(M{k,3},:); if strcmp(M{k,1},'QHW'), al=unwrap(al); end
  Vm=D(M{k,4},:); E=D(M{k,5},:); if max(abs(E))<1, E=E*1e3; end; mode=D(M{k,6},:);
  b=mode>0.5; ic=find(b,1); al=al-median(al(b));   % up=0 en balance
  % numero de vaivenes = cruces por cero de dalpha (picos de alpha) antes de catch
  da=[0 diff(al)]; zc=sum(da(1:ic-1).*da(2:ic)<0);
  % primer Vm significativo
  iv=find(abs(Vm)>0.1,1); s0=sign(Vm(iv));
  % min |alpha| en el vaiven previo a la captura
  seg=al(max(1,ic-round(0.4/ (t(2)-t(1)) )):ic); mprev=min(abs(seg))*180/pi;
  fprintf('%-6s %8.3f %8d %10d %12.1f\n', M{k,1}, t(ic), zc, s0, mprev);
  DAT{k}=struct('t',t,'al',al,'Vm',Vm,'E',E,'ic',ic);
end
% figura swing-up (primeros 3.5 s)
f=figure('Color','w','Position',[60 50 1000 760]); tiledlayout(3,1,'Padding','compact');
ax1=nexttile; hold(ax1,'on'); H=gobjects(1,3);
for k=1:3, S=DAT{k}; H(k)=plot(ax1,S.t,S.al*180/pi,'Color',Cm{k},'LineStyle',Lm{k},'LineWidth',1.2+(k==3)*0.3); end
grid(ax1,'on'); xlim(ax1,[0 3.6]); yl=yline(ax1,17,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off'; yl=yline(ax1,-17,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
ylabel(ax1,'\alpha [deg] (arriba=0)'); legend(ax1,H,Nm,'Location','southeast'); title(ax1,'Swing-up \alpha (umbral captura \pm17°)');
ax2=nexttile; hold(ax2,'on');
for k=1:3, S=DAT{k}; plot(ax2,S.t,S.Vm,'Color',Cm{k},'LineStyle',Lm{k},'LineWidth',1.0+(k==3)*0.3); end
grid(ax2,'on'); xlim(ax2,[0 3.6]); ylabel(ax2,'V_m [V]'); title(ax2,'V_m de swing-up');
ax3=nexttile; hold(ax3,'on');
for k=1:3, S=DAT{k}; plot(ax3,S.t,S.E,'Color',Cm{k},'LineStyle',Lm{k},'LineWidth',1.0+(k==3)*0.3); end
grid(ax3,'on'); xlim(ax3,[0 3.6]); yl=yline(ax3,30.2,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
ylabel(ax3,'E [mJ]'); xlabel(ax3,'t [s]'); title(ax3,'Energía (Er=30.2 mJ)');
exportgraphics(f,fullfile(out,'diag_swingup_qsm.png'),'Resolution',140); close(f);
fprintf('figura -> diag_swingup_qsm.png\n');
