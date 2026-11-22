# SteveCraft 64

Mod independiente para **SM64CoopDX**, adaptado al fork Android de ManIsCat2. Reemplaza visualmente al jugador por Steve y añade una cámara en primera/tercera persona y una primera versión de físicas y HUD inspiradas en Minecraft.

## Versión

**0.9.0-alpha** — primera integración de ajuste de movimiento y HUD Minecraft.

## Cámara

- Y alterna entre primera y tercera persona.
- En tercera persona se utiliza `CAMERA_MODE_NEWCAM`, el sistema de cámara libre incluido en el fork.
- Arrastra el dedo por la zona táctil derecha (`TOUCH_MOUSE`) para girar la cámara horizontal y verticalmente.
- La cámara conserva colisiones de nivel para no atravesar paredes.
- Las perspectivas trasera y frontal se recorren libremente girando alrededor de Steve.
- Las opciones de cámara que estaban activas antes de entrar a SteveCraft se guardan y se restauran al volver a primera persona.

## Físicas — primera fase

- `physics.lua` aplica límites conservadores a la velocidad horizontal antes de los pasos de física.
- Límite inicial en suelo: **28 unidades del motor**.
- Límite inicial en el aire: **32 unidades del motor**.
- La aceleración, la fricción y el resolvedor nativo de colisiones de SM64CoopDX siguen activos.
- No se modifican todavía el impulso de salto, la gravedad, el agua, las pendientes ni las acciones especiales. Se conservan hasta calibrar los valores en el juego y evitar romper los niveles.

Estos valores son una primera base de pruebas, no una equivalencia exacta de bloques por segundo de Minecraft.

## HUD

- Se oculta el HUD original de Mario mientras el HUD de SteveCraft está activo.
- Punto de mira central en primera persona.
- Barra de acceso rápido de nueve espacios.
- Selector de espacio con los gatillos izquierdo y derecho.
- Diez corazones que representan de forma aproximada la salud de SM64CoopDX.
- Cuadrícula visual de inventario de 36 espacios.

Comandos de chat:
- `/steveinv`: abrir o cerrar la cuadrícula del inventario.
- `/steveinv open`: abrir.
- `/steveinv close`: cerrar.
- `/stevehud off`: desactivar el HUD de SteveCraft y mostrar el HUD original.
- `/stevehud on`: volver a activar el HUD de SteveCraft.

**Limitación actual:** la barra y la cuadrícula son todavía una interfaz visual. No contienen objetos y aún no están conectadas a un sistema de inventario/bloques; `blocks.lua` sigue desactivado.

## Modelo y mano

El actor usa las proporciones clásicas del modelo de Minecraft:
- Cabeza: 8×8×8
- Torso: 8×12×4
- Brazos: 4×12×4
- Piernas: 4×12×4

Se mantiene la jerarquía de huesos de jugador de SM64CoopDX. El modelo utiliza materiales separados para piel, pelo, camiseta, pantalón y zapatos.

La mano independiente de primera persona usa la skin clásica de Steve 64×64, recortada a seis texturas pequeñas con filtrado por punto. Se reajustó su posición para mantenerla dentro del campo visual.

## Animaciones

Steve conserva el conjunto de animaciones de jugador compatible del motor. `animations.lua` reimplementa las fórmulas de marcha y agachado de `HumanoidModel.setupAnim` de Minecraft Java 1.21.11.

Las curvas personalizadas todavía no están aplicadas directamente al esqueleto: SM64CoopDX expone las rotaciones de huesos del jugador como solo lectura desde Lua. Para activarlas hay que generar clips SM64 con el orden correcto de los 21 segmentos.

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en el directorio `mods` de SM64CoopDX.
4. Inicia un nivel. Pulsa Y para cambiar a tercera persona y arrastra sobre la zona derecha de la pantalla para girar la cámara.

## Validación

GitHub Actions comprueba la sintaxis Lua. Esa comprobación no confirma el comportamiento visual ni la sensación de movimiento dentro del juego; la calibración final requiere probarlo en SM64CoopDX Android.
