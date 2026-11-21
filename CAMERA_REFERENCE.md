# Cámara de SteveCraft — integración Lua

## Lo que está conectado en el juego

camera.lua registra un controlador de perspectiva y lo aplica cuando el modelo Steve está asignado al jugador local:

1. **Primera persona:** activa set_first_person_enabled(true), deja que gFirstPersonCamera reciba el input táctil del motor y muestra el antebrazo steve_hand_geo como viewmodel.
2. **Tercera persona trasera:** desactiva primera persona, activa NEWCAM, habilita el orbitado táctil y la colisión de cámara; el yaw inicial sitúa la cámara detrás de Steve.
3. **Tercera persona frontal:** usa el mismo NEWCAM, con yaw inicial para colocar la cámara delante de Steve.
4. Pulsa **Y** para cambiar de modo. Otros scripts pueden llamar SteveCraft.set_perspective(0|1|2) o SteveCraft.cycle_perspective().

La primera persona usa el sistema de cámara que ya incorpora SM64CoopDX, no una cámara de Mario antigua superpuesta. La cámara conserva el control táctil nativo. NEWCAM sigue siendo responsable de las posiciones de cámara en tercera persona y de evitar atravesar la geometría del nivel.

## Matemáticas Minecraft

minecraft_26_3_camera.lua reproduce como funciones independientes:
- interpolación de posición y altura de ojos;
- interpolación de yaw/pitch;
- inversión de yaw/pitch de la vista frontal;
- distancia objetivo de tercera persona y modificadores;
- recorte de distancia mediante ocho rayos desplazados.

## Límite real de la API Lua

Los bindings permiten activar la cámara en primera persona y escribir algunos ángulos, pero no exponen la posición/foco de Lakitu como campos escribibles. Tampoco hay un raycaster voxel de Minecraft en un mod Lua de SM64CoopDX. Por ello, una cámara Minecraft completamente independiente, con eye-position y colisión VISUAL idénticas, **no puede conseguirse solo con el mod Lua actual**. Requeriría una API adicional o cambios del motor, lo que violaría el requisito de mantener SteveCraft independiente del APK.

Esta integración sí sustituye el modo de perspectiva y añade un brazo propio, pero no debe anunciarse como paridad total de cámara Minecraft.

## Referencias

- Lua FirstPersonCamera/LakituState: documentación de structs de SM64CoopDX.
- Funciones set_first_person_enabled, obj_set_model_extended y cámara NEWCAM: documentación Lua de SM64CoopDX.
- minecraft_26_3_camera.lua: implementación matemática independiente.
