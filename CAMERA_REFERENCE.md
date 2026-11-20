# Cámara de SteveCraft — referencia Minecraft Java 26.3

## Referencia de comportamiento

Se usa una referencia comunitaria de código decompilado 26.x; no es una publicación oficial del código fuente de Mojang:

- net.minecraft.client.Camera: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/client/camera/
- net.minecraft.client.Minecraft: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/client/minecraft/
- net.minecraft.world.entity.Entity: https://mc-packet-reference.netlify.app/26.x/source/net/minecraft/world/entity/entity/

El port independiente de minecraft_26_3_camera.lua reproduce las operaciones matemáticas relevantes: posición interpolada del jugador más altura de ojos interpolada, interpolación angular, cambio de yaw/pitch para tercera persona frontal, distancia trasera predeterminada de cuatro bloques y recorte de distancia con ocho rayos alrededor del origen de la cámara.

El algoritmo de los rayos espera un callback que represente el raycast del mundo Minecraft con forma VISUAL y sin fluidos. No se debe pasar el adaptador de triángulos SM64 como si fuera equivalente a ese raycast.

## Integración con SM64CoopDX

camera.lua conecta el port de ángulos con las tres perspectivas del mod:

1. Primera persona: cámara de brazo/viewmodel de Steve.
2. Tercera persona trasera: NEWCAM, rotación táctil y colisión nativa.
3. Tercera persona frontal: misma cámara nativa con el yaw de órbita igual al yaw de avance de Steve (el campo de SM64 describe foco→cámara, no la dirección óptica).

La API Lua documentada deja Camera.yaw como campo editable, pero Camera.pos, Camera.focus y las posiciones de LakituState son de solo lectura. Por tanto, el mod no puede trasladar el resultado XYZ de Camera.getMaxZoom directamente a la cámara nativa. NEWCAM sigue calculando el posicionamiento final y su prevención de clipping.

## Qué está portado y qué no

- Portado y probado como matemáticas independientes: interpolación, perspectiva frontal/trasera, distancia objetivo y recorte de ocho rayos.
- Conectado al juego: modos 1P/3P y yaw inicial de la perspectiva frontal.
- Aún no integrado: raycast de bloques VISUAL, cálculo directo de la posición/foco de la cámara y paridad completa del movimiento táctil de Minecraft.
- No verificado: comportamiento real en SM64CoopDX Android; requiere prueba en el dispositivo.

El límite no es una falta de ecuaciones Java. La API Lua actual no permite escribir la posición/foco de Lakitu ni reproduce el raycaster de bloques. Cambiar esas dos limitaciones requeriría modificar el motor, lo que está fuera del diseño independiente de SteveCraft.
