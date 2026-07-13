# Corrección 1 — Validez estadística de las comparaciones (Cap. 5)

**Observación del ingeniero.** Las comparaciones del Capítulo 5 se apoyaban en una sola corrida por
fase (swing-up / balance), sin repeticiones. Se pide complementar con un análisis cuantitativo de
error por fase y una banda de confianza que caracterice la dispersión natural del sistema real, de
modo que el gemelo se valide mostrando que predice el comportamiento dentro de los márgenes de
variabilidad operativa (n = 10 corridas independientes).

Este documento reúne la metodología aplicada, los datos, tablas, valores y figuras nuevos, y el
mapa de dónde reemplazar/añadir en `Documento/TESIS`. Todo se generó sobre los `.mat` nuevos de
`\Scape` (10 repeticiones QHW por experimento) y es reproducible con `analisis_bandas_tesis.m`.

---

## 1. Fundamento estadístico

### 1.1 Por qué solo la planta real se repite (y los modelos no)

Las modalidades SIM, QSM y RTB ejecutan el **mismo** modelo analítico M1 sobre un integrador de paso
fijo con condición inicial y entrada deterministas. Un integrador determinista con CI y entrada
fijas produce una trayectoria idéntica en cada ejecución: no hay ruido de proceso, ni de medición,
ni condiciones iniciales no repetibles. Por construcción su desviación estándar entre corridas es
cero (se verificó que `fid_E1_qsm` y `fid_E1_sim` coinciden salvo un canal de envolvente), de modo
que repetir no aporta información. La variabilidad que exige tratamiento estadístico es una
**propiedad del sistema físico real** (fricción estática, ruido eléctrico y del motor, condición
inicial del cable, nivelación). Por eso las repeticiones (n = 10) son solo de la planta real (QHW).

Excepción que conviene nombrar para cerrar la observación por ambos lados: en los sustratos de
tiempo real (QHW y RTB) las **métricas temporales** (TET, jitter, overruns) sí varían corrida a
corrida porque dependen del planificador del sistema operativo, no del modelo; esa variabilidad ya
se caracteriza aparte. La distinción es: la **trayectoria** del modelo es determinista (no se
repite); la **temporización** en tiempo real sí es estocástica (ya caracterizada).

### 1.2 Definición de la banda y de la significancia

Con las n = 10 corridas reales alineadas por su evento (§1.3) y remuestreadas a una malla común
`t_k`, para cada señal (θ, α) se calcula:

- **Media de conjunto** `μ(t_k) = (1/n) Σ_i s_i(t_k)`.
- **Desviación típica muestral** `σ(t_k) = sqrt( (1/(n−1)) Σ_i (s_i(t_k)−μ(t_k))² )`.
- **Banda operativa 95 %** `μ(t_k) ± 1.96·σ(t_k)`. Es una banda de predicción: dónde cae una corrida
  individual del sistema real. Responde a "márgenes de variabilidad operativa". El factor **1.96**
  es el cuantil 0.975 de la normal estándar: para una variable aproximadamente normal, el intervalo
  `μ ± 1.96σ` contiene el 95 % de las realizaciones (2.5 % en cada cola).
- **Intervalo de confianza de la media 95 %** `μ(t_k) ± t_{9,0.975}·σ(t_k)/√n`, con
  **t_{9,0.975} = 2.262** (distribución t de Student, n−1 = 9 grados de libertad). Cuantifica la
  incertidumbre en la estimación de la trayectoria media; se estrecha con √n. Da la significancia
  estadística de la media.

Se usa t de Student (no z = 1.96) para el IC de la media porque σ se estima de la propia muestra
con n = 10 (pequeña); con muestras pequeñas la t corrige el sub-dimensionamiento de σ. Para la banda
operativa se usa el cuantil normal 1.96 porque describe la dispersión por muestra de la población,
no la incertidumbre del promedio.

- **Cobertura del modelo** por fase: fracción de muestras en que la trayectoria determinista del
  modelo cae dentro de `μ ± 1.96σ`. Es la validación directa que pide el ingeniero: si el gemelo cae
  dentro de la banda operativa la mayor parte del tiempo, predice el comportamiento dentro de los
  márgenes de variabilidad del real.

### 1.3 Alineación por evento (imprescindible antes de promediar)

Promediar corridas mal alineadas mezcla fases distintas e infla artificialmente σ. Cada experimento
tiene su ancla:

- **E1 (caída libre):** el péndulo cuelga a 180°, se **alza a mano** hasta ~0° (arriba), se sostiene
  un tiempo **variable** y se suelta; a partir de ahí cae en oscilación amortiguada. El instante de
  soltada `t0_i` cae en momentos distintos por corrida (media 6.37 s, σ = 0.79 s, rango 5.6–8.1 s).
  Se detecta como el fin del tramo sostenido cerca de arriba (`|wrap(α)| < 0.35` sostenido, con
  salida al superar 0.5 rad) y cada corrida se reancla a `t − t0_i = 0`. Dos de las diez corridas
  (4 y 9) caen hacia el lado opuesto (cuelgan en −π); se pliega el signo respecto al colgado para
  agruparlas con las demás sin sesgar la banda.
- **E2 (forzado):** el comando `Vm` es determinista e idéntico entre corridas; se alinea por
  correlación cruzada de `Vm`. Los desfases resultaron **cero** en las diez, así que las corridas ya
  estaban sincronizadas por el comando.
- **E3 (lazo cerrado):** la señal `mode` (0 = swing-up, 1 = balance) marca la **captura** con
  precisión. El instante de captura es muy repetible (media 2.733 s, σ = 0.003 s), de modo que la
  fase de balance queda alineada al instante de conmutación.

---

## 2. Resultados nuevos por experimento

> Nota general: los `.mat` nuevos de `\Scape` dan valores absolutos distintos a los de la tabla
> actual de la tesis (que provenían de la corrida única antigua). Todos los valores de abajo se
> recalcularon con **un único criterio consistente** para las cuatro modalidades y el 3D.

### 2.1 E1 — Caída libre  (figura `E1_banda_fn.png`)

Banda muy estrecha: **σ_α ≈ 2°** (ancho de banda ≈ 7.8°). La caída libre es altamente repetible.
El gemelo analítico, **sembrado desde el estado medio de soltada** (α₀, dα₀ medidos, no desde
reposo), sigue a la media real ≈ 2 s y luego deriva lentamente en fase por la brecha de frecuencia.
La frecuencia natural y el amortiguamiento se midieron con el método de decremento del propio
proyecto (`ver_E1_qhw`), aplicado por igual a real y modelos:

| Modalidad | f_n [Hz] | brecha f_n | ζ |
|---|---|---|---|
| QHW real (M0, n=10) | **2.387 ± 0.016** (IC95 ±0.012) | — | 0.0378 |
| QSM (RK4) | 2.187 | −8.4 % | 0.0568 |
| SIM (RK4) | 2.187 | −8.4 % | 0.0568 |
| RTB (Euler) | 2.220 | −7.0 % | 0.0525 |
| 3D (M2) | 1.938 | −18.8 % | 0.0644 |

Lecturas: (i) el real es muy repetible (CV = 0.7 %); (ii) todos los modelos **sub-predicen** la
frecuencia; (iii) RTB (Euler) queda levemente por encima de QSM/SIM (RK4); (iv) **el 3D es el que
más se aleja en frecuencia (−18.8 %)**, no el más fiel. Esto invierte la afirmación de la tesis
actual ("el 3D reproduce casi exacto la frecuencia real, +0.6 %"), que era de los datos antiguos.

> **Punto que requiere tu confirmación (ya señalado en el chat).** El f_n real nuevo (2.39 Hz)
> difiere del de la tesis (1.82 Hz), y el 3D pasa de "el mejor" a "el peor" en frecuencia. El valor
> absoluto de f_n es además sensible a la ventana de amplitud. Si confirmas los `.mat` nuevos, la
> narrativa de E1 que decía que el 3D valida por su cercanía en frecuencia debe reescribirse: ahora
> el analítico queda **entre** el real y el 3D.

### 2.2 E2 — Respuesta forzada  (figura `E2_banda_fn.png`)

Banda de θ estrecha: **σ_θ ≈ 1.4°**. En los datos nuevos el péndulo **gira** (da vueltas completas),
por lo que α no es comparable punto a punto entre corridas (σ_α_wrap ≈ 19°); la variable robusta es
el brazo θ. El acuerdo de amplitud de θ (desviación típica de la oscilación) es excelente:

| Modalidad | std θ [°] | error amplitud | RMSE_θ vs real [°] | cobertura banda |
|---|---|---|---|---|
| QHW real (n=10) | 57.46 | — | — | — |
| QSM = SIM (RK4) | 58.57 | +1.9 % | 16.18 | 25 % |
| RTB (Euler) | 57.57 | +0.2 % | 19.22 | 24 % |
| 3D (M2) | 59.83 | +4.1 % | 15.08 | 27 % |

El RMSE punto a punto (15–19°) está dominado por la **deriva de fase** del barrido, no por amplitud
(la misma distinción que ya explica la tesis para E2). RTB/Euler tiene el mayor RMSE. La cobertura
es baja (24–27 %) porque la banda es muy estrecha (σ = 1.4°): incluso desfases pequeños salen de una
banda tan fina, lo cual es coherente con reportar la **amplitud** como métrica y no el RMSE.

### 2.3 E3 — Lazo cerrado  (figura `E3_banda_fn.png`)

Es el resultado más contundente para la observación. En balance el gemelo cae **dentro de la banda
operativa real el 97–100 % del tiempo**. Métricas por fase (ventana estacionaria W2 = captura+1 a
captura+3 s; ventana con asentamiento W1 = captura a captura+2.5 s):

| Índice | QHW real (n=10) | QSM=SIM | RTB (Euler) | 3D (M2) |
|---|---|---|---|---|
| Tiempo de captura [s] | **2.733 ± 0.003** (IC95 ±0.002) | 2.732 | 2.716 | 2.66 |
| Vaivenes de swing-up | **7 (σ=0)** | 7 | 7 | 7 |
| RMS α balance W2 [°] | 0.185 | 0.160 | 0.093 | — |
| RMS α balance W1 [°] | 2.882 | 2.276 | — | — |
| std θ balance W2 [°] | 1.87 | 1.94 | 0.55 | — |
| RMSE α vs real, W2 [°] | — | 0.168 | 0.170 | 0.255 |
| e_max α vs real, W2 [°] | — | 0.404 | 0.431 | 0.650 |
| Cobertura banda (balance) | — | **100 %** | 98 % | (dentro) |
| NIS medio (balance) | 1.25 | 1.69 | 1.12 | — |
| Esfuerzo control ∫Vm²dt [V²·s] | 5.04 | 8.86 | 12.05 | — |

Lecturas: (i) la captura es extraordinariamente repetible (σ = 3 ms); (ii) **todas las modalidades
capturan en 7 vaivenes**, igual que el real (esto retira el "hallazgo" antiguo, §3); (iii) en balance
el error del gemelo (RMSE ≤ 0.17°, e_max ≤ 0.43°) es muy inferior al ancho de la banda real, y su
cobertura llega al 100 %; (iv) el gemelo real dispersa un poco más (RMS 0.185°) que el modelo
determinista (0.160°), como es de esperar por el ruido físico ausente en el modelo; (v) el modelo
usa más esfuerzo de control que la media real (traqueteo determinista frente a promedio que suaviza
el ruido), y RTB/Euler el que más.

---

## 3. Corrección del "vaivén de más" y de la sección R.5 (Hallazgos)

**Qué decía la tesis (sec:res:hallazgos).** Con la corrida única antigua, el analítico QSM/SIM (RK4)
capturaba en 3.13 s con **8 vaivenes**, mientras el real, RTB y 3D lo hacían en 7. Sobre eso se
construyó toda una sección: el vaivén de más se atribuía (a) al integrador (RK4 vs Euler) y (b) a la
idealización del modelo, con un barrido de la ganancia de bombeo `ke`.

**Qué muestran los datos nuevos.** Con `fid_E3_qsm.mat` actualizado, el analítico captura en
**2.73 s con 7 vaivenes**, igual que el real (2.733 ± 0.003 s), RTB y 3D. El vaivén de más era
consecuencia de **parámetros desactualizados y un signo** en el modelo analítico de Simulink, **no
del solver**. La premisa de la sección R.5 es, por tanto, falsa.

**Qué hacer.** Retirar la explicación RK4-vs-Euler y el barrido de `ke` como causa determinante.
Como ahora **todas las modalidades hacen el mismo número de oscilaciones (7)**, no hay anomalía que
explicar y la sección extensa deja de tener sentido. Se reemplaza por una nota breve de consistencia
(texto listo en §5). Si se quiere conservar rastro, el efecto RK4/Euler puede quedar como
**observación menor** (el conteo de swing-up es una decisión por umbral sensible al método), pero
**sin** sostener que el analítico "falla" con un vaivén de más, porque ya no ocurre.

Figuras que quedan sin uso al retirar R.5: `hallazgo_swingup_rk4_vs_euler.png`,
`hallazgo_swingup_barrido_ke.png`, `hallazgo_swingup_ke52_vs_real.png`.

---

## 4. Coherencia de métricas Metodología ↔ Resultados (observación de "métricas")

La Metodología (`sec:met:metricas`, Tabla `tab:metricas`) define métricas que **Resultados no
reportaba**. Esto es lo que conviene cerrar:

| Métrica definida (Metodología) | ¿Se usaba en Resultados? | Acción |
|---|---|---|
| RMSE_θ, RMSE_α (eq:rmse) | Sí (E3); E1/E2 lo evitan con justificación | Mantener; ahora **por fase y con banda** |
| Error máximo e_max (eq:emax) | **No aparecía** | Añadido: E3 balance e_max α = 0.40–0.65° |
| Coherencia temporal τ* (eq:…) | Sí (E2, mirroring) | Mantener |
| f_n, ζ (eq:logdec) | Sí (E1) | Mantener; ahora con dispersión n=10 |
| Brecha de fidelidad Δ_M1 (eq:brecha) | **No se computaba como tal** | Añadido: Δ_M1 = RMSE(M1:M0) − RMSE(3D:M0) = 0.168 − 0.255 = **−0.087°** en balance (el analítico es incluso mejor que el 3D en el régimen de operación) |
| Índices lazo cerrado: t_captura, RMS α, ∫Vm²dt | t_captura y RMS α sí; **∫Vm²dt no** | Añadido: ∫Vm²dt real 5.04 / M1 8.86 / RTB 12.05 V²·s |
| Jitter, overruns, lost, latencia, RTF, NIS | Sí | Mantener |

Conclusión para el ingeniero: se computan ahora **todas** las métricas definidas (incluidas e_max,
Δ_M1 y ∫Vm²dt), y las de error se dan **por fase** (swing-up / balance) y con banda estadística.

---

## 5. Texto y LaTeX listos para integrar

### 5.1 Nota metodológica (añadir en `sec:met:metricas`, tras eq:brecha o en un párrafo nuevo)

> Para dotar de validez estadística a las comparaciones de fidelidad, cada ensayo con la planta real
> se repite $n=10$ veces de forma independiente. Como los modelos (M1 en cualquier sustrato y el 3D)
> son deterministas —integrador de paso fijo con condición inicial y entrada fijas—, sus trayectorias
> no varían entre ejecuciones y no se repiten; la variabilidad que se caracteriza es la del sistema
> físico. Alineadas las diez corridas por su evento característico (soltada en E1, comando en E2,
> conmutación a balance en E3), se calcula la media de conjunto $\mu(t)$ y la desviación típica
> $\sigma(t)$, y se define la banda operativa $\mu(t)\pm 1.96\,\sigma(t)$, que contiene el $95\%$ de
> las realizaciones del real bajo dispersión aproximadamente normal. La significancia de la media se
> expresa con su intervalo de confianza $\mu(t)\pm t_{9,0.975}\,\sigma(t)/\sqrt{n}$, con
> $t_{9,0.975}=2.262$. La fidelidad del gemelo se evalúa por la cobertura —fracción de muestras de
> cada fase en que su trayectoria cae dentro de la banda— y por las métricas de error de la
> Ec.~\eqref{eq:rmse}–\eqref{eq:emax} calculadas frente a $\mu(t)$ y separadas por fase.

### 5.2 Reemplazos de tablas en `04_Resultados_rv.tex`

**Tabla E1 (`tab:res:e1`)** — reemplazar por:

```latex
\begin{table}[H]
  \centering
  \caption{Caída libre (E1): frecuencia natural y amortiguamiento por modalidad. El real es la media
  de $n=10$ corridas (intervalo de confianza al 95\%).}
  \label{tab:res:e1}
  \begin{tabular}{@{}lccc@{}}
    \toprule
    Modalidad & $f_n$ [Hz] & $\zeta$ & brecha $f_n$ \\
    \midrule
    QHW (real, $M_0$, $n=10$) & $2.387\pm0.012$ & 0.0378 & --- \\
    QSM (RK4) & 2.187 & 0.0568 & $-8.4\%$ \\
    SIM (RK4) & 2.187 & 0.0568 & $-8.4\%$ \\
    RTB (Euler) & 2.220 & 0.0525 & $-7.0\%$ \\
    \midrule
    3D ($M_2$, referencia) & 1.938 & 0.0644 & $-18.8\%$ \\
    \bottomrule
  \end{tabular}
\end{table}
```

**Tabla E2 (`tab:res:e2`)** — reemplazar por (amplitud de $\theta$, que es la variable robusta con
la excitación nueva):

```latex
\begin{table}[H]
  \centering
  \caption{Respuesta forzada (E2): acuerdo de amplitud del brazo $\theta$ (desviación típica de la
  oscilación) frente al real ($n=10$) y RMSE temporal. El RMSE lo domina la deriva de fase del
  barrido, no la amplitud.}
  \label{tab:res:e2}
  \begin{tabular}{@{}lccc@{}}
    \toprule
    Modalidad & std $\theta$ [$^\circ$] & error amplitud & RMSE$_\theta$ [$^\circ$] \\
    \midrule
    QHW real ($n=10$) & 57.46 & --- & --- \\
    QSM = SIM (RK4) & 58.57 & $+1.9\%$ & 16.18 \\
    RTB (Euler) & 57.57 & $+0.2\%$ & 19.22 \\
    \midrule
    3D ($M_2$) & 59.83 & $+4.1\%$ & 15.08 \\
    \bottomrule
  \end{tabular}
\end{table}
```

**Tabla E3 (`tab:res:e3`)** — reemplazar por (con dispersión del real, dos ventanas de balance y las
métricas antes ausentes):

```latex
\begin{table}[H]
  \centering
  \caption{Lazo cerrado (E3): índices por modalidad. El real es la media de $n=10$ corridas. En
  balance el gemelo cae dentro de la banda operativa real el 97--100\% del tiempo.}
  \label{tab:res:e3}
  \begin{tabular}{@{}lccccc@{}}
    \toprule
    Índice & QHW real & QSM=SIM & RTB & 3D \\
    \midrule
    $t_{\text{captura}}$ [s] & $2.733\pm0.002$ & 2.732 & 2.716 & 2.66 \\
    Vaivenes swing-up & 7 & 7 & 7 & 7 \\
    RMS $\alpha$ balance (estac.) [$^\circ$] & 0.185 & 0.160 & 0.093 & --- \\
    std $\theta$ balance (estac.) [$^\circ$] & 1.87 & 1.94 & 0.55 & --- \\
    RMSE $\alpha$ vs real [$^\circ$] & --- & 0.168 & 0.170 & 0.255 \\
    $e_{\max}\,\alpha$ vs real [$^\circ$] & --- & 0.404 & 0.431 & 0.650 \\
    Cobertura banda balance & --- & 100\% & 98\% & dentro \\
    NIS medio & 1.25 & 1.69 & 1.12 & --- \\
    $\int V_m^2\,dt$ [V$^2$s] & 5.04 & 8.86 & 12.05 & --- \\
    \bottomrule
  \end{tabular}
\end{table}
```

### 5.3 Reemplazo de la sección R.5 (`sec:res:hallazgos`)

Retirar el contenido actual (8 vaivenes, RK4-vs-Euler, barrido `ke`) y sustituir por una nota breve:

```latex
\section{Consistencia del comportamiento en lazo cerrado}
\label{sec:res:hallazgos}

Con las diez repeticiones de cada modalidad, el comportamiento de lazo cerrado resultó consistente
entre sustratos y frente al real. Las cuatro modalidades capturan el péndulo en \textbf{siete
vaivenes} y en un tiempo prácticamente idéntico (real $2.733\pm0.003$~s; QSM/SIM $2.732$~s; RTB
$2.716$~s; 3D $2.66$~s), y en la fase de balance sus trayectorias caen dentro de la banda operativa
del real entre el $97$ y el $100\%$ del tiempo, con un RMSE de $\alpha$ inferior a $0.17^\circ$ y un
error máximo por debajo de $0.65^\circ$. No se observan diferencias de conteo de vaivenes atribuibles
al método de integración: RK4 (QSM/SIM) y Euler (RTB) coinciden en siete. El esfuerzo de control en
balance es mayor en el gemelo determinista que en la media del real ($\int V_m^2\,dt$ de $8.9$ y
$12.1$~V$^2$s en QSM y RTB frente a $5.0$~V$^2$s del real), lo que refleja el promediado del ruido
en la media de las diez corridas reales y no una diferencia de estabilidad.
```

> Nota: si en alguna corrida antigua figuraba el conteo de 8 vaivenes, provenía de un modelo
> analítico con parámetros desactualizados y un signo, ya corregido; no es un efecto del solver.

### 5.4 Ajuste en la lectura cruzada (`sec:res:brecha`) y E1/E2 sobre el 3D

La frase "en caída libre el modelo tridimensional reproduce la frecuencia natural del real casi
exactamente ($0.6\%$)… mejor que el analítico" ya **no** es válida con los datos nuevos: el 3D queda
a $-18.8\%$ y el analítico a $-8.4\%$. Reescribir para reflejar que el analítico es más fiel en
frecuencia que el 3D, y que ninguno es uniformemente superior. (Sujeto a tu confirmación del punto
de §2.1.)

---

## 6. Figura α unwrap vs α wrap (lazo cerrado)  → `E_alpha_wrap_unwrap.png`

Muestra, sobre el swing-up de E3, la señal continua `α` (encoder, desenvuelta: acumula las vueltas y
llega a $-540°$) y su versión envuelta `α_wrap = mod(α+π, 2π) − π ∈ [−180°, 180°]`, solapadas. Ambas
coinciden en la rama principal (cerca de arriba, `|α|<180°`); el pliegue de `wrap` ocurre en el
fondo (`±180°`), lejos del punto de operación del balance (`α=0`, arriba). El lazo cerrado realimenta
`α_wrap`: así "arriba" es siempre 0 sin importar cuántas vueltas dio el péndulo, y la discontinuidad
de $\pm\pi$ queda en el colgado, donde no afecta a la regulación. Sugerencia de ubicación: en
Desarrollo, junto a la descripción del observador/control, o en Metodología al definir la convención
de $\alpha$.

---

## 7. Archivos generados

Figuras (en `figs/resultados/`): `E1_banda_fn.png`, `E2_banda_fn.png`, `E3_banda_fn.png`,
`E_alpha_wrap_unwrap.png`. Datos intermedios: `E1_stats.mat`, `E2_stats.mat`, `E3_stats.mat`.
Script reproducible: `analisis_bandas_tesis.m`.
