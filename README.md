# SteveCraft 64

Mod Lua independiente para **SM64CoopDX Android** que representa al jugador como Steve de Minecraft Java 1.21.11. Usa un proxy físico basado en la entidad nativa del motor y un modelo Steve renderizado por separado.

## Versión

**0.15.0-alpha** — añade el Proxy visual independiente y un pre-resolutor de colisiones triangulares adaptado de SkyCraft/MarioCraft.

## Proxy físico/visual

- **MarioState y marioObj siguen siendo la autoridad física única:** el motor conserva el movimiento, gravedad, paredes, superficies, colisiones, daño e interacciones.
- **Steve es un objeto visual independiente:** cada cliente crea una representación local de Steve para cada jugador y la sincroniza con el objeto físico correspondiente.
- El objeto visual no tiene hitbox, interacciones ni gravedad. No procesa movimiento ni colisiones.
- Copia la posición, orientación y descriptor/frame de animación del jugador físico.
- El modelo de Steve conserva la jerarquía animada compatible con el esqueleto de jugador de SM64CoopDX.
- Se asigna `globalPlayerIndex` al objeto visual para que las rutinas GeoLayout de cabeza y torso resuelvan el estado corporal del jugador correcto.
- En primera persona se oculta el cuerpo visual independiente y se conserva el brazo viewmodel de Steve.
- La cámara nativa continúa siguiendo al proxy físico. La API Lua no expone un destino Lakitu editable para implementar una cámara Minecraft completamente independiente.

Este Proxy separa la representación del cuerpo que colisiona. **MarioState sigue siendo la única autoridad física** y el motor resuelve los contactos finales.

## Colisiones triangulares de SkyCraft/MarioCraft

- Se portó a Lua el algoritmo de `TriCollider` de SkyCraft: subpasos para evitar atravesar paredes, empuje lateral, muestreo de suelo bajo los pies, subida de escalones, seguimiento de pendientes y recorte contra techos.
- `sm64_collision_adapter.lua` consulta las superficies reales de SM64CoopDX con `find_floor`, `find_ceil` y `find_wall_collisions`; no lee memoria ni modifica los pools de colisión del motor.
- El desplazamiento propuesto se limita antes del paso físico normal. Después, SM64CoopDX sigue ejecutando su resolvedor original, sus acciones, las interacciones y sus colisiones dinámicas.
- La adaptación usa la escala de SteveCraft actual, todavía provisional. No copia la conversión Windows de MarioCraft (100 unidades SM64 por bloque).
- No se importó el puente de memoria compartida de Windows ni el cliente Fabric/Minecraft que MarioCraft arranca en segundo plano.

La precolisión triangular puede desactivarse desde Lua con `SteveCraft.physics.set_triangle_collision_enabled(false)`. Para volver a activarla, usa `SteveCraft.physics.set_triangle_collision_enabled(true)`. Si aparecen vibraciones, saltos de altura o bloqueos en pendientes, desactívala: el motor SM64 sigue siendo el resolvedor final.

**Esto no convierte las físicas de SM64 en las físicas completas de Minecraft.** MarioCraft obtiene velocidad, gravedad, fricción, saltos y demás del propio Minecraft Java que ejecuta por separado; el algoritmo reutilizado aquí solo resuelve geometría triangular.

Consulta [PROXY_ARCHITECTURE.md](PROXY_ARCHITECTURE.md) y [MARIOCRAFT_PORT.md](MARIOCRAFT_PORT.md) para los límites y el detalle de la adaptación.

## Movimiento

- **Correr:** doble toque hacia delante. Aplica el aumento de velocidad del 30% y activa la animación de correr.
- **Saltar:** impulso y gravedad inspirados en Minecraft Java 1.21.11.
- **Salto vertical:** al despegar se ponen a cero las velocidades horizontales X/Z, el avance y el deslizamiento. Durante toda la fase aérea no se aplica control horizontal.
- **Doble/triple salto:** las transiciones nativas de Mario se convierten en salto normal.

El salto no reproduce el impulso horizontal de 0.2 bloques/tick de Minecraft al saltar corriendo; se omite porque el requisito actual es que Steve solo se desplace verticalmente al saltar.

## FOV

- Primera persona: modificador de sprint 1.15× con interpolación.
- Tercera persona: preset nativo de 60° durante sprint. Es una aproximación, no una reproducción exacta de 1.15×; la API Lua del fork no expone un FOV arbitrario editable para LakituState.

## Cámara

Pulsa **Y** para alternar entre primera y tercera persona. En tercera persona, arrastra en la zona táctil derecha para orbitar alrededor de Steve.

La cámara reutiliza NEWCAM para seguimiento, entrada táctil y prevención de clipping. El punto de seguimiento continúa siendo el jugador físico Mario que actúa como proxy.

## Modelo y skin

El generador utiliza las dimensiones, cubos, capas exteriores y UV del modelo PlayerModel de Minecraft Java 1.21.11: cabeza 8×8×8, torso 8×12×4, brazos y piernas 4×12×4. La skin 64×64 se divide en texturas por cubo para ajustarse a los límites del renderizador F3D/DynOS.

El modelo se mantiene dentro de este repositorio independiente. No se modifica el APK ni el código de SM64CoopDX.

## Límites actuales

- La equivalencia entre bloques Minecraft y unidades SM64 sigue siendo provisional.
- El pre-resolutor triangular usa consultas de superficies del motor; no crea colisiones AABB/voxel de Minecraft y todavía requiere validación en Android.
- La física de agua/lava, modificadores individuales de bloques y paridad física multijugador no están implementadas.
- El Proxy aún depende de las animaciones del esqueleto SM64; no reemplaza los clips por los controladores Java de Minecraft.
- La API Lua no permite escribir directamente la posición/foco de Lakitu para una cámara Minecraft totalmente separada.
- Un build correcto y un análisis sintáctico Lua no sustituyen la prueba real del mod en SM64CoopDX Android.

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

GitHub Actions comprueba la sintaxis Lua, el Proxy, el solucionador triangular y el adaptador de superficies simulado. Después hace falta probar en SM64CoopDX Android: caminar por pendientes, subir escalones, atravesar paredes, techos bajos, aterrizar, saltos y cámara táctil.
