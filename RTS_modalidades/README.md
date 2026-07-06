# RTS_modalidades — paquete de la etapa de modalidades (fidelidad + RTS)

Consolida el estudio de las **4 modalidades** del gemelo M1 del péndulo de Furuta contra la planta real
M0, en los 3 experimentos (E1 caída libre, E2 respuesta forzada, E3 lazo cerrado swing-up+balance+EKF).

## Estructura
- **`RTB/`** — RT Box (PLECS): figuras a 2 ms, overlays, barridos, métricas, esquemáticos PLECS, scopes PDF, sweeps CSV.
- **`QSM/`** — QUARC-modelo: esquemáticos, scopes, figuras del barrido (fast timer).
- **`QHW/`** — QUARC-real (M0): esquemáticos, scopes.
- **`SIM/`** — sim normal: métricas RTF.
- **`comparacion/`** — 13 figuras comparativas + `comparacion_4mod.mat`, `barridos_qsm.mat`, memo comparativo.
- **`scripts/`** — todos los `.m` del post-proceso.
- **`docs/`** — documentos por modalidad + maestras + hallazgos + memos.

## Documentos por modalidad (docs/)
- `doc_RTB.md` y `doc_QSM.md` — **extensos** (implementación, solver, hallazgos, RTS, resultados).
- `doc_QHW.md` y `doc_SIM.md` — breves (corridas directas, sin ajustes de por medio).
- `COMPARACION_4_modalidades.md` — tablas de fidelidad y RTS + lectura para la tesis.
- Transversal: `hallazgo_QUARC_timer_floor_RTS.md`, `memo_correccion_2ms_RTBOX.md`,
  `GUIA_ubicacion_resultados_rtbox.md`, maestras RTS y SIM/QUARC.

## Figuras comparativas (comparacion/)
- 4-way (las 4 modalidades): `comp_E1_alpha_4mod`, `comp_E2_alpha_theta_4mod`,
  `comp_E3_{alpha,theta,Vm,alphadot,NIS,E}_4mod`.
- Cada modalidad a solas vs el real (3 subplots): `comp_E1_alpha_vsreal`,
  `comp_E2_{alpha,theta}_vsreal`, `comp_E3_{alpha,theta}_vsreal`.
- Convención: en E3 la α es continua (sin envolver) y referenciada a balance=0; se refleja SOLO la
  modalidad cuyo swing-up viene del lado contrario al real (resultó ser RTB).

## Resultado en una línea
El sustrato **no** cambia la fidelidad: RTB≈QSM≈SIM (misma M1) y todas aproximan al real M0 dentro de la
brecha M1↔M0 (~5% en E1; QSM≈QHW casi exacto en E3). El delta entre modalidades mide la **RTS**: SIM es la
cota libre (RTF 12–35×); RTB es *compute-bound* y determinista (jitter sub-µs, pero corrió a RTF≈2); QSM es
*timer/jitter-bound* (piso 1 ms sin fast timer, jitter ~320 µs); QHW usa el timebase HIL (jitter ~36–70 µs).
La diferencia numérica entre RTB y QSM/SIM con el mismo modelo es el **integrador** (Euler 0.5 ms en la box
vs RK4/ode4 en QUARC).
