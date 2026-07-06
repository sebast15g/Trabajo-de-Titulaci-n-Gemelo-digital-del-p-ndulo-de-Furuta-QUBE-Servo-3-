# Estado final del proyecto — Gemelo digital del péndulo de Furuta (QUBE-Servo 3)

Documento maestro de estado. Consolida hasta dónde está el trabajo y qué queda. Actualizado tras
cerrar los capítulos de la tesis y la integración de las modalidades de tiempo real en el
repositorio. **Único pendiente operativo: subir el repositorio** (el pulido de cierre del
repositorio está completo).

## Resumen de una línea

El gemelo digital analítico (M1) del péndulo de Furuta se construyó, se validó contra el modelo 3D
(M2) y contra el equipo real (M0), se le cerró el lazo con un observador (EKF de estado aumentado) y
un banco de control (swing-up por energía + balance LQI), y se desplegó sin cambios sobre cuatro
sustratos de ejecución (SIM, QSM, QHW, RTB) para medir la influencia de la simulación en tiempo real
sobre la fidelidad, la sincronización y el desempeño. Todo el material de respaldo está en este
repositorio.

## Qué está terminado

1. **Modelo 3D (M2) y parámetros.** SolidWorks → Simscape Multibody; dimensiones medidas y masas
   pesadas; parámetros físicos identificados por ensayo aislado y consolidados en
   `codigo/parametros_furuta.m` (g=9.7807, Ts=0.002). Cable del encoder: dinámica simplificada
   (rigidez, fricción seca, amortiguamiento de primer orden); la no linealidad de enrollamiento queda
   documentada como limitación.
2. **Modelo analítico (M1).** Euler-Lagrange, `f(x,u)` y jacobianos en forma cerrada; reproduce al 3D
   (RMSE θ=0.64°, α=0.83°); polo inestable en +13.42 rad/s.
3. **Observador (EKF).** Estado aumentado con la perturbación del cable; R=q²/12=7.84e-7,
   Q=diag(1e-7,1e-7,1e-5,1e-5,1e-4); sintonía por NIS; funciones codegen para Simulink; UKF ensayado
   y descartado.
4. **Control.** Banco swing-up + balance (LQI/LQR/PD/PID/LQG) sobre el estado estimado; conmutación en
   |α|≲17°; compensación por adelanto de la perturbación del cable.
5. **Gemelo bidireccional.** Acoplamiento físico-virtual por el propio EKF; espejo 3D con
   sincronizador; verificación de construcción en paralelo (real vs 3D, sin sincronización).
6. **Modalidades de ejecución (RTS).** Mismo M1 sobre simulación convencional (SIM), kernel de tiempo
   real de QUARC sobre el modelo (QSM), QUARC sobre la planta real (QHW = M0) y RT Box de PLECS (RTB),
   en los tres ensayos E1 (caída libre), E2 (respuesta forzada) y E3 (lazo cerrado). Comparación de
   fidelidad y de métricas de tiempo real completa.
7. **Hallazgos documentados.** Piso de 1 ms del temporizador de software de QUARC en Windows;
   sensibilidad del conteo de vaivenes del swing-up al integrador (Euler en RTB vs RK4 en QUARC) y a
   la idealización del modelo; dificultad intrínseca del sistema subactuado/inestable.
8. **Tesis (LaTeX).** Capítulos terminados y revisados: Marco Teórico (con las ecuaciones del EKF,
   LQR/LQI y el modelo analítico completo), Metodología, Desarrollo, Resultados, Conclusiones y
   recomendaciones, Resumen y Abstract. Figuras y tablas ajustadas. Fuente en
   `Documento/TESIS/` (fuera de este repositorio de código/datos).

## Estado del repositorio (TESIS_FINALES)

~305 archivos versionados (excluye artefactos de build), organizados por tema. Cierra el ciclo completo del trabajo:

```
TESIS_FINALES/
├── codigo/            (47)  parametros_furuta.m + referencia/ identificacion/ validacion/ modelo_control/ gemelo/
├── datos/             (38)  por tema (identificación, calibración, control, gemelo, validación)
├── figuras/           (46)  por tema (modelo_3d, motor, cable, contacto, alpha, analítico, ekf, control, gemelo, validación)
├── modelos/           (33)  .slx por tema (modelo_3d, ekf_control, gemelo, identificación, validación)
├── RTS_modalidades/  (133)  SIM/ QSM/ QHW/ RTB/ comparacion/ scripts/ docs/ (las 4 modalidades + comparación)
├── README.md                  (portada del repositorio)
├── ESTADO_FINAL_PROYECTO.md   (este archivo)
├── INDICE_documentacion.md    (índice unificado de la documentación)
└── LICENSE, CITATION.cff       (licencia MIT y cómo citar)
```

Una auditoría de completitud confirmó 0 figuras citadas faltantes y el código al día; `RTS_modalidades/`
incorpora la etapa de modalidades de tiempo real.

## Estado del cierre (completado)

El alistamiento del repositorio se completó en cinco fases:

- **Fase 1** — verificación funcional de los `.m` dentro de la estructura de subcarpetas.
- **Fase 2** — arranque automático (`PreLoadFcn`/`InitFcn`) en los modelos `.slx`.
- **Fase 3** — comentarios y encabezados a estilo técnico impersonal (sin cambios de lógica).
- **Fase 4** — `.gitignore`, unificación de nombres de figuras y depuración de duplicados.
- **Fase 5** — `LICENSE` (MIT), `CITATION.cff`, `README.md` por carpeta y verificación del índice.

En el cierre se corrigió además `parametros_furuta.m` (`Ts` 0.004 → 0.002, coherente con el resto
del repositorio) y un defecto de filtrado en `Analisis_pendulo_oscilacion_libre.m`.

El repositorio contiene ~305 archivos versionados (los artefactos de build quedan excluidos por
`.gitignore`). **Único pendiente: `git init` + commit y subida a GitHub**, desde una terminal local.
