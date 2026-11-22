# SteveCraft 64

Mod Lua independiente para **SM64CoopDX Android**. No es un APK.

## 0.20.0-alpha

### Movimiento
- Recupera el port de movimiento Minecraft Java 26.3: aceleración, fricción, salto, gravedad, sprint, movimiento aéreo y agua.
- SM64CoopDX sigue ejecutando la resolución final de colisiones. La simulación no sustituye completamente el solver voxel/AABB de Minecraft y necesita calibración dentro del juego.

### Modelo
- Steve conserva el objeto de jugador nativo como autoridad física; no se crea un segundo cuerpo.
- Se incorporan clips muestreados de animaciones Bedrock vinculados a estados de animación de SM64.
- La jerarquía de huesos sigue siendo la compatible con SM64CoopDX. Los estados sin clip asignado conservan la animación nativa.

### HUD
- Usa \`RESOLUTION_DJUI\` en vez de la resolución N64 fija.
- Hotbar de nueve espacios, selección, icono pixelado, contadores, corazones y mira central.
- Panel visual de inventario de cuatro filas.
- \`L\` cambia el espacio seleccionado; \`/steveinv\` y \`/stevehud\` controlan los paneles.
- Los botones táctiles A/B/X/Y/L/R siguen siendo controles nativos del motor. El HUD de SteveCraft es una aproximación gráfica con primitivas DJUI, no las texturas originales de Minecraft.

### Bloques
- \`R\` coloca un bloque de piedra donde apunta la mira; también existe \`/steveplace\`.
- El raycast usa \`collision_find_surface_on_ray\`.
- La colisión se crea con superficies persistentes \`smlua_collision_add_surface\`.
- Las caras internas entre bloques adyacentes se eliminan para evitar paredes invisibles.
- Los objetos se crean con \`spawn_sync_object\` para su replicación en sesiones compatibles.
- El tamaño inicial es 90 unidades SM64. El modelo visible usa temporalmente \`E_MODEL_TTC_PUSH_BLOCK\`, no una textura cúbica original de Minecraft.

**No se incluye romper bloques ni destruir el escenario.**

## Controles

| Control | Acción |
| --- | --- |
| Y | Alternar primera/tercera persona |
| L | Siguiente espacio de la hotbar |
| R | Colocar bloque |
| \`/steveplace\` | Colocar bloque |
| \`/steveinv\` | Abrir/cerrar inventario |
| \`/stevehud\` | Activar/desactivar HUD |

## Validación

GitHub Actions revisa sintaxis Lua y ejecuta pruebas de física, cámara, proxy, colisión y colocación. No ejecuta SM64CoopDX Android; la apariencia, el control táctil, la escala de bloque y la replicación deben probarse en el juego. Esta es una **alpha de reparación**, no una versión final.
