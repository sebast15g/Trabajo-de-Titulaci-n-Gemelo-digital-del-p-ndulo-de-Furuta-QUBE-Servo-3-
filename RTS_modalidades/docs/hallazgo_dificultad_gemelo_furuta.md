# Hallazgo — dificultad intrínseca de construir un gemelo fiel del péndulo de Furuta

Nota técnica para Resultados/Conclusiones. Reúne la evidencia de por qué obtener un gemelo
digital *bit-fiel* del péndulo de Furuta con QUBE-Servo 3 es intrínsecamente difícil, y por qué
esa dificultad no invalida el gemelo sino que es una propiedad del sistema. El hallazgo del
vaivén extra (`hallazgo_swingup_integrador.md`) es un caso concreto de esta dificultad.

## 1. Por qué el sistema es difícil de replicar

El péndulo de Furuta es **subactuado** (2 grados de libertad —brazo θ y péndulo α— con un solo
actuador sobre θ), **fuertemente no lineal** (la matriz de inercia depende de α; hay términos de
Coriolis y centrífugos con sin 2α) y su equilibrio de trabajo α=0 (arriba) es un **punto de
silla inestable**: el jacobiano linealizado tiene un autovalor real positivo. De aquí tres
consecuencias para el modelado como gemelo:

1. **Sensibilidad exponencial en el punto de operación.** En lazo abierto, cualquier discrepancia
   planta↔gemelo cerca de α=0 crece de forma exponencial. Solo el lazo cerrado la acota. Por
   tanto la fidelidad únicamente puede evaluarse de forma limpia (a) en lazo abierto lejos del
   equilibrio (E1 caída libre, E2 forzado en torno al colgado) o (b) en lazo cerrado con el
   control activo. No existe un régimen abierto en torno a α=0 donde comparar.

2. **El swing-up como acumulador de error.** El swing-up basado en energía bombea a lo largo de
   7–8 vaivenes hasta que |α̂| entra en la banda de captura de ±17°. Es un proceso **integral**:
   diferencias de energía por vaivén inferiores al 1 % se acumulan y son resueltas por un umbral
   fijo. En consecuencia, un resultado **discreto** (7 vs 8 vaivenes) es hipersensible a (i) el
   integrador —Euler inyecta un poco de energía numérica por paso, RK4 es conservativo— y (ii)
   cualquier detalle constructivo no modelado que altere el balance de energía por ciclo.

3. **Planta variante.** El QUBE-Servo 3 presenta efectos constructivos ausentes del modelo
   analítico: histéresis del cable/jack, acoplamiento del conector USB-C (artefacto del banco),
   stiction y deriva térmica del motor. El resultado es que los parámetros efectivos **derivan
   entre corridas**; no hay una planta M0 fija a la que ajustar bit a bit.

## 2. Evidencia de que el concepto de gemelo sí es válido

La dificultad es intrínseca, no un fallo del gemelo. La evidencia de validez es cuantitativa:

- **Lazo abierto.** E1: frecuencia natural del péndulo 1.72 (gemelo) vs 1.82 Hz (real), ~5.5 %.
  E2: acuerdo de amplitud de α dentro del **3.0 %** para el analítico RK4 (`metricas_cuantitativas.md`).
- **Consistencia interna planta↔estimador.** `furuta_planta_analitica` ≡ `furuta_f_aug` (modelo
  del EKF) a **1.7e-13** (`verif_ekf_planta.m`).
- **Gemelo 3D (derivado del CAD) en lazo cerrado.** Corrido en paralelo con el real, cada uno con
  su EKF+control: captura en **2.656 s vs 2.650 s** del real (6 ms) y α de balance RMS **1.26° vs
  1.20°** (`comparar_real_modelo3d.m`, `metricas_cuantitativas.md`).
- **Balance E3.** RMSE de α < 2° en las cuatro modalidades tras la captura.

## 3. Síntesis

Un gemelo fiel en lazo abierto (~3–5 %) puede, aun así, diferir en una **decisión por umbral**
en lazo cerrado, porque la dinámica subactuada e inestable amplifica errores pequeños a través
del swing-up acumulativo. El modelo 3D (más cercano a la construcción) y el sustrato Euler caen
en 7 vaivenes como el real; el analítico con RK4 cae en 8. La diferencia es **numérica y de
umbral** —cuantificada: subir el bombeo ke de 50 a 52 (~+4 %) pasa de 8 a 7— y **no** una pérdida
de fidelidad: tras capturar, las cuatro modalidades balancean igual.

El aporte para la tesis es doble. Primero, **la fidelidad de un sistema subactuado e inestable no
queda capturada solo por métricas de lazo abierto**: el transitorio de lazo cerrado expone una
sensibilidad al integrador y al umbral que persiste aunque el modelo, los parámetros y el
controlador sean idénticos. Segundo, esto **justifica el estudio multi-sustrato** (SIM, QSM, QHW,
RTB): el sustrato —integrador y temporizador (capítulo de RTS)— no es neutro para un sistema de
esta clase, y demostrarlo requiere correr el mismo gemelo sobre sustratos distintos.

## 4. Referencias cruzadas

`hallazgo_swingup_integrador.md` (el vaivén extra como caso concreto), `metricas_cuantitativas.md`
(RMSE E2/E3/3D), `verif_ekf_planta.m` (planta≡EKF), `comparar_real_modelo3d.m` (3D≈real),
figuras `hallazgo_swingup_{rk4_vs_euler,barrido_ke,ke52_vs_real}.png` y
`respaldo_3D_vs_real_lazocerrado.png`.
