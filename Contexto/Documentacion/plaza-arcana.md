# Plaza Arcana — 19 nov 2026

Publicado y desplegado en la ThinkPad el 19 nov 2026. Source y mapa en
serverrepo/docs/items-and-map/PLAZA_ARCANA.md.

Once apariencias 20214–20224: pisos, seis paredes, beacon y obelisco. Client IDs
3379,3368,3365,3363,3342,3253,3247,3246,3245,3244,3243. Se añaden 35 sprites:
14037 → 14072. Outfits, efectos, proyectiles y todos los sprites anteriores intactos.
DAT y SPR idénticos en Mac/Windows. Se publicó antes del mapa/OTB, con minimapa regenerado.
`publish_client.py`: 3 archivos cambiados, 0 borrados; 774 archivos cotejados entre
Mac, Windows, updater y ZIPs. Manifest y assets HTTP verificados en 8080 y 8076.
CRC DAT dc61b99b, SPR 8da89f7a. Assets fuente 55d5342; servidor b6b86a4.
Respaldo ~/backups/pre-deploy-20261119-211809-portal-citadel.
Probe OK / healthy tras reinicio ordenado; 1 cuenta, 8 personajes, 31 casas y depots preservados.

Prueba con motor Mac y cuenta sintética en 7280: pasillo sur–norte y ocho portales
con destinos correctos; locker con siete monedas guardadas. Revisión visual Windows pendiente.

QA: APP_NAME no cambia por sí solo el writeDir de este binario (otclientv8). La copia
de prueba debe cargar config con nombre propio y guardar el minimapa con otro nombre.
