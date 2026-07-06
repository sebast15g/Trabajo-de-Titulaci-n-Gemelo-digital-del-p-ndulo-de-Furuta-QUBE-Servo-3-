function prm = furuta_prm()
%#codegen
% FURUTA_PRM  Vector de parametros del modelo analitico, embebido para codegen.
% Espejo EXACTO de parametros_furuta.m (mismo orden que espera furuta_f_param).
% Se define aqui como constante para poder usarse dentro de un bloque MATLAB
% Function (QUARC/RT box compilan: no pueden leer 'p' del workspace base).
%
% UNICA REGLA DE MANTENIMIENTO: si cambias uno de estos 7 valores en
% parametros_furuta.m, cambialo tambien aqui. Son los unicos que entran al modelo.

    Dr       = 3.975e-4;   % p.Dr        viscoso mecanico del brazo/motor [N*m*s/rad]
    Tdry_th  = 0;          % p.Tdry_th   Coulomb sobre theta (eliminado)
    kc       = 2.384e-3;   % p.kc        rigidez torsional del cable [N*m/rad]
    theta0   = 0;          % p.theta0    reposo del cable [rad]
    Tc_alpha = 6.1e-6;     % p.Tc_alpha  Coulomb sobre alpha [N*m]
    Dp       = 0;          % p.Dp        viscoso del pendulo (despreciable)
    Jr       = 1.38e-4;    % p.Jr        inercia del eje theta [kg*m^2]

    prm = [Dr; Tdry_th; kc; theta0; Tc_alpha; Dp; Jr];
end
