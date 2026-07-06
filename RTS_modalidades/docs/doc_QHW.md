# Modalidad QHW — QUARC-real (planta física, = M0) · recopilación

Modalidad de **la planta real bajo control en tiempo real**: el QUBE-Servo 3 físico conectado al kernel
QUARC por la **HIL API** de Quanser (`HIL Initialize`, `HIL Read Encoder`, `HIL Write Analog`). Es la
**referencia M0** contra la que se mide la fidelidad de las otras tres. Corridas simples, sin barrido ni
ajustes especiales: la planta física siempre corre en tiempo real. Datos en
`SIM_QUARC_RTS/{E1_QHW,E2_QHW,E3_QHW}`.

## 1. Montaje

Mismo esquema de Simulink/QUARC que QSM, pero la planta simulada se reemplaza por el I/O físico (HIL): el
encoder entrega θ y α, y el analógico escribe Vm al motor. Esquemáticos en `E*_QHW_SIMULINK.png`; scopes
de ángulos en `E*_scope_*.png` / `*_scope_theta_alpha.png`. En E3 el retardo del lazo lo introduce el
propio I/O físico (no hace falta el `Unit Delay z⁻¹` de QSM/SIM). **Signo del actuador: aquí SÍ va el `−1`
de `For +ve CCW`** (convención del hardware Quanser).

## 2. Consideraciones (pocas, por ser corridas directas)

- **E1 (caída libre):** el péndulo se **levanta a mano** hasta cerca del invertido y se suelta; el log trae
  un preámbulo de sujeción que hay que **recortar** (desde la soltada) antes de estimar `f_n`/ζ. Lo hace
  `ver_E1_qhw.m` / los overlays (detección del fin del "hold" y del primer cruce del colgado).
- **Convención de α:** el encoder da α con reposo (colgado) ≈ 180°; la comparación con el modelo usa
  `α_real ↔ π − α_modelo` cuando aplica (verificado: en E1 la convención salió **directa**, sin inversión).
- **No hay estado "verdadero"** aparte del encoder: `theta/alpha` = `theta_meas/alpha_meas`; las velocidades
  se toman del EKF o se derivan en post.

## 3. RTS

- **RTF = 1** por construcción (planta física en tiempo real). No hay barrido de paso (la planta no se
  puede acelerar/ralentizar).
- **TET** medio ~8–10 µs (bloque `Computation Time`). **Jitter ~36–70 µs**: la **tarjeta HIL del QUBE
  aporta un *hardware timebase*** que disciplina el muestreo del lazo — por eso QHW tiene mucho menos
  jitter que QSM (~320 µs, solo timer de software), aunque compartan el mismo kernel QUARC. Coincide con la
  recomendación de Quanser de usar un hardware timebase para Ts ≤ 2 ms.

## 4. Resultados (referencia de fidelidad M0)

- **E1:** f_n=1.818 Hz, ζ=0.0390.
- **E2:** θ ∈ [−136, 136]°, α ∈ [124.1, 234.1]°.
- **E3:** captura 2.65 s, balance 82.3%, α̂_std 1.12°, θ_std 3.14°, NIS 1.52. El balance real es
  reproducido casi exactamente por QSM.

## 5. Layout y scripts

QHW E1/E2 (6 filas): `[t, seq, t_model, θ, α, Vm]`. QHW E3 (14 filas): `[t, seq, θm, αm, Vm, θ̂, α̂, θ̇̂,
α̇̂, d̂, nis, mode, E, θref]` — **`mode` es la fila 12** (binaria) y la fila 13 es E (mJ); decodificado por
estadísticas para no confundir canales. Carga con `cargar_log_quarc.m`; verificación con `ver_E1_qhw.m` y
los overlays `overlay_qhw_rtb.m`.
