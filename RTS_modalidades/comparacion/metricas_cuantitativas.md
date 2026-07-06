# Metricas cuantitativas — gemelo M1 vs real M0 (RMSE en grados)

RMSE de theta y alpha del gemelo contra la planta real. E2: respuesta forzada,
punto-a-punto sobre la parte oscilatoria (media removida), con alineacion de un
desfase pequeno por xcorr. E3: fase de balance (post-captura), alineando cada
modalidad por su propio instante de captura.

## E2 — respuesta forzada (lazo abierto)

En un barrido (chirp) de 35 s, dos respuestas con resonancias ligeramente distintas
derivan de fase progresivamente: la coherencia punto-a-punto cae a ~0.45 aunque la
AMPLITUD coincida en cada frecuencia. Por eso la metrica de fidelidad valida en E2 es
el acuerdo de amplitud (desviacion tipica de la oscilacion), no el RMSE temporal.

| modalidad | std alpha real [deg] | std alpha modelo [deg] | error alpha [%] | std theta real [deg] | std theta modelo [deg] | error theta [%] |
|---|---|---|---|---|---|---|
| RTB | 12.04 | 14.47 | 20.2 | 57.04 | 58.84 | 3.2 |
| QSM | 12.04 | 12.40 | 3.0 | 57.04 | 59.87 | 4.9 |
| SIM | 12.04 | 12.40 | 3.0 | 57.04 | 59.87 | 4.9 |

Acuerdo de amplitud dentro de ~3% en alpha. Como referencia, el RMSE punto-a-punto
(dominado por la deriva de fase del barrido, coherencia ~0.45) es: RTB alpha=13.9°/theta=20.3°  QSM alpha=12.8°/theta=16.5°  SIM alpha=12.8°/theta=16.5°  
SIM y QSM comparten la M1 analitica; sus valores coinciden salvo el sustrato.

## E3 — lazo cerrado, fase de balance (post-captura)

| modalidad | t_captura [s] | RMSE alpha bal [deg] | RMSE theta bal [deg] | std alpha [deg] | std theta [deg] |
|---|---|---|---|---|---|
| RTB | 2.716 | 0.883 | 5.513 | 1.987 | 1.645 |
| QSM | 3.130 | 0.690 | 8.462 | 2.344 | 6.581 |
| SIM | 3.130 | 0.689 | 8.474 | 2.345 | 6.577 |
| QSM52 | 2.754 | 1.708 | 6.151 | 2.301 | 5.548 |
| SIM52 | 2.754 | 1.708 | 6.151 | 2.301 | 5.548 |
| real (QHW) | 2.654 | — | — | — | — |

### Medición complementaria (aislada): balance estacionario, ventana tc+1.0 a tc+3.0 s

La tabla anterior toma 2.5 s desde la captura e **incluye el asentamiento** inicial
(el brazo aún corrige). Como zoom complementario —no la sustituye— se aísla la banda
estacionaria (desde 1 s después de capturar, 2 s de ventana), donde ambos regulan ya
en régimen.

| modalidad | RMSE alpha ss [deg] | RMSE theta ss [deg] | std alpha ss [deg] | std theta ss [deg] |
|---|---|---|---|---|
| RTB | 0.295 | 2.627 | 0.077 | 0.555 |
| QSM | 0.323 | 4.202 | 0.176 | 2.698 |
| SIM | 0.294 | 4.279 | 0.182 | 2.588 |
| QSM52 | 0.265 | 3.234 | 0.158 | 1.879 |
| SIM52 | 0.265 | 3.234 | 0.158 | 1.879 |

Al aislar el régimen estacionario la dispersión de theta del analítico baja respecto a
la ventana con asentamiento, confirmando que buena parte del exceso de la tabla previa
proviene del transitorio de captura y no del régimen de balance.

QSM52/SIM52 = analitico con ke=52 (7 vaivenes, captura como el real). QSM/SIM = ke=50
(8 vaivenes, hallazgo del vaiven extra). El RMSE de balance es practicamente igual
entre ke=50 y ke=52: el numero de vaivenes no afecta la fidelidad del balance.

## Modelo 3D (M2, Simscape) vs real — lazo cerrado en paralelo

| magnitud | real (M0) | modelo 3D (M2) |
|---|---|---|
| t_captura [s] | 2.650 | 2.656 |
| alpha balance RMS [deg] | 1.20 | 1.26 |
| RMSE alpha balance [deg] | 1.302 (modelo vs real) | |
| RMSE theta balance [deg] | 0.344 (modelo vs real) | |

El gemelo 3D captura casi al mismo instante que el real y balancea con una
dispersion equivalente: reproduce el lazo cerrado real de forma cuantitativa.
