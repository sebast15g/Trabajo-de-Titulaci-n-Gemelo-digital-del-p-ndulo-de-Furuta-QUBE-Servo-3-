%% ======================================================================
%  Amortiguamiento_alpha.m  -  disipacion de la junta alpha (oscilacion libre).
%  ----------------------------------------------------------------------
%  Ensayo de oscilacion libre del pendulo (brazo theta bloqueado).
%
%   Entradas      : alpha_free_oscilation.csv (Time, angle del encoder).
%   Salidas       : descriptores f0, Jp y parametros de friccion (consola) + figuras.
%   Dependencias  : ellipke (Symbolic/Signal Toolbox); readmatrix.
%   Referencia    : seccion 4.3 (disipacion de la junta alpha).
%
%  PARTE A  -> frecuencia natural de pequena amplitud f0 e inercia Jp
%              (correccion eliptica exacta periodo-amplitud).
%  PARTE B  -> disipacion de la junta alpha mapeada a los 4 parametros del
%              bloque Simscape ROTATIONAL FRICTION:
%                 1) Breakaway friction torque   T_brk  [N*m]
%                 2) Breakaway friction velocity w_brk  [rad/s]
%                 3) Coulomb friction torque     T_C    [N*m]
%                 4) Viscous friction coefficient f     [N*m/(rad/s)]
%
%  Notas de implementacion:
%   - Lee el CSV de QUARC (encabezado "Time","angle") con readmatrix.
%   - Recorte de ventana [t_start, t_end] para descartar el preambulo de
%     posicionamiento/sujecion previo a la suelta real.
%   - Deteccion de cruces por cero ROBUSTA: cuando el equilibrio cae justo
%     sobre un escalon del encoder, la senal centrada pasa por cero exacto
%     y la prueba s(i)*s(i+1)<0 no dispara. Se resuelve con relleno de
%     signo (forward-fill) de los ceros.
%   - Los descriptores f0, Jp, wn, k de la Parte A alimentan la Parte B.
%% ======================================================================

%% ===================== CONFIG (parametros de entrada) ================================
cfg.units    = 'deg';      % unidades de alpha: 'deg' o 'rad'
cfg.mp       = 0.024;      % masa del pendulo [kg]
cfg.Lp       = 0.129;    % longitud del pendulo [m]
cfg.g        = 9.78;       % gravedad local [m/s^2]
cfg.t_start  = 0;       % [s] inicio de la suelta limpia ([] = desde el inicio)
cfg.t_end    = [];         % [s] fin de ventana ([] = hasta el final)
cfg.Amin_deg = 0.5;        % descarta picos por debajo (cuantizacion encoder)
cfg.w_brk    = 0.1;        % velocidad de breakaway [rad/s] (def. Simscape)
cfg.do_nlfit = 0;          % 1 = validacion no lineal (ode45 + fminsearch)

% --- cargar datos ---
% CSV de QUARC:  readmatrix omite el encabezado y devuelve [Time angle]
M = readmatrix('alpha_free_oscilation.csv');
[t, a] = extraer_senal(M);
[t, a] = recorta(t, a, cfg.t_start, cfg.t_end);

%% ===================== PARTE A: frecuencia y Jp =======================
A = parte_frecuencia(t, a, cfg);
cfg.f0 = A.f0;  cfg.Jp = A.Jp;  cfg.wn = A.wn;  cfg.k = A.k;

%% ===================== PARTE B: friccion ==============================
F = parte_friccion(t, a, cfg);

if cfg.do_nlfit
    Fnl = valida_nolineal(t, a, cfg, F);
end

%% ===================== FUNCIONES LOCALES ==============================
function A = parte_frecuencia(t, a, cfg)
    [t,a] = sane(t,a);
    a0 = equilibrio(a, cfg);
    s  = a - a0;
    tzc = cruces_cero(t, s);
    Nz = numel(tzc);
    if Nz < 4, error('Pocos cruces por cero (%d). Revisa t_start/t_end.', Nz); end
    deg = strcmpi(cfg.units,'deg');
    P = zeros(Nz-2,1); Aw = zeros(Nz-2,1);
    for i = 1:Nz-2
        P(i) = tzc(i+2) - tzc(i);
        sp = s((t>=tzc(i)) & (t<=tzc(i+2)));
        Amp = (abs(max(sp)) + abs(min(sp)))/2;
        if deg, Amp = deg2rad(Amp); end
        Aw(i) = Amp;
    end
    mk = rad2deg(Aw) >= 0.5;                 % usa solo ciclos con SNR para f0
    if nnz(mk) < 3, mk = true(size(Aw)); end
    m   = sin(Aw/2).^2;  Kc = ellipke(m);
    T0i = P .* (pi/2) ./ Kc;                 % T = T0*(2/pi)*K(m)
    T0  = mean(T0i(mk));  f0 = 1/T0;
    l = cfg.Lp/2;  k = cfg.mp*cfg.g*l;  wn = 2*pi*f0;  Jp = k/wn^2;
    A = struct('f0',f0,'T0',T0,'T0_sd',std(T0i(mk)),'Jp',Jp,'wn',wn,'k',k, ...
               'Ncyc',nnz(mk),'a0',a0);
    fprintf('\n===== PARTE A: frecuencia / Jp =====\n');
    fprintf('Equilibrio a0 = %.4f %s   ciclos usados %d   amplitud %.2f -> %.2f deg\n', ...
            a0, cfg.units, A.Ncyc, rad2deg(max(Aw)), rad2deg(min(Aw)));
    fprintf('f0 = %.4f Hz   (T0=%.5f s, dispersion=%.2e s = %.1f%%)\n', ...
            f0, T0, A.T0_sd, 100*A.T0_sd/T0);
    if A.T0_sd/T0 > 0.05
        fprintf('  AVISO: dispersion alta -> registro ruidoso/baja amplitud; f0 poco fiable.\n');
    end
    fprintf('wn = %.4f rad/s   Jp = %.4e kg*m^2   k=mp*g*l = %.4e N*m/rad\n', wn, Jp, k);
end

function F = parte_friccion(t, a, cfg)
    [t,a] = sane(t,a);
    a0 = equilibrio(a, cfg);
    k = cfg.k; wn = cfg.wn; Jp = cfg.Jp; T = 1/cfg.f0;

    [Apk, tpk] = picos(t, a, a0);
    Adeg = abs(Apk);
    if strcmpi(cfg.units,'deg'), Arad = deg2rad(Adeg); else, Arad = Adeg; end

    keep = rad2deg(Arad) >= cfg.Amin_deg;
    Arad = Arad(keep); tpk = tpk(keep); Apk = Apk(keep);
    if numel(Arad) < 5
        error('Muy pocos picos utiles (%d). Baja cfg.Amin_deg o revisa la ventana.', numel(Arad));
    end

    % --- forma de la envolvente: lineal (Coulomb) vs exp (viscoso) ---
    tt = tpk - tpk(1);  Ad = rad2deg(Arad);
    pl = polyfit(tt, Ad, 1);        R2lin = 1 - var(Ad - polyval(pl,tt))/var(Ad);
    pe = polyfit(tt, log(Arad), 1); R2exp = 1 - var(log(Arad) - polyval(pe,tt))/var(log(Arad));

    % --- T_C desde la envolvente lineal (4*T_C/k por ciclo) ---
    dA_cycle = deg2rad(abs(pl(1)))*T;
    T_C_env  = k*dA_cycle/4;

    % --- separacion por regresion dA vs A (semiciclo): dA = pi*zeta*A + 2*T_C/k ---
    dA = Arad(1:end-1) - Arad(2:end);  Aref = Arad(1:end-1);
    ok = dA > 0;
    pr = polyfit(Aref(ok), dA(ok), 1);  slope = pr(1); inter = pr(2);
    zeta   = max(slope,0)/pi;
    f_vis  = 2*zeta*wn*Jp;
    T_C_reg = max(inter,0)*k/2;

    % --- valor recomendado y breakaway ---
    T_C   = T_C_env;                         % envolvente: R2 mas alto, inmune a fase
    A_stop = Arad(end);
    T_brk  = T_C;                            % zona muerta sub-cuenta -> T_brk = T_C
    if rad2deg(A_stop) > 0.18, T_brk = max(k*A_stop, T_C); end

    F = struct('T_C',T_C,'T_C_env',T_C_env,'T_C_reg',T_C_reg,'f_vis',f_vis, ...
               'zeta',zeta,'T_brk',T_brk,'w_brk',cfg.w_brk,'R2lin',R2lin,'R2exp',R2exp, ...
               'A_stop_deg',rad2deg(A_stop),'Apk',Apk,'tpk',tpk,'Arad',Arad,'a0',a0);

    fprintf('\n===== PARTE B: disipacion / friccion =====\n');
    fprintf('Picos utiles %d   amplitud %.2f -> %.2f deg   sobre %.1f s\n', ...
            numel(Arad), rad2deg(Arad(1)), rad2deg(Arad(end)), tt(end));
    fprintf('Forma envolvente:  R2 lineal=%.4f   R2 exp=%.4f  ->  %s\n', R2lin, R2exp, ...
            ternario(R2lin>=R2exp,'domina COULOMB (decaimiento lineal)','domina VISCOSO (exp)'));
    fprintf('T_C (envolvente lineal) = %.3e N*m   (caida %.4f deg/ciclo)\n', T_C_env, abs(pl(1))*T);
    fprintf('T_C (regresion dA-vs-A) = %.3e N*m   |   f_visc = %.3e N*m/(rad/s)  (zeta=%.4f)\n', ...
            T_C_reg, f_vis, zeta);
    fprintf('\n--- PARA EL BLOQUE ROTATIONAL FRICTION (junta alpha) ---\n');
    fprintf('  Breakaway friction torque  T_brk = %.3e  N*m   (>= T_C)\n', T_brk);
    fprintf('  Breakaway friction velocity w_brk= %.3e  rad/s (def.; no identificable aqui)\n', cfg.w_brk);
    fprintf('  Coulomb friction torque    T_C   = %.3e  N*m\n', T_C);
    fprintf('  Viscous friction coeff     f     = %.3e  N*m/(rad/s)\n', f_vis);
    fprintf('  (DampingCoefficient del Revolute alpha = 0; el viscoso va en el bloque)\n');
    fprintf('  VALIDA por simulacion: suelta a la misma amplitud; el modelo debe\n');
    fprintf('  decaer RECTO y durar ~%.0f s como el real. Ajusta T_C en su banda si hace falta.\n', tt(end));

    % --- figuras ---
    figure('Name','Disipacion alpha','Color','w');
    subplot(2,2,[1 2]); plot(t, a-a0,'-'); hold on; grid on;
    plot(tpk, Apk,'r.','MarkerSize',9);
    xlabel('t [s]'); ylabel(sprintf('alpha-a0 [%s]',cfg.units)); title('Senal y picos');
    subplot(2,2,3); plot(tt, Ad,'o-'); hold on; grid on; plot(tt, polyval(pl,tt),'--');
    xlabel('t [s]'); ylabel('amp [deg]'); title(sprintf('Lineal -> Coulomb  (R^2=%.4f)',R2lin));
    subplot(2,2,4); semilogy(tt, Ad,'o-'); grid on;
    xlabel('t [s]'); ylabel('amp [deg] log'); title(sprintf('Exp -> viscoso  (R^2=%.4f)',R2exp));
end

function Fnl = valida_nolineal(t, a, cfg, F0)
    [t,a] = sane(t,a);
    if strcmpi(cfg.units,'deg'), x = deg2rad(a - F0.a0); else, x = a - F0.a0; end
    % arrancar en el primer pico (v=0)
    [~,i0] = max(abs(x(1:min(40,end))));
    t = t(i0:end) - t(i0);  x = x(i0:end);
    Jp=cfg.Jp; mp=cfg.mp; g=cfg.g; l=cfg.Lp/2; wc=cfg.w_brk/10;
    odef = @(p) integra(p, t, x(1), 0, Jp, mp, g, l, wc);
    cost = @(p) sum((odef(abs(p)) - x).^2);
    pf = abs(fminsearch(cost, [F0.T_C, F0.f_vis], optimset('Display','off','MaxFunEvals',300)));
    xs = odef(pf); rmse = sqrt(mean((rad2deg(xs)-rad2deg(x)).^2));
    Fnl = struct('T_C',pf(1),'f_vis',pf(2),'rmse_deg',rmse);
    fprintf('\n===== Validacion no lineal (EDO completa) =====\n');
    fprintf('  T_C   = %.3e N*m   (envolvente %.3e)\n', pf(1), F0.T_C_env);
    fprintf('  f_vis = %.3e N*m/(rad/s)   (regresion %.3e)\n', pf(2), F0.f_vis);
    fprintf('  RMSE = %.4f deg  (nota: la deriva de fase en muchos ciclos lo infla)\n', rmse);
    figure('Name','Ajuste no lineal','Color','w');
    plot(t, rad2deg(x),'-'); hold on; grid on; plot(t, rad2deg(xs),'--');
    legend('medido','EDO ajustada'); xlabel('t [s]'); ylabel('alpha [deg]');
    title(sprintf('T_C=%.2e, f=%.2e (RMSE=%.3f deg)',pf(1),pf(2),rmse));
end

function xs = integra(p, t, x0, v0, Jp, mp, g, l, wc)
    Tc = p(1); f = p(2);
    od = @(tt,y)[y(2); -(f*y(2) + Tc*tanh(y(2)/wc) + mp*g*l*sin(y(1)))/Jp];
    sol = ode45(od, [t(1) t(end)], [x0; v0]); xs = deval(sol, t, 1).';
end

function tzc = cruces_cero(t, s)
    % Robusta ante equilibrio sobre la rejilla del encoder: rellena el signo
    % de los ceros con el signo previo, para no perder cruces que caen en 0.
    sg = sign(s);
    nz = find(sg~=0, 1);
    if ~isempty(nz), sg(1:nz-1) = sg(nz); end
    for i = 2:numel(sg)
        if sg(i)==0, sg(i) = sg(i-1); end
    end
    idx = find(sg(1:end-1).*sg(2:end) < 0);
    den = s(idx+1) - s(idx);
    den(den==0) = eps;
    tzc = t(idx) - s(idx).*(t(idx+1)-t(idx))./den;
end

function [Apk, tpk] = picos(t, a, a0)
    s = a - a0;  tzc = cruces_cero(t, s);
    if numel(tzc) < 2, error('Sin oscilacion detectable.'); end
    Apk=[]; tpk=[];
    for kk = 1:numel(tzc)-1
        seg = (t>=tzc(kk)) & (t<=tzc(kk+1));
        ss = s(seg); ts = t(seg);
        if isempty(ss), continue; end
        [~,im] = max(abs(ss));
        Apk(end+1,1) = ss(im); %#ok<AGROW>
        tpk(end+1,1) = ts(im); %#ok<AGROW>
    end
end

function a0 = equilibrio(a, cfg)
    if isfield(cfg,'a0') && ~isempty(cfg.a0), a0 = cfg.a0; else, a0 = median(a); end
end

function [t,a] = recorta(t, a, t0, t1)
    if ~isempty(t0), m = t>=t0; t=t(m); a=a(m); end
    if ~isempty(t1), m = t<=t1; t=t(m); a=a(m); end
end

function [t,a] = sane(t,a)
    t=t(:); a=a(:,1);
    [t,is]=sort(t); a=a(is); [t,iu]=unique(t); a=a(iu);
end

function r = ternario(c,x,y), if c, r=x; else, r=y; end, end

function [t, a] = extraer_senal(v)
    if isa(v,'timeseries'), t=v.Time(:); a=v.Data(:,1);
    elseif isa(v,'Simulink.SimulationData.Dataset'), e=v{1}; t=e.Values.Time(:); a=e.Values.Data(:,1);
    elseif isstruct(v) && isfield(v,'time') && isfield(v,'signals'), t=v.time(:); a=v.signals.values(:,1);
    elseif isnumeric(v) && size(v,2)>=2, t=v(:,1); a=v(:,2);
    else, error('Formato no reconocido. Usa matriz [t a], timeseries, Dataset o struct .time/.signals.values.');
    end
end