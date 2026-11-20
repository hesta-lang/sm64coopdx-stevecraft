# SteveCraft 64

Mod Lua independiente para **SM64CoopDX Android** que representa al jugador como Steve y mantiene el código de SteveCraft separado del motor. Usa un proxy físico basado en la entidad nativa del motor y un modelo Steve renderizado por separado.

## Versión

**0.18.0-alpha** — incorpora un controlador Lua que sustituye los pasos nativos de movimiento de Mario en suelo, aire y agua cuando el adaptador de superficies está disponible.

## Proxy físico/visual

- **MarioState y marioObj siguen siendo el contenedor de estado compatible con el motor:** SteveCraft escribe su posición y velocidad, y ejecuta su propia integración de movimiento. El motor sigue proporcionando las consultas de geometría y el sistema de interacciones.
- **Steve es un objeto visual independiente:** cada cliente crea una representación local de Steve para cada jugador y la sincroniza con el objeto físico correspondiente.
- El objeto visual no tiene hitbox, interacciones ni gravedad. No procesa movimiento ni colisiones.
- El GeoLayout independiente ya no llama a `geo_mirror_mario_set_alpha`: esa rutina lee `MarioBodyState.modelState`, que el proxy pone a alfa cero para ocultar a Mario. Mantenerla también ocultaba a Steve y dejaba visible solo su sombra.
- Copia la posición, orientación y descriptor/frame de animación del jugador físico.
- El modelo de Steve conserva la jerarquía animada compatible con el esqueleto de jugador de SM64CoopDX.
- Se asigna `globalPlayerIndex` al objeto visual para que las rutinas GeoLayout de cabeza y torso resuelvan el estado corporal del jugador correcto.
- En primera persona se oculta el cuerpo visual independiente y se conserva el brazo viewmodel de Steve.
- La cámara nativa continúa siguiendo al proxy físico. La API Lua no expone un destino Lakitu editable para implementar una cámara Minecraft completamente independiente.

Este Proxy separa la representación del cuerpo visual. **SteveCraft es ahora el propietario de la integración de movimiento** para los pasos que consigue interceptar; MarioState se conserva como estado puente para el motor, red e interacciones.

## Colisiones triangulares de SkyCraft/MarioCraft

- Se portó a Lua el algoritmo de `TriCollider` de SkyCraft: subpasos para evitar atravesar paredes, empuje lateral, muestreo de suelo bajo los pies, subida de escalones, seguimiento de pendientes y recorte contra techos.
- `sm64_collision_adapter.lua` consulta las superficies reales de SM64CoopDX con `find_floor`, `find_ceil` y `find_wall_collisions`; no lee memoria ni modifica los pools de colisión del motor.
- El adaptador consulta superficies reales de SM64CoopDX y el resolvedor triangular de SteveCraft calcula el desplazamiento aceptado. El cuerpo utiliza una huella radial y altura configurable, no una caja AABB voxel exacta.
- `HOOK_BEFORE_PHYS_STEP` cancela `perform_ground_step`, `perform_air_step` o `perform_water_step` devolviendo resultados compatibles cuando el resolvedor Lua completa el movimiento. Así se omiten el movimiento, colisiones finales y gravedad integrados en esos pasos nativos para el jugador local.
- La posición, velocidad, datos de contacto básicos y transformación gráfica se actualizan desde Lua. Si no se puede consultar la geometría o escribir la posición, el código cae de forma segura al paso nativo.
- La adaptación usa la escala de SteveCraft actual, todavía provisional. No copia la conversión Windows de MarioCraft (100 unidades SM64 por bloque).
- No se importó el puente de memoria compartida de Windows ni el cliente Fabric/Minecraft que MarioCraft arranca en segundo plano.

La precolisión triangular está desactivada por defecto porque SM64CoopDX ya realiza su propio paso de colisión en el mismo movimiento; aplicar dos resolutores seguidos puede causar bloqueos o vibraciones. Se puede habilitar experimentalmente con `SteveCraft.physics.set_triangle_collision_enabled(true)` y desactivar con `false`.

**Esto todavía no equivale a las físicas completas de Minecraft.** SteveCraft ya controla aceleración, gravedad, arrastre, salto y el paso de movimiento cuando el hook puede reemplazarlo, pero la geometría procede de las superficies triangulares de SM64CoopDX. No existe aún una colisión AABB contra una cuadrícula de bloques Minecraft.

Consulta [PROXY_ARCHITECTURE.md](PROXY_ARCHITECTURE.md) y [MARIOCRAFT_PORT.md](MARIOCRAFT_PORT.md) para los límites y el detalle de la adaptación.

## Movimiento — Minecraft Java 26.3

El movimiento se separó en minecraft_26_3_physics.lua, una traducción de comportamiento de las rutas relevantes de LocalPlayer, LivingEntity y Entity:

- Modificación de input: escala base 0.98, reducción al usar objetos, multiplicador de sigilo y corrección del movimiento diagonal al límite de un cuadrado unitario.
- Movimiento en suelo: aceleración basada en getFrictionInfluencedSpeed; el valor de fricción por defecto es 0.6. Se puede proporcionar fricción conocida por superficie con SteveCraft.physics.set_block_friction_provider(fn).
- Movimiento aéreo: aceleración normal de 0.02 y arrastre horizontal 0.91.
- Gravedad y arrastre vertical: gravedad por defecto 0.08 y factor vertical 0.98, aplicados en el mismo orden que el paso de movimiento de Minecraft.
- Salto: usa la fuerza de salto por defecto 0.42, conserva el momento horizontal y aplica el impulso de sprint de 0.2 bloques/tick.
- Sprint: doble toque hacia delante con ventana equivalente a la configuración predeterminada documentada.
- Movimiento sumergido: se conecta al hook real `STEP_TYPE_WATER`, usa velocidad de agua, eficiencia configurable, arrastre y los controles verticales A/Z. El paso de agua nativo conserva la resolución de suelo/techo y sus corrientes.
- Colisión/velocidad: guarda la velocidad solicitada antes del paso SM64 y la reconcilia con el desplazamiento observado. En aire no vuelve a leer la velocidad vertical después de que `perform_air_step()` ya haya ejecutado `apply_gravity()`; esto evita sumar una segunda gravedad de Mario a la gravedad de Minecraft.

Las recurrencias de 20 TPS se convierten matemáticamente a los 30 FPS del juego. En modo independiente el hook cancela el paso físico nativo de suelo/aire/agua y actualiza `MarioState.pos` directamente. La conversión de escala entre bloques y unidades SM64 sigue siendo provisional (160 unidades por 1.8 m). Los atributos, modificadores de objetos y estado de hambre que el motor Lua no expone requieren datos externos; SteveCraft.usingItem, SteveCraft.canSprint y el proveedor de fricción son entradas opcionales.

**Límite esencial:** la integración de movimiento nativa se evita solo en los pasos interceptados; se mantienen las superficies triangulares de SM64 como geometría consultada. El cuerpo usa una aproximación circular de 0.6 bloques de ancho, no AABB real. Las acciones especiales que no pasan por `HOOK_BEFORE_PHYS_STEP`, los daños/estados de Mario, corrientes, lava, escaleras, vuelo, monturas, efectos, sprint por atributos y fricción por bloque aún no tienen paridad completa. Si el adaptador falla, se permite un paso nativo de respaldo.

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
- El pre-resolutor triangular queda desactivado por defecto para no duplicar el resolvedor nativo. Es una opción experimental, no un reemplazo de las colisiones AABB/voxel de Minecraft.
- La ruta de agua es experimental: conserva la colisión de agua y las corrientes que gestiona SM64, pero no reproduce las corrientes Minecraft persistentes, burbujas, fluidos personalizados ni todos los estados de nado. Lava y modificadores individuales de bloque siguen incompletos.
- El Proxy aún depende de las animaciones del esqueleto SM64; no reemplaza los clips por los controladores Java de Minecraft.
- La API Lua no permite escribir directamente la posición/foco de Lakitu para una cámara Minecraft totalmente separada.
- La eliminación de `geo_mirror_mario_set_alpha` corrige el acoplamiento conocido entre la alfa de Mario y el cuerpo de Steve; sigue pendiente confirmar el renderizado real en SM64CoopDX Android.
- Un build correcto y las pruebas simuladas no demuestran que el bypass funcione en tiempo real con el fork Android. Es imprescindible verificar en dispositivo el movimiento, la cámara, las transiciones de acciones, las colisiones, el agua y los límites del nivel.

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
