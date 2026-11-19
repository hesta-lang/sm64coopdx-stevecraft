# SteveCraft 64

Mod Lua para **SM64CoopDX Android** que sustituye al jugador por Steve de Minecraft Java 1.21.11, con modelo cúbico, skin clásica, animaciones adaptadas, cámara en primera/tercera persona y movimiento inspirado en Minecraft.

## Versión

**0.12.0-alpha** — runtime Lua-only: el comportamiento de Steve se ejecuta en Lua y no requiere integrar C++ personalizado en el APK.

## Implementación Lua

- El modelo 3D se genera como recursos estáticos DynOS compatibles con SM64CoopDX.
- `character.lua` registra el modelo Steve en el jugador local y sincroniza el ID del modelo.
- `animations.lua` registra clips para idle, caminar, correr, agacharse, caminar agachado y nadar, adaptados de HumanoidModel y AnimationUtils. La animación de correr se activa con el estado de sprint.
- `physics.lua` adapta aceleración, fricción, sprint, salto, gravedad y salto corriendo con fórmulas de Minecraft Java 1.21.11. Mantiene el solver de colisiones de SM64.
- `camera.lua` configura NEWCAM para la tercera persona con giro táctil y colisiones de superficies; la primera persona utiliza FirstPersonCamera.

## Correr, saltar y FOV

- **Correr:** doble toque hacia delante, siguiendo el comportamiento de `LocalPlayer.aiStep()`. El sprint aumenta la velocidad base un 30%, como el modificador de `LivingEntity.setSprinting(true)`.
- **Saltar:** un salto normal basado en el impulso vertical de Minecraft (0.42 bloques/tick), gravedad (0.08 bloques/tick²) y arrastre vertical (0.98 por tick). Los saltos dobles/triples propios de Mario se convierten en un salto normal para no introducir saltos que Minecraft no permite.
- **Saltar corriendo:** además del impulso vertical normal, se suma el impulso horizontal de 0.2 bloques/tick en la dirección del yaw del jugador, como en `LivingEntity.jumpFromGround()`.
- **FOV en primera persona:** reproduce el multiplicador de sprint de Minecraft (1.15×) con interpolación.
- **FOV en tercera persona:** la API Lua no expone un setter arbitrario ni un campo FOV editable en LakituState. Se usa el preset nativo de aproximación a 60° durante el sprint y se vuelve al modo predeterminado al dejar de correr. El cambio existe, pero no es una reproducción numérica exacta del 1.15×.

Los controles de correr usan doble toque hacia delante; no se añadió un botón nuevo que pueda solaparse con los controles táctiles existentes.

## Cámara

Pulsa **Y** para alternar entre primera y tercera persona. En tercera persona, arrastra en la zona táctil derecha para orbitar alrededor de Steve.

La cámara no es una reimplementación completa de `net.minecraft.client.Camera`: esta API Lua no permite escribir directamente `LakituState.pos/focus`. Se reutiliza NEWCAM para seguimiento, entrada táctil y prevención de clipping. Esto no garantiza una copia exacta de distancia, interpolación o presets frontal/trasero de Minecraft.

## Modelo y skin

El generador utiliza las dimensiones, cubos, capas exteriores y UV del modelo PlayerModel de Minecraft Java 1.21.11: cabeza 8×8×8 y sombrero, torso 8×12×4 y chaqueta, brazos y mangas 4×12×4, piernas y pantalones. La skin 64×64 se divide en texturas por cubo para ajustarse a los límites del renderizador F3D/DynOS.

El render final sigue siendo el de SM64CoopDX. No se importa el renderizador Java de Minecraft.

## Física y límites actuales

La adaptación toma como referencia:

- Suelo: `getSpeed() * 0.21600002 / friction³`, con fricción normal 0.6 y arrastre `friction * 0.91`.
- Sprint: modificador de velocidad +30% y doble toque hacia delante.
- Aire: entrada horizontal 0.02 y arrastre horizontal 0.91.
- Salto: impulso inicial 0.42 bloques/tick; gravedad 0.08 bloques/tick²; arrastre vertical 0.98.
- Salto corriendo: impulso horizontal adicional 0.2 bloques/tick.
- FOV: modificador 1.15× en primera persona; preset de 60° en tercera persona por limitación de la API Lua.

La conversión entre bloques Minecraft y unidades SM64 usa provisionalmente `160 / 1.8` unidades por bloque. **Todavía necesita calibración y pruebas reales en el dispositivo.** El input de doble toque también es una adaptación sobre el joystick/ángulo de SM64, no el sistema de teclado original de Minecraft.

Las colisiones siguen siendo las de superficies SM64, no AABB/voxels de Minecraft. No se han implementado todavía modificadores de velocidad de bloques, agua/lava, escalada, elytra ni paridad de físicas en multijugador. El CI de Lua no demuestra que el salto, el sprint o la cámara funcionen correctamente dentro del APK.

## Referencia de ingeniería inversa

La adaptación utiliza como referencia una decompilación comunitaria de Minecraft Java 1.21.11, no una publicación oficial del código de Mojang:

- [LivingEntity.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/world/entity/LivingEntity.java)
- [LocalPlayer.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/player/LocalPlayer.java)
- [AbstractClientPlayer.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/player/AbstractClientPlayer.java)
- [Entity.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/world/entity/Entity.java)
- [GameRenderer.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/renderer/GameRenderer.java)
- [PlayerModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/player/PlayerModel.java)
- [HumanoidModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/HumanoidModel.java)

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en `mods` de SM64CoopDX.
4. Inicia un nivel y selecciona Steve como modelo si no se activa automáticamente.

## Validación

GitHub Actions comprueba la sintaxis Lua y genera recursos DynOS. La versión **0.12.0-alpha** necesita validación dentro de SM64CoopDX Android: sprint con doble toque, salto normal, salto corriendo, aterrizaje, FOV y controles táctiles.
