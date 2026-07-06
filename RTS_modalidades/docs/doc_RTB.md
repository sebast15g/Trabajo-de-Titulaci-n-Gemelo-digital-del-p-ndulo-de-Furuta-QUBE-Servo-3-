# Modalidad RTB — RT Box (PLECS Coder) · recopilación completa

Modalidad de **simulación en tiempo real del gemelo M1 sobre la Plexim RT Box 1** (bare-metal, PLECS
Coder). Es, junto con QSM, la modalidad más extensa del estudio por el trabajo de implementación,
consideraciones y hallazgos que hubo. Este documento recopila todo: montaje, C-Scripts, solver, logging,
captura de RTS, hallazgos y resultados. Datos en `RTS_SIM_RTBOX1/`; scripts y figuras en
`TESIS_FINALES/RTS_modalidades/{RTB,scripts,comparacion}`.

## 1. Qué es y cómo se montó

El modelo M1 (péndulo de Furuta, 4 estados) corre como **C-Scripts** dentro de un esquemático PLECS que
se compila con el PLECS Coder y se despliega en la RT Box 1 (procesador embebido, tiempo real duro).
Esquemáticos en `E*_PLECS.png`. Tres experimentos (E1 caída libre, E2 respuesta forzada, E3 lazo cerrado).

**C-Scripts:**
- **`PLANTA`** (continuo, 4 estados): dinámica Lagrangiana 2-DOF de Furuta (`furuta_f_aug`), tope mecánico
  θ=±135° (resorte-amortiguador unilateral `K_STOP=50`, `B_STOP=0.037`) y emulación del encoder
  (cuantización 2π/2048, α con `wrapd`). Salidas `theta, alpha, dtheta, dalpha, theta_meas, alpha_meas`.
  Parámetros = `parametros_furuta.m` (g=9.7807, mp=0.024, lp=0.064325, Jp_cm=3.3101645e-5, …).
- **`CONTROL_EKF_SWINGUP`** (discreto 2 ms): EKF de estado aumentado (5 estados, Jacobiano numérico +
  corrección + NIS) + swing-up de energía de Quanser (`ke=50`, `Er=2·mp·g·lp≈30.2 mJ`, `u_max=6`) +
  balance LQI del proyecto (`Ka`), conmutación a 17°. Ajustes verificados: `K_ACC2V` **negativo** (si no,
  el swing-up amortigua en vez de bombear) y `COMP_EN=0` (el feedforward −d̂ es redundante con el
  integrador del LQI y mete chatter).
- **`EXCITACION`** (E2): genera la señal procedural indexada por `seq` (el `From File` no code-genera).
  **`RATIO`** convierte `seq` a índice de muestra a 2 ms; ver hallazgo §4.
- **Contador `seq`**: `Constant 1 → Sum → Delay(z⁻¹)` (NO `Ramp`/`Clock`, que usan tiempo absoluto y el
  Coder los rechaza).

## 2. Solver (clave de por qué difiere de QUARC)

La RT Box integra los estados continuos del C-Script con **Euler explícito a paso base 0.5 ms**: el código
generado hace `X_Planta[i] += 0.0005 * deriv[i]` cada paso base (confirmado en `tesis_E*_RTBOX.c`). **El
target de la RT Box no ofrece `ode4`** para los estados continuos del C-Script; es Euler de paso fijo.
Esto contrasta con QSM/SIM, donde la planta (`furuta_planta_analitica`) integra con **RK4 (`nsub=4`)** =
ode4. Misma física, mismas ecuaciones, mismos parámetros → **distinto integrador numérico**:
- En E1 (caída libre suave) la diferencia es pequeña: RTB `f_n=1.76 Hz` vs QSM `1.72 Hz`.
- En E2, bajo los **golpes repetidos al tope rígido** de la cuadrada, Euler es más sensible que RK4; se
  verificó (reproduciendo el mismo Vm con Euler y con RK4) que la diferencia es del integrador, no de los
  parámetros. Acotada al mismo régimen (α ∈ [113,237]°), coincide con QSM/real.

`subTaskPeriod[0]=4` (4 pasos base de 0.5 ms) → la subtarea de logging/control corre a **2 ms de modelo**.

## 3. Logging

Dos `To File` por corrida, unidos por `seq`:
- **`fid_E*_rtbox.mat`** (fidelidad): E1/E2 8 filas `[seq,θ,α,θ̇,α̇,θm,αm,Vm]`; E3 16 filas
  `[seq,θ,α,θ̇,α̇,θm,αm,Vm,θ̂,α̂,θ̇̂,α̇̂,d̂,nis,mode,E]`.
- **`rt_rtbox_E*.mat`** (tiempo real): `[seq,yy,MM,dd,hh,mm,ss,us]` (Wall Clock, offset UTC −5).
- **Tiempo-modelo = `seq × 2e-3`** (una muestra por subtarea). No se usa el wall-clock para el eje.

## 4. Hallazgos (todos verificados)

1. **Eje temporal (el "2× off" que NO existía).** El post-proceso reconstruía el tiempo desde el
   wall-clock (~1 ms/muestra) cuando el log es a 2 ms de modelo → todas las métricas con tiempo salían al
   doble (E1 3.52 Hz, E3 t_catch 1.36 s). Corregido a `seq×2 ms`: E1 1.76 Hz, E3 2.72 s. La física
   siempre fue correcta. Detalle en `memo_correccion_2ms_RTBOX.md`.
2. **RTF ≈ 2 (hallazgo de RTS aparte).** El modelo avanza 2 ms/muestra y el wall-clock ~1 ms → RTF =
   modelo/pared = **2.00 exacto** en E1/E2/E3. La box **no sostuvo tiempo real 1:1** (ejecutó a 2× la
   velocidad de pared). No afecta la fidelidad (dinámica en tiempo-modelo). Este "1 ms de pared" era lo
   que se confundía con "la box loguea a 1 ms".
3. **E2: `RATIO` de la excitación.** Con `seq` a 2 ms, el índice de muestra es `m=(seq−1)/RATIO`. Con
   `RATIO=2` (creyendo que `seq` iba a 1 ms) la excitación se **estira 2×** (arranca en 2.0 s, chirp a la
   mitad de frecuencia). La corrida válida usa **`RATIO=1`** (arranca en 1.0 s, α ∈ [113,237]°).
4. **Trampa de duplicados.** Una corrida intermedia de E2 quedó con la PLANTA de inercia vieja (α se
   dispara a [3,317]°, respondiendo ~30× de más al Vm). El discriminador es el **contenido** (onset 1.0 s
   **y** α ∈ ~[113,237]°), no el nombre/fecha. Se verifica reproduciendo la dinámica con el Vm grabado.
5. **Determinismo.** El jitter de la box es sub-µs (timer de hardware, hardware-locked); es el sustrato
   más determinista del estudio a paso fino.

## 5. Captura de RTS (TET y overruns)

En la RT Box **el TET no es señal del modelo** (no hay bloque de TET en el target). Se obtiene por la
interfaz web / API JSON-RPC de la box:
- **`rtbox_watch.py`**: sondea `rtbox.queryCounter()` (endpoint `http://<ip>:9998/rpc2`, devuelve
  `runningCycleTime`, `maxCycleTime` en ns), lee el Application Log (`getApplicationLog()`), y acumula el
  barrido en `rts_sweep_*.csv`. Cuenta overruns reales con `count_overruns()` (la errata del firmware es
  `Overrrun`, y agrega "N more overruns detected"; el conteo ingenuo subestima).
- **`rtbox_log.py`**: respaldo por XML-RPC (`/RPC2`).
- **Regla:** `overrun ⇔ cycle time > CPU step` (el paso base, no los 2 ms de logging).

**Barrido de paso base** (headroom de tiempo real), por MODELO (abierto E2 cubre E1; cerrado E3):

| lazo | TET_max | umbral de overrun | overruns @umbral |
|---|---|---|---|
| abierto (E1/E2) | 6.7–7.8 µs | ~5 µs | 5120 |
| cerrado (E3) | 16–17 µs (el EKF ~triplica el TET) | ~10 µs | 10240 |

Fuentes: `rts_sweep_openloop_E2.csv`, `rts_sweep_closedloop_E3.csv`, `rt_E*_<paso>.txt` (Application Log)
y `rt_E*_<paso>_cycle.csv` (serie del TET). Figuras `rtbox_barrido_{openloop,closedloop}.png`.

## 6. Resultados

- **E1:** f_n=1.761 Hz, ζ=0.0525 (≈ QSM 1.72; real 1.82).
- **E2:** θ topa ±136°, α ∈ [113.4, 237.1]°, Vm arranca en 1.0 s.
- **E3:** captura t=2.72 s, balance 91.6–93.8% (según corrida), α̂_std 0.51–0.60°, θ_std 0.66–0.69°,
  NIS 1.10, ∫Vm²=9.9, E_max 30.2 mJ.

## 7. Scripts y archivos

`cargar_log_rtbox.m` (carga fid+rt, tiempo seq×2 ms, RTF/jitter del wall-clock), `procesar_rtbox.m`
(métricas + figuras E1/E2/E3 + barridos), `rtbox_watch.py`, `rtbox_log.py`. C-Scripts documentados en
`cscript_PLANTA_corregido.md`, `cscript_control_ekf_swingup.md`, `cscript_excitacion_E2.md`,
`guia_cscripts_plecs.md`. Trabajo futuro (no es una de las 4 modalidades): E3-HIL con controlador en
TI C2000 (`guia_E3_TI_C2000_rtbox_HIL.md`).
