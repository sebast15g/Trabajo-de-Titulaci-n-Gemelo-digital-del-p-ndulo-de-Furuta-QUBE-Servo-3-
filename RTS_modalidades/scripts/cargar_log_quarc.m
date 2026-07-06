function D = cargar_log_quarc(fp)
% CARGAR_LOG_QUARC  Carga un log de QUARC robusto a MAT v4 mal finalizado.
%   El bloque "To File" de QUARC, si la corrida se detiene a mano, deja la
%   cabecera v4 inconsistente (declara más/menos columnas que las escritas) y a
%   veces relleno de ceros al final, y MATLAB `load` falla con "File might be
%   corrupt". Esta función intenta `load`; si falla, lee el v4 crudo, reconstruye
%   la matriz con las columnas realmente escritas y recorta el padding.
%
%   D = cargar_log_quarc(fp)  -> D en orientación (señales x N).

    D=[];
    try
        S=load(fp); f=fieldnames(S); D=S.(f{1});
    catch
        fid=fopen(fp,'r','ieee-le');
        h=fread(fid,5,'int32');           % [mopt mrows ncols imagf namelen]
        mrows=h(2); namelen=h(5);
        fseek(fid, namelen, 'cof');        % saltar el nombre de la variable
        data=fread(fid,inf,'double');      % leer TODOS los doubles escritos
        fclose(fid);
        N=floor(numel(data)/mrows);
        D=reshape(data(1:N*mrows), mrows, N);
        warning('cargar_log_quarc:recuperado', ...
            'MAT v4 mal finalizado: recuperadas %d columnas crudas.', N);
    end
    % orientar a (señales x N): el tiempo (N) es la dimensión mayor
    if size(D,1)>size(D,2), D=D.'; end
    % recortar columnas finales todo-cero (padding del To File)
    nz=any(D~=0,1); last=find(nz,1,'last');
    if ~isempty(last), D=D(:,1:last); end
end
