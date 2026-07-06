% CREATE_SCALON  Escalera triangular de voltaje para el barrido cuasi-estatico del cable (theta).
%   Genera V_levels para el bloque Repeating Sequence Stair (barrido +Vmax/-Vmax).
%   Salidas: V_levels en el workspace; imprime numero de peldanos y duracion.
%   Referencia: seccion 4.3 (cable del encoder en theta).
V_max    = 1;     % V  (ajustar en el ensayo piloto)
dV       = 0.05;    % V  paso
T_dwell  = 4;       % s  permanencia por peldano (> asentamiento de theta)
n_cycles = 3;

up   = 0:dV:V_max;             % 0 -> +Vmax
down = V_max-dV:-dV:-V_max;    % +Vmax -> -Vmax
up2  = -V_max+dV:dV:0;         % -Vmax -> 0
V_levels = repmat([up down up2], 1, n_cycles);

% En el bloque Repeating Sequence Stair:
%   Vector of output values = V_levels ;  Sample time = T_dwell
T_total = numel(V_levels)*T_dwell;
fprintf('Peldanos: %d | Duracion: %.1f min\n', numel(V_levels), T_total/60);