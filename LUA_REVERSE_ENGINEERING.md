# SteveCraft — Lua-only reverse engineering

## Scope

Objetivo: adaptar al jugador de Minecraft Java 1.21.11 (modelo, animaciones, cámara y movimiento) como mod Lua de SM64CoopDX. No se intenta portar el motor de bloques, el renderizador Java ni toda la simulación de Minecraft.

La referencia es una decompilación comunitaria de Minecraft Java 1.21.11, no una publicación oficial de Mojang. La implementación es una adaptación independiente a las APIs Lua disponibles.

## Arquitectura del runtime

El mod no necesita funciones C/C++ personalizadas en el APK. Utiliza:

- `HOOK_BEFORE_PHYS_STEP` para ajustar velocidad horizontal antes del paso de colisión.
- `HOOK_MARIO_UPDATE` para registrar modelo y animación del jugador.
- `smlua_anim_util_register_animation` para clips propios.
- NEWCAM, FirstPersonCamera y funciones Lua de configuración de cámara.
- El solver de colisiones por superficies de SM64.

En el fork Android inspeccionado, `src/game/mario_step.c` llama `HOOK_BEFORE_PHYS_STEP` desde `perform_ground_step` y `perform_air_step`. El hook recibe el estado de Mario y el tipo de paso. SteveCraft cambia solo `m.vel.x/z` y no devuelve una anulación de resultado; por tanto, el motor conserva sus colisiones.

## Movimiento terrestre

Minecraft aplica aceleración relativa al suelo:

`a = movementSpeed × 0.21600002 / friction³`

y arrastre horizontal:

`d = friction × 0.91`

Se usan los valores base de jugador `movementSpeed = 0.1` y fricción de bloque normal `0.6`. SM64CoopDX no tiene materiales de bloques Minecraft, así que este valor es una aproximación global, no una conversión de cada tipo de superficie.

## Movimiento aéreo

Para acciones de salto/caída ordinarias, Minecraft usa aceleración horizontal `0.02` y arrastre `0.91` por tick. Se convierten esos coeficientes a pasos de 30 Hz y se modifican las componentes X/Z antes de que el motor resuelva las colisiones.

## Conversión temporal y espacial

Minecraft simula a 20 ticks/s y el objetivo se actualiza a 30 frames/s. El arrastre se convierte como:

`dragFrame = dragTick^(20/30)`

La aceleración se escala además para conservar la velocidad terminal en unidades SM64 por frame:

`accelFrame = accelTick × scale × (20/30) × (dragTick/dragFrame) × (1-dragFrame)/(1-dragTick)`

La escala del mundo se estima provisionalmente en `160 / 1.8` unidades SM64 por bloque, derivada de la conversión anterior del modelo Steve. Es una aproximación y debe calibrarse en un nivel real antes de afirmar equivalencia exacta.

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

- Gravedad e impulso vertical de salto idénticos a Minecraft.
- Movimiento acuático y lava; los pasos de agua no usan el hook terrestre/aéreo revisado.
- Fricción individual de bloques y modificadores de superficie.
- Escalada, nieve polvo, telarañas, miel, soul sand, elytra, monturas y efectos.
- Colisiones AABB/voxels de Minecraft (se conserva la geometría SM64).
- Cámara exacta de ocho rayos y control de posición/foco.
- Paridad de físicas en multijugador.
- Pruebas en dispositivo Android: CI Lua no confirma gameplay.

## Aceptación

- [ ] Steve se ve vertical y las UV son correctas.
- [ ] Idle, caminar, correr, agacharse y nadar funcionan en el actor.
- [ ] Velocidad y distancia de frenado se calibran en una superficie plana.
- [ ] Control aéreo estable sin atravesar paredes.
- [ ] Giro táctil y cambio de perspectiva funcionan.
- [ ] Las preferencias de cámara se restauran al salir.
- [ ] No se necesita añadir C++ al APK.
