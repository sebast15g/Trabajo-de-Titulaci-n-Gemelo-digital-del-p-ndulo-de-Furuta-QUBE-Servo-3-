# Protocolo de calibración del modelo (alta fidelidad) — Furuta QUBE-Servo 3

Define cómo calibrar correctamente los parámetros físicos del modelo contra el real, como paso previo al gemelo de alta fidelidad. Citas `[n]` según `fuentes_bibliograficas_proyecto.md`.

## 0. Principios (por qué así y no de otra forma)

- **Excitación aislada por parámetro.** Cada parámetro se identifica con un experimento que **excita ese efecto** y silencia los demás. Calibrar "todo a la vez" desde una corrida de **balanceo** es **inválido**: en balanceo θ y θ̇ casi no se mueven → la rigidez del cable y la fricción **no se excitan** (regresor mal condicionado). *Evidencia:* `calibrar_modelo.m` sobre 4 balanceos explicó solo **7%** de `d̂` y dio `kc` 290× el real.
- **Medir, no inferir desde `d̂`.** La perturbación `d̂` del EKF es un **cajón de sastre** (absorbe estructura no modelada y escalados): no es un par físico limpio (sale ~0,15 N·m, 65× el par del motor). No sirve como señal de calibración. Se mide el par real (vía `τ=kt·Vm/Rm`) o se observa la dinámica libre.
- **Validar en datos independientes** [13]: los parámetros se identifican en unas corridas y se **validan en otra distinta** (error de predicción a horizonte corto, no en la misma data del ajuste).
- **Parsimonia** [13]: el modelo ya tiene la estructura (cable resorte, Coulomb+viscoso por junta, motor). Calibrar = afinar esos coeficientes, no añadir términos.

## 1. Cable del encoder en θ: rigidez `kc` y reposo `θ0` (+ fricción seca del brazo)

- **Excita:** posición del brazo θ. **Silencia:** velocidad/inercia (cuasi-estático) y el péndulo (déjalo colgando fijo o retíralo).
- **Procedimiento:** mueve el brazo θ **muy lento** (triángulo, θ̇≈0) por su rango, en ambos sentidos; loguea `Vm` y `θ`. Par aplicado `τ ≈ kt·Vm/Rm` (a θ̇≈0 no hay viscoso ni inercia).
- **Extrae:** grafica `τ` vs `θ` → es un **lazo de histéresis**. La **pendiente** = `kc`; la **media-altura** del lazo = `Tdry_th` (fricción seca total del brazo); el centro = `θ0`.
- **Estado:** YA HECHO (`identificacion_cable_theta.m`, 3 corridas v2 → `kc=1,19e-3`, `Tdry_th=0,71e-3`). Refinar solo si la validación (§6) lo pide. Ref. del cable de este encoder [9].

## 2. Fricción del brazo: viscoso `Dr` y Coulomb `Tdry_th` (confirmación)

- **Excita:** velocidad del brazo θ̇. **Silencia:** el péndulo (colgando/retirado) y la transitoria (régimen permanente).
- **Procedimiento:** lleva el brazo a **velocidad constante** a varios valores (lazo abierto con `Vm` constante, espera el régimen), loguea `Vm`, `θ̇`. Par mecánico `τ_mec = kt·Vm/Rm − km·θ̇` (resta la fcem). Resta también el cable `kc·(θ−θ0)`.
- **Extrae:** `τ_mec` vs `θ̇` → recta por tramos: **ordenada** = `Tdry_th` (Coulomb), **pendiente** = `Dr` (viscoso). Modelo de fricción seca+viscosa [10]; flujo tipo barrido par–velocidad [16]; mapeo a los 4 parámetros del bloque Simscape *Rotational Friction* [20].

## 3. Amortiguamiento del péndulo: Coulomb `Tc_alpha` y viscoso `Dp`

- **Excita:** oscilación libre del péndulo. **Silencia:** el motor (apagado) y el brazo (bloqueado).
- **Procedimiento:** con el motor off y el brazo fijo, desplaza el péndulo y **déjalo oscilar libre**; loguea `α`.
- **Extrae:** el **decaimiento** de la envolvente: caída **lineal** ⇒ Coulomb (`Tc_alpha`), caída **exponencial** ⇒ viscoso (`Dp`) (decremento logarítmico). En el Furuta la fricción de α es dominada por Coulomb y pequeña [12] (`Tc_alpha~6,1e-6`, `Dp≈0`).

## 4. Inercias

- **`Jp` (péndulo):** de la geometría (`mp`, `Lp` medidos) → `Jp_cm=(1/12)mp Lp²`. Confiable, no calibrar.
- **`Jr` (brazo+rotor):** dos vías cruzadas — (a) del **CAD** (`Jr_desde_CAD.m` → 1,38e-4); (b) con `kc` conocido, el brazo (péndulo retirado) es un **oscilador torsional** de `ωn=√(kc/Jr)` → mide su frecuencia natural → `Jr=kc/ωn²`. Que ambas coincidan valida `Jr`.

## 5. Motor DC (`Rm`, `kt`, `km`)

- Del **manual** (Tabla 2.2) [15]; `km=kt`. Verificación opcional: ensayo de par/corriente en bloqueo. Su **fricción mecánica** ya está incluida en `Tdry_th` (§1–2), **no** sumarla aparte.

## 6. Validación (el paso que faltaba)

- Haz **una corrida independiente RICA EN EXCITACIÓN** (no usada en la identificación): mueve la referencia de θ con un **chirp/escalones/PRBS** (péndulo colgando o retirado), loguea `Vm`, `θ`, `α`.
- **Métrica:** alimenta el modelo (analítico o Simscape) con el `Vm` logueado y compara su salida con la medida → **error de predicción** a horizonte corto (1–N pasos). Con buenos parámetros, el error de predicción baja y el `d̂` del EKF en esa corrida se reduce respecto a los valores actuales.
- Es la validación cruzada de Ljung [13]: identificar en unas corridas, validar en otra.

## 7. Dónde se aplica la calibración

1. `parametros_furuta.m`: `p.kc`, `p.theta0`, `p.Tdry_th`, `p.Dr`, `p.Tc_alpha`, `p.Dp`, `p.Jr`.
2. **Re-correr `derivar_modelo_furuta_EKF.m`** → re-hornea `furuta_f_aug`/`furuta_Fc` con los nuevos valores.
3. **Modelo 3D/Simscape:** poner los MISMOS valores en el bloque *Rotational Friction* del brazo (Coulomb=`Tdry_th`, viscoso=`Dr`) y del péndulo (`Tc_alpha`), y en el resorte del cable (`kc`, `θ0`). Así la planta digital y el modelo del observador comparten física.

## 8. Alternativa: identificación conjunta automática

Si en vez de tests aislados quieres un ajuste conjunto sobre una corrida rica en excitación:
- **Simulink Design Optimization → Parameter Estimation** sobre el modelo Simscape (parámetros como variables), o **System Identification → grey-box** (`idnlgrey`/`nlgreyest`). Optimizan todos los parámetros para minimizar el error entrada-salida. Requiere excitación persistente y buena identificabilidad; más potente pero con riesgo de mínimos locales. Recomendado solo para **refinar** tras la identificación aislada (§1–5), no para sustituirla.

## Resumen operativo

Lo que ya tienes (cable `kc`, fricción seca) viene de identificación aislada correcta — probablemente ya es bueno. Lo que **falta** para "calibración válida" es: (a) confirmar `Dr`/`Tc_alpha`/`Jr` con sus tests si hace dudar la validación, y sobre todo (b) **la corrida de excitación de validación (§6)** que mide objetivamente la fidelidad del modelo calibrado contra el real. Sin esa validación, no hay "calibración comprobada".
