# Revisión de condiciones y recargas — 18 nov 2026

Revisión de condiciones y recargas. Los cambios se aplicaron idénticos en Mac y Windows. No cambió el servidor,
los binarios, el protocolo, las palabras ni el costo de los hechizos.

## Comportamiento

- Invisibility tiene un nuevo indicador con la imagen existente `SpellIcons.invisible` (hoja
  `defaultspells`, recortada por `Spells.getImageClip`). Se activa al recibir un outfit invisible del
  servidor, también al entrar con un anillo equipado. No tiene segundos inventados. Un cambio de outfit
  lo apaga al terminar; Chameleon no se confunde con invisibilidad.
- Seed of Life tiene un ícono para la curación que recibís y otro apagado para la recarga de tu hechizo.
  Recibir la semilla de otro druida no enciende tu recarga. Si recibís dos, florecer la primera conserva
  la segunda hasta que también florezca o se marchite.
- Los contadores guardan plazos absolutos en `g_clock.millis()`: una pausa del event loop no agrega
  segundos. Recibir un mensaje de fin tampoco reinicia la recarga.
- Los tres paneles usan filas de íconos. La barra superior ocupa como máximo el 55 % del espacio de
  las barras, y agrega filas al achicarse la ventana. Health Info conserva visibles sus condiciones;
  Health Info e inventario ajustan su altura según las filas. Minimizar mantiene la altura cerrada;
  maximizar vuelve a calcular las filas.

Los estados clásicos siguen `onStatesChange`; los buffs nuevos siguen `registerMessageMode` y sus
avisos del servidor. `utana vid` se obtiene de `onOutfitChange` / `isInvisible`, que el binario actual
expone. La luz se refleja en la iluminación; Challenge cambia el target de los monstruos. No se
infieren estados a partir de haber escrito las palabras del hechizo.

## Archivos tocados

Estas rutas se modificaron tanto en `mac/` como en `windows/`:

| Ruta relativa a la plataforma | Cambio |
|---|---|
| `modules/game_inventory/inventory.lua` | Invisibilidad, semillas, plazos, filas del inventario |
| `modules/game_healthinfo/healthinfo.lua` | Condiciones visibles, altura según filas, minimizar/maximizar |
| `modules/game_topbar/topbar.lua` | Ancho y filas según condiciones y espacio disponible |
| `modules/game_topbar/topbar.otui` | Grilla superior |
| `data/styles/40-healthinfo.otui` | Grilla del layout base |
| `data/styles/40-inventory.otui` | Grilla del layout base |
| `layouts/retro/styles/40-healthinfo.otui` | Grilla del layout retro |
| `layouts/retro/styles/40-inventory.otui` | Grilla del layout retro |

Compartidos: este documento, `Contexto/MEMORY.md`, `tests/status_icons.lua` y `tests/status_icons_ui.lua`.
No se agregó ningún archivo de imagen: se reutiliza el arte del propio cliente.

## Pruebas

Desde la raíz de este repo:

```sh
luajit tests/status_icons.lua mac
luajit tests/status_icons.lua windows
git diff --check
```

Resultado: **162 comprobaciones por plataforma**, sobre las tres copias del ícono. Incluye todos los
buffs con mensaje, recargas solas, mensajes de fin, pausas, semillas de otros druidas, dos semillas
simultáneas, invisibilidad y cancelación de eventos al salir. Usa el catálogo y el código real de cada
plataforma; solo simula widgets, reloj y scheduler.

`tests/status_icons_ui.lua` se ejecutó además con el **binario Mac distribuido**, XQuartz y las imágenes y
estilos de esta copia. Sin login ni conexión al servidor: envía los avisos por `g_game.onTextMessage` y
comprueba geometría y contenido de widgets reales. Mostró 21 indicadores (8 clásicos + 13 de hechizos),
probó ventana ancha y angosta, varias filas en los tres paneles, minimizar/maximizar y retirada de íconos.
Todas las aserciones pasaron; al cerrar el HUD de prueba el motor emitió un aviso de widget sin destrucción
explícita. No hubo errores de Lua. No sustituye el recorrido visual manual en el juego ni prueba el binario
de Windows.

Para repetir la prueba de motor, usar una **copia temporal** de `mac/` con sus `data/`, `layouts/`,
`modules/`, `init.lua` y el binario distribuido. En el `init.lua` de esa copia poner un `APP_NAME` exclusivo
(por ejemplo `retro76_status_qa`) y `Services.updater = ""`. Copiar `tests/status_icons_ui.lua` como
`status_qa.lua` en esa copia y agregar al final del `init.lua`:

```lua
scheduleEvent(function() dofile('/status_qa.lua') end, 2000)
```

Abrir el binario con el `DISPLAY` de XQuartz, sin usar la configuración de una instalación habitual.
La prueba termina sola y debe imprimir:

```text
STATUS_QA: real UI PASS; icons=21, top=18, health=58
STATUS_QA: narrow layout PASS; top=254x36
STATUS_QA: minimize/maximize/cleanup PASS
```

Las dimensiones exactas pueden variar con el tamaño inicial de la ventana; las aserciones verifican
que los íconos entren. Falta la comprobación visual in-game en Mac y Windows. La publicación usa `publish_client.py` y requiere
autorización de Gonzalo según el contrato de `serverrepo`.
