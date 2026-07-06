# Modalidad QSM — QUARC-modelo (planta analítica M1 en el kernel de tiempo real) · recopilación completa

Modalidad de **simulación en tiempo real del gemelo M1 en el kernel QUARC** (target `quarc_win64`, sobre
Windows), sin hardware en el lazo. Junto con RTB, la más extensa por el trabajo de RTS y los hallazgos del
timer. Recopila montaje, solver, hallazgos del piso de 1 ms y el fast timer, barrido y resultados. Datos
en `SIM_QUARC_RTS/{E1_QSM,E2_QSM,E3_QSM}`; scripts/figuras en `TESIS_FINALES/RTS_modalidades/`.

## 1. Qué es y cómo se montó

El mismo M1 corre como bloques de Simulink compilados al kernel de tiempo real de QUARC en el PC. La
planta es **`furuta_planta_analitica.m`** (MATLAB Function): transcripción literal del C-Script `PLANTA`
de la RT Box (dinámica 2-DOF + tope θ=±135° + encoder), **verificada contra `furuta_f_aug` a 1.14e-13**.
El EKF es `ekf_step.m` (un paso del EKF aumentado, `nis` como reducción escalar para codegen). Swing-up de
Quanser + balance LQI. Esquemáticos en `E*_QSM_SIMULINK.png`; scopes de ángulos en `*_scope_*.png`.
Ruptura del lazo en E3 con `Unit Delay z⁻¹` (2 ms) para romper el lazo algebraico de la MATLAB Function
(feedthrough). Signo del actuador SIN el `−1` de `For +ve CCW` (ese `−1` es solo del hardware real, QHW).

## 2. Solver (clave de por qué difiere de la RT Box)

QSM/SIM integran M1 con **RK4 (`nsub=4` → subpaso 0.5 ms) = ode4**, dentro de la MATLAB Function; el
solver de Simulink/QUARC es **fixed-step ode4 (o discreto) a 2 ms**. La RT Box, en cambio, integra las
mismas ecuaciones con **Euler explícito** (su target no ofrece ode4 para el C-Script continuo). Misma
física y parámetros, distinto integrador → RK4 (QSM) es más preciso que Euler (RTB); la diferencia es
pequeña en E1 (1.72 vs 1.76 Hz) y visible bajo golpes al tope en E2. Es la razón numérica de que dos
modalidades con "el mismo modelo" no den bit-idénticas.

## 3. Hallazgo principal — piso de tasa base de 1 ms (win64) y fast system timer

Documentado en `hallazgo_QUARC_timer_floor_RTS.md`. Resumen:
- Por defecto, `quarc_win64` usa el **timer de software de Windows con resolución de 1 ms**. Solo admite
  pasos base múltiplos de 1 ms. **Por debajo de 1 ms el kernel rechaza el base rate** ("Unable to set base
  rate. A value is outside the valid range" / "Actual period will be 0"), tanto en Monitor & Tune como en
  standalone (descarta que sea límite de External Mode). Es un **límite entre QUARC y Windows**, no del
  cómputo (el TET sobra: ~7–8 µs). Quanser mismo llama "crude and inaccurate" a la tasa de 1 kHz de
  Windows.
- **Corrección importante de la tesis:** QUARC (win64) usa **timer de software**, NO "timer de hardware".
- **Checklist para ir más allá de 1 ms (experimental):** activar **"Allow use of fast system timer"**
  (Configuration Parameters → Code Generation → QUARC). Esto libera pasos sub-ms usando más recursos de los
  **núcleos de CPU** (muy intensivo en CPU; recomendado en sistemas con >2 núcleos; **siempre deshabilitado
  en 1 CPU**). Sin él, la corrida a <1 ms **da error de ejecución** (el piso descrito). Con él activado, el
  kernel acepta hasta 1 µs. Correr en **standalone** (`quarc_run` o doble-clic al `.rt-win64`), NO en
  Monitor & Tune (External Mode topa a 1 kHz por `quarc_comm`).
- **Caveat de logging a tasas rápidas:** el `seq` de 16 bits se desborda (a 1 µs, 15 M muestras) y corrompe
  el `t_model` reconstruido; usar el `t` del target y el `t_wall`, o loguear `seq` a 32 bits.

## 4. Captura de RTS y barrido de paso

Bloques QUARC: **`Computation Time`** (TET, opción *Output computation time of task*), **`System Time`**
(wall clock), **`Counter Free-Running`** (`seq`), dos `To File` (fid y rt=`[t,seq,t_model,t_wall,TET]`).
Post-proceso del barrido con **`procesar_barrido_rts.m`** (RTF, TET min/med/máx, overruns=#TET>paso, paso
real). El barrido es exclusivo de QSM (planta simulada): en QHW la planta es física y siempre corre en
tiempo real; en SIM no hay tiempo real.

**Barrido con fast timer (E1 abierto / E3 cerrado):**

| paso base | RTF abierto | RTF cerrado | TET med | TET máx | overruns |
|---|---|---|---|---|---|
| 2 ms → 500 µs | 1.000 | 1.000 | 7–10 µs | 200–600 µs | 0 |
| 100 µs | 1.000 | 1.000 | 4–5 µs | ~500 µs | 0.1 % |
| 10 µs | 1.000 | 1.000 | 2–3 µs | 0.8–2.6 ms | 1–2 % |
| 5 µs | 1.000 | 1.000 | 1.6–3 µs | 1.6–3.1 ms | 5–7 % |
| **1 µs** | **0.685** | **0.319** | ~1–2 µs | **13–36 ms** | 57–100 % |

Lectura: QSM **mantiene RTF=1 hasta ~5 µs** (con fast timer) y colapsa en 1 µs; alcanza esencialmente el
mismo paso fino que la RT Box (~5–10 µs), pero el **peor caso** (TET_max) crece a decenas de ms por los
stalls de scheduling de Windows, frente al jitter sub-µs de la box. Es *timer/jitter-bound* (con fast
timer) vs *compute-bound* (RT Box). Tablas en `barridos_qsm.mat`. Figuras
`E1_qsm_barrido_fasttimer.png`, `E3_qsm_barrido_abierto_vs_cerrado.png`.

**Jitter en el punto de operación (2 ms):** ~320 µs (solo timer de software de Windows, sin hardware
timebase) — mucho mayor que QHW (~36–70 µs, timebase HIL) y que la box (sub-µs). Para el punto de
operación conviene **desactivar el fast timer** (baja el TET_max y da el jitter representativo del sustrato
estándar).

## 5. Resultados

- **E1:** f_n=1.724 Hz, ζ=0.0568.
- **E2:** θ ±136°, α ∈ [123.6, 225.1]°.
- **E3:** captura 3.13 s, balance 79.1%, α̂_std 1.11°, θ_std 3.10°, NIS 1.50 → **≈ QHW casi exacto** (el
  modelo reproduce el balance real).

## 6. Scripts y archivos

`cargar_log_quarc.m` (carga robusta a MAT v4 mal finalizado), `procesar_barrido_rts.m`, `run_sim_normal.m`
(comparte con SIM), `furuta_planta_analitica.m`, `ekf_step.m`, `setup_swingup.m`. Doc del hallazgo:
`hallazgo_QUARC_timer_floor_RTS.md`. Maestra: `DOCUMENTACION_MAESTRA_SIM_QUARC_E1E2E3.md`.
