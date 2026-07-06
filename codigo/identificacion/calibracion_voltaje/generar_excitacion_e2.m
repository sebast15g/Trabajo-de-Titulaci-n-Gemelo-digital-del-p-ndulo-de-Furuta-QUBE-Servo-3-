function generar_excitacion_e2(plotear)
% GENERAR_EXCITACION_E2  Senal de voltaje Vm para el experimento E2 (respuesta
%   forzada en lazo abierto, pendulo COLGANDO) del gemelo digital del Furuta.
%   Tres fases pensadas para excitar la dinamica sin sorpresas y exponer el
%   desajuste esperado en alta frecuencia:
%     1) Cuadrada bipolar de amplitud creciente, baja frecuencia (transitorios,
%        rango del brazo; las amplitudes altas llegan al tope, como el real).
%     2) Multiseno de baja frecuencia (excitacion suave y REPRODUCIBLE, hace de
%        "random" sin perder determinismo entre modalidades).
%     3) Chirp corto a frecuencias mas altas (0.5->3 Hz), amplitud menor: aqui
%        es donde el modelo se desajusta mas, y queda documentado.
%
%   Ts = 0.002 s (IDENTICO al real, para que las tres modalidades no difieran).
%   |Vm| <= 2 V por seguridad. Convencion de signo: la del real (sin cambios).
%
%   Exporta, junto a este .m:
%     excitacion_Vm_e2.mat : Vm_exc (timeseries), Vm_signal=[t Vm], t, Vm, Ts
%     excitacion_Vm_e2.csv : columnas t,Vm  (para PLECS/RT Box "From File")
%
%   USO:
%   - Simulink/QUARC : bloque FROM WORKSPACE, Data = Vm_signal (o Vm_exc),
%     Sample time = 0.002, INTERPOLACION OFF (zero-order hold), "Form output
%     after final data value = Hold final value". Conectar donde iba el control.
%   - PLECS/RT Box   : bloque FROM FILE apuntando a excitacion_Vm_e2.csv
%     (primera columna = tiempo). Mismo Ts del modelo discreto = 0.002.

    if nargin<1, plotear=true; end
    Ts = 0.002;

    % --- Fase 1: cuadrada bipolar, amplitudes crecientes, baja frecuencia ---
    amps  = [0.5 1.0 1.5];          % V  niveles (el de 1.5 V alcanza el tope)
    Thalf = 1.5;                    % s  medio periodo (~0.33 Hz)
    nh    = round(Thalf/Ts);
    v1 = [];
    for a = amps
        v1 = [v1, a*ones(1,nh), -a*ones(1,nh)];   % un ciclo +/- por nivel
    end

    % --- Fase 2: multiseno de baja frecuencia (reproducible) ---
    T2 = 12; t2 = (0:round(T2/Ts)-1)*Ts;
    fk = [0.20 0.35 0.55 0.80];     % Hz componentes bajas
    ph = [0.0 1.1 2.7 0.4];         % fases fijas (reproducibilidad)
    v2 = zeros(size(t2));
    for i = 1:numel(fk), v2 = v2 + sin(2*pi*fk(i)*t2 + ph(i)); end
    v2 = 1.0 * v2 / max(abs(v2));   % normaliza a +/-1.0 V

    % --- Fase 3: chirp corto a frecuencias mas altas, amplitud menor ---
    T3 = 8; t3 = (0:round(T3/Ts)-1)*Ts;
    v3 = 0.6 * chirp(t3, 0.5, t3(end), 3.0, 'linear');

    % --- union con pausas a 0 entre fases ---
    np = round(1.0/Ts); z = zeros(1,np);
    Vm = [z, v1, z, v2, z, v3, z];

    % ventana suave en los extremos (evita escalon brusco al arrancar/parar)
    nw = round(0.10/Ts); w = ones(size(Vm));
    w(1:nw) = linspace(0,1,nw); w(end-nw+1:end) = linspace(1,0,nw);
    Vm = Vm .* w;

    Vm = max(min(Vm, 2.0), -2.0);   % saturacion de seguridad +/-2 V
    t  = (0:numel(Vm)-1)*Ts;

    % --- exportar ---
    Vm_exc    = timeseries(Vm(:), t(:));   %#ok<NASGU>
    Vm_signal = [t(:) Vm(:)];              %#ok<NASGU>
    here = fileparts(mfilename('fullpath'));
    save(fullfile(here,'excitacion_Vm_e2.mat'),'Vm_exc','Vm_signal','t','Vm','Ts');
    writematrix([t(:) Vm(:)], fullfile(here,'excitacion_Vm_e2.csv'));
    % cabecera legible para el CSV (PLECS ignora/usa la 1a col como tiempo)
    fid = fopen(fullfile(here,'excitacion_Vm_e2_conheader.csv'),'w');
    fprintf(fid,'t,Vm\n'); fclose(fid);
    writematrix([t(:) Vm(:)], fullfile(here,'excitacion_Vm_e2_conheader.csv'),'WriteMode','append');

    fprintf('Excitacion E2 lista: %.2f s, %d muestras, Ts=%.4g s, |Vm|max=%.2f V\n',...
            t(end), numel(Vm), Ts, max(abs(Vm)));
    fprintf('  Fase1 cuadrada +/-[%.1f %.1f %.1f] V | Fase2 multiseno 0.2-0.8 Hz | Fase3 chirp 0.5-3 Hz\n',amps);
    fprintf('  StopTime del modelo = %.2f s. Archivos: excitacion_Vm_e2.mat / .csv\n', t(end));

    if plotear
        f = figure('Color','w','Position',[80 80 980 320]);
        plot(t,Vm,'b'); grid on; xlabel('t [s]'); ylabel('V_m [V]');
        title('Excitacion E2: cuadrada (amp. creciente) + multiseno + chirp');
        exportgraphics(f, fullfile(here,'excitacion_Vm_e2.png'),'Resolution',150);
    end
end
