function [xhat, dhat, nis] = ekf_step(y, Vm)
%#codegen
% EKF_STEP  Un paso del EKF de estado aumentado para el bloque MATLAB Function.
%   Entradas:  y  = [theta; alpha]  (encoders; convencion arriba=0)
%              Vm = voltaje del motor [V]
%   Salidas:   xhat = [theta; alpha; dtheta; dalpha]   (estado estimado)
%              dhat = perturbacion del cable estimada [N*m]
%              nis  = innovacion normalizada al cuadrado (consistencia EKF, 2 dof).
%   Requiere en el path: furuta_f_aug, furuta_Fc, furuta_meas, furuta_Hjac.

persistent xa P

xhat = zeros(4,1);
dhat = 0;
nis  = 0;

if isempty(xa)
    xa = zeros(5,1);
    xa(1) = y(1);  xa(2) = y(2);
    P  = diag([0.02 0.02 1 1 1e-6]);
end

Ts = 0.002;
Q  = diag([1e-7 1e-7 1e-5 1e-5 1e-4]);
R  = diag([7.84e-7 7.84e-7]);

% Prediccion
F  = eye(5) + Ts*furuta_Fc(xa, Vm);
xp = xa + Ts*furuta_f_aug(xa, Vm);
Pp = F*P*F' + Q;

% Correccion
H  = furuta_Hjac(xp, Vm);
yh = furuta_meas(xp, Vm);
nu = y - yh;
Sk = H*Pp*H' + R;
Kk = Pp*H'/Sk;
xa = xp + Kk*nu;
P  = (eye(5) - Kk*H)*Pp;

xhat = xa(1:4);
dhat = xa(5);
nis  = sum(nu .* (Sk \ nu));   % NIS = v'*inv(S)*v como reduccion escalar (1x1 garantizado)
end
