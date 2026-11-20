# Cámara de SteveCraft — referencia Minecraft Java 26.3

## Referencia de comportamiento

Se usa una referencia comunitaria de código decompilado 26.x; no es una publicación oficial del código fuente de Mojang:

- net.minecraft.client.Camera: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/client/camera/
- net.minecraft.client.Minecraft: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/client/minecraft/
- net.minecraft.world.entity.Entity: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/world/entity/entity/

El port independiente de `minecraft_26_3_camera.lua` implementa:
- interpolación de posición y altura de ojos;
- interpolación angular de yaw/pitch;
- inversión de yaw/pitch para tercera persona frontal;
- distancia objetivo trasera de 4 bloques;
- recorte de distancia con ocho rayos desplazados y forma de colisión VISUAL sin fluidos.

El algoritmo de los rayos espera un callback de raycast del mundo Minecraft. No se conecta al adaptador triangular SM64, porque los triángulos del nivel no equivalen a los bloques VISUAL de Minecraft.

## Ajustes conectados al juego

### Primera persona

- SM64CoopDX ya usa un FOV de primera persona de 70° como valor predeterminado. SteveCraft conserva el FOV configurado por el usuario; no lo fuerza a 70° si se ha cambiado.
- El punto de ojos nativo del fork está en 120 unidades SM64. Con la conversión actual de 160 unidades por 1.8 bloques, Minecraft requiere 1.62 bloques (144 unidades) de pie y 1.27 bloques al agacharse. SteveCraft escribe la diferencia en el componente editable `gFirstPersonCamera.offset.y`, restaurando el valor original al cambiar a tercera persona/salir.
- El brazo derecho independiente es un cuboide 4×12×4 orientado desde la cámara. Recibe bob de movimiento y swing de ataque con B. No incluye todavía el renderizado de herramienta/objeto en mano ni todas las poses de uso de objeto.

### Tercera persona

- Trasera y frontal usan NEWCAM para conservar el giro táctil y la colisión del fork Android.
- La tercera persona frontal corrige el yaw inicial con el yaw de avance del jugador.
- NEWCAM sigue calculando la posición XYZ y el foco definitivos. Los bindings Lua permiten escribir `Camera.yaw`, pero no `Camera.pos`, `Camera.focus` ni las posiciones `LakituState`. Por eso no es posible imponer desde Lua la distancia exacta de cuatro bloques ni aplicar el resultado del raycast Minecraft a la cámara nativa.

## Qué está portado y qué no

- Portado y probado como matemáticas independientes: interpolación, perspectiva frontal/trasera, distancia objetivo, recorte de ocho rayos y conversión de altura de ojos.
- Conectado al juego: alternancia 1P/3P, yaw inicial frontal, altura de ojos de primera persona y brazo viewmodel orientado a la cámara.
- Aún no integrado: raycast de bloques VISUAL, escritura de la posición/foco final de Lakitu, zoom trasero exacto de cuatro bloques, todos los gestos y curvas de aceleración de cámara de Minecraft, objetos/herramientas en la mano.
- No verificado en Android real: posición final del brazo, altura de ojos, clipping en paredes y seguimiento NEWCAM.

## Límite técnico

La falta de paridad exacta en tercera persona no se resuelve añadiendo más ecuaciones Lua: el motor sigue siendo propietario de la posición/foco final y del raycast de colisión usado por la cámara. Cambiarlo requeriría un hook o binding C/C++ nuevo en SM64CoopDX, lo que modificaría el motor y queda fuera del diseño independiente actual de SteveCraft.
