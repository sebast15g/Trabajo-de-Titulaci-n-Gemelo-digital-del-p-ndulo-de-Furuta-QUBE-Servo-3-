% FIGURAS_VM_BALANCE_ZOOM  Amplia la zona de balance de Vm, que a escala completa
% (swing-up + balance) se ve como una banda de ruido. Dos paneles: (arriba) Vm completo
% con la ventana de zoom sombreada; (abajo) zoom a la banda estacionaria de balance.
% Variantes ke=50 y ke=52. Adicion; no reemplaza comp_E3_Vm_4mod.png.
clear;
out=fullfile(repo_root,'RTS_modalidades','comparacion');   % figuras de salida dentro del repo
fp.RTB='fid_E3_rtbox.mat';
fp.QHW='fid_E3_qhw.mat';
fp.QSM='fid_E3_qsm.mat';
fp.SIM='fid_E3_sim.mat';
fp.QSM52='fid_E3_qsm_ke52.mat';
fp.SIM52='fid_E3_sim_ke52.mat';
C=containers.Map({'RTB','QSM','SIM','QHW'},{[0.85 0.1 0.1],[0.1 0.55 0.1],[0.55 0.3 0.85],[0 0.2 0.9]});
LS=containers.Map({'RTB','QSM','SIM','QHW'},{'--','-.',':','-'});
LB=containers.Map({'RTB','QSM','SIM','QHW'},{'RTB (RT Box)','QSM (QUARC-modelo)','SIM (offline)','QHW (real M0)'});

R=le3(fp.QHW,'QHW'); tcR=R.t(find(R.mode>0.5,1));
zlo=tcR+0.95; zhi=tcR+1.55;   % ventana de zoom (banda estacionaria)

make_fig(fp,{'RTB','QSM','SIM'},'QHW',C,LS,LB,out,'comp_E3_Vm_balance_zoom_4mod.png',zlo,zhi,'ke=50');
% ke=52: QSM/SIM analitico a ke=52 (etiquetas QSM/SIM pero datos ke52)
fp2=fp; fp2.QSM=fp.QSM52; fp2.SIM=fp.SIM52;
make_fig(fp2,{'RTB','QSM','SIM'},'QHW',C,LS,LB,out,'comp_E3_Vm_balance_zoom_ke52_4mod.png',zlo,zhi,'ke=52');
fprintf('OK -> comp_E3_Vm_balance_zoom{,_ke52}_4mod.png\n');

function make_fig(fp,mods,ref,C,LS,LB,out,png,zlo,zhi,tag)
  f=figure('Color','w','Position',[60 50 1000 720]); tl=tiledlayout(f,2,1,'Padding','compact');
  allm=[mods {ref}];
  % --- panel 1: Vm completo con ventana sombreada ---
  ax1=nexttile(tl); hold(ax1,'on'); H=gobjects(1,numel(allm));
  for j=1:numel(allm), mm=allm{j}; S=le3(fp.(mm),mm);
    H(j)=plot(ax1,S.t,S.Vm,'Color',C(mm),'LineStyle',LS(mm),'LineWidth',1.0+strcmp(mm,ref)*0.3);
  end
  yl=ylim(ax1); patch(ax1,[zlo zhi zhi zlo],[yl(1) yl(1) yl(2) yl(2)],[0.9 0.9 0.2], ...
       'FaceAlpha',0.15,'EdgeColor','none','HandleVisibility','off');
  grid(ax1,'on'); xlim(ax1,[0 6]); ylabel(ax1,'V_m [V]');
  legend(ax1,H,cellfun(@(m)LB(m),allm,'uni',0),'Location','northeast');
  title(ax1,sprintf('E3 — V_m completo (%s); recuadro = zona de balance ampliada',tag));
  % --- panel 2: zoom a la banda estacionaria ---
  ax2=nexttile(tl); hold(ax2,'on');
  for j=1:numel(allm), mm=allm{j}; S=le3(fp.(mm),mm);
    plot(ax2,S.t,S.Vm,'Color',C(mm),'LineStyle',LS(mm),'LineWidth',1.1+strcmp(mm,ref)*0.3);
  end
  grid(ax2,'on'); xlim(ax2,[zlo zhi]);
  yl2=yline(ax2,0,':k'); yl2.Annotation.LegendInformation.IconDisplayStyle='off';
  ylabel(ax2,'V_m [V]'); xlabel(ax2,'t [s]');
  title(ax2,'Zoom: V_m de control en balance (regulacion LQI, no ruido)');
  exportgraphics(f,fullfile(out,png),'Resolution',140); close(f);
end
function S=le3(fp,mm)
  Sr=load(fp); fn=fieldnames(Sr); M=Sr.(fn{1}); if size(M,1)>size(M,2),M=M.';end
  switch mm
    case 'RTB', S.t=(M(1,:)-M(1,1))*2e-3; S.Vm=M(8,:); S.mode=M(15,:);
    case {'QSM','SIM'}, S.t=M(1,:); S.Vm=M(9,:); S.mode=M(16,:);
    case 'QHW', S.t=M(1,:); S.Vm=M(5,:); S.mode=M(12,:);
  end
end
