function disenar_banco_controladores()
% DISENAR_BANCO_CONTROLADORES  Disena y guarda el banco de controladores del Furuta,
%   todos sobre el MISMO estado estimado x_hat=[theta;alpha;theta_dot;alpha_dot] del EKF.
%   Convencion ANALITICA: u = -K*x_hat.  En HARDWARE se usa la ganancia NEGADA (positiva)
%   por el bloque 'For +ve CCW' -> en el bloque de HW pon -K (o multiplica la salida por -1).
%
%   ctrl_id (para el Multiport Switch / Dropdown del Dashboard):
%     1 = PD   (realim. de estado por ubicacion de polos, sin integral)   -> K 1x4
%     2 = PID  (PD + integral de theta)                                    -> K 1x5
%     3 = LQR  (optimo, sin integral)                                      -> K 1x4
%     4 = LQI  (optimo + integral de theta; re-sintonizado con pesos del LQR)  -> K 1x5
%     5 = LQG  (LQR aplicada sobre x_hat del EKF = observador)             -> K 1x4 (=K_LQR)
%
%   Guarda banco_controladores.mat con K_PD,K_LQR,K_LQG,K_LQI,K_PID y A,B,Aa,Ba.

    here = fileparts(mfilename('fullpath')); cd(here);
    S = load('modelo_furuta_EKF.mat');  A = S.A(1:4,1:4); B = S.B(1:4);

    % Sistema aumentado con integral de theta (estado extra xi, xi_dot = +(theta-ref)).
    % Convencion del integrador del HW: xi = +int(theta-ref) -> ganancia integral NEGATIVA.
    C_th = [1 0 0 0];  Aa = [A zeros(4,1); C_th 0];  Ba = [B;0];

    % --- Disenos (analiticos). Pesos de estado del banco: Qs ---
    Qs = diag([2.155 20 0.25 0.2]);                         % pesos de estado (LQR/LQG/LQI)
    K_LQR = lqr(A, B, Qs, 1);                               % optimo
    K_PD  = place(A, B, [-6 -9 -13 -17]);                   % "PD" = realim. estado por ubicacion de polos
    K_LQI = lqr(Aa, Ba, blkdiag(Qs, 20), 1);               % optimo + integral (pesos del LQR + peso integral 20)
    K_PID = lqr(Aa, Ba, diag([2 8 0.3 0.3 3]), 1);         % "PID" = PD + integral (metodo aparte)
    K_LQG = K_LQR;                                          % LQR sobre x_hat (= K_LQR; NO se compara aparte)

    % --- Reporte ---
    f=@(K) sprintf('[%s]', strtrim(sprintf('%+.3f ',K)));
    fprintf('\n=== BANCO DE CONTROLADORES (convencion analitica, u=-K*x_hat) ===\n');
    fprintf(' 1 PD   = %s   estab polos max Re = %.2f\n', f(K_PD),  max(real(eig(A-B*K_PD))));
    fprintf(' 2 PID  = %s\n', f(K_PID));
    fprintf(' 3 LQR  = %s   estab polos max Re = %.2f\n', f(K_LQR), max(real(eig(A-B*K_LQR))));
    fprintf(' 4 LQI  = %s   (re-sintonizada: pesos del LQR + integral)\n', f(K_LQI));
    fprintf(' 5 LQG  = %s   (= LQR sobre x_hat)\n', f(K_LQG));
    fprintf('\nEN HARDWARE usa -K (positiva). Los integrales (PID,LQI) llevan el estado xi del integrador.\n');

    save(fullfile(here,'banco_controladores.mat'), 'K_PD','K_LQR','K_LQG','K_LQI','K_PID','A','B','Aa','Ba');
    fprintf('Guardado banco_controladores.mat\n');
end
