Icons = {}
Icons[PlayerStates.Poison] = { tooltip = tr('You are poisoned'), path = '/images/game/states/poisoned', id = 'condition_poisoned' }
Icons[PlayerStates.Burn] = { tooltip = tr('You are burning'), path = '/images/game/states/burning', id = 'condition_burning' }
Icons[PlayerStates.Energy] = { tooltip = tr('You are electrified'), path = '/images/game/states/electrified', id = 'condition_electrified' }
Icons[PlayerStates.Drunk] = { tooltip = tr('You are drunk'), path = '/images/game/states/drunk', id = 'condition_drunk' }
Icons[PlayerStates.ManaShield] = { tooltip = tr('You are protected by a magic shield'), path = '/images/game/states/magic_shield', id = 'condition_magic_shield' }
Icons[PlayerStates.Paralyze] = { tooltip = tr('You are paralysed'), path = '/images/game/states/slowed', id = 'condition_slowed' }
Icons[PlayerStates.Haste] = { tooltip = tr('You are hasted'), path = '/images/game/states/haste', id = 'condition_haste' }
Icons[PlayerStates.Swords] = { tooltip = tr('You may not logout during a fight'), path = '/images/game/states/logout_block', id = 'condition_logout_block' }
Icons[PlayerStates.Drowning] = { tooltip = tr('You are drowning'), path = '/images/game/states/drowning', id = 'condition_drowning' }
Icons[PlayerStates.Freezing] = { tooltip = tr('You are freezing'), path = '/images/game/states/freezing', id = 'condition_freezing' }
Icons[PlayerStates.Dazzled] = { tooltip = tr('You are dazzled'), path = '/images/game/states/dazzled', id = 'condition_dazzled' }
Icons[PlayerStates.Cursed] = { tooltip = tr('You are cursed'), path = '/images/game/states/cursed', id = 'condition_cursed' }
Icons[PlayerStates.PartyBuff] = { tooltip = tr('You are strengthened'), path = '/images/game/states/strengthened', id = 'condition_strengthened' }
Icons[PlayerStates.PzBlock] = { tooltip = tr('You may not logout or enter a protection zone'), path = '/images/game/states/protection_zone_block', id = 'condition_protection_zone_block' }
Icons[PlayerStates.Pz] = { tooltip = tr('You are within a protection zone'), path = '/images/game/states/protection_zone', id = 'condition_protection_zone' }
Icons[PlayerStates.Bleeding] = { tooltip = tr('You are bleeding'), path = '/images/game/states/bleeding', id = 'condition_bleeding' }
Icons[PlayerStates.Hungry] = { tooltip = tr('You are hungry'), path = '/images/game/states/hungry', id = 'condition_hungry' }

InventorySlotStyles = {
  [InventorySlotHead] = "HeadSlot",
  [InventorySlotNeck] = "NeckSlot",
  [InventorySlotBack] = "BackSlot",
  [InventorySlotBody] = "BodySlot",
  [InventorySlotRight] = "RightSlot",
  [InventorySlotLeft] = "LeftSlot",
  [InventorySlotLeg] = "LegSlot",
  [InventorySlotFeet] = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo] = "AmmoSlot"
}

inventoryWindow = nil
inventoryPanel = nil
inventoryButton = nil
purseButton = nil

combatControlsWindow = nil
fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
chaseModeButton = nil
safeFightButton = nil
mountButton = nil
fightModeRadioGroup = nil
buttonPvp = nil

soulLabel = nil
capLabel = nil
conditionPanel = nil

function init()
  connect(LocalPlayer, {
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange
  })
  connect(g_game, { onGameStart = refresh })
  -- En este cliente g_game.onTextMessage reparte por tipo de mensaje (gamelib/textmessages.lua): connect() no
  -- recibe nada. Se escucha en todos los tipos, porque cada aviso del server llega con el suyo.
  for _, mode in pairs(MessageModes) do
    registerMessageMode(mode, onTimedIconMessage)
  end

  g_keyboard.bindKeyDown('Ctrl+I', toggle)


  inventoryWindow = g_ui.loadUI('inventory', modules.game_interface.getRightPanel())
  inventoryWindow:disableResize()
  inventoryPanel = inventoryWindow:getChildById('contentsPanel'):getChildById('inventoryPanel')
  if not inventoryWindow.forceOpen then
    inventoryButton = modules.client_topmenu.addRightGameToggleButton('inventoryButton', tr('Inventory') .. ' (Ctrl+I)', '/images/topbuttons/inventory', toggle)
    inventoryButton:setOn(true)
  end
  
  purseButton = inventoryWindow:recursiveGetChildById('purseButton')
  purseButton.onClick = function()
    local purse = g_game.getLocalPlayer():getInventoryItem(InventorySlotPurse)
    if purse then
      g_game.use(purse)
    end
  end
  
  -- controls
  fightOffensiveBox = inventoryWindow:recursiveGetChildById('fightOffensiveBox')
  fightBalancedBox = inventoryWindow:recursiveGetChildById('fightBalancedBox')
  fightDefensiveBox = inventoryWindow:recursiveGetChildById('fightDefensiveBox')

  chaseModeButton = inventoryWindow:recursiveGetChildById('chaseModeBox')
  safeFightButton = inventoryWindow:recursiveGetChildById('safeFightBox')
  buttonPvp = inventoryWindow:recursiveGetChildById('buttonPvp')

  mountButton = inventoryWindow:recursiveGetChildById('mountButton')
  mountButton.onClick = onMountButtonClick

  whiteDoveBox = inventoryWindow:recursiveGetChildById('whiteDoveBox')
  whiteHandBox = inventoryWindow:recursiveGetChildById('whiteHandBox')
  yellowHandBox = inventoryWindow:recursiveGetChildById('yellowHandBox')
  redFistBox = inventoryWindow:recursiveGetChildById('redFistBox')

  fightModeRadioGroup = UIRadioGroup.create()
  fightModeRadioGroup:addWidget(fightOffensiveBox)
  fightModeRadioGroup:addWidget(fightBalancedBox)
  fightModeRadioGroup:addWidget(fightDefensiveBox)

  connect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
  connect(chaseModeButton, { onCheckChange = onSetChaseMode })
  connect(safeFightButton, { onCheckChange = onSetSafeFight })
  if buttonPvp then
    connect(buttonPvp, { onClick = onSetSafeFight2 })  
  end
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onFightModeChange = update,
    onChaseModeChange = update,
    onSafeFightChange = update,
    onPVPModeChange   = update,
    onWalk = check,
    onAutoWalk = check
  })

  connect(LocalPlayer, { onOutfitChange = onOutfitChange })

  if g_game.isOnline() then
    online()
  end
-- controls end

-- status
  soulLabel = inventoryWindow:recursiveGetChildById('soulLabel')
  capLabel = inventoryWindow:recursiveGetChildById('capLabel')
  conditionPanel = inventoryWindow:recursiveGetChildById('conditionPanel')


  connect(LocalPlayer, { onStatesChange = onStatesChange,
                         onSoulChange = onSoulChange,
                         onFreeCapacityChange = onFreeCapacityChange })
-- status end
  
  refresh()
  inventoryWindow:setup()
  connect(inventoryWindow, { onMaximize = updateConditionLayout })
  conditionPanel.onLayoutUpdate = updateConditionLayout
  conditionPanel.onGeometryChange = updateConditionLayout
  updateConditionLayout()
end

function terminate()
  disconnect(LocalPlayer, {
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange
  })
  disconnect(g_game, { onGameStart = refresh })
  for _, mode in pairs(MessageModes) do
    unregisterMessageMode(mode, onTimedIconMessage)
  end
  stopTimedIcons()

  g_keyboard.unbindKeyDown('Ctrl+I')

  -- controls
  if g_game.isOnline() then
    offline()
  end

  fightModeRadioGroup:destroy()
  
  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onFightModeChange = update,
    onChaseModeChange = update,
    onSafeFightChange = update,
    onPVPModeChange   = update,
    onWalk = check,
    onAutoWalk = check
  })

  disconnect(LocalPlayer, { onOutfitChange = onOutfitChange })
  -- controls end
  -- status
  disconnect(LocalPlayer, { onStatesChange = onStatesChange,
                         onSoulChange = onSoulChange,
                         onFreeCapacityChange = onFreeCapacityChange })
  -- status end

  disconnect(inventoryWindow, { onMaximize = updateConditionLayout })
  inventoryWindow:destroy()
  if inventoryButton then
    inventoryButton:destroy()
  end
end

function toggleAdventurerStyle(hasBlessing)
  for slot = InventorySlotFirst, InventorySlotLast do
    local itemWidget = inventoryPanel:getChildById('slot' .. slot)
    if itemWidget then
      itemWidget:setOn(hasBlessing)
    end
  end
end

function refresh()
  local player = g_game.getLocalPlayer()
  for i = InventorySlotFirst, InventorySlotPurse do
    if g_game.isOnline() then
      onInventoryChange(player, i, player:getInventoryItem(i))
    else
      onInventoryChange(player, i, nil)
    end
    toggleAdventurerStyle(player and Bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)
  end
  if player then
    onSoulChange(player, player:getSoul())
    onFreeCapacityChange(player, player:getFreeCapacity())
    onStatesChange(player, player:getStates(), 0)
    refreshNativeSpellIcons(player)
  end

  purseButton:setVisible(g_game.getFeature(GamePurseSlot))
end

function toggle()
  if not inventoryButton then
    return
  end
  if inventoryButton:isOn() then
    inventoryWindow:close()
    inventoryButton:setOn(false)
  else
    inventoryWindow:open()
    inventoryButton:setOn(true)
  end
end

function onMiniWindowClose()
  if not inventoryButton then
    return
  end
  inventoryButton:setOn(false)
end

-- hooked events
function onInventoryChange(player, slot, item, oldItem)
  if slot > InventorySlotPurse then return end

  if slot == InventorySlotPurse then
    if g_game.getFeature(GamePurseSlot) then
      --purseButton:setEnabled(item and true or false)
    end
    return
  end

  local itemWidget = inventoryPanel:getChildById('slot' .. slot)
  if item then
    itemWidget:setStyle('InventoryItem')
    itemWidget:setItem(item)
  else
    itemWidget:setStyle(InventorySlotStyles[slot])
    itemWidget:setItem(nil)
  end
  if slot == InventorySlotFeet then
    refreshNativeSpellIcons(player)
  end
end

function onBlessingsChange(player, blessings, oldBlessings)
  local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
  if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
    toggleAdventurerStyle(hasAdventurerBlessing)
  end
end


-- controls
function update()
  local fightMode = g_game.getFightMode()
  if fightMode == FightOffensive then
    fightModeRadioGroup:selectWidget(fightOffensiveBox)
  elseif fightMode == FightBalanced then
    fightModeRadioGroup:selectWidget(fightBalancedBox)
  else
    fightModeRadioGroup:selectWidget(fightDefensiveBox)
  end

  local chaseMode = g_game.getChaseMode()
  chaseModeButton:setChecked(chaseMode == ChaseOpponent)

  local safeFight = g_game.isSafeFight()
  safeFightButton:setChecked(not safeFight)
  if buttonPvp then
    if safeFight then
      buttonPvp:setOn(false)
    else
      buttonPvp:setOn(true)  
    end
  end
  
  if g_game.getFeature(GamePVPMode) then
    local pvpMode = g_game.getPVPMode()
    local pvpWidget = getPVPBoxByMode(pvpMode)
  end
end

function check()
  if modules.client_options.getOption('autoChaseOverride') then
    if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
      g_game.setChaseMode(DontChase)
    end
  end
end

function online()
  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()

    local lastCombatControls = g_settings.getNode('LastCombatControls')

    if not table.empty(lastCombatControls) then
      if lastCombatControls[char] then
        g_game.setFightMode(lastCombatControls[char].fightMode)
        g_game.setChaseMode(lastCombatControls[char].chaseMode)
        g_game.setSafeFight(lastCombatControls[char].safeFight)
        if lastCombatControls[char].pvpMode then
          g_game.setPVPMode(lastCombatControls[char].pvpMode)
        end
      end
    end

    if g_game.getFeature(GamePlayerMounts) then
      mountButton:setVisible(true)
      mountButton:setChecked(player:isMounted())
    else
      mountButton:setVisible(false)
    end
  end

  update()
end

function offline()
  local lastCombatControls = g_settings.getNode('LastCombatControls')
  if not lastCombatControls then
    lastCombatControls = {}
  end

  stopTimedIcons()
  conditionPanel:destroyChildren()

  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()
    lastCombatControls[char] = {
      fightMode = g_game.getFightMode(),
      chaseMode = g_game.getChaseMode(),
      safeFight = g_game.isSafeFight()
    }

    if g_game.getFeature(GamePVPMode) then
      lastCombatControls[char].pvpMode = g_game.getPVPMode()
    end

    -- save last combat control settings
    g_settings.setNode('LastCombatControls', lastCombatControls)
  end
end

function onSetFightMode(self, selectedFightButton)
  if selectedFightButton == nil then return end
  local buttonId = selectedFightButton:getId()
  local fightMode
  if buttonId == 'fightOffensiveBox' then
    fightMode = FightOffensive
  elseif buttonId == 'fightBalancedBox' then
    fightMode = FightBalanced
  else
    fightMode = FightDefensive
  end
  g_game.setFightMode(fightMode)
end

function onSetChaseMode(self, checked)
  local chaseMode
  if checked then
    chaseMode = ChaseOpponent
  else
    chaseMode = DontChase
  end
  g_game.setChaseMode(chaseMode)
end

function onSetSafeFight(self, checked)
  g_game.setSafeFight(not checked)
  if buttonPvp then
    if not checked then
      buttonPvp:setOn(false)
    else
      buttonPvp:setOn(true)  
    end
  end
end

function onSetSafeFight2(self)
  onSetSafeFight(self, not safeFightButton:isChecked())
end

function onSetPVPMode(self, selectedPVPButton)
  if selectedPVPButton == nil then
    return
  end

  local buttonId = selectedPVPButton:getId()
  local pvpMode = PVPWhiteDove
  if buttonId == 'whiteDoveBox' then
    pvpMode = PVPWhiteDove
  elseif buttonId == 'whiteHandBox' then
    pvpMode = PVPWhiteHand
  elseif buttonId == 'yellowHandBox' then
    pvpMode = PVPYellowHand
  elseif buttonId == 'redFistBox' then
    pvpMode = PVPRedFist
  end

  g_game.setPVPMode(pvpMode)
end

function onMountButtonClick(self, mousePos)
  local player = g_game.getLocalPlayer()
  if player then
    player:toggleMount()
  end
end

function onOutfitChange(localPlayer, outfit, oldOutfit)
  refreshNativeSpellIcons(localPlayer)
  if outfit.mount == oldOutfit.mount then
    return
  end

  mountButton:setChecked(outfit.mount ~= nil and outfit.mount > 0)
end

function getPVPBoxByMode(mode)
  local widget = nil
  if mode == PVPWhiteDove then
    widget = whiteDoveBox
  elseif mode == PVPWhiteHand then
    widget = whiteHandBox
  elseif mode == PVPYellowHand then
    widget = yellowHandBox
  elseif mode == PVPRedFist then
    widget = redFistBox
  end
  return widget
end

-- status
function updateConditionLayout()
  if not conditionPanel or inventoryWindow:isOn() then return end
  local columns = math.max(1, math.floor((conditionPanel:getWidth() - 4) / 20))
  local height = math.max(1, math.ceil(conditionPanel:getChildCount() / columns)) * 18 + 4
  if conditionPanel:getLayout():getNumColumns() ~= columns then
    conditionPanel:getLayout():setNumColumns(columns)
  end
  local delta = height - conditionPanel:getHeight()
  if delta ~= 0 then
    conditionPanel:setHeight(height)
    inventoryWindow:setHeight(inventoryWindow:getHeight() + delta)
  end
end

function toggleIcon(bitChanged)
  local icon = conditionPanel:getChildById(Icons[bitChanged].id)
  if icon then
    icon:destroy()
  else
    icon = loadIcon(bitChanged)
    icon:setParent(conditionPanel)
  end
end

function loadIcon(bitChanged)
  local icon = g_ui.createWidget('ConditionWidget', conditionPanel)
  icon:setId(Icons[bitChanged].id)
  icon:setImageSource(Icons[bitChanged].path)
  icon:setTooltip(Icons[bitChanged].tooltip)
  return icon
end

function onSoulChange(localPlayer, soul)
  if not soul then return end
  soulLabel:setText(tr('Soul') .. ':\n' .. soul)
end

function onFreeCapacityChange(player, freeCapacity)
  if not freeCapacity then return end
  if freeCapacity > 99 then
    freeCapacity = math.floor(freeCapacity * 10) / 10
  end
  if freeCapacity > 999 then
    freeCapacity = math.floor(freeCapacity)
  end
  if freeCapacity > 99999 then
    freeCapacity = math.min(9999, math.floor(freeCapacity/1000)) .. "k"
  end
  capLabel:setText(tr('Cap') .. ':\n' .. freeCapacity)
end

function onStatesChange(localPlayer, now, old)
  if now == old then return end
  local bitsChanged = bit32.bxor(now, old)
  for i = 1, 32 do
    local pow = math.pow(2, i-1)
    if pow > bitsChanged then break end
    local bitChanged = bit32.band(bitsChanged, pow)
    if bitChanged ~= 0 then
      toggleIcon(bitChanged)
    end
  end
end

-- [Retro76] Iconos de los hechizos en los paneles de condiciones (inventario, Health Info y barra de arriba,
-- los mismos donde sale el escudo de utamo vita). El byte de estados del 7.6 no tiene bits
-- libres, asi que los maneja el texto que manda el server:
--   "<Hechizo>: ready again in N s."  -> el icono queda APAGADO con la cuenta hasta poder relanzarlo
--   "... for N s." / "... in N s."    -> mientras dura el efecto, ENCENDIDO con los segundos del efecto
--   mensaje de fin                    -> se termina el efecto (queda apagado si falta para relanzarlo)
-- No cambiar estos textos sin cambiar el server (serverrepo: docs/gameplay/SPELLS_FEEDBACK.md y
-- docs/gameplay/SPELL_ATTACK_SPEED.md).
local TimedIcons = {
  { id = 'condition_invisible', path = '/images/game/spells/defaultspells',
    clip = Spells.getImageClip(SpellIcons.invisible[1], 'Default'), names = {},
    tooltip = tr('You are invisible'), native = function(player) return player:isInvisible() end },
  { id = 'condition_soft_boots', path = '/images/game/states/soft_boots', names = {},
    tooltip = tr('Soft Boots active (+3 HP and +12 MP every 3 s)'),
    native = function(player)
      local boots = player:getInventoryItem(InventorySlotFeet)
      -- 6070 = Soft Boots puestas (brillan como los anillos, serverrepo docs/gameplay/SOFT_BOOTS.md)
      return boots ~= nil and (boots:getId() == 3549 or boots:getId() == 6070)
    end },
  { id = 'condition_skill_buff', path = '/images/game/states/skill_buff', names = { 'Skill Buff', 'Sharpshooter' },
    tooltip = tr('Your skills are raised'),
    start = '^Your skills rise by %d+ for (%d+) s%.$', stop = { 'Your skills return to normal.' } },
  { id = 'condition_echo', path = '/images/game/states/echo', names = { 'Echo' },
    tooltip = tr('Your next strike will echo'),
    start = '^Your next strike will echo for (%d+) s%.$', stop = { 'Your strike echoes.', 'The echo fades.', 'The echo fades: you changed target.' } },
  { id = 'condition_attack_speed', path = '/images/game/states/strengthened', names = { 'Frenzy', 'Rapid Fire' },
    tooltip = tr('Your attacks are faster'),
    start = '^Your attacks speed up for (%d+) s%.$', stop = { 'Your attacks slow down.' } },
  { id = 'condition_counter_stance', path = '/images/game/states/counter_stance', names = { 'Counter Stance' },
    tooltip = tr('You are in a counter stance: the next hits deal less damage'),
    start = '^You take a counter stance for (%d+) s', stop = { 'Your counter stance ends.' } },
  { id = 'condition_blood_ritual', path = '/images/game/states/blood_ritual', names = { 'Blood Ritual' },
    tooltip = tr('Your health is turning into mana'),
    start = '^Your blood turns into mana for (%d+) s', stop = { 'Your blood ritual ends.' } },
  -- Recibir una semilla no pone en recarga tu propio hechizo (puede venir de otro druida).
  { id = 'condition_seed_of_life_cooldown', path = '/images/game/states/seed_of_life', names = { 'Seed of Life' } },
  { id = 'condition_seed_of_life', path = '/images/game/states/seed_of_life', names = {}, stacked = true,
    tooltip = tr('A seed of life will bloom on you'),
    start = '^A seed of life will bloom on you in (%d+) s', stop = { 'The seed of life blooms.', 'The seed of life withers.' } },
  { id = 'condition_rescue', path = '/images/game/states/rescue', names = { 'Rescue' },
    tooltip = tr('Monsters attack you instead of your ally'),
    start = '^You draw %d+ monsters? away from .- for (%d+) s', stop = { 'Your rescue ends.' } },
  { id = 'condition_piercing_volley', path = '/images/game/states/piercing_volley', names = { 'Piercing Volley' } },
  { id = 'condition_cleanse', path = '/images/game/states/cleanse', names = { 'Cleanse' } },
  { id = 'condition_chain_lightning', path = '/images/game/states/chain_lightning', names = { 'Chain Lightning' } },
  { id = 'condition_field_detonation', path = '/images/game/states/field_detonation', names = { 'Field Detonation' } },
}
local timedByName = {}
for _, def in ipairs(TimedIcons) do
  for _, name in ipairs(def.names) do
    timedByName[name:lower()] = def
  end
end
-- Todos los paneles donde se ven las condiciones (cada uno con su copia del ícono).
local function timedPanels()
  local list = {}
  if conditionPanel then table.insert(list, conditionPanel) end
  local hi = modules.game_healthinfo and modules.game_healthinfo.healthInfoWindow
  local hp = hi and hi:recursiveGetChildById('conditionPanel')
  if hp then table.insert(list, hp) end
  local top = modules.game_interface and modules.game_interface.getTopBar and modules.game_interface.getTopBar()
  local states = top and top:recursiveGetChildById('states')
  local box = states and states:getChildById('box')
  if box then table.insert(list, box) end
  return list
end

local timedState = {}   -- id -> { activeUntil, readyAt, native, name }; horas locales en ms
local timedEvents = {}

local function removeTimedIcon(def)
  if timedEvents[def.id] then
    removeEvent(timedEvents[def.id])
    timedEvents[def.id] = nil
  end
  timedState[def.id] = nil
  for _, panel in ipairs(timedPanels()) do
    local icon = panel:getChildById(def.id)
    if icon then
      icon:destroy()
    end
  end
end

local function drawTimedIcon(def)
  local st = timedState[def.id]
  local now = g_clock.millis()
  local active = st and math.max(0, math.ceil((st.activeUntil - now) / 1000)) or 0
  local ready = st and math.max(0, math.ceil((st.readyAt - now) / 1000)) or 0
  if not st or (not st.native and active <= 0 and ready <= 0) then
    removeTimedIcon(def)
    return false
  end
  for _, panel in ipairs(timedPanels()) do
    local icon = panel:getChildById(def.id)
    if not icon then
      icon = g_ui.createWidget('ConditionWidget', panel)
      icon:setId(def.id)
      icon:setImageSource(def.path)
      if def.clip then icon:setImageClip(def.clip) end
      icon:setFont('verdana-11px-rounded')
      icon:setTextAlign(AlignBottomRight)
    end
    if st.native then
      icon:setText('')
      icon:setTooltip(def.tooltip)
    elseif active > 0 then
      icon:setOpacity(1.0)
      icon:setColor('#ffffff')
      icon:setText(tostring(active))
      icon:setTooltip((def.tooltip or st.name or '') .. ' (' .. active .. ' s)')
    else
      icon:setOpacity(0.5)
      icon:setColor('#c0c0c0')
      icon:setText(tostring(ready))
      icon:setTooltip((st.name or '') .. ': ' .. tr('ready again in') .. ' ' .. ready .. ' s')
    end
  end
  return true
end

local function tickTimedIcon(def)
  timedEvents[def.id] = nil
  if not drawTimedIcon(def) then return end
  timedEvents[def.id] = scheduleEvent(function()
    tickTimedIcon(def)
  end, 1000)
end

local function updateTimedIcon(def, active, ready, name)
  local st = timedState[def.id] or { activeUntil = 0, readyAt = 0 }
  local now = g_clock.millis()
  if active then
    -- Varias semillas pueden estar pendientes a la vez; florecer una no termina las demás.
    if def.stacked and active > 0 then
      st.pending = (st.pending or 0) + 1
    elseif def.stacked and active == 0 and (st.pending or 0) > 1 then
      st.pending = st.pending - 1
      active = nil
    end
    if active then st.activeUntil = now + active * 1000 end
  end
  if ready then st.readyAt = now + ready * 1000 end
  if name then st.name = name end
  timedState[def.id] = st
  if timedEvents[def.id] then
    removeEvent(timedEvents[def.id])
    timedEvents[def.id] = nil
  end
  tickTimedIcon(def)
end

function refreshNativeSpellIcons(player)
  for _, def in ipairs(TimedIcons) do
    if def.native then
      if player and def.native(player) then
        timedState[def.id] = { activeUntil = 0, readyAt = 0, native = true }
        if not timedEvents[def.id] then tickTimedIcon(def) end
      else
        removeTimedIcon(def)
      end
    end
  end
end

function stopTimedIcons()
  for _, def in ipairs(TimedIcons) do
    removeTimedIcon(def)
  end
end

function onTimedIconMessage(mode, text)
  if type(text) ~= 'string' then return end
  local name, ready = text:match('^(.-): ready again in (%d+) s%.$')
  local def = name and timedByName[name:lower()]
  if def then
    updateTimedIcon(def, nil, tonumber(ready), name)
    return
  end
  for _, def in ipairs(TimedIcons) do
    local seconds = def.start and text:match(def.start)
    if seconds then
      updateTimedIcon(def, tonumber(seconds), nil, nil)
      return
    end
    for _, stopText in ipairs(def.stop or {}) do
      if text == stopText then
        if timedState[def.id] then
          updateTimedIcon(def, 0, nil, nil)
        end
        return
      end
    end
  end
end
