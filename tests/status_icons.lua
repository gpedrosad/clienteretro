-- luajit tests/status_icons.lua [mac|windows], desde la raíz de clienteretro.
local platform = arg[1] or 'mac'
dofile(platform .. '/modules/gamelib/const.lua')
Player = {}
dofile(platform .. '/modules/gamelib/player.lua')
tr = function(text) return text end
AlignBottomRight = 1
local now, serial, events = 0, 0, {}
g_clock = { millis = function() return now end }
function scheduleEvent(callback, delay)
  serial = serial + 1
  events[serial] = {callback = callback, due = now + delay}
  return serial
end
function removeEvent(id) events[id] = nil end
local function advance(ms)
  now = now + ms  -- simula también un event loop detenido por varios segundos
  local due = {}
  for id, event in pairs(events) do
    if event.due <= now then due[#due+1] = id end
  end
  for _, id in ipairs(due) do
    local event = events[id]
    events[id] = nil
    if event then event.callback() end
  end
end
local function panel()
  local p = {children = {}}
  function p:getChildById(id) return self.children[id] end
  return p
end
local panels = {panel(), panel(), panel()}
g_ui = {createWidget = function(style, parent)
  local icon = {}
  function icon:setId(id) self.id = id; parent.children[id] = self end
  function icon:destroy() parent.children[self.id] = nil end
  for _, property in ipairs({'ImageSource','ImageClip','Font','TextAlign','Text','Tooltip','Opacity','Color'}) do
    icon['set' .. property] = function(self, value) self[property] = value end
  end
  return icon
end}
modules = {
  game_healthinfo = {healthInfoWindow = {recursiveGetChildById = function() return panels[2] end}},
  game_interface = {getTopBar = function()
    return {recursiveGetChildById = function()
      return {getChildById = function() return panels[3] end}
    end}
  end}
}
dofile(platform .. '/modules/gamelib/spells.lua')
dofile(platform .. '/modules/game_inventory/inventory.lua')
conditionPanel = panels[1]
local checks = 0
local function expect(id, text, opacity)
  for _, p in ipairs(panels) do
    local icon = p:getChildById('condition_' .. id)
    if text == nil then
      assert(not icon, id .. ' should be absent')
    else
      assert(icon, id .. ' missing')
      assert(icon.Text == text, id .. ': expected ' .. text .. ', got ' .. tostring(icon.Text))
      if opacity then assert(icon.Opacity == opacity, id .. ': wrong opacity') end
    end
    checks = checks + 1
  end
end
local function message(text) onTimedIconMessage(20, text) end
local cases = {
  {'skill_buff','Skill Buff','Your skills rise by 30 for 10 s.','Your skills return to normal.',10},
  {'skill_buff','Sharpshooter','Your skills rise by 30 for 10 s.','Your skills return to normal.',10},
  {'echo','Echo','Your next strike will echo for 6 s.','Your strike echoes.',6},
  {'attack_speed','Frenzy','Your attacks speed up for 6 s.','Your attacks slow down.',6},
  {'attack_speed','Rapid Fire','Your attacks speed up for 6 s.','Your attacks slow down.',6},
  {'counter_stance','Counter Stance','You take a counter stance for 5 s: the next 2 hits deal 25% less damage.','Your counter stance ends.',5},
  {'blood_ritual','Blood Ritual','Your blood turns into mana for 8 s: 30 health into 60 mana every 2 s.','Your blood ritual ends.',8},
  {'rescue','Rescue','You draw 2 monsters away from Ally for 4 s.','Your rescue ends.',4},
}
for _, c in ipairs(cases) do
  stopTimedIcons()
  message(c[2]:lower() .. ': ready again in 30 s.')
  message(c[3])
  expect(c[1],tostring(c[5]),1)
  advance(2200)
  expect(c[1],tostring(c[5]-2),1)
  message(c[4])
  expect(c[1],'28',0.5)
  advance(28000)
  expect(c[1],nil)
end
for _, c in ipairs({{'piercing_volley','Piercing Volley'},{'cleanse','Cleanse'},{'chain_lightning','Chain Lightning'},{'field_detonation','Field Detonation'}}) do
  message(c[2] .. ': ready again in 8 s.')
  expect(c[1],'8',0.5)
  advance(8100)
  expect(c[1],nil)
end
-- Quien recibe la semilla conserva su propia recarga y el indicador de la curación.
message('Seed of Life: ready again in 12 s.')
advance(4000)
message('A seed of life will bloom on you in 3 s.')
expect('seed_of_life','3',1)
expect('seed_of_life_cooldown','8',0.5)
message('The seed of life blooms.')
expect('seed_of_life',nil)
expect('seed_of_life_cooldown','8',0.5)
stopTimedIcons()
message('A seed of life will bloom on you in 3 s.')
expect('seed_of_life_cooldown',nil)
message('The seed of life withers.')
expect('seed_of_life',nil)
-- Dos druidas: florecer la primera semilla deja visible la segunda.
message('A seed of life will bloom on you in 3 s.')
advance(1000)
message('A seed of life will bloom on you in 3 s.')
advance(2000)
message('The seed of life blooms.')
expect('seed_of_life','1',1)
message('The seed of life withers.')
expect('seed_of_life',nil)
-- Recast actualiza el plazo; los mensajes de fin no agregan un segundo de recarga.
message('Your next strike will echo for 6 s.')
message('Echo: ready again in 25 s.')
advance(3500)
message('The echo fades: you changed target.')
expect('echo','22',0.5)
advance(21500)
expect('echo',nil)
-- El ícono nativo sigue al outfit real, sin inventar duración y sin confundir chameleon.
onOutfitChange({isInvisible=function() return true end},{},{})
expect('invisible','')
advance(300000)
expect('invisible','')
assert(panels[1].children.condition_invisible.ImageClip == Spells.getImageClip(SpellIcons.invisible[1], 'Default'))
onOutfitChange({isInvisible=function() return false end},{},{})
expect('invisible',nil)
message('Frenzy: ready again in 20 s.')
stopTimedIcons()
expect('attack_speed',nil)
assert(next(events) == nil, 'events remain after logout/unload')
print(platform .. ': PASS (' .. checks .. ' widget checks; active/cooldown, stall, seed, invisibility, cleanup)')
