function init()
  -- add manually your shaders from /data/shaders

  -- map shaders
  g_shaders.createShader("map_default", "/shaders/map_default_vertex", "/shaders/map_default_fragment")  

  g_shaders.createShader("map_rainbow", "/shaders/map_rainbow_vertex", "/shaders/map_rainbow_fragment")
  g_shaders.addTexture("map_rainbow", "/images/shaders/rainbow.png")

  -- use modules.game_interface.gameMapPanel:setShader("map_rainbow") to set shader

  -- outfit shaders
  g_shaders.createOutfitShader("outfit_default", "/shaders/outfit_default_vertex", "/shaders/outfit_default_fragment")

  g_shaders.createOutfitShader("outfit_rainbow", "/shaders/outfit_rainbow_vertex", "/shaders/outfit_rainbow_fragment")
  g_shaders.addTexture("outfit_rainbow", "/images/shaders/rainbow.png")

  -- you can use creature:setOutfitShader("outfit_rainbow") to set shader

  -- Retro76: el GM con /invisible se ve a si mismo semitransparente (los demas no lo ven)
  g_shaders.createOutfitShader("outfit_ghost", "/shaders/outfit_default_vertex", "/shaders/outfit_ghost_fragment")
  connect(g_game, { onTextMessage = onGhostMessage, onGameEnd = clearGhost })
end

function terminate()
  disconnect(g_game, { onTextMessage = onGhostMessage, onGameEnd = clearGhost })
end

-- Retro76: el servidor avisa con estos mensajes al prender y apagar /invisible (commands.cpp, gmInvisible).
-- Al entrar el GM siempre esta visible, asi que alcanza con seguir los mensajes.
local GHOST_ON = "You are invisible."
local GHOST_OFF = "You are visible again."

local function setGhost(on)
  local player = g_game.getLocalPlayer()
  if player then
    player:setOutfitShader(on and "outfit_ghost" or "outfit_default")
  end
end

function onGhostMessage(mode, text)
  if text == GHOST_ON then
    setGhost(true)
  elseif text == GHOST_OFF then
    setGhost(false)
  end
end

function clearGhost()
  setGhost(false)
end


