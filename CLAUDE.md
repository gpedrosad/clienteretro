# CLAUDE.md — Contexto Técnico · Cliente Oficial Retro76

## Lectura obligatoria antes de cualquier tarea
1. `/Contexto/MEMORY.md` — aprendizajes acumulados del equipo
2. `agents.md` — roles del equipo y sus restricciones
3. Este archivo — mapa técnico del proyecto

---

## ¿Qué es este repo?

Es el **repo de distribución del cliente oficial** de un servidor privado tipo Tibia **retro, protocolo 7.60** (`retro76.cl:7171`). Contiene el cliente **listo para descargar/ejecutar** por los jugadores, empaquetado por plataforma. Es un cliente **OTClient** (motor C++ + scripting Lua); según el `README`, línea **OTClientV8**.

Este repo **no es un servidor** ni tiene lógica de negocio de juego (esa vive en el servidor YurOTS, en otro repo). Es la **distribución del cliente**: binarios del motor, módulos Lua de interfaz/juego, layout visual y assets.

| Dato | Valor |
|------|-------|
| Servidor destino | `retro76.cl:7171` (protocolo **7.60**) |
| Plataformas | Windows (`windows/`) y macOS (`mac/`) |
| Motor | OTClient (OTClientV8) |

---

## ⚠️ Estructura CLAVE: dos distribuciones en paralelo

El repo mantiene **dos copias completas del cliente**, una por plataforma:

```
clienteretro/
├── README.md
├── build-zips.sh        # empaqueta mac/ y windows/ → web/downloads/
├── windows/             # cliente Windows COMPLETO
│   ├── init.lua · modules/ · data/ · layouts/
│   ├── otclient_gl.exe · otclient_dx.exe
│   ├── libEGL.dll · libGLESv2.dll · d3dcompiler_47.dll (ANGLE)
│   ├── Iniciar Cliente.bat · LEEME.txt
└── mac/                 # cliente macOS COMPLETO
    ├── init.lua · modules/ · data/ · layouts/
    ├── otclient_mac
    ├── Iniciar Cliente.command (requiere XQuartz) · LEEME.txt
```

**REGLA DE ORO DEL REPO — Paridad win/mac:** los `modules/*.lua` (y en general el código/assets) son **idénticos entre `windows/` y `mac/`** (Lua es cross-platform). **Todo cambio de cliente debe aplicarse a AMBAS carpetas.** Modificar solo una rompe la paridad y deja a media plataforma sin el fix.

---

## Empaquetado (`build-zips.sh`)

Genera `Retro76-Windows.zip` y `Retro76-Mac.zip` en `web/downloads/`. **Asume que este repo vive dentro del monorepo del juego**, junto a `../scripts/resolve-project-root.sh` y `../web/`. Como clon standalone (fuera del monorepo) el script no resuelve la raíz — es una dependencia a tener presente al hacer release.

---

## Flujos críticos

### Arranque del cliente
```
Iniciar Cliente.bat (win) / Iniciar Cliente.command (mac)
  → otclient_gl.exe | otclient_dx.exe | otclient_mac
  → init.lua: define Servers (retro76.cl:7171:760), resuelve layout, carga módulos por prioridad
```

### Conexión y login
```
client_entergame → retro76.cl:7171 (protocolo 7.60)
  → ProtocolLogin (cuenta) → selección de personaje → ProtocolGame (mundo)
  → game_interface monta el HUD; los módulos game_* reaccionan a los paquetes del server
```

> El **servidor es la fuente de verdad**. El cliente solo renderiza y envía input — no simula ni inventa estado autoritativo.

---

## Reglas y convenciones

- **Paridad win/mac obligatoria** en todo cambio de `modules/`/`data/`/`layouts/`.
- **Sin lógica de negocio autoritativa en el cliente.**
- **Protocolo fijo 7.60.** No mezclar assets/features de otras versiones (`data/things/760`).
- **El flag `stackable` es contrato cliente↔servidor:** el `.dat` del cliente debe coincidir con el `items.otb` del server, o se desincroniza el parseo de ProtocolGame.
- **Módulos autocontenidos:** cada `modules/<nombre>` con su `.otmod`/`.lua`/`.otui`.
- **No editar binarios/DLLs a mano** (`otclient_*.exe`, `otclient_mac`, DLLs ANGLE) — se reemplazan por build.
- **Servidores custom deshabilitados** (`ALLOW_CUSTOM_SERVERS = false`).

---

## Nota de seguridad (pendiente para `/seguridad`)

El cliente publicado ejecuta **Lua editable desde disco**: cualquier jugador puede modificar sus `modules/*.lua`. Ventajas "client-side" (ej. el auto-apilado de ítems) son en realidad modificaciones que un jugador podría hacer por su cuenta → **superficie de trampa/integridad**. Lo verdaderamente autoritativo debe vivir en el server. Revisar en su momento con el rol `/seguridad`.

---

## Cómo correr el cliente

1. Windows: doble clic en `windows/Iniciar Cliente.bat` (OpenGL) o `windows/otclient_dx.exe` (DirectX/ANGLE).
2. macOS: instalar XQuartz → `mac/Iniciar Cliente.command`.
3. Conecta automáticamente a `retro76.cl:7171`. Iniciar sesión con cuenta del server retro.

> Cambios de Lua: el motor los lee de disco en cada arranque — **no se compila**. Editar → reiniciar el cliente.
