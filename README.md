# SteveCraft 64

Mod para **SM64CoopDX**, adaptado al fork Android de ManIsCat2. Reemplaza al jugador por Steve con proporciones cúbicas de Minecraft y cámara en tercera persona controlada por el tacto.

## Versión

**0.9.0-alpha** — primer port funcional de las curvas de animación humanoide de Minecraft Java y optimización de caras internas del modelo.

## Cámara

- Y alterna entre primera y tercera persona.
- En tercera persona se utiliza `CAMERA_MODE_NEWCAM`, el sistema de cámara libre incluido en el fork.
- Arrastra el dedo por la zona táctil derecha (`TOUCH_MOUSE`) para girar la cámara horizontal y verticalmente.
- La cámara conserva colisiones de nivel para no atravesar paredes.
- Las perspectivas trasera y frontal se recorren libremente girando alrededor de Steve; ya no requieren C-buttons ni cruceta.
- Las opciones de cámara que estaban activas antes de entrar a SteveCraft se guardan y se restauran al volver a primera persona.

## Modelo

El actor conserva las proporciones clásicas de Minecraft:
- Cabeza: 8×8×8
- Torso: 8×12×4
- Brazos: 4×12×4
- Piernas: 4×12×4

Se mantiene la jerarquía de huesos compatible de SM64CoopDX. El exportador usa colores primitivos independientes para piel, pelo, ojos, camiseta, pantalón y zapatos.

La geometría se ha reducido sin alterar la silueta: se eliminan las caras que quedan completamente ocultas entre la manga y la mano de cada brazo, y se comparten los vértices coincidentes de esa unión dentro del mismo grupo rígido. El exportador informa de los vértices, caras y caras omitidas. Se conserva la variante metálica por compatibilidad con el sistema de modelos del juego.

La mano independiente de primera persona usa la skin clásica de Steve 64×64, recortada a seis texturas pequeñas con filtrado por punto.

## Animaciones

`animations.lua` ahora registra clips en el formato nativo de animación de SM64CoopDX y los aplica únicamente a los jugadores que usan el modelo de Steve:

- **Caminar:** curvas de brazos y piernas de `HumanoidModel.setupAnim`.
- **Correr:** misma ecuación de marcha con una amplitud mayor, como hace Minecraft al elevar `walkAnimationSpeed`.
- **Agacharse:** inclinación de torso de 0.5 radianes y +0.4 radianes en ambos brazos.
- **Caminar agachado:** combina la marcha con la pose de agachado.
- **Nadar:** ciclo de 26 unidades de fase, con la curva de brazos y el movimiento de piernas del código de Minecraft.
- **Quieto, salto y caída normales:** pose humanoide neutra con el balanceo sutil de brazos de `AnimationUtils.bobModelPart`. Minecraft no tiene una animación corporal independiente para un salto normal; la pose de planeo con élitros sí inclina la cabeza.

El port no es todavía una reproducción 100 % idéntica: SM64CoopDX no expone el mismo par dinámico `walkAnimationPos/walkAnimationSpeed`, así que caminar y correr usan intensidades fijas (0.60 y 1.00). La pose de agachado aplica las rotaciones, pero deja pendientes los pequeños desplazamientos locales de cabeza, torso, brazos y piernas porque las unidades y ejes del esqueleto SM64 necesitan validación visual. Los clips también usan el esqueleto compatible de SM64, no el esqueleto interno de Minecraft.

## Referencia

Las curvas se adaptaron de la implementación decompilada de Minecraft Java 1.21.11:
- [HumanoidModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/HumanoidModel.java)
- [AnimationUtils.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/AnimationUtils.java)
- [PlayerModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/player/PlayerModel.java)

El repositorio de referencia es una copia decompilada mantenida por la comunidad, no una publicación oficial del código fuente de Mojang.

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en el directorio `mods` de SM64CoopDX.
4. Inicia un nivel. Pulsa Y para cambiar a tercera persona y arrastra sobre la zona derecha de la pantalla para girar la cámara.

## Validación pendiente

GitHub Actions puede comprobar la sintaxis Lua y regenerar los recursos DynOS, pero no demuestra por sí solo que las articulaciones se vean correctamente en Android. La validación final debe comprobar la marcha, el nado, el agachado, las transiciones de salto y que la cámara táctil y la mano en primera persona sigan funcionando.
