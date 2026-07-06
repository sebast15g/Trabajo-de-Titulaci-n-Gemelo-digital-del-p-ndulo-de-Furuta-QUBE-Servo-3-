% COMPARAR_4MOD  Comparacion de las 4 modalidades (RTB/QSM/QHW/SIM) del estudio.
% Tablas de fidelidad y RTS + figuras de overlay de alpha/theta contra el real (M0).
% En el swing-up (E3) se invierte el signo de alpha por modalidad para que el ultimo
% vaiven previo a la captura venga del mismo lado (calce visual).
clear;
out=fullfile(repo_root,'RTS_modalidades','comparacion'); if ~exist(out,'dir'),mkdir(out);end
% fuentes RTB estables + QSM/QHW/SIM (resueltas por el path a RTS_modalidades/<modalidad>)
fp.RTB1='fid_E1_rtbox.mat'; fp.RTB2='fid_E2_rtbox.mat'; fp.RTB3='fid_E3_rtbox.mat';
fp.QSM1='fid_E1_qsm.mat'; fp.QSM2='fid_E2_qsm.mat'; fp.QSM3='fid_E3_qsm.mat';
fp.QHW1='fid_E1_qhw.mat'; fp.QHW2='fid_E2_qhw.mat'; fp.QHW3='fid_E3_qhw.mat';
fp.SIM1='fid_E1_sim.mat'; fp.SIM2='fid_E2_sim.mat'; fp.SIM3='fid_E3_sim.mat';
mods={'RTB','QSM','SIM','QHW'};  col=containers.Map({'RTB','QSM','SIM','QHW'},{[0.85 0.1 0.1],[0.1 0.5 0.1],[0.5 0.3 0.8],[0 0.2 0.9]});
ls =containers.Map({'RTB','QSM','SIM','QHW'},{'--','-.',':','-'});

% ================= FIDELIDAD =================
fprintf('\n=========== FIDELIDAD (4 modalidades vs real M0=QHW) ===========\n');
fprintf('E1:  %-6s f_n=%.3f Hz  zeta=%.4f\n','',0,0);
R=struct();
for m=mods
  mm=m{1}; [t,al,~,~]=openm(fp.([mm '1']),mm);
  if strcmp(mm,'QHW'), [t,al]=crop_rel(t,al); end
  [fn,ze]=fnz(t,al); R.(mm).E1=[fn ze];
  fprintf('     %-6s f_n=%.3f Hz  zeta=%.4f\n',mm,fn,ze);
end
fprintf('E2 (rangos deg):\n');
for m=mods
  mm=m{1}; [t,al,th,Vm]=openm(fp.([mm '2']),mm);
  R.(mm).E2=[min(th) max(th) min(al) max(al)]*180/pi;
  fprintf('     %-6s theta=[%6.1f,%6.1f]  alpha=[%6.1f,%6.1f]  Vmmax=%.2f\n',mm,R.(mm).E2,max(abs(Vm)));
end
fprintf('E3 (lazo cerrado):\n');
for m=mods
  mm=m{1}; [tc,bal,as,ts,ni]=closedm(fp.([mm '3']),mm); R.(mm).E3=[tc bal as ts ni];
  fprintf('     %-6s t_catch=%.2fs  bal=%.1f%%  ahat_std=%.2f  th_std=%.2f  NIS=%.2f\n',mm,tc,bal,as,ts,ni);
end
save(fullfile(out,'comparacion_4mod.mat'),'-struct','R');

% ================= OVERLAYS =================
% ---- E1 alpha (4-way, alineado por 1er cruce del colgado) ----
f=figure('Color','w','Position',[70 70 980 460]); hold on;
for m=mods
  mm=m{1}; [t,al,~,~]=openm(fp.([mm '1']),mm);
  if strcmp(mm,'QHW'), [t,al]=crop_rel(t,al); end
  t=t-tcross(t,al);
  plot(t,al*180/pi,'Color',col(mm),'LineStyle',ls(mm),'LineWidth',1.3+strcmp(mm,'QHW')*0.2,'DisplayName',lab(mm));
end
grid on; xlim([0 8]); yline(180,':k','HandleVisibility','off'); xlabel('t desde el colgado [s]'); ylabel('\alpha [deg]');
legend('Location','northeast'); title('E1 — \alpha caída libre: 4 modalidades vs real');
sv(f,fullfile(out,'comp_E1_alpha_4mod.png'));

% ---- E2 alpha+theta (4-way, t directo) ----
f=figure('Color','w','Position',[70 60 980 660]); tiledlayout(2,1,'Padding','compact');
nexttile; hold on;
for m=mods, mm=m{1}; [t,al,th,~]=openm(fp.([mm '2']),mm);
  plot(t,al*180/pi,'Color',col(mm),'LineStyle',ls(mm),'LineWidth',1.0+strcmp(mm,'QHW')*0.3,'DisplayName',lab(mm)); end
grid on; xlim([0 35]); ylabel('\alpha [deg]'); legend('Location','northeast'); title('\alpha (péndulo)');
nexttile; hold on;
for m=mods, mm=m{1}; [t,al,th,~]=openm(fp.([mm '2']),mm);
  plot(t,th*180/pi,'Color',col(mm),'LineStyle',ls(mm),'LineWidth',1.0+strcmp(mm,'QHW')*0.3,'DisplayName',lab(mm)); end
grid on; xlim([0 35]); yline(135,':k'); yline(-135,':k'); ylabel('\theta [deg]'); xlabel('t [s]'); title('\theta (brazo), tope \pm135°');
sv(f,fullfile(out,'comp_E2_alpha_theta_4mod.png'));

% ---- E3 alpha (4-way, wrapToPi, signo del swing-up homogeneizado) ----
f=figure('Color','w','Position',[70 70 980 460]); hold on;
for m=mods
  mm=m{1}; [t,al,mode]=closed_sig(fp.([mm '3']),mm);
  alw=atan2(sin(al),cos(al));
  if presign(alw,mode)<0, alw=-alw; end
  plot(t,alw*180/pi,'Color',col(mm),'LineStyle',ls(mm),'LineWidth',1.1+strcmp(mm,'QHW')*0.2,'DisplayName',lab(mm));
end
grid on; xlim([0 6]); yline(0,':k','HandleVisibility','off'); xlabel('t [s]'); ylabel('\alpha [deg] (arriba=0)');
legend('Location','northeast'); title('E3 — \alpha swing-up y balance: 4 modalidades vs real');
sv(f,fullfile(out,'comp_E3_alpha_4mod.png'));
fprintf('\nOK figuras comp_* en %s\n',out);

% ===== helpers =====
function M=ld(fp), S=load(fp); fn=fieldnames(S); M=S.(fn{1}); if size(M,1)>size(M,2),M=M.';end; end
function [t,al,th,Vm]=openm(fp,mm)
  M=ld(fp);
  switch mm
    case 'RTB', seq=M(1,:); t=(seq-seq(1))*2e-3; th=M(2,:); al=M(3,:); Vm=M(8,:);
    case {'QSM','SIM'}, t=M(1,:); th=M(3,:); al=M(4,:); Vm=M(9,:);
    case 'QHW', t=M(1,:); th=M(4,:); al=M(5,:); Vm=M(6,:);
  end
  t=t(:).'; al=al(:).'; th=th(:).'; Vm=Vm(:).';
end
function [tc,bal,as,ts,ni]=closedm(fp,mm)
  [t,al,alh,mode,nis,th]=e3rows(fp,mm); b=mode>0.5; ic=find(b,1);
  tc=t(ic); bal=100*mean(b); alw=atan2(sin(alh),cos(alh));
  as=std(alw(b))*180/pi; ts=std(th(b)-mean(th(b)))*180/pi; ni=mean(nis(b));
end
function [t,al,mode]=closed_sig(fp,mm), [t,al,~,mode,~,~]=e3rows(fp,mm); end
function [t,al,alh,mode,nis,th]=e3rows(fp,mm)
  M=ld(fp);
  switch mm
    case 'RTB', seq=M(1,:); t=(seq-seq(1))*2e-3; th=M(2,:); al=M(3,:); alh=M(10,:); nis=M(14,:); mode=M(15,:);
    case {'QSM','SIM'}, t=M(1,:); th=M(3,:); al=M(4,:); alh=M(11,:); nis=M(15,:); mode=M(16,:);
    case 'QHW', t=M(1,:); th=M(3,:); al=M(4,:); alh=M(7,:); nis=M(11,:); mode=M(12,:);
  end
  t=t(:).';
end
function s=presign(al,mode)
  ic=find(mode>0.5,1); if isempty(ic)||ic<50,s=1;return;end
  seg=al(max(1,ic-200):ic-1); [~,im]=max(abs(seg)); s=sign(seg(im)); if s==0,s=1;end
end
function [tc,alc]=crop_rel(t,al)
  lo=al<0.4; d=diff([0 lo 0]); s0=find(d==1); e0=find(d==-1)-1;
  [~,mi]=max(e0-s0); ir=e0(mi); tc=t(ir:end)-t(ir); alc=al(ir:end);
end
function t0=tcross(t,al), i=find(al(1:end-1)<pi & al(2:end)>=pi,1); if isempty(i),t0=t(1);else,t0=t(i);end; end
function [fn,ze]=fnz(t,a)
  fn=NaN; ze=0; a=a(:).'; t=t(:).'; n=numel(a);
  s=a-mean(a(max(1,n-round(0.1*n)):end)); amp=max(abs(s(1:min(n,round(0.3*n))))); if amp<=0,return;end
  h=0.15*amp; zc=[]; armed=false;
  for i=1:n, if s(i)<-h,armed=true;end; if armed&&s(i)>0,zc(end+1)=i;armed=false;end; end %#ok<AGROW>
  if numel(zc)<3,return;end; fn=1/median(diff(t(zc)));
  Ts=median(diff(t)); minsep=max(1,round(0.6/fn/Ts)); last=-inf; pk=[];
  for i=2:numel(s)-1, if s(i)>s(i-1)&&s(i)>=s(i+1)&&s(i)>0&&(i-last)>=minsep,pk(end+1)=s(i);last=i;end; end %#ok<AGROW>
  if numel(pk)>=2, r=pk(1:end-1)./pk(2:end); r=r(r>0&isfinite(r)); d=median(log(r)); ze=d/sqrt(4*pi^2+d^2); end
end
function s=lab(mm)
  switch mm, case 'RTB',s='RTB (RT Box)'; case 'QSM',s='QSM (QUARC-modelo)'; case 'SIM',s='SIM (offline)'; case 'QHW',s='QHW (real M0)'; end
end
function sv(f,png), exportgraphics(f,png,'Resolution',140); close(f); end
