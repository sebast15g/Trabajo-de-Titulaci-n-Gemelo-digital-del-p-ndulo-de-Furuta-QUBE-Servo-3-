% FIG_SWINGUP_ANALISIS  Figuras del hallazgo del vaiven extra (integrador + ke).
%  (1) RK4 vs Euler (mismo paso) -> 8 vs 7 vaivenes.
%  (2) barrido de ke -> # vaivenes (filo de navaja).
%  (3) analitico ke=50 vs ke=52 vs real -> con +2 de bombeo iguala al real (7).
clear;
out=fullfile(repo_root,'RTS_modalidades','comparacion');   % figuras de salida dentro del repo
P.Jr=1.38e-4; P.mp=0.024; P.Lr=0.086; P.lp=0.064325; P.Jp=3.3101645e-5; P.g=9.7807;
P.kt=0.0422; P.km=0.0422; P.Rm=7.5; P.Dr=3.975e-4; P.Dp=0.0; P.kc=2.384e-3; P.Tc=6.1e-6; P.EPSC=1e-3;
P.THMAX=2.3561944901923448; P.KSTOP=50; P.BSTOP=0.037351; P.JTH=2.2879e-4;
S.Er=2*P.mp*P.g*P.lp; S.umax=6; S.Kacc2V=-(P.Rm/P.kt)*(0.095*0.085); S.catch=17*pi/180; S.Vsat=10;
S.Ka=[-3.79294 -33.8988 -1.48036 -2.91551 -4.47214]; S.XILIM=0.447214;

% (1) RK4 vs Euler
[tR,aR,tcR,nR]=runcl(P,S,50,0.5e-3,'RK4');
[tE,aE,tcE,nE]=runcl(P,S,50,0.5e-3,'Euler');
f=figure('Color','w','Position',[70 70 950 430]); ax=axes(f); hold(ax,'on');
h1=plot(ax,tR,aR,'Color',[0.1 0.55 0.1],'LineWidth',1.4);
h2=plot(ax,tE,aE,'Color',[0.85 0.1 0.1],'LineStyle','--','LineWidth',1.4);
yl=yline(ax,17,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
yl=yline(ax,-17,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
grid(ax,'on'); xlim(ax,[0 3.6]); ylim(ax,[-200 60]); xlabel(ax,'t [s]'); ylabel(ax,'\alpha (desv. de arriba) [deg]');
legend(ax,[h1 h2],{sprintf('RK4 / ode4 (QSM,SIM): %d vaivenes, captura %.2fs',nR,tcR), ...
                   sprintf('Euler (RT Box): %d vaivenes, captura %.2fs',nE,tcE)},'Location','southeast');
title(ax,'Mismo modelo, mismo paso (0.5 ms), mismo control — solo cambia el integrador');
sv(f,fullfile(out,'hallazgo_swingup_rk4_vs_euler.png'));

% (2) barrido de ke
kes=44:2:60; nk=zeros(size(kes)); tk=zeros(size(kes));
for i=1:numel(kes), [~,~,tk(i),nk(i)]=runcl(P,S,kes(i),0.5e-3,'RK4'); end
f=figure('Color','w','Position',[70 70 900 430]); ax=axes(f); yyaxis(ax,'left');
b=bar(ax,kes,nk,0.6,'FaceColor',[0.3 0.5 0.85]); ylabel(ax,'# de vaivenes hasta capturar'); ylim(ax,[0 12]);
yyaxis(ax,'right'); plot(ax,kes,tk,'o-','Color',[0.85 0.2 0.2],'LineWidth',1.4); ylabel(ax,'tiempo de captura [s]');
xline(ax,50,'k--','ke actual'); xline(ax,52,'k:','ke=52 \rightarrow 7');
grid(ax,'on'); xlabel(ax,'ke (ganancia de energía del swing-up)');
title(ax,'Sensibilidad del conteo de vaivenes a ke (RK4) — subir 2 unidades pasa de 8 a 7');
sv(f,fullfile(out,'hallazgo_swingup_barrido_ke.png'));

% (3) ke=50 vs ke=52 vs real
[t50,a50,tc50,n50]=runcl(P,S,50,0.5e-3,'RK4');
[t52,a52,tc52,n52]=runcl(P,S,52,0.5e-3,'RK4');
Q=load('fid_E3_qhw.mat'); fn=fieldnames(Q); D=Q.(fn{1}); if size(D,1)>size(D,2),D=D.';end
tq=D(1,:); alq=unwrap(D(4,:)); modeq=D(12,:); bq=modeq>0.5; alq=alq-median(alq(bq)); alqw=atan2(sin(alq),cos(alq))*180/pi;
% orientar real al mismo lado del analitico
ic=find(bq,1); seg=alqw(max(1,ic-40):ic-3); seg=seg(abs(seg)<114); if ~isempty(seg)&&sign(median(seg))>0, alqw=-alqw; end
f=figure('Color','w','Position',[70 70 950 430]); ax=axes(f); hold(ax,'on');
h1=plot(ax,tq,alqw,'Color',[0 0.2 0.9],'LineWidth',1.5);
h2=plot(ax,t50,a50,'Color',[0.1 0.55 0.1],'LineStyle','-.','LineWidth',1.3);
h3=plot(ax,t52,a52,'Color',[0.85 0.4 0],'LineStyle','--','LineWidth',1.3);
yl=yline(ax,17,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off'; yl=yline(ax,-17,'k:'); yl.Annotation.LegendInformation.IconDisplayStyle='off';
grid(ax,'on'); xlim(ax,[0 3.6]); ylim(ax,[-200 60]); xlabel(ax,'t [s]'); ylabel(ax,'\alpha (desv. de arriba) [deg]');
legend(ax,[h1 h2 h3],{'real (QHW): 7 vaivenes', sprintf('analítico ke=50: %d vaivenes',n50), sprintf('analítico ke=52 (bombeo +4%%): %d vaivenes',n52)},'Location','southeast');
title(ax,'Con ke=52 el analítico captura como el real (7 vaivenes)');
sv(f,fullfile(out,'hallazgo_swingup_ke52_vs_real.png'));

fprintf('OK: hallazgo_swingup_{rk4_vs_euler,barrido_ke,ke52_vs_real}.png\n');
fprintf('tabla ke: '); for i=1:numel(kes), fprintf('%d->%d  ',kes(i),nk(i)); end; fprintf('\n');

function [trec,alw,tcatch,nvai]=runcl(P,S,ke,hsub,intg)
  x=[0;pi;0;0]; xi=0; T=8; N=round(T/hsub); tcatch=NaN; nvai=0; last=0; caught=false;
  alrec=zeros(1,N); trec=(0:N-1)*hsub;
  for k=1:N
    al=atan2(sin(x(2)),cos(x(2))); dal=x(4); E=0.5*P.Jp*dal^2+P.mp*P.g*P.lp*(1+cos(al));
    if abs(al)<S.catch
      if ~caught, tcatch=(k-1)*hsub; caught=true; end
      xi=xi+hsub*(x(1)); xi=max(min(xi,S.XILIM),-S.XILIM);
      Vm=-(S.Ka(1)*x(1)+S.Ka(2)*al+S.Ka(3)*x(3)+S.Ka(4)*dal+S.Ka(5)*xi);
    else
      sgn=(dal*cos(al)>=0)*2-1; ua=ke*(S.Er-E)*sgn; ua=max(min(ua,S.umax),-S.umax); Vm=S.Kacc2V*ua;
      if ~caught, sg=sign(dal); if sg~=0&&sg~=last&&last~=0, nvai=nvai+1; end; last=sg; end
    end
    Vm=max(min(Vm,S.Vsat),-S.Vsat);
    if strcmp(intg,'RK4'), k1=drv(x,Vm,P);k2=drv(x+hsub/2*k1,Vm,P);k3=drv(x+hsub/2*k2,Vm,P);k4=drv(x+hsub*k3,Vm,P); x=x+(hsub/6)*(k1+2*k2+2*k3+k4);
    else, x=x+hsub*drv(x,Vm,P); end
    alrec(k)=x(2);
  end
  alw=atan2(sin(alrec),cos(alrec))*180/pi;
end
function d=drv(x,Vm,P)
  th=x(1);a=x(2);dth=x(3);da=x(4); c=cos(a); s2=sin(2*a);
  M11=P.Jp+P.Jr+P.Lr^2*P.mp+P.lp^2*P.mp-P.Jp*c^2-P.lp^2*P.mp*c^2; M12=P.Lr*P.lp*P.mp*c; M22=P.Jp+P.lp^2*P.mp;
  h1=P.Jp*da*dth*s2-P.Lr*da^2*P.lp*P.mp*sin(a)+da*dth*P.lp^2*P.mp*s2;
  h2=-0.5*P.Jp*dth^2*s2-P.g*P.lp*P.mp*sin(a)-0.5*dth^2*P.lp^2*P.mp*s2;
  tm=P.kt*(Vm-P.km*dth)/P.Rm; tc=P.kc*th; Q1=tm-P.Dr*dth-tc; Q2=-P.Dp*da-P.Tc*tanh(da/P.EPSC);
  dt=M11*M22-M12*M12; ddth=(M22*(Q1-h1)-M12*(Q2-h2))/dt; dda=(-M12*(Q1-h1)+M11*(Q2-h2))/dt;
  ts=0; if th>P.THMAX, ts=-(P.KSTOP*(th-P.THMAX)+P.BSTOP*dth); if ts>0,ts=0;end; elseif th<-P.THMAX, ts=-(P.KSTOP*(th+P.THMAX)+P.BSTOP*dth); if ts<0,ts=0;end; end
  d=[dth;da;ddth+ts/P.JTH;dda];
end
function sv(f,png), exportgraphics(f,png,'Resolution',140); close(f); end
