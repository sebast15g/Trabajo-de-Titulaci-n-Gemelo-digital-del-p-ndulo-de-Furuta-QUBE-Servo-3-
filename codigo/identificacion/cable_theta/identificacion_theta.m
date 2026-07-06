%% IDENTIFICACION DEL CABLE EN THETA - MULTI-CORRIDA (promedio de varias adquisiciones)
%  Furuta QUBE-Servo 3 - Gemelo Digital
%
%  Procesa N corridas del barrido cuasi-estatico par-angulo, identifica en cada una
%  (k_c, tau_dry, theta0) y promedia. k_c y tau_dry son invariantes a un offset
%  constante de angulo, por lo que se promedian directamente; theta0 NO (cada corrida
%  se pone a cero a mano => offset distinto), de modo que se reporta su dispersion como
%  incertidumbre de puesta a cero y para el modelo se reancla el origen.
%
%  Salidas: parametros medios +/- desviacion y mapeo a los bloques de Simscape.
%  Sirve para 1 o mas archivos (deteccion de ciclos automatica, cualquier V_max).
% ------------------------------------------------------------------------
clear; clc; close all;

%% -------------------- CONFIGURACION --------------------
cfg.files = {'cable_params_v2.csv','cable_params_v2_1.csv','cable_params_v2_2.csv'};
cfg.kt          = 0.0422;     % N*m/A
cfg.col = struct('Vm',1,'Im',2,'thd',3,'th',4,'al',5);  % columnas tras Time
cfg.settle_frac = 0.70;       % fraccion final del peldano = reposo
cfg.skip_cycles = 1;          % descartar 1er ciclo (transitorio)
cfg.n_cycles    = 2;          % ciclos a usar por corrida
cfg.move_thr    = 0.03;       % rad, umbral "en movimiento"
cfg.fit_absmax  = 1.60;       % rad, limite |theta| del ajuste (zona lineal)
cfg.savefigs    = true;
% -------------------------------------------------------

nF = numel(cfg.files);
K = zeros(nF,1); TD = zeros(nF,1); TH0 = zeros(nF,1);
runs = struct('th',{},'tau',{},'pa',{},'pd',{});

for i = 1:nF
    r = identify_run(cfg.files{i}, cfg);
    K(i)=r.k_c; TD(i)=r.tau_dry; TH0(i)=r.theta0;
    runs(i)=struct('th',r.th,'tau',r.tau,'pa',r.pa,'pd',r.pd);
    fprintf('%-26s  k_c=%.2f mN/rad  tau_dry=%.2f mN  theta0=%+.1f deg\n', ...
            cfg.files{i}, r.k_c*1e3, r.tau_dry*1e3, rad2deg(r.theta0));
end

%% -------------------- PROMEDIO --------------------
k_c     = mean(K);     k_c_sd   = std(K,0);
tau_dry = mean(TD);    tau_dry_sd = std(TD,0);
th0_m   = mean(TH0);   th0_sd   = std(TH0,0);     % dispersion = artefacto de cero a mano
deadband_deg = rad2deg(tau_dry/k_c);

fprintf('\n================ PROMEDIO (%d corridas) ================\n', nF);
fprintf('  k_c     = %.3e +/- %.1e N*m/rad   (%.2f +/- %.2f mN*m/rad)\n', k_c,k_c_sd,k_c*1e3,k_c_sd*1e3);
fprintf('  tau_dry = %.3e +/- %.1e N*m       (%.2f +/- %.2f mN*m)\n', tau_dry,tau_dry_sd,tau_dry*1e3,tau_dry_sd*1e3);
fprintf('  theta0  = %+.1f +/- %.1f deg   (dispersion = puesta a cero manual; NO fisico)\n', rad2deg(th0_m),rad2deg(th0_sd));
fprintf('  banda muerta +/- tau_dry/k_c = +/- %.1f deg\n', deadband_deg);

%% -------------------- PARAMETROS PARA SIMSCAPE --------------------
fprintf('\n---- Revolute1 (theta) > Internal Mechanics ----\n');
fprintf('  Spring stiffness      = %.3e N*m/rad   (reemplaza 2.73e-3 provisional)\n', k_c);
fprintf('  Equilibrium position  = 0 deg           (theta0 es artefacto de cero; usar 0)\n');
fprintf('  Damping coefficient   = 0               (quitar 1.20e-4 viscoso provisional)\n');
fprintf('---- Bloque Rotational Friction sobre el eje de theta (anadir, como en alpha) ----\n');
fprintf('  Breakaway friction torque = %.3e N*m\n', tau_dry);
fprintf('  Coulomb friction torque   = %.3e N*m   (= breakaway)\n', tau_dry);
fprintf('  Breakaway velocity        = 0.1 rad/s   (defecto; no identificable)\n');
fprintf('  Viscous coefficient       = 0\n');
fprintf('========================================================\n');

%% -------------------- FIGURAS --------------------
% (1) Lazos superpuestos, reanclados por su propio theta0 (para comparar forma)
f1 = figure('Name','Lazos superpuestos','Color','w','Position',[80 80 760 560]);
cols = lines(nF); hold on;
for i = 1:nF
    plot(rad2deg(runs(i).th - TH0(i)), runs(i).tau*1e3, '.-', 'Color', cols(i,:), ...
         'MarkerSize',6, 'LineWidth',0.4, 'DisplayName', sprintf('corrida %d', i));
end
xx = linspace(-cfg.fit_absmax, cfg.fit_absmax, 50);
plot(rad2deg(xx),  (k_c*xx+tau_dry)*1e3, 'k--','LineWidth',1.3,'DisplayName','modelo: k_c\theta+\tau_{dry}');
plot(rad2deg(xx),  (k_c*xx-tau_dry)*1e3, 'k--','LineWidth',1.3,'HandleVisibility','off');
xlabel('\theta - \theta_0 [deg]'); ylabel('\tau = k_t I_m  [mN\cdotm]');
title(sprintf('Lazos reanclados  |  k_c=%.2f\\pm%.2f mN/rad, \\tau_{dry}=%.2f\\pm%.2f mN, banda \\pm%.0f deg', ...
      k_c*1e3,k_c_sd*1e3,tau_dry*1e3,tau_dry_sd*1e3,deadband_deg));
legend('Location','northwest'); grid on;

% (2) Parametros por corrida
f2 = figure('Name','Parametros por corrida','Color','w','Position',[80 80 820 320]);
subplot(1,3,1); bar(K*1e3); yline(k_c*1e3,'r--'); title('k_c [mN/rad]'); xlabel('corrida'); grid on;
subplot(1,3,2); bar(TD*1e3); yline(tau_dry*1e3,'r--'); title('\tau_{dry} [mN]'); xlabel('corrida'); grid on;
subplot(1,3,3); bar(rad2deg(TH0)); title('\theta_0 [deg] (artefacto cero)'); xlabel('corrida'); grid on;

if cfg.savefigs
    exportgraphics(f1,'cable_lazos_multi.png','Resolution',150);
    exportgraphics(f2,'cable_params_multi.png','Resolution',150);
    fprintf('Figuras guardadas (cable_*_multi.png)\n');
end

%% -------------------- FUNCION DE IDENTIFICACION POR CORRIDA --------------------
function r = identify_run(file, cfg)
    R  = readmatrix(file);
    Vm = R(:,1+cfg.col.Vm); Im = R(:,1+cfg.col.Im); th = R(:,1+cfg.col.th);
    chg = find(abs(diff(Vm)) > 1e-9) + 1;
    s0 = [1; chg]; s1 = [chg-1; numel(Vm)];
    P = [];
    for k = 1:numel(s0)
        seg = s0(k):s1(k);
        if numel(seg) < 100, continue; end
        tl = seg(round(numel(seg)*cfg.settle_frac):end);
        P(end+1,:) = [Vm(seg(1)), median(th(tl)), cfg.kt*median(Im(tl))]; %#ok<AGROW>
    end
    % deteccion de ciclos (inicios en +Vmax)
    pk = find(abs(P(:,1)-max(P(:,1))) < 1e-9);
    cyc = pk([true; diff(pk) > 1]);
    a = min(cfg.skip_cycles+1, numel(cyc));
    b = a + cfg.n_cycles;
    i0 = cyc(a);
    if b > numel(cyc), i1 = size(P,1); else, i1 = cyc(b)-1; end
    Q = P(i0:i1,:); thq = Q(:,2); tauq = Q(:,3);
    dth = [0; diff(thq)];
    asc  = (dth >  cfg.move_thr) & (abs(thq) < cfg.fit_absmax);
    desc = (dth < -cfg.move_thr) & (abs(thq) < cfg.fit_absmax);
    pa = polyfit(thq(asc),tauq(asc),1); pd = polyfit(thq(desc),tauq(desc),1);
    r.k_c     = (pa(1)+pd(1))/2;
    r.tau_dry = (pa(2)-pd(2))/2;
    r.theta0  = -((pa(2)+pd(2))/2)/r.k_c;
    r.th = thq; r.tau = tauq; r.pa = pa; r.pd = pd;
end