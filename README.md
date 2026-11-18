# SteveCraft 64

Mod para **SM64CoopDX**, adaptado al fork Android de ManIsCat2. Reemplaza el personaje por Steve con proporciones clásicas de Minecraft y ofrece tres perspectivas.

## Versión

**0.7.0-alpha** — tres perspectivas y modelo de Steve reajustado.

## Cámara

- El botón **Y** alterna en ciclo: primera persona → tercera persona trasera → tercera persona frontal.
- Las dos vistas de tercera persona usan `CAMERA_MODE_ROM_HACK` del fork.
- Distancia objetivo: 400 unidades de SM64CoopDX; altura de cámara: 160.
- La cruceta controla la órbita: arriba recentra detrás de Steve, izquierda/derecha giran y abajo ajusta el ángulo a incrementos de 45°.
- Se activan las colisiones de cámara del motor para evitar atravesar paredes.
- Al volver a primera persona se restaura la cámara y la configuración previa de ROM_HACK.

## Modelo

El generador usa las proporciones del modelo clásico de Minecraft Java:
- Cabeza: 8×8×8
- Torso: 8×12×4
- Brazos: 4×12×4
- Piernas: 4×12×4

Se mantiene la jerarquía de huesos de jugador de SM64CoopDX para que el motor pueda animar el personaje. El modelo fuente se escala a 0.5 en el GeoLayout para que tenga una altura visible a la distancia de cámara seleccionada.

La mano independiente de primera persona usa una skin clásica de 64×64, recortada a seis texturas pequeñas con filtrado por punto.

## Animaciones

Steve conserva el conjunto de animaciones de jugador compatible del motor. `animations.lua` también reimplementa las ecuaciones de marcha y agachado de `HumanoidModel.setupAnim` de Minecraft Java 1.21.11.

**Las nuevas curvas todavía no están horneadas a clips SM64.** El API Lua expone las rotaciones de huesos del jugador como solo lectura; para aplicarlas hace falta generar arrays de animación con el orden correcto de los 21 segmentos del esqueleto. No se declara esa conversión como terminada.

## Estructura

```text
sm64coopdx-stevecraft/
├── main.lua
├── camera.lua
├── character.lua
├── first_person_hand.lua
├── animations.lua
├── actors/
│   ├── steve/
│   └── steve_hand/
├── assets/steve/
└── tools/
    ├── build_steve_actor.py
    └── build_steve_hand.py
```

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en el directorio `mods` de SM64CoopDX.
4. Inicia un nivel y usa el botón Y para cambiar de perspectiva.

## Validación

GitHub Actions valida la sintaxis Lua y genera los recursos de actor. Eso no sustituye la prueba dentro del juego Android. Siguen pendientes la confirmación visual de las tres perspectivas, el encuadre, las colisiones en todos los niveles y la conversión de clips personalizados.
