# Índice unificado de la documentación

Punto de entrada único a toda la documentación del proyecto. Reúne (une) los documentos dispersos que
se produjeron durante el trabajo, agrupados por tema. Las rutas relativas parten de `Scape/`.

Convención: **[GD]** = carpeta `Gemelo Digital del pendulo invertido de Furuta usando el QubeServo 3
de Quanser/` (documentos de proceso). **[RF]** = `TESIS_FINALES/RTS_modalidades/docs/`. **[TF]** =
`TESIS_FINALES/`.

## 0. Estado y navegación
- **[TF] ESTADO_FINAL_PROYECTO.md** — estado global; qué está hecho y qué queda.
- **[TF] README.md** — portada del repositorio, estructura y guía de uso.
- **[TF] LICENSE**, **[TF] CITATION.cff** — licencia MIT y forma de citar.
- **[TF] codigo/README.md · datos/README.md · figuras/README.md · modelos/README.md** — índice por carpeta.
- **[GD] INVENTARIO_archivos_finales_tesis.md** — inventario de archivos por sección de la tesis.
- **[GD] AUDITORIA_documentacion_vs_tesis.md** — cruce documentación ↔ capítulos.

## 1. Modelado 3D y parámetros
- **[GD] modelos_v4_y_Model3d_legible.md** — modelo 3D (SolidWorks→Simscape) legible.
- **Scape/DOCUMENTACION_Ensamblaje_pendulo_furuta_multibody_v4.md** — ensamblaje multibody v4.
- **[GD] metodologia_gemelo_digital.md** — metodología general de construcción del gemelo.

## 2. Identificación de parámetros (§4.3)
- **[GD] metodologia_cable_encoder_theta.md** — cable del encoder sobre θ (rigidez, fricción, tope).
- **[GD] calibracion_protocolo.md** — protocolo de calibración por excitación aislada.
- **[GD] analisis_paper_Le2020_cable_y_motor.md** — parámetros de motor y cable desde Le et al. (2020).
- **[GD] instrucciones_linealizacion_simscape.md** — linealización del 3D (cross-check de polos).

## 3. Modelo analítico y observador (§4.4–§4.5)
- **[GD] modelo_alta_fidelidad_observador.md** — modelo analítico + EKF de alta fidelidad.
- **[GD] implementacion_gemelo_en_linea.md** — implementación en línea del observador/control.

## 4. Control, swing-up y gemelo bidireccional (§4.6–§4.8)
- **[GD] etapa5_construccion_paso_a_paso.md** — construcción incremental (EKF→control→banco).
- **[GD] guia_E3_swingup_hibrido.md** — swing-up por energía + conmutación a balance.
- **[GD] acoplamiento_bidireccional_real_digital.md** — acoplamiento físico-virtual (bidireccional).
- **[GD] guia_dashboard_gemelo.md** — visualización/dashboard del gemelo.

## 5. C-Scripts (RT Box / PLECS)
- **[GD] guia_cscripts_plecs.md** — guía completa de los C-Scripts en PLECS.
- **[GD] cscript_PLANTA_corregido.md**, **cscript_control_ekf_swingup.md**, **cscript_excitacion_E2.md**
  — transcripción y notas de cada C-Script.

## 6. Modalidades de tiempo real y comparación (§4.9 / Resultados)
- **[RF] doc_SIM.md, doc_QSM.md, doc_QHW.md, doc_RTB.md** — una por modalidad (RTB y QSM extensas).
- **[RF] DOCUMENTACION_MAESTRA_RTS_E1E2E3.md**, **DOCUMENTACION_MAESTRA_SIM_QUARC_E1E2E3.md**,
  **DOCUMENTACION_GENERAL_RTS_unificada.md** — documentos maestros de las modalidades.
- **[TF] RTS_modalidades/comparacion/COMPARACION_4_modalidades.md** — tablas de fidelidad y RTS.
- **[RF] metricas_cuantitativas.md**, **GUIA_ubicacion_resultados_rtbox.md**.
- **[GD] guia_sim_normal_quarc_real_E1E2E3.md**, **guia_logging_RTS_plecs_quarc_sim.md**,
  **guia_rtbox_ce_lazo_abierto.md**, **guia_udp_y_comparacion_modalidades.md** — montaje y logging.
- **[GD] experimentos_E1E2E3_excitacion_y_logging.md** — excitación y logging por modalidad.

## 7. Hallazgos
- **[RF] hallazgo_QUARC_timer_floor_RTS.md** — piso de 1 ms del temporizador de QUARC en Windows.
- **[RF] hallazgo_swingup_integrador.md** — conteo de vaivenes sensible al integrador (Euler vs RK4).
- **[RF] hallazgo_dificultad_gemelo_furuta.md** — dificultad del sistema subactuado/inestable.
- **[RF] memo_correccion_2ms_RTBOX.md** — corrección del paso de 2 ms en la RT Box.

## 8. Extensiones (fuera del alcance del trabajo actual)
- **[GD] gemelo_robusto_tolerancia_fallos.md**, **procedimiento_reconfiguracion_sensor.md** — FTC/FDI.
- **[GD] guia_E3_HIL_TI_migracion.md**, **guia_E3_TI_C2000_rtbox_HIL.md** — migración a HIL con tarjeta TI.

## 9. Bibliografía
- **[GD] fuentes_bibliograficas_proyecto.md** — fuentes usadas en el proyecto.

## 10. Redacción de la tesis
- **[RF] PLAN_redaccion_desarrollo_resultados.md** — plan de redacción de Desarrollo y Resultados.
- Fuente LaTeX final en `Documento/TESIS/` (capítulos cerrados: Marco, Metodología, Desarrollo,
  Resultados, Conclusiones, Resumen, Abstract).

## 11. Archivo histórico
- **[GD] _docs_archivo/** — instrucciones y estados de etapas ya superadas (cerrar_etapa1, EKF Simulink,
  compensación d, LQI, swing-up, roadmap, prompts de continuación). Se conservan como registro del
  proceso; el estado vigente está en los documentos maestros de la sección 0.
