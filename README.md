# SteveCraft 64

Mod Lua independiente para **SM64CoopDX Android** que representa al jugador como Steve y mantiene el código de SteveCraft separado del motor. Usa un proxy físico basado en la entidad nativa del motor y un modelo Steve renderizado por separado.

## Versión

**0.16.0-alpha** — añade el port de comportamiento de movimiento y matemáticas de cámara de Minecraft Java 26.3, sobre el proxy independiente y el adaptador experimental de colisiones.

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

## Movimiento — Minecraft Java 26.3

El movimiento se separó en minecraft_26_3_physics.lua, una traducción de comportamiento de las rutas relevantes de LocalPlayer, LivingEntity y Entity:

- Modificación de input: escala base 0.98, reducción al usar objetos, multiplicador de sigilo y corrección del movimiento diagonal al límite de un cuadrado unitario.
- Movimiento en suelo: aceleración basada en getFrictionInfluencedSpeed; el valor de fricción por defecto es 0.6. Se puede proporcionar fricción conocida por superficie con SteveCraft.physics.set_block_friction_provider(fn).
- Movimiento aéreo: aceleración normal de 0.02 y arrastre horizontal 0.91.
- Gravedad y arrastre vertical: gravedad por defecto 0.08 y factor vertical 0.98, aplicados en el mismo orden que el paso de movimiento de Minecraft.
- Salto: usa la fuerza de salto por defecto 0.42, conserva el momento horizontal y aplica el impulso de sprint de 0.2 bloques/tick.
- Sprint: doble toque hacia delante con ventana equivalente a la configuración predeterminada documentada.

Las recurrencias de 20 TPS se convierten matemáticamente a los 30 FPS del juego. La conversión de escala entre bloques y unidades SM64 sigue siendo provisional (160 unidades por 1.8 m). Los atributos, modificadores de objetos y estado de hambre que el motor Lua no expone requieren datos externos; SteveCraft.usingItem, SteveCraft.canSprint y el proveedor de fricción son entradas opcionales.

**Límite esencial:** esto no sustituye el movimiento/colisión voxel-AABB de Minecraft. MarioState y el motor SM64 siguen resolviendo la colisión final. No están completas las físicas de agua/lava, escaleras, vuelo, monturas, efectos, ni el comportamiento de cada bloque.

## FOV

- Primera persona: modificador de sprint 1.15× con interpolación.
- Tercera persona: preset nativo de 60° durante sprint. Es una aproximación; las bindings Lua no ofrecen un FOV arbitrario editable para LakituState.

## Cámara — Minecraft Java 26.3

Pulsa **Y** para alternar entre primera persona, tercera persona trasera y tercera persona frontal. En tercera persona, arrastra en la zona táctil derecha para orbitar.

minecraft_26_3_camera.lua implementa como matemáticas independientes:
- interpolación de posición y altura de ojos;
- interpolación de yaw/pitch;
- inversión de yaw y pitch en la perspectiva frontal;
- distancia por defecto de 4 bloques con modificadores de escala/distancia;
- algoritmo de recorte de cámara mediante ocho rayos desplazados 0.1 unidades y forma de colisión VISUAL sin fluidos.

El raycaster del módulo es una interfaz; no se conecta directamente a los triángulos SM64 porque estos no equivalen a los bloques VISUAL del mundo Minecraft. En el juego real, NEWCAM sigue colocando la cámara y resolviendo paredes. La perspectiva frontal fija el yaw inicial mediante el campo de cámara que la API expone como editable.

Por eso, esta versión porta las transformaciones y el algoritmo de cámara, pero **no puede afirmar paridad total de cámara** con Minecraft mientras no exista un raycaster de bloques y una API Lua que permita escribir la posición/foco de cámara.

CAMERA_REFERENCE.md y tools/minecraft_26_3_physics_camera.json detallan los métodos, fuentes y límites.

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

## Referencias de ingeniería inversa

El modelo/skin que ya existía conserva referencias de Minecraft Java 1.21.11 para su geometría y jerarquía PlayerModel/HumanoidModel. El nuevo port de movimiento y cámara toma como objetivo Minecraft Java 26.3 y está documentado por separado en CAMERA_REFERENCE.md y tools/minecraft_26_3_physics_camera.json.

Para el comportamiento 26.3 se usan referencias comunitarias decompiladas, no código oficial distribuido por Mojang:
- LocalPlayer: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/client/player/localplayer/
- LivingEntity: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/world/entity/livingentity/
- Entity: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/world/entity/entity/
- Camera: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/client/camera/

El código Java decompilado no se copia a este repositorio. Los módulos son una traducción de comportamiento en Lua con pruebas automatizadas y adaptadores específicos de SM64CoopDX.

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en `mods` de SM64CoopDX.
4. Inicia un nivel y selecciona Steve como modelo si no se activa automáticamente.

## Validación

GitHub Actions comprueba la sintaxis Lua, el Proxy, el solucionador triangular y el adaptador de superficies simulado. Después hace falta probar en SM64CoopDX Android: caminar por pendientes, subir escalones, atravesar paredes, techos bajos, aterrizar, saltos y cámara táctil.
