# SteveCraft 64

Mod para **SM64CoopDX**, adaptado al fork Android de ManIsCat2. Reemplaza al jugador por Steve con geometría cúbica y una cámara en tercera persona controlada por el tacto.

## Versión

**0.9.0-alpha** — cámara nativa de tres perspectivas con control táctil directo y colisiones por raycast.

## Cámara

- Y recorre las tres perspectivas de Minecraft: primera persona, tercera persona trasera y tercera persona frontal.
- El motor nativo coloca la cámara a cuatro bloques de Steve en tercera persona y recorta la distancia mediante ocho rayos de colisión contra la geometría del nivel.
- Arrastra un dedo por una zona libre de controles en la mitad derecha de la pantalla para mirar alrededor. El gesto no captura los botones virtuales.
- La orientación es inmediata; la cámara no depende de la interpolación de Lakitu ni de los botones C.
- La dirección de movimiento se calcula respecto al ángulo de la cámara.
- La configuración previa de mouse-look y sensibilidad se restaura al salir del juego.

## Modelo

El actor usa las proporciones clásicas del modelo de Minecraft:
- Cabeza: 8×8×8
- Torso: 8×12×4
- Brazos: 4×12×4
- Piernas: 4×12×4

Se mantiene la jerarquía de huesos de jugador de SM64CoopDX. La escala raíz es 1.0. El exportador establece colores primitivos independientes para piel, pelo, ojos, camiseta, pantalón, zapatos y variante metálica; esto evita que las superficies salgan blancas por depender de vértices `SHADE` que se exportan en blanco.

La mano independiente de primera persona usa la skin clásica de Steve 64×64, recortada a seis texturas pequeñas con filtrado por punto.

## Animaciones

Steve conserva el conjunto de animaciones de jugador compatible del motor. `animations.lua` reimplementa las fórmulas de marcha y agachado de `HumanoidModel.setupAnim` de Minecraft Java 1.21.11.

Las curvas personalizadas aún no están horneadas en clips SM64. El API Lua expone las rotaciones de huesos del jugador como solo lectura; para aplicarlas es necesario generar arrays con el orden correcto de los 21 segmentos del esqueleto.

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en el directorio `mods` de SM64CoopDX.
4. Inicia un nivel. Pulsa Y para recorrer primera persona, tercera persona trasera y tercera persona frontal. Arrastra sobre una zona libre de controles de la mitad derecha para mirar.

## Validación

GitHub Actions valida la sintaxis Lua y genera los recursos DynOS. Eso no sustituye la comprobación dentro del juego Android. Siguen pendientes la confirmación visual del nuevo render, el tacto en el dispositivo y la ausencia de oclusión en todos los niveles.
