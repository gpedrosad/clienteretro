# Entrada, faroles y rejas arcanos — 20 nov 2026

Publicado en la ThinkPad el 20 nov 2026. Fuente y estado de mapa:
serverrepo/docs/items-and-map/PLAZA_ARCANA.md.

Server IDs 20253–20259; clients 3229–3223: arco pasable de dos mitades, farol de cristal
animado, tres orientaciones de reja y aplique animado 1×2. 32 sprites añadidos:
14311 → 14343. DAT/SPR copiados del canónico de RME a Mac y Windows.
Publicar el cliente antes de activar el OTB/mapa nuevos. No hay cambios de C++.
Sin suites ni pruebas de juego, por pedido de Gonzalo.

Publicación autorizada: DAT/SPR/minimapa, 3 cambios y 0 borrados en 774 archivos.
CRC DAT c79d1bcc, SPR 10c7d5dd; contenido HTTP verificado en 8080/8076.
Servidor b347fff: restart ordenado, probe OK / healthy, runtime preservado.
Respaldo ~/backups/pre-deploy-20261120-110552-temple-details.

Corrección del pórtico y torre sureste: arco completo de cuatro casillas, mismos clients
3229/3228, anclas 160,57,7 y 162,57,7. Escaleras nuevas 20260/3217 (sube) y 20261/3214 (baja).
Se añaden 13 sprites: 14343 → 14356. Incluye bindings Lua y mapa, sin cambios de C++.
Corrección publicada en la ThinkPad: fuente cliente 71ae582, servidor a3325f4.
DAT c5508297, SPR f23b91d0, minimapa 309f31ee; HTTP 8080/8076 y ZIPs Mac/Windows
coinciden. Reinicio ordenado, probe OK / healthy; runtime preservado.
Respaldo ~/backups/pre-deploy-20261120-112515-complete-portico-tower.
Sin suites ni recorrido in-game por pedido de Gonzalo.

Accesos despejados (20 nov, servidor d747052): torre extendida a x170; escaleras
alternan x169/x167, y54; acceso oeste y corredor libre en y55, sin puerta 1210.
Murallas norte/sudoeste enlazadas con la galería; faroles del pórtico en 158,57 y 164,57.
Sin nuevos assets: publicación de un archivo (minimapa CRC 2dee4a3c), 0 borrados.
DAT/SPR c5508297/f23b91d0 conservados. Respaldo ThinkPad
~/backups/pre-deploy-20261120-113712-clear-temple-access.
