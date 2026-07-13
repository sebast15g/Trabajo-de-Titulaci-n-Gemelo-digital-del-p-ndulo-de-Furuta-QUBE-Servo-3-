# Corrección 1 (v2) — Validez estadística, análisis por fase/zona y contraste de hipótesis

Reemplaza a la v1. Incorpora: (a) corrección del f_n de E1 y del "3D outlier"; (b) auditoría y
arreglo de signos entre modalidades; (c) modalidades separadas y consistentes en todas las figuras;
(d) E2 por segmentos de Vm; (e) E3 por zonas (swing-up / transición / balance); (f) barras
estadísticas con IC/σ para E1, E2, E3; (g) contraste explícito de la hipótesis (Sec. 2.11); (h) mapa
de cambios en Desarrollo, Resultados y Conclusiones. Todo reproducible con `analisis_bandas_tesis.m`.

---

## 0. Correcciones respecto de la v1 (importantes)

1. **f_n de E1 — el 3D NO es un outlier.** En la v1 el 3D salía a −18.8 %; era un artefacto de medir
   f_n promediando toda la cola de la caída (cada modalidad pasa distinto tiempo en cada amplitud, y
   el periodo del péndulo depende de la amplitud). Midiendo el periodo **a amplitud igualada** (o el
   f_n lineal de pequeña amplitud, 8–25°), **todas las modalidades coinciden**: QSM = SIM = RTB = 3D
   = 2.203 Hz, y el real 2.432 Hz. La brecha es **uniforme −9.4 %** y es del modelo, no de ninguna
   modalidad en particular. La figura `E1_periodo_amplitud.png` lo demuestra: las cinco curvas se
   solapan a amplitud grande y solo el real se adelanta ~9 % en pequeña amplitud.

2. **Signos entre modalidades.** Auditoría por correlación con el real: en E3 el **θ del 3D** estaba
   invertido y el **α de QSM y RTB** invertido (la dirección del swing-up es arbitraria y algunas
   modalidades registran α con signo opuesto). Se corrige alineando el signo de **cada señal de cada
   modalidad** al real por correlación (práctica que el propio proyecto ya usa en
   `comparar_real_modelo3d`). En E2 los signos ya coincidían.

3. **Modalidades separadas y consistentes.** Cada modalidad se grafica y tabula por separado: QHW
   real (M0), QSM (RTS QUARC del analítico), SIM (Simulink convencional del analítico), RTB (RT Box),
   3D (M2). QSM y SIM dan trayectoria **idéntica** (mismo M1, mismo RK4; solo cambia el sustrato de
   ejecución), por eso comparten curva rotulada "QSM=SIM", pero son **filas separadas** en las tablas.
   En todos los paneles (α y θ) aparecen las cuatro modalidades.

---

## 1. Fundamento estadístico (igual que v1, resumen)

n = 10 corridas independientes solo de la planta real; los modelos son deterministas (σ=0 por
construcción) y no se repiten. Banda operativa **μ ± 1.96σ** (1.96 = cuantil 0.975 normal → 95 % de
las realizaciones); IC de la media **μ ± 2.262·σ/√n** (t de Student, 9 g.l.). Cobertura = fracción
de muestras de cada fase dentro de la banda. Alineación por evento: soltada (E1), comando Vm (E2),
conmutación `mode` (E3).

---

## 2. E1 — Caída libre  (figuras: `E1_banda.png`, `E1_barras.png`, `E1_periodo_amplitud.png`)

Banda muy estrecha (σ_α ≈ 2°): la caída es altamente repetible. Frecuencia natural y amortiguamiento
medidos **igual para todos** (periodo en el régimen lineal de pequeña amplitud, 8–25°):

| Modalidad | f_n [Hz] | brecha | ζ |
|---|---|---|---|
| QHW real (M0, n=10) | **2.432 ± 0.017** (IC95) | — | **0.0261 ± 0.0006** (IC95) |
| QSM (RTS QUARC, RK4) | 2.203 | −9.4 % | 0.0274 |
| SIM (Simulink conv., RK4) | 2.203 | −9.4 % | 0.0274 |
| RTB (RT Box, Euler) | 2.203 | −9.4 % | 0.0255 |
| 3D (M2) | 2.203 | −9.4 % | 0.0255 |

Lecturas: (i) el real es muy repetible (CV = 0.7 % en f_n); (ii) **todos los modelos convergen al
mismo f_n lineal (2.203 Hz)** — el 3D no difiere de los demás; (iii) la brecha −9.4 % es del modelo
(péndulo real ~9 % más rápido en pequeña amplitud), uniforme; (iv) el amortiguamiento coincide
(ζ ≈ 0.026 en todos). La figura de barras lleva **IC95 del real en f_n y en ζ**. La figura
periodo-vs-amplitud muestra que a amplitud grande (>100°) las cinco curvas se solapan y la separación
solo aparece en pequeña amplitud.

> Esto **corrige** la tabla de la tesis actual (real 1.82, 3D +0.6 % "el más fiel"): con los datos
> nuevos y un método consistente, el 3D no es más fiel que el analítico en frecuencia; todos empatan.

---

## 3. E2 — Respuesta forzada  (figuras: `E2_banda.png`, `E2_segmentos.png`)

Banda de θ estrecha (σ_θ ≈ 1.4°). α gira (da vueltas) → no comparable punto a punto; θ es la variable
robusta. Las cuatro modalidades se muestran con signo alineado. Se analiza el Vm por **tres
segmentos** de carácter distinto:

| Segmento (Vm) | saturación tope | RMSE_θ QSM=SIM | RMSE_θ RTB | RMSE_θ 3D | error amplitud (QSM/RTB/3D) |
|---|---|---|---|---|---|
| Escalones (1–10 s) — choca ±135° | 19 % del tramo | 20.8° | 29.3° | 11.8° | −2.8 % / −10.7 % / +3.0 % |
| Barrido lento-medio (10–24 s) | 0 % | 18.4° | 18.2° | 21.0° | +9.4 % / +16.0 % / +6.1 % |
| Barrido rápido (24–33 s) | 0 % | 7.7° | 7.9° | 7.4° | −2.4 % / −1.7 % / −1.8 % |

Lecturas: (i) en la zona de **escalones que chocan el tope**, el **3D es el más fiel** (RMSE 11.8°,
amplitud +3 %) porque modela el contacto con el límite mecánico, y **RTB/Euler el peor** (29.3°,
−10.7 %); (ii) en el **barrido lento** RTB/Euler **sobreestima** la amplitud (+16 %), el efecto de
inyección de energía numérica del Euler; (iii) en el **barrido rápido** (pequeña amplitud) las cuatro
coinciden (~±2 %). El RMSE temporal (15–20°) lo domina la deriva de fase del barrido, no la amplitud.

---

## 4. E3 — Lazo cerrado por zonas  (figuras: `E3_banda.png`, `E3_zonas.png`)

Controlador híbrido swing-up (bombeo de energía) → conmutación en la banda de captura ±17° → balance
LQI sobre el estado estimado. Se compara la maniobra **completa** y por **tres zonas**: swing-up,
transición (al cruzar 17° hasta asentarse en 3°) y balance estable. Todas las modalidades con signo
alineado.

| Zona / índice | QHW real (n=10) | QSM=SIM | RTB | 3D |
|---|---|---|---|---|
| **Swing-up** captura [s] | 2.733 ± 0.003 (IC95 ±0.002) | 2.732 | 2.716 | 2.676 |
| **Swing-up** vaivenes | 7 (σ=0) | 7 | 7 | 7 |
| **Transición** sobrepico α [°] | 16.6 ± 0.2 | 16.9 | 16.7 | 17.0 |
| **Transición** asentamiento 17°→3° [s] | 0.253 ± 0.004 | 0.284 | 0.104 | 0.094 |
| **Balance** RMS α (regulación) [°] | 0.268 ± 0.128 | 0.160 | 0.093 | 0.088 |
| **Balance** dispersión θ [°] | 2.18 | 1.94 | 0.55 | 0.15 |
| **Balance** NIS medio | 1.25 | 1.69 | 1.12 | — |
| **Balance** esfuerzo ∫Vm²dt [V²·s] | 5.04 | 8.86 | 12.05 | — |

Lecturas: (i) **todas capturan en 7 vaivenes** y en ~2.7 s (esto retira el "hallazgo" del vaivén de
más, §6); (ii) en la **transición**, el **QSM (analítico) es el que mejor iguala el asentamiento del
real** (0.284 vs 0.253 s), mientras RTB y 3D asientan "demasiado limpio" (0.09–0.10 s); (iii) en el
**balance**, el **real dispersa más** (RMS α 0.268°, std θ 2.18°) que los modelos (0.09–0.16°;
0.15–1.94°), porque los modelos no tienen el ruido y la fricción física — el gemelo regula incluso
más fino que el real, no peor. La banda operativa del real acota a los modelos en la fase estable.

---

## 5. Coherencia de métricas Metodología ↔ Resultados (obs. de "métricas")

Se computan ahora **todas** las métricas definidas en `sec:met:metricas` y que Resultados no
reportaba: **error máximo** e_max (E3 balance: 0.40–0.65°), **brecha de fidelidad**
Δ_M1 = RMSE(M1:M0) − RMSE(3D:M0) (≈ −0.09° en balance → el analítico no es peor que el 3D en el punto
de operación), y **esfuerzo de control** ∫Vm²dt (real 5.04 / QSM 8.86 / RTB 12.05 V²·s). Las métricas
de error se dan **por fase/zona** y con banda estadística.

---

## 6. Corrección del "vaivén de más" (R.5) — se retira

Con `fid_E3_qsm.mat` actualizado, el analítico captura en 2.73 s con **7 vaivenes**, igual que real,
RTB y 3D. El "8 vaivenes" antiguo era por parámetros desactualizados y un signo en el modelo de
Simulink, **no por el solver**. Toda la sección R.5 (RK4-vs-Euler, barrido `ke`) pierde premisa y se
reemplaza por una nota breve de consistencia (LaTeX en §8.3). Como observación menor puede mencionarse
que el conteo de swing-up es una decisión por umbral en principio sensible al integrador, pero **sin**
sostener que el analítico "falla", porque ya no ocurre.

---

## 7. Contraste explícito de la hipótesis (Sec. 2.11) — obs. del revisor

**Hipótesis (`sec:marco:hipotesis`):** «La ejecución en tiempo real … modifica de forma medible su
fidelidad respecto de la planta física … y ese efecto se relaciona con el jitter y los overruns …».

**Veredicto: se rechaza en su forma fuerte y se redefine.** La evidencia del Capítulo 5:
- Con el **integrador fijo**, QSM (RTS QUARC) y SIM (simulación convencional) dan trayectoria
  **idéntica** (E1 f_n 2.203 en ambos; E2 amplitud +1.9 %/idéntica; E3 balance idéntico). Es decir, la
  ejecución en tiempo real **por sí misma no modifica la fidelidad**.
- La única diferencia de trayectoria entre sustratos es **RTB (Euler) vs QSM/SIM (RK4)**, y su origen
  es el **método de integración**, no el jitter ni los overruns. De hecho **no hubo overruns** en el
  punto de operación, y el jitter (de microsegundos) no altera la trayectoria de un solver de paso
  fijo.
- Por tanto, el jitter/overruns gobiernan el **determinismo temporal** (Sección de RTS), no la
  fidelidad. La fidelidad la gobierna el **modelo** (brecha ~9 % con el real) y, en segundo orden, el
  **integrador**.

Redacción de la hipótesis redefinida (para la Discusión y Conclusiones): *el sustrato de tiempo real
no modifica de forma medible la fidelidad del gemelo (QSM ≡ SIM; RTB difiere solo por el integrador);
el jitter y los overruns condicionan el determinismo temporal, no la correspondencia con la planta.*

---

## 8. LaTeX listo para integrar

### 8.1 Tabla E1 (`tab:res:e1`)
```latex
\begin{table}[H]\centering
\caption{Caída libre (E1): frecuencia natural (lineal, régimen de pequeña amplitud) y
amortiguamiento por modalidad. El real es la media de $n=10$ corridas (IC 95\%).}
\label{tab:res:e1}
\begin{tabular}{@{}lccc@{}}\toprule
Modalidad & $f_n$ [Hz] & $\zeta$ & brecha $f_n$ \\ \midrule
QHW (real, $M_0$, $n=10$) & $2.432\pm0.017$ & $0.0261\pm0.0006$ & --- \\
QSM (RTS QUARC, RK4) & 2.203 & 0.0274 & $-9.4\%$ \\
SIM (Simulink conv., RK4) & 2.203 & 0.0274 & $-9.4\%$ \\
RTB (RT Box, Euler) & 2.203 & 0.0255 & $-9.4\%$ \\
3D ($M_2$) & 2.203 & 0.0255 & $-9.4\%$ \\ \bottomrule
\end{tabular}\end{table}
```

### 8.2 Tabla E3 (`tab:res:e3`)
```latex
\begin{table}[H]\centering
\caption{Lazo cerrado (E3) por zona. El real es la media de $n=10$ corridas (IC 95\%).}
\label{tab:res:e3}
\begin{tabular}{@{}lcccc@{}}\toprule
Índice & QHW real & QSM=SIM & RTB & 3D \\ \midrule
Captura [s] & $2.733\pm0.002$ & 2.732 & 2.716 & 2.676 \\
Vaivenes & 7 & 7 & 7 & 7 \\
Sobrepico transición [$^\circ$] & $16.6\pm0.2$ & 16.9 & 16.7 & 17.0 \\
Asentamiento $17^\circ\!\to\!3^\circ$ [s] & $0.253\pm0.004$ & 0.284 & 0.104 & 0.094 \\
RMS $\alpha$ balance [$^\circ$] & $0.268\pm0.128$ & 0.160 & 0.093 & 0.088 \\
Dispersión $\theta$ balance [$^\circ$] & 2.18 & 1.94 & 0.55 & 0.15 \\
NIS medio & 1.25 & 1.69 & 1.12 & --- \\
$\int V_m^2\,dt$ [V$^2$s] & 5.04 & 8.86 & 12.05 & --- \\ \bottomrule
\end{tabular}\end{table}
```

(La tabla E2 por segmentos está en §3; su versión LaTeX es análoga, una fila por segmento.)

### 8.3 Reemplazo de R.5 (`sec:res:hallazgos`)
```latex
\section{Consistencia del comportamiento en lazo cerrado}
\label{sec:res:hallazgos}
Con las diez repeticiones, el lazo cerrado resultó consistente entre sustratos y frente al real. Las
cuatro modalidades capturan en \textbf{siete vaivenes} y en un tiempo casi idéntico (real
$2.733\pm0.003$~s; QSM/SIM $2.732$~s; RTB $2.716$~s; 3D $2.676$~s); no hay diferencia de conteo
atribuible al integrador (RK4 y Euler coinciden en siete). En la transición a balance, el analítico
reproduce el asentamiento del real ($0.284$ frente a $0.253$~s) mejor que la RT Box o el 3D, que
asientan más rápido por carecer del ruido y la fricción físicos; en balance, el real dispersa algo más
(RMS de $\alpha$ de $0.268^\circ$) que los modelos ($0.09$--$0.16^\circ$), que regulan más fino al no
tener perturbaciones reales. El esfuerzo de control en balance es mayor en el gemelo determinista que
en la media del real ($8.9$ y $12.1$~V$^2$s en QSM y RTB frente a $5.0$~V$^2$s).
```

### 8.4 Párrafo de contraste de hipótesis (añadir al final de `sec:res:discusion`)
```latex
Con esto puede contrastarse la hipótesis (Sección~\ref{sec:marco:hipotesis}). Su forma fuerte
—que la ejecución en tiempo real modifica de forma medible la fidelidad y que ese efecto se relaciona
con el jitter y los overruns— no se sostiene: con el integrador fijo, QUARC en tiempo real (QSM) y la
simulación convencional (SIM) producen trayectorias idénticas, de modo que el tiempo real por sí mismo
no altera la fidelidad; la única diferencia de trayectoria entre sustratos proviene del método de
integración (Euler en la RT Box frente a Runge--Kutta), no del jitter ni de los overruns, que además
no se produjeron en el punto de operación. La hipótesis se redefine en consecuencia: el sustrato de
tiempo real gobierna el determinismo temporal (jitter, TET, RTF), mientras que la fidelidad la
gobiernan el modelo y, en segundo orden, el integrador, con independencia de la ejecución en tiempo
real.
```

---

## 9. Mapa de cambios por capítulo

### Desarrollo (`04_Desarrollo_rv.tex`)
- Añadir, junto al observador/control, la figura `E_alpha_wrap_unwrap.png` y una frase: el lazo
  realimenta $\alpha_{\text{wrap}}$ para que "arriba" sea siempre 0 y la discontinuidad de $\pm\pi$
  quede en el colgado, fuera del punto de operación.
- Si se menciona la validación 3D↔real, dejar claro que la comparación de fidelidad se cuantifica en
  Resultados con $n=10$ y banda.

### Resultados (`04_Resultados_rv.tex`)
- **§Fidelidad E1:** reemplazar `tab:res:e1` (§8.1) y las figuras por `E1_banda.png`,
  `E1_barras.png`, `E1_periodo_amplitud.png`. Reescribir el texto: el gap es uniforme ~9 % y el 3D no
  es más fiel en frecuencia; añadir que la comparación honesta es a amplitud igualada.
- **§Fidelidad E2:** añadir el análisis por segmentos (§3) con `E2_banda.png` y `E2_segmentos.png`;
  reportar el 3D como el más fiel en la zona de tope y el Euler como el que más sobreestima en el
  barrido lento.
- **§Fidelidad E3:** reemplazar `tab:res:e3` (§8.2) por la versión por zonas; figuras `E3_banda.png` y
  `E3_zonas.png`. Añadir la lectura por zonas (transición y balance).
- **§R.5:** reemplazar por §8.3 (se retira el vaivén de más).
- **§Discusión:** añadir el párrafo de hipótesis (§8.4). Ajustar "brecha ~5 %" a "~9 %".
- Añadir la nota metodológica de banda/n=10 (ver v1 §5.1) en `sec:met:metricas`.

### Conclusiones (`XX_Conclusiones_rv.tex`)
- **Corregir el párrafo de hallazgos** (líneas ~60–68): ya no procede decir que Euler/RK4 "cambia una
  decisión por umbral como el conteo de vaivenes" (ahora todas hacen 7). Sustituir por: las
  diferencias finas entre sustratos son de segundo orden (integrador) y no cambian el conteo de
  vaivenes ni la fidelidad; la comparación por zonas confirma que el analítico reproduce la transición
  y el balance del real dentro de su banda de variabilidad.
- **Actualizar** "cinco por ciento" → "alrededor del nueve por ciento" en la firma dinámica libre.
- **Añadir el veredicto explícito de la hipótesis** (una frase): *la hipótesis de partida
  (Sección~\ref{sec:marco:hipotesis}) se rechaza en su forma fuerte y se redefine: el tiempo real no
  modifica la fidelidad del gemelo (QSM ≡ SIM), sino su determinismo temporal; las diferencias de
  trayectoria entre sustratos provienen del integrador, no del jitter ni de los overruns.*

---

## 11. Addendum v3 — correcciones de α (E2), zonas de E3, θ y respuesta a la hipótesis

### 11.1 E2: α se muestra SIN envolver (corrige la v2)

El wrap de α solo tiene sentido en el lazo cerrado (swing-up+balance), donde el control necesita
"arriba = 0". En E1 (caída libre) y E2 (forzado) α es una señal **continua** del encoder y debe usarse
sin envolver. Al envolverla se creaba un falso "giro/divergencia". Con α **cruda**, en E2 el péndulo
oscila entre 120° y 234° (en torno al colgado 180°, **no gira**) y es **muy repetible entre corridas**:
σ_α ≈ 0.42° (más estrecha aún que θ). Por tanto α **sí** es comparable y es la variable principal de E2
(como en la tesis), junto con θ. Figuras `E2_banda.png` y `E2_corridas.png` regeneradas con α sin
envolver.

Métricas por segmento (RMSE, deg), con signo/nivel alineados al real:

| Segmento | RMSE α (QSM/RTB/3D) | RMSE θ (QSM/RTB/3D) |
|---|---|---|
| Escalones/tope | 21.4 / 19.3 / 11.7 | 20.8 / 29.3 / 11.8 |
| Barrido lento | 6.8 / 11.7 / 7.5 | 18.4 / 18.2 / 21.0 |
| Barrido rápido | 12.2 / 13.0 / 12.5 | 7.7 / 7.9 / 7.4 |

Hallazgo: en el **barrido lento** los modelos **sobrestiman la amplitud de α** (la std de α del real
ahí es ~5°, y los modelos 8–12°, +54 a +140 %) — es la zona de resonancia, donde la brecha de ~9 % en
frecuencia (E1) desplaza el pico. En el **tope** el 3D es el más fiel (modela el contacto) y en el
**rápido** las cuatro coinciden. θ (brazo) sigue mejor en todo el barrido. La media de amplitud se
reporta con la advertencia de que el % explota donde la amplitud real es mínima (resonancia): allí la
métrica robusta es el RMSE absoluto.

### 11.2 E3: métrica correcta por zona (el RMSE de α no vale en swing-up)

Durante el swing-up α salta ±180° en la vista **envuelta**, de modo que el RMSE punto a punto sobre la
señal envuelta es engañoso (72–90°). La solución correcta es calcular las métricas sobre α
**desenvuelta** (continua), que sí es comparable: el swing-up se juzga por sus **eventos** (captura y
vaivenes) y, además, con el RMSE de α desenvuelta por zona (la figura puede seguir mostrándose
envuelta, más legible). RMSE de α (desenvuelta, modelos vs real, deg):

| Zona | QSM=SIM | RTB | 3D |
|---|---|---|---|
| General | 11.4 | 10.2 | 19.1 |
| Swing-up | 24.9 | 22.3 | 41.7 |
| Transición | 6.3 | 4.5 | 7.0 |
| Balance | 0.27 | 0.19 | 0.14 |

Sobre un swing de ±180° con 7 vaivenes, un RMSE de 22–25° (QSM/RTB) es buen seguimiento; el 3D queda
peor (41.7°) porque captura antes (2.676 s). Nota sobre las barras de "RMSE vs real": no llevan barra
del real, porque el error se mide contra el real (real vs real = 0). Resumen por zona (figura
`E3_zonas.png`, 6 paneles):

| Zona | métrica | real (n=10) | QSM=SIM | RTB | 3D |
|---|---|---|---|---|---|
| Swing-up | captura [s] | 2.733±0.003 | 2.732 | 2.716 | 2.676 |
| Swing-up | vaivenes | 7 | 7 | 7 | 7 |
| Transición | asentam. 17°→3° [s] | 0.253±0.004 | 0.284 | 0.104 | 0.094 |
| Balance | RMS α [°] | 0.268±0.128 | 0.160 | 0.093 | 0.088 |
| Balance | dispersión θ [°] | 2.18 | 1.94 | 0.55 | 0.15 |
| Balance | RMSE α vs real [°] | — | 0.30 | 0.24 | 0.26 |

Lectura (que hay que dejar explícita en el texto): **α general es casi idéntico** entre modalidades
(swing-up de 7 vaivenes y captura común; la superposición general está en `E3_banda.png`); **por fases,
el swing-up y la transición coinciden**, y **solo el balance cambia**, porque ahí manda el ruido/la
fricción físicos: el real dispersa más (RMS α 0.27°, σ visible corrida a corrida) y los modelos
deterministas regulan más fino. Esa diferencia de balance es de la planta física, no del modelo.

### 11.3 ¿θ por fases? — recomendación

No es necesario para θ el desglose que sí requiere α. θ es continua (no tiene wrap), así que el punto a
punto vale en todo el registro; basta reportar θ **general** (RMSE ≈ 6.9°, muy buena) y su **dispersión
en balance** (std θ, ya incluida). El comportamiento de θ en swing-up ya se ve en la banda
(`E3_banda.png`). Un desglose por fases de θ añadiría poco.

### 11.4 Signos e inversiones (efecto en tablas)

Las inversiones detectadas (θ del 3D en E3; α de QSM y RTB en E3; plegado conjunto de α y θ en E1) son
de **convención de signo/dirección** y se corrigen alineando cada señal al real por correlación. **No
cambian** las métricas escalares de fidelidad (f_n, ζ, std, RMS, RMSE, captura, vaivenes son
invariantes al signo o se calculan tras alinear), de modo que **las tablas de resultados no cambian**
por este motivo; solo mejora la legibilidad de las figuras y se corrige la banda/media de θ en E1
(σ_θ ≈ 1.5°).

### 11.5 Respuesta a la hipótesis (Sección~\ref{sec:marco:hipotesis})

**Enunciado:** la ejecución en tiempo real modifica de forma medible la fidelidad del gemelo y ese
efecto se relaciona con el jitter y los overruns.

**Respuesta: la hipótesis se RECHAZA en su forma fuerte y se REDEFINE.** Evidencia:
1. Con el integrador fijo, **QSM (tiempo real, QUARC) y SIM (simulación convencional) dan la misma
   trayectoria** en los tres ensayos (E1 f_n 2.203 en ambos; E2 α/θ idénticas; E3 balance idéntico).
   Es decir, la ejecución en tiempo real **por sí misma no modifica la fidelidad**.
2. La única diferencia de trayectoria entre sustratos es **RTB (Euler) vs QSM/SIM (RK4)**, atribuible
   al **método de integración**, no al jitter ni a los overruns; de hecho **no hubo overruns** en el
   punto de operación y el jitter (µs) no altera un solver de paso fijo.
3. Por tanto, jitter y overruns gobiernan el **determinismo temporal** (Sección de RTS), no la
   fidelidad; la fidelidad la gobiernan el **modelo** (brecha ~9 % con el real) y, en segundo orden, el
   **integrador**.

Redacción sugerida (Discusión y Conclusiones): *«La hipótesis no se sostiene en su forma original: el
tiempo real no modifica de forma medible la fidelidad del gemelo (QSM ≡ SIM), sino su determinismo
temporal. La única diferencia de fidelidad entre sustratos proviene del método de integración
(Euler vs Runge–Kutta), no del jitter ni de los overruns. La hipótesis se redefine así:
el sustrato de tiempo real condiciona el determinismo temporal, mientras que la fidelidad depende del
modelo y del integrador, con independencia de la ejecución en tiempo real.»*

---

## 10b. Figuras de corridas individuales (n=5) y corrección del plegado de θ

Se añaden, por experimento, figuras que superponen **5 corridas reales** en α y θ (más su media),
para mostrar de dónde nace la dispersión y cómo varía cada ejecución:

- `E1_corridas.png`: en α las cinco corridas casi se solapan (muy repetible); en θ, tras el plegado
  correcto, se alinean y la variación principal es una corrida ligeramente más lenta.
- `E2_corridas.png`: θ es muy repetible entre corridas; α oscila alrededor del colgado y **diverge**
  entre corridas (por eso no es comparable punto a punto y se usa θ).
- `E3_corridas.png`: el swing-up es casi idéntico entre corridas; en el **zoom de balance** se ve la
  variación corrida a corrida — una corrida (la 4) queda sesgada en +0.5–1° (es la ruidosa, RMS
  0.58°), mientras las demás oscilan cerca de 0 con la cuantización del encoder (±0.5°). Esto explica
  visualmente el intervalo de confianza ancho del RMS de α en balance.

**Corrección aplicada (plegado de θ en E1).** Al plegar por dirección de caída en E1 (para agrupar las
corridas que caen a un lado y al otro) debe invertirse **α y θ juntas**; antes solo se invertía α, lo
que dejaba a las corridas 4 y 9 con θ en fase opuesta e inflaba artificialmente la banda de θ y
achataba su media. Con el plegado correcto, σ_θ de E1 baja a ≈1.5°. La figura `E1_banda.png` y el
`E1_stats.mat` ya están regenerados con esta corrección.

## 10. Archivos generados

Figuras (`figs/resultados/`): `E1_banda.png`, `E1_barras.png`, `E1_periodo_amplitud.png`,
`E1_corridas.png`, `E2_banda.png`, `E2_segmentos.png`, `E2_corridas.png`, `E3_banda.png`,
`E3_zonas.png`, `E3_corridas.png`, `E_alpha_wrap_unwrap.png`.
Datos: `E1_stats.mat`, `E1_fnz.mat`, `E2_seg.mat`, `E3_zonas.mat`, `E3_modzonas.mat`.
Script: `analisis_bandas_tesis.m` (regenera todo; verificado).
