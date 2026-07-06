# modelos/

Modelos de Simulink/Simscape (`.slx`) por tema: `modelo_3d/`, `motor_friccion/`,
`cable_theta/`, `contacto_topes/`, `alpha/`, `ekf_control/`, `gemelo/`, `validacion/`.

Cada modelo trae un `PreLoadFcn` que localiza la raíz del repositorio (buscador por
marcador), arma el path y carga los parámetros; no requiere preparación manual. Los
modelos 3D ejecutan además el `DataFile` para poblar `smiData` antes de compilar.
