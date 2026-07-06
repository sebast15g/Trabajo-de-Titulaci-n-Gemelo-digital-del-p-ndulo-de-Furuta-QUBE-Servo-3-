%% ======================================================================
%  analisis_pendulo_oscilacion_libre.m
%  ----------------------------------------------------------------------
%  Extrae la frecuencia natural de pequena amplitud (f0) y la inercia del
%  pendulo respecto a su pivote (Jp) a partir de un ensayo de oscilacion
%  libre con el brazo (theta) bloqueado.
%
%   Entradas      : variable de datos reales (VAR_REAL) en el workspace.
%   Salidas       : f0, T0, Jp (consola) + figuras de senal y periodo-amplitud.
%   Dependencias  : ellipke (integral eliptica completa).
%
%  Corrige la dependencia periodo-amplitud de forma EXACTA mediante la
%  integral eliptica completa de primera especie:
%
%        T(theta0) = T0 * (2/pi) * K( sin(theta0/2)^2 )
%
%  De modo que recupera T0 (y f0 = 1/T0) desde cualquier amplitud, incluida
%  90 grados. Sirve igual para:
%    - la planta REAL (decae barriendo amplitudes -> muchos ciclos),
%    - el modelo DIGITAL sin amortiguamiento (amplitud constante -> 1 ciclo
%      ya basta, porque la correccion es exacta).
%
%  El periodo de cada ciclo se mide por CRUCES POR CERO interpolados (mas
%  precisos que los picos, donde la velocidad es nula y pesa la cuantizacion
%  del encoder). La amplitud de cada ciclo es la media de los dos extremos.
%
%  Configuracion en el bloque CONFIG: unidades, mp, Lp, g y el nombre de la
%  variable de datos. El analisis del registro del modelo se habilita
%  descomentando la seccion ANALISIS MODELO.
%
%  Validacion: f0 es el dato medido (independiente de g). Jp se DERIVA de f0
%  con Jp = mp*g*l/(2*pi*f0)^2 y por tanto escala con g; usa la g local.
%% ======================================================================

%% ===================== CONFIG (parametros de entrada) ================================
cfg.units = 'deg';      % unidades de la senal 'a': 'deg' o 'rad'
cfg.mp    = 0.024;      % masa del pendulo [kg]   (Tabla 2.2, QUBE-Servo 3)
cfg.Lp    = 0.129;    % longitud del pendulo [m] (medida con calibrador)
cfg.g     = 9.77;       % gravedad LOCAL [m/s^2]  (Cuenca ~9.77; verificar)
cfg.a0    = [];         % equilibrio de alpha; [] = usar la media de la senal
cfg.Amin_deg = 2;   
% --- Cargar la senal REAL del workspace -------------------------------
% VAR_REAL: variable con los datos reales. extraer_senal admite:
%   timeseries | struct .time/.signals.values | Dataset | matriz [t a] | [t,a]
VAR_REAL = data_alpha;                 % variable de datos reales (definir en el workspace)
[t, a]   = extraer_senal(VAR_REAL);

%% ===================== ANALISIS REAL ==================================
R = pend_decay(t, a, cfg);

%% ===================== ANALISIS MODELO (opcional) =====================
% Corre tambien sobre el registro del modelo digital. La correccion eliptica
% recupera su f0 aunque la amplitud sea constante (90 grados).
%
% VAR_MODELO = ScopeData_modelo;       % registro del modelo digital
% [tm, am]   = extraer_senal(VAR_MODELO);
% cfg_m      = cfg;  cfg_m.g = 9.80665; % g del modelo (la que tenga el .slx)
% Rm = pend_decay(tm, am, cfg_m);
% comparar(R, Rm);

%% ===================== FUNCIONES LOCALES ==============================
function R = pend_decay(t, a, cfg)
    % --- saneo de la senal ---
    t = t(:); a = a(:,1);
    if ~isnumeric(t) || ~isnumeric(a)
        error('t y a deben ser vectores numericos.');
    end
    [t, is] = sort(t);          a = a(is);
    [t, iu] = unique(t);        a = a(iu);

    % --- equilibrio y senal centrada ---
    if isempty(cfg.a0), a0 = mean(a); else, a0 = cfg.a0; end
    s = a - a0;

    % --- cruces por cero interpolados ---
    idx = find(s(1:end-1).*s(2:end) < 0);
    tzc = zeros(numel(idx),1);
    for k = 1:numel(idx)
        i = idx(k);
        tzc(k) = t(i) - s(i)*(t(i+1)-t(i))/(s(i+1)-s(i));
    end
    Nz = numel(tzc);
    if Nz < 3
        error('Senal insuficiente: solo %d cruces por cero detectados.', Nz);
    end

    % --- periodo completo y amplitud media de cada ciclo ---
    %     periodo i: del cruce i al cruce i+2 (un ciclo completo)
    nP  = Nz - 2;
    P   = zeros(nP,1);          % periodo [s]
    Ar  = zeros(nP,1);          % amplitud media [rad]
    tc  = zeros(nP,1);          % instante central [s]
    deg = strcmpi(cfg.units,'deg');
    for i = 1:nP
        P(i)  = tzc(i+2) - tzc(i);
        seg   = (t >= tzc(i)) & (t <= tzc(i+2));
        sp    = s(seg);
        Aamp  = (abs(max(sp)) + abs(min(sp)))/2;   % unidades originales
        if deg, Aamp = deg2rad(Aamp); end
        Ar(i) = Aamp;
        tc(i) = (tzc(i) + tzc(i+2))/2;
    end

    % --- descartar ciclos en zona de cuantizacion (amplitud < Amin_deg) ---
    keep = rad2deg(Ar) >= cfg.Amin_deg;
    if nnz(keep) >= 3
        P = P(keep);  Ar = Ar(keep);  tc = tc(keep);
    end
    nP = numel(P);

    % --- estimador EXACTO por integral eliptica (por ciclo) ---
    m    = sin(Ar/2).^2;
    Kc   = ellipke(m);
    T0i  = P .* (pi/2) ./ Kc;            % despeja T0 de T = T0*(2/pi)*K
    T0   = mean(T0i);
    T0sd = std(T0i);
    f0   = 1/T0;

    % --- verificacion cruzada: extrapolacion T vs amplitud^2 a 0 ---
    x = Ar.^2;
    if (max(x)-min(x)) > 1e-4               % hay barrido de amplitud (real)
        p1 = polyfit(x, P, 1);  P0lin = p1(end);
        if numel(x) >= 3
            p2 = polyfit(x, P, 2);  P0quad = p2(end);
        else
            p2 = []; P0quad = NaN;
        end
    else                                     % amplitud ~constante (modelo)
        p1 = []; p2 = []; P0lin = NaN; P0quad = NaN;
    end

    % --- inercia derivada ---
    l  = cfg.Lp/2;
    Jp = cfg.mp*cfg.g*l/(2*pi*f0)^2;

    % --- salida ---
    R = struct('f0',f0,'T0',T0,'T0_sd',T0sd,'Jp',Jp, ...
               'P',P,'A_rad',Ar,'tc',tc,'Ncyc',nP, ...
               'P0_lin',P0lin,'P0_quad',P0quad, ...
               'A_max_deg',rad2deg(max(Ar)),'A_min_deg',rad2deg(min(Ar)), ...
               'P_first',P(1),'cfg',cfg);

    % --- reporte ---
    fac = (2/pi)*ellipke(sin(max(Ar)/2)^2);
    fprintf('\n----- Oscilacion libre del pendulo -----\n');
    fprintf('Ciclos analizados : %d   (amplitud %.1f deg -> %.1f deg)\n', ...
            R.Ncyc, R.A_max_deg, R.A_min_deg);
    fprintf('Periodo 1er ciclo : %.5f s  (f = %.4f Hz)  [gran amplitud, NO usar para Jp]\n', ...
            R.P_first, 1/R.P_first);
    fprintf('Correccion a %2.0f deg: T/T0 = %.4f  (%.1f%% mas largo que peq. amplitud)\n', ...
            R.A_max_deg, fac, 100*(fac-1));
    fprintf('f0 (peq. amplitud): %.5f Hz   <-- usar este  [correccion eliptica]\n', R.f0);
    fprintf('   T0 = %.5f s   (dispersion entre ciclos = %.2e s)\n', R.T0, R.T0_sd);
    if ~isnan(R.P0_lin)
        fprintf('   cross-check lineal    : f0 = %.5f Hz\n', 1/R.P0_lin);
        if ~isnan(R.P0_quad)
            fprintf('   cross-check cuadratico: f0 = %.5f Hz\n', 1/R.P0_quad);
        end
    else
        fprintf('   (amplitud ~constante: extrapolacion no aplica; modelo sin amortiguamiento)\n');
    end
    fprintf('Jp (pivote): %.4e kg*m^2   [g=%.4f  mp=%.4f  l=%.5f]\n', ...
            R.Jp, cfg.g, cfg.mp, l);

    % --- figuras ---
    figure('Name','Oscilacion libre del pendulo','Color','w');
    subplot(2,1,1);
    plot(t, a, '-'); hold on; grid on;
    yline(a0, ':');
    plot(tzc, a0*ones(Nz,1), 'r.', 'MarkerSize', 9);
    xlabel('t [s]'); ylabel(sprintf('alpha [%s]', cfg.units));
    title('Senal y cruces por cero detectados');

    subplot(2,1,2);
    plot(x, P, 'o'); hold on; grid on;
    xx = linspace(0, max(x), 100);
    if ~isempty(p1), plot(xx, polyval(p1,xx), '-'); end
    if ~isempty(p2), plot(xx, polyval(p2,xx), '--'); end
    yline(R.T0, ':');
    xlabel('amplitud^2 [rad^2]'); ylabel('periodo [s]');
    title(sprintf('Periodo vs amplitud^2   ->   f0 = %.4f Hz (eliptico)', R.f0));
    leg = {'por ciclo'};
    if ~isempty(p1), leg{end+1} = 'extrap. lineal'; end
    if ~isempty(p2), leg{end+1} = 'extrap. cuadratica'; end
    leg{end+1} = 'T0 (eliptico)';
    legend(leg, 'Location','best');
end

function comparar(R, Rm)
    fprintf('\n========== Comparacion real vs modelo ==========\n');
    fprintf('f0 real   = %.4f Hz   (Jp = %.4e kg*m^2)\n', R.f0,  R.Jp);
    fprintf('f0 modelo = %.4f Hz   (Jp = %.4e kg*m^2)\n', Rm.f0, Rm.Jp);
    fprintf('Desviacion en f0 : %+.2f %%\n', 100*(Rm.f0 - R.f0)/R.f0);
    fprintf('Desviacion en Jp : %+.2f %%   (Jp ~ 1/f0^2; nota: depende de g)\n', ...
            100*(Rm.Jp - R.Jp)/R.Jp);
    fprintf('Nota: el dato medido y comparable es f0; Jp es derivado.\n');
end

function [t, a] = extraer_senal(v)
    % Adapta los formatos mas comunes a vectores (t, a).
    if isa(v,'timeseries')
        t = v.Time(:);            a = v.Data(:,1);
    elseif isa(v,'Simulink.SimulationData.Dataset')
        e = v{1};                 t = e.Values.Time(:);  a = e.Values.Data(:,1);
    elseif isstruct(v) && isfield(v,'time') && isfield(v,'signals')
        t = v.time(:);            a = v.signals.values(:,1);
    elseif isnumeric(v) && size(v,2) >= 2
        t = v(:,1);               a = v(:,2);
    else
        error(['Formato de datos no reconocido. Pasa una timeseries, un ' ...
               'Dataset, un struct con .time/.signals.values, o una matriz ' ...
               '[t a]; o asigna t y a a mano y llama pend_decay(t,a,cfg).']);
    end
end