function generar_excitacion(A_chirp, A_step, f0, f1, plotear)
% GENERAR_EXCITACION  Crea la señal de voltaje de excitación para calibrar/validar
%   el modelo (etapa alta fidelidad). Pensada para el QUBE-Servo 3 con el PÉNDULO
%   COLGANDO (estable). Excita inercia + fricción + resonancia del brazo-cable sin
%   disparar θ (chirp POR ENCIMA de la resonancia ~0.47 Hz).
%
%   generar_excitacion                          valores por defecto
%   generar_excitacion(A_chirp,A_step,f0,f1)    ajusta amplitudes/frecuencias
%
%   Deja la señal como timeseries 'Vm_exc' en el workspace y en 'excitacion_Vm.mat'.
%   En Simulink: bloque FROM WORKSPACE -> Data = Vm_exc, Sample time = 0.002,
%   y conéctala donde iba la salida del control (-> Sat ±10 -> For +ve CCW -> HIL Write).
%
%   Nota de seguridad: iniciar con A_chirp pequeño; vigilar |θ|<30° y reducirlo si se excede.

    if nargin<1||isempty(A_chirp), A_chirp=0.4; end   % V  amplitud del chirp
    if nargin<2||isempty(A_step),  A_step =0.2; end   % V  amplitud de los escalones
    if nargin<3||isempty(f0), f0=1;  end              % Hz inicio (por encima de la resonancia)
    if nargin<4||isempty(f1), f1=6;  end              % Hz fin
    if nargin<5, plotear=true; end
    Ts=0.002;

    % --- 1) Escalones iniciales (parte lenta/transitoria): +A,-A,+A,-A, 1.5 s c/u ---
    Tstep=1.5; ns=round(Tstep/Ts);
    vstep=1.5*[ A_step*ones(1,ns), -A_step*ones(1,ns), A_step*ones(1,ns), -A_step*ones(1,ns) ];

    % --- 2) Chirp logarítmico f0->f1 (inercia/fricción/resonancia) ---
    Tch=40; tch=0:Ts:Tch-Ts;
    vch=A_chirp*chirp(tch, f0, tch(end), f1, 'logarithmic');

    % --- 3) Unir + ventana suave en bordes (evita escalón brusco) ---
    Vm=[zeros(1,ns/2), vstep, vch, zeros(1,ns/2)];
    nw=round(0.15/Ts); w=ones(size(Vm)); w(1:nw)=linspace(0,1,nw); w(end-nw+1:end)=linspace(1,0,nw);
    Vm=Vm.*w;
    t=(0:numel(Vm)-1)*Ts;

    Vm_exc=timeseries(Vm.', t.');
    save(fullfile(fileparts(mfilename('fullpath')),'excitacion_Vm.mat'),'Vm_exc');
    assignin('base','Vm_exc',Vm_exc);
    fprintf('Señal lista: duración=%.1f s, %d muestras, Ts=%.3g s\n', t(end), numel(Vm), Ts);
    fprintf('  escalones ±%.2f V (1.5 s c/u) + chirp %g–%g Hz, ±%.2f V\n', A_step, f0, f1, A_chirp);
    fprintf('  -> en el workspace como Vm_exc y en excitacion_Vm.mat\n');
    fprintf('  StopTime del modelo = %.1f s\n', t(end));

    if plotear
        figure('Name','Señal de excitación Vm','Color','w','Position',[80 80 950 320]);
        plot(t,Vm,'b'); grid on; xlabel('t [s]'); ylabel('Vm [V]'); title('Excitación (escalones + chirp 1–6 Hz) — péndulo colgando');
    end
end
