# MarioCraft / SkyCraft: qué se reutilizó

## Resultado de la investigación

MarioCraft no trae un motor de físicas de Minecraft independiente que se pueda copiar a Lua. Ejecuta un Minecraft Java real en segundo plano: Minecraft calcula las velocidades, gravedad, salto, fricción y sprint. SkyCraft añade un solucionador de colisiones triangulares para adaptar el movimiento de ese jugador a la geometría del otro juego.

Por eso, el componente de código reutilizable para SteveCraft es el solucionador geométrico de SkyCraft, no el movimiento Java completo ni la integración Windows de MarioCraft.

## Adaptación incluida

- `tri_collider.lua`: port Lua de la geometría de `SkyTri` y `TriCollider`.
- `sm64_collision_adapter.lua`: reúne superficies de SM64CoopDX usando sus funciones Lua documentadas: `find_floor`, `find_ceil`, `collision_get_temp_wall_collision_data`, `find_wall_collisions` y `get_surface_from_wcd_index`.
- `physics.lua`: usa el resultado como pre-recorte de la velocidad/desplazamiento antes del paso de física nativo.

La matemática adaptada cubre:
- subpasos horizontales para reducir el paso a través de paredes;
- empuje lateral y deslizamiento contra paredes;
- muestreo de varias posiciones bajo los pies;
- subida de superficies pequeñas dentro del límite de escalón;
- seguimiento del suelo al descender;
- recorte vertical contra techos;
- subdivisión adicional de desplazamientos largos.

El objeto visual de Steve no recibe física propia. El adaptador opera sobre el único `MarioState`, y SM64CoopDX sigue ejecutando el paso físico original después del pre-recorte.

## Diferencias respecto a MarioCraft

MarioCraft/SkyCraft mueve un jugador Minecraft real contra triángulos exportados al cliente Fabric. SteveCraft no ejecuta Minecraft Java, no tiene Fabric y no recibe una copia completa del mundo en memoria compartida.

El adaptador Lua consulta las superficies del nivel a demanda. No modifica los pools de colisión ni lee memoria del motor. Esto significa que el port es una adaptación, no una reproducción exacta del bridge original.

MarioCraft también exporta un indicador `TRI_WALKABLE` para ciertas rampas especiales. La API Lua disponible no expone ese indicador del exportador personalizado; SteveCraft usa la normal de la superficie y reconoce las superficies SM64 no resbaladizas con un umbral más bajo. Algunas rampas especiales pueden comportarse de forma distinta.

## Lo que no se copió

- El cliente Minecraft Java/Fabric oculto que MarioCraft inicia con Prism Launcher.
- El puente de memoria compartida de Windows.
- Los cambios C de MarioCraft en el núcleo de SM64CoopDX.
- El sistema de renderizado de bloques y entidades de Minecraft.
- El sistema de combate, inventario, minería, construcción, mobs, multijugador Minecraft y exportación de mundo.

Eso requiere una arquitectura distinta y/o modificar el motor, incompatible con el objetivo actual de un mod Lua independiente para Android.

## Activación y reversión

El pre-recortador está activo por defecto cuando las funciones Lua de colisión están disponibles.

Se puede desactivar en runtime:

```lua
SteveCraft.physics.set_triangle_collision_enabled(false)
```

Y volver a activar:

```lua
SteveCraft.physics.set_triangle_collision_enabled(true)
```

La versión debe considerarse experimental hasta probarla en SM64CoopDX Android. Las pruebas automatizadas cubren el algoritmo y un adaptador simulado; no sustituyen la prueba del juego real ni miden el coste de las consultas en el teléfono.

## Fuentes y licencias

- [MarioCraft](https://github.com/Boom64dude/MarioCraft), licencia MIT; su README describe el Minecraft Java oculto y el reparto de responsabilidades.
- [SkyCraft](https://github.com/chasmlol/SkyCraft), commit `bfcaf17`, licencia MIT. El port se basa en `TriCollider.java` y `SkyTri.java`.
- [SM64CoopDX Lua functions](https://github.com/coop-deluxe/sm64coopdx/tree/8cd6e5977d9f920d51ca71f2c61801d019ed79c6/docs/lua): referencia de las consultas de superficies utilizadas.

Los avisos completos de las licencias están en `THIRD_PARTY_NOTICES.md` y en `licenses/`.
