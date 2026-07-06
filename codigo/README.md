# codigo/

Scripts y funciones de MATLAB del gemelo digital, organizados por etapa. Antes de
ejecutar cualquier archivo, correr `setup_paths.m` en la raíz del repositorio: arma
el path y deja el struct de parámetros `p` en el workspace (`parametros_furuta.m`).

- `parametros_furuta.m` — parámetros físicos finales (archivo central; cargar primero).
- `Ensamblaje_..._v4_DataFile.m` — `smiData` (geometría/inercias/CoM del CAD).
- `referencia/` — parámetros de referencia del péndulo rotatorio de Quanser.
- `identificacion/` — identificación de parámetros por ensayo aislado (§4.3):
  `motor_friccion/`, `cable_theta/`, `contacto_topes/`, `alpha/`, `inercia_Jr/`,
  `calibracion_voltaje/`.
- `validacion/` — validación de la fricción del motor y del retorno libre del cable (§4.3).
- `modelo_control/` — modelo analítico M1, observador EKF y banco de control (§4.4–§4.6).
- `gemelo/` — comparación real vs. modelo 3D y demostración del gemelo bidireccional (§4.8).
