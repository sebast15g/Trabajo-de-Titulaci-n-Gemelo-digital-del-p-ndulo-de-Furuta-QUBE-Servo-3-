% VERIF_EKF_PLANTA  Verifica que la dinamica del modelo del EKF (furuta_f_aug,
% generado por derivar_modelo_furuta_EKF) coincide con la de la planta analitica
% (furuta_planta_analitica), en estados sin tope (|theta|<135) y con d=0.
clear;
% funciones furuta_* (furuta_f_aug, furuta_planta_analitica) resueltas por el path (setup_paths)
% --- parametros de la PLANTA (identicos al C-Script, horneados en furuta_planta_analitica) ---
Jr=1.38e-4; mp=0.024; Lr=0.086; lp=0.064325; Jp=3.3101645e-5; gg=9.7807;
kt=0.0422; km=0.0422; Rm=7.5; Dr=3.975e-4; Dp=0.0; kc=2.384e-3; theta0=0; Tdry=0; Tc=6.1e-6; EPSC=1e-3;
plant_deriv=@(x,Vm) deriv_base(x,Vm,Jr,mp,Lr,lp,Jp,gg,kt,km,Rm,Dr,Dp,kc,theta0,Tdry,Tc,EPSC);

rng_states = 2*rand(4,2000)-1; rng_states(1,:)=rng_states(1,:)*2.0;  % th in +-2 (<2.356 tope)
rng_states(2,:)=rng_states(2,:)*pi; rng_states(3:4,:)=rng_states(3:4,:)*10;  % vel +-10
Vms = 6*(2*rand(1,2000)-1);
emax=0; erel=0;
for k=1:2000
  x=rng_states(:,k); Vm=Vms(k);
  dp=plant_deriv(x,Vm);                 % [dth;dal;ddth;ddal]
  fa=furuta_f_aug([x;0],Vm);            % [dth;dal;ddth;ddal;0]  (dcab=0)
  e=abs(dp - fa(1:4));
  emax=max(emax,max(e));
  erel=max(erel, max(e./max(abs(dp),1e-6)));
end
fprintf('=== dinamica: planta vs furuta_f_aug (EKF) ===\n');
fprintf('  error abs maximo en [dth,dal,ddth,ddal] = %.3e\n', emax);
fprintf('  error relativo maximo                    = %.3e\n', erel);
if emax<1e-8, fprintf('  -> COINCIDEN (mismo modelo, mismos parametros).\n');
else, fprintf('  -> DIFIEREN: furuta_f_aug puede estar desfasado de parametros_furuta.m actuales.\n'); end

% --- chequeo puntual de parametros clave (gravedad/inercia) via un estado simple ---
x0=[0.3; 0.7; 0; 0];   % reposo de velocidades: ddal domina por gravedad
dp=plant_deriv(x0,0); fa=furuta_f_aug([x0;0],0);
fprintf('\nestado [th=0.3,al=0.7,0,0], Vm=0:\n');
fprintf('  ddalpha  planta=%.8f   f_aug=%.8f   (gravedad/inercia)\n', dp(4), fa(4));
fprintf('  ddtheta  planta=%.8f   f_aug=%.8f   (cable)\n', dp(3), fa(3));

function xd=deriv_base(x,Vm,Jr,mp,Lr,lp,Jp,gg,kt,km,Rm,Dr,Dp,kc,theta0,Tdry,Tc,EPSC)
  th=x(1); al=x(2); dth=x(3); dal=x(4);
  c=cos(al); s2=sin(2*al);
  M11=Jp+Jr+Lr*Lr*mp+lp*lp*mp-Jp*c*c-lp*lp*mp*c*c; M12=Lr*lp*mp*c; M22=Jp+lp*lp*mp;
  h1= Jp*dal*dth*s2 - Lr*dal*dal*lp*mp*sin(al) + dal*dth*lp*lp*mp*s2;
  h2=-0.5*Jp*dth*dth*s2 - gg*lp*mp*sin(al) - 0.5*dth*dth*lp*lp*mp*s2;
  tau_mot=kt*(Vm-km*dth)/Rm; tau_cab=kc*(th-theta0)+Tdry*tanh(dth/EPSC);
  Q1=tau_mot-Dr*dth-tau_cab; Q2=-Dp*dal-Tc*tanh(dal/EPSC); det=M11*M22-M12*M12;
  ddth=(M22*(Q1-h1)-M12*(Q2-h2))/det; ddal=(-M12*(Q1-h1)+M11*(Q2-h2))/det;
  xd=[dth;dal;ddth;ddal];
end
