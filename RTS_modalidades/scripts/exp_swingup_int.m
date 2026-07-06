% EXP_SWINGUP_INT  Prueba decisiva: RK4 vs Euler (mismo paso fino, sin retardo) en el
% swing-up analitico de lazo cerrado. Aisla el integrador como causa del vaiven extra.
% Ademas: sensibilidad al ke (ganancia de energia) para ver que 7-vs-8 es un knife-edge.
clear;
P.Jr=1.38e-4; P.mp=0.024; P.Lr=0.086; P.lp=0.064325; P.Jp=3.3101645e-5; P.g=9.7807;
P.kt=0.0422; P.km=0.0422; P.Rm=7.5; P.Dr=3.975e-4; P.Dp=0.0; P.kc=2.384e-3; P.Tc=6.1e-6; P.EPSC=1e-3;
P.THMAX=2.3561944901923448; P.KSTOP=50; P.BSTOP=0.037351; P.JTH=2.2879e-4;
S.Er=2*P.mp*P.g*P.lp; S.umax=6; S.Kacc2V=-(P.Rm/P.kt)*(0.095*0.085); S.catch=17*pi/180; S.Vsat=10;
S.Ka=[-3.79294 -33.8988 -1.48036 -2.91551 -4.47214]; S.XILIM=0.447214;

fprintf('--- integrador (paso 0.5 ms, sin retardo, ke=50) ---\n');
for intg={'RK4','Euler'}
  [tc,nv]=runcl(P,S,50,0.5e-3,intg{1});
  fprintf('  %-6s : catch=%.3fs  vaivenes=%d\n', intg{1}, tc, nv);
end
fprintf('--- sensibilidad al ke (RK4, 0.5 ms) : el conteo 7<->8 es knife-edge ---\n');
for ke=[46 48 50 52 55 60]
  [tc,nv]=runcl(P,S,ke,0.5e-3,'RK4');
  fprintf('  ke=%2d : catch=%.3fs  vaivenes=%d\n', ke, tc, nv);
end

function [tcatch,nvai]=runcl(P,S,ke,hsub,intg)
  x=[0;pi;0;0]; xi=0; T=8; N=round(T/hsub); tcatch=NaN; nvai=0; last=0; caught=false;
  for k=1:N
    al=atan2(sin(x(2)),cos(x(2))); dal=x(4); E=0.5*P.Jp*dal^2+P.mp*P.g*P.lp*(1+cos(al));
    if abs(al)<S.catch
      if ~caught, tcatch=(k-1)*hsub; caught=true; end
      xi=xi+hsub*(x(1)-0); xi=max(min(xi,S.XILIM),-S.XILIM);
      Vm=-(S.Ka(1)*x(1)+S.Ka(2)*al+S.Ka(3)*x(3)+S.Ka(4)*dal+S.Ka(5)*xi);
    else
      sgn=(dal*cos(al)>=0)*2-1; ua=ke*(S.Er-E)*sgn; ua=max(min(ua,S.umax),-S.umax); Vm=S.Kacc2V*ua;
      if ~caught, sg=sign(dal); if sg~=0&&sg~=last&&last~=0, nvai=nvai+1; end; last=sg; end
    end
    Vm=max(min(Vm,S.Vsat),-S.Vsat);
    if strcmp(intg,'RK4')
      k1=drv(x,Vm,P);k2=drv(x+hsub/2*k1,Vm,P);k3=drv(x+hsub/2*k2,Vm,P);k4=drv(x+hsub*k3,Vm,P); x=x+(hsub/6)*(k1+2*k2+2*k3+k4);
    else
      x=x+hsub*drv(x,Vm,P);
    end
  end
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
