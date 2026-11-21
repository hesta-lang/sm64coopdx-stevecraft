# SteveCraft — animaciones de Minecraft Bedrock

## Integración

SteveCraft registra clips con \`smlua_anim_util_register_animation\` y selecciona el clip según el ID de animación de Mario mediante \`smlua_anim_util_set_animation\`. El proxy visual de Steve copia el descriptor de animación de Mario al objeto visual separado; MarioState y \`marioObj\` siguen siendo la única autoridad de física y colisión.

Esta solución evita reemplazar \`mario_geo\` globalmente: hacerlo también cambiaría el modelo del proxy físico y rompería la separación de SteveCraft. La tabla binaria DynOS tampoco es el selector directo para el objeto visual independiente, por eso los clips se registran con la API Lua que el proxy ya transfiere.

## Clips registrados

Hay 19 clips muestreados, asociados a 27 IDs del jugador SM64:

| Familia | Clips |
|---|---|
| Movimiento | idle, walk, run |
| Agacharse | start crouch, crouch, stop crouch |
| Gatear | start crawl, crawl, stop crawl |
| Nadar | swim, swim legs, swim idle |
| Estado | ride, sleep, sleep lying |
| Ataque | attack, attack left, attack fast, attack fast left |

Cada clip tiene tres canales de traslación raíz a cero y 60 canales de rotación XYZ para los 20 nodos animados del rig SM64: 63 canales y 126 índices. La traslación de raíz se mantiene en cero para que el cuerpo visual permanezca alineado con el proxy físico.

## Referencia Bedrock

Fuente fijada al commit \`15701fa9c13923f12662984c32c124327e40e3d3\` (\`v1.26.60.5\`):

- [player.animation.json](https://github.com/Mojang/bedrock-samples/blob/15701fa9c13923f12662984c32c124327e40e3d3/resource_pack/animations/player.animation.json): locomoción, agacharse, nadar, ataque y dormir.
- [humanoid.animation.json](https://github.com/Mojang/bedrock-samples/blob/15701fa9c13923f12662984c32c124327e40e3d3/resource_pack/animations/humanoid.animation.json): balanceo de brazos y postura de montura.
- [player.entity.json](https://github.com/Mojang/bedrock-samples/blob/15701fa9c13923f12662984c32c124327e40e3d3/resource_pack/entity/player.entity.json): variable \`tcos0\` y giro del torso durante el ataque.

## Límites

Esto no ejecuta los controladores Bedrock en tiempo real: las curvas se muestrean en clips SM64 estáticos. En particular, \`tcos0\` depende de \`query.modified_distance_moved\`, \`query.modified_move_speed\` y \`variable.gliding_speed_value\`; el ciclo de andar/correr usa una fase fija, así que no sigue esas consultas dinámicas. Los ataques usan una curva muestreada; la natación no integra la inclinación ni el desplazamiento dinámico de raíz; dormir no conoce la orientación ni la posición de la cama.

No se portan los controladores de objetos/capas (arco, ballesta, escudo, objetos en mano), primera persona animada, tracking de objetivos, todos los estados de vuelo/deslizamiento ni las mezclas/overlays Bedrock. No es paridad 100 % en tiempo real con Minecraft.

La geometría actual del repositorio sigue siendo el actor independiente \`actors/steve/\`, generado desde el PlayerModel de Java 1.21.11. Este cambio añade los clips Bedrock a ese actor; no sustituye la malla por \`minecraft_steve_bedrock_animated.bin\`. La tabla DynOS del \`.bin\` anterior no se conecta automáticamente al proxy visual separado de esta rama.

## Pruebas

\`lua5.4 tools/test_bedrock_animations.lua\` carga \`animations.lua\` con stubs de la API SM64CoopDX. Comprueba el registro de 19 clips, las 27 asignaciones, dimensiones de índices, límites de muestras y las transiciones no cíclicas. Valida el registro/mapeo, no la orientación visual ni el resultado dentro de Android.


## Corrección 0.19.0-alpha

Se corrigió `horizontal_step()`: ahora recibe el `movement_speed` efectivo como tercer valor devuelto por `horizontal_parameters()`. Antes se leía una variable global inexistente, generando `attempt to perform arithmetic on a nil value (global 'movement_speed')` y deteniendo `HOOK_BEFORE_PHYS_STEP`.

La prueba de física ahora ejercita `horizontal_step()` en suelo, aire y sprint. Las pruebas automáticas no determinan por sí solas por qué una captura de pantalla presenta a Steve tumbado; para eso debe observarse el ID de animación seleccionado y verificarse la orientación dentro del juego. No se debe confundir el error de física con la orientación del esqueleto.


## Protección de poses de raíz (0.19.1-alpha)

La natación solo activa el giro raíz cuando la acción de Mario contiene simultáneamente `ACT_FLAG_SWIMMING_OR_FLYING` y `ACT_FLAG_WATER_OR_TEXT`; esto evita confundir vuelo con natación. Gateo y sueño necesitan `SteveCraft.crawling = true` y `SteveCraft.sleeping = true`, respectivamente, porque SM64 no tiene estados Bedrock equivalentes. En cada cambio de clip se registra el ID y el nombre elegido para permitir diagnóstico desde el log de Android.

El objetivo es impedir que un ID coincidente de SM64 tumbe accidentalmente el modelo en tierra. La postura de natación/gateo/dormir debe validarse visualmente por separado.
