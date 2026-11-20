# SteveCraft 64

Mod Lua independiente para **SM64CoopDX Android** que representa al jugador como Steve sin modificar el APK ni el motor. SteveCraft sustituye la acción de locomoción, la integración de movimiento y la actualización geométrica nativas de Mario; MarioState se conserva como puente de compatibilidad/interacciones y Steve tiene un modelo renderizado por separado.

## Versión

**0.20.0-alpha** — aísla la locomoción de Steve mediante una acción Lua propia, sustituye el preprocesamiento geométrico nativo y sincroniza el renderizado con MarioState.

## Proxy físico/visual

- **MarioState y marioObj son el puente de compatibilidad con el motor:** SteveCraft controla la aceleración, salto, gravedad, movimiento y resolución de contactos del jugador local. El motor conserva las consultas de geometría y el sistema de interacciones.
- **Steve es un objeto visual independiente:** cada cliente crea una representación local de Steve para cada jugador y la sincroniza con el objeto físico correspondiente.
- El objeto visual no tiene hitbox, interacciones ni gravedad. No procesa movimiento ni colisiones.
- El GeoLayout independiente ya no llama a `geo_mirror_mario_set_alpha`: esa rutina lee `MarioBodyState.modelState`, que el proxy pone a alfa cero para ocultar a Mario. Mantenerla también ocultaba a Steve y dejaba visible solo su sombra.
- La posición y orientación visuales se leen directamente de `MarioState.pos` y `MarioState.faceAngle`; solo se reutiliza el descriptor/frame de animación compatible. No se copia la transformación gráfica potencialmente atrasada de Mario.
- Se ocultan las sombras nativas tanto del proxy Mario como del actor DynOS separado (`header.gfx.shadowInvisible`). Esta versión elimina las sombras negras generadas por SM64; todavía no dibuja una sombra de Minecraft propia.
- El modelo de Steve conserva la jerarquía animada compatible con el esqueleto de jugador de SM64CoopDX.
- Se asigna `globalPlayerIndex` al objeto visual para que las rutinas GeoLayout de cabeza y torso resuelvan el estado corporal del jugador correcto.
- En primera persona se oculta el cuerpo visual independiente y se conserva el brazo viewmodel de Steve.
- La cámara nativa continúa siguiendo al proxy físico. La API Lua no expone un destino Lakitu editable para implementar una cámara Minecraft completamente independiente.

Este Proxy separa el cuerpo visual del puente de compatibilidad. **SteveCraft es el propietario de la locomoción y de la integración física** mientras el modo independiente está activo; MarioState sigue transportando posición, contactos, datos de jugador e interacciones requeridos por el motor.

## Colisiones triangulares de SkyCraft/MarioCraft

- Se portó a Lua el algoritmo de `TriCollider` de SkyCraft: subpasos para evitar atravesar paredes, empuje lateral, muestreo de suelo bajo los pies, subida de escalones, seguimiento de pendientes y recorte contra techos.
- `sm64_collision_adapter.lua` consulta las superficies reales de SM64CoopDX con `find_floor`, `find_ceil` y `find_wall_collisions`; no lee memoria ni modifica los pools de colisión del motor.
- El adaptador consulta superficies reales de SM64CoopDX y el resolvedor triangular de SteveCraft calcula el desplazamiento aceptado. El cuerpo utiliza una huella radial y altura configurable, no una caja AABB voxel exacta.
- `hook_mario_action()` registra `ACT_STEVECRAFT_CONTROLLED` como una acción estacionaria personalizada sin flags `INTANGIBLE` ni `INVULNERABLE`. Así el motor sigue procesando colisiones de objetos y puede iniciar diálogos con NPCs, pero el callback Lua sustituye la rutina nativa de reposo y las transiciones de locomoción. El callback `gravity` bloquea la gravedad nativa de Mario.
- `HOOK_BEFORE_PHYS_STEP` intercepta los pasos de suelo, aire y agua que la acción Steve solicita; devuelve resultados compatibles y cancela el resolvedor/gravedad integrados del motor.
- `HOOK_MARIO_OVERRIDE_GEOMETRY_INPUTS` devuelve `false` para el jugador Steve. Con ello se omite `update_mario_geometry_inputs()`, incluidos `f32_find_wall_collision()` y las correcciones de posición nativas de Mario. `steve_geometry.lua` repone mediante consultas Lua los contactos básicos de suelo, techo, agua y gas sin mover al jugador.
- `HOOK_ALLOW_FORCE_WATER_ACTION` impide que Mario convierta el estado de Steve en su salto de agua/plunge. `HOOK_ALLOW_HAZARD_SURFACE` desactiva para Steve las reacciones físicas nativas de arenas movedizas, lava y viento.
- La posición, velocidad, datos de contacto básicos y transformación gráfica se actualizan desde Lua. Si el resolvedor no puede resolver un paso, el modo de aislamiento devuelve un resultado neutral y detiene ese paso; **no vuelve al resolvedor nativo de Mario**.
- La adaptación usa la escala de SteveCraft actual, todavía provisional. No copia la conversión Windows de MarioCraft (100 unidades SM64 por bloque).
- No se importó el puente de memoria compartida de Windows ni el cliente Fabric/Minecraft que MarioCraft arranca en segundo plano.

El modo independiente está activado por defecto. `SteveCraft.physics.set_independent_mode(false)` permite volver deliberadamente al movimiento nativo para diagnóstico; `true` restaura el aislamiento. La corrección geométrica nativa puede consultarse o reactivarse con `SteveCraft.physics.is_native_geometry_disabled()` y `set_native_geometry_disabled(false)`, aunque no se recomienda mezclarla con la resolución de Steve.

**Esto todavía no equivale a las físicas completas de Minecraft.** La locomoción y el preprocesamiento geométrico nativos de Mario quedan desactivados para Steve mientras el aislamiento está activo, pero la geometría consultada sigue siendo la malla triangular del nivel SM64. No existe aún una colisión voxel/AABB contra una cuadrícula real de bloques Minecraft.

Consulta [PROXY_ARCHITECTURE.md](PROXY_ARCHITECTURE.md) y [MARIOCRAFT_PORT.md](MARIOCRAFT_PORT.md) para los límites y el detalle de la adaptación.

## Movimiento — Minecraft Java 26.3

El movimiento se separó en minecraft_26_3_physics.lua, una traducción de comportamiento de las rutas relevantes de LocalPlayer, LivingEntity y Entity:

- Modificación de input: escala base 0.98, reducción al usar objetos, multiplicador de sigilo y corrección del movimiento diagonal al límite de un cuadrado unitario.
- Movimiento en suelo: aceleración basada en getFrictionInfluencedSpeed; el valor de fricción por defecto es 0.6. Se puede proporcionar fricción conocida por superficie con SteveCraft.physics.set_block_friction_provider(fn).
- Movimiento aéreo: aceleración normal de 0.02 y arrastre horizontal 0.91.
- Gravedad y arrastre vertical: gravedad por defecto 0.08 y factor vertical 0.98, aplicados en el mismo orden que el paso de movimiento de Minecraft.
- Salto: usa la fuerza de salto por defecto 0.42, conserva el momento horizontal y aplica el impulso de sprint de 0.2 bloques/tick.
- Sprint: doble toque hacia delante con ventana equivalente a la configuración predeterminada documentada.
- Movimiento sumergido: reemplaza el paso `STEP_TYPE_WATER` cuando el hook puede resolverlo, usa velocidad de agua, eficiencia configurable, arrastre y controles verticales A/Z.
- Colisión/velocidad: el solver triangular calcula el desplazamiento aceptado antes de que el motor ejecute su resolver. La posición se escribe directamente en MarioState y el módulo sincroniza la transformación gráfica. La gravedad nativa no se ejecuta en los pasos interceptados.

Las recurrencias de 20 TPS se convierten matemáticamente a los 30 FPS del juego. En modo independiente el hook cancela el paso físico nativo de suelo/aire/agua y actualiza `MarioState.pos` directamente. La conversión de escala entre bloques y unidades SM64 sigue siendo provisional (160 unidades por 1.8 m). Los atributos, modificadores de objetos y estado de hambre que el motor Lua no expone requieren datos externos; SteveCraft.usingItem, SteveCraft.canSprint y el proveedor de fricción son entradas opcionales.

**Límites de la versión:** se reemplazan las acciones nativas de locomoción y se desactiva la corrección geométrica nativa para Steve. También se bloquean las reacciones físicas nativas de quicksand, lava, viento y plunge de agua. El motor sigue proporcionando triángulos y consultas de superficies, no bloques Minecraft. El colisionador horizontal usa una huella radial de 0.3 bloques y una altura de 1.8 bloques, no una caja AABB rectangular. Los suelos de warp/death-plane, temporizadores PSS y transiciones de muerte siguen siendo funciones de nivel/estado del motor; requieren revisión separada si también se quieren sustituir. Interacciones, daño, salud, networking y cámara siguen usando el motor como puente. La conversión de escala continúa siendo provisional. Si el resolvedor Lua falla, Steve no usa el movimiento nativo: ese paso se detiene para evitar mezclar dos sistemas físicos.

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
- La acción propia cubre la locomoción regular de Steve y permanece no-intangible/no-invulnerable para permitir interacciones y diálogos. Se conservan las secuencias terminales de muerte del motor; warp/death-plane y temporizadores PSS siguen siendo mecánicas de nivel nativas, mientras quicksand, lava, viento y plunge de agua quedan bloqueados para Steve.
- El colisionador horizontal usa una aproximación radial de 0.3 bloques de radio, no un AABB rectangular exacto. Las superficies consultadas siguen siendo triángulos de SM64.
- La ruta de agua aún no reproduce corrientes Minecraft persistentes, burbujas, fluidos personalizados ni todos los estados de nado. Lava y modificadores individuales de bloque siguen incompletos.
- El Proxy aún depende de las animaciones del esqueleto SM64; no reemplaza los clips por los controladores Java de Minecraft.
- La API Lua no permite escribir directamente la posición/foco de Lakitu para una cámara Minecraft totalmente separada.
- La eliminación de `geo_mirror_mario_set_alpha` evita compartir la alfa de Mario; también se oculta la sombra del proxy y la transformación Steve viene directamente de MarioState. El aspecto final todavía requiere prueba real en Android.
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
