# SteveCraft 64

Mod modular para **sm64coopdx**, orientado al fork Android de ManIsCat2. Convierte al jugador en Steve con geometría cúbica y prepara la base para añadir las mecánicas de Minecraft.

## Versión

**0.4.0-alpha** — corrección de GeoLayout DynOS y primera implementación del brazo 3D en primera persona.

## Estado

- La cámara permanente en primera persona existente se conserva.
- El cuerpo de Steve usa geometría cúbica y el esqueleto de jugador de SM64CoopDX.
- Los brazos del cuerpo tienen manga turquesa y mano color piel en piezas separadas.
- Un actor DynOS independiente, `steve_hand_geo`, dibuja el brazo 3D en primera persona.
- El brazo sigue la orientación de `gFirstPersonCamera`, se coloca respecto a `gLakituState.curPos` y tiene balanceo al caminar y pose de golpe.
- El cuerpo sigue usando las animaciones estándar del motor. Las animaciones completas de Minecraft y la física/construcción de bloques aún no están implementadas.
- El brazo es un objeto 3D unido a la cámara, no una pasada HUD independiente; su escala, posición y oclusión necesitan validación visual en Android.

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
└── tools/build_steve_actor.py
```

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta en el directorio `mods` de SM64CoopDX.
4. Inicia un nivel. DynOS lee los archivos `.inc.c` de ambos actores y genera los recursos binarios durante la carga del pack.
5. Comprueba el modelo de Steve y el brazo 3D en primera persona.

En multijugador, instala el mod en cada cliente que deba mostrar a Steve.

## Compatibilidad DynOS

El exportador elimina los `CUSTOM_CMD()` vacíos que Fast64 añade y que el parser GeoLayout del fork Android no reconoce. Si queda alguno, la compilación falla. El registro Lua rechaza tanto `E_MODEL_NONE` como `E_MODEL_ERROR_MODEL`, en lugar de aplicar un ID de modelo inválido.

## Validación

GitHub Actions comprueba la sintaxis Lua y genera los recursos fuente. Eso no sustituye la prueba dentro de SM64CoopDX Android. Sigue pendiente comprobar en el dispositivo la carga de ambos actores, su escala/posición, las animaciones y la ausencia de oclusión inesperada.
