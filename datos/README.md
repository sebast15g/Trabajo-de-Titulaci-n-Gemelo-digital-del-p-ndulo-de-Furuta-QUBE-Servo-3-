# datos/

Datos de entrada y registros (`.mat`/`.csv`) que consumen los scripts, por tema. Se
resuelven por el path (`setup_paths.m`), sin rutas absolutas.

- `motor_friccion/`, `cable_theta/`, `contacto_topes/`, `alpha/`, `calibracion_voltaje/`
  — datos de identificación de parámetros (§4.3).
- `control/` — logs del banco de controladores (LQR/LQI/PD/PID).
- `gemelo/` — logs de sincronización y de verificación de construcción (real vs. 3D).
- `modelo_control/` — artefactos del modelo y del observador (`banco_controladores.mat`,
  `modelo_furuta_EKF.mat`).
- `validacion/` — salidas de simulación para las figuras de validación.
