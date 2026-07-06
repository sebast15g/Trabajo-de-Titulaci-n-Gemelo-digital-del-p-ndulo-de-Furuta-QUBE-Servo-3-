%% fig_swingup_balance.m  — maniobra swing-up + balance (modelo 3D)
%  Vista de control: alpha (desenvuelta, de la posicion colgante a la invertida),
%  theta, y el voltaje Vm, con la conmutacion swing-up -> balance marcada.
%  Entrada: log_simscape_swing_balance.mat (t, Vm, theta_m, alpha_m; alpha en up=0).
run('parametros_furuta.m');
L = load('log_simscape_swing_balance.mat');
t = L.t(:); Vm = L.Vm(:); th = L.theta_m(:);
al = atan2(sin(L.alpha_m(:)), cos(L.alpha_m(:)));   % WRAPPED: +-180=abajo, 0=arriba (mas legible)

% conmutacion: primer instante de balanceo sostenido (|alpha|<20 deg por > 0.3 s)
Ts = median(diff(t)); bal = abs(al) < deg2rad(20); need = round(0.3/Ts);
ksw = NaN; run = 0;
for k = 1:numel(bal)
    if bal(k), run = run+1; else, run = 0; end
    if run >= need, ksw = k-run+1; break; end
end

f = figure('Color','w','Position',[80 80 900 640]);
ax1 = subplot(3,1,1); plot(t, rad2deg(al),'b','LineWidth',1.3); grid on;
ylabel('\alpha [deg]'); hold on;
ax2 = subplot(3,1,2); plot(t, rad2deg(th),'Color',[0 .5 0],'LineWidth',1.3); grid on; ylabel('\theta [deg]'); hold on;
ax3 = subplot(3,1,3); plot(t, Vm,'Color',[.7 .1 .1],'LineWidth',1.0); grid on;
ylabel('V_m [V]'); xlabel('Tiempo [s]'); hold on;
if ~isnan(ksw)
    for ax = [ax1 ax2 ax3]
        xline(ax, t(ksw), 'k--', 'LineWidth', 1.1);
    end
    text(ax1, t(ksw), max(rad2deg(al)), '  swing-up \rightarrow balance', ...
         'VerticalAlignment','top','FontSize',9);
end
exportgraphics(f,'swingup_balance.png','Resolution',200);
fprintf('Conmutacion en t=%.2f s | figura swingup_balance.png\n', t(ksw));
