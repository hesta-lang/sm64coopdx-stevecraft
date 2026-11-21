# Cámara independiente de SteveCraft — Minecraft Java 26.3

## Arquitectura conectada al juego

La rama `0.22.0-alpha` sustituye el cálculo de posición/foco de la cámara normal por un controlador Lua. No cambia el APK ni añade código C/C++ al fork.

Orden verificado en SM64CoopDX Android:
1. El motor actualiza el objeto jugador y ejecuta `first_person_update()`.
2. Actualiza `OBJ_LIST_UNIMPORTANT`, donde está el objeto de cámara Lua.
3. Llama a `update_camera()`.

El controlador aprovecha ese orden:
- Mantiene habilitado `gFirstPersonCamera` para conservar el estado de orientación/mouse-look que el motor pueda proporcionar.
- `camera_freeze()` hace que `update_camera()` salga antes de aplicar la posición/foco nativos.
- El objeto Lua escribe los componentes XYZ de `MarioState`-eye anchor, `Camera.pos/focus` y `LakituState.pos/curPos/goalPos/focus/curFocus/goalFocus`.
- La cámara no depende de `NEWCAM` para el posicionamiento final. Steve sigue usando `MarioState` como puente de jugador/colisión, no como controlador de cámara.

## Perspectivas y alturas

Pulsa Y para alternar:
- Primera persona.
- Tercera persona trasera.
- Tercera persona frontal.

Altura del origen de cámara:
- De pie: 1.62 bloques sobre los pies.
- Agachado: 1.27 bloques sobre los pies.

La conversión actual usa 160 unidades SM64 por 1.8 bloques. Es la escala activa de SteveCraft y sigue siendo provisional.

Tercera persona:
- Distancia inicial configurable de 4 bloques.
- Vista frontal invierte el yaw y el pitch de la perspectiva.
- La orientación usa yaw/pitch de `gFirstPersonCamera` más el control digital del jugador.
- La cámara conserva el FOV/proyección configurados por el motor. El fork usa 70° por defecto en primera persona; SteveCraft no impone un FOV distinto.

## Controles de mirada

### Android táctil

El controlador Lua lee los campos de botones de `MarioState.controller`:
- D-pad izquierda/derecha: gira yaw.
- D-pad arriba/abajo: gira pitch.
- C-buttons: alternativa si el usuario los activa en el editor de controles táctiles.

Velocidad por defecto: 2 grados por frame. Se puede cambiar:

```lua
SteveCraft.cameraController.set_digital_look_speed(2.0)
```

El backend `controller_touchscreen.c` del fork calcula `touch_x/touch_y` para su control de tipo Mouse, pero no los copia a `MarioState.controller`, no los expone como globals Lua y no dispone de hooks Lua de touch/mouse-move. Por tanto, un mod Lua independiente **no puede leer el arrastre del dedo directamente** en esta versión del fork. Para obtener swipe de estilo Minecraft hace falta un pequeño binding/hook nativo que publique esos deltas a Lua; esta rama no modifica el APK ni el motor.

### Mouse y mandos

Cuando el fork sí actualiza `gFirstPersonCamera.yaw/pitch` mediante el mouse relativo o las entradas analógicas soportadas por el sistema, la cámara Lua reutiliza esos ángulos y controla solamente la transformación final.

## Zoom y colisión

`SteveCraft.cameraController` ofrece:
- `set_distance_blocks(distance)`: configura la distancia objetivo, limitada entre 1 y 8 bloques.
- `get_distance_blocks()`: devuelve la distancia actual.
- `set_digital_look_speed(degreesPerFrame)`: limita y configura el giro digital.
- `get_last_pose()`: devuelve la última pose calculada.
- `get_view_origin(marioState)`: devuelve el ancla de ojos para el viewmodel.

La distancia trasera/frontal empieza en 4 bloques. El recorte conectado hace un barrido de 16 pasos hacia la posición objetivo y consulta paredes, suelo y techo usando las consultas de superficies del nivel SM64; usa radio de cámara aproximado de 0.1 bloques y tres alturas.

**No es un raycast de bloques Minecraft.** La geometría sigue siendo la malla triangular de SM64CoopDX. El módulo independiente `minecraft_26_3_camera.lua` contiene también la matemática de ocho rayos desplazados 0.1 unidades con forma VISUAL sin fluidos, pero esa interfaz espera un raycaster de mundo Minecraft y no se conecta al nivel SM64.

## Validación automatizada

El workflow prueba:
- Primera persona en el ancla de ojos.
- Cambio de altura al agacharse.
- Tercera persona trasera y frontal.
- Distancia de cuatro bloques.
- Recorte contra una pared simulada y restauración del modo de consulta.
- Giro de yaw/pitch con el D-pad táctil.
- Restauración de freeze y del estado original de la cámara al salir.

Los tests usan superficies y objetos simulados. No prueban el orden real de renderizado Android ni sustituyen una prueba dentro de SM64CoopDX en el dispositivo.

## Límites pendientes

- No existe aún un puente Lua para los deltas de swipe táctil; se requiere binding nativo.
- El clipping usa triángulos SM64, no bloques VISUAL Minecraft.
- No están portadas todas las curvas de easing, aceleración/desaceleración ni el cambio dinámico de FOV por sprint de Minecraft.
- La escala y la conversión de unidades siguen siendo provisionales.
- Es necesaria una verificación Android real de primera persona, tercera persona frontal/trasera, giros D-pad, clipping en paredes y la posición del brazo 1P.
