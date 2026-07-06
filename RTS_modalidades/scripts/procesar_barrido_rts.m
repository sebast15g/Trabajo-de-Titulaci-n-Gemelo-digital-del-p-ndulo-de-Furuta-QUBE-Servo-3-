function T = procesar_barrido_rts(carpeta, prefijo, pasos)
% PROCESAR_BARRIDO_RTS  Arma la tabla RTS del barrido de paso de QUARC-QSM.
%   Lee los rt_*.mat de cada paso base y calcula RTF, TET (min/med/max),
%   overruns (#TET>paso) y el paso real logrado. Es el post-proceso del barrido
%   de tiempo real (E1 lazo abierto / E3 lazo cerrado) del estudio de RTS.
%
%   Layout rt (QUARC): [t_auto, seq, t_model, t_wall, TET].
%
%   Uso:
%     pasos = [2e-3 1e-3 5e-4 1e-4 5e-5 1e-5 5e-6 1e-6];
%     T = procesar_barrido_rts('.', 'rt_E1_qsm', pasos);
%   Espera archivos tipo rt_E1_qsm_2e_3.mat, rt_E1_qsm_1e_6.mat, etc.
%   (con la convencion de nombre: 2e_3, 5e_4, 25e_4, 1e_6 ...).

    if nargin < 3
        pasos = [2e-3 1e-3 5e-4 1e-4 5e-5 1e-5 5e-6 1e-6];
    end
    n = numel(pasos);
    paso=zeros(n,1); RTF=zeros(n,1); TETmin=zeros(n,1); TETmed=zeros(n,1);
    TETmax=zeros(n,1); over=zeros(n,1); pasoreal=zeros(n,1); N=zeros(n,1);

    fprintf('%-9s %8s %9s %9s %9s %7s %10s\n', ...
            'paso[s]','RTF','TETmed','TETmax','over%','N','pasoreal');
    for i = 1:n
        tag = num2str(pasos(i), '%g');
        tag = strrep(strrep(tag, '.', ''), '-', '_');   % 5e-04 -> 5e_04
        % probar variantes comunes de nombre
        cand = dir(fullfile(carpeta, [prefijo '_*' 'e' '*' '.mat']));
        f = elegir_archivo(carpeta, prefijo, pasos(i));
        if isempty(f)
            fprintf('%-9g  (sin archivo)\n', pasos(i)); continue;
        end
        S = load(f); Q = S.(char(fieldnames(S)));
        if size(Q,1) > size(Q,2), Q = Q.'; end
        if size(Q,2) < 5, fprintf('%-9g  vacio/corto\n', pasos(i)); continue; end
        tm = Q(1,:); tw = Q(4,:); tet = Q(5,:); tet = tet(2:end);   % dropa 1a muestra
        Ts = pasos(i);
        paso(i)=Ts; N(i)=numel(tm);
        RTF(i)=(tm(end)-tm(1))/(tw(end)-tw(1));
        TETmin(i)=min(tet)*1e6; TETmed(i)=median(tet)*1e6; TETmax(i)=max(tet)*1e6;
        over(i)=100*mean(tet>Ts); pasoreal(i)=(tw(end)-tw(1))/numel(tm)*1e6;
        fprintf('%-9g %8.3f %7.1fus %7.0fus %7.1f %7d %8.2fus\n', ...
                Ts, RTF(i), TETmed(i), TETmax(i), over(i), N(i), pasoreal(i));
    end
    k = find(RTF>0 & RTF<0.99, 1);
    if ~isempty(k) && k>1
        fprintf('\nCruce RTF=1 entre paso %g (RTF %.2f) y %g (RTF %.2f).\n', ...
                paso(k-1), RTF(k-1), paso(k), RTF(k));
    end
    T = table(paso, RTF, TETmin, TETmed, TETmax, over, pasoreal, N);
end

function f = elegir_archivo(carpeta, prefijo, Ts)
    % construye el sufijo tipo 2e_3, 5e_4, 1e_6, 25e_4 y busca el .mat
    suf = {};
    switch Ts
        case 2e-3, suf = {'2e_3'};
        case 1e-3, suf = {'1e_3'};
        case 5e-4, suf = {'5e_4','5e-4'};
        case 2.5e-4, suf = {'25e_4','2_5e_4'};
        case 1e-4, suf = {'1e_4'};
        case 5e-5, suf = {'5e_5'};
        case 1e-5, suf = {'1e_5'};
        case 5e-6, suf = {'5e_6'};
        case 1e-6, suf = {'1e_6'};
        otherwise, suf = {strrep(num2str(Ts,'%g'),'.','')};
    end
    f = '';
    for j = 1:numel(suf)
        c = fullfile(carpeta, sprintf('%s_%s.mat', prefijo, suf{j}));
        if isfile(c), f = c; return; end
    end
end
