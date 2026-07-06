# Hallazgo — el vaivén extra del swing-up en el modelo analítico (integrador + umbral)

Nota técnica para Resultados. Explica, con evidencia, por qué en el lazo cerrado (E3) el gemelo
**analítico** (QSM y SIM) hace **un vaivén de swing-up de más** (8) frente al RT Box, al modelo 3D y al
real (7), y por qué **NO es un defecto de fidelidad del gemelo**. Scripts:
`SIM_QUARC_RTS/postproceso_comparaciones/{diag_swingup.m, exp_swingup_int.m, fig_swingup_analisis.m}`.

## 1. Observación

En E3, el swing-up de energía captura cuando `|α̂| < 17°`. El número de vaivenes hasta capturar:

| modalidad | integrador | vaivenes | captura |
|---|---|---|---|
| RT Box (RTB) | Euler 0.5 ms | 7 | 2.72 s |
| **QSM / SIM (analítico)** | **RK4 / ode4** | **8** | **3.13 s** |
| Modelo 3D (M2, Simscape) | ode fino | 7 | 2.66 s |
| Real (M0, QHW) | — | 7 | 2.65 s |

El analítico (RK4) es el único que hace 8. En su vaivén penúltimo llega a **27°** (α̂), por encima de la
banda de ±17°, así que no captura, se devuelve (la energía cae de ~27 a ~12 mJ) y captura en el siguiente.

## 2. NO es un error del modelo (evidencia)

- **Fidelidad de lazo abierto:** analítico ≈ real (E1 `f_n` 1.72 vs 1.82 Hz; E2 rangos). El modelo es
  válido en lazo abierto.
- **Planta ≡ modelo del EKF:** `furuta_planta_analitica` y `furuta_f_aug` (generado por
  `derivar_modelo_furuta_EKF`) coinciden a **1.7e-13** (verificado, `verif_ekf_planta.m`). No hay
  inconsistencia planta↔estimador; α̂ sigue a la α física a 0.1° en la captura (`diag_catch_qsm.png`).
- **Balance:** α̂_std, θ_std y NIS del analítico ≈ real (ver tabla de Resultados).
- **Respaldo del gemelo 3D en lazo cerrado** (`respaldo_3D_vs_real_lazocerrado.png`,
  `comparar_real_modelo3d.m`): el modelo 3D corrido en paralelo con el real, cada uno con su EKF+control,
  **captura en 2.66 s = real 2.65 s** (mismos 7 vaivenes), α_balance RMS 1.26° vs 1.20°. El gemelo
  reproduce el swing-up real casi exacto.

Conclusión: el concepto de gemelo es válido; el 3D (que viene del CAD, muy cercano al real) calca al real.
El único que difiere es el **analítico**, y por una razón numérica, no de modelado.

## 3. SÍ es el integrador + el umbral de captura (evidencia)

Aislando variables en un lazo cerrado analítico controlado (`exp_swingup_int.m`), **mismo modelo, mismo
paso 0.5 ms, mismo control, sin retardo, cambiando SOLO el integrador:**

| integrador | vaivenes | captura |
|---|---|---|
| **RK4 (= QSM/SIM/ode4)** | **8** | 3.15 s |
| **Euler (= RT Box)** | **7** | 2.71 s |

- **No es la discretización ni "ponerlo en bloques":** el lazo analítico **ideal** (0.5 ms, sin `Unit
  Delay`, sin EKF) con RK4 ya da 8. La forma en bloques no cambió nada.
- **Es el integrador:** Euler explícito **inyecta un poco de energía numérica por paso** (el mismo efecto
  que se ve en el tope de E2); bombea un pelo más rápido y captura un vaivén antes (7, como el real). RK4
  es conservativo → 8.
- **El conteo está en el filo de la navaja.** Barriendo la ganancia de bombeo `ke` (RK4):

  | ke | 44 | 46 | 48 | **50 (actual)** | **52** | 54 | 56 |
  |---|---|---|---|---|---|---|---|
  | vaivenes | 11 | 10 | 9 | **8** | **7** | 7 | 6 |

  Un **4%** más de bombeo (ke 50→52) pasa de 8 a 7. Por eso una diferencia **sub-1% por vaivén** —la que
  introduce Euler, o el residuo del modelo teórico— decide entre 7 y 8.

## 4. Interpretación para la tesis

El swing-up de energía con umbral de captura fijo es una **decisión por umbral**: si un vaivén entra a la
banda de ±17°, captura; si se queda en 27°, hace uno más. Sobre 7-8 bombeos, una diferencia de fracciones
de porcentaje en la energía por vaivén decide el conteo. El **analítico es el péndulo de Furuta teórico**
(no captura detalles constructivos del QUBE-Servo, como el cable, la histéresis o asimetrías del banco);
integrado con RK4 (fiel), su bombeo queda un pelín por debajo y cae en 8. El **modelo 3D**, derivado del
CAD y por tanto más cercano a la construcción real, y el **RT Box** (Euler, que inyecta energía) caen en 7,
como el real. **Es un efecto numérico/umbral, no una pérdida de fidelidad**: después de capturar, las
cuatro balancean igual (mismo LQI, misma M1).

Este es, de hecho, un resultado fino y reportable: **una decisión por umbral en lazo cerrado es sensible
al integrador aunque el modelo, los parámetros y el controlador sean idénticos.** Refuerza el capítulo de
RTS (el sustrato/integrador importa) sin comprometer la validez del gemelo.

## 5. Convenciones (para no confundir en las figuras)

- **Wrap de α:** RTB usa α **envuelta** (medida y innovación con `wrapd`); QSM usa α **sin envolver**
  (medida incremental; `ekf_step` no envuelve la innovación). Cada uno es internamente consistente. NO
  mezclar; flipear θ solo en la planta desincroniza el EKF (`furuta_f_aug`) y la captura (que usa α̂)
  deja de dispararse — probado.
- **Signo θ vs α independiente:** el real comparte la convención de **θ** con el RT Box (corr +0.975) pero
  tiene **α** con signo opuesto (corr −0.900). Por eso, para las figuras comparativas, θ y α se orientan al
  real **por separado** (por correlación), no como espejo conjunto. El 3D queda con θ y α ambos opuestos
  (lo corrige `comparar_real_modelo3d.m`).

## 6. Opciones

- **Recomendada:** dejar `ke=50` y **reportar este hallazgo** (tablas §1/§3 + figuras). Es honesto y
  defendible: el gemelo es válido (§2), el 7-vs-8 es numérico (§3).
- **Alternativa (si se quiere que las figuras calcen en 7):** subir `ke` a ~52 en el swing-up del
  analítico. Debe hacerse en **SIM y QSM a la vez** (misma M1) para mantener consistencia; RTB no se toca.
  Efecto: analítico captura en 7 como el real (`hallazgo_swingup_ke52_vs_real.png`).

## 7. Figuras
`hallazgo_swingup_rk4_vs_euler.png` (RK4 vs Euler, 8 vs 7), `hallazgo_swingup_barrido_ke.png` (sensibilidad
del conteo a ke), `hallazgo_swingup_ke52_vs_real.png` (ke=52 iguala al real), `diag_swingup_qsm.png`
(energía y umbral), `diag_catch_qsm.png` (α̂≡α en la captura), `respaldo_3D_vs_real_lazocerrado.png`
(gemelo 3D ≈ real, 2.66 vs 2.65 s).


## 8. Confirmación con ke=52, orientación y respaldo cuantitativo (RMSE)

Esta sección amplía el hallazgo sin sustituir lo anterior: se conservan las figuras y
tablas a ke=50 (que documentan el vaivén extra) y se añade la confirmación a ke=52.

**ke=52 (confirmación).** Con el analítico a ke=52 el swing-up hace **7 vaivenes** y captura
en **2.754 s**, igual que el real (2.654 s) y el RT Box; desaparece el vaivén extra. Se
generó el gemelo SIM idéntico al QSM a ke=52 (verificado **bit a bit**, `isequal`, diferencia
máxima 0). Figuras: `comp_E3_{alpha,theta,Vm,alphadot,E}_4mod_ke52.png` y
`comp_E3_{alpha,theta}_vsreal_ke52.png`. Las de ke=50 quedan sin sufijo (`comp_E3_*_4mod.png`).
Decisión editorial: **ke=50 documenta el hallazgo; ke=52 confirma** que basta ~+4 % de bombeo
para igualar el conteo del real.

**Orientación de las figuras (corrección).** En E3, α (y α̇) se orienta al real por el **signo
del mayor vaivén del swing-up**, criterio invariante al sentido de desenvolvimiento; θ (y Vm)
por correlación sobre θ continua. El criterio previo —correlación sobre α **envuelta**— no es
fiable cuando el swing-up supera los 180°: la α continua del analítico se desenvuelve hacia
+180° mientras la del real lo hace hacia −180°, ambas dan correlación envuelta negativa pero
requieren tratamiento opuesto. Eso invertía las curvas de QSM (verde) y SIM (morado). Corregido
en `figuras_comparacion.m`; ninguna curva queda ahora invertida respecto al real.

**RMSE θ/α** (`metricas_cuantitativas.{m,md,mat}`):

- *E2 (respuesta forzada) — amplitud.* En un barrido la coherencia punto-a-punto cae a ~0.45
  por deriva de fase (dos resonancias ligeramente distintas se desfasan a lo largo de 35 s),
  aunque la amplitud coincida en cada frecuencia. La métrica válida es el acuerdo de amplitud
  (desviación típica): α del analítico RK4 (QSM/SIM) **3.0 %** vs real; α del RT Box (Euler)
  **20.2 %**. El Euler **infla la amplitud** de α —la misma inyección de energía numérica que
  decide el vaivén—, lo que enlaza E2 con el swing-up.
- *E3 (lazo cerrado) — balance post-captura.* RMSE de α < 2° en las cuatro modalidades; el RMSE
  de balance a ke=50 y a ke=52 es equivalente ⇒ **el conteo de vaivenes no afecta la fidelidad
  del balance**.
- *3D (M2).* t_captura 2.656 s vs real 2.650 s (6 ms); α balance RMS 1.26° vs 1.20°.

**Encuadre.** Este resultado es un **caso particular** de la dificultad intrínseca de construir
un gemelo fiel del péndulo de Furuta (sistema subactuado, inestable en el punto de operación y
variante). Ver `hallazgo_dificultad_gemelo_furuta.md`.
