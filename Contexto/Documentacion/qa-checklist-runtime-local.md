# QA · Checklist de Runtime Local (cliente ↔ YurOTS en Docker)

> Mantenido por `/qa`. Objetivo: validar end-to-end los features de la rama
> `feat/autostack-y-fixes-actionbar` (ya mergeada a `main`) contra un server
> YurOTS **local** levantado en Docker, sin depender de `retro76.cl`.

## Entorno de prueba

| Pieza | Cómo |
|-------|------|
| Server | `serverrepo/` → `docker compose up -d --build` (expone `7171` juego, `7172` login) |
| Cliente | `clienteretro/windows/Iniciar Cliente.bat` (o `otclient_dx.exe`) |
| Server destino | **local**: `127.0.0.1:7171:760` |

### Prerequisitos de harness (NO commitear — solo para probar en local) — ✅ APLICADOS 2026-07-03

1. ✅ **Cliente — entry de server QA.** Agregado a `windows/init.lua` Y `mac/init.lua`
   (paridad): `["QA Local"] = "127.0.0.1:7171:760"`. (Convive con `ALLOW_CUSTOM_SERVERS=false`
   porque es un entry declarado, no un server custom escrito por el usuario.)
2. ✅ **Server — redirección de mundo.** `serverrepo/.../ots/config.lua`:
   `ip = "127.0.0.1"` (antes `retro76.cl`; en protocolo 7.x el login devuelve esa IP
   como mundo). El boot ahora anuncia `Global IP address: 127.0.0.1`.
3. ✅ **Cuenta de prueba sembrada** (`serverrepo/.../ots/data/`):
   - `accounts/1.xml` → **cuenta nº 1, password `beiss`**, premium.
   - `players/gm beiss.xml` → personaje **`GM Beiss`**, sorcerer, **nivel 300**,
     `access="3"` (GM), backpack con stackables (2152 ×2, 2311 ×10) y lista completa
     de spells (incluye `exura`, `exevo pan`).

**Login en el cliente:** elegir server **QA Local** → cuenta `1` → pass `beiss` → personaje `GM Beiss`.

> Regla de oro: ningún cambio de harness se commitea. Al terminar, **revertir**:
> el entry `QA Local` (win+mac), `ip` del server a `"retro76.cl"`, y borrar
> `accounts/1.xml` + `players/gm beiss.xml`. Dejar la distribución intacta.
>
> Bugs de entorno del server ya corregidos para poder levantarlo (ver MEMORY,
> slug `yurots-docker-bringup-fixes`): Dockerfile `moreutils`, CRLF en
> `docker-start-yurots.sh`, y stubs `queue.xml`/`houseitems.xml`.

---

## Criterios de aceptación por feature

### 1. Arranque / no-regresión (`init.lua`)
- [ ] El cliente abre sin `fatal` (data/ y modules/ existen).
- [ ] Login contra `127.0.0.1:7171` OK → lista de personajes → entra al mundo.
- [ ] HUD monta (`game_interface`) sin errores en consola.
- [ ] Sin `attempt to index a nil value` durante login ni al montar HUD.

### 2. Auto-stack v1 (`game_containers/containers.lua` + `gamelib/ui/uiitem.lua`)
- [ ] Mover un stackable (ej. gold, food) a un contenedor que YA tiene un stack
      del mismo ítem → **se apila** en el slot existente (no crea slot nuevo).
- [ ] Mover a contenedor sin stack existente → cae en slot libre normal.
- [ ] No hay desync tras apilar (sin `no thing at pos` en consola).
- [ ] Ítem no-stackable → comportamiento normal (no intenta merge).

### 3. Fixes de action bar (`game_actionbar/actionbar.lua`)
- [ ] Diálogo de hotkey sobre botón **sin configurar**: botones OK / Clear
      funcionan **sin** `attempt to index a nil value` (guard nil okFunc/clearFunc).
- [ ] `assignHotkey` cierra el diálogo con `closeFunc()` (no `cancelFunc`).

### 4. Texto flotante naranja de spells (`game_console/console.lua`)
- [ ] Castear un spell real (ej. `exura`) → texto flotante **naranja `#F6A731`**
      sobre el pj, **sin** aparecer en el chat (`hideInConsole`).
- [ ] Decir texto normal (no-spell) → flotante **amarillo** y sí aparece en chat.
- [ ] Palabra que NO matchea `Spells.getSpellByWords` → tratada como say normal
      (sin falso positivo naranja).
- [ ] El pending solo aplica al jugador local (no a otros jugadores).

### 5. Defaults de cursor Retro76 (`client_options/options.lua`)
- [ ] `crosshair = 1` (None) por default en instalación limpia.
- [ ] `highlightThingsUnderCursor = false` por default.
- [ ] Sin highlight bajo cursor en el mapa (uigamemap no marca creature).

---

## Paridad win/mac
- [x] `containers.lua`, `actionbar.lua`, `console.lua`, `uiitem.lua`, `options.lua`
      **idénticos** win/mac (verificado por diff — 2026-07-03).
- [ ] Validación runtime en **macOS** (requiere macOS + XQuartz). Pendiente.

---

## Registro de ejecución
| Fecha | Feature | Plataforma | Resultado | Notas |
|-------|---------|------------|-----------|-------|
| 2026-07-03 | Auto-stack v1 | Windows (local) | ✅ OK | Apila al mover stackables sobre stack existente |
| 2026-07-03 | Texto naranja spells | Windows (local) | ⚠️ PARCIAL | Funciona, pero `SpellInfo` del cliente desincronizado con `spells.xml` 7.6 del server → sin naranja en: adori vita vis (Sudden Death), exevo mort hur (Energy Wave), adori, adori blank, adori gran, adori gran flam, death, utani slow. Ver MEMORY slug `client-spellinfo-desync-server76`. Fix `/datos`o`/lua`, paridad win/mac |
| 2026-07-03 | Scroll hero id 1949 | Windows (local) | ℹ️ NO-CLIENTE | "you cannot use this object" = server (item sin flag readable/action). Contenido server, no bug cliente |
| 2026-07-03 | Texto naranja — FIX | win+mac | ✅ OK | `SpellInfo` reconciliado: 6 words corregidos en `Default` + perfil `Retro76` con `adori blank`/`death`. `luac5.1 -p` OK, paridad OK. **Validado en runtime: los 8 en naranja sin chat.** Slug `client-spellinfo-fix-aplicado` |
