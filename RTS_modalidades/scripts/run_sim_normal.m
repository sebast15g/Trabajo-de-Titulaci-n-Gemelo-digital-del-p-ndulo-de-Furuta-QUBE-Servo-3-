function RTF = run_sim_normal(model, Tstop, tag)
% RUN_SIM_NORMAL  Corre un modelo QSM en modo Normal (offline, sin tiempo real)
% y reporta el RTF = tiempo_modelo / tiempo_pared. Es la modalidad "sim normal"
% del estudio de RTS: RTF >> 1 (unica metrica de RTS que aplica; TET/overruns/
% jitter son n/a sin kernel de tiempo real).
%
%   RTF = run_sim_normal('E1_QSM', 15, 'E1')
%
% El .mat de fidelidad lo escribe el bloque To File del propio modelo (ponle
% nombre fid_<tag>_sim.mat). Este script solo mide el RTF y guarda rt_<tag>_sim.mat.
%
% NOTA: el modelo debe tener solver Fixed-step ode4 a 2e-3 (mismo que las demas
% modalidades). Los bloques QUARC de RTS (System Time / Computation Time) son n/a
% aqui; puedes dejarlos o desconectarlos, no afectan al RTF.

    if nargin < 3, tag = model; end

    % forzar modo Normal (offline), por si el modelo quedo en external/quarc
    set_param(model, 'SimulationMode', 'normal');

    % correr cronometrando el tiempo de pared
    tw = tic;
    simOut = sim(model, 'StopTime', num2str(Tstop)); %#ok<NASGU>
    t_wall = toc(tw);

    RTF = Tstop / t_wall;
    fprintf('%-8s | %.1f s de modelo en %.3f s de pared -> RTF = %.1f\n', ...
            tag, Tstop, t_wall, RTF);

    % guardar la (unica) metrica de RTS de sim normal
    rt = struct('RTF', RTF, 'Tstop', Tstop, 't_wall', t_wall, ...
                'nota', 'sim normal offline: TET/overruns/jitter = n/a');
    save(sprintf('rt_%s_sim.mat', tag), '-struct', 'rt');
end
