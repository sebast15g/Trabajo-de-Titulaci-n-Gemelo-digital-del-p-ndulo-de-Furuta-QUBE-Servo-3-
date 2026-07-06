# Documentación maestra — Validación del gemelo digital (E1/E2/E3) y estudio de RTS

Documento de contexto y procedimiento para el estudio de **fidelidad del gemelo digital del péndulo
de Furuta (QUBE-Servo) y del impacto de la simulación en tiempo real (RTS)**, a través de tres
sustratos de ejecución: **simulación normal (PLECS offline), QUARC (tiempo real + planta real) y
RT Box (PLECS Coder)**. Está redactado para que cualquier persona o IA retome el trabajo sin perder
contexto cuando se completen las corridas de QUARC/real y sim normal y se vaya a redactar la tesis.

Estado a la fecha de este documento: **RT Box completo para E1, E2 y E3** (fidelidad + RTS). Pendiente:
QUARC + planta real y sim normal (con el mismo molde). E3-HIL con controlador en TI C2000: diseñado y
documentado, validación física en hardware queda como trabajo futuro (§11).

---

## 1. Objetivo y diseño del estudio

Se compara **el mismo gemelo digital** ejecutado en tres modalidades, contra la **planta real (M0)**:

- **M0** = QUBE-Servo real (referencia).
- **M1** = modelo analítico (C-Script `PLANTA`, 4 estados).
- **M2** = modelo 3D Simscape (`Model3d_Furuta_Pendulum`), usado para calibrar M1.

Tres modalidades de ejecución, con la **misma entrada, misma condición inicial, misma Ts de
comparación (2 ms)**, para que un solo post-proceso aplique las métricas por igual:

| Modalidad | Sustrato | Naturaleza |
|---|---|---|
| **Simulación normal** | PLECS offline (PC) | libre, RTF ≫ 1 |
| **QUARC** | kernel de tiempo real en el PC + planta REAL | tiempo real, RTF = 1 |
| **RT Box** | PLECS Coder sobre RT Box 1 | tiempo real, RTF = 1 |

Dos familias de métricas:

- **Fidelidad** (gemelo vs real): RMSE de θ y α, error máximo, `f_n`/`ζ` (E1), índices de desempeño (E3),
  consistencia del EKF (NIS). Salen de las **señales del modelo**.
- **RTS** (impacto del tiempo real): TET (cycle time), overruns, jitter, muestras perdidas, RTF. Salen
  del **sustrato de ejecución**, no del modelo.

El contraste central es **libre (sim normal) vs tiempo real estricto (QUARC, RT Box)**: en sim normal solo
tiene sentido el RTF (≫1); en QUARC/RT Box el RTF es 1 por construcción y lo que discrimina es TET vs Ts y
los overruns.

---

## 2. Convenciones comunes (no negociables)

1. **`Ts = 2 ms` (500 Hz)** como malla de muestreo/comparación en las tres modalidades (= la del real).
2. **Paso base de integración**: RT Box `5e-4` s (sub-paso fino para el Coulomb `tanh(·/EPSC)`);
   sim normal `ode4`/`2e-3`. El muestreo de comparación sigue siendo 2 ms.
3. **Convención de ángulos**: θ (brazo) y α (péndulo) en la convención del control, **α = 0 arriba
   (invertido), α = π colgado**. El encoder del real entrega α invertida → para comparar se usa
   `α_real ↔ π − α_modelo` (verificado con logs `pruebaincial`), no un simple bias.
4. **Entrada sin reinterpolar**: la excitación está en la malla de 2 ms; usarla con **ZOH
   (interpolación OFF)** en todas las modalidades.
5. **El tiempo se reconstruye de `seq`**, no del `t_model` del modelo (ver §5). En la RT Box el `To File`
   no antepone el tiempo de forma fiable y el sample time se coacciona (loguea a 1 ms aunque se pida 2 ms);
   por eso el tiempo bueno sale del contador `seq` y del Wall Clock.
6. **Convención de signo del actuador**: en la box/analítico se usa `u = −Ka·[x̂;xi]` SIN el `−1` de
   `For +ve CCW` (ese `−1` es solo para el hardware Quanser real).

---

## 3. Los tres experimentos

### E1 — Caída libre (lazo abierto, sin entrada)
- **Entrada**: `Vm = 0` (Constant 0). **Condición inicial**: `AL0 = 0.05` (arranca casi arriba, cae sola).
- **Valida**: dinámica pasiva — inercias, Coulomb de α (`Tc_alpha`), cable (`kc`, `Dr`).
- **Métricas**: RMSE de α; descriptores físicos `f_n`, `ζ` (decremento logarítmico).

### E2 — Respuesta forzada con `Vm(t)` (lazo abierto)
- **Entrada**: `excitacion_Vm_e2` — 33 s, 16500 muestras a 2 ms, |Vm| ≤ 1.5 V, tres fases: (1) cuadrada
  bipolar de amplitud creciente ±[0.5,1.0,1.5] V ~0.33 Hz, (2) multiseno 0.20/0.35/0.55/0.80 Hz
  normalizado a ±1 V, (3) chirp lineal 0.5→3 Hz, ±0.6 V. Generada por `generar_excitacion_e2.m`.
- **Condición inicial**: `AL0 = π` (péndulo colgando).
- **Valida**: motor (`kt,km,Rm`) y acoplamiento θ–α bajo excitación; el brazo topa en ±135° con la cuadrada.
- **Métricas**: RMSE de θ y α (alineado por `τ*`), error máximo, brecha `Δ_M1`.

### E3 — Lazo cerrado con controlador híbrido (swing-up + balance + EKF)
- **Controlador**: EKF de estado aumentado (5 estados) + **swing-up de energía (Quanser)** + balance LQI,
  con conmutación a 20° (17° en la corrida final). Parámetros del swing-up (de `q_qube2_swingup.slx`):
  `ke = 50 m/s/J`, `Er = 30 mJ = 2·mp·g·l`, `u_max = 6 m/s²`. Ver `setup_swingup.m` y
  `cscript_control_ekf_swingup.md`.
- **Condición inicial**: `AL0 = π` (colgado → el swing-up sube).
- **Lazo cerrado en la box**: `PLANTA.theta_meas/alpha_meas → CONTROL → Vm → [Delay z⁻¹, 2ms] → PLANTA.Vm`.
  El `Delay z⁻¹` rompe el lazo algebraico (PLECS marca el C-Script como feedthrough) y modela el retardo
  de 1 paso cómputo→actuación.
- **Valida**: comportamiento bajo realimentación (uso real del gemelo).
- **Métricas**: tiempo de swing-up, RMS de regulación de α en balance, esfuerzo `∫Vm²`, sobreimpulso/
  asentamiento del escalón de θ, consistencia del EKF (NIS). No se compara trayectoria punto a punto.

---

## 4. Modelo de la planta y del controlador (C-Scripts en la RT Box)

- **`PLANTA`** (C-Script, continuo): dinámica del Furuta `furuta_f_aug`, 4 estados; incluye el **tope
  mecánico θ = ±135°** (penalización unilateral resorte-amortiguador) y la **emulación del encoder**
  (cuantización 2π/2048). Salidas: `theta, alpha, dtheta, dalpha, theta_meas, alpha_meas`. Física en
  `guia_cscripts_plecs.md` §1; parámetros en `parametros_furuta.m`.
- **`CONTROL_EKF_SWINGUP`** (C-Script, discreto a 2 ms): EKF (predicción con Jacobiano numérico +
  corrección + NIS) + híbrido swing-up/balance. Entradas `theta_meas, alpha_meas, theta_ref`; salidas
  `Vm, θ̂, α̂, θ̇̂, α̇̂, d̂, nis, mode, E`. Código completo verificado en `cscript_control_ekf_swingup.md`.
  Notas de sintonía: `COMP_EN 0` (el `d̂` es redundante con el integrador del LQI y mete chatter);
  el signo de `K_ACC2V` salió **negativo** en esta planta (verificación de bombeo).
- **Excitación E2** en la box: como el `From File` **no code-genera**, se usa el C-Script `EXCITACION`
  que genera la señal procedural indexada por `seq` (`cscript_excitacion_E2.md`, verificado a 5e-11).
  `RATIO` distinto por modalidad: sim normal (contador a 2 ms) `RATIO=1`; RT Box (contador a 1 ms) `RATIO=2`.

---

## 5. Logging: fidelidad + tiempo real (dos `To File`)

Por corrida se generan **dos `.mat`** unidos por `seq`:

- **`fid_E*_rtbox.mat`** (fidelidad): señales del modelo. Layouts:
  - E1: `[seq, t_model, theta, alpha, dtheta, dalpha, theta_meas, alpha_meas, Vm]` (9 filas).
  - E2: `[seq, theta, alpha, dtheta, dalpha, theta_meas, alpha_meas, Vm]` (8 filas; `t_model` eliminado).
  - E3: `[seq, theta, alpha, dtheta, dalpha, theta_meas, alpha_meas, Vm, θ̂, α̂, θ̇̂, α̇̂, d̂, nis, mode, E]` (16 filas).
- **`rt_rtbox_E*.mat`** (tiempo real): `[seq, (t_model,) yy, MM, dd, hh, mm, ss, us]` — contador `seq` +
  Wall Clock (`Offset to UTC = −5`, Ecuador). **Es el mismo esquema en E1/E2/E3.**

Puntos críticos aprendidos:
- El `t_model` del modelo salió **mal escalado** (Gain descalibrado y sample time coaccionado). **No usarlo.**
  El tiempo se reconstruye de `seq × Ts_log`, con `Ts_log` medido del Wall Clock (real ≈ 1 ms en la box).
- El contador `seq` se hace con **`Constant 1 → Sum → Delay(z⁻¹)`** (o C-Script con `DiscState`), NO con
  `Ramp`/`Clock` (usan tiempo absoluto → el Coder de la RT Box lo rechaza).
- **La box loguea a ~1 ms** aunque el `To File` pida 2 ms; en post se **decima ×2** a la malla de 2 ms.

---

## 6. Metodología de captura de RTS

**TET y overruns NO son señal del modelo en la RT Box** (verificado v4.0: no hay bloque `CPU Load` como en
los MCU embebidos). Se obtienen así:

- **TET (cycle time)**: pestaña **Application → Simulation** de la interfaz web (`Current` / `Max cycle
  time`), o por API JSON-RPC `rtbox.queryCounter()` (endpoint `http://<ip>:9998/rpc2`, devuelve
  `runningCycleTime`, `maxCycleTime` en **ns**). Automatizado en `rtbox_watch.py`.
- **Overruns**: Application Log (Diagnostics), `rtbox.getApplicationLog()`. Ojo con la errata del firmware
  (`Overrrun`, 3 erres) y la agregación (`N more overruns detected`): el conteo real se suma con
  `count_overruns()` en `rtbox_watch.py` (el conteo ingenuo subestima; p.ej. E2@5µs = 5120, no 9).
- **DEADLINE = CPU step (paso base)**, no los 2 ms de logging: `overrun ⇔ cycle time > CPU step`.

**Barrido de step** (headroom de tiempo real): se corre el mismo modelo variando el *discretization step*
en Coder Options → Scheduling (valores divisores de 2 ms: `1e-3, 5e-4, 2.5e-4, 1e-4, 5e-5, 2.5e-5, 1e-5`,
y menores para forzar overrun). El barrido es **por MODELO, no por experimento**: uno para lazo abierto
(E2, cubre E1) y otro para lazo cerrado (E3). La fidelidad se toma en el **punto de operación (500 µs)**.

Herramientas: `rtbox_watch.py` (sondea `queryCounter`, guarda serie + resumen + Application Log, acumula
fila en el `--sweep-csv`), `rtbox_log.py` (respaldo por XML-RPC `/RPC2`). Detalle en
`guia_cscripts_plecs.md` §4 y `guia_logging_RTS_plecs_quarc_sim.md`.

---

## 7. Resultados RT Box (lo que ya se tiene)

### 7.1 Fidelidad (punto de operación, 500 µs base / 2 ms comparación)
- **E1**: caída física correcta; α de 0.05 a ~π amortiguándose. Datos en `E1_data/fid_E1_rtbox`.
- **E2**: excitación reproducida bit-exacto (Vm decimado ×2 = `excitacion_Vm_e2` a 3e-8), θ topa en ±135°,
  `AL0=π`, 0 muestras perdidas. Datos en `E2_data/fid_E2_rtbox`.
- **E3**: swing-up sube la energía de 0 a `Er=30.2 mJ`; **captura en t≈1.36 s**; balance firme
  (α final en ±0.002 rad = ±0.11°); mode=1 el 91.6 % del tiempo; NIS medio 1.15 (consistente); Vm limpio
  ±2.4 V (tras `COMP_EN=0`); 0 muestras perdidas. Datos en `E3_data/fid_E3_rtbox.mat`.

### 7.2 RTS — barrido de step (TET_max de la box = worst case autoritativo)

**E1/E2 (lazo abierto)** — TET ≈ 6–8 µs (casi constante, independiente del step):

| CPU step | TET_max [µs] | carga [%] | overruns |
|---|---|---|---|
| 1000 µs | 6.99 | 0.70 | 0 |
| 500 µs (oper.) | 6.67 | 1.34 | 0 |
| 100 µs | 6.86 | 6.86 | 0 |
| 50 µs | 6.73 | 13.46 | 0 |
| 10 µs | 7.80 | 78.02 | 0 |
| **5 µs** | **7.54** | **150.84** | **5120** ← umbral cruzado |

Umbral de tiempo real (lazo abierto) ≈ **7.5 µs** (= TET_max). Corre holgado ≥ 10 µs; overrunea en 5 µs.

**E3 (lazo cerrado, con EKF)** — TET ≈ 16–17 µs (más pesado):

| CPU step | TET_max [µs] | carga [%] | overruns |
|---|---|---|---|
| 1000 µs | 16.04 | 1.60 | 0 |
| 500 µs (oper.) | 15.85 | 3.17 | 0 |
| 100 µs | 16.65 | 16.65 | 0 |
| 50 µs | 16.46 | 32.93 | 0 |
| 25 µs | 16.67 | 66.68 | 0 |
| **10 µs** | **17.02** | **170.23** | **10240** ← umbral cruzado |
| 5 µs | 16.82 | 336.48 | 10240 |

Umbral de tiempo real (lazo cerrado) ≈ **16–17 µs**. Corre holgado ≥ 25 µs; overrunea en ≤ 10 µs.
Contraste E2↔E3: el EKF ~triplica el TET y sube el umbral de overrun de 7.5 µs a ~17 µs — evidencia
directa del costo de cómputo del lazo cerrado. En el punto de operación (500 µs) ambos corren con
RTF = 1 y 0 overruns (carga 1.3 % y 3.2 %).

> **Corrección aplicada:** los CSV de barrido ya traen el conteo de overruns real (recontado desde el
> Diagnostics de cada `rt_*.txt`): E2@5µs = **5120**, E3@10µs y E3@5µs = **10240**. Se eliminó la fila
> `E2_50` duplicada mal etiquetada (`cpu_step=500`) y se conservó la buena (`cpu_step=50`).

---

## 8. Inventario de datos — `RTS_SIM_RTBOX1/`

Cuatro subcarpetas. Contenido relevante (se ignoran `.plecs` y `*_codegen`):

- **`E1_data/`**: `fid_E1_rtbox`, `rt_rtbox_E1` (.mat de fidelidad y RT); `rt_E1_500.txt` + `_cycle.csv`
  (TET/overruns punto de operación); `rts_sweep_openloop_E1.csv`; `E1_PLECS.png` (esquemático);
  `scope_E1_theta.pdf`, `scope_E1_alpha.pdf`.
- **`E2_data/`**: `fid_E2_rtbox`, `rt_rtbox_E2`; `rt_E2_{1000,500,100,50,10,5}.txt` + `_cycle.csv`
  (barrido); `rts_sweep_openloop_E2.csv`; `E2_PLECS.png`; `E2_scope_{theta,alpha,Vm}.pdf`;
  `dashboard_E2_{5,10,50,500}.png` (capturas de la web con el cycle time por step).
- **`E3_data/`**: `fid_E3_rtbox.mat`, `rt_rtbox_E3.mat`; `rt_E3_{1000,500,100,50,25,10,5}.txt` +
  `_cycle.csv`; `rts_sweep_closedloop_E3.csv`; `E3_PLECS.png`; `E3_scope_{theta,alpha,Vm}.pdf`.
- **`E3_data_control_HIL/`**: `E3_CONTROL_HIL_PLECS.png` (esquemático dual-target),
  `E3_hil_subsytem_planta.png`, `E3_hil_subsytem_ekf_control.png` (subsistemas por dentro). Sin `.mat`:
  el lazo HIL no llegó a cerrar en hardware (§11).

Nombres: `fid_*` = fidelidad, `rt_*` = tiempo real; `_cycle.csv` = serie temporal del TET;
`rts_sweep_*` = tabla del barrido; el número en `rt_E*_<n>` = CPU step en µs.

---

## 9. Post-proceso y métricas

- **Carga**: `cargar_log_rtbox.m` lee el par `fid`/`rt`, **reconstruye el tiempo de `seq`** (autodetecta
  layout con/sin `t_model`), arma `t_wall` del Wall Clock, verifica muestras perdidas, calcula jitter y
  RTF, y **decima a 2 ms** (`Ts_cmp=2e-3`) para la malla común. Uso:
  `S = cargar_log_rtbox('fid_E3_rtbox.mat','rt_rtbox_E3.mat', 2e-3);`
- **Fidelidad** (con `S.*_2` en malla 2 ms): alinear por correlación cruzada `τ*` antes del RMSE (para no
  contar un retardo constante como error de forma); aplicar `α_real ↔ π − α_modelo`; RMSE θ/α, e_max,
  `f_n`/`ζ` (E1), índices E3, NIS. `validar_resultados.m` cubre la parte de estimación/balance (mapear el
  struct `col` al layout de §5).
- **RTS**: del barrido (§7.2) TET_max/carga/overruns vs step; jitter y RTF del `rt` (jitter ≈ 0 en la box
  por muestreo hardware-locked → apoya RTF=1 determinista).

**Falta el lado de QUARC/real y sim normal para poder comparar** — por eso aún no hay cálculos finales de
fidelidad cruzada ni tablas comparativas. Este documento deja el molde para que entren directo.

---

## 10. Pendiente: QUARC + planta real y sim normal (mismo molde)

Para que la comparación sea homogénea, en QUARC/real y sim normal hay que respetar §2 (Ts 2 ms, misma
excitación ZOH, misma condición inicial, convención α). Y loguear el **mismo vector de fidelidad** por
experimento (§5), con el tiempo como canal explícito para que `cargar_log_quarc.m` lo lea igual.

Métricas RTS por modalidad (mínimo común denominador para que existan en las tres):
- **Sim normal**: solo **RTF** (≫1), por `tic/toc` alrededor de `sim()` o `SimulationMetadata`. Jitter/
  overruns/perdidas = n/a.
- **QUARC**: RTF = 1; TET/overruns por el kernel (reportar **agregado por corrida**, no serie por-muestra,
  para que sea comparable con la RT Box); jitter del reloj de pared del target; muestras perdidas por `seq`.
- **RT Box**: ya hecho (§7).

Cuando estén las tres, el post-proceso único emite: fidelidad (idéntica en las tres) + RTS (RTF en sim;
jitter/TET-agregado/overruns/perdidas en QUARC y RT Box). El delta entre modalidades = impacto de la RTS.

---

## 11. E3-HIL con controlador en TI C2000 — diseñado, trabajo futuro

Configuración avanzada: **controlador (EKF+swing-up+balance) en la LaunchPad F28379D, planta en la RT Box**,
conectados por la **Plexim RT Box LaunchPad Interface** (ruteo fijo, solo pines digitales). Encoding:
Vm por **PWM** (ePWM1/GPIO0 → DI-0 de la box, `duty = 0.5 + Vm/20`), ángulos por **cuadratura**
(Incremental Encoder de la box → eQEP del TI, `ángulo = cuenta·2π/2048`, α con offset `+π`, wrap a (−π,π]).
Mapeo de pines validado contra el manual: θ→eQEP2 GPIO[24,25,26]↔DO[4,24,22]; α→eQEP3 GPIO[104,63,65]↔
DO[27,20,—]; PWM ePWM1↔DI-0. Coder Options dual-target: planta→RT Box @ 5e-4, controlador→TI2837x @ 2e-3.

**Estado**: modelo, mapeo de pines, encoding y guías completos (`guia_E3_TI_C2000_rtbox_HIL.md`,
`guia_E3_HIL_TI_migracion.md`, diagramas `diag_E3_HIL_*.png`). La puesta en marcha del lazo cerrado en
hardware (flasheo del F28379D con "Build and Program", verificación de encoders/PWM físicos) no se
completó — el `Vm` reconstruido quedó en 0, atribuible a que el TI no llegó a ejecutar/rutear la señal.

**Justificación de dejarlo como futuro**: en QUARC y en el real el controlador+EKF corren en el **kernel de
tiempo real del PC** (control centralizado), no en una tarjeta embebida separada. El E3-todo-en-la-RT-Box
replica esa topología (controlador + planta en un solo target de tiempo real) y es la comparación
**consistente** con las otras modalidades. El TI-como-controlador-externo es una arquitectura distinta
(RCP embebido/distribuido) que no corresponde a ninguna de las tres modalidades del estudio; por eso se
reporta como **diseño e integración documentados, con validación física como recomendación/trabajo futuro.**

---

## 12. Índice de archivos generados (guías, scripts, datos)

**Guías (procedimiento):**
- `guia_cscripts_plecs.md` — C-Scripts PLANTA/CONTROL, logging (§4 RTS), armado por experimento.
- `guia_logging_RTS_plecs_quarc_sim.md` — qué guardar (fidelidad vs RT), campos de Coder Options, métricas por modalidad.
- `cscript_excitacion_E2.md` — C-Script de excitación E2 (reemplazo del From File; RATIO por modalidad).
- `cscript_control_ekf_swingup.md` — C-Script completo del controlador híbrido E3 (verificado).
- `guia_E3_swingup_hibrido.md` — E3 en caja: swing-up de Quanser, cableado, Delay z⁻¹, logging.
- `guia_E3_TI_C2000_rtbox_HIL.md` + `guia_E3_HIL_TI_migracion.md` — HIL con TI (futuro).
- `experimentos_E1E2E3_excitacion_y_logging.md` — definición operativa de los tres experimentos.

**Scripts:**
- `rtbox_watch.py` — captura automática de TET/overruns (JSON-RPC queryCounter + Application Log + sweep CSV).
- `rtbox_log.py` — respaldo por XML-RPC (/RPC2).
- `cargar_log_rtbox.m` — carga fid+rt, reconstruye tiempo de seq, decima a 2 ms, jitter/RTF/gaps.
- `setup_swingup.m` — parámetros del swing-up (ke=50, Er=30 mJ, u_max=6, catch, K_bal).
- `generar_excitacion_e2.m` — genera `excitacion_Vm_e2.mat/.csv`.
- `validar_resultados.m`, `cargar_log_quarc.m` — post-proceso de métricas y carga robusta de logs.

**Datos:** `RTS_SIM_RTBOX1/{E1_data, E2_data, E3_data, E3_data_control_HIL}` (§8).

**Diagramas:** `diag_E3_HIL_{1_topologia,2_plant,3_controller}.png`.

---

## 13. Estado / checklist

- [x] E1 RT Box — fidelidad + RTS (punto de operación).
- [x] E2 RT Box — fidelidad + barrido de step (umbral overrun ≈ 7.5 µs).
- [x] E3 RT Box — lazo cerrado (swing-up+balance+EKF) + barrido (umbral ≈ 16–17 µs).
- [x] E3-HIL TI — diseño, mapeo de pines, encoding, guías. (Validación física → futuro.)
- [x] Corregir conteo de overruns en los CSV de barrido y limpiar fila `E2_50` duplicada. **HECHO.**
- [ ] **Sim normal** (PLECS offline) — E1/E2/E3 con mismo molde + RTF.
- [ ] **QUARC + planta real** — E1/E2/E3 con mismo molde + TET/overruns agregados.
- [ ] Post-proceso comparativo final (fidelidad cruzada + RTS) con `cargar_log_rtbox`/`cargar_log_quarc`.
- [ ] Redacción (Resultados/Metodología) con las tablas de §7 y las que salgan de QUARC/sim.
