%% BANCO DE PRUEBAS DEL EKF EN SIMULACION PURA (Furuta - Gemelo Digital)
%  Valida el EKF de estado aumentado antes de tocar el tiempo real:
%   - "Verdad": modelo analitico integrado (RK4) con una perturbacion d_true(t) en theta
%     (representa el cable) y control LQG (u = -K*x_hat).
%   - Medidas: y = [theta, alpha, Im] + ruido + cuantizacion de encoders.
%   - EKF: ciclo predict/update con las funciones exportadas (furuta_f_aug/_Fc/_h/_H),
%     estima el estado completo Y la perturbacion d.
%   - Verifica: estado estimado vs verdad, d_hat vs d_true, y consistencia (NIS).
%
%  Requiere: parametros_furuta.m, modelo_furuta_EKF.mat y las funciones furuta_*
%  generadas por derivar_modelo_furuta_EKF.m.
% --------------------------------------------------------------------------
clear; clc; close all;
run('parametros_furuta.m');
S = load('modelo_furuta_EKF.mat','K','Q','R');
K = S.K; Q = S.Q; R = S.R;
Ts = p.Ts; T = 6; N = round(T/Ts);

%% Perturbacion "verdad" del cable (escalon suave a t=2 s)
%  Amplitud de prueba representativa del residuo del cable (p.Tdry_th=0 en el modelo final,
%  por eso aqui se fija un valor de prueba para demostrar la estimacion de la perturbacion).
d_amp  = 7e-4;                                                  % N*m  perturbacion de prueba
d_true = @(t) d_amp * (1./(1+exp(-(t-2)/0.05)) - 0.5)*2;        % +-d_amp, conmuta en t=2 s

%% Inicializacion
x_true  = [0.15; 0.08; 0; 0];          % perturbacion inicial [theta alpha dtheta dalpha] (rad)
xa_hat  = [0; 0; 0; 0; 0];             % estimacion inicial (incl. d_hat=0)
P       = diag([0.02 0.02 0.1 0.1 1e-6]);
sigR    = sqrt(diag(R));               % desv. de ruido de medida

% Logs
X = zeros(4,N); Xh = zeros(5,N); Dt = zeros(1,N); NIS = zeros(1,N); tt=(0:N-1)*Ts;

fd_true = @(x,u,d) subsref(furuta_f_aug([x; d], u), struct('type','()','subs',{{1:4}})); % 4 estados verdad

for k = 1:N
    t = tt(k);
    % --- Control LQG (usa la estimacion) ---
    u = -K*xa_hat(1:4);  u = max(min(u,10),-10);

    % --- Medidas de la verdad (ruido + cuantizacion de encoders) ---
    y = furuta_meas([x_true;0], u) + sigR.*randn(2,1);
    y(1) = round(y(1)/p.q_theta)*p.q_theta;     % cuantizacion theta
    y(2) = round(y(2)/p.q_alpha)*p.q_alpha;     % cuantizacion alpha

    % --- EKF: prediccion ---
    F  = eye(5) + Ts*furuta_Fc(xa_hat,u);
    xa_pred = xa_hat + Ts*furuta_f_aug(xa_hat,u);
    P_pred  = F*P*F' + Q;
    % --- EKF: correccion ---
    H  = furuta_Hjac(xa_pred,u);
    yh = furuta_meas(xa_pred,u);
    Sk = H*P_pred*H' + R;
    Kk = P_pred*H'/Sk;
    innov = y - yh;
    xa_hat = xa_pred + Kk*innov;
    P = (eye(5) - Kk*H)*P_pred;

    % --- Verdad: integra RK4 con d_true y el control ---
    d = d_true(t);
    k1 = fd_true(x_true,u,d);
    k2 = fd_true(x_true+Ts/2*k1,u,d);
    k3 = fd_true(x_true+Ts/2*k2,u,d);
    k4 = fd_true(x_true+Ts*k3,u,d);
    x_true = x_true + Ts/6*(k1+2*k2+2*k3+k4);

    % Logs
    X(:,k)=x_true; Xh(:,k)=xa_hat; Dt(k)=d; NIS(k)=innov'/Sk*innov;
end

%% Metricas
rmse = sqrt(mean((X - Xh(1:4,:)).^2, 2));
fprintf('RMSE de estimacion:\n');
fprintf('  theta = %.4e rad | alpha = %.4e rad | dtheta = %.4e | dalpha = %.4e\n', rmse);
fprintf('NIS medio = %.2f  (ideal ~ dim(y)=2; consistencia del filtro)\n', mean(NIS));

%% Graficas
nm = {'\theta','\alpha','\theta dot','\alpha dot'};
figure('Color','w','Position',[60 60 1000 600]);
for i=1:4
    subplot(3,2,i); plot(tt,X(i,:),'k',tt,Xh(i,:),'r--','LineWidth',1.1);
    ylabel(nm{i}); grid on; if i==1, legend('verdad','EKF','Location','best'); end
end
subplot(3,2,5); plot(tt,Dt,'k',tt,Xh(5,:),'r--','LineWidth',1.1);
ylabel('d (cable)'); xlabel('t [s]'); legend('d_{true}','d_{hat}','Location','best'); grid on;
subplot(3,2,6); plot(tt,NIS,'b'); yline(2,'r--'); ylabel('NIS'); xlabel('t [s]');
title('consistencia (ideal ~2)'); grid on;
exportgraphics(gcf,'ekf_testbench.png','Resolution',150);
fprintf('Figura guardada: ekf_testbench.png\n');
