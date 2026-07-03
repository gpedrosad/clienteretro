# MEMORY.md — Aprendizajes del Equipo · Cliente Oficial Retro76

> Índice de contexto cargado al inicio de cada sesión. Formato de entrada: `- [ROL][FECHA] descripción.`

## Aprendizajes del Equipo

### Arquitecto / Tech Lead
- [Arquitecto][2026-07-01] **Este repo (`gpedrosad/clienteretro`) es el repo CANÓNICO del cliente publicado.** Es de DISTRIBUCIÓN: raíz con `README.md` + `build-zips.sh`, y DOS variantes paralelas `windows/` y `mac/`, cada una un cliente OTClient 7.60 completo (`init.lua`, `modules/`, `data/`, `layouts/`, binarios). Motor: OTClientV8 (según README). Server destino: `retro76.cl:7171` protocolo 7.60.
- [Arquitecto][2026-07-01] **REGLA DE ORO: paridad win/mac.** Los `modules/*.lua` son IDÉNTICOS entre `windows/` y `mac/` (Lua cross-platform). Todo cambio de código/assets del cliente se aplica a AMBAS carpetas; tocar solo una rompe la paridad.
- [Arquitecto][2026-07-01] **`build-zips.sh` asume que el repo vive dentro del monorepo del juego** (usa `../scripts/resolve-project-root.sh` y `../web/downloads/`). Como clon standalone no resuelve la raíz — dependencia a considerar en release.
- [Arquitecto][2026-07-03] **El SERVER (`serverrepo`, YurOTS 7.6, `gpedrosad/serverrepo`) ya tiene su propio equipo de agentes.** Montado el scaffolding espejo en `serverrepo/`: `CLAUDE.md`, `AGENTS.md`, `Contexto/MEMORY.md`, `.claude/commands/*` (11 roles) y `.claude/hooks/`. Roster server: `/arquitecto /engine /gameplay /mundo /datos /protocolo /infra /seguridad /qa /auditor /web`. Contratos cliente↔server (los custodia arquitecto+protocolo en AMBOS repos): protocolo **7.60** y **`stackable`** (`items.otb` server ↔ `.dat` cliente `data/things/760`). Incidente abierto del server: cuelgues jul 2026 (`YUROTS_SOCKET_DEBUG=1`).
- [Arquitecto][2026-07-03][OJO] **El guardrail de ESTE repo (`clienteretro/.claude/hooks/guardrail.sh`) es un no-op en esta máquina Windows:** parsea el JSON con `python3`, y `python3` acá es el stub de Microsoft Store (falla) → `TOOL` queda vacío → sale 0 sin bloquear nada. El guardrail nuevo del `serverrepo` se reescribió **sin python3** (grep/sed puro) y quedó verificado (11/11 casos). **Pendiente: portar ese enfoque sin-python al guardrail del cliente** para que los bloqueos de commit/push realmente funcionen.

### Build / Distribución Engineer
- [Build][2026-07-01] **Primeros cambios portados desde el workspace de pruebas** a la rama `feat/autostack-y-fixes-actionbar` (3 commits, cada uno aplicado a `windows/` + `mac/`): guard nil en `game_actionbar/actionbar.lua` (okFunc/clearFunc, ~931/945); `cancelFunc()`→`closeFunc()` en `assignHotkey` (~966); feature auto-apilado v1 (`game_containers/containers.lua` helper `findMergeSlotPosition` + enganche en `gamelib/ui/uiitem.lua:onDrop`). Verificado en runtime (ver QA). **Pendiente: push de la rama a `origin` + PR contra `main`** (requiere OK del usuario).

### Seguridad / Integridad del Cliente
- [Security][2026-07-01][CRITICO] **El cliente PUBLICADO corre Lua editable desde disco** (el que se descarga del sitio). Cualquier jugador puede modificar sus `modules/*.lua`. Las "ventajas" client-side (ej. el auto-apilado de ítems al mover) son en realidad modificaciones que un jugador podría hacerse solo → **superficie de trampa/integridad**. Lo verdaderamente autoritativo (stacking real, loot, combate) debe vivir en el SERVER. Slug: client-lua-editable-security-surface. Revisar a fondo qué mecánicas client-side representan brecha y cuáles mover a autoridad del server.

### Protocolo / Networking Engineer
- [Protocolo][2026-07-01] **El flag `stackable` es contrato cliente↔servidor.** En protocolo Tibia, si un ítem es stackable determina si viaja el byte count/subtype. El `.dat` del cliente (`data/things/760`) y el `items.otb` del server DEBEN coincidir; si no, se desincroniza el parseo de `ProtocolGame` (síntoma: `no thing at pos`). Relevante para cualquier cambio que quiera hacer stackable un ítem que hoy no lo es (ej. comida del hechizo exevo pan — ese fix es SERVER-side en YurOTS, no del cliente).

### QA Engineer
- [QA][2026-07-03] **Bring-up del server YurOTS en Docker para pruebas end-to-end del cliente — 4 bugs de entorno desbloqueados (todos en `serverrepo`, sin commitear).** Para levantar `docker compose up` en `serverrepo` (imagen i386/ubuntu 20.04, expone 7171/7172) hubo que corregir, en orden: (1) **Dockerfile pedía `moreutils`** → no existe para i386/focal, `apt` fallaba exit 100; se quitó (el entrypoint ya tenía fallback sin `ts` y el compose local no lo usa). (2) **`scripts/docker-start-yurots.sh` con CRLF** (repo tiene `core.autocrlf=true` → checkout con `\r`); bash tiraba `set: pipefail: invalid option name` y el `exec ./source/yurots\r` no se hallaba → contenedor exit 2. Fix inmediato: `sed -i 's/\r$//'`. **Durable pendiente (server team): `.gitattributes` con `*.sh text eol=lf`.** (3) falta `data/queue.xml` y (4) `data/houseitems.xml` → archivos de estado runtime que el server genera al `save()`, ausentes en primer arranque; se crearon stubs vacíos (`<queue/>`, `<houseitems/>`, raíz válida). Tras eso: `:: Retro76 Server Running`, 7171/7172 ABIERTOS desde el host. Slug: yurots-docker-bringup-fixes.
- [QA][2026-07-03][OJO] **Loop 100% local necesita 2 ajustes de harness NO commiteables:** (a) server `config.lua` tiene `ip = "retro76.cl"` → el login (7.x) devuelve esa IP como mundo, así el cliente logueado en `127.0.0.1` se redirige a PRODUCCIÓN (log confirma `Global IP address: retro76.cl`). Para aislar: `ip = "127.0.0.1"`. (b) cliente `init.lua` solo lista `retro76.cl` y `ALLOW_CUSTOM_SERVERS=false` → agregar entry temporal `["QA Local"]="127.0.0.1:7171:760"`. Además **no hay cuentas** (`data/accounts/` inexistente; `players/0-4.xml` son plantillas del `accmaker="main"`) → sembrar cuenta de prueba para login. Checklist de aceptación en `Contexto/Documentacion/qa-checklist-runtime-local.md`.
- [QA][2026-07-03] **Harness local APLICADO (por pedido del usuario, todo sin commitear):** server `ip="127.0.0.1"` (boot confirma `Global IP address: 127.0.0.1`); entry `["QA Local"]="127.0.0.1:7171:760"` en `windows/init.lua` Y `mac/init.lua` (paridad); cuenta sembrada `data/accounts/1.xml` (**nº 1 / pass `beiss`**, premium) + personaje `data/players/gm beiss.xml` (**`GM Beiss`**, sorcerer nivel **300**, `access=3` GM, backpack con stackables 2152×2/2311×10 y spells `exura`/`exevo pan`). Login: server QA Local → cuenta 1 → pass beiss → GM Beiss. **Revertir al cerrar:** entry QA Local (win+mac), `ip`→`retro76.cl`, borrar `accounts/1.xml` y `players/gm beiss.xml`. La validación interactiva de la GUI la hace el usuario. Slug: qa-local-harness-aplicado.
- [QA][2026-07-03][OJO server] **Binario `source/yurots` STALE vs fuentes (el docker corre precompilado, NO compila).** `docker-start-yurots.sh` hace `exec ./source/yurots`; el binario commiteado es de Jul 1 22:57 pero `source/protocol76.cpp` (y otras) son de Jul 3 17:07 → el server corre código viejo. Detectado al probar el scroll escribible (1949): el cliente abre la ventana editable OK (lado cliente ✓) pero al guardar salía **"write not working yet"** (string presente solo en el binario, ausente en la fuente: `parseTextWindow` en las fuentes YA implementa `setText`+persistencia). Fix: **recompilar** (`source/Makefile`, `make -j` dentro del contenedor que ya tiene toolchain liblua5.1/libxml2/libboost-regex/zlib). **Recomendación server team: que el Dockerfile/entrypoint COMPILE en vez de correr binario precompilado, o no commitear el binario.** Slug: yurots-stale-binary. **RESUELTO en local:** al recompilar aparecieron **build breaks por includes transitivos perdidos (refactor Jul 3)** → se agregaron 4 includes: `otserv.cpp`+`spawn.h`, `game.cpp`+`spawn.h`, `commands.cpp`+`monster.h`, `spawn.cpp`+`monster.h`. Con eso linkeó limpio (binario Jul 3 18:41, sin el stub "write not working yet"). **Esto es tarea `/engine` server** (las fuentes commiteadas NO compilan sin estos includes). Todo sin commitear.
- [QA][2026-07-03] **Scroll del hero (1949) escribible — RESUELTO por el recompilado, NO era falta de flag.** El server lee `RWInfo` del `items.otb` (`ITEM_GROUP_WRITEABLE`=9 / `FLAG_READABLE`=16384; sin override por items.xml). **Auditoría del `items.otb`** (parser perl del árbol OTB, en scratchpad `otb_rw_audit.pl`; validado porque el premium scroll 1954 y el parchment 1953 caen correctamente en readable-only): **14 items ESCRIBIBLES (grupo 9):** 1811,1818,1947,1948,**1949**,1951,1952,2597,2599,4842,4853,4854,4855,4857. **37 SOLO-LECTURA (flag READABLE):** 1810,1815,1950,1953,1954(premium scroll),1955–1986. → **1949 SÍ estaba flagueado writeable**; el "you cannot use this object" original era el **binario stale sin el handler default de legibles/escribibles** (las fuentes Jul 3 lo agregaron junto con `parseTextWindow`). Post-recompilado, el default cubre los 14 escribibles (editable+persiste) y 37 legibles (read-only) **sin scripts por-id**. Se creó y luego **se BORRÓ `blank_scroll.lua`** (redundante). Todo sin commitear. Slug: otb-readables-audit.
- [QA][2026-07-03] **Resultados runtime local (GM Beiss vs YurOTS docker): auto-stack OK ✓. Texto naranja de spells: OK salvo cobertura del diccionario.** El naranja depende de `Spells.getSpellByWords` (`gamelib/spells.lua` → `SpellInfo`), que es la **tabla mainline de OTClient** y NO coincide con las palabras del server retro 7.6 (`serverrepo/.../data/spells/spells.xml`). Síntoma reportado: `adori vita vis` no se pinta. Causa: en el server `adori vita vis`=**Sudden Death**, pero el cliente tiene Sudden Death con `adori gran mort`. Cruce completo (solo spells casteables por el jugador, ignorando spells de monstruos `*_haste`/`demon_*`/etc.): **sin naranja** → `adori vita vis`(Sudden Death), `exevo mort hur`(Energy Wave; cliente lo tiene como `exevo vis hur`), `adori`, `adori blank`, `adori gran`, `adori gran flam`, `death`, `utani slow`. Dos clases: (a) mismo spell con palabras distintas (las más engañosas: Sudden Death, Energy Wave), (b) spells ausentes. **NO es regresión del feature** (funciona para lo que el diccionario conoce; el gate por `getSpellByWords` es a propósito, anti falso-positivo). **Fix = reconciliar `SpellInfo` de `gamelib/spells.lua` con `spells.xml` del server (corregir `words` + agregar faltantes), en `windows/` Y `mac/` (paridad) → tarea `/datos` o `/lua`.** Slug: client-spellinfo-desync-server76.
- [QA][2026-07-03] **Fix del desync de spells APLICADO en `gamelib/spells.lua` (windows Y mac, idénticos, `luac5.1 -p` OK).** `getSpellByWords` matchea EXACTO el texto normalizado completo (no prefijo) e itera TODOS los perfiles de `SpellInfo`; `spelllist`/`actionbar` usan solo `SpellInfo['Default']`. Se hizo: **(a) 6 correcciones de `words` in-place en `Default`** (mismo nombre, palabra 7.6; verificado que la palabra vieja no era otro spell del server): Sudden Death `adori gran mort`→`adori vita vis`, Energy Wave `exevo vis hur`→`exevo mort hur`, Light Magic Missile `adori min vis`→`adori`, Heavy Magic Missile `adori vis`→`adori gran`, Great Fireball `adori mas flam`→`adori gran flam`, Paralyze `adana ani`→`utani slow`. **(b) perfil nuevo `['Retro76']`** con los 2 server-custom sin equivalente (`adori blank`=Blank, `death`), con `icon` dummy (`retro_blank`/`retro_death`) para no colisionar en `getSpellByIcon` y NO ensuciar el spell list (que solo lee Default). Cubre los 8 gaps casteables por el jugador. **Nota:** el desync es sistémico (otras vocaciones/spells tienen más mismatches); esto cubre lo verificado del audit. **VALIDADO en runtime por el usuario (2026-07-03): los 8 casteados salen en naranja `#F6A731` sin ir al chat.** Slug: client-spellinfo-fix-aplicado.
- [QA][2026-07-01] **Auto-stack v1 + fixes de actionbar: validados en runtime (Windows) por el usuario — OK.** Se probó la build de `clienteretro/windows/` (rama `feat/autostack-y-fixes-actionbar` checked out). Falta validación runtime en **macOS** (paridad ya aplicada en código; requiere macOS + XQuartz). Criterios verificados: apilado al mover stackables a un contenedor con stack existente; diálogo de hotkey sobre botón sin configurar (OK/Clear) sin `attempt to index a nil value`.

### UI / OTUI Engineer
- [UI][2026-07-03] **Defaults Retro76 de puntero:** `crosshair = 1` (None) y `highlightThingsUnderCursor = false`. Migración v3 en `client_options/options.lua` — **bug v1/v2:** `g_settings:exists()` no existe en el singleton (solo en `g_configs.getSettings()`), la migración subía `optionsSettingsVersion` sin cambiar valores. v3 usa `getNumber`/`getBoolean` directo. `uigamemap.lua` no ejecuta `updateMarkedCreature` si highlight está off.

### Pendientes / Próximos pasos (para esta sesión)
- [Estado][2026-07-01] **1) Push + PR:** subir `feat/autostack-y-fixes-actionbar` a `origin` y abrir PR contra `main` (los 3 commits ya están; requiere OK del usuario para el push — ningún agente pushea solo).
- [Estado][2026-07-01] **2) Commitear el scaffolding del equipo:** `CLAUDE.md`, `agents.md`, `Contexto/`, `.claude/` quedaron untracked (se crearon estando en la rama feature). Idealmente commitearlos en `main` (son infraestructura del equipo, no parte del feature). Sugerido: `git switch main` → add → commit `chore: scaffolding del equipo de agentes`.
- [Estado][2026-07-01] **3) Server-side (otro repo, YurOTS):** el apilado de ítems CREADOS por el server (exevo pan, loot) NO va en el cliente. Causa raíz ya localizada: `Player::addItem` no fusiona stacks (`source/player.cpp:810`, `container.cpp:47`). Fix = agregar merge-con-stack-existente antes de `getFreeSlot`. Ojo con el contrato `stackable` .dat↔.otb si la comida hoy no es stackable.

--- Sesión cerrada: 2026-07-03 14:24 ---

--- Sesión cerrada: 2026-07-03 14:26 ---

--- Sesión cerrada: 2026-07-03 14:27 ---

- [Lua][2026-07-03] **Texto flotante naranja para spells:** `game_console/console.lua` detecta casts vía `Spells.getSpellByWords` + `registerPendingSpellMessage` (TTL 3s) en say/action bar; `spellCast` usa `MessageModes.MonsterSay`, color `#F6A731`, `hideInConsole=true`. Action bar registra pending antes de `g_game.talk`. Paridad win/mac.
- [Lua][2026-07-03] **Fix false positive spell:** no registrar pending en todo `say` — solo si `getSpellByWords` matchea; pending solo para jugador local. Say/whisper/yell normales mantienen amarillo en flotante y chat.

--- Sesión cerrada: 2026-07-03 14:31 ---

--- Sesión cerrada: 2026-07-03 14:35 ---

--- Sesión cerrada: 2026-07-03 14:35 ---

--- Sesión cerrada: 2026-07-03 14:40 ---

--- Sesión cerrada: 2026-07-03 14:40 ---

--- Sesión cerrada: 2026-07-03 14:41 ---

--- Sesión cerrada: 2026-07-03 14:42 ---

--- Sesión cerrada: 2026-07-03 14:42 ---

--- Sesión cerrada: 2026-07-03 14:49 ---

--- Sesión cerrada: 2026-07-03 14:50 ---

--- Sesión cerrada: 2026-07-03 15:42 ---

--- Sesión cerrada: 2026-07-03 15:42 ---

--- Sesión cerrada: 2026-07-03 16:05 ---

--- Sesión cerrada: 2026-07-03 16:35 ---

--- Sesión cerrada: 2026-07-03 16:43 ---

--- Sesión cerrada: 2026-07-03 16:58 ---

--- Sesión cerrada: 2026-07-03 17:03 ---

--- Sesión cerrada: 2026-07-03 17:07 ---

--- Sesión cerrada: 2026-07-03 17:11 ---

--- Sesión cerrada: 2026-07-03 17:17 ---

--- Sesión cerrada: 2026-07-03 17:38 ---

--- Sesión cerrada: 2026-07-03 18:48 ---

--- Sesión cerrada: 2026-07-03 19:21 ---

--- Sesión cerrada: 2026-07-03 19:58 ---
