%% CALIBRAR Jr para que el polo inestable analitico coincida con el de Simscape
%  El polo inestable del modelo analitico depende de la inercia del brazo Jr (via el
%  acoplamiento). Se ajusta Jr para que max(real(eig(A))) = polo inestable de Simscape.
%  Mantiene el modelo en coordenadas fisicas [theta,alpha,dtheta,dalpha] para LQR y EKF.
%
%   Entradas      : parametros_furuta.m (parametros del sistema).
%   Salidas       : diagnostico del polo vs Jr (consola); Jr calibrado si aplica.
%   Dependencias  : Symbolic Math Toolbox.
%   Referencia    : seccion 4.3 (inercia del brazo Jr).
% --------------------------------------------------------------------------
clear; clc;
run('parametros_furuta.m');

lambda_target = 10.2;     % polo inestable objetivo, de la linealizacion Simscape [rad/s]

%% EOM con Jr simbolico (resto de parametros numericos)
syms th al dth dal ddth dda Vm Jr_s real
rhat=[cos(th);sin(th);0]; that=[-sin(th);cos(th);0]; zhat=[0;0;1];
pcm = p.Lr*rhat + p.lp*( sin(al)*that + cos(al)*zhat );
vcm = jacobian(pcm,[th;al])*[dth;dal];
omega_p = dth*zhat + dal*rhat;
ehat = sin(al)*that + cos(al)*zhat;
KE = 1/2*Jr_s*dth^2 + 1/2*p.mp*(vcm.'*vcm) ...
   + 1/2*p.Jp_cm*((omega_p.'*omega_p)-(omega_p.'*ehat)^2);
PE = p.mp*p.g*p.lp*cos(al);
Lag = KE-PE;
q=[th;al]; dq=[dth;dal]; ddq=[ddth;dda];
dL=jacobian(Lag,dq).';
EL = jacobian(dL,q)*dq + jacobian(dL,dq)*ddq - jacobian(Lag,q).';
M = jacobian(EL,ddq); hvec = subs(EL,ddq,[0;0]);
tau = p.kt*(Vm-p.km*dth)/p.Rm - p.Dr*dth;
ddq_cl = M\([tau;-p.Dp*dal]-hvec);
f_clean = [dth;dal;ddq_cl];
A_sym = jacobian(f_clean,[th;al;dth;dal]);
A_sym = subs(A_sym,[th al dth dal Vm],[0 0 0 0 0]);   % en el equilibrio superior (A no depende de th)

%% DIAGNOSTICO: polo inestable en funcion de Jr y su PISO fisico
Afun = matlabFunction(A_sym,'Vars',Jr_s);
unstable = @(J) max(real(eig(Afun(J))));

piso = unstable(1e3);   % limite Jr -> grande (brazo pesado): pendulo sobre pivote fijo
fprintf('PISO del polo inestable (Jr grande) = %.2f rad/s  [= sqrt(mp*g*lp/Jp_piv)]\n', piso);
fprintf('Objetivo Simscape pedido            = %.2f rad/s\n\n', lambda_target);

fprintf(' Jr [kg*m^2] | polo inestable [rad/s]\n');
for J = [1.0e-4 1.5e-4 2.0e-4 3.0e-4 5.0e-4 1.0e-3]
    fprintf('  %.2e   |   %.2f\n', J, unstable(J));
end

if lambda_target > piso + 1e-3
    Jr_cal = fzero(@(J) unstable(J)-lambda_target, 2e-4);
    fprintf('\nJr que da el objetivo = %.3e kg*m^2\n', Jr_cal);
else
    fprintf(['\n>> El objetivo (%.2f) esta POR DEBAJO del piso (%.2f): NO hay Jr positivo que lo de.\n' ...
             '   El piso lo fija Jp (validado). El 10.2 de Simscape probablemente esta deprimido por\n' ...
             '   el punto de operacion no-quieto (warning). Conclusion: NO calibrar Jr por el polo;\n' ...
             '   LEER Jr del CAD/Simscape (brazo+hub+disco+rotor respecto al eje del motor).\n'], ...
             lambda_target, piso);
end
