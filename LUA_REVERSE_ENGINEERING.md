# SteveCraft — Lua-only reverse engineering

## Scope

Objetivo: adaptar al jugador de Minecraft Java 1.21.11 (modelo, animaciones, cámara y movimiento) como mod Lua de SM64CoopDX. No se intenta portar el motor de bloques, el renderizador Java ni toda la simulación de Minecraft.

La referencia es una decompilación comunitaria de Minecraft Java 1.21.11, no una publicación oficial de Mojang. La implementación es una adaptación independiente a las APIs Lua disponibles.

## Correr

Minecraft Java 1.21.11 permite activar el sprint mediante doble toque hacia delante. SteveCraft detecta ese patrón a partir de la magnitud y dirección calculadas por el joystick de SM64CoopDX:

- Ventana aproximada de segundo toque: 11 frames a 30 Hz.
- Multiplicador de velocidad base: 1.3.
- El sprint termina al soltar la dirección hacia delante.
- La animación de Steve cambia al clip de correr durante el sprint.

## Salto vertical

La referencia de salto es `LivingEntity.jumpFromGround()` y `Entity.applyGravity()`:

- Impulso vertical de referencia: 0.42 bloques/tick.
- Gravedad base de referencia: 0.08 bloques/tick².
- Arrastre vertical ordinario de referencia: 0.98 por tick.

La adaptación convierte esos coeficientes de 20 TPS a 30 actualizaciones/s y usa la escala provisional de bloques a unidades SM64.

**Diferencia deliberada respecto a Minecraft:** el usuario requiere que el salto no tenga desplazamiento horizontal. Por eso, al entrar en `ACT_JUMP`:

- Se borran `vel.x` y `vel.z`.
- Se borran `forwardVel`, `slideVelX` y `slideVelZ`.
- Durante cada paso aéreo se vuelve a fijar X/Z a cero después de que Mario procese su input nativo.
- No se aplica control horizontal aéreo ni el impulso lateral sprint-jump de 0.2 bloques/tick.
- La velocidad vertical continúa usando el solver de colisiones SM64 para resolver suelo y techo.

Los saltos dobles/triples de Mario se redirigen a `ACT_JUMP` para evitar saltos que no existen en Minecraft. El sprint terrestre permanece activo, pero saltar mientras corres sigue siendo estrictamente vertical.

## Modelo y texturas: corrección de ejes

El template oficial de SM64CoopDX usa mallas parentadas a armatures con una rotación local de +90° en X. El generador anterior escribía posiciones calculadas en el espacio del armature directamente en los vértices locales de la malla; el objeto volvía a aplicar su rotación al exportar, intercambiando anchura y profundidad. Esto colocaba las extremidades en el plano equivocado.

La generación actual:
1. Calcula la posición del cubo Minecraft en coordenadas del armature.
2. Obtiene la transformación de la malla respecto a su armature.
3. Aplica la inversa de esa matriz antes de guardar el vértice en el espacio local de la malla.

Se aplica tanto al cuerpo principal como a la cabeza capless. El exportador genera la capa UV con el nombre exacto `UVMap` requerido por Fast64. Las UV siguen basándose en las seis caras de `ModelPart.Cube` y en los recortes del atlas 64×64.

## Límites

- La escala de mundo `160 / 1.8` unidades SM64 por bloque sigue siendo provisional.
- El input de sprint es una aproximación adaptada al joystick táctil.
- El salto es vertical solamente, intencionalmente distinto al salto corriendo original de Minecraft.
- Se mantienen las colisiones por superficies SM64; no hay colisiones AABB/voxels de Minecraft.
- Agua/lava, modificadores de bloques, escalada y paridad física multijugador quedan pendientes.
- Una validación CI no sustituye las pruebas en el APK Android.

## Aceptación

- [ ] Steve se renderiza vertical y con proporciones correctas.
- [ ] Ambas extremidades quedan separadas del torso.
- [ ] Cara, pelo, camiseta, brazos y pantalones usan las regiones correctas de la skin.
- [ ] Doble toque hacia delante activa y desactiva el sprint.
- [ ] Saltar no cambia X ni Z y no conserva deriva lateral.
- [ ] La colisión con suelo y techo sigue funcionando.
- [ ] La cámara táctil y el FOV siguen funcionando.
- [ ] No se necesita añadir C++ al APK.
