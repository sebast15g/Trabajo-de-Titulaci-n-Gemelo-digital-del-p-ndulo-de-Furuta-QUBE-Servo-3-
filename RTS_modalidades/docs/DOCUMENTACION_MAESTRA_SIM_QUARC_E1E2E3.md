# Documentación maestra — modalidades Simulink / MATLAB / QUARC (E1/E2/E3) y estudio de RTS

Documento de recopilación y procedimiento de la fase **Simulink/MATLAB/QUARC** del estudio de
fidelidad del gemelo digital del péndulo de Furuta (QUBE-Servo 3) y del impacto de la simulación
en tiempo real (RTS). Es la contraparte de `DOCUMENTACION_MAESTRA_RTS_E1E2E3.md` (RT Box) y cierra
las **tres modalidades que faltaban** para completar el estudio de cuatro sustratos. Redactado para
retomar el trabajo sin perder contexto y para alimentar los capítulos de Desarrollo y Resultados.

Estado: **completo** para E1, E2 y E3 en las tres modalidades (fidelidad + RTS + barridos donde
aplica). Falta solo el post-proceso comparativo final (fidelidad cruzada contra M0 + tablas
consolidadas), que es ya redacción de Resultados.

---

## 1. Objetivo y las tres modalidades de esta fase

El estudio compara **el mismo gemelo digital** ejecutado en cuatro sustratos contra la planta real
(M0). La RT Box quedó documentada aparte; esta fase añade las tres modalidades sobre Simulink/QUARC:

| ID | Nombre | Sustrato | Planta | RTF | Naturaleza |
|---|---|---|---|---|---|
| **SIM** | Sim normal | Simulink offline (PC) | modelo M1 (MATLAB Function) | ≫ 1 | libre, sin tiempo real |
| **QSM** | QUARC-modelo | kernel de tiempo real QUARC (PC) | modelo M1 | = 1 | tiempo real, planta simulada |
| **QHW** | QUARC-real | kernel QUARC (PC) + QUBE-Servo 3 físico | planta física M0 | = 1 | tiempo real, hardware (interfaz HIL) |

`RTB` (RT Box, PLECS Coder) es la cuarta modalidad. **M1** = modelo analítico de 4 estados
(`furuta_f_aug`, transcrito a `furuta_planta_analitica.m`); **M2** = modelo 3D Simscape, usado en su
momento para calibrar M1 (no interviene aquí como planta).

Dos familias de métricas, idénticas a la RT Box:
- **Fidelidad** (gemelo vs real): RMSE θ/α, error máximo, `f_n`/`ζ` (E1), índices de desempeño (E3),
  consistencia del EKF (NIS). Salen de las señales del modelo.
- **RTS** (impacto del tiempo real): RTF, TET, overruns, jitter, muestras perdidas. Salen del
  sustrato de ejecución.

**Aclaración de terminología (importante para la redacción).** En la taxonomía X-in-the-Loop, QSM y
RTB son **simulaciones en tiempo real** del gemelo (no HIL: no hay hardware en el lazo); QHW es la
**planta física bajo control en tiempo real** (M0). El término "HIL" se usa solo en el sentido
comercial de Quanser (la interfaz con el QUBE usa la HIL API: `HIL Initialize`, `HIL Read Encoder`,
`HIL Write Analog`), no en el de emulación de planta.

---

## 2. Convenciones comunes (no negociables — comunes con la RT Box §2)

1. **`Ts = 2 ms` (500 Hz)** como malla de muestreo/comparación en las cuatro modalidades.
2. **Solver Simulink/QUARC**: `ode4` (o discreto) a paso fijo `2e-3`. La planta M1 integra internamente
   por RK4 con `nsub = 4` subpasos (`h = 5e-4`, = paso base de la RT Box).
3. **Convención de ángulos**: θ y α en la del control, **α = 0 arriba, α = π colgado**. El encoder
   real entrega α; la comparación con el modelo usa `α_real ↔ π − α_modelo` en post-proceso.
4. **α SIEMPRE unwrapped hacia el EKF/control.** El encoder del QUBE es incremental (cuenta continua);
   la planta M1 entrega `alpha_meas` **cuantizada pero SIN envolver**, para que `nu = y − ŷ` del EKF no
   tenga saltos de 2π durante el swing-up. (En el log de fidelidad puede guardarse envuelta si se
   prefiere; el control usa la unwrapped.)
5. **Excitación E2** = `excitacion_Vm_e2` (33 s, 16500 muestras a 2 ms, |Vm| ≤ 1.5 V), desde
   `From Workspace` con *Interpolate data = OFF (ZOH)*, *Hold final value* — idéntica a la de la box.
6. **Condición inicial**: E1 `AL0 = 0.05` (cae desde arriba), E2 `AL0 = π`, E3 `AL0 = π` (colgado).
7. **El tiempo va como canal explícito** (fila 1 del log). En QUARC el `To File` antepone su tiempo
   automáticamente (a diferencia de PLECS); se reconstruye igual y `cargar_log_quarc.m` lo lee directo.
8. **Signo del actuador**: en SIM/QSM se usa `u = −Ka·[x̂;xᵢ]` sin el `−1` de `For +ve CCW`; ese `−1`
   solo aparece en QHW (hardware Quanser real).

---

## 3. La planta y el controlador (bloques Simulink reutilizados)

- **Planta M1 — `furuta_planta_analitica.m`** (bloque MATLAB Function): integrador discreto
  autocontenido (RK4, `nsub=4`) que es la **transcripción literal del C-Script `PLANTA` de la RT Box**.
  Incluye la dinámica Lagrangiana 2-DOF, el **tope mecánico θ = ±135°** (penalización unilateral
  resorte-amortiguador) y la **emulación del encoder** (cuantización 2π/2048, α unwrapped). Salidas:
  `theta, alpha, dtheta, dalpha, theta_meas, alpha_meas`. **Verificada contra `furuta_f_aug.m` a
  1.14e-13** (params actuales, `g = 9.7807`). No usa `furuta_f_param.m`, que quedó con `g = 9.77`
  horneada (desactualizada; regenerable con `derivar_furuta_f_param.m`).
- **EKF — `ekf_step.m`** (bloque MATLAB Function): un paso del EKF de estado aumentado (5 estados,
  predicción con Jacobiano + corrección + NIS). Entradas `y = [theta_meas; alpha_meas]` (unwrapped),
  `Vm`. Salidas `xhat = [θ̂,α̂,θ̇̂,α̇̂]`, `dhat`, `nis`. `nis` se calcula como reducción escalar
  `sum(nu.*(Sk\nu))` (garantiza `1×1` para codegen). Requiere `furuta_f_aug/_Fc/_meas/_Hjac` en el path.
- **Swing-up + balance**: swing-up de energía de Quanser (`ke=50`, `Er=2·mp·g·lp≈30.2 mJ`, `u_max=6`)
  con conmutación a balance (`catch` ~17–20°). Balance = **LQI del proyecto**
  `K_LQI = [-3.7921 -33.888 -1.4796 -2.9148 -4.4721]` (4 estados + integrador), NO la ganancia por
  defecto de Quanser. Energía `E = 0.5·Jp_cm·α̇² + mp·g·lp·(1+cos α)`, con α̂/α̇̂ del EKF.
- **Ruptura del lazo**: en E3 el lazo `planta → EKF → control → Vm → planta` se cierra con un
  **`Unit Delay z⁻¹`** (2 ms, inicial 0) entre el `Vm` del control y el `Vm` de la planta. En QSM/SIM es
  imprescindible (la planta MATLAB Function es feedthrough → sin el delay hay lazo algebraico). En QHW
  no hace falta: el hardware (HIL Read/Write) introduce el retardo de forma natural.

---

## 4. Logging (mismo vector de fidelidad que la RT Box §5)

Dos `.mat` por corrida unidos por `seq`, con el **tiempo como canal explícito** (fila 1).

- **Fidelidad `fid_E*_<mod>.mat`**:
  - E1/E2 (lazo abierto): `[t, seq, theta, alpha, dtheta, dalpha, theta_meas, alpha_meas, Vm]` (9 filas).
  - E3 (lazo cerrado): `+ [theta_hat, alpha_hat, dtheta_hat, dalpha_hat, dhat, nis, mode, E]`
    (y `theta_ref`) — hasta 18 filas.
  - En **QHW no hay estado "verdadero"** aparte del encoder: `theta/alpha` = `theta_meas/alpha_meas`;
    las velocidades se derivan en post o se toman del EKF.
- **Tiempo real `rt_E*_<mod>.mat`**:
  - **SIM**: solo `RTF` (struct escueto; TET/overruns/jitter = n/a).
  - **QSM/QHW**: `[t, seq, t_model, t_wall, TET]`, con `t_wall` del bloque QUARC **System Time** y `TET`
    del bloque **Computation Time** (opción *Output computation time of task*, modo *Wall clock*).

**Bloques de captura de RTS (QUARC):** `Counter Free-Running` (seq, sample time 0.002),
`System Time` (t_wall, *Wall clock*), `Computation Time` (TET, *Output computation time of task*),
dos `To File` (fid y rt). En SIM esos bloques QUARC son n/a; se desconectan y el RTF sale de
`tic/toc` alrededor de `sim()` (`run_sim_normal.m`).

---

## 5. Hallazgo principal de RTS — piso de tasa base de QUARC (win64)

Documentado en detalle en `hallazgo_QUARC_timer_floor_RTS.md` (en `E1_QSM/`). Resumen:

- Por defecto, el target `quarc_win64` usa el **timer de Windows con resolución de 1 ms**: solo admite
  pasos base múltiplos de 1 ms. **Por debajo de 1 ms el kernel rechaza el base rate** ("Unable to set
  base rate. A value is outside the valid range" / "Actual period will be 0"), tanto en External Mode
  como en standalone. Quanser mismo califica la tasa de 1 kHz de Windows de "crude and inaccurate" [1].
- La casilla **"Allow use of fast system timer"** (Config Params → QUARC) elimina ese piso y permite
  pasos sub-ms, a costa de mucho CPU (recomendado en multinúcleo) [1].
- **Distinción clave (timer-bound vs compute-bound):** la RT Box es *compute-bound* (timer de hardware
  fino; overrunea cuando el TET supera al paso, ~5–10 µs abierto, ~16–17 µs cerrado). QUARC por defecto
  es *timer-bound* (el cómputo sobra —TET ~7–8 µs— pero el reloj del SO topa en 1 ms). Con fast timer,
  QUARC pasa a *compute/jitter-bound* y mantiene RTF=1 hasta ~5 µs (E1 y E3), colapsando en 1 µs
  (RTF 0.68 abierto, 0.32 cerrado; TET_max hasta 36 ms por stalls de Windows).
- **Trade-off del sustrato:** QUARC (PC potente + fast timer) gana en **throughput mediano** (TET ~µs,
  menor que la box); la RT Box gana en **determinismo** (jitter sub-µs acotado por hardware vs stalls de
  ms de Windows). En QUARC el costo del EKF (lazo cerrado) es despreciable porque el PC es rápido; en la
  box es visible (por eso su umbral cerrado 16 µs ≫ abierto 5–10 µs).
- **Jitter según timebase** (a 2 ms, sin overruns): RT Box sub-µs ≪ QHW ~36–70 µs (timebase HW de la
  tarjeta HIL disciplina el lazo) ≪ QSM ~320 µs (solo timer de software Windows, sin hardware timebase).

Referencia: [1] Quanser Inc., "Configuration Parameters," QUARC Documentation,
https://docs.quanser.com/quarc/documentation/configuration_parameters.html

---

## 6. Metodología del barrido de paso (solo QSM)

El barrido de paso base (headroom de tiempo real) es **exclusivo de QSM** (planta simulada): en QHW la
planta es física y corre en tiempo real pase lo que pase; en SIM no hay tiempo real. Procedimiento:

1. Todos los bloques con sample time a **`-1` (inherit)**; controlar la tasa solo con el *Fixed-step
   size = `Ts_base`* del solver → modelo mono-tasa (evita el error "Data integrity issue" de multi-tasa).
2. Barrer `Ts_base`: por defecto solo 2e-3 y 1e-3 (piso del timer); **con fast timer** 5e-4, 2.5e-4, 1e-4,
   5e-5, 1e-5, 5e-6, 1e-6 hasta el colapso de RTF.
3. Correr en **standalone** (`quarc_run` o doble-clic al `.rt-win64`), no en Monitor & Tune (External
   Mode topa a 1 kHz por `quarc_comm`, aparte del kernel). Leer el `rt_*.mat` (Computation Time) o la
   consola de QUARC.
4. Un barrido por **tipo de lazo**: abierto (E1, cubre E2) y cerrado (E3). Post-proceso con
   `procesar_barrido_rts.m` (RTF, TET min/med/max, overruns, paso real vs paso nominal).
5. Fidelidad se toma aparte, en el punto de operación (2 ms).

Caveat de logging a tasas rápidas: el contador `seq` de 16 bits se desborda (a 1 µs, 15 M muestras) y
corrompe el `t_model` reconstruido; usar el `t` del target (fila 1) y el `t_wall`, o loguear `seq` a 32
bits. Para las corridas de punto de operación (2 ms), **desactivar el fast timer** (baja el TET_max y da
el jitter representativo del sustrato normal).

---

## 7. Resultados preliminares (RTS)

**Sim normal (offline, RTF ≫ 1):** E1 RTF 12.3, E2 RTF 35.4, E3 RTF 15.4 (tiempo de pared ~1 s en los
tres; el RTF incluye el overhead fijo de init de Simulink → es un límite inferior conservador). TET/
overruns/jitter = n/a.

**QSM — punto de operación (2 ms):** RTF=1, 0 overruns, 0 muestras perdidas. TET medio ~8–10 µs (abierto)
y ~15 µs (cerrado, con EKF); jitter ~320 µs (software puro, sin hardware timebase).

**QSM — barrido de paso (fast timer):** RTF=1 hasta ~5 µs; colapso en 1 µs. Ver
`E1_qsm_barrido_fasttimer.png` (abierto) y `E3_qsm_barrido_abierto_vs_cerrado.png` (comparativa).

**QHW — punto de operación (2 ms):** RTF=1, 0 overruns, jitter ~36–70 µs (timebase HW de la tarjeta HIL).
Es la referencia M0.

---

## 8. Consideraciones de fidelidad — por qué difieren real (M0) y modelo (M1)

(Se ahondará en la redacción; aquí el resumen de las causas físicas identificadas.)

- **Frecuencia de α (E1, caída libre):** el modelo va ~8–9 % más lento que el real (2.20 vs 2.40 Hz). Es
  dominado por las **inercias** (Jr del brazo, Jp del péndulo) y el acoplamiento con el brazo libre; el
  cable contribuye de forma secundaria. Los parámetros son de CAD (SolidWorks + calibrador), físicamente
  fundamentados; **no se sobreajustan** para no degradar el modelo en el resto del régimen.
- **Cable-jack (E2, cerca del tope):** el conector del encoder se enrosca a la base del QUBE; al girar el
  brazo al tope (±135°) el jack rota y el cable se enrolla, con rigidez dependiente de la posición,
  histéresis y reposo θ₀ que se desplaza. El error de θ crece hacia el tope (14°→18°) y deja un offset
  residual (~14°) que se acumula. **No representable con parámetros constantes** — M1 modela el cable
  como resorte lineal + viscoso. Es una limitación del régimen, no un mis-tuning.
- **Conector USB-C (E2):** el conector físico de alimentación/USB-C obstruye al péndulo cuando |Vm|≥1 V
  lo lanza al tope; le quita amplitud y cambia el rebote. Es un **artefacto del banco de pruebas**, no un
  déficit del modelo — argumento en contra de tocar parámetros.
- **Stiction y ruido (E3, balance):** el real oscila **4× más en θ** que el modelo (std 2.75° vs 0.69°),
  porque el gemelo limpio no tiene cable-jack, stiction, ruido de encoder ni jitter que rechazar. La
  subactuación obliga a mover θ para sostener α; a más perturbación real, más movimiento de θ. Es una
  medida directa de la brecha de fidelidad en lazo cerrado, no un fallo del control.

Conclusión metodológica: M1 es un **gemelo válido para su propósito** (estimación + control + estudio de
RTS), con un **régimen de validez documentado** (excelente a baja frecuencia/amplitud moderada; se
degrada cerca del tope, en alta frecuencia y con el conector). El lazo cerrado (E3) coincide muy bien
real vs modelo (mismo control, tiempos y amplitudes de swing-up), que es la validación más relevante para
un gemelo destinado a control. Como M1 es idéntico en las cuatro modalidades, esta brecha **se cancela**
en el delta entre modalidades → no afecta al estudio de RTS.

---

## 9. Inventario de la carpeta `SIM_QUARC_RTS/`

Estructura por modalidad (paralela a `RTS_SIM_RTBOX1/`). Cada subcarpeta trae el `.slx` del modelo, el
`.rt-win64` compilado (QUARC), los `.mat` de fidelidad y RT, capturas del modelo Simulink y de los
scopes θ/α, y algún `.txt` de consola (se conservan a modo de evidencia; se descartan para el análisis,
que sale de los `.mat`).

- **`E1E2E3_sim_normal/`**: `E1_SIM.slx`, `E2_SIM.slx`, `E3_SIM.slx`; `fid_E{1,2,3}_sim.mat`,
  `rt_E{1,2,3}_sim.mat` (solo RTF); `run_sim_normal.m` (corre offline y mide RTF por `tic/toc`).
- **`E1_QSM/`**: `E1_QSM.slx` + `.rt-win64`; `fid_E1_qsm.mat`; `rt_E1_qsm.mat` (2 ms) y el **barrido**
  `rt_E1_qsm_{2e_3,1e_3,5e_4,1e_4,5e_5,1e_5,5e_6,1e_6}.mat`; capturas `E1_QSM_SIMULINK.png`,
  `E1_qsm_scope_theta_alpha.png`; `.txt` de consola; y **`hallazgo_QUARC_timer_floor_RTS.md`**.
- **`E2_QSM/`**: `E2_QSM.slx` + `.rt-win64`; `fid_E2_qsm.mat`, `rt_E2_qsm.mat` (2 ms); capturas.
- **`E3_QSM/`**: `E3_QSM.slx` + `.rt-win64`; `fid_E3_qsm.mat`; barrido cerrado
  `rt_E3_qsm_{2e_3…1e_6}.mat`; capturas.
- **`E1_QHW/`, `E2_QHW/`, `E3_HQW/`** (planta real, M0): `.slx` + `.rt-win64`; `fid_E*_qhw.mat`,
  `rt_E*_qhw.mat` (solo punto de operación 2 ms, sin barrido — planta física); capturas del modelo y de
  los scopes; `.txt` de consola.
- **`postproceso_comparaciones/`**: `ver_E1_qhw.m` (verificador E1: layout, signo de α, `f_n`/`ζ`,
  jitter/RTF/TET), `E1_overlay_preview.m`, `E2_overlay_preview.m` (overlays real vs analítico con
  detección de inversión de signo), `procesar_barrido_rts.m` (tabla RTS del barrido).

Nombres: `fid_*` = fidelidad, `rt_*` = tiempo real; el sufijo en `rt_E*_qsm_<paso>` = paso base del
barrido. `*_SIMULINK.png` = bloques y conexiones del modelo; `*_scope_*` = scopes θ/α.

> Nota: la subcarpeta de la planta real de E3 está nombrada `E3_HQW` (typo de `E3_QHW`); el contenido es
> el correcto de QHW-E3.

---

## 10. Post-proceso y estado / checklist

- **Carga**: `cargar_log_quarc.m` lee cualquier `.mat` de SIM/QSM/QHW (orienta a señales×N, recorta
  padding, espera el tiempo en la fila 1). `cargar_log_rtbox.m` para la box.
- **Fidelidad**: alinear por correlación cruzada `τ*`, aplicar `α_real ↔ π−α_modelo`, decimar a 2 ms, y
  emitir RMSE θ/α, e_max, `f_n`/`ζ` (E1), índices E3, NIS. `validar_resultados.m` cubre estimación/balance.
- **RTS**: RTF (SIM ≫1; resto =1), jitter/TET/overruns (QUARC, box), barridos (`procesar_barrido_rts.m`).

Checklist:
- [x] SIM — E1/E2/E3 offline + RTF.
- [x] QSM — E1/E2/E3 fidelidad a 2 ms + barridos abierto (E1) y cerrado (E3) + hallazgo del timer floor.
- [x] QHW — E1/E2/E3 fidelidad a 2 ms (M0) + RTS.
- [ ] Post-proceso comparativo final (fidelidad cruzada vs M0 + tablas RTS de las 4 modalidades).
- [ ] Redacción de Desarrollo (esta carpeta, capturas de modelos y scopes) y Resultados (tablas).

---

## Referencia
[1] Quanser Inc., "Configuration Parameters," QUARC Documentation.
    https://docs.quanser.com/quarc/documentation/configuration_parameters.html
    (parámetros *Allow use of fast system timer* y *Stop the model if an overrun occurs*).
