# SteveCraft 64

Mod modular para **sm64coopdx**, probado inicialmente en el fork Android de ManIsCat2. El proyecto transforma al jugador en Steve, con cuerpo cúbico y una base preparada para incorporar las físicas, construcción y destrucción de bloques de Minecraft.

## Versión

**0.3.0-alpha** — primer modelo de Steve exportado a DynOS y registrado como personaje de jugador.

## Estado de esta versión

- La cámara en primera persona continúa activa.
- El mod está separado por sistemas Lua.
- Se genera un modelo de Steve a partir de seis piezas cúbicas principales.
- El modelo conserva el esqueleto compatible con SM64CoopDX.
- El jugador usa el conjunto de animaciones integrado del motor: caminar, correr, saltar, caer, aterrizar, daño y muerte.
- El modelo se registra con `smlua_model_util_get_id("steve_geo")` y se aplica con `obj_set_model_extended`.
- Las animaciones personalizadas de Minecraft, físicas y mecánicas de bloques todavía no están implementadas.
- El modelo exportado necesita validación visual dentro del juego Android.

## Estructura

```text
sm64coopdx-stevecraft/
├── main.lua
├── camera.lua
├── character.lua
├── animations.lua
├── physics.lua
├── blocks.lua
├── actors/
│   └── steve/
│       ├── geo.inc.c
│       ├── geo_header.h
│       ├── model.inc.c
│       └── README.md
├── assets/
│   └── steve/
│       ├── steve_reference.obj
│       ├── steve_reference.mtl
│       └── steve_rig_spec.json
├── tools/
│   └── build_steve_actor.py
└── .github/workflows/
    ├── lua-check.yml
    └── build-steve-actor.yml
```

## Instalación

1. Descarga el repositorio como ZIP desde GitHub.
2. Extrae la carpeta `sm64coopdx-stevecraft`.
3. Copia la carpeta completa dentro de la carpeta `mods` utilizada por tu instalación de sm64coopdx.
4. Comprueba que la estructura incluya `main.lua` y `actors/steve/geo.inc.c`.
5. Inicia el juego. SM64CoopDX debe reconocer y compilar el actor DynOS antes de poder mostrarlo.
6. Entra en un nivel y comprueba Steve y la cámara en primera persona.

Instala SteveCraft en cada cliente que vaya a mostrar el modelo en una partida multijugador. La ubicación exacta de `mods` depende de cómo esté empaquetada la versión Android.

## Modelo y animaciones

El actor se exporta con Fast64-Gart desde la plantilla oficial de personaje de SM64CoopDX. Se conserva el armature de jugador y se sustituyen los modelos visibles por piezas cúbicas de Steve. El archivo OBJ de referencia es una fuente geométrica; el juego utiliza los archivos DynOS generados bajo `actors/steve/`.

La versión actual reutiliza las animaciones integradas del esqueleto de jugador. No son todavía las animaciones originales de Minecraft.

## Compatibilidad

La cámara utiliza `gFirstPersonCamera.enabled`, `set_first_person_enabled` y los eventos `HOOK_UPDATE`, `HOOK_ON_LEVEL_INIT` y `HOOK_ON_WARP`.

El registro del modelo espera a que `steve_geo` esté disponible. Si el actor DynOS no se compila o no se carga, el mod no aplica `MODEL_NONE`.

## Validación

GitHub Actions valida la sintaxis Lua y exporta los archivos fuente DynOS con Blender 3.6 y Fast64-Gart. Eso no sustituye la prueba dentro de SM64CoopDX Android: hay que comprobar la carga del actor, las articulaciones, las animaciones y la cámara en el juego real.
