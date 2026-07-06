# Documentación general unificada — estudio de fidelidad del gemelo y de RTS (E1/E2/E3)

Documento paraguas que **unifica los dos procedimientos** del estudio: la rama **RT Box (PLECS
Coder)** y la rama **Simulink/MATLAB/QUARC (sim normal + QUARC-modelo + QUARC-real)**. Da el molde
común, contrasta cómo se hizo cada cosa en cada sustrato, consolida los hallazgos de RTS y apunta a
las dos documentaciones maestras y a todos los artefactos (guías, C-Scripts, scripts Python, `.m`,
comandos, targets/IPs, carpetas). Sirve como punto de entrada único para redactar Desarrollo y
Resultados sin mezclar los dos flujos.

Documentos maestros que este general integra:
- **RT Box:** `DOCUMENTACION_MAESTRA_RTS_E1E2E3.md` (y copia en `RTS_SIM_RTBOX1/`).
- **Simulink/QUARC:** `SIM_QUARC_RTS/DOCUMENTACION_MAESTRA_SIM_QUARC_E1E2E3.md`.
- **Hallazgo de RTS de QUARC:** `SIM_QUARC_RTS/E1_QSM/hallazgo_QUARC_timer_floor_RTS.md`.

---

## 1. Panorama del estudio

Se compara **el mismo gemelo digital** del péndulo de Furuta (QUBE-Servo 3) ejecutado en **cuatro
sustratos**, contra la **planta real (M0)**, en tres experimentos (E1 caída libre, E2 respuesta
forzada, E3 lazo cerrado swing-up + balance + EKF):

| Modalidad | Sustrato | Planta | RTF | Rama |
|---|---|---|---|---|
| **SIM** | Simulink offline (PC) | modelo M1 | ≫ 1 | Simulink/QUARC |
| **QSM** | kernel QUARC (PC) | modelo M1 | = 1 | Simulink/QUARC |
| **QHW** | kernel QUARC + QUBE real | planta física **M0** | = 1 | Simulink/QUARC |
| **RTB** | RT Box (PLECS Coder) | modelo M1 (C-Script) | = 1 | RT Box |

- **M0** = QUBE-Servo 3 real (referencia de fidelidad).
- **M1** = modelo analítico de 4 estados. En la box es el C-Script `PLANTA`; en Simulink es
  `furuta_planta_analitica.m` (transcripción literal, verificada a 1.14e-13). **Es el mismo modelo en
  las cuatro modalidades** — condición para que el delta entre modalidades mida solo la RTS.
- **M2** = modelo 3D Simscape, usado para calibrar M1 (no interviene como planta del estudio).

Dos familias de métricas: **fidelidad** (gemelo vs real: RMSE θ/α, e_max, `f_n`/`ζ`, índices E3, NIS) y
**RTS** (impacto del tiempo real: RTF, TET, overruns, jitter, muestras perdidas).

---

## 2. Molde común (idéntico en las cuatro modalidades)

Lo que garantiza que la comparación sea homogénea (detalle en las §2 de cada maestra):

1. **`Ts = 2 ms` (500 Hz)** de muestreo/comparación; paso base de integración fino (RT Box `5e-4`;
   Simulink/QUARC `nsub=4` → `h=5e-4`); comparación decimada a 2 ms.
2. **Convención de ángulos** α=0 arriba, π colgado; `α_real ↔ π−α_modelo` en post; **α unwrapped**
   hacia el EKF (encoder incremental).
3. **Excitación E2** = `excitacion_Vm_e2` (ZOH, interpolación OFF). En la box vía C-Script `EXCITACION`
   (indexado por `seq`, `RATIO` por modalidad); en Simulink/QUARC vía `From Workspace`.
4. **CI por experimento**: E1 `AL0=0.05`, E2/E3 `AL0=π`.
5. **Tiempo como canal explícito** (fila 1); `seq` para muestras perdidas.
6. **Mismo vector de fidelidad** (9 filas abierto; +estimador/control en E3) y **dos `.mat`** por corrida
   (fidelidad + tiempo real) unidos por `seq`.
7. **Controlador E3 idéntico**: EKF de estado aumentado + swing-up de energía (Quanser) + balance LQI
   del proyecto (`K_LQI`). Lazo roto con `Delay z⁻¹` (box/QSM/SIM) o por el I/O físico (QHW).

---

## 3. Las dos ramas de procedimiento (cómo se hizo cada cosa)

| Aspecto | Rama RT Box | Rama Simulink/QUARC |
|---|---|---|
| **Planta M1** | C-Script `PLANTA` (continuo, 4 estados) | `furuta_planta_analitica.m` (MATLAB Function, RK4 discreto) |
| **Control E3** | C-Script `CONTROL_EKF_SWINGUP` | bloques: `ekf_step.m` + swing-up Quanser + LQI |
| **Excitación E2** | C-Script `EXCITACION` (From File no code-genera) | `From Workspace` (ZOH) |
| **Ruptura lazo E3** | `Delay z⁻¹` (C-Script feedthrough) | `Unit Delay z⁻¹` (QSM/SIM); I/O físico (QHW) |
| **Tiempo/seq** | `Constant→Sum→Delay` o C-Script `DiscState` (NO Ramp/Clock) | `Counter Free-Running`; QUARC antepone `t` |
| **Reloj de pared** | `Wall Clock` (requiere NTP) | bloque QUARC **System Time** (*Wall clock*) |
| **TET** | NO hay bloque; se lee de la web/Application Log (agregado por corrida) | bloque QUARC **Computation Time** (*Output computation time of task*) |
| **Overruns** | Application Log (`getApplicationLog`), errata `Overrrun`, recuento con `count_overruns()` | `#(TET>Ts)` del log + consola del kernel |
| **Barrido de paso** | *Discretization step* en Coder Options → Scheduling | *Fixed-step size* del solver (bloques a `-1`); requiere **fast system timer** para <1 ms |
| **Ejecución/captura** | interfaz web `http://<ip>/`, API JSON-RPC/XML-RPC `http://<ip>:9998/rpc2` (o `/RPC2`); scripts `rtbox_watch.py`/`rtbox_log.py` | `quarc_run` / `.rt-win64` standalone (`shmem://model:1`), o Monitor & Tune (External Mode, topa a 1 kHz) |
| **Target / dirección** | RT Box 1 por IP/nombre en la LAN (WebDAV `http://<nombre-rtbox>/dav`) | target `quarc_win64` local; interfaz con el QUBE por **HIL API** (`qube_servo3_usb`) |
| **Carga de datos** | `cargar_log_rtbox.m` | `cargar_log_quarc.m` |
| **Documentación** | `guia_cscripts_plecs.md`, `guia_E3_swingup_hibrido.md`, `guia_E3_TI_C2000_rtbox_HIL.md` (HIL con TI, futuro), `guia_logging_RTS_plecs_quarc_sim.md`, `experimentos_E1E2E3_excitacion_y_logging.md` | `DOCUMENTACION_MAESTRA_SIM_QUARC_E1E2E3.md`, `hallazgo_QUARC_timer_floor_RTS.md` |

> **Cuidado con el "control con HIL":** en la rama RT Box hay una configuración avanzada documentada
> (E3-HIL con el controlador en una TI C2000 y la planta en la RT Box, unidas por la Plexim RT Box
> LaunchPad Interface) que quedó como **trabajo futuro** — NO forma parte de las cuatro modalidades del
> estudio (en QUARC/real el control va en el kernel del PC, no en tarjeta externa). Ver
> `guia_E3_TI_C2000_rtbox_HIL.md` / `guia_E3_HIL_TI_migracion.md`. En la rama Simulink/QUARC, "HIL" es
> solo el sentido comercial de Quanser (la HIL API que conecta con el QUBE), no HIL de controlador.

---

## 4. Hallazgos de RTS unificados

El contraste central del estudio es **libre (SIM) vs tiempo real estricto (QSM/QHW/RTB)**, y dentro del
tiempo real, **cómo topa cada sustrato**:

- **SIM**: RTF ≫ 1 (12–35× medido); TET/overruns/jitter = n/a. Es la cota "sin restricción".
- **RTB (RT Box, bare-metal): *compute-bound*.** Timer de hardware fino (fija pasos hasta 5 µs);
  overrunea cuando el TET supera al paso: ~5–10 µs lazo abierto (TET 6–7 µs), ~16–17 µs lazo cerrado
  (el EKF triplica el TET). Jitter sub-µs (hardware-locked).
- **QSM/QHW (QUARC sobre Windows): *timer/jitter-bound*.** Con el timer por defecto, **piso duro en 1 ms**
  (rechaza pasos menores; Quanser mismo llama "crude and inaccurate" a la tasa de 1 kHz de Windows). Con
  **fast system timer** el piso desaparece y mantiene RTF=1 hasta ~5 µs (abierto y cerrado), colapsando
  en 1 µs. El costo del EKF (lazo cerrado) es despreciable en QUARC porque el PC es rápido → abierto y
  cerrado topan igual (a diferencia de la box, donde el cerrado topa antes).
- **Jitter por timebase (2 ms, sin overruns):** RTB sub-µs ≪ **QHW ~36–70 µs** (la tarjeta HIL aporta un
  *hardware timebase* que disciplina el lazo) ≪ **QSM ~320 µs** (solo timer de software de Windows).

Lectura para la tesis: **RT Box gana en determinismo** (jitter acotado por hardware); **QUARC + fast
timer gana en throughput mediano** (CPU potente), a costa de una cola de latencia no acotada (stalls de
ms) y mucho CPU. El sustrato realmente determinista a paso fino es el **hardware timebase**. Detalle y
referencia en `hallazgo_QUARC_timer_floor_RTS.md`.

---

## 5. Fidelidad unificada — el sustrato no cambia la fidelidad

Como **M1 es idéntico en SIM/QSM/RTB**, las tres dan prácticamente la misma trayectoria; la brecha de
fidelidad es **gemelo vs real (M1 vs M0)** y es aproximadamente constante entre sustratos. Por eso:

- La **RTS** (timing) se estudia con el delta entre modalidades; la **fidelidad** (M1 vs M0) con
  cualquier modalidad simulada contra QHW (M0).
- Causas físicas de la brecha M1↔M0 (a ahondar en Resultados; resumen en la maestra Simulink/QUARC §8):
  frecuencia de α ~8–9 % baja (inercias/acoplamiento), cable-jack no lineal e histerético cerca del tope
  (E2), obstrucción del conector USB-C (artefacto del banco), stiction y ruido en el balance (E3: real
  oscila 4× más en θ que el modelo limpio, por subactuación). M1 es un gemelo válido con **régimen de
  validez documentado**; en lazo cerrado (uso real) reproduce muy bien al real.

---

## 6. Post-proceso unificado

Un solo pipeline para las cuatro modalidades: `cargar_log_rtbox.m` (RTB) y `cargar_log_quarc.m`
(SIM/QSM/QHW) entregan el mismo layout `(señales × N)` con el tiempo en la fila 1. Después:

1. Alinear por correlación cruzada `τ*` (no contar un retardo constante como error de forma).
2. Aplicar `α_real ↔ π−α_modelo`; remuestrear/decimar a la malla de 2 ms.
3. **Fidelidad** (todas contra M0): RMSE θ/α, e_max, `f_n`/`ζ` (E1, decremento log.), índices E3
   (tiempo de swing-up, RMS de regulación, `∫Vm²`, sobreimpulso/asentamiento), NIS.
   `validar_resultados.m` cubre estimación/balance.
4. **RTS**: RTF (SIM ≫1; resto =1), jitter/TET/overruns (QUARC y box), barridos
   (`procesar_barrido_rts.m` para QSM). El **delta entre modalidades = impacto de la RTS**.

Scripts de post-proceso preliminar (en `SIM_QUARC_RTS/postproceso_comparaciones/`): `ver_E1_qhw.m`,
`E1_overlay_preview.m`, `E2_overlay_preview.m`, `procesar_barrido_rts.m`.

---

## 7. Índice de artefactos (ambas ramas)

**Guías y documentación de procedimiento:**
- RT Box: `DOCUMENTACION_MAESTRA_RTS_E1E2E3.md`, `guia_cscripts_plecs.md`,
  `guia_logging_RTS_plecs_quarc_sim.md`, `cscript_excitacion_E2.md`, `cscript_control_ekf_swingup.md`,
  `guia_E3_swingup_hibrido.md`, `guia_E3_TI_C2000_rtbox_HIL.md`, `guia_E3_HIL_TI_migracion.md`,
  `experimentos_E1E2E3_excitacion_y_logging.md`.
- Simulink/QUARC: `SIM_QUARC_RTS/DOCUMENTACION_MAESTRA_SIM_QUARC_E1E2E3.md`,
  `SIM_QUARC_RTS/E1_QSM/hallazgo_QUARC_timer_floor_RTS.md`.
- General: este documento.

**C-Scripts (RT Box):** `PLANTA`, `CONTROL_EKF_SWINGUP`, `EXCITACION`, `RTS_LOG` (verificados en las
guías de C-Scripts).

**Bloques/funciones Simulink (QUARC/SIM):** `furuta_planta_analitica.m` (planta), `ekf_step.m` (EKF),
swing-up de Quanser + LQI; captura RTS con `System Time` y `Computation Time`.

**Scripts Python (RT Box):** `rtbox_watch.py` (TET/overruns por JSON-RPC `queryCounter` + Application
Log + sweep CSV), `rtbox_log.py` (respaldo XML-RPC `/RPC2`).

**Scripts MATLAB:** `cargar_log_rtbox.m`, `cargar_log_quarc.m`, `setup_swingup.m`,
`generar_excitacion_e2.m`, `validar_resultados.m`, `derivar_modelo_furuta_EKF.m`
(genera `furuta_f_aug/_Fc/_meas/_Hjac`), `derivar_furuta_f_param.m`, `run_sim_normal.m`, y los de
`postproceso_comparaciones/`.

**Comandos y targets/IPs:**
- RT Box: interfaz web `http://<nombre-rtbox>/`; API JSON-RPC `http://<ip>:9998/rpc2`, XML-RPC
  `http://<ip>:9998/RPC2`; datos por WebDAV `http://<nombre-rtbox>/dav` o USB.
- QUARC: target `quarc_win64` local; standalone `quarc_run -l -t %QUARC_TARGET% <modelo>.rt-win64`
  (parar con `-q`), URI local `shmem://<modelo>:1`; QUBE por HIL API (`qube_servo3_usb`).

**Carpetas de datos:**
- RT Box: `RTS_SIM_RTBOX1/{E1_data, E2_data, E3_data, E3_data_control_HIL}`.
- Simulink/QUARC: `SIM_QUARC_RTS/{E1E2E3_sim_normal, E1_QSM, E2_QSM, E3_QSM, E1_QHW, E2_QHW, E3_HQW,
  postproceso_comparaciones}`.

**Capturas (para Desarrollo/Resultados):** en cada subcarpeta, `*_SIMULINK.png` (bloques y conexiones
del modelo) y `*_scope_*` (scopes θ/α); en la rama RT Box, capturas de los esquemáticos PLECS, del
modelo construido y de los scopes/dashboard.

---

## 8. Estado global

- [x] RT Box — E1/E2/E3 (fidelidad + RTS + barridos). Documentado.
- [x] SIM — E1/E2/E3 offline (RTF).
- [x] QSM — E1/E2/E3 (fidelidad 2 ms + barridos abierto/cerrado + hallazgo del timer floor).
- [x] QHW — E1/E2/E3 (M0 + RTS 2 ms).
- [ ] Post-proceso comparativo final (fidelidad cruzada vs M0 + tablas RTS de las 4 modalidades).
- [ ] Redacción: Desarrollo (procedimientos + capturas de ambas ramas) y Resultados (tablas + brecha
  de fidelidad + impacto de la RTS).
