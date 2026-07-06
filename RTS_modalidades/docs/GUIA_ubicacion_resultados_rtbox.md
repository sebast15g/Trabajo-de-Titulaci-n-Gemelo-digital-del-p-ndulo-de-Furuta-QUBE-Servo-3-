# Guía de ubicación de resultados — modalidad RT Box (E1/E2/E3)

Indica qué se extrajo de la RT Box, qué gráfica va dónde (Desarrollo / Resultados) y con qué
consideraciones de redacción. Es el molde; las secciones de QUARC-modelo (QSM), QUARC-real (QHW) y
sim normal (SIM) se agregan igual. Post-proceso reproducible en `procesar_rtbox.m` (esta carpeta);
métricas en `metricas_rtbox.mat`. Comparativa cruzada en
`SIM_QUARC_RTS/postproceso_comparaciones/crosscheck_rtbox.m`.

> **Estado (corregido):** el pipeline reconstruye el tiempo como **seq × 2 ms** (tiempo-modelo), no
> desde el wall-clock. Con esto la box coincide con QSM y con el real en las tres pruebas (ver
> DIAGNÓSTICO, reescrito). El detalle del procedimiento de corrección está en
> `memo_correccion_2ms_RTBOX.md`.

## Reglas de redacción para TODAS las gráficas (aplican a las cuatro modalidades)
- **Un solo plot** → SIN título (el *caption* de la figura en LaTeX será el título; no redundar).
- **Varios subplots** → cada subplot con su título corto, SIN título general del conjunto.
- **Convención de α en lazo cerrado (E3):** graficar α de modo que **el último vaivén antes de la
  captura venga del lado POSITIVO** y luego balancee, para que coincida con el real (puede requerir un
  `×(−1)`). `procesar_rtbox.m` lo hace con `fix_alpha_convention`. Mismo criterio en QSM/QHW/SIM.
- Fondo blanco, `exportgraphics` a 140 dpi, ejes en grados para θ/α.

## Consideración de captura de RTS (para nombrar bien en Metodología/Resultados)
- **Tiempo-modelo (eje temporal):** la box loguea **una muestra cada 2 ms de MODELO**
  (`subTaskPeriod[0]=4 × paso base 0.5 ms`), confirmado en el `.c` generado (`tesis_E*_RTBOX.c`). El
  tiempo se reconstruye como **seq × 0.002 s**, NO desde el reloj de pared. (El `t_model` del `To File`
  puede omitirse; el eje bueno es `seq × 2 ms`.)
- **RTF (hallazgo de RTS aparte):** el wall-clock avanza ~1 ms por muestra mientras el modelo avanza
  2 ms → **RTF = modelo/pared ≈ 2.00** (exacto en E1, E2 y E3). La box **no sostuvo tiempo real 1:1**:
  ejecutó cada paso de 2 ms de modelo en ~1 ms de pared. Es un resultado de RTS (no afecta la
  fidelidad, que se integra en tiempo-modelo). Este "~1 ms por muestra" es el que antes se confundía
  con "la box loguea a 1 ms" y producía el factor 2 fantasma.
- **TET/overruns:** NO son señal del modelo en la RT Box (no hay bloque de TET en el target). Se
  obtuvieron por la **interfaz web / API JSON-RPC** con `rtbox_watch.py` (`queryCounter` + Application
  Log), volcados a `rts_sweep_*.csv` y `rt_E*_<paso>.txt/_cycle.csv`. El jitter de la box es ~0
  (hardware-locked).
- **QUARC (QSM/QHW):** el TET sí es señal (bloque *Computation Time*), el wall-clock viene de *System
  Time* y el RTF por `tic/toc` en sim normal. (Detalle en la doc maestra Simulink/QUARC.)

---

## Qué se extrajo por experimento (RT Box, tiempo-modelo 2 ms)

### E1 — caída libre (lazo abierto)
- **Fidelidad:** `f_n = 1.76 Hz`, `ζ = 0.053` del decaimiento de α (decremento logarítmico), reposo
  α = π. Coincide con QSM (1.72 Hz, ζ 0.057) y con el real M0 (QHW 1.82 Hz) dentro de la brecha M1↔M0
  (~3 %). Nota: `f_n` es dependiente de amplitud (péndulo no lineal); medir en el mismo régimen en las
  cuatro modalidades (el pipeline usa la cola de pequeña amplitud). El antiguo "hallazgo a reconciliar"
  del amortiguamiento (Dp=0) queda **resuelto**: box y QSM usan la misma M1 y dan la misma ζ.
- **Gráfica:** `E1_rtbox_senales.png` (subplots α, θ) → **Resultados** (fidelidad E1) o Desarrollo si se
  ilustra el montaje.

### E2 — respuesta forzada (lazo abierto)
- **Fidelidad:** θ topa en ±135° (max 136.1°), α en [113.4°, 237.1°] (≈ ±60° del colgado), Vm_max 1.5 V,
  con la excitación arrancando en **t = 1.0 s** (C-Script EXCITACION con `RATIO = 1`, un índice por
  muestra de 2 ms). Coincide con QSM (α [123.6, 225.1]°) y con el real (α [124.1, 234.1]°).
  ⚠ Usar la corrida **`fid_E2_rtbox.mat` con `RATIO = 1` y PLANTA de parámetros vigentes** (α ∈ ~[113,
  237]°). Corridas intermedias con `RATIO = 2` (excitación estirada 2×, arranca en t = 2.0 s) o con la
  PLANTA de inercia vieja (α que se dispara a ~[3, 317]°) **NO son válidas** — ver el memo.
- **Gráfica:** `E2_rtbox_senales.png` (subplots θ, α, Vm) → **Resultados** (fidelidad E2, respuesta a la
  excitación; útil para el overlay contra el real).

### E3 — lazo cerrado (swing-up + balance + EKF)
- **Fidelidad/desempeño:** captura en **t = 2.72 s**, balance **91.6 %** del tiempo, α_std balance
  **0.60°**, θ_std **0.69°**, NIS medio **1.10** (consistente), `∫Vm²dt` **9.91**, E_max **30.2 mJ**
  (=Er). Coincide con QSM (catch 3.13 s, bal 79 %, α_std 1.11°, NIS 1.50) y con el real (catch 2.65 s,
  bal 82 %, α_std 1.12°, NIS 1.52): QSM ≈ QHW casi exacto; la box balancea algo más apretado (sustrato
  bare-metal). El swing-up sube la energía de 0 a Er en las tres.
- **Gráficas:** `E3_rtbox_senales.png` (subplots α, θ, Vm, E&mode; α con convención corregida) →
  **Resultados** (desempeño del lazo cerrado); `E3_rtbox_alpha.png` (α sola, un solo plot, SIN título) →
  figura de la captura/balance con caption.

### RTS — barridos de paso base
- **Lazo abierto (E1/E2):** TET_max ≈ 6.7–7.8 µs (casi constante), umbral de overrun ≈ **5 µs**
  (5120 overruns), carga 150 % a 5 µs. Fuente `rts_sweep_openloop_E2.csv`.
- **Lazo cerrado (E3):** TET_max ≈ 16–17 µs (el EKF ~triplica el TET), umbral ≈ **10 µs**
  (10240 overruns). Fuente `rts_sweep_closedloop_E3.csv`.
- Los barridos son **independientes de la parametrización del péndulo y del eje temporal** (miden costo
  de cómputo) → no se re-corren; siguen válidos tal cual.
- **Gráficas:** `rtbox_barrido_openloop.png`, `rtbox_barrido_closedloop.png` (subplots TET vs paso, y
  carga/overruns vs paso) → **Resultados** (capítulo RTS, tabla + figura del headroom de la box).

---

## Dónde va cada cosa (Desarrollo vs Resultados)

**Última parte del Desarrollo — "Implementación de las modalidades":** el *montaje* de cada modalidad
(no los datos): esquemático PLECS (`E*_PLECS.png`), C-Scripts PLANTA/CONTROL/EXCITACION, despliegue en
la RT Box, mismo Ts = 2 ms, cómo se capturó el TET/overruns (web/API + `rtbox_watch.py`). Aquí va la
corrección del texto actual (que decía "RT Box pendiente" y que QUARC usa "timer de hardware" — en win64
QUARC usa el **timer de software** de Windows). Las capturas de bloques/scopes ilustran el montaje.

**Resultados — capítulo de comparación de modalidades:**
1. **Fidelidad** por experimento (E1 `f_n`/ζ; E2 respuesta; E3 índices de swing-up/balance/NIS), con las
   gráficas de señales y, cuando corresponda, el overlay contra el real (M0).
2. **RTS** por sustrato: tabla y figuras del barrido (box abierto/cerrado), TET/overruns/jitter, RTF, y
   el contraste *compute-bound* (box) vs *timer/jitter-bound* (QUARC) del hallazgo del timer. Incluir el
   **RTF ≈ 2 de la box** (no sostuvo 1:1) como observación de RTS.
3. **Comparación cruzada** de las cuatro modalidades contra M0 (RMSE θ/α alineado por τ*, etc.).

**Resultados — parte cualitativa aparte de las modalidades:** además de las modalidades, van resultados
**cualitativos** de α/θ del modelamiento y la **comparación en paralelo**: (a) lazo cerrado con la
**planta real** + EKF + control, y (b) el mismo esquema con el **modelo 3D** en vez de la planta real. En
Desarrollo esto fue cuantitativo; en Resultados va cualitativo. Fuentes en `TESIS_FINALES/` y
`datos/gemelo/`.

## Estado de la comparación cruzada (siguiente paso)
- [x] Amortiguamiento/parametrización de α de la box reconciliado: **box ≡ QSM ≡ real** (misma M1),
  confirmado en E1 (`f_n`/ζ), E2 (rangos) y E3 (índices). Ya no hay que regenerar el C-Script PLANTA.
- [x] Mismo `procesar_*` aplicado a la box; `crosscheck_rtbox.m` aplica la misma medición de `f_n`/ζ
  (mismo régimen) y la misma convención de α a QSM/QHW/SIM.
- [ ] Tabla final de Resultados (fidelidad cruzada vs M0 + RTS de las 4 modalidades) — redacción.

---

## DIAGNÓSTICO (comparación box vs QSM vs real) — RESUELTO

**La RT Box NUNCA estuvo "2× off".** El síntoma (α de la box al doble de frecuencia y con más
amortiguamiento) era un **error de eje temporal**: el post-proceso reconstruía el tiempo desde el
wall-clock (~1 ms/muestra) cuando el `To File` loguea a **2 ms de modelo** por muestra
(`subTaskPeriod[0]=4 × 0.5 ms`, confirmado en el `.c` generado). Con el tiempo bien reconstruido
(`seq × 2 ms`), la box coincide con QSM y con el real:

| | f_α (E1) | ratio vs real |
|---|---|---|
| REAL (QHW, M0) | 1.82 Hz | — |
| **QSM** (`furuta_planta_analitica`) | 1.72 Hz | 0.95 ✓ |
| **RT Box** (M1 C-Script, seq×2 ms) | **1.76 Hz** | **0.97 ✓ coincide** |

Confirmación en las tres pruebas (`crosscheck_rtbox.m`):
- **E1:** f_n 1.76 (box) ≈ 1.72 (QSM) ≈ 1.82 (real) Hz; ζ 0.053 (box) ≈ 0.057 (QSM).
- **E2:** α ∈ [113, 237]° (box) ≈ [124, 225]° (QSM) ≈ [124, 234]° (real); θ topa ±136° y Vm_max 1.5 V en
  las tres.
- **E3:** balance firme en las tres, QSM ≈ QHW casi exacto (α_std 1.11° vs 1.12°, NIS 1.50 vs 1.52); la
  box algo más apretada (α_std 0.60°) por ser sustrato bare-metal.

**Lo que quedó DESCARTADO** (era la hipótesis previa equivocada): que el C-Script PLANTA de la box
tuviera la inercia del péndulo mal parametrizada (~1/4) dando 3.52 Hz / 1.94× off. La física de la box
siempre fue correcta: `M22 = Jp_cm + lp²·mp = 1.324e-4`, estados continuos integrados a 0.5 ms. NO hay
que regenerar el C-Script PLANTA por "inercia".

**Precaución de duplicados (lección del proceso):** el `2× off` desaparece con `seq×2 ms`, pero E2 tuvo
además dos trampas de archivo que sí importan y se verifican **por contenido**, no por nombre/fecha:
(1) el `RATIO` de la excitación — con `RATIO=2` la excitación se estira 2× (arranca en 2.0 s, mal); la
buena tiene `RATIO=1` (arranca en 1.0 s); (2) una corrida intermedia de E2 quedó con la PLANTA de
inercia vieja (α se dispara a [3, 317]°, respondiendo ~30× de más al Vm). La corrida válida de E2 es la
que tiene onset 1.0 s **y** α ∈ ~[113, 237]° (coincide con QSM/real). Ver `memo_correccion_2ms_RTBOX.md`.

Gráficas del diagnóstico (regeneradas): `E1_rtbox_senales.png`, `E2_rtbox_senales.png`,
`E3_rtbox_senales.png`, `E3_rtbox_alpha.png`, `rtbox_barrido_{openloop,closedloop}.png`.
