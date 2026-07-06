function demo_DT_bidireccional(logfile)
% DEMO_DT_BIDIRECCIONAL  Graficas de DEMOSTRACION del gemelo bidireccional
%   (DT_bidireccional_RT.slx) siguiendo distintas referencias. Es SOLO para
%   mostrar el sistema integrado en operacion (defensa); NO calcula metricas de
%   comparacion: este log no se compara (el banco ya se analizo aparte).
%
%   Referencias del ensayo (segun se configuro en el modelo):
%     - constante
%     - cuadrada 1 Hz, +/-45 deg
%     - senoidal, amplitud +/-90 deg
%
%   USO:   demo_DT_bidireccional                      % usa el nombre por defecto
%          demo_DT_bidireccional('mi_log.mat')
%
%   El mapa de columnas de abajo corresponde al layout real del log (parecido al
%   de E58, con la referencia anadida al final). Si el orden difiere, cambiar solo
%   los indices de la seccion "MAPA DE COLUMNAS".

    if nargin<1, logfile='log_simscape_E58_sinc_final.mat'; end
    S  = load(logfile);
    fn = fieldnames(S);
    D  = S.(fn{1});                         % primera variable = matriz de datos
    if size(D,1) > size(D,2), D = D.'; end  % dejar filas = senales

    % ===== MAPA DE COLUMNAS (layout E58, 14 filas, SIN columna de referencia) =====
    % t, theta, alpha, xhat(4), theta_m, alpha_m, x_m(4), Vm   (la ultima fila es Vm)
    t   = D(1,:);        % tiempo
    th  = D(2,:);        % theta (brazo) del gemelo/real
    al  = D(3,:);        % alpha (pendulo)
    Vm  = D(14,:);       % voltaje de comando (ultima fila del log)
    ref = zeros(size(t));% referencia de regulacion: theta_ref = 0 (todas las pruebas con referencia usaron 0)
    % Si alpha del real queda con signo opuesto (como en E58), descomentar:
    % al = -al;
    dg = @(x) x*180/pi;

    % ===== Figura de demostracion =====
    f = figure('Color','w','Position',[60 60 1000 680]);

    subplot(3,1,1); hold on; grid on;
    plot(t, dg(ref),'k--','LineWidth',1.4,'DisplayName','referencia \theta_{ref}');
    plot(t, dg(th), 'b','LineWidth',1.5,'DisplayName','\theta (gemelo)');
    ylabel('\theta [deg]'); legend('Location','best');
    title('Gemelo bidireccional: seguimiento de referencias (demostracion)');

    subplot(3,1,2); grid on; hold on;
    plot(t, dg(al),'g','LineWidth',1.3); yline(0,'k:');
    ylabel('\alpha [deg]'); title('Pendulo estabilizado en la vertical (\alpha \approx 0)');

    subplot(3,1,3); grid on;
    plot(t, Vm,'r','LineWidth',1.0);
    ylabel('V_m [V]'); xlabel('t [s]'); title('Voltaje de comando');

    % error de seguimiento (solo informativo para la charla, no es metrica de tesis)
    e = dg(th - ref);
    fprintf('Demostracion DT bidireccional: |error seguimiento theta| RMS = %.2f deg, max = %.2f deg\n',...
            sqrt(mean(e.^2,'omitnan')), max(abs(e)));

    try, exportgraphics(f,'demo_DT_bidireccional.png','Resolution',150); catch, end
end
