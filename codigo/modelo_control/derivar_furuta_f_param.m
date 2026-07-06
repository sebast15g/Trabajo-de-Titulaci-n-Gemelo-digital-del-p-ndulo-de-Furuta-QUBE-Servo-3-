%% DERIVAR_FURUTA_F_PARAM  Genera furuta_f_param.m (variante parametrica del M1)
%  Modelo analitico de 4 estados [th; al; dth; dal] con los 7 parametros
%  TUNEABLES simbolicos, pasados como tercer argumento prm:
%       prm = [Dr; Tdry_th; kc; theta0; Tc_alpha; Dp; Jr]   (orden de furuta_prm.m)
%  El resto (g, mp, Lr, lp, Jp_cm, kt, km, Rm) se hornea numericamente desde
%  parametros_furuta.m -> con g = 9.7807 (version vigente; una variante previa usaba g=9.77).
%
%  Cinematica/Lagrangiano identicos a derivar_modelo_furuta_EKF.m; la unica
%  diferencia es que aqui Dr,Tdry_th,kc,theta0,Tc_alpha,Dp,Jr quedan simbolicos
%  (para los scripts de calibracion) en vez de sustituirse por su valor numerico.
%  Es la version SIN estado aumentado (sin +dcab): la planta, no el proceso del EKF.
%
%  Uso: run('derivar_furuta_f_param.m'). Requiere Symbolic Math Toolbox.
% --------------------------------------------------------------------------
clear; clc;
run('parametros_furuta.m');     % struct p (parametros NUMERICOS actuales, g=9.7807)
ep = 1e-3;                       % suavizado de Coulomb (tanh), igual que el resto

%% 1) Simbolos: estados/entrada + los 7 parametros tuneables ------------------
syms th al dth dal ddth dda Vm real
syms Dr Tdry_th kc theta0 Tc_alpha Dp Jr real   % parametros tuneables, simbolicos

%% 2) Cinematica (identica a derivar_modelo_furuta_EKF.m) ---------------------
rhat = [cos(th); sin(th); 0];
that = [-sin(th); cos(th); 0];
zhat = [0; 0; 1];
pcm  = p.Lr*rhat + p.lp*( sin(al)*that + cos(al)*zhat );
vcm  = jacobian(pcm, [th; al]) * [dth; dal];
omega_p = dth*zhat + dal*rhat;
ehat    = sin(al)*that + cos(al)*zhat;

%% 3) Energias y Lagrangiano (Jr simbolico; mp,Jp_cm,g horneados) -------------
KE = 1/2*Jr*dth^2 ...
   + 1/2*p.mp*(vcm.'*vcm) ...
   + 1/2*p.Jp_cm*( (omega_p.'*omega_p) - (omega_p.'*ehat)^2 );
PE = p.mp*p.g*p.lp*cos(al);
Lag = KE - PE;

%% 4) Euler-Lagrange ----------------------------------------------------------
q = [th; al]; dq = [dth; dal]; ddq = [ddth; dda];
dL_ddq = jacobian(Lag, dq).';
ddt    = jacobian(dL_ddq, q)*dq + jacobian(dL_ddq, dq)*ddq;
EL     = simplify( ddt - jacobian(Lag, q).' );
M      = simplify(jacobian(EL, ddq));
hvec   = simplify(subs(EL, ddq, [0;0]));

%% 5) Fuerzas generalizadas y f(x,Vm,prm) ------------------------------------
tau_mot   = p.kt*(Vm - p.km*dth)/p.Rm;                 % kt,km,Rm horneados
tau_cable = kc*(th - theta0) + Tdry_th*tanh(dth/ep);   % kc,theta0,Tdry_th simbolicos
Qgen = [ tau_mot - Dr*dth - tau_cable ; ...
         -Dp*dal - Tc_alpha*tanh(dal/ep) ];            % Dr,Dp,Tc_alpha simbolicos
ddq_p = M \ (Qgen - hvec);
f4    = [dth; dal; ddq_p];                             % 4 estados, SIN +dcab

%% 6) Exportar ----------------------------------------------------------------
prm = [Dr; Tdry_th; kc; theta0; Tc_alpha; Dp; Jr];     % = orden de furuta_prm.m
matlabFunction(f4, 'File','furuta_f_param', ...
               'Vars',{[th;al;dth;dal], Vm, prm}, 'Optimize',true);
fprintf('Exportado furuta_f_param.m (parametrico, g=%.4f horneada).\n', p.g);
