battleWindow = nil
battleButton = nil
battlePanel = nil

mouseWidget = nil
updateEvent = nil

hoveredCreature = nil
newHoveredCreature = nil
prevCreature = nil

battleButtons = {}
local ageNumber = 1
local ages = {}

function init()  
  g_ui.importStyle('battlebutton')
  battleButton = modules.client_topmenu.addRightGameToggleButton('battleButton', tr('Battle') .. ' (Ctrl+B)', '/images/topbuttons/battle', toggle, false, 2)
  battleButton:setOn(true)
  battleWindow = g_ui.loadUI('battle', modules.game_interface.getRightPanel())
  g_keyboard.bindKeyDown('Ctrl+B', toggle)

  -- this disables scrollbar auto hiding
  local scrollbar = battleWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = { }})

  battlePanel = battleWindow:recursiveGetChildById('battlePanel')

  mouseWidget = g_ui.createWidget('UIButton')
  mouseWidget:setVisible(false)
  mouseWidget:setFocusable(false)
  mouseWidget.cancelNextRelease = false

  battleWindow:setContentMinimumHeight(80)

  battleWindow:setup()
  
  for i=1,30 do
    local battleButton = g_ui.createWidget('BattleButton', battlePanel)
    battleButton:setup()
    battleButton:hide()
    battleButton.onHoverChange = onBattleButtonHoverChange
    battleButton.onMouseRelease = onBattleButtonMouseRelease
    table.insert(battleButtons, battleButton)
  end
  
  updateBattleList()
  
  connect(LocalPlayer, {
    onPositionChange = onPlayerPositionChange
  })
  connect(Creature, {
    onAppear = updateSquare,
    onDisappear = updateSquare
  })  
  connect(g_game, { 
    onAttackingCreatureChange = updateSquare,
    onFollowingCreatureChange = updateSquare 
  })
end

function terminate()
  if battleButton == nil then
    return
  end
  
  battleButtons = {}
  
  g_keyboard.unbindKeyDown('Ctrl+B')
  battleButton:destroy()
  battleWindow:destroy()
  mouseWidget:destroy()
	
  disconnect(LocalPlayer, {
    onPositionChange = onPlayerPositionChange
  })
  disconnect(Creature, {
    onAppear = updateSquare,
    onDisappear = updateSquare
  })  
  disconnect(g_game, { 
    onAttackingCreatureChange = updateSquare,
    onFollowingCreatureChange = updateSquare 
  })

  removeEvent(updateEvent)
end

function toggle()
  if battleButton:isOn() then
    battleWindow:close()
    battleButton:setOn(false)
  else
    battleWindow:open()
    battleButton:setOn(true)
  end
end

function onMiniWindowClose()
  battleButton:setOn(false)
end

-- functions
function updateBattleList() 
  removeEvent(updateEvent)
	updateEvent = scheduleEvent(updateBattleList, 100)
  checkCreatures()
end

function checkCreatures()
  if not battlePanel or not g_game.isOnline() then
    return
  end

  local player = g_game.getLocalPlayer()
  if not player then
    return
  end
  
  local dimension = modules.game_interface.getMapPanel():getVisibleDimension()
  local spectators = g_map.getSpectatorsInRangeEx(player:getPosition(), false, math.floor(dimension.width / 2), math.floor(dimension.width / 2), math.floor(dimension.height / 2), math.floor(dimension.height / 2))
  local maxCreatures = battlePanel:getChildCount()
  
  local creatures = {}
  for _, creature in ipairs(spectators) do
    if doCreatureFitFilters(creature) and #creatures < maxCreatures then
      if not ages[creature:getId()] then
        if ageNumber > 1000 then
          ageNumber = 1
          ages = {}
        end
        ages[creature:getId()] = ageNumber
        ageNumber = ageNumber + 1
      end
      table.insert(creatures, creature)	
    end
  end
  
  updateSquare()
  sortCreatures(creatures)
  battlePanel:getLayout():disableUpdates()
  
  for i=1,#creatures do
    local battleButton = battleButtons[i]
    battleButton:creatureSetup(creatures[i])
    battleButton:show()
    battleButton:setOn(true)
  end
  
  if g_app.isMobile() and #creatures > 0 then
    onBattleButtonHoverChange(battleButtons[1], true)
  end
    
  for i=#creatures + 1,maxCreatures do
    if battleButtons[i]:isHidden() then break end
    battleButtons[i]:hide()
    battleButtons[i]:setOn(false)
  end

  battlePanel:getLayout():enableUpdates()
  battlePanel:getLayout():update()
end

function doCreatureFitFilters(creature)
  if creature:isLocalPlayer() then
    return false
  end
  if creature:getHealthPercent() <= 0 then
    return false
  end

  local pos = creature:getPosition()
  if not pos then return false end

  local localPlayer = g_game.getLocalPlayer()
  if pos.z ~= localPlayer:getPosition().z or not creature:canBeSeen() then return false end

  return true
end

-- Como en el 7.6: en el orden en que aparecieron (el primero arriba). No salta al moverse los monstruos.
function sortCreatures(creatures)
  table.sort(creatures, function(a, b) return (ages[a:getId()] or 0) < (ages[b:getId()] or 0) end)
end

-- other functions
function onBattleButtonMouseRelease(self, mousePosition, mouseButton)
  if mouseWidget.cancelNextRelease then
    mouseWidget.cancelNextRelease = false
    return false
  end
  if not self.creature then
    return false
  end
  if ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton)
    or (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
    mouseWidget.cancelNextRelease = true
    g_game.look(self.creature, true)
    return true
  elseif mouseButton == MouseLeftButton and g_keyboard.isShiftPressed() then
    g_game.look(self.creature, true)
    return true
  elseif mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
    modules.game_interface.createThingMenu(mousePosition, nil, nil, self.creature)
    return true
  elseif mouseButton == MouseLeftButton and not g_mouse.isPressed(MouseRightButton) then
    if self.isTarget then
      g_game.cancelAttack()
    else
      g_game.attack(self.creature)
    end
    return true
  end
  return false
end

function onBattleButtonHoverChange(battleButton, hovered)
  if not hovered then
    newHoveredCreature = nil    
  else
    newHoveredCreature = battleButton.creature
  end
  if battleButton.isHovered ~= hovered then
    battleButton.isHovered = hovered
    battleButton:update()
  end
  updateSquare()
end

function onPlayerPositionChange(creature, newPos, oldPos)
  addEvent(checkCreatures)
end

local CreatureButtonColors = {
  onIdle = {notHovered = '#888888', hovered = '#FFFFFF' },
  onTargeted = {notHovered = '#FF0000', hovered = '#FF8888' },
  onFollowed = {notHovered = '#00FF00', hovered = '#88FF88' }
}

function updateSquare()
  local following = g_game.getFollowingCreature()
  local attacking = g_game.getAttackingCreature()
    
  if newHoveredCreature == nil then
    if hoveredCreature ~= nil then
      hoveredCreature:hideStaticSquare()
      hoveredCreature = nil
    end
  else
    if hoveredCreature ~= nil then
      hoveredCreature:hideStaticSquare()
    end
    hoveredCreature = newHoveredCreature
    hoveredCreature:showStaticSquare(CreatureButtonColors.onIdle.hovered)
  end
  
  local color = CreatureButtonColors.onIdle
  local creature = nil
  if attacking then
    color = CreatureButtonColors.onTargeted
    creature = attacking
  elseif following then
    color = CreatureButtonColors.onFollowed
    creature = following
  end

  if prevCreature ~= creature then
    if prevCreature ~= nil then
      prevCreature:hideStaticSquare()
    end
    prevCreature = creature
  end
  
  if not creature then
    return
  end
  
  color = creature == hoveredCreature and color.hovered or color.notHovered
  creature:showStaticSquare(color)
end