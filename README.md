# SteveCraft 64

Mod modular para **sm64coopdx**, probado inicialmente en el fork Android de ManIsCat2. El proyecto busca convertir la experiencia de Mario en una experiencia inspirada en Minecraft: personaje cúbico, animaciones propias, físicas y mecánicas de bloques.

## Versión

**0.2.0-alpha** — refactor modular y preparación de los recursos del personaje.

## Estado de esta versión

- La cámara en primera persona continúa activa; es la implementación probada en 0.1.0-alpha.
- El código ahora está separado por sistemas Lua.
- Se incluye una malla OBJ de referencia de Steve formada por seis piezas cúbicas.
- Se documenta el flujo necesario para convertir esa geometría a un modelo de jugador compatible con SM64CoopDX.
- El modelo jugable y las animaciones propias todavía no están activos.
- Las físicas de Minecraft y las mecánicas de bloques todavía no están implementadas.

## Estructura

```text
sm64coopdx-stevecraft/
├── main.lua
├── camera.lua
├── character.lua
├── animations.lua
├── physics.lua
├── blocks.lua
├── assets/
│   └── steve/
│       ├── steve_reference.obj
│       ├── steve_reference.mtl
│       ├── steve_rig_spec.json
│       └── README.md
├── .github/
│   └── workflows/
│       └── lua-check.yml
└── MODEL_PIPELINE.md
```

SM64CoopDX admite mods organizados en carpetas con varios scripts Lua, siempre que la carpeta tenga un archivo `main.lua`. Los recursos de actores se colocan en `actors/`.

## Instalación

1. Descarga el repositorio como ZIP desde GitHub.
2. Extrae la carpeta `sm64coopdx-stevecraft`.
3. Copia la carpeta dentro de la carpeta `mods` que utiliza tu instalación de sm64coopdx.
4. Comprueba que el archivo quede en `mods/sm64coopdx-stevecraft/main.lua`.
5. Inicia el juego y comprueba la cámara dentro de un nivel.

La ubicación exacta de `mods` depende de cómo esté empaquetada la versión Android. Usa la carpeta de mods que exponga tu APK/launcher; no copies el archivo dentro del APK.

## Requisitos del modelo

Un archivo `.obj` no puede asignarse directamente como modelo de jugador. SM64CoopDX utiliza recursos de geometría DynOS, como `actors/steve_geo.bin`, registrados con `smlua_model_util_get_id("steve_geo")`.

La malla OBJ incluida es la fuente geométrica de seis piezas, no el recurso binario final. Consulta [MODEL_PIPELINE.md](MODEL_PIPELINE.md) antes de intentar activarlo.

## Compatibilidad

La cámara utiliza `gFirstPersonCamera.enabled`, `set_first_person_enabled` y los eventos `HOOK_UPDATE`, `HOOK_ON_LEVEL_INIT` y `HOOK_ON_WARP`.

El motor puede cancelar temporalmente la vista en primera persona durante ciertas acciones o secuencias. El mod mantiene activada la configuración, pero no fuerza la cámara contra todas las cancelaciones internas del juego.

## Validación

El workflow **Lua syntax check** comprueba la sintaxis de todos los archivos Lua en cada push y pull request. Una validación sintáctica correcta no sustituye la prueba dentro del juego Android.
