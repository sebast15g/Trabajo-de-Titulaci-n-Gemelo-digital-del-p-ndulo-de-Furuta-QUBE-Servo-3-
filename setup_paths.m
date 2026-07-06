function setup_paths()
%SETUP_PATHS  Prepara el path del repositorio y carga los parametros centrales.
%  Anade al path de MATLAB el codigo, los datos y los scripts de post-proceso del
%  repositorio, y deja el struct de parametros 'p' en el workspace base ejecutando
%  parametros_furuta.m. La raiz se localiza desde la ubicacion de este propio archivo,
%  de modo que funciona sin importar cual sea la carpeta actual de MATLAB.
%
%  Uso:
%    - Manual: ejecutar setup_paths una vez tras abrir MATLAB.
%    - Modelos .slx: invocado desde PreLoadFcn/InitFcn (ver Fase 2 del cierre).
%
%  Salidas: struct 'p' en el workspace base; rutas anadidas al path (no persistente).
%  Dependencias: codigo/parametros_furuta.m.

root = fileparts(mfilename('fullpath'));

addpath(root);
addpath(genpath(fullfile(root, 'codigo')));
addpath(genpath(fullfile(root, 'datos')));

mdl = fullfile(root, 'modelos');
if isfolder(mdl)
    addpath(genpath(mdl));   % .slx y datos de los modelos (para load_system por nombre)
end

rts = fullfile(root, 'RTS_modalidades');
if isfolder(rts)
    addpath(genpath(rts));   % scripts + datos por modalidad (SIM/QSM/QHW/RTB/comparacion)
end

run(fullfile(root, 'codigo', 'parametros_furuta.m'));
end
