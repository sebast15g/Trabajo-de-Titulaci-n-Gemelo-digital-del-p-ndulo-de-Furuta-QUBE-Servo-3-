# Plan de redacción — última sección de Desarrollo e "Resultados"

Guion para cerrar el LaTeX. Insumos ya listos en `TESIS_FINALES/RTS_modalidades/` (figuras, tablas,
docs por modalidad, hallazgos). Convención de figuras del proyecto: 1 plot → sin título (caption en
LaTeX); varios subplots → cada uno con su título, sin título general; ejes en grados.

---

## A. DESARROLLO — "Implementación de las cuatro modalidades" (última sección)

Objetivo: describir el **montaje** de cada modalidad (no los datos; los datos van a Resultados).
Corrige la sección actual (que decía "3 modalidades", "RT Box pendiente" y "QUARC usa timer de hardware").

1. **Encuadre (½ pág).** Las 4 modalidades (SIM, QSM, QHW, RTB) del mismo gemelo M1 contra la planta real
   M0, en 3 experimentos (E1 caída libre, E2 respuesta forzada, E3 lazo cerrado swing-up+balance+EKF).
   Molde común: Ts=2 ms, misma excitación (E2), misma CI, convención α=0 arriba. Tabla resumen
   (modalidad | sustrato | planta | RTF | naturaleza) — de `DOCUMENTACION_GENERAL_RTS_unificada.md §1`.

2. **SIM (sim normal).** Simulink Normal, ode4 2 ms, `furuta_planta_analitica` (RK4 nsub=4). Solo RTF por
   `tic/toc`. Breve (`doc_SIM.md`). Captura del esquemático `E*_SIM`.

3. **QSM (QUARC-modelo).** Kernel QUARC, M1 en bloques (`furuta_planta_analitica` + `ekf_step`), lazo roto
   con `Unit Delay z⁻¹`. Captura de RTS (`Computation Time`, `System Time`, `Counter`). **Hallazgo del
   piso de 1 ms** del timer de software de Windows y el **fast system timer** (experimental, multinúcleo)
   — corregir aquí el error de "timer de hardware". Esquemáticos `E*_QSM_SIMULINK.png`. Extenso
   (`doc_QSM.md`).

4. **QHW (QUARC-real, M0).** Igual que QSM pero I/O físico por HIL API; `−1` de *For +ve CCW*; en E1 se
   suelta a mano (recorte). Referencia de fidelidad. Esquemáticos `E*_QHW_SIMULINK.png`. Breve
   (`doc_QHW.md`).

5. **RTB (RT Box).** C-Scripts PLANTA/CONTROL/EXCITACION, Euler 0.5 ms (sin ode4), log a 2 ms
   (`subTaskPeriod=4`). Captura de RTS por web/API (`rtbox_watch.py`, Application Log). Esquemáticos
   `E*_PLECS.png`. Extenso (`doc_RTB.md`).

6. **Diferencias de sustrato (½–1 pág, tabla).** Solver (Euler box vs ode4/RK4 QUARC), timer
   (hardware timebase box/HIL vs software Windows), captura de TET/overruns (API box vs bloques QUARC),
   RTF. Tabla de `COMPARACION_4_modalidades.md §2`. Aquí se justifica por qué "el mismo modelo" no da
   bit-idéntico entre sustratos (integrador).

Figuras de Desarrollo: esquemáticos (`*_SIMULINK.png`, `*_PLECS.png`) y scopes (`*_scope_*`) de cada
carpeta — ilustran el montaje, no los resultados.

---

## B. RESULTADOS — comparación de las cuatro modalidades

### B.1 Fidelidad (gemelo vs real M0)
- **E1 (caída libre):** tabla `f_n`/ζ de las 4 (RTB 1.76 / QSM 1.72 / SIM 1.72 / QHW 1.82 Hz).
  Figura `comp_E1_alpha_4mod.png` (4-way) y `comp_E1_alpha_vsreal.png` (subplots vs real).
- **E2 (respuesta forzada):** tabla de rangos θ/α + Vm; opcional RMSE θ/α alineado por τ*.
  Figuras `comp_E2_alpha_theta_4mod.png`, `comp_E2_{alpha,theta}_vsreal.png`.
- **E3 (lazo cerrado):** tabla de índices (t_catch, balance %, α̂_std, θ_std, **NIS en tabla, no figura**).
  Figuras `comp_E3_{alpha,theta,Vm,alphadot,E}_4mod.png` y `comp_E3_{alpha,theta}_vsreal.png`.
  → aquí entra el **hallazgo del vaivén extra** (§B.4).

  Tabla E3 (valores actuales):
  | mod | t_catch | balance % | α̂_std° | θ_std° | NIS |
  |---|---|---|---|---|---|
  | RTB | 2.72 | 91.6–93.8 | 0.51–0.60 | 0.66–0.69 | 1.10 |
  | QSM | 3.13 | 79.1 | 1.11 | 3.10 | 1.50 |
  | SIM | 3.13 | 79.1 | 1.11 | 3.10 | 1.50 |
  | QHW | 2.65 | 82.3 | 1.12 | 3.14 | 1.52 |

### B.2 RTS (impacto del tiempo real)
- Tabla RTF/TET/umbral-overrun/jitter de las 4 (`COMPARACION_4_modalidades.md §2`).
- Barridos: box abierto/cerrado (`rtbox_barrido_*`), QSM fast timer (`E1_qsm_barrido_fasttimer.png`,
  `E3_qsm_barrido_abierto_vs_cerrado.png`; tabla de `barridos_qsm.mat`).
- Hallazgos: **RTF≈2 de la box** (no sostuvo 1:1), **piso de 1 ms de QUARC** + fast timer, **jitter por
  timebase** (box sub-µs ≪ QHW HIL 36–70 µs ≪ QSM software 320 µs).
- Trade-off: *compute-bound* (box, determinista) vs *timer/jitter-bound* (QUARC, throughput).

### B.3 Comparación cruzada vs M0
- Overlays α/θ de las 4 vs el real (figuras B.1). Lectura: sustrato NO cambia la fidelidad
  (RTB≈QSM≈SIM), brecha M1↔M0 ~5%; QSM≈QHW casi exacto en balance.

### B.4 Hallazgo del vaivén extra (subsección propia) — `hallazgo_swingup_integrador.md`
- El analítico (RK4) hace 8 vaivenes vs 7 del RTB/3D/real. **No es defecto de fidelidad** (evidencia:
  fidelidad abierta, planta≡EKF 1.7e-13, 3D≈real 2.66 vs 2.65 s). **Es el integrador + umbral** (RK4→8,
  Euler→7; ke 50→52 pasa a 7). Figuras `hallazgo_swingup_{rk4_vs_euler,barrido_ke,ke52_vs_real}.png`,
  `respaldo_3D_vs_real_lazocerrado.png`, `diag_catch_qsm.png`. Es un resultado de RTS/numérico.

### B.5 Parte cualitativa (recordatorio) 
- Modelamiento α/θ y comparación en paralelo: (a) lazo cerrado real + EKF + control, (b) mismo esquema con
  modelo 3D. En Desarrollo fue cuantitativo; aquí cualitativo (`respaldo_3D_vs_real_lazocerrado.png` y
  figuras del gemelo en `TESIS_FINALES/`). Causas físicas de la brecha M1↔M0: cable-jack/histéresis,
  conector USB-C (artefacto del banco), stiction — parámetros no modelados a detalle.

---

## C. Orden sugerido de escritura
1. Desarrollo A (montajes) — reusar `doc_RTB/QSM/QHW/SIM.md`.
2. Resultados B.1 fidelidad → B.2 RTS → B.3 cruzada.
3. B.4 hallazgo del swing-up (cierra la duda del vaivén).
4. B.5 cualitativo + conclusiones parciales.

Pendiente opcional antes de redactar: RMSE θ/α por τ* en E2 (cuantitativo punto-a-punto); decidir ke=50
(documentar) vs ke=52 (re-correr SIM+QSM).


---

## D. Añadidos cuantitativos y de encuadre (iteración de cierre)

Estos insumos se integran en las secciones ya listadas; no las reemplazan.

- **RMSE θ/α cuantitativo** (`metricas_cuantitativas.md`, `metricas_cuantitativas.mat`, script
  `metricas_cuantitativas.m`). Entra en B.1 (fidelidad) como respaldo punto-a-punto:
  - E2 por **amplitud** (la coherencia temporal cae a ~0.45 por deriva de fase del barrido):
    α del analítico RK4 (QSM/SIM) 3.0 % vs real; α del Euler (RTB) 20.2 % — el Euler infla la
    amplitud, mismo efecto que decide el vaivén.
  - E3 **balance** (post-captura): RMSE α < 2° en todas; equivalente entre ke=50 y ke=52.
  - **3D**: t_captura 2.656 vs 2.650 s; α balance RMS 1.26° vs 1.20°.
- **Figuras ke=52** (`comp_E3_*_ke52*.png`): el analítico con 7 vaivenes que iguala al real, junto
  a las de ke=50 (hallazgo). SIM≡QSM verificado bit a bit. Se presentan en pareja en B.1/B.4.
- **Cuantitativo del 3D** (`metricas_cuantitativas.md §3D`): da números a lo que en B.5 era
  cualitativo (t_captura, RMSE de balance, α balance RMS).
- **Segundo hallazgo — dificultad del gemelo de Furuta** (`hallazgo_dificultad_gemelo_furuta.md`):
  nueva subsección **B.6** (o encuadre de conclusiones parciales). Reencuadra el vaivén extra como
  un caso concreto de una propiedad general: la fidelidad de un sistema subactuado e inestable no
  se captura solo con métricas de lazo abierto, y el sustrato/integrador no es neutro. Justifica el
  estudio multi-sustrato.
- **Orientación de figuras corregida**: α por signo del mayor vaivén del swing-up; θ/Vm por
  correlación en continuo. Ninguna curva queda invertida respecto al real (antes QSM/SIM sí).

### Tabla E3 — filas ke=52 añadidas (no sustituyen a las de ke=50)

| mod | t_catch [s] | balance % | RMSE α bal [°] | RMSE θ bal [°] |
|---|---|---|---|---|
| QSM ke=52 | 2.754 | 81.6 | 1.71 | 6.15 |
| SIM ke=52 | 2.754 | 81.6 | 1.71 | 6.15 |
| real (QHW) | 2.654 | 82.3 | — | — |

Nota: θ del gemelo analítico dispersa algo más que el real en el balance (std ~5–7° vs ~1.6° del
real/RTB), coherente con un brazo menos amortiguado en el modelo (stiction/fricción del banco no
modelada a detalle). El RTB, con Euler, replica mejor la dispersión de θ del real.
