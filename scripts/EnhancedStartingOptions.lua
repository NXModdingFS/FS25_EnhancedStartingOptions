local ESO_MOD_DIR = g_currentModDirectory or ""

enhancedStartingOptions = {
    elapsedMs         = 0,

    guiLoaded         = false,
    selectorShown     = false,
    monthChosen       = false,
    chosenMonth       = nil,
    selectorTimeoutMs = 120000,

    notifyText        = nil,
    notifyShown       = false,
    notifyRetryMs     = 0,
    shownOnce         = false,

    alreadyRan        = false,
    flagWritePending  = false,
    fieldsApplied     = false,

    pendingPeriodBroadcast = false,

    loadedDefaults    = nil,
}

local SELECTOR_SHOW_MS    = 5000
local FIELDS_APPLY_MS     = 8000
local NOTIFY_RETRY_MAX_MS = 45000

local MARCH = {
    name                = "March",
    period              = 1,
    dayInPeriod         = 1,
    dayOfYear           = 1,
    daysPerPeriod       = 3,
    startHour           = 6,
    plowingEnabled      = true,
    weedsEnabled        = true,
    limeRequired        = true,
    helperBuyFuel       = true,
    helperBuySeeds      = true,
    helperBuyFertilizer = true,
    helperSlurrySource  = 2,
    helperManureSource  = 2,
    economicDifficulty  = 1,
    moneyUnit           = 0,
    automaticMotorStart = true,
    fruitDestruction    = true,
    timeScale           = 5,
}

function Mission00:getIsTourSupported()
    return false
end

local function ESO_onEnvironmentLoad(env, xmlFile, missionInfo, baseDirectory)
    if g_currentMission ~= nil
    and g_currentMission.getIsServer ~= nil
    and g_currentMission:getIsServer() then
        Environment.INITIAL_PERIOD        = MARCH.period
        Environment.INITIAL_DAY_IN_PERIOD = MARCH.dayInPeriod
        Environment.INITIAL_DAY           = MARCH.dayOfYear
    end
end
Environment.load = Utils.prependedFunction(Environment.load, ESO_onEnvironmentLoad)

local function ESO_isServerSP()
    if g_currentMission == nil or g_currentMission.getIsServer == nil then return false end
    if not g_currentMission:getIsServer() then return false end
    local mi = g_currentMission.missionInfo
    if mi == nil then return false end
    if mi.isMultiplayer == true then return false end
    return true
end

local function ESO_getSaveFlagPath()
    local mi = g_currentMission and g_currentMission.missionInfo
    if mi == nil
    or mi.savegameDirectory == nil
    or mi.savegameDirectory == "" then
        return nil
    end
    return mi.savegameDirectory .. "/enhancedStartingOptions.xml"
end

local function ESO_getModSettingsPath()
    local appPath = getUserProfileAppPath()
    return Utils.getFilename("modSettings/FS25_EnhancedStartingOptions.xml", appPath)
end

local function ESO_readProfileXML(path)
    if path == nil then return nil end
    if not fileExists(path) then return nil end

    local xmlFile = loadXMLFile("ESO_profile_read", path)
    if xmlFile == nil or xmlFile == 0 then return nil end

    local s = {}
    local base = "enhancedStartingOptions.settings"

    local function getB(key, default)
        local v = getXMLBool(xmlFile, base .. "#" .. key)
        if v == nil then return default end
        return v
    end
    local function getI(key, default)
        local v = getXMLInt(xmlFile, base .. "#" .. key)
        if v == nil then return default end
        return v
    end

    s.period              = getI("period",              1)
    s.dayInPeriod         = getI("dayInPeriod",         1)
    s.daysPerPeriod       = getI("daysPerPeriod",       3)
    s.startHour           = getI("startHour",           6)
    s.plowingEnabled      = getB("plowingEnabled",      true)
    s.weedsEnabled        = getB("weedsEnabled",        true)
    s.limeRequired        = getB("limeRequired",        true)
    s.helperBuyFuel       = getB("helperBuyFuel",       true)
    s.helperBuySeeds      = getB("helperBuySeeds",      true)
    s.helperBuyFertilizer = getB("helperBuyFertilizer", true)
    s.helperSlurrySource  = getI("helperSlurrySource",  2)
    s.helperManureSource  = getI("helperManureSource",  2)
    s.economicDifficulty  = getI("economicDifficulty",  1)
    s.moneyUnit           = getI("moneyUnit",           0)
    s.automaticMotorStart = getB("automaticMotorStart", true)
    s.fruitDestruction    = getB("fruitDestruction",    true)
    s.timeScale           = getI("timeScale",           5)

    delete(xmlFile)
    return s
end

local function ESO_writeProfileXML(path, settings, includeRanFlag)
    if path == nil or settings == nil then return false end

    createFolder(getUserProfileAppPath() .. "modSettings/")

    local xmlFile
    if fileExists(path) then
        xmlFile = loadXMLFile("ESO_profile_write", path)
    else
        xmlFile = createXMLFile("ESO_profile_write", path, "enhancedStartingOptions")
    end

    if xmlFile == nil or xmlFile == 0 then return false end

    if includeRanFlag then
        setXMLBool(xmlFile, "enhancedStartingOptions#ran", true)
    end

    local base = "enhancedStartingOptions.settings"
    setXMLInt (xmlFile, base .. "#period",              settings.period              or 1)
    setXMLInt (xmlFile, base .. "#dayInPeriod",         settings.dayInPeriod         or 1)
    setXMLInt (xmlFile, base .. "#daysPerPeriod",       settings.daysPerPeriod       or 3)
    setXMLInt (xmlFile, base .. "#startHour",           settings.startHour           or 6)
    setXMLBool(xmlFile, base .. "#plowingEnabled",      settings.plowingEnabled      ~= false)
    setXMLBool(xmlFile, base .. "#weedsEnabled",        settings.weedsEnabled        ~= false)
    setXMLBool(xmlFile, base .. "#limeRequired",        settings.limeRequired        ~= false)
    setXMLBool(xmlFile, base .. "#helperBuyFuel",       settings.helperBuyFuel       ~= false)
    setXMLBool(xmlFile, base .. "#helperBuySeeds",      settings.helperBuySeeds      ~= false)
    setXMLBool(xmlFile, base .. "#helperBuyFertilizer", settings.helperBuyFertilizer ~= false)
    setXMLInt (xmlFile, base .. "#helperSlurrySource",  settings.helperSlurrySource  or 2)
    setXMLInt (xmlFile, base .. "#helperManureSource",  settings.helperManureSource  or 2)
    setXMLInt (xmlFile, base .. "#economicDifficulty",  settings.economicDifficulty  or 1)
    setXMLInt (xmlFile, base .. "#moneyUnit",           settings.moneyUnit           or 0)
    setXMLBool(xmlFile, base .. "#automaticMotorStart", settings.automaticMotorStart ~= false)
    setXMLBool(xmlFile, base .. "#fruitDestruction",    settings.fruitDestruction    ~= false)
    setXMLInt (xmlFile, base .. "#timeScale",           settings.timeScale           or 5)

    saveXMLFile(xmlFile)
    delete(xmlFile)
    return true
end

local function ESO_getMergedDefaults()
    local profilePath = ESO_getModSettingsPath()
    local merged = ESO_readProfileXML(profilePath) or {}

    local savePath = ESO_getSaveFlagPath()
    if savePath ~= nil and fileExists(savePath) then
        local saveProfile = ESO_readProfileXML(savePath)
        if saveProfile ~= nil then
            for k, v in pairs(saveProfile) do merged[k] = v end
        end
    end

    return merged
end

local function ESO_isNewCareer()
    local mi = g_currentMission and g_currentMission.missionInfo
    if mi == nil then return false end
    if mi.isMultiplayer == true then return false end
    local path = ESO_getSaveFlagPath()
    if path == nil then return true end
    return not fileExists(path)
end

local function ESO_writeFlag()
    local path = ESO_getSaveFlagPath()
    if path == nil then return false end

    local xmlFile
    if fileExists(path) then
        xmlFile = loadXMLFile("ESO_flag", path)
    end
    if xmlFile == nil or xmlFile == 0 then
        xmlFile = createXMLFile("ESO_flag", path, "enhancedStartingOptions")
    end
    if xmlFile == nil then return false end

    setXMLBool(xmlFile, "enhancedStartingOptions#ran", true)
    saveXMLFile(xmlFile)
    delete(xmlFile)
    return true
end

local function ESO_getText(key, fallback)
    if g_i18n ~= nil and g_i18n.getText ~= nil then
        local t = g_i18n:getText(key)
        if t ~= nil and t ~= "" and t ~= key then return t end
    end
    return fallback
end

local function ESO_applyDaysPerPeriod(dpp)
    local env = g_currentMission and g_currentMission.environment
    if env == nil then return end

    env.daysPerPeriod = dpp

    local mi = g_currentMission and g_currentMission.missionInfo
    if mi ~= nil then
        mi.plannedDaysPerPeriod = dpp
    end

    if SavegameSettingsEvent ~= nil and SavegameSettingsEvent.sendEvent ~= nil then
        pcall(SavegameSettingsEvent.sendEvent, mi)
    end
end

local function ESO_applyCurrency(moneyUnit)
    if moneyUnit == nil then return end
    if g_gameSettings == nil then return end

    g_gameSettings.moneyUnit = moneyUnit

    for _, methodName in ipairs({ "save", "saveToXMLFile", "saveToXML", "saveSettings" }) do
        if g_gameSettings[methodName] ~= nil then
            local ok = pcall(g_gameSettings[methodName], g_gameSettings)
            if ok then break end
        end
    end
end

local function ESO_applyGameRules(month)
    if month == nil then return end

    local mi = g_currentMission and g_currentMission.missionInfo
    if mi == nil then return end

    if month.plowingEnabled ~= nil then
        mi.plowingRequiredEnabled = month.plowingEnabled
    end

    if month.weedsEnabled ~= nil then
        mi.weedsEnabled = month.weedsEnabled
        pcall(function()
            if g_messageCenter ~= nil and MessageType.WEEDS_ENABLED_CHANGED ~= nil then
                g_messageCenter:publish(MessageType.WEEDS_ENABLED_CHANGED, month.weedsEnabled)
            end
        end)
    end

    if month.limeRequired ~= nil then
        mi.limeRequired = month.limeRequired
        pcall(function()
            if g_messageCenter ~= nil and MessageType.LIME_REQUIRED_CHANGED ~= nil then
                g_messageCenter:publish(MessageType.LIME_REQUIRED_CHANGED, month.limeRequired)
            end
        end)
    end

    if month.helperBuyFuel        ~= nil then mi.helperBuyFuel        = month.helperBuyFuel        end
    if month.helperBuySeeds       ~= nil then mi.helperBuySeeds       = month.helperBuySeeds       end
    if month.helperBuyFertilizer  ~= nil then mi.helperBuyFertilizer  = month.helperBuyFertilizer  end
    if month.helperSlurrySource   ~= nil then mi.helperSlurrySource   = month.helperSlurrySource   end
    if month.helperManureSource   ~= nil then mi.helperManureSource   = month.helperManureSource   end

    if month.economicDifficulty ~= nil then
        mi.economicDifficulty = month.economicDifficulty
        pcall(function()
            if g_currentMission.economyManager ~= nil
            and g_currentMission.economyManager.setEconomicDifficulty ~= nil then
                g_currentMission.economyManager:setEconomicDifficulty(month.economicDifficulty)
            end
        end)
    end

    if month.moneyUnit ~= nil then
        ESO_applyCurrency(month.moneyUnit)
    end

    if month.automaticMotorStart ~= nil then
        mi.automaticMotorStartEnabled = month.automaticMotorStart
    end

    if month.fruitDestruction ~= nil then
        mi.fruitDestruction = month.fruitDestruction
    end

    if month.timeScale ~= nil then
        mi.timeScale = month.timeScale
        pcall(function()
            if g_currentMission.environment ~= nil
            and g_currentMission.environment.setTimeScale ~= nil then
                g_currentMission.environment:setTimeScale(month.timeScale)
            end
        end)
    end

    if SavegameSettingsEvent ~= nil and SavegameSettingsEvent.sendEvent ~= nil then
        pcall(SavegameSettingsEvent.sendEvent, mi)
    end
end

local function ESO_applyMonthToEnvironment(month)
    if month == nil then return end
    local env = g_currentMission and g_currentMission.environment
    if env == nil then return end

    local dpp = month.daysPerPeriod or env.daysPerPeriod

    ESO_applyDaysPerPeriod(dpp)

    local dayTimeMs = math.floor((month.startHour or 6) * 1000 * 60 * 60)

    pcall(function()
        env:setEnvironmentTime(
            env.currentMonotonicDay,
            month.dayOfYear,
            dayTimeMs,
            dpp,
            true)
    end)

    ESO_applyGameRules(month)
end

local function ESO_broadcastPeriodLength()
    local mi  = g_currentMission and g_currentMission.missionInfo
    local env = g_currentMission and g_currentMission.environment
    if mi == nil or env == nil then return end

    local dpp = env.daysPerPeriod or (mi.plannedDaysPerPeriod or 3)

    pcall(function()
        if g_messageCenter ~= nil and MessageType.PERIOD_LENGTH_CHANGED ~= nil then
            g_messageCenter:publish(MessageType.PERIOD_LENGTH_CHANGED, dpp)
        end
    end)
end

local ESO_SPRING_GROWTH = { 0,    0.15, 0.35, 0.55, 0.78, 1.0,  0,    0,    0,    0,    0,    0    }
local ESO_WINTER_GROWTH = { 0.45, 0.60, 0.75, 0.92, 1.0,  0,    0.05, 0.20, 0.35, 0.45, 0.50, 0.50 }

local function ESO_isSpringReadyCrop(name)
    if name == nil then return false end
    local l = string.lower(name)
    return l:find("grass")         ~= nil
        or l:find("meadow")        ~= nil
        or l:find("oilseedradish") ~= nil
end

local function ESO_isWinterCrop(name)
    if name == nil then return false end
    local l = string.lower(name)
    return l:find("canola")  ~= nil
        or l:find("rape")    ~= nil
        or l:find("winter")  ~= nil
        or l:find("oilseed") ~= nil
end

local function ESO_getNumGrowthStatesRobust(fd)
    if fd == nil then return 0 end
    local candidates = {
        fd.numGrowthStates,
        fd.maxGrowthState,
        fd.maxHarvestingGrowthState,
        fd.numStates,
        fd.growthStateCount,
        fd.numGrowthStateMax,
        fd.maxState,
    }
    for _, v in ipairs(candidates) do
        if type(v) == "number" and v > 0 then
            return math.floor(v)
        end
    end
    for k, v in pairs(fd) do
        if type(v) == "number" and v > 0 then
            local kl = string.lower(tostring(k))
            if kl:find("growth") ~= nil or kl:find("state") ~= nil then
                return math.floor(v)
            end
        end
    end
    return 0
end

local function ESO_getTargetGrowthState(fruitDesc, period)
    local numStates = ESO_getNumGrowthStatesRobust(fruitDesc)
    if numStates <= 0 then return 0 end

    local isWinter  = ESO_isWinterCrop(fruitDesc.name)
    local fractions = isWinter and ESO_WINTER_GROWTH or ESO_SPRING_GROWTH
    local fraction  = fractions[period] or 0

    if fraction <= 0 then return 0 end

    local state = math.max(1, math.min(numStates, math.ceil(fraction * numStates)))

    if period <= 3 and not ESO_isSpringReadyCrop(fruitDesc.name) then
        state = math.min(state, math.max(1, numStates - 2))
    end

    return state
end

local function ESO_canApplyFields()
    if g_fieldManager  == nil or g_fieldManager.getFields   == nil then return false end
    if FieldUpdateTask == nil or FieldUpdateTask.new        == nil then return false end
    if FieldGroundType == nil or FieldGroundType.CULTIVATED == nil then return false end
    if FruitType       == nil or FruitType.UNKNOWN          == nil then return false end
    if g_fruitTypeManager == nil                                   then return false end
    return true
end

local function ESO_addTaskImmediateSafe(task)
    local ok = pcall(g_fieldManager.addFieldUpdateTask, g_fieldManager, task, true)
    if ok then return true end
    return pcall(g_fieldManager.addFieldUpdateTask, g_fieldManager, task) == true
end

local function ESO_forceProcessTasks()
    local fgs
    if g_fieldGroundSystem ~= nil then
        fgs = g_fieldGroundSystem
    elseif g_currentMission ~= nil then
        fgs = g_currentMission.fieldGroundSystem
           or g_currentMission.groundSystem
           or g_currentMission.fieldSystem
    end
    if fgs ~= nil then
        if fgs.forceUpdate ~= nil then pcall(fgs.forceUpdate, fgs); return end
        if fgs.update      ~= nil then pcall(fgs.update, fgs, 0);   return end
    end
    if g_fieldManager ~= nil and g_fieldManager.update ~= nil then
        pcall(g_fieldManager.update, g_fieldManager, 0)
    end
end

local function ESO_applySeasonalFieldState(period)
    if not ESO_canApplyFields() then return false end

    local fruitTypes = nil
    pcall(function()
        if g_fruitTypeManager.getFruitTypes ~= nil then
            fruitTypes = g_fruitTypeManager:getFruitTypes()
        else
            fruitTypes = g_fruitTypeManager.fruitTypes
        end
    end)

    if fruitTypes == nil then return false end

    local springCrops      = {}
    local winterCrops      = {}
    local springReadyCrops = {}

    for _, fd in pairs(fruitTypes) do
        if fd ~= nil
        and type(fd) == "table"
        and fd.index ~= nil
        and fd.index ~= FruitType.UNKNOWN
        and ESO_getNumGrowthStatesRobust(fd) > 0 then
            local fdNameLower = string.lower(fd.name or "")
            local skipFruit = fdNameLower:find("grape")  ~= nil
                           or fdNameLower:find("poplar") ~= nil
            if not skipFruit then
                if ESO_isSpringReadyCrop(fd.name) then
                    table.insert(springReadyCrops, fd)
                elseif ESO_isWinterCrop(fd.name) then
                    table.insert(winterCrops, fd)
                else
                    local skip = fdNameLower:find("chaff") ~= nil
                              or fdNameLower:find("straw") ~= nil
                    if not skip then
                        table.insert(springCrops, fd)
                    end
                end
            end
        end
    end

    if #springCrops == 0 and #winterCrops == 0 then return false end

    local fields     = g_fieldManager:getFields() or {}
    local tasksAdded = 0

    for i, field in ipairs(fields) do
        if field ~= nil then
            local fruitDesc

            if #springReadyCrops > 0 and (i % 8) == 0 then
                fruitDesc = springReadyCrops[((i - 1) % #springReadyCrops) + 1]
            elseif #winterCrops > 0 and (i % 3) == 0 then
                fruitDesc = winterCrops[((i - 1) % #winterCrops) + 1]
            else
                fruitDesc = springCrops[((i - 1) % #springCrops) + 1]
            end

            local growthState = ESO_getTargetGrowthState(fruitDesc, period)

            local task = FieldUpdateTask.new()
            task:setField(field)
            task:setGroundType(FieldGroundType.CULTIVATED)

            if growthState > 0 then
                task:setFruit(fruitDesc.index, growthState)
            else
                task:setFruit(FruitType.UNKNOWN, 0)
            end

            if task.clearHeight ~= nil then task:clearHeight() end

            if ESO_addTaskImmediateSafe(task) then
                tasksAdded = tasksAdded + 1
            end
        end
    end

    ESO_forceProcessTasks()

    return tasksAdded > 0
end

local eso_guiRetryTimer      = 0
local eso_guiAttempts        = 0
local ESO_GUI_RETRY_INTERVAL = 500
local ESO_GUI_MAX_ATTEMPTS   = 20

local function ESO_tryLoadGui(self)
    if self.guiLoaded then return true end

    eso_guiRetryTimer = eso_guiRetryTimer + self._lastDt
    if eso_guiRetryTimer < ESO_GUI_RETRY_INTERVAL and eso_guiAttempts > 0 then
        return false
    end
    eso_guiRetryTimer = 0
    eso_guiAttempts   = eso_guiAttempts + 1

    if eso_guiAttempts > ESO_GUI_MAX_ATTEMPTS then
        self.guiLoaded = true
        return true
    end

    if g_gui == nil then return false end

    if g_gui.guis == nil or g_gui.guis["ESOSelectorScreen"] == nil then
        local ok = pcall(function()
            if ESOSelectorScreen ~= nil then
                g_gui:loadProfiles(ESO_MOD_DIR .. "gui/guiProfiles.xml")
                g_gui:loadGui(
                    ESO_MOD_DIR .. "gui/ESOSelectorScreen.xml",
                    "ESOSelectorScreen",
                    ESOSelectorScreen.new(nil, nil)
                )
            end
        end)
        if not ok then return false end
    end

    self.guiLoaded = true
    return true
end

local function ESO_showMonthSelector(self)
    if g_gui == nil then return false end
    if g_gui.guis == nil or g_gui.guis["ESOSelectorScreen"] == nil then return false end

    local ok = pcall(function() g_gui:showDialog("ESOSelectorScreen") end)
    if ok then self.selectorShown = true end
    return ok
end

function enhancedStartingOptions:onMonthSelected(month)
    self.chosenMonth = month
    self.monthChosen = true
    ESO_applyGameRules(self.chosenMonth)
    ESO_applyMonthToEnvironment(self.chosenMonth)

    local profilePath = ESO_getModSettingsPath()
    ESO_writeProfileXML(profilePath, month, false)

    local savePath = ESO_getSaveFlagPath()
    if savePath ~= nil then
        ESO_writeProfileXML(savePath, month, false)
    end
end

local function ESO_tryNotifyFallback(msg)
    if g_currentMission ~= nil then
        if g_currentMission.addIngameNotification ~= nil and FSBaseMission ~= nil then
            pcall(g_currentMission.addIngameNotification,
                  g_currentMission, FSBaseMission.INGAME_NOTIFICATION_INFO, msg)
            return true
        end
        if g_currentMission.hud ~= nil
        and g_currentMission.hud.showIngameNotification ~= nil then
            pcall(g_currentMission.hud.showIngameNotification,
                  g_currentMission.hud, msg)
            return true
        end
    end
    return false
end

local function ESO_tryShowNotification(self, dt)
    if self.shownOnce then
        self.notifyText = nil; self.notifyShown = true; return
    end
    if self.notifyShown or self.notifyText == nil then return end

    self.notifyRetryMs = self.notifyRetryMs + (dt or 0)

    if self.notifyRetryMs > NOTIFY_RETRY_MAX_MS then
        ESO_tryNotifyFallback(self.notifyText)
        self.notifyShown = true; self.notifyText = nil; self.shownOnce = true
        return
    end

    if g_gui ~= nil
    and g_gui.getIsGuiVisible ~= nil
    and g_gui:getIsGuiVisible() then
        return
    end

    local ok = pcall(function()
        if InfoDialog ~= nil and InfoDialog.show ~= nil and DialogElement ~= nil then
            InfoDialog.show(self.notifyText, nil, nil, DialogElement.TYPE_INFO)
        end
    end)

    if ok then
        self.notifyShown = true; self.notifyText = nil; self.shownOnce = true
    else
        if (self.notifyRetryMs % 5000) < 30 then
            ESO_tryNotifyFallback(self.notifyText)
        end
    end
end

local function ESO_queueNotify(self)
    if self.shownOnce then return end
    local monthName = (self.chosenMonth and self.chosenMonth.name) or "March"
    local template  = ESO_getText(
        "eso_info_spring_reset",
        "Game starts in %s. Fields have been set to match the season."
    )
    self.notifyText    = string.format(template, monthName)
    self.notifyShown   = false
    self.notifyRetryMs = 0
end

function enhancedStartingOptions:saveUserProfile(settings)
    local profilePath = ESO_getModSettingsPath()
    local ok = ESO_writeProfileXML(profilePath, settings, false)
    if ok then self.loadedDefaults = settings end
    return ok
end

function enhancedStartingOptions:loadMap(mapName)
    self.elapsedMs               = 0
    self.guiLoaded               = false
    self.selectorShown           = false
    self.monthChosen             = false
    self.chosenMonth             = nil
    self.notifyText              = nil
    self.notifyShown             = false
    self.notifyRetryMs           = 0
    self.shownOnce               = false
    self.alreadyRan              = false
    self.flagWritePending        = false
    self.fieldsApplied           = false
    self.pendingPeriodBroadcast  = false
    self._lastDt                 = 0
    self.loadedDefaults          = nil
    eso_guiRetryTimer             = 0
    eso_guiAttempts               = 0

    self.loadedDefaults = ESO_getMergedDefaults()
end

function enhancedStartingOptions:update(dt)
    self._lastDt = dt or 0

    ESO_tryShowNotification(self, dt)

    if not ESO_isServerSP()  then return end
    if not ESO_isNewCareer() then return end
    if self.alreadyRan       then return end

    self.elapsedMs = self.elapsedMs + self._lastDt

    if not self.guiLoaded then
        ESO_tryLoadGui(self)
        return
    end

    if not self.selectorShown then
        if self.elapsedMs >= SELECTOR_SHOW_MS then
            if g_gui ~= nil and g_gui.getIsGuiVisible ~= nil and g_gui:getIsGuiVisible() then
                return
            end
            if not ESO_showMonthSelector(self) then return end
        else
            return
        end
    end

    if self.selectorShown and not self.monthChosen then
        if self.elapsedMs >= self.selectorTimeoutMs then
            self.chosenMonth = MARCH
            self.monthChosen = true
            ESO_applyMonthToEnvironment(MARCH)
        else
            return
        end
    end

    if not self.monthChosen then return end

    if not self.fieldsApplied and self.elapsedMs >= FIELDS_APPLY_MS then
        self.fieldsApplied = true
        local period = (self.chosenMonth and self.chosenMonth.period) or 1
        local ok, err = pcall(ESO_applySeasonalFieldState, period)
        if ok and err then
            ESO_queueNotify(self)
            self.flagWritePending = true
        end
    end

    if self.flagWritePending then
        if ESO_writeFlag() then
            self.flagWritePending = false
            self.alreadyRan       = true

            if self.pendingPeriodBroadcast then
                self.pendingPeriodBroadcast = false
                ESO_broadcastPeriodLength()
            end
        end
    end
end

function enhancedStartingOptions:deleteMap() end
function enhancedStartingOptions:draw() end

addModEventListener(enhancedStartingOptions)