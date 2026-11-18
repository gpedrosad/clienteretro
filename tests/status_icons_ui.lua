-- Ejecutar en una copia de QA del cliente; ver Contexto/Documentacion/status-icons.md.
g_resources.makeDir('/settings/')
local stage = g_ui.createWidget('UIWidget', g_ui.getRootWidget())
stage:setSize({width = 980, height = 640})
stage:setPosition({x = 0, y = 0})
stage:setBackgroundColor('#24262c')
local title = g_ui.createWidget('Label', stage)
title:setText('Retro76 - condiciones y recargas (prueba local sin conexion)')
title:setPosition({x = 30, y = 20})
title:setSize({width = 900, height = 25})
modules.game_topbar.setupTopBar()
local top = modules.game_interface.getTopBar()
local topParent = top:getParent()
top:setParent(stage)
top:show()
top:setSize({width = 880, height = 100})
top:setPosition({x = 30, y = 60})
local health = modules.game_healthinfo.healthInfoWindow
local healthParent = health:getParent()
health:setParent(stage)
health:setPosition({x = 35, y = 190})
health:show()
local inventory = modules.game_inventory.inventoryWindow
local inventoryParent = inventory:getParent()
inventory:setParent(stage)
inventory:setPosition({x = 310, y = 190})
inventory:show()
local bits = PlayerStates.Poison + PlayerStates.Burn + PlayerStates.Energy + PlayerStates.Drunk + PlayerStates.ManaShield + PlayerStates.Paralyze + PlayerStates.Haste + PlayerStates.Swords
modules.game_inventory.onStatesChange(nil, bits, 0)
modules.game_healthinfo.onStatesChange(nil, bits, 0)
modules.game_topbar.onStatesChange(nil, bits, 0)
local messages = {
 'Your skills rise by 30 for 10 s.', 'Echo: ready again in 25 s.',
 'Your next strike will echo for 6 s.', 'Frenzy: ready again in 20 s.',
 'Your attacks speed up for 6 s.', 'Counter Stance: ready again in 30 s.',
 'You take a counter stance for 5 s: the next 2 hits deal 25% less damage.',
 'Blood Ritual: ready again in 30 s.', 'Your blood turns into mana for 8 s: 30 health into 60 mana every 2 s.',
 'Seed of Life: ready again in 12 s.', 'A seed of life will bloom on you in 3 s.',
 'Rescue: ready again in 15 s.', 'You draw 2 monsters away from Ally for 4 s.',
 'Piercing Volley: ready again in 8 s.', 'Cleanse: ready again in 10 s.',
 'Chain Lightning: ready again in 8 s.', 'Field Detonation: ready again in 15 s.'
}
for _, text in ipairs(messages) do g_game.onTextMessage(MessageModes.Look, text) end
modules.game_inventory.refreshNativeSpellIcons({isInvisible = function() return true end})
scheduleEvent(function()
 local states = top:recursiveGetChildById('box')
 local conditions = health:recursiveGetChildById('conditionPanel')
 assert(states:getChildCount() == 21, 'top icon count: ' .. states:getChildCount())
 assert(states:getHeight() >= 36 or states:getWidth() >= states:getChildCount() * 20, 'top clips icons')
 assert(conditions:isVisible(), 'health conditions hidden')
 assert(conditions:getHeight() >= 40, 'health conditions must wrap')
 assert(conditions:getChildById('condition_seed_of_life'):getText() ~= '', 'seed timer missing')
 assert(conditions:getChildById('condition_seed_of_life_cooldown'):getText() ~= '', 'seed cooldown missing')
 assert(conditions:getChildById('condition_invisible'):getText() == '', 'invented invisibility duration')
 assert(inventory:recursiveGetChildById('conditionPanel'):getHeight() >= 40, 'inventory must wrap')
 top:setWidth(480)
 scheduleEvent(function()
   print('QA narrow geometry: top=' .. top:getWidth() .. ', stats=' .. top:recursiveGetChildById('stats'):getWidth() .. ', box=' .. states:getWidth() .. 'x' .. states:getHeight() .. ', columns=' .. states:getLayout():getNumColumns())
   assert(states:getHeight() >= 36, 'narrow top must wrap')
   print('STATUS_QA: narrow layout PASS; top=' .. states:getWidth() .. 'x' .. states:getHeight())
   health:minimize(true)
   inventory:minimize(true)
   local healthHeight, inventoryHeight = health:getHeight(), inventory:getHeight()
   modules.game_inventory.stopTimedIcons()
   scheduleEvent(function()
     assert(health:getHeight() == healthHeight, 'minimized health grew')
     assert(inventory:getHeight() == inventoryHeight, 'minimized inventory grew')
     health:maximize(true)
     inventory:maximize(true)
     scheduleEvent(function()
       assert(conditions:getHeight() == 22, 'health rows did not shrink')
       assert(inventory:recursiveGetChildById('conditionPanel'):getHeight() == 40, 'inventory rows did not shrink')
       print('STATUS_QA: minimize/maximize/cleanup PASS')
       top:setParent(topParent)
       health:setParent(healthParent, true)
       inventory:setParent(inventoryParent, true)
       stage:destroy()
       g_app.exit()
     end, 500)
   end, 500)
 end, 500)
 print('STATUS_QA: real UI PASS; icons=' .. states:getChildCount() .. ', top=' .. states:getHeight() .. ', health=' .. conditions:getHeight())
end, 500)
