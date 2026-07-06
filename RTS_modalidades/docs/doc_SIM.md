# Modalidad SIM — Sim normal (offline) · recopilación

Modalidad **libre, sin tiempo real**: el mismo modelo M1 corre en Simulink en modo *Normal* (offline) en
el PC, tan rápido como el CPU permita. Es la **cota "sin restricción"** del estudio de RTS. Corridas
simples, sin ajustes ni problemas. Datos en `SIM_QUARC_RTS/E1E2E3_sim_normal/`.

## 1. Montaje

Los modelos `E1_SIM.slx`, `E2_SIM.slx`, `E3_SIM.slx` son los mismos de QSM pero en modo Normal, con solver
**fixed-step ode4 a 2 ms** (mismo que las demás modalidades). La planta es `furuta_planta_analitica.m`
(RK4 interno). Los bloques QUARC de RTS (`System Time`, `Computation Time`) son n/a aquí (se dejan o se
desconectan; no afectan). El `.mat` de fidelidad lo escribe el propio `To File`.

## 2. RTS — solo RTF

La única métrica de RTS que aplica es el **RTF = tiempo_modelo / tiempo_pared**, medido con `tic/toc`
alrededor de `sim()` en **`run_sim_normal.m`**. TET, overruns y jitter son **n/a** (no hay kernel de tiempo
real). Resultados: RTF ≫ 1 — **E1 ≈ 12.3, E2 ≈ 35.4, E3 ≈ 15.4** (el RTF incluye el overhead fijo de init
de Simulink, así que es un límite inferior conservador).

## 3. Fidelidad

Como usa el **mismo modelo M1 que QSM** y es determinista, la trayectoria de SIM es **idéntica a QSM**
(E1 f_n 1.724 Hz, E2 α ∈ [123.6, 225.1]°, E3 captura 3.13 s / balance 79.1% / NIS 1.50). Confirma que el
sustrato no cambia la fidelidad: SIM y QSM comparten M1 y solver, y solo difieren en si hay o no
restricción de tiempo real. Sirve como control (misma M1, sin tiempo real) frente a QSM (misma M1, con
tiempo real): su delta aísla el efecto puro de la RTS.

## 4. Scripts

`run_sim_normal.m` (fuerza modo Normal, cronometra, guarda `rt_E*_sim.mat` con solo el RTF). Comparte
`furuta_planta_analitica.m`, `ekf_step.m`, `setup_swingup.m` con QSM.
