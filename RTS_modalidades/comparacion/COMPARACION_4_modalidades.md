# Comparación de las 4 modalidades — fidelidad y RTS (E1/E2/E3)

Cierre del estudio: el mismo gemelo M1 ejecutado en cuatro sustratos contra la planta real M0.
Modalidades: **RTB** (RT Box/PLECS), **QSM** (QUARC-modelo), **SIM** (sim normal offline), **QHW**
(QUARC-real = M0). Post-proceso reproducible en `SIM_QUARC_RTS/postproceso_comparaciones/`
(`comparar_4mod.m`, `crosscheck_rtbox.m`, `procesar_barrido_rts.m`). Datos en `comparacion_4mod.mat` y
`barridos_qsm.mat`.

> Convención de figuras: en el swing-up (E3) se homogeneiza el signo de α por modalidad (se invierte si
> el último vaivén antes de la captura viene del lado contrario) para que las curvas calcen. Aplica al
> real o al modelo indistintamente.

## 1. Fidelidad (gemelo vs real M0)

Como RTB, QSM y SIM comparten la MISMA M1, coinciden entre sí; la brecha de fidelidad es M1↔M0 y es
aproximadamente constante entre sustratos (el sustrato no cambia la fidelidad).

**E1 — caída libre (α):**

| modalidad | f_n [Hz] | ζ | ratio f_n vs real |
|---|---|---|---|
| RTB | 1.761 | 0.0525 | 0.97 |
| QSM | 1.724 | 0.0568 | 0.95 |
| SIM | 1.724 | 0.0568 | 0.95 |
| **QHW (M0)** | **1.818** | **0.0390** | — |

RTB/QSM/SIM se agrupan (~1.72–1.76 Hz); el real va ~5 % más rápido (inercias/acoplamiento). RTB queda
levemente por encima de QSM por el integrador (Euler 0.5 ms vs RK4). Figura: `comp_E1_alpha_4mod.png`.

**E2 — respuesta forzada (rangos, misma excitación |Vm|≤1.5 V):**

| modalidad | θ [min,max]° | α [min,max]° |
|---|---|---|
| RTB | [−136.1, 136.0] | [113.4, 237.1] |
| QSM | [−135.8, 135.8] | [123.6, 225.1] |
| SIM | [−135.8, 135.8] | [123.6, 225.1] |
| **QHW (M0)** | [−136.1, 136.2] | [124.1, 234.1] |

θ topa en ±135° en las cuatro; α ~±60° del colgado. RTB oscila un poco más en la cuadrada (0–10 s) por
sensibilidad del tope rígido al integrador, pero acotado al mismo régimen. El seguimiento del brazo (θ) y
de las fases multiseno/chirp es excelente entre las cuatro. Figura: `comp_E2_alpha_theta_4mod.png`.

**E3 — lazo cerrado (swing-up + balance + EKF):**

| modalidad | t_catch [s] | balance % | α̂_std° | θ_std° | NIS |
|---|---|---|---|---|---|
| RTB | 2.72 | 93.8 | 0.51 | 0.66 | 1.10 |
| QSM | 3.13 | 79.1 | 1.11 | 3.10 | 1.50 |
| SIM | 3.13 | 79.1 | 1.11 | 3.10 | 1.50 |
| **QHW (M0)** | 2.65 | 82.3 | 1.12 | 3.14 | 1.52 |

**QSM ≈ QHW casi exacto** (α̂_std 1.11 vs 1.12°, θ_std 3.10 vs 3.14°, NIS 1.50 vs 1.52): el modelo
reproduce el balance real. SIM = QSM (mismo modelo, offline). RTB balancea algo más apretado (α̂_std
0.51°) por sustrato bare-metal. El swing-up es sensible al arranque → t_catch varía (2.65–3.13 s), pero
las cuatro capturan y balancean. Figura: `comp_E3_alpha_4mod.png`. NIS ~1–2 en las cuatro → EKF
consistente.

## 2. RTS (impacto del tiempo real)

El contraste es **libre (SIM) vs tiempo real estricto (QSM/QHW/RTB)** y, dentro del tiempo real, **cómo
topa cada sustrato**.

| modalidad | RTF | TET (punto op., 2 ms) | umbral de overrun | jitter @2 ms | naturaleza |
|---|---|---|---|---|---|
| **SIM** | ≫1 (E1 12.3, E2 35.4, E3 15.4) | n/a | n/a | n/a | libre, sin tiempo real |
| **RTB** | =1 (corrió a ~2× pared, ver nota) | 6.7 µs abierto / 16.8 µs cerrado | ~5 µs abierto / ~10 µs cerrado | sub-µs (hardware-locked) | *compute-bound*, bare-metal |
| **QSM** | =1 hasta ~5 µs (colapsa 1 µs) | ~7–8 µs med (máx 200–415 µs) | ~5 µs (con fast timer) | ~320 µs (software Windows) | *timer/jitter-bound* |
| **QHW (M0)** | =1 | ~8–10 µs med | — (planta física) | ~36–70 µs (timebase HIL) | planta real en tiempo real |

**Barrido de paso (QSM, fast timer):** RTF=1 desde 2 ms hasta 5 µs; colapso en 1 µs (abierto RTF 0.685,
56.7 % overruns; cerrado RTF 0.319, 100 %). TET_max crece de ~200 µs a 36 ms al forzar la tasa (stalls de
Windows). Sin fast timer, QUARC (win64) tiene **piso duro en 1 ms** (rechaza pasos menores: "unable to set
base rate"); el fast timer libera tasas sub-ms a costa de mucho CPU (recomendado en multinúcleo) —
experimental. Tablas en `barridos_qsm.mat`.

**Barrido de paso (RTB):** abierto TET_max ~6.7–7.8 µs, umbral overrun ~5 µs (5120 overruns @5 µs, carga
150 %); cerrado TET_max ~16–17 µs (el EKF ~triplica el TET), umbral ~10 µs (10240 overruns). Fuente
`rts_sweep_*.csv` + Application Log (`rt_E*_<paso>.txt`).

**Notas de RTS:**
- **RTB RTF≈2 (hallazgo aparte):** el modelo avanza 2 ms/muestra y el wall-clock ~1 ms → la box ejecutó a
  2× la velocidad de pared (no sostuvo 1:1). No afecta la fidelidad (dinámica en tiempo-modelo).
- **Contraste de sustratos:** RTB gana en **determinismo** (jitter sub-µs acotado por hardware); QUARC+fast
  timer gana en **throughput mediano** (TET ~µs, CPU potente) a costa de una cola de latencia no acotada
  (stalls de ms) y mucho CPU. El sustrato determinista a paso fino es el **hardware timebase** (RT Box, o
  la tarjeta HIL del QUBE en QHW). Corrección de la tesis: QUARC (win64) usa **timer de software** de
  Windows, no de hardware.

## 3. Lectura para la tesis

- **Fidelidad:** M1 es un gemelo válido, con brecha M1↔M0 de ~5 % en frecuencia (E1), ~±10° cerca del tope
  (E2, cable-jack/conector) y balance real ligeramente más disperso (E3, stiction/ruido). La brecha es del
  MODELO, no del sustrato: RTB≈QSM≈SIM. El lazo cerrado (E3) es la validación más relevante y QSM≈QHW.
- **RTS:** el delta entre modalidades mide el impacto del tiempo real. SIM es la cota libre; RTB y QHW son
  deterministas por hardware; QSM depende del timer de software (piso 1 ms sin fast timer, jitter alto).
- **Pendiente de redacción:** RMSE θ/α alineado por τ* (E2, misma excitación) para cuantificar la brecha
  punto-a-punto; y la sección de Desarrollo "Implementación de las modalidades" (4 modalidades, E1/E2/E3,
  montajes con las capturas `*_SIMULINK.png`/`*_PLECS.png` y scopes `*_scope_*`).
