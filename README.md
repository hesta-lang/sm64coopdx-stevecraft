# SteveCraft 64

Mod Lua para **sm64coopdx** que establece la cámara en primera persona como perspectiva predeterminada.

## Versión

**0.1.0-alpha** — primera implementación experimental de cámara.

## Estado actual

- Activa la primera persona al cargar el mod.
- Comprueba cada frame que el ajuste siga habilitado.
- Vuelve a habilitarlo después de inicializar un nivel o completar un warp.
- Todavía no incluye el personaje Steve, físicas de Minecraft, bloques ni inventario.

## Instalación

1. Descarga el repositorio como ZIP desde GitHub.
2. Extrae la carpeta `sm64coopdx-stevecraft`.
3. Copia la carpeta dentro de la carpeta `mods` que utiliza tu instalación de sm64coopdx.
4. Comprueba que el archivo quede en `mods/sm64coopdx-stevecraft/main.lua`.
5. Inicia el juego y comprueba la cámara dentro de un nivel.

La ubicación exacta de `mods` depende de cómo esté empaquetada la versión Android. Usa la carpeta de mods que exponga tu APK/launcher; no copies el archivo dentro del APK.

## Compatibilidad y limitaciones

Utiliza la API Lua documentada por el fork de ManIsCat2: `gFirstPersonCamera.enabled`, `set_first_person_enabled` y los eventos `HOOK_UPDATE`, `HOOK_ON_LEVEL_INIT` y `HOOK_ON_WARP`.

El motor puede cancelar temporalmente la vista en primera persona durante ciertas acciones o secuencias. El mod mantiene activada la configuración, pero no fuerza la cámara contra todas las cancelaciones internas del juego. Esto evita interferir agresivamente con cutscenes y estados especiales.

## Desarrollo

Proyecto independiente para el primer paso de SteveCraft 64. Esta versión solo valida la cámara; el personaje y las mecánicas de Minecraft se desarrollarán después de comprobar esta base en Android.
