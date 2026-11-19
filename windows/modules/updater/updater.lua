Updater = { }

Updater.maxRetries = 5

--[[

]]--

local updaterWindow
local loadModulesFunction
local scheduledEvent
local httpOperationId = 0
-- Retro76: login que espera a que termine la actualizacion (Updater.checkBeforeLogin)
local loginContinue

-- Retro76: archivos que se cambian sin reiniciar ni recargar modulos (sprites y minimapa)
local function isDataOnly(file)
  return string.find(file, "data/things") or string.find(file, "data/minimap")
end

local function onLog(level, message, time)
  if level == LogError then    
    Updater.error(message)
    g_logger.setOnLog(nil)
  end
end

local function initAppWindow()
  if g_resources.getLayout() == "mobile" then
    g_window.setMinimumSize({ width = 640, height = 360 })
  else
    g_window.setMinimumSize({ width = 800, height = 640 })  
  end

  -- window size
  local size = { width = 1024, height = 600 }
  size = g_settings.getSize('window-size', size)
  g_window.resize(size)

  -- window position, default is the screen center
  local displaySize = g_window.getDisplaySize()
  local defaultPos = { x = (displaySize.width - size.width)/2,
                       y = (displaySize.height - size.height)/2 }
  local pos = g_settings.getPoint('window-pos', defaultPos)
  pos.x = math.max(pos.x, 0)
  pos.y = math.max(pos.y, 0)
  g_window.move(pos)

  -- window maximized?
  local maximized = g_settings.getBoolean('window-maximized', false)
  if maximized then g_window.maximize() end

  g_window.setTitle(g_app.getName())
  g_window.setIcon('/images/clienticon')
  
  if g_app.isMobile() then
    scheduleEvent(function()
      g_app.scale(5.0)
    end, 10)
  end
end

local function loadModules()
  if loadModulesFunction then
    local tmpLoadFunc = loadModulesFunction
    loadModulesFunction = nil
    tmpLoadFunc()
  end
end

local function downloadFiles(url, files, index, retries, doneCallback)
  if not updaterWindow then return end
  local entry = files[index]
  if not entry then -- finished
    return doneCallback()
  end
  local file = entry[1]
  local file_checksum = entry[2]
  
  if retries > 0 then
    updaterWindow.downloadStatus:setText(tr("Downloading (%i retry):\n%s", retries, file))
  else
    updaterWindow.downloadStatus:setText(tr("Downloading:\n%s", file))
  end
  updaterWindow.downloadProgress:setPercent(0)
  updaterWindow.mainProgress:setPercent(math.floor(100 * index / #files))
  
  httpOperationId = HTTP.download(url .. file, file,
    function (file, checksum, err)
      if not err and checksum ~= file_checksum then
        err = "Invalid checksum of: " .. file .. ".\nShould be " .. file_checksum .. ", is: " .. checksum
      end
      if err then
        if retries >= Updater.maxRetries then
          Updater.error("Can't download file: " .. file .. ".\nError: " .. err)
        else
          scheduledEvent = scheduleEvent(function()
            downloadFiles(url, files, index, retries + 1, doneCallback)
          end, 250)
        end
        return
      end
      downloadFiles(url, files, index + 1, 0, doneCallback)
    end,
    function (progress, speed)
      updaterWindow.downloadProgress:setPercent(progress)
      updaterWindow.downloadProgress:setText(speed .. " kbps")
    end)
end

local function updateFiles(data, keepCurrentFiles)
  if not updaterWindow then return end
  if type(data) ~= "table" then
    return Updater.error("Invalid data from updater api (not table)")
  end
  if type(data["error"]) == 'string' and data["error"]:len() > 0 then
    return Updater.error(data["error"])    
  end
  if not data["files"] or type(data["url"]) ~= 'string' or data["url"]:len() < 4 then
    return Updater.error("Invalid data from updater api: " .. json.encode(data, 2))
  end
  if data["keepFiles"] then
    keepCurrentFiles = true
  end
  
  local newFiles = false
  local finalFiles = {}
  local localFiles = g_resources.filesChecksums()
  local toUpdate = {}
  -- keep all files or files from data/things
  for file, checksum in pairs(localFiles) do
    if keepCurrentFiles or string.find(file, "data/things") then
      table.insert(finalFiles, file)
    end
  end
  -- update files
  for file, checksum in pairs(data["files"]) do
    table.insert(finalFiles, file)
    if not localFiles[file] or localFiles[file] ~= checksum then
      table.insert(toUpdate, {file, checksum})
      newFiles = true
    end
  end
  -- update binary
  local binary = nil
  if type(data["binary"]) == "table" and data["binary"]["file"]:len() > 1 then
    local selfChecksum = g_resources.selfChecksum()
    if selfChecksum:len() > 0 and selfChecksum ~= data["binary"]["checksum"] then
      binary = data["binary"]["file"]
      table.insert(toUpdate, {binary, data["binary"]["checksum"]})
    end
  end
  
  if #toUpdate == 0 then -- nothing to update
    updaterWindow.mainProgress:setPercent(100)
    scheduledEvent = scheduleEvent(Updater.abort, 20)
    return
  end
  
  -- update of some files require full client restart
  local forceRestart = false
  local reloadModules = false
  local thingsChanged = false
  local forceRestartPattern = {"init.lua", "corelib", "updater", "otmod"}
  for _, file in ipairs(toUpdate) do
    for __, pattern in ipairs(forceRestartPattern) do
      if string.find(file[1], pattern) then
        forceRestart = true
      end
      if not isDataOnly(file[1]) then
        reloadModules = true
      end
    end
    if string.find(file[1], "data/things") then
      thingsChanged = true
    end
  end
  
  updaterWindow.status:setText(tr("Updating %i files", #toUpdate))
  updaterWindow.mainProgress:setPercent(0)
  updaterWindow.downloadProgress:setPercent(0)
  updaterWindow.downloadProgress:show()
  updaterWindow.downloadStatus:show()
  updaterWindow.changeUrlButton:hide()
  downloadFiles(data["url"], toUpdate, 1, 0, function()
    updaterWindow.status:setText(tr("Updating client (may take few seconds)"))
    updaterWindow.mainProgress:setPercent(100)
    updaterWindow.downloadProgress:hide()
    updaterWindow.downloadStatus:hide() 
    scheduledEvent = scheduleEvent(function()
      local restart = binary or (not loadModulesFunction and reloadModules) or forceRestart
      if newFiles then
        g_resources.updateData(finalFiles, not restart)
      end
      if binary then
        g_resources.updateExecutable(binary)
      end
      if restart then
        if loginContinue then
          -- Retro76: al volver a abrir, la pantalla de login avisa que hay que entrar de nuevo
          g_settings.set('updated-at-login', true)
          g_settings.save()
        end
        g_app.restart()
      else
        if reloadModules then
          g_modules.reloadModules()
        end
        -- Retro76: sprites nuevos con el cliente abierto (si ya se cargaron alguna vez)
        if thingsChanged and g_game.getClientVersion() > 0 and modules.game_things then
          modules.game_things.load()
        end
        Updater.abort()
      end
    end, 100)  
  end)
end

-- public functions
function Updater.init(loadModulesFunc)
  g_logger.setOnLog(onLog)
  loadModulesFunction = loadModulesFunc
  initAppWindow()
  Updater.check()
end

function Updater.terminate()
  loadModulesFunction = nil
  loginContinue = nil
  Updater.abort()
end

function Updater.abort()
  HTTP.cancel(httpOperationId)
  removeEvent(scheduledEvent)
  if updaterWindow then
    updaterWindow:destroy()
    updaterWindow = nil
  end
  loadModules()
  if loginContinue then
    local fn = loginContinue
    loginContinue = nil
    fn()
  end
end

-- Retro76: al apretar Login, preguntar a la web si hay archivos nuevos antes de conectar.
-- Sin cambios (o si la web no responde) sigue el login enseguida. Si hay, abre la ventana del updater y los baja:
-- sprites y minimapa se cambian con el cliente abierto y el login sigue solo; si cambio codigo del cliente
-- (modulos, init.lua) se reinicia como al abrirlo. Doc: docs/CLIENT_UPDATER_RETRO76.md (serverrepo).
Updater.loginTimeout = 5000

local loginChecking = false

function Updater.checkBeforeLogin(onContinue)
  if loginChecking or loginContinue or updaterWindow then
    return -- ya hay un login revisando o actualizando: este segundo intento (otro Enter) se ignora
  end
  if type(Services.updater) ~= 'string' or Services.updater:len() <= 4 or not g_resources.isLoadedFromArchive() then
    return onContinue()
  end

  loginChecking = true
  local finished = false
  local box = displayCancelBox(tr('Please wait'), tr('Checking for updates...'))
  local timeoutEvent
  local function finish()
    if finished then return false end
    finished = true
    loginChecking = false
    removeEvent(timeoutEvent)
    if box then
      box:destroy()
      box = nil
    end
    return true
  end
  connect(box, { onCancel = function()
    box = nil
    if finish() then
      HTTP.cancel(httpOperationId)
      if EnterGame then EnterGame.show() end
    end
  end })
  timeoutEvent = scheduleEvent(function()
    if finish() then
      g_logger.warning("Updater: la web no respondio a tiempo, se entra sin actualizar")
      HTTP.cancel(httpOperationId)
      onContinue()
    end
  end, Updater.loginTimeout)

  httpOperationId = HTTP.postJSON(Services.updater, {
    version = APP_VERSION,
    build = g_app.getVersion(),
    os = g_app.getOs(),
    platform = g_window.getPlatformType(),
    args = {}
  }, function(data, err)
    if not finish() then return end
    if err or type(data) ~= "table" or type(data["files"]) ~= "table" then
      g_logger.warning("Updater: no se pudo revisar al entrar (" .. tostring(err or "respuesta invalida") .. ")")
      return onContinue()
    end
    local localFiles = g_resources.filesChecksums()
    local changed = false
    for file, checksum in pairs(data["files"]) do
      if localFiles[file] ~= checksum then
        changed = true
        break
      end
    end
    if not changed then
      return onContinue()
    end
    loginContinue = onContinue
    updaterWindow = g_ui.displayUI('updater')
    updaterWindow:show()
    updaterWindow:focus()
    updaterWindow:raise()
    updateFiles(data)
  end)
end

function Updater.check(args)
  if updaterWindow then return end
  
  updaterWindow = g_ui.displayUI('updater')
  updaterWindow:show()
  updaterWindow:focus()
  updaterWindow:raise()  
  
  local updateData = nil
  local function progressUpdater(value)
    removeEvent(scheduledEvent)
    if value == 100 then
      return Updater.error(tr("Timeout"))
    end
    if updateData and (value > 60 or (not g_app.isMobile() or not ALLOW_CUSTOM_SERVERS or not loadModulesFunc)) then -- gives 3s to set custom updater for mobile version
      return updateFiles(updateData)
    end
    scheduledEvent = scheduleEvent(function() progressUpdater(value + 1) end, 50)
    updaterWindow.mainProgress:setPercent(value)
  end
  progressUpdater(0)

  httpOperationId = HTTP.postJSON(Services.updater, {
    version = APP_VERSION,
    build = g_app.getVersion(),
    os = g_app.getOs(),
    platform = g_window.getPlatformType(),
    args = args or {}
  }, function(data, err)
    if err then      
      return Updater.error(err)
    end
    updateData = data
  end)
end

function Updater.error(message)
  removeEvent(scheduledEvent)
  if not updaterWindow then return end
  displayErrorBox(tr("Updater Error"), message).onOk = function()
    Updater.abort()
  end
end

function Updater.changeUrl()
  removeEvent(scheduledEvent)
  modules.client_textedit.edit(Services.updater, {title="Enter updater url", width=300}, function(newUrl)
    if updaterWindow and newUrl:len() > 4 then
      Services.updater = newUrl
    end
    if updaterWindow then
      updaterWindow:destroy()
      updaterWindow = nil
    end
    Updater.check()
  end)
end