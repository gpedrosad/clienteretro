# MEMORY.md — Aprendizajes del Equipo · Cliente Oficial Retro76

> Índice de contexto cargado al inicio de cada sesión. Formato de entrada: `- [ROL][FECHA] descripción.`

## Aprendizajes del Equipo

### Arquitecto / Tech Lead
- [Arquitecto][2026-07-01] **Este repo (`gpedrosad/clienteretro`) es el repo CANÓNICO del cliente publicado.** Es de DISTRIBUCIÓN: raíz con `README.md` + `build-zips.sh`, y DOS variantes paralelas `windows/` y `mac/`, cada una un cliente OTClient 7.60 completo (`init.lua`, `modules/`, `data/`, `layouts/`, binarios). Motor: OTClientV8 (según README). Server destino: `retro76.cl:7171` protocolo 7.60.
- [Arquitecto][2026-07-01] **REGLA DE ORO: paridad win/mac.** Los `modules/*.lua` son IDÉNTICOS entre `windows/` y `mac/` (Lua cross-platform). Todo cambio de código/assets del cliente se aplica a AMBAS carpetas; tocar solo una rompe la paridad.
- [Arquitecto][2026-07-01] **`build-zips.sh` asume que el repo vive dentro del monorepo del juego** (usa `../scripts/resolve-project-root.sh` y `../web/downloads/`). Como clon standalone no resuelve la raíz — dependencia a considerar en release.

### Build / Distribución Engineer
- [Build][2026-07-01] **Primeros cambios portados desde el workspace de pruebas** a la rama `feat/autostack-y-fixes-actionbar` (3 commits, cada uno aplicado a `windows/` + `mac/`): guard nil en `game_actionbar/actionbar.lua` (okFunc/clearFunc, ~931/945); `cancelFunc()`→`closeFunc()` en `assignHotkey` (~966); feature auto-apilado v1 (`game_containers/containers.lua` helper `findMergeSlotPosition` + enganche en `gamelib/ui/uiitem.lua:onDrop`). Verificado en runtime (ver QA). **Pendiente: push de la rama a `origin` + PR contra `main`** (requiere OK del usuario).

### Seguridad / Integridad del Cliente
- [Security][2026-07-01][CRITICO] **El cliente PUBLICADO corre Lua editable desde disco** (el que se descarga del sitio). Cualquier jugador puede modificar sus `modules/*.lua`. Las "ventajas" client-side (ej. el auto-apilado de ítems al mover) son en realidad modificaciones que un jugador podría hacerse solo → **superficie de trampa/integridad**. Lo verdaderamente autoritativo (stacking real, loot, combate) debe vivir en el SERVER. Slug: client-lua-editable-security-surface. Revisar a fondo qué mecánicas client-side representan brecha y cuáles mover a autoridad del server.

### Protocolo / Networking Engineer
- [Protocolo][2026-07-01] **El flag `stackable` es contrato cliente↔servidor.** En protocolo Tibia, si un ítem es stackable determina si viaja el byte count/subtype. El `.dat` del cliente (`data/things/760`) y el `items.otb` del server DEBEN coincidir; si no, se desincroniza el parseo de `ProtocolGame` (síntoma: `no thing at pos`). Relevante para cualquier cambio que quiera hacer stackable un ítem que hoy no lo es (ej. comida del hechizo exevo pan — ese fix es SERVER-side en YurOTS, no del cliente).

### QA Engineer
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

--- Sesión cerrada: 2026-07-03 14:31 ---

--- Sesión cerrada: 2026-07-03 14:35 ---

--- Sesión cerrada: 2026-07-03 14:35 ---

--- Sesión cerrada: 2026-07-03 14:40 ---

--- Sesión cerrada: 2026-07-03 14:40 ---
