function S = validar_ganancias(K, verbose)
% VALIDAR_GANANCIAS  Validacion PREDICTIVA de un controlador candidato ANTES de aplicarlo
%   al real: el gemelo (modelo) prueba la ganancia K y decide si es segura.
%   Es el uso del gemelo como "banco de pruebas": si el modelo se mantiene estable y
%   acotado con K, se aprueba; si diverge o satura, se RECHAZA y no se expone la planta.
%
%   S = validar_ganancias(K)
%     K : ganancia candidata 1x4 (sin integral) o 1x5 (con integral de theta).
%   Devuelve S con: ok (true/false), polos, max_alpha_deg, settling_s, u_peak_V y motivo.
%
%   Criterios de aprobacion (ajustables abajo):
%     - lazo cerrado ESTABLE (todos los polos con parte real < 0),
%     - tras una perturbacion de 10 deg en alpha, |alpha| se mantiene < 30 deg,
%     - el voltaje pico se mantiene < 10 V (no satura de forma sostenida),
%     - asentamiento (|alpha|<2 deg) en < 3 s.

    if nargin<2, verbose=true; end
    B0=load('banco_controladores.mat');   % A,B,Aa,Ba (en datos/modelo_control, resuelto por el path de setup_paths)

    K=K(:).';  n=numel(K);
    if n==4,     A=B0.A;  B=B0.B;  na=4;
    elseif n==5, A=B0.Aa; B=B0.Ba; na=5;
    else, error('K debe ser 1x4 (sin integral) o 1x5 (con integral).'); end

    Acl = A - B*K;
    pol = eig(Acl);
    estable = all(real(pol) < 0);

    % --- Simulacion lineal: perturbacion inicial de 10 deg en alpha ---
    Ts=0.002; T=4; t=0:Ts:T; x=zeros(na,numel(t)); x(2,1)=10*pi/180;  % alpha0=10 deg
    u=zeros(1,numel(t));
    for k=1:numel(t)-1
        u(k)   = -K*x(:,k);
        x(:,k+1)= x(:,k) + Ts*(A*x(:,k) + B*u(k));   % Euler (modelo lineal)
    end
    al = x(2,:)*180/pi;
    max_alpha = max(abs(al));
    u_peak    = max(abs(u));
    % asentamiento: ultimo instante con |alpha|>2 deg
    idx=find(abs(al)>2,1,'last'); settling = isempty(idx)*0 + (~isempty(idx))*t(min(idx+1,numel(t)));

    % --- Criterios ---
    ok = estable && (max_alpha < 30) && (u_peak < 10) && (settling < 3) && all(isfinite(al));

    S=struct('ok',ok,'estable',estable,'polos',pol, ...
             'max_alpha_deg',max_alpha,'settling_s',settling,'u_peak_V',u_peak);
    if ~estable,                 S.motivo='lazo INESTABLE';
    elseif ~all(isfinite(al)),   S.motivo='diverge (no finito)';
    elseif max_alpha>=30,        S.motivo='alpha supera 30 deg';
    elseif u_peak>=10,           S.motivo='voltaje satura (>=10 V)';
    elseif settling>=3,          S.motivo='asentamiento lento (>3 s)';
    else,                        S.motivo='OK'; end

    if verbose
        fprintf('\n=== VALIDACION DE GANANCIA (gemelo como banco de pruebas) ===\n');
        fprintf('  K = [%s]\n', strtrim(sprintf('%+.3f ',K)));
        fprintf('  estable=%d | max|alpha|=%.1f deg | u_pico=%.2f V | asentamiento=%.2f s\n', ...
                estable, max_alpha, u_peak, settling);
        fprintf('  >> %s -> %s\n', S.motivo, ternary(ok,'APROBADA (segura para el real)','RECHAZADA'));
    end
end
function y=ternary(c,a,b), if c, y=a; else, y=b; end, end
