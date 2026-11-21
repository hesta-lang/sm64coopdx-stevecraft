# SteveCraft 64

Mod Lua independiente para **SM64CoopDX Android** que sustituye directamente el modelo del jugador por Steve en el objeto nativo de Mario. No crea un segundo cuerpo ni modifica el APK o el motor.

## Versión

**0.18.0-alpha** — sustituye el proxy visual duplicado por el modelo Steve en el marioObj nativo, corrige el error nil de horizontal_step, amplía las pruebas de regresión y conecta los modos de cámara.

## Representación del jugador

- MarioState y marioObj siguen siendo la única autoridad física: el motor conserva movimiento, gravedad, superficies, colisiones, daño e interacciones.
- proxy.lua usa obj_set_model_extended(m.marioObj, steveModelId) para sustituir el modelo del mismo objeto nativo. No genera un segundo Steve completo, no copia transformaciones ni oculta el cuerpo de Mario mediante alfa.
- El motor continúa aplicando posición, orientación y animaciones al mismo objeto.
- En primera persona, el cuerpo del jugador queda oculto por la cámara nativa y first_person_hand.lua dibuja el antebrazo Steve.
- En multijugador, cada cliente cambia el modelo del MarioState local que simula; la sincronización de jugador sigue siendo la de SM64CoopDX.

Este diseño evita que un segundo objeto quede tumbado, desincronizado o visible junto al cuerpo principal. MarioState sigue siendo la única autoridad física.

## Colisiones triangulares de SkyCraft/MarioCraft

- Se portó a Lua el algoritmo de `TriCollider` de SkyCraft: subpasos para evitar atravesar paredes, empuje lateral, muestreo de suelo bajo los pies, subida de escalones, seguimiento de pendientes y recorte contra techos.
- `sm64_collision_adapter.lua` consulta las superficies reales de SM64CoopDX con `find_floor`, `find_ceil` y `find_wall_collisions`; no lee memoria ni modifica los pools de colisión del motor.
- El desplazamiento propuesto se limita antes del paso físico normal. Después, SM64CoopDX sigue ejecutando su resolvedor original, sus acciones, las interacciones y sus colisiones dinámicas.
- La adaptación usa la escala de SteveCraft actual, todavía provisional. No copia la conversión Windows de MarioCraft (100 unidades SM64 por bloque).
- No se importó el puente de memoria compartida de Windows ni el cliente Fabric/Minecraft que MarioCraft arranca en segundo plano.

La precolisión triangular está desactivada por defecto porque SM64CoopDX ya realiza su propio paso de colisión en el mismo movimiento; aplicar dos resolutores seguidos puede causar bloqueos o vibraciones. Se puede habilitar experimentalmente con `SteveCraft.physics.set_triangle_collision_enabled(true)` y desactivar con `false`.

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
- Movimiento sumergido: se conecta al hook real `STEP_TYPE_WATER`, usa velocidad de agua, eficiencia configurable, arrastre y los controles verticales A/Z. El paso de agua nativo conserva la resolución de suelo/techo y sus corrientes.
- Colisión/velocidad: guarda la velocidad solicitada antes del paso SM64 y la reconcilia con el desplazamiento observado. En aire no vuelve a leer la velocidad vertical después de que `perform_air_step()` ya haya ejecutado `apply_gravity()`; esto evita sumar una segunda gravedad de Mario a la gravedad de Minecraft.

Las recurrencias de 20 TPS se convierten matemáticamente a los 30 FPS del juego. horizontal_step utiliza la velocidad efectiva retornada por horizontal_parameters: velocidad con fricción/sprint en suelo y 0.02 en aire. La conversión de escala entre bloques y unidades SM64 sigue siendo provisional (160 unidades por 1.8 m). Los atributos, modificadores de objetos y estado de hambre que el motor Lua no expone requieren datos externos; SteveCraft.usingItem, SteveCraft.canSprint y el proveedor de fricción son entradas opcionales.

**Límite esencial:** esto no sustituye el movimiento/colisión voxel-AABB de Minecraft. MarioState y el motor SM64 siguen resolviendo la colisión final. El paso de agua reproduce solo el movimiento sumergido normal; las corrientes de SM64 se añaden después del hook y no se integran aún como velocidad persistente. Lava, escaleras, vuelo, monturas, efectos, sprint por atributos y fricción por bloque aún no tienen paridad completa.

## FOV

- Primera persona: modificador de sprint 1.15× con interpolación.
- Tercera persona: preset nativo de 60° durante sprint. Es una aproximación; las bindings Lua no ofrecen un FOV arbitrario editable para LakituState.

## Cámara — controlador de perspectivas

Pulsa **Y** para alternar entre primera persona, tercera persona trasera y tercera persona frontal. En tercera persona, arrastra en la zona táctil derecha para orbitar. También están disponibles SteveCraft.set_perspective(0|1|2) y SteveCraft.cycle_perspective().

- Primera persona: usa gFirstPersonCamera, conserva el control táctil nativo y muestra el antebrazo Steve.
- Tercera persona: usa NEWCAM para orbitado táctil y colisión con la geometría del nivel; la cámara se inicializa detrás o delante según el modo.
- minecraft_26_3_camera.lua conserva las fórmulas matemáticas independientes de Minecraft para interpolación, eye height, distancia y rayos de recorte.

**Límite:** la API Lua no permite escribir directamente el XYZ/foco de Lakitu ni incluye un raycaster de bloques VISUAL de Minecraft. Por tanto, esta versión conecta los modos de perspectiva, pero no es una cámara Minecraft completamente independiente ni tiene paridad total de posición/colisión.

CAMERA_REFERENCE.md detalla qué está conectado y qué requiere una API del motor.
 
## Modelo y skin

El generador utiliza las dimensiones, cubos, capas exteriores y UV del modelo PlayerModel de Minecraft Java 1.21.11: cabeza 8×8×8, torso 8×12×4, brazos y piernas 4×12×4. La skin 64×64 se divide en texturas por cubo para ajustarse a los límites del renderizador F3D/DynOS.

El modelo se mantiene dentro de este repositorio independiente. No se modifica el APK ni el código de SM64CoopDX.

### Importador experimental de Minecraft Bedrock

La rama stevecraft-bedrock-model-importer-alpha incorpora tools/import_bedrock_geometry.py. Lee la geometría oficial geometry.humanoid.custom.geo.json y player.entity.json de Mojang/bedrock-samples, conserva los 17 huesos, pivotes y localizadores como metadatos y convierte los 12 cubos clásicos para el generador DynOS.

El exportador Blender puede consumir esa conversión mediante STEVE_BEDROCK_GEOMETRY_SPEC. En esta primera etapa, los cubos se siguen asignando a los seis grupos del esqueleto de SM64CoopDX; todavía no se genera un rig DynOS nativo de 17 huesos ni se importan las animaciones completas de Bedrock. El flujo de Actions en esta rama ejecuta la compilación con geometría Bedrock; la opción manual del workflow permite elegir Java o Bedrock.

Los archivos oficiales de muestra están sujetos a la Minecraft EULA. El workflow los descarga durante la compilación y no guarda el JSON original en el repositorio. Consulta BEDROCK_MODEL_IMPORT.md para las limitaciones y la conversión.

## Límites actuales

- La equivalencia entre bloques Minecraft y unidades SM64 sigue siendo provisional.
- El pre-resolutor triangular queda desactivado por defecto para no duplicar el resolvedor nativo. Es una opción experimental, no un reemplazo de las colisiones AABB/voxel de Minecraft.
- La ruta de agua es experimental: conserva la colisión de agua y las corrientes que gestiona SM64, pero no reproduce las corrientes Minecraft persistentes, burbujas, fluidos personalizados ni todos los estados de nado. Lava y modificadores individuales de bloque siguen incompletos.
- El modelo usa el esqueleto y las animaciones registradas para SM64CoopDX; la paridad con todos los controladores Java de Minecraft sigue incompleta.
- La API Lua no permite escribir directamente la posición/foco de Lakitu para una cámara Minecraft totalmente separada.
- El reemplazo del modelo nativo evita el cuerpo duplicado anterior; todavía falta validar el renderizado y las proporciones en SM64CoopDX Android.
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
