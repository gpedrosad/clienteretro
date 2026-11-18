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
  connect(g_game, { onTextMessage = onTimedIconMessage })

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
end

function terminate()
  disconnect(LocalPlayer, {
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange
  })
  disconnect(g_game, { onGameStart = refresh })
  disconnect(g_game, { onTextMessage = onTimedIconMessage })
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

-- [Retro76] Iconos con cuenta regresiva para los hechizos que duran unos segundos: Frenzy / Rapid Fire
-- (utito hur / utito san hur), Counter Stance (utito tera), Blood Ritual (utamo mort), Seed of Life (exura tera,
-- en quien la recibe) y Rescue (exeta sio). El byte de estados del 7.6 no tiene bits libres, asi que cada icono
-- lo prende un mensaje del server con los segundos ("... for N s.") y lo apaga otro mensaje o la cuenta a 0.
-- Los segundos que quedan se ven sobre el icono. No cambiar estos textos sin cambiar el server
-- (serverrepo: docs/gameplay/SPELL_ATTACK_SPEED.md y docs/gameplay/SPELLS_FEEDBACK.md).
local TimedIcons = {
  { id = 'condition_attack_speed', path = '/images/game/states/strengthened', tooltip = tr('Your attacks are faster'),
    start = '^Your attacks speed up for (%d+) s%.$', stop = { 'Your attacks slow down.' } },
  { id = 'condition_counter_stance', path = '/images/game/states/counter_stance', tooltip = tr('Counter stance: the next hits deal less damage'),
    start = '^You take a counter stance for (%d+) s', stop = { 'Your counter stance ends.' } },
  { id = 'condition_blood_ritual', path = '/images/game/states/blood_ritual', tooltip = tr('Blood ritual: your health turns into mana'),
    start = '^Your blood turns into mana for (%d+) s', stop = { 'Your blood ritual ends.' } },
  { id = 'condition_seed_of_life', path = '/images/game/states/seed_of_life', tooltip = tr('A seed of life will bloom on you'),
    start = '^A seed of life will bloom on you in (%d+) s', stop = { 'The seed of life blooms.', 'The seed of life withers.' } },
  { id = 'condition_rescue', path = '/images/game/states/rescue', tooltip = tr('Monsters attack you instead of your ally'),
    start = '^You draw %d+ monsters? away from .- for (%d+) s', stop = { 'Your rescue ends.' } },
}
local timedLeft = {}
local timedEvents = {}

local function stopTimedIcon(def)
  if timedEvents[def.id] then
    removeEvent(timedEvents[def.id])
    timedEvents[def.id] = nil
  end
  timedLeft[def.id] = nil
  local icon = conditionPanel and conditionPanel:getChildById(def.id)
  if icon then
    icon:destroy()
  end
end

local function tickTimedIcon(def)
  timedEvents[def.id] = nil
  local icon = conditionPanel and conditionPanel:getChildById(def.id)
  local left = timedLeft[def.id] or 0
  if not icon or left <= 0 then
    stopTimedIcon(def)
    return
  end
  icon:setText(tostring(left))
  icon:setTooltip(def.tooltip .. ' (' .. left .. ' s)')
  timedLeft[def.id] = left - 1
  timedEvents[def.id] = scheduleEvent(function() tickTimedIcon(def) end, 1000)
end

local function startTimedIcon(def, seconds)
  stopTimedIcon(def)
  if not conditionPanel then return end
  local icon = g_ui.createWidget('ConditionWidget', conditionPanel)
  icon:setId(def.id)
  icon:setImageSource(def.path)
  icon:setFont('verdana-11px-rounded')
  icon:setColor('#ffffff')
  icon:setTextAlign(AlignBottomRight)
  timedLeft[def.id] = seconds
  tickTimedIcon(def)
end

function stopTimedIcons()
  for _, def in ipairs(TimedIcons) do
    stopTimedIcon(def)
  end
end

function onTimedIconMessage(mode, text)
  if type(text) ~= 'string' then return end
  for _, def in ipairs(TimedIcons) do
    local seconds = text:match(def.start)
    if seconds then
      startTimedIcon(def, tonumber(seconds))
      return
    end
    for _, stopText in ipairs(def.stop) do
      if text == stopText then
        stopTimedIcon(def)
        return
      end
    end
  end
end
