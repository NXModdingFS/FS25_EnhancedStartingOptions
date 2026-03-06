ESOSelectorScreen = {}
local ESOSelectorScreen_mt = Class(ESOSelectorScreen, MessageDialog)

local DAYS_PER_MONTH = 30

local MONTH_KEYS = {
    "eso_month_march",
    "eso_month_april",
    "eso_month_may",
    "eso_month_june",
    "eso_month_july",
    "eso_month_august",
    "eso_month_september",
    "eso_month_october",
    "eso_month_november",
    "eso_month_december",
    "eso_month_january",
    "eso_month_february",
}

local MONTH_FALLBACKS = {
    "March","April","May","June","July","August",
    "September","October","November","December","January","February",
}

local DAYS_PER_PERIOD_OPTIONS = { 1, 3, 6, 9, 12, 15, 28, 30 }
local DAYS_PER_PERIOD_DEFAULT_IDX = 2

local HOUR_DEFAULT = 6

local TOGGLE_ON  = 1
local TOGGLE_OFF = 2

local SOURCE_OFF = 1
local SOURCE_BUY = 2

local TIME_SCALE_OPTIONS     = { 1, 2, 5, 10, 15, 20, 30, 60, 120 }
local TIME_SCALE_DEFAULT_IDX = 3

local ECONOMIC_DIFFICULTY_OPTIONS     = { 1, 2, 3 }
local ECONOMIC_DIFFICULTY_DEFAULT_IDX = 1

local CURRENCY_OPTIONS = {
    { value = 0,  label = "$ USD"  },
    { value = 1,  label = "€ EUR"  },
    { value = 3,  label = "£ GBP"  },
}
local CURRENCY_DEFAULT_IDX = 1

function ESOSelectorScreen.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or ESOSelectorScreen_mt)
    self.returnScreenClass = nil
    self.monthData         = {}
    return self
end

function ESOSelectorScreen:onGuiSetupFinished()
    ESOSelectorScreen:superClass().onGuiSetupFinished(self)
    self.optionMonth              = self:getDescendantById("optionMonth")
    self.optionDaysPerMonth       = self:getDescendantById("optionDaysPerMonth")
    self.optionStartDay           = self:getDescendantById("optionStartDay")
    self.optionStartHour          = self:getDescendantById("optionStartHour")
    self.optionPlowing            = self:getDescendantById("optionPlowing")
    self.optionWeeds              = self:getDescendantById("optionWeeds")
    self.optionLime               = self:getDescendantById("optionLime")
    self.optionHelperFuel         = self:getDescendantById("optionHelperFuel")
    self.optionHelperSeeds        = self:getDescendantById("optionHelperSeeds")
    self.optionHelperFertilizer   = self:getDescendantById("optionHelperFertilizer")
    self.optionHelperSlurry       = self:getDescendantById("optionHelperSlurry")
    self.optionHelperManure       = self:getDescendantById("optionHelperManure")
    self.optionEconomicDifficulty = self:getDescendantById("optionEconomicDifficulty")
    self.optionCurrency           = self:getDescendantById("optionCurrency")
    self.optionAutoMotor          = self:getDescendantById("optionAutoMotor")
    self.optionFruitDestruction   = self:getDescendantById("optionFruitDestruction")
    self.optionTimeScale          = self:getDescendantById("optionTimeScale")
    self.saveDefaultsButton       = self:getDescendantById("saveDefaultsButton")
end

local function buildMonthData()
    local months = {}
    for i = 1, 12 do
        local key  = MONTH_KEYS[i]
        local name = g_i18n and g_i18n:getText(key) or nil
        if name == nil or name == "" or name == key then
            name = MONTH_FALLBACKS[i]
        end
        table.insert(months, {
            name      = name,
            period    = i,
            dayOfYear = (i - 1) * DAYS_PER_MONTH + 1,
        })
    end
    return months
end

local function buildDayTexts(daysPerPeriod)
    local dayLabel = (g_i18n and g_i18n:getText("ui_day")) or "Day"
    local texts    = {}
    for i = 1, daysPerPeriod do
        table.insert(texts, string.format("%s %d", dayLabel, i))
    end
    return texts
end

local function buildHourTexts()
    local texts = {}
    for h = 0, 23 do
        table.insert(texts, string.format("%02d:00", h))
    end
    return texts
end

local function buildToggleTexts()
    local onText  = (g_i18n and g_i18n:getText("eso_on"))  or "On"
    local offText = (g_i18n and g_i18n:getText("eso_off")) or "Off"
    if onText  == "eso_on"  then onText  = "On"  end
    if offText == "eso_off" then offText = "Off" end
    return { onText, offText }
end

local function buildSourceTexts()
    local offText = (g_i18n and g_i18n:getText("eso_off")) or "Off"
    local buyText = (g_i18n and g_i18n:getText("eso_buy")) or "Buy"
    if offText == "eso_off" then offText = "Off" end
    if buyText == "eso_buy" then buyText = "Buy" end
    return { offText, buyText }
end

local function buildDifficultyTexts()
    local easy   = (g_i18n and g_i18n:getText("eso_difficulty_easy"))   or "Easy"
    local normal = (g_i18n and g_i18n:getText("eso_difficulty_normal")) or "Normal"
    local hard   = (g_i18n and g_i18n:getText("eso_difficulty_hard"))   or "Hard"
    if easy   == "eso_difficulty_easy"   then easy   = "Easy"   end
    if normal == "eso_difficulty_normal" then normal = "Normal" end
    if hard   == "eso_difficulty_hard"   then hard   = "Hard"   end
    return { easy, normal, hard }
end

local function buildCurrencyTexts()
    local texts = {}
    for _, c in ipairs(CURRENCY_OPTIONS) do
        table.insert(texts, c.label)
    end
    return texts
end

function ESOSelectorScreen:getSelectedDaysPerPeriod()
    if self.optionDaysPerMonth == nil then
        return DAYS_PER_PERIOD_OPTIONS[DAYS_PER_PERIOD_DEFAULT_IDX]
    end
    return DAYS_PER_PERIOD_OPTIONS[self.optionDaysPerMonth:getState()]
        or DAYS_PER_PERIOD_OPTIONS[DAYS_PER_PERIOD_DEFAULT_IDX]
end

function ESOSelectorScreen:onOpen()
    ESOSelectorScreen:superClass().onOpen(self)

    if self.registerInputActionEvent ~= nil then
        self:registerInputActionEvent(InputAction.MENU_BACK, self, self.onClickBack,
                                      false, true, false, true)
    end

    if self.saveDefaultsButton ~= nil then
        self.saveDefaultsButton:setInputAction(InputAction.MENU_EXTRA_1)
    end

    local d = (enhancedStartingOptions ~= nil) and enhancedStartingOptions.loadedDefaults or nil

    local function dfltBool(profileKey, miField, hardDefault)
        if d ~= nil and d[profileKey] ~= nil then return d[profileKey] end
        local mi = g_currentMission and g_currentMission.missionInfo
        if mi ~= nil and mi[miField] ~= nil then return mi[miField] end
        return hardDefault
    end
    local function dfltInt(profileKey, miField, hardDefault)
        if d ~= nil and d[profileKey] ~= nil then return d[profileKey] end
        local mi = g_currentMission and g_currentMission.missionInfo
        if mi ~= nil and mi[miField] ~= nil then return mi[miField] end
        return hardDefault
    end

    self.monthData = buildMonthData()

    if self.optionMonth ~= nil then
        local monthTexts = {}
        for _, m in ipairs(self.monthData) do
            table.insert(monthTexts, m.name)
        end
        self.optionMonth:setTexts(monthTexts)
        local defaultPeriod = (d ~= nil and d.period) or 1
        local monthIdx = math.max(1, math.min(defaultPeriod, #self.monthData))
        self.optionMonth:setState(monthIdx)
    end

    if self.optionDaysPerMonth ~= nil then
        local dpmTexts = {}
        for _, v in ipairs(DAYS_PER_PERIOD_OPTIONS) do
            table.insert(dpmTexts, tostring(v))
        end
        self.optionDaysPerMonth:setTexts(dpmTexts)

        local defaultDPP = (d ~= nil and d.daysPerPeriod)
                        or (g_currentMission and g_currentMission.environment
                            and g_currentMission.environment.daysPerPeriod)
                        or DAYS_PER_PERIOD_OPTIONS[DAYS_PER_PERIOD_DEFAULT_IDX]
        local selectedIdx = DAYS_PER_PERIOD_DEFAULT_IDX
        for idx, v in ipairs(DAYS_PER_PERIOD_OPTIONS) do
            if v == defaultDPP then selectedIdx = idx; break end
        end
        self.optionDaysPerMonth:setState(selectedIdx)
    end

    local defaultDayInPeriod = (d ~= nil and d.dayInPeriod) or 1
    self:refreshStartDayOptions(defaultDayInPeriod)

    if self.optionStartHour ~= nil then
        self.optionStartHour:setTexts(buildHourTexts())
        local defaultHour = (d ~= nil and d.startHour) or HOUR_DEFAULT
        self.optionStartHour:setState(math.max(1, math.min(defaultHour + 1, 24)))
    end

    local toggleTexts = buildToggleTexts()

    if self.optionPlowing ~= nil then
        self.optionPlowing:setTexts(toggleTexts)
        local enabled = dfltBool("plowingEnabled", "plowingRequiredEnabled", true)
        self.optionPlowing:setState(enabled and TOGGLE_ON or TOGGLE_OFF)
    end

    if self.optionWeeds ~= nil then
        self.optionWeeds:setTexts(toggleTexts)
        local enabled = dfltBool("weedsEnabled", "weedsEnabled", true)
        self.optionWeeds:setState(enabled and TOGGLE_ON or TOGGLE_OFF)
    end

    if self.optionLime ~= nil then
        self.optionLime:setTexts(toggleTexts)
        local enabled = dfltBool("limeRequired", "limeRequired", true)
        self.optionLime:setState(enabled and TOGGLE_ON or TOGGLE_OFF)
    end

    local sourceTexts = buildSourceTexts()

    if self.optionHelperFuel ~= nil then
        self.optionHelperFuel:setTexts(toggleTexts)
        local enabled = dfltBool("helperBuyFuel", "helperBuyFuel", true)
        self.optionHelperFuel:setState(enabled and TOGGLE_ON or TOGGLE_OFF)
    end

    if self.optionHelperSeeds ~= nil then
        self.optionHelperSeeds:setTexts(toggleTexts)
        local enabled = dfltBool("helperBuySeeds", "helperBuySeeds", true)
        self.optionHelperSeeds:setState(enabled and TOGGLE_ON or TOGGLE_OFF)
    end

    if self.optionHelperFertilizer ~= nil then
        self.optionHelperFertilizer:setTexts(toggleTexts)
        local enabled = dfltBool("helperBuyFertilizer", "helperBuyFertilizer", true)
        self.optionHelperFertilizer:setState(enabled and TOGGLE_ON or TOGGLE_OFF)
    end

    if self.optionHelperSlurry ~= nil then
        self.optionHelperSlurry:setTexts(sourceTexts)
        local source = dfltInt("helperSlurrySource", "helperSlurrySource", SOURCE_BUY)
        self.optionHelperSlurry:setState(source == SOURCE_BUY and 2 or 1)
    end

    if self.optionHelperManure ~= nil then
        self.optionHelperManure:setTexts(sourceTexts)
        local source = dfltInt("helperManureSource", "helperManureSource", SOURCE_BUY)
        self.optionHelperManure:setState(source == SOURCE_BUY and 2 or 1)
    end

    if self.optionEconomicDifficulty ~= nil then
        self.optionEconomicDifficulty:setTexts(buildDifficultyTexts())
        local currentDiff = dfltInt("economicDifficulty", "economicDifficulty",
                                    ECONOMIC_DIFFICULTY_OPTIONS[ECONOMIC_DIFFICULTY_DEFAULT_IDX])
        local selectedIdx = ECONOMIC_DIFFICULTY_DEFAULT_IDX
        for idx, v in ipairs(ECONOMIC_DIFFICULTY_OPTIONS) do
            if v == currentDiff then selectedIdx = idx; break end
        end
        self.optionEconomicDifficulty:setState(selectedIdx)
    end

    if self.optionCurrency ~= nil then
        self.optionCurrency:setTexts(buildCurrencyTexts())
        local defaultUnit
        if d ~= nil and d.moneyUnit ~= nil then
            defaultUnit = d.moneyUnit
        else
            defaultUnit = (g_gameSettings ~= nil and g_gameSettings.moneyUnit) or 0
        end
        local selectedIdx = 1
        for idx, c in ipairs(CURRENCY_OPTIONS) do
            if c.value == defaultUnit then selectedIdx = idx; break end
        end
        self.optionCurrency:setState(selectedIdx)
    end

    if self.optionAutoMotor ~= nil then
        self.optionAutoMotor:setTexts(toggleTexts)
        local enabled = dfltBool("automaticMotorStart", "automaticMotorStartEnabled", true)
        self.optionAutoMotor:setState(enabled and TOGGLE_ON or TOGGLE_OFF)
    end

    if self.optionFruitDestruction ~= nil then
        self.optionFruitDestruction:setTexts(toggleTexts)
        local enabled = dfltBool("fruitDestruction", "fruitDestruction", true)
        self.optionFruitDestruction:setState(enabled and TOGGLE_ON or TOGGLE_OFF)
    end

    if self.optionTimeScale ~= nil then
        local tsTexts = {}
        for _, v in ipairs(TIME_SCALE_OPTIONS) do
            table.insert(tsTexts, v .. "x")
        end
        self.optionTimeScale:setTexts(tsTexts)
        local currentTS   = dfltInt("timeScale", "timeScale", 5)
        local selectedIdx = TIME_SCALE_DEFAULT_IDX
        for idx, v in ipairs(TIME_SCALE_OPTIONS) do
            if v == currentTS then selectedIdx = idx; break end
        end
        self.optionTimeScale:setState(selectedIdx)
    end
end

function ESOSelectorScreen:refreshStartDayOptions(preferredDay)
    if self.optionStartDay == nil then return end

    local dpp     = self:getSelectedDaysPerPeriod()
    local prevDay = preferredDay or self.optionStartDay:getState()

    self.optionStartDay:setTexts(buildDayTexts(dpp))

    if dpp > 1 then
        self.optionStartDay:setDisabled(false)
        self.optionStartDay:setState(math.max(1, math.min(prevDay, dpp)))
    else
        self.optionStartDay:setState(1)
        self.optionStartDay:setDisabled(true)
    end
end

function ESOSelectorScreen:onClickDaysPerMonth(state, element)
    self:refreshStartDayOptions()
end

function ESOSelectorScreen:onClickBack()
    self:closeAndCleanup()
end

function ESOSelectorScreen:inputEvent(action, value, eventUsed)
    if eventUsed or value == 0 then
        return ESOSelectorScreen:superClass().inputEvent(self, action, value, eventUsed)
    end

    if action == InputAction.MENU_EXTRA_1 then
        self:onClickSaveDefaults()
        return true
    end

    return ESOSelectorScreen:superClass().inputEvent(self, action, value, eventUsed)
end

function ESOSelectorScreen:onClickConfirm()
    if self.optionMonth == nil then
        self:closeAndCleanup()
        return
    end

    local monthIdx = self.optionMonth:getState()
    local month    = self.monthData[monthIdx]

    if month == nil then
        self:closeAndCleanup()
        return
    end

    local daysPerPeriod = self:getSelectedDaysPerPeriod()
    local dayInPeriod   = (self.optionStartDay  ~= nil) and self.optionStartDay:getState()  or 1
    local startHour     = (self.optionStartHour ~= nil) and (self.optionStartHour:getState() - 1) or HOUR_DEFAULT

    daysPerPeriod = math.max(1, daysPerPeriod)
    dayInPeriod   = math.max(1, math.min(dayInPeriod, daysPerPeriod))
    startHour     = math.max(0, math.min(startHour, 23))

    local plowingEnabled = (self.optionPlowing == nil) or (self.optionPlowing:getState() == TOGGLE_ON)
    local weedsEnabled   = (self.optionWeeds   == nil) or (self.optionWeeds:getState()   == TOGGLE_ON)
    local limeRequired   = (self.optionLime    == nil) or (self.optionLime:getState()    == TOGGLE_ON)

    local helperBuyFuel       = (self.optionHelperFuel       == nil) or (self.optionHelperFuel:getState()       == TOGGLE_ON)
    local helperBuySeeds      = (self.optionHelperSeeds      == nil) or (self.optionHelperSeeds:getState()      == TOGGLE_ON)
    local helperBuyFertilizer = (self.optionHelperFertilizer == nil) or (self.optionHelperFertilizer:getState() == TOGGLE_ON)

    local helperSlurrySource = SOURCE_BUY
    if self.optionHelperSlurry ~= nil then
        helperSlurrySource = (self.optionHelperSlurry:getState() == 2) and SOURCE_BUY or SOURCE_OFF
    end

    local helperManureSource = SOURCE_BUY
    if self.optionHelperManure ~= nil then
        helperManureSource = (self.optionHelperManure:getState() == 2) and SOURCE_BUY or SOURCE_OFF
    end

    local economicDifficulty = ECONOMIC_DIFFICULTY_OPTIONS[ECONOMIC_DIFFICULTY_DEFAULT_IDX]
    if self.optionEconomicDifficulty ~= nil then
        economicDifficulty = ECONOMIC_DIFFICULTY_OPTIONS[self.optionEconomicDifficulty:getState()]
                             or economicDifficulty
    end

    local moneyUnit = CURRENCY_OPTIONS[1].value
    if self.optionCurrency ~= nil then
        local entry = CURRENCY_OPTIONS[self.optionCurrency:getState()]
        if entry ~= nil then moneyUnit = entry.value end
    end

    local automaticMotorStart = (self.optionAutoMotor        == nil) or (self.optionAutoMotor:getState()        == TOGGLE_ON)
    local fruitDestruction    = (self.optionFruitDestruction == nil) or (self.optionFruitDestruction:getState() == TOGGLE_ON)

    local timeScale = TIME_SCALE_OPTIONS[TIME_SCALE_DEFAULT_IDX]
    if self.optionTimeScale ~= nil then
        timeScale = TIME_SCALE_OPTIONS[self.optionTimeScale:getState()] or timeScale
    end

    local result = {
        name                = month.name,
        period              = month.period,
        dayOfYear           = (month.period - 1) * daysPerPeriod + dayInPeriod,
        dayInPeriod         = dayInPeriod,
        daysPerPeriod       = daysPerPeriod,
        startHour           = startHour,
        plowingEnabled      = plowingEnabled,
        weedsEnabled        = weedsEnabled,
        limeRequired        = limeRequired,
        helperBuyFuel       = helperBuyFuel,
        helperBuySeeds      = helperBuySeeds,
        helperBuyFertilizer = helperBuyFertilizer,
        helperSlurrySource  = helperSlurrySource,
        helperManureSource  = helperManureSource,
        economicDifficulty  = economicDifficulty,
        moneyUnit           = moneyUnit,
        automaticMotorStart = automaticMotorStart,
        fruitDestruction    = fruitDestruction,
        timeScale           = timeScale,
    }

    if enhancedStartingOptions ~= nil and enhancedStartingOptions.onMonthSelected ~= nil then
        enhancedStartingOptions:onMonthSelected(result)
    end

    self:closeAndCleanup()
end

function ESOSelectorScreen:onClickSaveDefaults()
    local monthIdx      = self.optionMonth       and self.optionMonth:getState()       or 1
    local daysPerPeriod = self:getSelectedDaysPerPeriod()
    local dayInPeriod   = self.optionStartDay    and self.optionStartDay:getState()    or 1
    local startHour     = self.optionStartHour   and (self.optionStartHour:getState() - 1) or HOUR_DEFAULT

    daysPerPeriod = math.max(1, daysPerPeriod)
    dayInPeriod   = math.max(1, math.min(dayInPeriod, daysPerPeriod))
    startHour     = math.max(0, math.min(startHour, 23))

    local plowingEnabled      = (self.optionPlowing          == nil) or (self.optionPlowing:getState()          == TOGGLE_ON)
    local weedsEnabled        = (self.optionWeeds            == nil) or (self.optionWeeds:getState()            == TOGGLE_ON)
    local limeRequired        = (self.optionLime             == nil) or (self.optionLime:getState()             == TOGGLE_ON)
    local helperBuyFuel       = (self.optionHelperFuel       == nil) or (self.optionHelperFuel:getState()       == TOGGLE_ON)
    local helperBuySeeds      = (self.optionHelperSeeds      == nil) or (self.optionHelperSeeds:getState()      == TOGGLE_ON)
    local helperBuyFertilizer = (self.optionHelperFertilizer == nil) or (self.optionHelperFertilizer:getState() == TOGGLE_ON)

    local helperSlurrySource = SOURCE_BUY
    if self.optionHelperSlurry ~= nil then
        helperSlurrySource = (self.optionHelperSlurry:getState() == 2) and SOURCE_BUY or SOURCE_OFF
    end
    local helperManureSource = SOURCE_BUY
    if self.optionHelperManure ~= nil then
        helperManureSource = (self.optionHelperManure:getState() == 2) and SOURCE_BUY or SOURCE_OFF
    end

    local economicDifficulty = ECONOMIC_DIFFICULTY_OPTIONS[ECONOMIC_DIFFICULTY_DEFAULT_IDX]
    if self.optionEconomicDifficulty ~= nil then
        economicDifficulty = ECONOMIC_DIFFICULTY_OPTIONS[self.optionEconomicDifficulty:getState()]
                             or economicDifficulty
    end

    local moneyUnit = CURRENCY_OPTIONS[1].value
    if self.optionCurrency ~= nil then
        local entry = CURRENCY_OPTIONS[self.optionCurrency:getState()]
        if entry ~= nil then moneyUnit = entry.value end
    end

    local automaticMotorStart = (self.optionAutoMotor        == nil) or (self.optionAutoMotor:getState()        == TOGGLE_ON)
    local fruitDestruction    = (self.optionFruitDestruction == nil) or (self.optionFruitDestruction:getState() == TOGGLE_ON)

    local timeScale = TIME_SCALE_OPTIONS[TIME_SCALE_DEFAULT_IDX]
    if self.optionTimeScale ~= nil then
        timeScale = TIME_SCALE_OPTIONS[self.optionTimeScale:getState()] or timeScale
    end

    self._pendingSaveSettings = {
        period              = monthIdx,
        dayInPeriod         = dayInPeriod,
        daysPerPeriod       = daysPerPeriod,
        startHour           = startHour,
        plowingEnabled      = plowingEnabled,
        weedsEnabled        = weedsEnabled,
        limeRequired        = limeRequired,
        helperBuyFuel       = helperBuyFuel,
        helperBuySeeds      = helperBuySeeds,
        helperBuyFertilizer = helperBuyFertilizer,
        helperSlurrySource  = helperSlurrySource,
        helperManureSource  = helperManureSource,
        economicDifficulty  = economicDifficulty,
        moneyUnit           = moneyUnit,
        automaticMotorStart = automaticMotorStart,
        fruitDestruction    = fruitDestruction,
        timeScale           = timeScale,
    }

    local confirmText = g_i18n:getText("eso_save_defaults_confirm")
    if confirmText == nil or confirmText == "eso_save_defaults_confirm" then
        confirmText = "Save current settings as your default profile?\nThis will overwrite your existing defaults."
    end

    YesNoDialog.show(self.onConfirmSaveDefaults, self, confirmText)
end

function ESOSelectorScreen:onConfirmSaveDefaults(yes)
    if not yes then
        self._pendingSaveSettings = nil
        return
    end

    local settings = self._pendingSaveSettings
    self._pendingSaveSettings = nil

    if settings == nil then return end

    if enhancedStartingOptions ~= nil and enhancedStartingOptions.saveUserProfile ~= nil then
        local ok = enhancedStartingOptions:saveUserProfile(settings)
        if ok then
            local doneText = g_i18n:getText("eso_save_defaults_done")
            if doneText == nil or doneText == "eso_save_defaults_done" then
                doneText = "Default profile saved."
            end
            InfoDialog.show(doneText)
        else
            InfoDialog.show("Failed to save default profile.")
        end
    end
end

function ESOSelectorScreen:onClickOk()
    return false
end

function ESOSelectorScreen:closeAndCleanup()
    if self.clearInputActionEvents ~= nil then self:clearInputActionEvents() end
    self:close()
end

function ESOSelectorScreen:onClose()
    ESOSelectorScreen:superClass().onClose(self)
    if self.clearInputActionEvents ~= nil then self:clearInputActionEvents() end
end