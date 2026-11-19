# Calavera punitiva cian — 19 nov 2026

Publicada para Mac y Windows el 19 nov 2026 mediante el updater y ambos ZIPs.

El estado 7 (`SkullPink`) usa `/images/game/skulls/skull_cyan`, PNG 11×11 RGBA con
alpha binario y ojos/contorno azul marino. Se cambió solo la apariencia. `/pink`,
`/unpink`, la persistencia y el drop total siguen en el servidor sin modificaciones.

Archivos por plataforma: `modules/gamelib/creature.lua`, comentario de
`modules/gamelib/const.lua`, `data/images/game/skulls/skull_cyan.png`.
El PNG rosa se conserva para compatibilidad. DAT y SPR también incluyen las once
variantes de pared exclusivas del depot, IDs 20200–20210; publicar sus assets antes
que el mapa y el OTB.

Fuentes de ImageGen, prompts, instalación y prueba con el cliente real en
`serverrepo/docs/items-and-map/DEPOT_ELECTRICO.md`. Mapa nuevo probado con un locker
que contiene siete crystal coins, contra servidor aislado en 7278.

Deploy de mapa/OTB: serverrepo 51ca529. Probe OK tras reinicio; 11 lockers con depotid 1.
