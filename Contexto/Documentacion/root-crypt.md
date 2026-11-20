# Cripta de Raíces — quest BoH al sur del depot

Publicada en la ThinkPad el 20 nov 2026. Once piezas propias 20262–20272,
clients 3213/3212/3210/3208/3205/3158/3156/3154/3151/3130/3124.
Piedra gris verdosa, musgo, raíces y faroles ámbar. Solo el edificio de la quest:
x127–136, y61–66, z6/z7. Reja con nivel 60 original; teleports/cofres conservados.
44 sprites añadidos (14356→14400); outfits, efectos y proyectiles intactos.
DAT/SPR copiados del canónico de RME a Mac/Windows. Reja con dos capas, no animada.
Fuentes/prompts: serverrepo/devtools/zagan-test/custom-sprites/root-crypt/.
Documentación: serverrepo/docs/gameplay/QUEST_BOOTS_OF_HASTE.md.
Publicar el cliente antes de activar mapa/OTB/actions.xml juntos; sin cambios de C++.
Sin suites ni pruebas in-game, por pedido de Gonzalo.

Deploy autorizado: servidor cd841f6, fuente cliente 521249f. `publish_client.py`: 3
archivos cambiados (DAT/SPR/minimapa), 0 borrados, 774 comunes. CRC 61142f45 /
2d5b06c9 / c6ec995a; HTTP 8080/8076 y ZIPs Mac/Windows coinciden. Reinicio ordenado,
probe OK / healthy y runtime preservado; sin rebuild. Respaldo
~/backups/pre-deploy-20261120-121746-root-crypt.
