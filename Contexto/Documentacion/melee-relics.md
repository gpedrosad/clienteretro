# Melee Relics — 19 nov 2026

Preparado localmente, sin publicar. Fuente: serverrepo/docs/gameplay/MELEE_RELICS.md.
Riftblade 20250/client 3233, Aethercleaver 20251/3238 y Graviton Maul 20252/3235.
Tres sprites de ítem + 24 cuadros de impacto nuevos: 14284 → 14311.
Efectos DAT 48/49/50 (protocolo 47/48/49), outfits y proyectiles intactos.
DAT/SPR iguales en Mac y Windows. Requiere binario nuevo y OTB; publicar cliente primero.
No reutilizamos slot 3236: music piece 2349 existe en el GM. Main lo reservó después para Metal Hydra.

Build limpio del servidor en copia separada: 0 errores / 0 warnings.
Motor Mac: MELEE_RELICS_CLIENT_PASS. Combate parcial en 7281: combos, Elite Knight,
maná PvP/monstruos, maná shield, inmunidad y trainers comprobados.
Gonzalo pidió detener las pruebas y pushear; se interrumpió el caso maul vs monstruo blindado.
QA detenida. Sin publicación del updater ni deploy del servidor de juego.

Integrado main con cadáveres/Metal: IDs finales 20250–20252, clients 3233/3238/3235.
No hubo más compilaciones ni pruebas tras reasignar IDs, por pedido de Gonzalo.
