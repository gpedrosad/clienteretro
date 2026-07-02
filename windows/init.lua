-- CONFIG
APP_NAME = "retro_oficial"
APP_VERSION = 760
DEFAULT_LAYOUT = "retro"

Services = {
  website = "",
  updater = "",
  stats = "",
  crash = "",
  feedback = "",
  status = ""
}

Servers = {
  ["Cliente Oficial Retro"] = "retro76.cl:7171:760",
}

ALLOW_CUSTOM_SERVERS = false

g_app.setName("Cliente Oficial Retro")
-- CONFIG END

g_logger.info(os.date("== application started at %b %d %Y %X"))
g_logger.info(g_app.getName() .. ' ' .. g_app.getVersion() .. ' rev ' .. g_app.getBuildRevision() .. ' (' .. g_app.getBuildCommit() .. ') made by ' .. g_app.getAuthor() .. ' built on ' .. g_app.getBuildDate() .. ' for arch ' .. g_app.getBuildArch())

if not g_resources.directoryExists("/data") then
  g_logger.fatal("Data dir doesn't exist.")
end

if not g_resources.directoryExists("/modules") then
  g_logger.fatal("Modules dir doesn't exist.")
end

g_configs.loadSettings("/config.otml")

local settings = g_configs.getSettings()
local layout = DEFAULT_LAYOUT
if g_app.isMobile() then
  layout = "mobile"
elseif settings:exists('layout') then
  layout = settings:getValue('layout')
end
g_resources.setLayout(layout)

g_modules.discoverModules()
g_modules.ensureModuleLoaded("corelib")

local function loadModules()
  g_modules.autoLoadModules(99)
  g_modules.ensureModuleLoaded("gamelib")
  g_modules.autoLoadModules(499)
  g_modules.ensureModuleLoaded("client")
  g_modules.autoLoadModules(999)
  g_modules.ensureModuleLoaded("game_interface")
  g_modules.autoLoadModules(9999)
end

if type(Services.crash) == 'string' and Services.crash:len() > 4 and g_modules.getModule("crash_reporter") then
  g_modules.ensureModuleLoaded("crash_reporter")
end

if type(Services.updater) == 'string' and Services.updater:len() > 4 
  and g_resources.isLoadedFromArchive() and g_modules.getModule("updater") then
  g_modules.ensureModuleLoaded("updater")
  return Updater.init(loadModules)
end
loadModules()
