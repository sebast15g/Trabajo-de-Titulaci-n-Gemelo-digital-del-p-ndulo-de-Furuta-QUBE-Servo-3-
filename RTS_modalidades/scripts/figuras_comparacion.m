% FIGURAS_COMPARACION  Set desglosado de figuras comparativas de las 4 modalidades.
% (1) 4-way overlays de E3: alpha, theta, Vm, alpha_dot, NIS, E.
% (2) subplots "cada modalidad a solas vs el real" para E1(alpha), E2(alpha,theta),
%     E3(alpha,theta).
% alpha de E3 = CONTINUA (sin envolver a +-180) y referenciada a balance=0, para
% evitar los saltos de +-180 del colgado. Se toma QHW como referencia de signo del
% swing-up; se refleja SOLO la(s) modalidad(es) cuyo ultimo vaiven viene del lado
% contrario (=> RTB). Al reflejar se invierte el trayecto fisico (alpha,theta,dalpha,Vm).
clear;
out=fullfile(repo_root,'RTS_modalidades','comparacion');   % figuras de salida dentro del repo
fp.RTB1='fid_E1_rtbox.mat'; fp.RTB2='fid_E2_rtbox.mat'; fp.RTB3='fid_E3_rtbox.mat';
fp.QSM1='fid_E1_qsm.mat'; fp.QSM2='fid_E2_qsm.mat'; fp.QSM3='fid_E3_qsm.mat';
fp.QHW1='fid_E1_qhw.mat'; fp.QHW2='fid_E2_qhw.mat'; fp.QHW3='fid_E3_qhw.mat';
fp.SIM1='fid_E1_sim.mat'; fp.SIM2='fid_E2_sim.mat'; fp.SIM3='fid_E3_sim.mat';
mods={'RTB','QSM','SIM','QHW'};
C=containers.Map({'RTB','QSM','SIM','QHW'},{[0.85 0.1 0.1],[0.1 0.55 0.1],[0.55 0.3 0.85],[0 0.2 0.9]});
LS=containers.Map({'RTB','QSM','SIM','QHW'},{'--','-.',':','-'});
LB=containers.Map({'RTB','QSM','SIM','QHW'},{'RTB (RT Box)','QSM (QUARC-modelo)','SIM (offline)','QHW (real M0)'});

% cargar E3 + orientar grupo-ALPHA (alpha,dalpha) y grupo-THETA (theta,Vm) de forma
% INDEPENDIENTE respecto al real, por correlacion en el swing-up. (El real comparte la
% convencion de theta pero tiene alpha con signo opuesto al modelo -> NO se voltean juntos.)
Q=load_e3(fp.QHW3,'QHW'); Q.alc=Q.alc-median(Q.alc(Q.mode>0.5)); E3=struct(); E3.QHW=Q;
icq=find(Q.mode>0.5,1); if isempty(icq),icq=numel(Q.t);end
[~,ipq]=max(abs(Q.alc(1:max(icq-1,1)))); sR=sign(Q.alc(ipq)); if sR==0,sR=1;end
for m=mods, mm=m{1}; if strcmp(mm,'QHW'), continue; end
  S=load_e3(fp.([mm '3']),mm);
  % alpha+dalpha: orientar por el SIGNO del mayor vaiven del swing-up (robusto al
  % sentido de desenvolvimiento; la correlacion de alpha ENVUELTA no lo es).
  a0=S.alc-median(S.alc(S.mode>0.5)); ica=find(S.mode>0.5,1); if isempty(ica),ica=numel(a0);end
  [~,ip]=max(abs(a0(1:max(ica-1,1))));
  if sign(a0(ip))~=sR, S.alc=-S.alc; S.dalh=-S.dalh; end
  if corr_su(S.t,S.th,S.mode, Q.t,Q.th,Q.mode)<0, S.th=-S.th; S.Vm=-S.Vm; end
  S.alc=S.alc-median(S.alc(S.mode>0.5));   % balance en 0
  E3.(mm)=S;
end

% ---------- (1) 4-WAY overlays de E3 ----------
% {campo, ylabel, titulo, tag, escala, ejeCero}
sig={'alc','\alpha [deg] (arriba=0, continua)','E3 — \alpha (swing-up y balance)','alpha',180/pi,1;
     'th','\theta [deg]','E3 — \theta (brazo)','theta',180/pi,1;
     'Vm','V_m [V]','E3 — V_m de control','Vm',1,1;
     'dalh','$\dot{\alpha}$ [deg/s] (EKF)','E3 — velocidad angular del péndulo','alphadot',180/pi,1;
     'E','E [mJ]','E3 — energía del péndulo','E',1,0};   % NIS va en TABLA, no en figura
for i=1:size(sig,1)
  f=figure('Color','w','Position',[70 70 980 460]); ax=axes(f); hold(ax,'on'); H=gobjects(1,numel(mods));
  for j=1:numel(mods), mm=mods{j}; S=E3.(mm);
    H(j)=plot(ax,S.t,S.(sig{i,1})*sig{i,5},'Color',C(mm),'LineStyle',LS(mm),'LineWidth',1.1+strcmp(mm,'QHW')*0.35);
  end
  grid(ax,'on'); xlim(ax,[0 6]);
  if sig{i,6}, yl=yline(ax,0,':k'); yl.Annotation.LegendInformation.IconDisplayStyle='off'; end
  xlabel(ax,'t [s]'); ylabel(ax,sig{i,2},'Interpreter',tern(contains(sig{i,2},'dot'),'latex','tex'));
  legend(ax,H,values(LB,mods),'Location','northeast'); title(ax,sig{i,3});
  sv(f,fullfile(out,sprintf('comp_E3_%s_4mod.png',sig{i,4})));
end

% ---------- E1/E2 4-WAY overlays ----------
f=figure('Color','w','Position',[70 70 980 460]); ax=axes(f); hold(ax,'on'); H=gobjects(1,4);
for j=1:4, mm=mods{j}; [t,al,~,~]=openm(fp.([mm '1']),mm);
  if strcmp(mm,'QHW'), [t,al]=crop_rel(t,al); end; t=t-tcross(t,al);
  H(j)=plot(ax,t,al*180/pi,'Color',C(mm),'LineStyle',LS(mm),'LineWidth',1.2+strcmp(mm,'QHW')*0.3);
end
grid(ax,'on'); xlim(ax,[0 8]); yl=yline(ax,180,':k'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
xlabel(ax,'t desde el colgado [s]'); ylabel(ax,'\alpha [deg]'); legend(ax,H,values(LB,mods),'Location','northeast'); title(ax,'E1 — \alpha caída libre: 4 modalidades vs real');
sv(f,fullfile(out,'comp_E1_alpha_4mod.png'));
f=figure('Color','w','Position',[70 60 980 660]); tl=tiledlayout(f,2,1,'Padding','compact');
ax=nexttile(tl); hold(ax,'on'); H=gobjects(1,4);
for j=1:4, mm=mods{j}; [t,al,~,~]=openm(fp.([mm '2']),mm); H(j)=plot(ax,t,al*180/pi,'Color',C(mm),'LineStyle',LS(mm),'LineWidth',1.0+strcmp(mm,'QHW')*0.35); end
grid(ax,'on'); xlim(ax,[0 35]); ylabel(ax,'\alpha [deg]'); legend(ax,H,values(LB,mods),'Location','northeast'); title(ax,'\alpha (péndulo)');
ax=nexttile(tl); hold(ax,'on');
for j=1:4, mm=mods{j}; [t,~,th,~]=openm(fp.([mm '2']),mm); plot(ax,t,th*180/pi,'Color',C(mm),'LineStyle',LS(mm),'LineWidth',1.0+strcmp(mm,'QHW')*0.35); end
grid(ax,'on'); xlim(ax,[0 35]); yl=yline(ax,135,':k'); yl.Annotation.LegendInformation.IconDisplayStyle='off'; yl2=yline(ax,-135,':k'); yl2.Annotation.LegendInformation.IconDisplayStyle='off';
ylabel(ax,'\theta [deg]'); xlabel(ax,'t [s]'); title(ax,'\theta (brazo), tope \pm135°');
sv(f,fullfile(out,'comp_E2_alpha_theta_4mod.png'));

% ---------- (2) SUBPLOTS: cada modalidad a solas vs el real ----------
subs_vs_real('E1','al',fp,C,LB,out,'comp_E1_alpha_vsreal.png','\alpha [deg]',1);
subs_vs_real('E2','al',fp,C,LB,out,'comp_E2_alpha_vsreal.png','\alpha [deg]',0);
subs_vs_real('E2','th',fp,C,LB,out,'comp_E2_theta_vsreal.png','\theta [deg]',0);
subs_vs_real_e3(E3,C,LB,out,'comp_E3_alpha_vsreal.png','alc','\alpha [deg] (arriba=0)');
subs_vs_real_e3(E3,C,LB,out,'comp_E3_theta_vsreal.png','th','\theta [deg]');
fprintf('OK figuras desglosadas en %s\n',out);

% ================= helpers =================
function M=ld(fp), S=load(fp); fn=fieldnames(S); M=S.(fn{1}); if size(M,1)>size(M,2),M=M.';end; end
function S=load_e3(fp,mm)
  M=ld(fp); S=struct();
  switch mm
    case 'RTB', S.t=(M(1,:)-M(1,1))*2e-3; S.th=M(2,:); alc=M(3,:); S.Vm=M(8,:); S.dalh=M(12,:); S.nis=M(14,:); S.mode=M(15,:); S.E=M(16,:);
    case {'QSM','SIM'}, S.t=M(1,:); S.th=M(3,:); alc=M(4,:); S.Vm=M(9,:); S.dalh=M(13,:); S.nis=M(15,:); S.mode=M(16,:); S.E=M(17,:);
    case 'QHW', S.t=M(1,:); S.th=M(3,:); alc=unwrap(M(4,:)); S.Vm=M(5,:); S.dalh=M(9,:); S.nis=M(11,:); S.mode=M(12,:); S.E=M(13,:);
  end
  S.alc=alc;   % alpha continua (para RTB/QSM/SIM = estado verdadero; QHW = medida desenvuelta)
  if max(abs(S.E))<1, S.E=S.E*1e3; end   % normaliza energia a mJ (RTB loguea en J, QUARC en mJ)
end
function [t,al,th,Vm]=openm(fp,mm)
  M=ld(fp);
  switch mm
    case 'RTB', seq=M(1,:); t=(seq-seq(1))*2e-3; th=M(2,:); al=M(3,:); Vm=M(8,:);
    case {'QSM','SIM'}, t=M(1,:); th=M(3,:); al=M(4,:); Vm=M(9,:);
    case 'QHW', t=M(1,:); th=M(4,:); al=M(5,:); Vm=M(6,:);
  end
  t=t(:).'; al=al(:).'; th=th(:).'; Vm=Vm(:).';
end
function s=presign(alc,mode)
  ic=find(mode>0.5,1); if isempty(ic)||ic<20,s=1;return;end
  a=alc-median(alc(mode>0.5)); w=a(max(1,ic-60):max(1,ic-3)); w=w(abs(w)<2.0);
  if isempty(w), s=1; return; end
  s=sign(median(w)); if s==0,s=1;end
end
function [tc,alc]=crop_rel(t,al)
  lo=al<0.4; d=diff([0 lo 0]); s0=find(d==1); e0=find(d==-1)-1;
  [~,mi]=max(e0-s0); ir=e0(mi); tc=t(ir:end)-t(ir); alc=al(ir:end);
end
function t0=tcross(t,al), i=find(al(1:end-1)<pi & al(2:end)>=pi,1); if isempty(i),t0=t(1);else,t0=t(i);end; end
function subs_vs_real(ex,fld,fp,C,LB,out,png,ylab,align)
  [tq,alq,thq,~]=openm(fp.(['QHW' ex(2)]),'QHW');
  if align
    lo=alq<0.4; d=diff([0 lo 0]); s0=find(d==1); e0=find(d==-1)-1; [~,mi]=max(e0-s0); ir=e0(mi);
    tq=tq(ir:end)-tq(ir); alq=alq(ir:end); thq=thq(ir:end); tq=tq-tcross(tq,alq);
  end
  if strcmp(fld,'al'), yr=alq*180/pi; else, yr=thq*180/pi; end
  mm3={'RTB','QSM','SIM'};
  f=figure('Color','w','Position',[60 50 980 720]); tiledlayout(3,1,'Padding','compact');
  for i=1:3
    mm=mm3{i}; [t,al,th,~]=openm(fp.([mm ex(2)]),mm);
    if align, t=t-tcross(t,al); end
    if strcmp(fld,'al'), ym=al*180/pi; else, ym=th*180/pi; end
    ax=nexttile; plot(ax,tq,yr,'Color',[0 0.2 0.9],'LineWidth',1.3); hold(ax,'on');
    plot(ax,t,ym,'Color',C(mm),'LineStyle','--','LineWidth',1.2); grid(ax,'on');
    if ex(2)=='2', xlim(ax,[0 35]); else, xlim(ax,[0 8]); end
    if strcmp(fld,'th'), yl=yline(ax,135,':k'); yl.Annotation.LegendInformation.IconDisplayStyle='off'; yl2=yline(ax,-135,':k'); yl2.Annotation.LegendInformation.IconDisplayStyle='off'; end
    ylabel(ax,ylab); legend(ax,'QHW (real M0)',LB(mm),'Location','northeast'); title(ax,sprintf('%s vs real',LB(mm)));
    if i==3, xlabel(ax,'t [s]'); end
  end
  sv(f,fullfile(out,png));
end
function subs_vs_real_e3(E3,C,LB,out,png,fld,ylab)
  R=E3.QHW; mm3={'RTB','QSM','SIM'};
  f=figure('Color','w','Position',[60 50 980 720]); tiledlayout(3,1,'Padding','compact');
  for i=1:3
    mm=mm3{i}; S=E3.(mm);
    yr=R.(fld)*(1+ (strcmp(fld,'alc')||strcmp(fld,'th'))*(180/pi-1)); % deg si angulo
    ym=S.(fld)*(1+ (strcmp(fld,'alc')||strcmp(fld,'th'))*(180/pi-1));
    ax=nexttile; plot(ax,R.t,yr,'Color',[0 0.2 0.9],'LineWidth',1.3); hold(ax,'on');
    plot(ax,S.t,ym,'Color',C(mm),'LineStyle','--','LineWidth',1.2); grid(ax,'on'); xlim(ax,[0 6]);
    if strcmp(fld,'alc'), yl=yline(ax,0,':k'); yl.Annotation.LegendInformation.IconDisplayStyle='off'; end
    ylabel(ax,ylab); legend(ax,'QHW (real M0)',LB(mm),'Location','northeast'); title(ax,sprintf('%s vs real',LB(mm)));
    if i==3, xlabel(ax,'t [s]'); end
  end
  sv(f,fullfile(out,png));
end
function y=tern(c,a,b), if c, y=a; else, y=b; end; end
function c=corr_su(t1,y1,m1,t2,y2,m2)
  ic1=find(m1>0.5,1); if isempty(ic1),ic1=numel(t1);end
  ic2=find(m2>0.5,1); if isempty(ic2),ic2=numel(t2);end
  te=0.9*min(t1(ic1),t2(ic2)); tg=linspace(0.15,te,400);
  a=interp1(t1,y1,tg,'linear','extrap'); b=interp1(t2,y2,tg,'linear','extrap');
  a=a-mean(a); b=b-mean(b); c=sum(a.*b)/(sqrt(sum(a.^2)*sum(b.^2))+eps);
end
function sv(f,png), exportgraphics(f,png,'Resolution',140); close(f); end
