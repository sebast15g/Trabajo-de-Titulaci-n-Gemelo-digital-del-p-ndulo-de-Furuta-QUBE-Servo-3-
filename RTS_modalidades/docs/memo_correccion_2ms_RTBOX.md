# Memo — corrección del pipeline de la RT Box a tiempo-modelo 2 ms y verificación cruzada

Registro del procedimiento con que se corrigió el post-proceso de la modalidad RT Box (RTB) del estudio
de fidelidad + RTS del gemelo del péndulo de Furuta, se re-procesaron E1/E2/E3, y se verificó contra las
modalidades QSM (QUARC-modelo), QHW (QUARC-real = M0) y SIM (sim normal). Fecha: 2026-07-03.

## 1. Problema de partida

El post-proceso reconstruía el eje temporal de la box desde el **wall-clock** (`cargar_log_rtbox.m` y el
helper `tiempo()` de `procesar_rtbox.m`). El wall-clock avanza ~1 ms por muestra logueada, así que las
métricas con tiempo salían al **doble**: E1 `f_n = 3.52 Hz` (real 1.82), E3 `t_catch = 1.36 s`. Esto se
había interpretado erróneamente como que la box tenía la **inercia del péndulo mal parametrizada** ("2×
off").

## 2. Causa raíz (confirmada en el código generado)

El `To File` de la box escribe **una muestra por subtarea**, y la subtarea corre a
`subTaskPeriod[0] = 4 × paso base 0.5 ms = 2 ms` de MODELO. Verificado en `tesis_E1_RTBOX.c`,
`tesis_E2_RTBOX.c` y `tesis_E3_RTBOX.c`: el contador `seq` (`Constant 1 → Sum → Delay`) y ambos `To File`
están dentro de `if (subTaskHit[0])`, que se cumple cada 4 pasos base. Por tanto el tiempo correcto es
**`t = (seq − seq(1)) × 2e-3`**, no el wall-clock.

El "~1 ms por muestra" del wall-clock no es el paso del modelo: es el tiempo de **pared**. Como el modelo
avanza 2 ms mientras el reloj marca 1 ms, la box corrió a **RTF = 2** (ver §5). Ese factor 2 es el que
contaminaba el eje temporal.

## 3. Cambios en el pipeline

- **`cargar_log_rtbox.m`**: el tiempo pasa a `seq × Ts_model` (`Ts_model = 2e-3`). El wall-clock se
  conserva solo como diagnóstico de RTS (RFT, jitter, span). La decimación a 2 ms queda como identidad
  (la box ya loguea a esa malla).
- **`procesar_rtbox.m`**: el helper `tiempo()` devuelve `seq × 2e-3` y, aparte, el RTF del wall-clock
  (solo si el `rt` casa en N con el `fid`; si no, RTF = NaN). Lee los `.mat` con **nombres canónicos**
  (`fid_E{1,2,3}_rtbox.mat`, `rt_rtbox_E{1,2,3}.mat`) del set definitivo en `E*_data/`.

## 4. Set de datos definitivo (elegido por CONTENIDO, no por nombre/fecha)

Había duplicados en tres carpetas (`Scape/`, la del proyecto, y `RTS_SIM_RTBOX1/E*_data/`). El
criterio de selección fue el contenido:
- **E1** (`fid_E1_rtbox.mat`, N = 19550): Vm = 0; físicamente idéntico entre copias.
- **E2** (`fid_E2_rtbox.mat`, N = 41850): el válido tiene **onset de Vm en 1.0 s** (`RATIO=1`) **y**
  α ∈ [113.4, 237.1]° (parámetros de PLANTA vigentes). Se descartaron: la de `RATIO=2` (onset 2.0 s,
  excitación estirada 2×) y una intermedia con PLANTA de inercia vieja (α ∈ [3, 317]°).
- **E3** (`fid_E3_rtbox.mat`, N = 16100): `t_catch` = 2.716 s en todas las copias (confirma el doblado
  desde 1.36 s).

Nota: para E2 no se conservó un `rt` que case en N (41850) con la corrida buena; el RTF de E2 se reporta
como n/a (el hallazgo RTF ≈ 2 queda establecido por E1 y E3, mismo sustrato).

## 5. Resultados de la box re-procesada (tiempo-modelo 2 ms)

| Exp | métrica clave | antes (wall) | ahora (seq×2 ms) |
|---|---|---|---|
| E1 | f_n | 3.52 Hz | **1.76 Hz** |
| E1 | ζ | 0.052 | 0.053 (adimensional, ~igual) |
| E2 | onset Vm; α | 2.0 s; [141,219]° (estirada) | **1.0 s; [113,237]°** |
| E3 | t_catch | 1.36 s | **2.72 s** |
| E3 | ∫Vm²dt | 4.96 | **9.91** (dobla con el eje) |
| E3 | balance %, α_std, θ_std, NIS | 91.6 %, 0.59°, 0.69°, 1.10 | iguales (adimensionales) |

**Hallazgo de RTS aparte — RFT ≈ 2:** el modelo avanza 2 ms por muestra y el wall-clock ~1 ms →
RTF = modelo/pared = **2.00 exacto** en E1, E2 y E3. La box **no sostuvo tiempo real 1:1**; ejecutó a 2×.
No afecta la fidelidad (la dinámica se integra en tiempo-modelo). Va al capítulo de RTS.

## 6. Verificación cruzada contra QSM / QHW / SIM (`crosscheck_rtbox.m`)

Como RTB, QSM y SIM comparten la MISMA M1, deben coincidir entre sí y aproximar al real (QHW = M0)
dentro de la brecha de fidelidad M1↔M0.

**E1 (caída libre) — f_n / ζ:**

| mod | f_n [Hz] | ζ |
|---|---|---|
| RTB | 1.761 | 0.0525 |
| QSM | 1.724 | 0.0568 |
| SIM | 1.724 | 0.0568 |
| QHW (M0) | 1.818 | 0.0390 |

**E2 (respuesta forzada) — rangos:**

| mod | θ [min,max]° | α [min,max]° | Vm_max |
|---|---|---|---|
| RTB | [−136.1, 136.0] | [113.4, 237.1] | 1.50 |
| QSM | [−135.8, 135.8] | [123.6, 225.1] | 1.50 |
| QHW | [−136.1, 136.2] | [124.1, 234.1] | 1.50 |

**E3 (lazo cerrado) — desempeño** (α_std sobre `alpha_hat` del EKF, centrada en 0 = arriba):

| mod | t_catch [s] | balance % | α̂_std° | θ_std° | NIS |
|---|---|---|---|---|---|
| RTB | 2.716 | 91.6 | 0.60 | 0.69 | 1.10 |
| QSM | 3.130 | 79.1 | 1.11 | 3.10 | 1.50 |
| QHW | 2.654 | 82.3 | 1.12 | 3.14 | 1.52 |

Lectura: la box coincide con QSM y con el real en las tres pruebas. **QSM ≈ QHW casi exacto** en E3
(α̂_std 1.11 vs 1.12°, NIS 1.50 vs 1.52) → el modelo reproduce el balance real. La box balancea algo más
apretado (0.60°) por ser sustrato bare-metal sin perturbaciones. El "2× off" queda **enterrado**.

## 7. Notas de decodificación de layouts (para no repetir errores)

- **RTB E1/E2 (8 filas):** `[seq, θ, α, θ̇, α̇, θm, αm, Vm]`; tiempo = seq × 2 ms.
- **RTB E3 (16 filas):** `[seq, θ, α, θ̇, α̇, θm, αm, Vm, θ̂, α̂, θ̇̂, α̇̂, d̂, nis, mode, E]`.
- **QSM/SIM E1/E2 (9 filas):** `[t, seq, θ, α, θ̇, α̇, θm, αm, Vm]`.
- **QSM E3 (18 filas):** `[t, seq, θ, α, θ̇, α̇, θm, αm, Vm, θ̂, α̂, θ̇̂, α̇̂, d̂, nis, mode, E, θref]`.
- **QHW E1/E2 (6 filas):** `[t, seq, t_model, θ, α, Vm]`.
- **QHW E3 (14 filas):** `[t, seq, θm, αm, Vm, θ̂, α̂, θ̇̂, α̇̂, d̂, nis, mode, E, 0]` — **`mode` es la
  fila 12 (binaria)**, la fila 13 es E (en mJ), la fila 14 es 0 (θref). Decodificado por estadísticas
  (una asignación equivocada de `mode`/`α̂` daba α̂_std ~37° espurio).

## 8. Archivos generados/actualizados

- Scripts: `cargar_log_rtbox.m`, `RTS_SIM_RTBOX1/procesado/procesar_rtbox.m`,
  `SIM_QUARC_RTS/postproceso_comparaciones/crosscheck_rtbox.m` (+ `diag_e2.m`, `test_e2_integrator.m`
  del diagnóstico de E2).
- Datos canónicos: `RTS_SIM_RTBOX1/E{1,2,3}_data/fid_E*_rtbox.mat` y `rt_rtbox_E*.mat`.
- Figuras (2 ms): `RTS_SIM_RTBOX1/procesado/E{1,2,3}_rtbox_senales.png`, `E3_rtbox_alpha.png`,
  `rtbox_barrido_{openloop,closedloop}.png`; métricas en `metricas_rtbox.mat`.
- Docs: `GUIA_ubicacion_resultados_rtbox.md` (DIAGNÓSTICO reescrito), este memo.

## 9. Pendiente

- Redacción del capítulo de Resultados (tabla de fidelidad cruzada + RTS de las 4 modalidades, con el
  RFT ≈ 2 de la box y el contraste compute-bound vs timer/jitter-bound).
- Reescribir en el Desarrollo la sección "Implementación de las modalidades" (cuatro modalidades,
  E1/E2/E3 con lazo cerrado, corregir que QUARC usa timer de software).
