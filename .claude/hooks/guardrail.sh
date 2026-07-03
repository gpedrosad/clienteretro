#!/bin/bash
# guardrail.sh — PreToolUse hook
# Intercepta operaciones peligrosas antes de que se ejecuten.
# Recibe JSON en stdin con { "tool_name": "...", "tool_input": { "command": "..." } }
# Exit 0 = permitir | Exit 2 = bloqueo duro (Claude no puede continuar la acción)
#
# Proyecto: Cliente Oficial Retro76 (OTClient 7.60), repo de distribución windows/ + mac/. Sin base de datos.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)

if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

# Normalizar para comparar (minúsculas, sin espacios extra)
CMD_LOWER=$(echo "$COMMAND" | tr '[:upper:]' '[:lower:]')

# --- BLOQUEO: git commit ---
if echo "$CMD_LOWER" | grep -qE '^\s*git\s+commit\b|&&\s*git\s+commit\b|\|\s*git\s+commit\b'; then
  echo "🚫 GUARDRAIL BLOQUEADO: Se detectó git commit."
  echo "   Los commits NO los ejecuta el agente — se sugieren al usuario al final de la tarea."
  echo "   Comando interceptado: $COMMAND"
  exit 2
fi

# --- BLOQUEO: git push ---
if echo "$CMD_LOWER" | grep -qE '^\s*git\s+push\b|&&\s*git\s+push\b|\|\s*git\s+push\b'; then
  echo "🚫 GUARDRAIL BLOQUEADO: Se detectó git push."
  echo "   Los push NO los ejecuta el agente — se sugieren al usuario al final de la tarea."
  echo "   Comando interceptado: $COMMAND"
  exit 2
fi

# --- BLOQUEO: modificación/borrado a mano de binarios del motor o DLLs ---
# Los binarios (otclient_*.exe, otclient_mac) y las DLLs (ANGLE) se reemplazan por build, no se parchean.
if echo "$CMD_LOWER" | grep -qE '\b(rm|mv|cp|sed\s+-i|tee|truncate)\b.*(otclient_[a-z]+\.exe|otclient_mac|libegl\.dll|libglesv2\.dll|d3dcompiler_47\.dll)'; then
  echo "🚫 GUARDRAIL BLOQUEADO: Intento de modificar o borrar un binario/DLL del cliente."
  echo "   otclient_*.exe / otclient_mac y las DLLs de ANGLE se reemplazan por build — no se editan a mano."
  echo "   Comando interceptado: $COMMAND"
  exit 2
fi

# --- ADVERTENCIA: borrado recursivo dentro de assets del cliente ---
if echo "$CMD_LOWER" | grep -qE '\brm\s+-[rf]+\b.*(data/|modules/|layouts/)'; then
  echo "⚠️  GUARDRAIL ADVERTENCIA: Borrado recursivo sobre data/, modules/ o layouts/."
  echo "   Asegúrate de que esto fue explícitamente autorizado por el usuario."
  echo "   Comando: $COMMAND"
  # No bloquear — puede ser una limpieza autorizada.
  exit 0
fi

exit 0
