# Hallazgo — piso de tasa base de QUARC (win64) en el estudio de RTS

Nota técnica para la redacción del capítulo de RTS. Documenta por qué el sustrato QUARC
(QSM y QHW, target `quarc_win64`) no admite pasos de muestreo por debajo de ~1 ms con la
configuración por defecto, cuál es la causa, la opción para superarlo, y qué significa para
la comparación con la RT Box.

## 1. Observación

Al barrer el paso base del modelo E1-QSM (planta analítica en el kernel de tiempo real de
QUARC), las corridas fallan **a partir de 5e-4 s (2 kHz)**, tanto en Monitor & Tune (External
Mode) como en ejecución **standalone** (doble clic al `.rt-win64`, sin host). Standalone (que
descarta cualquier límite de External Mode) imprime:

```
Creating main thread with priority 2 and period 0.0005...
*** Actual period will be 0 ***
Unable to set base rate. A value is outside the valid range.
---- Model 'E1_QSM' terminated (exit code 1) ----
```

Mientras que a 2e-3 y 1e-3 corre normal:

```
Creating main thread with priority 2 and period 0.002...
Main thread exited
---- Model 'E1_QSM' terminated (exit code 0) ----
```

El mensaje **"Actual period will be 0"** es el diagnóstico: el período solicitado (500 µs),
convertido a las unidades del timer del sistema, redondea a 0 → período inválido → el kernel
rechaza. Como aparece también en standalone, **es un límite del kernel de tiempo real, no de
la comunicación External Mode.**

## 2. Causa raíz: resolución del timer del sistema (Windows)

Por defecto, el target `quarc_win64` usa el **timer del sistema de Windows, con resolución de
1 ms**. Los períodos válidos son múltiplos enteros de ese tick: 2 ms y 1 ms funcionan; 0.5 ms
no se puede representar (0.5 ticks → 0). Documentación de Quanser (Configuration Parameters,
parámetro *Stop the model if an overrun occurs*):

> "the Windows target sampling rate of 1 kHz is crude and inaccurate in some systems and
> causes a lot of overrun occurrences in your model."

Es decir, el propio fabricante califica de "tosca e inexacta" la tasa de 1 kHz del target de
Windows; por eso el corte por overrun viene desactivado de fábrica.

## 3. Opción para superarlo: *fast system timer*

QUARC ofrece en *Configuration Parameters → Code Generation → QUARC* la casilla
**"Allow use of fast system timer"** (desactivada por defecto). De la documentación:

> "It is used for sample times faster than one or two milliseconds ... allows sample times
> faster than one millisecond to be specified. ... If this option is not checked then sample
> times are limited to one millisecond."

Restricciones documentadas del fast system timer:
- Es **muy intensivo en CPU**; conviene en sistemas con **más de 2 núcleos**.
- Está **siempre deshabilitado en sistemas de 1 CPU** (la casilla se ignora).
- Para tasas rápidas y deterministas, Quanser recomienda usar un **hardware timebase** (el
  timer de una tarjeta HIL) en lugar del timer de software.

Consecuencia: para empujar el barrido de QSM por debajo de 1 ms hay que **activar el fast
system timer**. Sin él, los únicos pasos factibles son 2 ms y 1 ms.

## 4. Interpretación para la tesis: timer-bound vs compute-bound

El resultado central es que **los dos sustratos topan con el tiempo real por razones
distintas**:

- **RT Box (PLECS Coder, bare-metal):** *compute-bound*. Tiene un timer de hardware de
  resolución fina (permite fijar pasos hasta 5 µs), así que corre hasta que el **cómputo** ya
  no alcanza: overrunea cuando el TET (~6–7 µs en lazo abierto) supera al paso, alrededor de
  5–10 µs.
- **QUARC win64 (sobre Windows):** *timer-bound*. El cómputo sobra por amplio margen (TET
  ~7–8 µs, ver §5), pero el **reloj del sistema operativo (1 ms)** es el techo: el kernel
  **rechaza** (bounds check del período) cualquier paso < 1 ms mucho antes de que el cómputo
  sea un problema. Rechaza en vez de overrunear.

Esta distinción es más informativa que un simple "QUARC es más lento": el cuello de botella
del sustrato QUARC por defecto no es la potencia de cálculo sino la **granularidad del reloj
del SO**. Con el fast system timer activado, QUARC podría bajar de 1 ms y eventualmente
llegar también a un límite de cómputo (como la box), a costa de mucho uso de CPU.

## 5. Datos medidos (E1-QSM, lazo abierto, corridas válidas)

| paso base | dt log | TET min | TET medio | TET máx | carga (TET/Ts) | overruns |
|---|---|---|---|---|---|---|
| 2 ms  | 2004 µs | 1.7 µs | 8.4 µs | 414.7 µs | 0.4 % | 0 |
| 1 ms  | 1001 µs | 1.0 µs | 7.1 µs | 201.9 µs | 0.7 % | 0 |
| ≤ 0.5 ms | — | — | — | — | — | **no arranca** ("unable to set base rate") |

El TET mediano (~7–8 µs) es casi constante y del mismo orden que el de la RT Box (6–7 µs); la
diferencia está en el **máximo** (200–415 µs), que son los picos de jitter de scheduling de
Windows (tiempo real blando), muy por encima del jitter sub-µs de la box (hardware-locked).

## 6. Implicación metodológica y próximos pasos

- Reportar el piso de QUARC como **hallazgo del sustrato**, no como fallo: QUARC (win64, timer
  por defecto) sostiene hasta 1 kHz; por debajo rechaza el base rate por resolución del reloj.
- Para un barrido de QUARC comparable en rango al de la box, **activar "Allow use of fast
  system timer"** y repetir 5e-4, 2.5e-4, 1e-4, ... hasta el nuevo límite (que ya sí debería
  ser de cómputo/jitter). Documentar que se requirió el fast timer y sus caveats.
- El barrido de la box y el de QUARC no son directamente superponibles en el eje del paso: la
  box mide *headroom de cómputo*; QUARC (por defecto) mide *resolución de reloj*. La tabla
  comparativa debe dejar esto explícito.
- El sustrato realmente determinista a paso fino es el **hardware timebase** (RT Box, o la
  tarjeta HIL del QUBE en QHW), no el timer de software de Windows.

## Referencia
[1] Quanser Inc., "Configuration Parameters," QUARC Documentation.
    https://docs.quanser.com/quarc/documentation/configuration_parameters.html
    (parámetros *Allow use of fast system timer* y *Stop the model if an overrun occurs*).

---

## 7. Resultado con el *fast system timer* ACTIVADO (standalone)

Al activar "Allow use of fast system timer" y correr en standalone, QUARC **acepta** tasas
base hasta 1 µs (ya no aparece "unable to set base rate"): la consola imprime períodos de
1e-4, 1e-5 y 1e-6 con "Main thread exited" y exit code 0. El piso de 1 ms del timer por
defecto queda eliminado.

Pero *aceptar* la tasa no es *cumplir* el tiempo real. Medido en el `rt` de la corrida a
**1 µs** (paso nominal 1e-6 s):

| magnitud | valor |
|---|---|
| RTF (modelo/pared) | **0.685** (15.00 s de modelo en 21.91 s de pared) → NO alcanza |
| paso real logrado | 1.46 µs (pedido 1.00 µs) |
| muestras con TET > paso | 57 % |
| TET mediana | ~1.0 µs |
| TET máximo | **36.5 ms** (stall de scheduling) |

Interpretación: con el fast timer, QUARC pasa de *timer-bound* a **compute/jitter-bound**
—el mismo régimen que la RT Box—. A escala de µs ya no mantiene RTF=1.

**Matiz importante (trade-off del sustrato):**
- La **mediana** de QUARC es excelente (TET ~1 µs), de hecho **menor que la de la RT Box**
  (~6–7 µs), porque el CPU del PC de escritorio es mucho más potente que el procesador
  embebido de la box. En throughput típico, QUARC puede pisar más fino.
- El **peor caso** es catastrófico: stalls de decenas de ms (36.5 ms medido), producto del
  no-determinismo de Windows. La RT Box tiene jitter sub-µs acotado por hardware.

Conclusión: no es que un sustrato sea "mejor". QUARC (fast timer) gana en **throughput
mediano** (CPU potente), la RT Box gana en **determinismo** (jitter acotado). El fast timer
desbloquea tasas finas a costa de mucho CPU y de una cola de latencia no acotada.

El cruce RTF=1 (headroom real de QUARC con fast timer) está entre 1e-3 (RTF≈1, §5) y 1e-6
(RTF=0.685); para fijarlo hay que medir los puntos intermedios (1e-5, 1e-4, 5e-6, 2e-6).

Caveat de logging a tasas rápidas: el contador `seq` de 16 bits **se desborda** (a 1 µs da
15 M muestras), lo que corrompe el `t_model` reconstruido (aparece topado en 131 s =
65536·2 ms). Para estas corridas hay que usar el `t` del target (fila 1) y el `t_wall`
(System Time), o loguear `seq` a 32 bits.

### 7.1 Barrido completo con fast timer (E1-QSM, lazo abierto)

| paso base | RTF | TET med | TET máx | overruns |
|---|---|---|---|---|
| 500 µs | 1.000 | 7.1 µs | 199 µs | 0 % |
| 100 µs | 1.000 | 3.7 µs | 590 µs | 0 % |
| 50 µs  | 1.000 | 3.4 µs | 509 µs | 0 % |
| 10 µs  | 1.000 | 2.4 µs | 849 µs | 1 % |
| 5 µs   | 1.000 | 1.6 µs | 3 125 µs | 5 % |
| 1 µs   | **0.685** | 1.0 µs | **36 473 µs** | 57 % |

Lectura: QUARC con fast timer **mantiene RTF=1 hasta ~5 µs** (con 1–5 % de overruns puntuales
que aún recupera) y solo **colapsa en 1 µs** (RTF 0.685, 57 %). Es decir, alcanza
**esencialmente el mismo paso fino de tiempo real que la RT Box** (~5–10 µs). La diferencia
decisiva está en el **peor caso**: el `TET_max` crece de ~200 µs a **36 ms** al forzar la tasa,
por el no-determinismo de Windows, mientras el jitter de la box permanece sub-µs. 

Conclusión final del sustrato: en **capacidad de tasa** QUARC (PC potente + fast timer) ≈ RT
Box; en **determinismo** (cota del peor caso) la RT Box es netamente superior. El fast timer
iguala el throughput a costa de una cola de latencia no acotada y alto uso de CPU.

---

## 8. Jitter según el timebase: QSM (software) vs QHW (hardware HIL) vs RT Box

En el punto de operación (2 ms, sin overruns en ninguno) el **jitter del instante de muestreo**
depende de qué disciplina el reloj del lazo, no del experimento:

| modalidad | timebase del lazo | jitter @ 2 ms |
|---|---|---|
| RT Box | timer de hardware (bare-metal) | sub-µs |
| QHW (planta real) | `HIL Read Encoder Timebase` (timer de la tarjeta HIL) | ~36–70 µs |
| QSM (planta simulada) | timer de software de Windows (sin hardware) | ~320 µs |

Medido en E2-QSM a 2 ms (fast timer OFF): RTF=1.000, TET med 9.5 µs, TET máx 237 µs, 0
overruns, **jitter 319 µs**. Frente a E2-QHW (mismo kernel QUARC, misma tasa): jitter ~36 µs.
La diferencia (~×5–10) **no** es el cómputo (el TET es igual de bajo) ni el fast timer (apagarlo
solo bajó el TET máx de 557 a 237 µs; el jitter siguió en ~320 µs): es que **QHW tiene un
timebase de hardware** (la tarjeta HIL del QUBE disciplina el muestreo) y **QSM no** (depende
del reloj de software del SO). Coincide con la recomendación de Quanser de usar un hardware
timebase para tiempos de muestreo ≤ 2 ms [1].

Ordenamiento del determinismo, coherente con §4 y §7: **RT Box (hardware bare-metal) ≪ QHW
(timebase HIL) ≪ QSM (software Windows).** Cuanto más disciplina de hardware tiene el reloj,
menor el jitter. El mismo comportamiento aplica a E1-QSM y E3-QSM: es una propiedad del
sustrato (software puro sin timebase), no del experimento.

> **Nota metodológica:** para las corridas de punto de operación (2 ms) conviene **desactivar
> el fast system timer** (solo se necesita para el barrido sub-ms); con él apagado el TET máx
> baja y el jitter reportado es el representativo del sustrato QUARC estándar.

---

## 9. Barrido de lazo cerrado (E3-QSM) y comparacion abierto/cerrado y box/QUARC

Barrido con fast timer del modelo de lazo cerrado (planta + EKF + swing-up + LQI):

| paso base | RTF | overruns | paso real logrado |
|---|---|---|---|
| 500 µs | 1.000 | 0 % | 500 µs |
| 100 µs | 1.000 | 0 % | 100 µs |
| 50 µs  | 1.000 | 0 % | 50 µs |
| 10 µs  | 1.000 | 2 % | 10 µs |
| 5 µs   | 1.000 | 7 % | 5 µs |
| 1 µs   | **0.319** | 100 % | 3.13 µs |

E3 (cerrado) mantiene RTF=1 hasta ~5 µs y colapsa en 1 µs, **mismo umbral que E1 (abierto)**,
pero colapsa **más fuerte** (RTF 0.319 vs 0.685 de E1; 100 % vs 57 % de overruns): el lazo
cerrado, más pesado, cae más abajo al pasar el límite.

**Contraste con la RT Box — el hallazgo fino:**

| | RT Box (bare-metal) | QUARC-QSM (fast timer, PC) |
|---|---|---|
| Umbral lazo ABIERTO (E1/E2) | ~5–10 µs | ~5 µs |
| Umbral lazo CERRADO (E3) | ~16–17 µs | ~5 µs |
| ¿Por qué cerrado > abierto? | CPU embebido lento → el TET del EKF (~16 µs) domina y overrunea antes | CPU del PC tan rápido que el EKF es despreciable; ambos topan en el **mismo** piso de timer/jitter |

Lectura: en la **RT Box** el costo de cómputo del EKF es **visible** — el lazo cerrado overrunea
en un paso mucho más grueso (16 µs) que el abierto (5–10 µs), porque el procesador embebido es
lento y el EKF sube el TET. En **QUARC sobre PC** el CPU es tan potente que el cómputo del EKF es
**despreciable**: abierto y cerrado topan igual (~5 µs), limitados por el timer/jitter del SO, no
por el cómputo. Es decir, la penalización de cerrar el lazo que se ve claramente en la box
**desaparece** en QUARC por el exceso de potencia del PC — otra manifestación de *compute-bound*
(box) vs *timer/jitter-bound* (QUARC). La única huella del lazo cerrado en QUARC es que colapsa
más severamente una vez cruzado el piso (RTF 0.32 vs 0.68 en 1 µs).

Fidelidad E3-QSM en el punto de operación (2 ms): swing-up llega a Er, captura y balancea firme
(α ±0.12°, θ std 0.67°), incluso más apretado que QHW por ser modelo limpio sin perturbaciones.
