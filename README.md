# SteveCraft 64

Mod Lua para **SM64CoopDX Android** que sustituye al jugador por Steve de Minecraft Java 1.21.11, con modelo cúbico, skin clásica, animaciones adaptadas y una primera capa de movimiento inspirado en Minecraft.

## Versión

**0.11.0-alpha** — runtime Lua-only: el comportamiento de Steve se ejecuta en Lua y no requiere integrar C++ personalizado en el APK.

## Implementación Lua

- El modelo 3D se genera como recursos estáticos DynOS compatibles con SM64CoopDX.
- `character.lua` registra el modelo Steve en el jugador local y sincroniza el ID del modelo.
- `animations.lua` registra clips para idle, caminar, correr, agacharse, caminar agachado y nadar, adaptados de HumanoidModel y AnimationUtils.
- `physics.lua` usa `HOOK_BEFORE_PHYS_STEP` para adaptar aceleración horizontal, fricción terrestre y control horizontal en el aire. Después deja que SM64 ejecute su solver de colisiones.
- `camera.lua` configura NEWCAM para la tercera persona con giro táctil y colisiones de superficies; la primera persona utiliza FirstPersonCamera.

## Cámara

Pulsa **Y** para alternar entre primera y tercera persona. En tercera persona, arrastra en la zona táctil derecha para orbitar alrededor de Steve.

La cámara no es una reimplementación completa de `net.minecraft.client.Camera`: esta API Lua no permite escribir directamente `LakituState.pos/focus`. Se reutiliza NEWCAM para seguimiento, entrada táctil y prevención de clipping. Esto no garantiza una copia exacta de distancia, interpolación o presets frontal/trasero de Minecraft.

## Modelo y skin

El generador utiliza las dimensiones, cubos, capas exteriores y UV del modelo PlayerModel de Minecraft Java 1.21.11: cabeza 8×8×8 y sombrero, torso 8×12×4 y chaqueta, brazos y mangas 4×12×4, piernas y pantalones. La skin 64×64 se divide en texturas por cubo para ajustarse a los límites del renderizador F3D/DynOS.

El render final sigue siendo el de SM64CoopDX. No se importa el renderizador Java de Minecraft.

## Física y límites actuales

La capa Lua adapta parte de las fórmulas de movimiento de Minecraft:

- Suelo: `movementSpeed * 0.21600002 / friction³` y arrastre `friction * 0.91`.
- Aire: aceleración horizontal `0.02` y arrastre `0.91`.
- Convierte los coeficientes de 20 ticks/segundo a 30 actualizaciones/segundo y a las unidades aproximadas de Steve.

**Pendiente de calibración y validación:**
- La equivalencia entre bloques Minecraft y unidades SM64 es provisional.
- Se usa fricción genérica 0.6; no hay mapeo de superficies SM64 a bloques individuales.
- Gravedad, impulso vertical del salto, agua/lava, elytra y modificadores de bloques siguen usando el motor.
- Las colisiones siguen siendo las de superficies SM64, no AABB/voxels de Minecraft.
- La sintaxis Lua y el build de recursos no sustituyen pruebas dentro del APK Android.

## Referencia de ingeniería inversa

La adaptación utiliza como referencia una decompilación comunitaria de Minecraft Java 1.21.11, no una publicación oficial del código de Mojang:

- [Entity.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/world/entity/Entity.java)
- [LivingEntity.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/world/entity/LivingEntity.java)
- [LocalPlayer.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/player/LocalPlayer.java)
- [Camera.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/Camera.java)
- [PlayerModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/player/PlayerModel.java)
- [HumanoidModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/HumanoidModel.java)

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en `mods` de SM64CoopDX.
4. Inicia un nivel y selecciona Steve como modelo si no se activa automáticamente.

## Validación

GitHub Actions comprueba la sintaxis Lua y genera recursos DynOS. Aún se debe validar el modelo, animaciones, cámara táctil y movimiento dentro de SM64CoopDX Android.
