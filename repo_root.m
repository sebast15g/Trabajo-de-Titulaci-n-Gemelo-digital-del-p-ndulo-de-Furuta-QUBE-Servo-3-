function root = repo_root()
%REPO_ROOT  Carpeta raiz del repositorio.
%  Se resuelve desde la ubicacion de este archivo, que reside en la raiz del
%  repositorio. Permite a scripts y funciones localizar datos/ y codigo/ sin
%  depender de la carpeta actual de MATLAB.
%
%  Requiere que la raiz este en el path (la anade setup_paths).
%  Salida: root (char) con la ruta absoluta de la raiz del repositorio.
root = fileparts(mfilename('fullpath'));
end
