# SteveCraft 64

Mod modular para **sm64coopdx**, orientado al fork Android de ManIsCat2. Convierte al jugador en Steve con geometría cúbica y prepara la base para añadir las mecánicas de Minecraft.

## Versión

**0.7.0-alpha** — brazo de primera persona con proporciones 4×12×4 y textura clásica de Steve 64×64.

## Estado

- La cámara empieza en primera persona, pero ahora permite alternar a tercera persona con la cruceta arriba (`U_JPAD`).
- El cuerpo sigue las proporciones clásicas del modelo de jugador de Minecraft Java: cabeza 8×8×8, torso 8×12×4 y extremidades 4×12×4. Conserva el esqueleto compatible de SM64CoopDX.
- Los brazos del cuerpo tienen manga turquesa y mano color piel en piezas separadas.
- Un actor DynOS independiente, `steve_hand_geo`, dibuja el brazo clásico de Minecraft de 4×12×4 unidades. Sus seis caras se texturizan desde las regiones UV originales del brazo derecho de la skin clásica de Steve 64×64.
- El brazo sigue la orientación de `gFirstPersonCamera`, usa el transform de viewmodel de Gun Mod y tiene balanceo al caminar. La orientación longitudinal se corrigió para dejar la mano hacia el centro y la manga hacia la esquina inferior derecha; el modelo se redujo a 2.5× y se acercó ligeramente al encuadre.
- El cuerpo sigue usando el conjunto de animaciones estándar del motor. Se incorporaron las fórmulas de movimiento de HumanoidModel como referencia compatible, pero los clips personalizados aún no se han horneado a los índices de huesos de SM64.
- El brazo 3D solo se muestra en primera persona; al pasar a tercera persona se elimina.\n- La tercera persona usa la cámara nativa `CAMERA_MODE_FREE_ROAM` de SM64CoopDX, con órbita y prevención de colisiones del motor. La vista frontal independiente de Minecraft aún no está implementada.

## Estructura

```text
sm64coopdx-stevecraft/
├── main.lua
├── camera.lua
├── character.lua
├── first_person_hand.lua
├── animations.lua
├── physics.lua
├── blocks.lua
├── actors/
│   ├── steve/
│   │   ├── geo.inc.c
│   │   ├── geo_header.h
│   │   ├── model.inc.c
│   │   └── README.md
│   └── steve_hand/
│       ├── geo.inc.c
│       ├── geo_header.h
│       ├── model.inc.c
│       └── README.md
├── assets/steve/
├── tools/build_steve_actor.py
└── tools/build_steve_hand.py
```

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta en el directorio `mods` de SM64CoopDX.
4. Inicia un nivel. DynOS lee los archivos `.inc.c` de ambos actores y genera los recursos binarios durante la carga del pack.
5. Comprueba el modelo de Steve y el brazo 3D en primera persona.

En multijugador, instala el mod en cada cliente que deba mostrar a Steve.

## Compatibilidad DynOS

El exportador elimina los `CUSTOM_CMD()` vacíos que Fast64 añade y que el parser GeoLayout del fork Android no reconoce. El generador del brazo recorta seis PNG pequeños desde la skin clásica de Steve 64×64 en lugar de cargar el atlas completo de una vez, refleja la orientación longitudinal del brazo para el punto de vista en primera persona y fuerza `G_TF_POINT` para evitar interpolación de texeles. El registro Lua rechaza tanto `E_MODEL_NONE` como `E_MODEL_ERROR_MODEL`.

## Validación

GitHub Actions comprueba la sintaxis Lua y genera los recursos fuente. Eso no sustituye la prueba dentro de SM64CoopDX Android. Sigue pendiente comprobar en el dispositivo la carga de ambos actores, su escala/posición, las animaciones y la ausencia de oclusión inesperada.
