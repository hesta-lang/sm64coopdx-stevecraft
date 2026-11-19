# SteveCraft — Lua-only reverse engineering

## Scope

Objetivo: adaptar al jugador de Minecraft Java 1.21.11 (modelo, animaciones, cámara y movimiento) como mod Lua de SM64CoopDX. No se intenta portar el motor de bloques, el renderizador Java ni toda la simulación de Minecraft.

La referencia es una decompilación comunitaria de Minecraft Java 1.21.11, no una publicación oficial de Mojang. La implementación es una adaptación independiente a las APIs Lua disponibles.

## Arquitectura del runtime

El mod no necesita funciones C/C++ personalizadas en el APK. Utiliza:

- `HOOK_MARIO_UPDATE` para detectar doble toque hacia delante después de calcular la entrada de control y actualizar el sprint.
- `HOOK_BEFORE_SET_MARIO_ACTION` para sustituir los saltos dobles/triples de Mario por el salto ordinario.
- `HOOK_ON_SET_MARIO_ACTION` para inicializar el impulso vertical de Steve y el impulso de salto corriendo.
- `HOOK_BEFORE_PHYS_STEP` para aplicar las velocidades adaptadas antes de la resolución de colisiones.
- `HOOK_MARIO_UPDATE` para actualizar la velocidad vertical posterior al paso.
- NEWCAM, FirstPersonCamera y funciones Lua de configuración de cámara.
- El solver de colisiones por superficies de SM64.

En el fork Android inspeccionado, `src/game/mario_step.c` invoca `HOOK_BEFORE_PHYS_STEP` desde `perform_ground_step` y `perform_air_step`. SteveCraft no devuelve un resultado de paso desde ese hook; por tanto, no cancela el solver nativo de suelo/pared/techo.

## Correr (sprint)

Minecraft Java 1.21.11 activa el sprint en `LocalPlayer.aiStep()` mediante tecla sprint o doble toque hacia delante. SteveCraft implementa el segundo método con el ángulo de entrada y la orientación de Mario:

- Ventana del segundo toque: 11 frames de SM64 a 30 Hz (aproximación a 7 ticks de Minecraft).
- La velocidad base se multiplica por 1.3, equivalente al modificador de velocidad sprint `+0.3` de `LivingEntity.setSprinting(true)`.
- El sprint termina cuando se deja de introducir movimiento hacia delante.
- La animación `steve_mc_run` se selecciona mientras se mantiene el estado de sprint.

La entrada se calcula a partir de `intendedMag`, `intendedYaw` y `faceAngle.y`; es una aproximación al sistema de teclado/ClientInput de Minecraft, adaptada al joystick de SM64CoopDX.

## Salto y gravedad

La referencia es `LivingEntity.jumpFromGround()` y `Entity.applyGravity()`:

- Impulso vertical del jugador: 0.42 bloques/tick.
- Gravedad base: 0.08 bloques/tick².
- Arrastre vertical ordinario: 0.98 por tick.
- El salto corriendo suma 0.2 bloques/tick de velocidad horizontal en la dirección del yaw del jugador.
- `HOOK_ON_SET_MARIO_ACTION` reemplaza el impulso vertical nativo de Mario al entrar en `ACT_JUMP`.
- `HOOK_BEFORE_PHYS_STEP` aplica la velocidad vertical convertida a 30 Hz, y conserva el solver de colisiones SM64.
- Las transiciones `ACT_DOUBLE_JUMP` y `ACT_TRIPLE_JUMP` se redirigen a `ACT_JUMP` para evitar el doble/triple salto de Mario.

Se convierten los coeficientes verticales de 20 ticks/s a 30 actualizaciones/s mediante la misma conversión discreta usada para el movimiento horizontal. La escala espacial sigue siendo provisional; por eso la altura y duración del salto necesitan calibración dentro del APK.

## Movimiento terrestre y aéreo

Minecraft aplica aceleración relativa al suelo:

`a = movementSpeed × 0.21600002 / friction³`

y arrastre:

`d = friction × 0.91`

Se usan velocidad base de jugador 0.1, fricción genérica 0.6 y el multiplicador de sprint 1.3 cuando procede.

En el aire, Minecraft usa entrada horizontal 0.02 y arrastre 0.91. La entrada no nula incluye el factor 0.98 de `LocalPlayer.modifyInput()`.

## FOV de sprint

`AbstractClientPlayer.getFieldOfViewModifier()` calcula el modificador a partir de la velocidad relativa. Con el modificador sprint +30%, el factor objetivo es:

`(1.3 + 1.0) / 2.0 = 1.15`

- Primera persona: `gFirstPersonCamera.fov` está expuesto a Lua; SteveCraft aplica 1.15× e interpola con el factor temporal de `GameRenderer`.
- Tercera persona: el Lua binding expone campos de posición/foco de `LakituState`, pero no FOV editable; tampoco se encontró un setter arbitrario implementado en el fork. Se utiliza el preset existente `CAM_FOV_APP_60` durante sprint y `CAM_FOV_DEFAULT` al dejar de correr. Es un cambio visual funcional previsto, pero no es la proporción exacta 1.15×.

## Conversión temporal y espacial

Minecraft simula a 20 ticks/s y el objetivo se actualiza a 30 frames/s. El arrastre se convierte como:

`dragFrame = dragTick^(20/30)`

La aceleración se escala para conservar la velocidad terminal en unidades SM64 por frame:

`accelFrame = accelTick × scale × (20/30) × (dragTick/dragFrame) × (1-dragFrame)/(1-dragTick)`

La escala se estima provisionalmente en `160 / 1.8` unidades SM64 por bloque, derivada de la conversión anterior del modelo Steve. Debe calibrarse en un nivel real.

## Cámara

Minecraft interpola el foco y la altura de ojos, calcula orientación yaw/pitch, mueve el brazo de cámara y acorta distancia con ocho rayos. La API Lua actual no permite escribir la posición/foco de Lakitu, así que no puede reproducir el algoritmo completo de `Camera` desde Lua.

La implementación actual ofrece:
- Primera persona mediante FirstPersonCamera.
- Tercera persona mediante NEWCAM.
- Giro táctil Android mediante el sistema TOUCH_MOUSE existente.
- Colisiones de cámara mediante NEWCAM.

No es un port exacto de la cámara Java; la perspectiva frontal se obtiene orbitando alrededor de Steve, no con un preset garantizado.

## Modelo y animación

El actor DynOS está generado con dimensiones y UV del PlayerModel Java 1.21.11. Lua registra clips basados en HumanoidModel y AnimationUtils: idle, caminar, correr, agacharse, caminar agachado y nadar. Se mapean al esqueleto de SM64 para mantener compatibilidad con el motor.

## Pendiente

- Calibrar la escala mundial y la altura/duración del salto en Android.
- Confirmar doble toque hacia delante en el control táctil del dispositivo.
- Confirmar que el impulso horizontal del salto corriendo conserva dirección y no excede velocidad en cambios bruscos de yaw.
- Mejorar el FOV de tercera persona cuando el binding Lua exponga un valor arbitrario editable.
- Movimiento acuático y lava; los pasos de agua no usan el hook terrestre/aéreo revisado.
- Fricción individual de bloques y modificadores de superficie.
- Escalada, nieve polvo, telarañas, miel, soul sand, elytra, monturas y efectos.
- Colisiones AABB/voxels de Minecraft (se conserva la geometría SM64).
- Paridad de físicas en multijugador.
- Pruebas reales en Android: CI Lua no confirma gameplay.

## Aceptación

- [ ] Steve se ve vertical y las UV son correctas.
- [ ] Idle, caminar, correr, agacharse y nadar funcionan en el actor.
- [ ] Doble toque hacia delante activa el sprint y soltarlo lo desactiva.
- [ ] El salto normal alcanza una altura y duración cercanas a Minecraft tras calibrar escala.
- [ ] El salto corriendo añade impulso horizontal en la dirección correcta.
- [ ] La colisión con suelo, pared y techo permanece estable.
- [ ] El FOV aumenta al correr y vuelve al valor normal al dejar de correr.
- [ ] Giro táctil y cambio de perspectiva funcionan.
- [ ] Las preferencias de cámara se restauran al salir.
- [ ] No se necesita añadir C++ al APK.
