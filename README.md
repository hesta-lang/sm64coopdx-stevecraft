# SteveCraft 64

Mod Lua para **SM64CoopDX Android** que sustituye al jugador por Steve de Minecraft Java 1.21.11, con modelo cúbico, skin clásica, animaciones adaptadas, cámara en primera/tercera persona y movimiento inspirado en Minecraft.

**0.14.0-alpha** — nueva ruta de modelado con IA basada en el template oficial de SM64CoopDX, referencias originales de Minecraft Java 1.21.11 y conversión Fast64/DynOS automatizada.

## Nuevo flujo de modelo 3D (alpha)

- Ejecuta [Prepare Steve AI model kit](https://github.com/hesta-lang/sm64coopdx-stevecraft/actions/workflows/prepare-steve-ai-model-kit.yml) para obtener el kit con el modelo fuente Java, la skin original y el template Blender de SM64CoopDX.
- Sigue las instrucciones de [AI_MODEL_PROMPT.md](AI_MODEL_PROMPT.md) o la ruta web descrita en [AI_MODEL_PROMPT_WEB.md](AI_MODEL_PROMPT_WEB.md).

- Para trabajar desde el navegador del teléfono, usa [AI_MODEL_PROMPT_WEB.md](AI_MODEL_PROMPT_WEB.md) y [AI 3D Editor](https://ai3deditor.com/); el archivo final debe ser `ai-model/steve_compatible.fbx`.
- Para un agente que edite directamente escenas Blender, usa `AI_MODEL_PROMPT.md`; el archivo final debe ser `ai-model/steve_compatible.blend`.
- El resultado debe subirse como `ai-model/steve_compatible.blend` a la rama `stevecraft-ai-model-pipeline-alpha`.
- El workflow [Convert AI Steve Blender model to DynOS](https://github.com/hesta-lang/sm64coopdx-stevecraft/actions/workflows/convert-ai-steve-model.yml) valida la escena y exporta el actor.

El modelo 3D generado por IA todavía no está incluido. La exportación no se ejecutará hasta que se suba el archivo Blender compatible. El modelo anterior queda como provisional.



## Correcciones de modelo y texturas

- El generador ahora convierte las posiciones de Minecraft al espacio local de cada malla teniendo en cuenta la rotación de 90° del objeto de malla del template oficial de SM64CoopDX.
- Esto evita intercambiar los ejes de anchura y profundidad, que colocaba las extremidades en el plano equivocado.
- Las UV se siguen obteniendo de las regiones originales de la skin clásica 64×64 y se exportan usando el nombre de capa `UVMap` que exige Fast64.
- Las capas base y externas de PlayerModel (cabeza, torso, brazos y piernas) siguen separadas por cubo/material para respetar el límite de memoria de texturas del renderizador.
- El exportador DynOS conserva el esqueleto oficial del jugador; no se cambia la cámara para ocultar la orientación incorrecta.

## Movimiento

- **Correr:** doble toque hacia delante. Aplica el aumento de velocidad del 30% y activa la animación de correr.
- **Saltar:** impulso y gravedad inspirados en Minecraft Java 1.21.11.
- **Salto vertical:** al despegar se ponen a cero las velocidades horizontales X/Z, el avance y el deslizamiento. Durante toda la fase aérea no se aplica control horizontal. Esto también se aplica al saltar mientras corres.
- **Doble/triple salto:** las transiciones nativas de Mario se convierten en salto normal.

El salto ya no reproduce el impulso horizontal de 0.2 bloques/tick de Minecraft al saltar corriendo. Se omite deliberadamente porque el requisito actual es que Steve solo se desplace verticalmente al saltar.

## FOV

- Primera persona: modificador de sprint 1.15× con interpolación.
- Tercera persona: preset nativo de 60° durante sprint. Es una aproximación, no una reproducción exacta de 1.15×; la API Lua del fork no expone un FOV arbitrario editable para LakituState.

## Cámara

Pulsa **Y** para alternar entre primera y tercera persona. En tercera persona, arrastra en la zona táctil derecha para orbitar alrededor de Steve.

La cámara no es una reimplementación completa de `net.minecraft.client.Camera`: la API Lua no permite escribir directamente `LakituState.pos/focus`. Se reutiliza NEWCAM para seguimiento, entrada táctil y prevención de clipping.

## Modelo y skin

El generador utiliza las dimensiones, cubos, capas exteriores y UV del modelo PlayerModel de Minecraft Java 1.21.11: cabeza 8×8×8, torso 8×12×4, brazos y piernas 4×12×4. La skin 64×64 se divide en texturas por cubo para ajustarse a los límites del renderizador F3D/DynOS.

El render final sigue siendo el de SM64CoopDX. No se importa el renderizador Java de Minecraft.

## Límites actuales

- La equivalencia entre bloques Minecraft y unidades SM64 sigue siendo provisional.
- El doble toque se calcula desde la dirección del joystick táctil de SM64; no es el sistema original de teclado de Minecraft.
- El salto es deliberadamente vertical y no tiene movimiento horizontal aéreo.
- Las colisiones siguen siendo las de superficies SM64, no AABB/voxels de Minecraft.
- Todavía no se implementan físicas de agua/lava, modificadores individuales de bloques ni paridad física multijugador.
- Un build correcto de DynOS y un análisis sintáctico Lua no sustituyen la prueba del APK Android.

## Referencia de ingeniería inversa

La adaptación utiliza como referencia una decompilación comunitaria de Minecraft Java 1.21.11, no una publicación oficial del código de Mojang:

- [LivingEntity.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/world/entity/LivingEntity.java)
- [LocalPlayer.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/player/LocalPlayer.java)
- [AbstractClientPlayer.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/player/AbstractClientPlayer.java)
- [Entity.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/world/entity/Entity.java)
- [GameRenderer.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/renderer/GameRenderer.java)
- [PlayerModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/player/PlayerModel.java)
- [HumanoidModel.java](https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/HumanoidModel.java)

## Instalación

1. Descarga el repositorio como ZIP.
2. Extrae la carpeta completa.
3. Copia la carpeta del mod en `mods` de SM64CoopDX.
4. Inicia un nivel y selecciona Steve como modelo si no se activa automáticamente.

## Validación

GitHub Actions debe generar de nuevo los recursos DynOS y validar todos los scripts Lua. Después hace falta probar en SM64CoopDX Android: orientación vertical, visibilidad de brazos/piernas, detalles de la skin, doble toque de sprint, salto vertical sin deriva lateral, aterrizaje, colisiones y FOV.
