# SteveCraft 64

Mod para **SM64CoopDX**, adaptado al fork Android de ManIsCat2. Reemplaza al jugador por el modelo humanoide de Minecraft Java con su skin de Steve y cámara en tercera persona controlada por el tacto.

## Versión

**0.10.0-alpha** — conversión del modelo PlayerModel de Minecraft Java 1.21.11 a geometría DynOS compatible con el esqueleto de jugador de SM64CoopDX.

## Native C++ port

The next stage is documented in [ENGINE_REVERSE_ENGINEERING.md](ENGINE_REVERSE_ENGINEERING.md). It defines the limited Minecraft model/animation/camera code slice to port into the Android SM64CoopDX engine as native C++, rather than attempting to translate the entire game or placing non-compilable C++ files in a Lua mod.

## Cámara

- Y alterna entre primera y tercera persona.
- En tercera persona se utiliza `CAMERA_MODE_NEWCAM`, el sistema de cámara libre incluido en el fork.
- Arrastra el dedo por la zona táctil derecha (`TOUCH_MOUSE`) para girar la cámara horizontal y verticalmente.
- La cámara conserva colisiones de nivel para no atravesar paredes.
- Las perspectivas trasera y frontal se recorren libremente girando alrededor de Steve; ya no requieren C-buttons ni cruceta.
- Las opciones de cámara que estaban activas antes de entrar a SteveCraft se guardan y se restauran al volver a primera persona.

## Modelo

El generador ya no construye el cuerpo usando cubos coloreados aproximados. Usa las dimensiones, posiciones, capas e instrucciones UV del modelo humanoide de Minecraft Java 1.21.11:

- Cabeza base 8×8×8 y sombrero exterior con inflación de 0.5 píxeles.
- Torso base 8×12×4 y chaqueta exterior con inflación de 0.25 píxeles.
- Brazos anchos 4×12×4 y mangas exteriores.
- Piernas 4×12×4 y pantalones exteriores.

Las 12 piezas cúbicas se asignan a los grupos de huesos compatibles de SM64CoopDX: cabeza, torso, brazos y piernas. El generador adapta los ejes XYZ de Minecraft a las coordenadas del esqueleto del jugador sin sustituir la jerarquía que necesita el motor.

La skin clásica de Steve de 64×64 se recorta usando los rectángulos UV del código de Minecraft. Cada pieza recibe su textura pequeña para mantener los límites de memoria de texturas del renderizador N64. Se conservan los píxeles alfa de las capas externas: una capa totalmente transparente permanece invisible, igual que en Minecraft. El punto de filtrado evita difuminar los texeles.

La variante metálica de Mario se mantiene separada como variante especial del sistema de SM64CoopDX. El actor principal de Steve usa la skin, no la paleta de colores planos anterior.

## Animaciones

`animations.lua` registra clips en el formato nativo de SM64CoopDX y los aplica únicamente a los jugadores que usan el modelo de Steve:

- **Caminar:** curvas de brazos y piernas de `HumanoidModel.setupAnim`.
- **Correr:** misma ecuación de marcha con una amplitud mayor.
- **Agacharse:** inclinación de torso y brazos de Minecraft.
- **Caminar agachado:** combina la marcha con la pose de agachado.
- **Nadar:** curva de brazos y movimiento de piernas del código de Minecraft.
- **Quieto, salto y caída normales:** pose humanoide neutra con el balanceo sutil de brazos. Minecraft no tiene una animación corporal independiente para un salto normal.

El port de animaciones mantiene el esqueleto compatible de SM64CoopDX. Las intensidades de caminar y correr son fijas porque el hook del motor no expone el mismo par dinámico `walkAnimationPos/walkAnimationSpeed` de Minecraft. Los desplazamientos locales del agachado aún requieren validación de escala y ejes.

## Referencia del modelo y las animaciones

La geometría y las coordenadas UV se adaptan de:
- [PlayerModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/player/PlayerModel.java)
- [HumanoidModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/HumanoidModel.java)
- [ModelPart.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/geom/ModelPart.java)

Las animaciones se adaptan de:
- [AnimationUtils.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/AnimationUtils.java)

El repositorio usado como referencia es una copia decompilada mantenida por la comunidad, no una publicación oficial del código fuente de Mojang.

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en el directorio `mods` de SM64CoopDX.
4. Inicia un nivel. Pulsa Y para cambiar a tercera persona y arrastra sobre la zona derecha de la pantalla para girar la cámara.

## Validación

GitHub Actions debe completar la generación del actor DynOS con Blender/Fast64 y comprobar que las texturas del modelo se exportan. Aunque el exportador termine correctamente, todavía falta validar en SM64CoopDX Android que la skin, las capas transparentes, las articulaciones, la cámara táctil y la mano en primera persona se vean correctamente.
