# Cursor, crosshair y highlight bajo el puntero

Documentación de las tres capas visuales del puntero en el cliente Retro76 (OTClient 7.60).

---

## Resumen de defaults (Retro76)

| Opción | Clave en `g_settings` | Default Retro76 | Default stock OTClient |
|--------|----------------------|-----------------|------------------------|
| Crosshair | `crosshair` | `1` — **None** | `2` — Default |
| Highlight bajo cursor | `highlightThingsUnderCursor` | `false` | `true` |

Los nuevos jugadores (sin `config.otml` previo) reciben los defaults Retro76 vía `g_settings.setDefault` en `client_options/options.lua`.

---

## 1. Cursor del sistema (`g_mouse`)

El cursor del SO se reemplaza por sprites definidos en `data/cursors/cursors.otml` (y opcionalmente en `layouts/<layout>/cursors/`).

| Nombre | Uso típico |
|--------|------------|
| `pointer` | Cursor normal sobre la UI y el mapa |
| `target` | Modo “apuntar” al arrastrar ítems o usar “with crosshair” en hotkeys/action bar |
| `text` | Campos de texto editables |
| `horizontal` / `vertical` | Splitters redimensionables |

**Carga:** `modules/client_styles/styles.lua` → `g_mouse.loadCursors(...)`.

**Push/pop:** módulos como `game_interface`, `gamelib/ui/uiitem.lua`, `game_actionbar` y `game_hotkeys` llaman `g_mouse.pushCursor('target')` al entrar en modo uso sobre mapa/objeto y `g_mouse.popCursor('target')` al salir.

El cursor **no** tiene opción en el menú Options; es comportamiento del motor según contexto (arrastre, hotkey con crosshair, etc.).

**Archivos relevantes:**
- `data/cursors/cursors.otml`
- `data/cursors/*.png` (sprites referenciados en el OTML)
- `modules/client_styles/styles.lua`

---

## 2. Crosshair en el mapa

Overlay gráfico **centrado en el tile bajo el puntero** dentro del `gameMapPanel`. Independiente del cursor `target`.

| Índice UI (`crosshair`) | Etiqueta en Options | Imagen |
|-------------------------|---------------------|--------|
| `1` | None | `""` (sin overlay) |
| `2` | Default | `/images/crosshair/default.png` |
| `3` | Full | `/images/crosshair/full.png` |

**Configuración:** Options → Interface → combo **Crosshair**.

**Aplicación:** `modules/client_options/options.lua` → `setOption('crosshair', value)` → `gameMapPanel:setCrosshair(path)`.

**Archivos relevantes:**
- `modules/client_options/options.lua` — default y `setOption`
- `modules/client_options/interface.otui` — combo de la UI
- `data/images/crosshair/` — assets del overlay

---

## 3. Highlight things under cursor

Resalta en **amarillo** la criatura o cosa bajo el puntero mientras se mueve el mouse sobre el mapa (sin clic).

**Configuración:** Options → Interface → checkbox **Highlight things under cursor** (`highlightThingsUnderCursor`).

**Implementación:** `modules/game_interface/widgets/uigamemap.lua`:
- `updateMarkedCreature()` dispara cada 100 ms un `onMouseRelease` sintético para recalcular qué hay bajo el cursor.
- `markThing(thing, color)` llama `thing:setMarked(color)` **solo si** `g_settings.getBoolean('highlightThingsUnderCursor')` es verdadero.

Si la opción está desactivada, `markThing` guarda la referencia pero no pinta el borde amarillo.

---

## Migración de settings guardados (v1)

Jugadores que ya tenían un `config.otml` con los defaults stock de OTClient deben pasar a los defaults Retro76 **sin perder elecciones explícitas**.

**Mecanismo:** clave `optionsSettingsVersion` en `g_settings`. Al arrancar `client_options`, antes de registrar defaults:

```
optionsSettingsVersion < 3  →  migración v3 (sin g_settings:exists)  →  optionsSettingsVersion = 3
```

**v3 (2026-07-03):** la v1/v2 usaban `g_settings:exists()`, que **no existe** en el singleton de `g_settings` (solo en el objeto crudo de `g_configs.getSettings()`). La migración marcaba versión pero nunca cambiaba valores. v3 usa `getNumber`/`getBoolean` directo.

**Reglas v1** (solo si la clave ya existía en disco):

| Clave guardada | Valor antiguo (stock) | Acción |
|----------------|----------------------|--------|
| `crosshair` | `2` (Default) | → `1` (None) |
| `highlightThingsUnderCursor` | `true` | → `false` |

**No se migran:**
- `crosshair` en `1` (None) o `3` (Full) — asumimos elección del usuario.
- `highlightThingsUnderCursor` ya en `false`.
- Claves ausentes — `setDefault` aplica el default Retro76 en el primer arranque.

**Código:** `migrateOptionsSettings()` en `modules/client_options/options.lua` (win + mac).

Para futuros cambios de defaults, incrementar `OPTIONS_SETTINGS_VERSION` y añadir un bloque `if version < N then ... end`.

---

## Paridad win/mac

Todo cambio en `modules/client_options/options.lua` debe replicarse en `windows/` y `mac/`.

---

## QA sugerido

1. **Instalación limpia:** sin `config.otml` → crosshair None, highlight desactivado.
2. **config antiguo** con `crosshair=2` y `highlightThingsUnderCursor=true` → tras un arranque, ambos en nuevo default; `optionsSettingsVersion=1`.
3. **config con crosshair=3** → tras migración, sigue en Full.
4. **Segundo arranque** → migración no vuelve a ejecutarse (versión ya 1).
5. Cambiar manualmente en Options → valores persisten entre reinicios.
