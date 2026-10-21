-- Motor Sound Configurator dialog
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- MessageDialog pattern (as used by the UsedPlus mod): loaded once with g_gui:loadGui in loadMap, opened with
-- MotorSoundConfiguratorDialog.show(vehicleData). Every change is applied immediately (live). "Apply" saves the
-- settings file, "Cancel" (also Esc) restores the settings from when the dialog was opened, after a question if
-- something changed.
-- Layout (user 2026-10-02): tabs "Sound" (engine and transmission side by side) and "Extra sounds" (one row per
-- layer group), "Hear original" toggle, live rpm / load with preview, Reset (current tab) and "Reset model"
-- (current vehicle model, internally resetAll).
-- v0.13.0.0: third tab "Presets" (one toggle button per preset, src/Presets.lua), always for this model.
-- v0.15.0.0 (UI review 2026-10-03, docs/UI_REVIEW.md): tabs "Sound" (volume, pitch, rpm character, cabin & fan) and
-- "Filter" (tone / presence in the cabin and outside), one scope row for all pages, LB / RB (Q / E) switch tabs.
-- v0.16.0.0: fifth tab "Engine swap" (one toggle button per catalog engine, src/EngineSwap.lua), always for this model.
-- v0.19.0.0: second tab "Other sounds" (cabin & fan, parts rattle, harvester work sounds, trailer / implement table).

MotorSoundConfiguratorDialog = {}
local MotorSoundConfiguratorDialog_mt = Class(MotorSoundConfiguratorDialog, MessageDialog)

MotorSoundConfiguratorDialog.NAME = "MotorSoundConfiguratorDialog"
MotorSoundConfiguratorDialog.XML_FILENAME = "gui/MotorSoundConfiguratorDialog.xml"

MotorSoundConfiguratorDialog.SCOPE_GLOBAL = 1
MotorSoundConfiguratorDialog.SCOPE_MODEL = 2

-- v0.15.0.0 (UI review 2026-10-03, variants D + C): the former "Sound" page is split into "Sound" and "Filter"
-- v0.19.0.0 (user 2026-10-19): second sound tab "Other sounds" (cabin & fan, parts rattle, harvester work sounds and
-- the trailer / implement table); "Sound" keeps engine and transmission ("Engine & gearbox")
MotorSoundConfiguratorDialog.PAGE_SOUND = 1
MotorSoundConfiguratorDialog.PAGE_OTHER = 2
MotorSoundConfiguratorDialog.PAGE_FILTER = 3
MotorSoundConfiguratorDialog.PAGE_LAYERS = 4
MotorSoundConfiguratorDialog.PAGE_PRESETS = 5
-- v0.16.0.0 (user 2026-10-11): engine swap on its own tab (src/EngineSwap.lua)
MotorSoundConfiguratorDialog.PAGE_SWAP = 6
MotorSoundConfiguratorDialog.PAGE_COUNT = 6
-- parameters shown on the "Sound" / "Other sounds" / "Filter" page
MotorSoundConfiguratorDialog.PAGE_PARAMETERS = {
    [MotorSoundConfiguratorDialog.PAGE_SOUND] = { "volume", "pitch", "rpm" },
    [MotorSoundConfiguratorDialog.PAGE_OTHER] = { "volume" },
    [MotorSoundConfiguratorDialog.PAGE_FILTER] = { "indoorDamping", "cutoffIndoor", "gainIndoor", "cutoffOutdoor", "gainOutdoor" }
}
-- categories of the vehicle itself on the "Other sounds" page (volume only there); the implement categories are in its
-- table. Everything else (engine, transmission) is on "Sound" / "Filter"
MotorSoundConfiguratorDialog.OTHER_CATEGORIES = {
    [MotorSoundConfigurator.CATEGORY_CABIN] = true,
    [MotorSoundConfigurator.CATEGORY_RATTLE] = true,
    [MotorSoundConfigurator.CATEGORY_WORK] = true,
    [MotorSoundConfigurator.CATEGORY_DISCHARGE] = true,
    [MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK] = true,
    [MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE] = true,
    [MotorSoundConfigurator.CATEGORY_IMPLEMENT_RATTLE] = true
}
-- tables of the "Other sounds" page (user 2026-10-19): "Implements" = attached models with work or drive sounds,
-- "Trailers" = attached models with only driving rattle. XML ids <rowPrefix><n>Name and <rowPrefix><n><cell>Option /
-- Value / Dash, column headers per cell. The global row ("All vehicles") of the implement block leaves out the driving
-- rattle (inGlobal false): it is one global value, shown in the trailer block
MotorSoundConfiguratorDialog.TABLE_ROWS = 5
MotorSoundConfiguratorDialog.TABLE_BLOCKS = {
    { rowPrefix = "implRow", header = "implementBlockHeader", allText = "msc_implement_all",
      cells = {
          { id = "Work", category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK, header = "implementWorkHeader" },
          { id = "Drive", category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE, header = "implementDriveHeader" },
          { id = "Rattle", category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_RATTLE, header = "implementRattleHeader", inGlobal = false } } },
    { rowPrefix = "trailerRow", header = "trailerBlockHeader", allText = "msc_trailer_all",
      cells = {
          { id = "Rattle", category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_RATTLE, header = "trailerRattleHeader" } } }
}
MotorSoundConfiguratorDialog.BLOCK_IMPLEMENTS = 1
MotorSoundConfiguratorDialog.BLOCK_TRAILERS = 2
-- value texts: own value of the model (or any value in "All vehicles") white, value taken from "All vehicles" grey
MotorSoundConfiguratorDialog.VALUE_COLOR_OWN = { 1, 1, 1, 1 }
MotorSoundConfiguratorDialog.VALUE_COLOR_INHERITED = { 0.55, 0.55, 0.55, 1 }
-- volume slider of a layer row that is switched off ("Off"): dimmed, it cannot be used (UI review #7)
MotorSoundConfiguratorDialog.DISABLED_ALPHA = 0.35

-- controller (UI review #13, variant K2, user 2026-10-03): A (MENU_ACCEPT) activates the focused element through the
-- FocusManager, so "Apply" moves to the right stick press (MENU_EXTRA_2 = BUTTON_12, profileTemplate/
-- inputBindingDefault_Gamepad.xml); keyboard and mouse keep Enter (MENU_ACCEPT). Switched with the input help mode.
MotorSoundConfiguratorDialog.APPLY_ACTION_KEYBOARD = "MENU_ACCEPT"
MotorSoundConfiguratorDialog.APPLY_ACTION_GAMEPAD = "MENU_EXTRA_2"
-- up / down order of the controls per page (controller): engine column, then transmission column; left / right on a
-- slider changes its value. Layer rows: choice, then its volume. Presets and the left column use the automatic order.
MotorSoundConfiguratorDialog.FOCUS_ORDER = {
    [MotorSoundConfiguratorDialog.PAGE_SOUND] = {
        "motor_volumeOption", "motor_pitchOption", "motor_rpmOption",
        "gearbox_volumeOption", "gearbox_pitchOption", "gearbox_rpmOption" },
    -- vehicle block row by row, then the table row by row (filled below)
    [MotorSoundConfiguratorDialog.PAGE_OTHER] = { "cabin_volumeOption", "rattle_volumeOption", "work_volumeOption", "discharge_volumeOption" },
    [MotorSoundConfiguratorDialog.PAGE_FILTER] = {
        "motor_indoorDampingOption", "motor_cutoffIndoorOption", "motor_gainIndoorOption", "motor_cutoffOutdoorOption", "motor_gainOutdoorOption",
        "gearbox_indoorDampingOption", "gearbox_cutoffIndoorOption", "gearbox_gainIndoorOption", "gearbox_cutoffOutdoorOption", "gearbox_gainOutdoorOption" },
    [MotorSoundConfiguratorDialog.PAGE_LAYERS] = {
        "layerRow1Choice", "layerRow1Volume", "layerRow2Choice", "layerRow2Volume", "layerRow3Choice", "layerRow3Volume",
        "layerRow4Choice", "layerRow4Volume", "layerRow5Choice", "layerRow5Volume", "layerRow6Choice", "layerRow6Volume",
        "layerRow7Choice", "layerRow7Volume", "layerRow8Choice", "layerRow8Volume", "layerRow9Choice", "layerRow9Volume" },
    [MotorSoundConfiguratorDialog.PAGE_PRESETS] = { "presetButton1" },
    [MotorSoundConfiguratorDialog.PAGE_SWAP] = { "swapVolumeOption", "swapButton1" }
}
for _, block in ipairs(MotorSoundConfiguratorDialog.TABLE_BLOCKS) do
    for row = 1, MotorSoundConfiguratorDialog.TABLE_ROWS do
        for _, cell in ipairs(block.cells) do
            table.insert(MotorSoundConfiguratorDialog.FOCUS_ORDER[MotorSoundConfiguratorDialog.PAGE_OTHER], block.rowPrefix .. row .. cell.id .. "Option")
        end
    end
end

-- rows of the "Extra sounds" page (layerRow1 .. layerRow8 in the XML), one per layer group (v0.18.0.0: rattle, rumble
-- and fan each in their own group, so they can play together, user 2026-10-13; turbo group removed again in v0.18.1.0)
-- v1.1.0.0: row 9 for the group "Engine (mods & DLCs)" (only shown when engines from mods / DLCs were found)
MotorSoundConfiguratorDialog.LAYER_ROWS = 9
-- buttons of the "Presets" page (presetButton1 .. presetButton12 in the XML), one per preset
MotorSoundConfiguratorDialog.PRESET_BUTTONS = 12
-- buttons of the "Engine swap" page (swapButton1 .. swapButton50 in the XML): 1 = own engine, then one per engine
MotorSoundConfiguratorDialog.SWAP_BUTTONS = 50
-- lists of the "Engine swap" page (v1.1.0.0, user 2026-10-20): base game catalog or engines from mods and DLCs; the mod
-- lists have pages of SWAP_BUTTONS - 1 engines ("Own engine" first on every page). SWAP_VIEW_MOD = tractors from mods /
-- DLCs, SWAP_VIEW_OTHER = their other vehicles (trucks, harvesters, cars, trains ..., user 2026-10-20)
MotorSoundConfiguratorDialog.SWAP_VIEW_BASE = 1
MotorSoundConfiguratorDialog.SWAP_VIEW_MOD = 2
MotorSoundConfiguratorDialog.SWAP_VIEW_OTHER = 3
-- volume of a sound chosen in a layer row before its slider was touched
MotorSoundConfiguratorDialog.LAYER_DEFAULT_VOLUME = 1.0
-- marker behind labels / tabs whose values differ from the original sound
MotorSoundConfiguratorDialog.CHANGED_MARKER = " *"
-- frames between the answer to "apply changes?" and closing the dialog (see onApplyAnswer)
MotorSoundConfiguratorDialog.CLOSE_FRAME_WAIT = 2

-- factor steps: fine around 100 %, coarse towards the ends, 0 .. 300 % (agreed with the user), 400 .. 1000 % only for
-- parameters with a higher max (cabin tone, user 2026-10-02);
-- each parameter uses the steps inside its min / max, plus its min as first step
MotorSoundConfiguratorDialog.FACTOR_STEPS = {
    0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8,
    0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4, 1.45, 1.5,
    1.75, 2.0, 2.5, 3.0,
    4.0, 5.0, 6.0, 8.0, 10.0
}
MotorSoundConfiguratorDialog.stepsByParameter = {}
-- shown as 1 - value with reversed steps (v0.20.0.0, user 2026-10-19): the stored "indoorDamping" (1.0 = original) is
-- the "Cabin openness" in the dialog (0 % = original, 100 % = like outside)
MotorSoundConfiguratorDialog.INVERTED_PARAMETERS = { indoorDamping = true }
-- cabin rows that hardly act at a high openness (value texts grey from OPENNESS_GREY_FROM, user 2026-10-19)
MotorSoundConfiguratorDialog.OPENNESS_DEPENDENT_PARAMETERS = { cutoffIndoor = true, gainIndoor = true }
MotorSoundConfiguratorDialog.OPENNESS_GREY_FROM = 0.999
MotorSoundConfiguratorDialog.layerVolumeSteps = nil

-- rpm / load preview (user 2026-10-02): the vehicle cannot be driven while the dialog is open, so the sound gets
-- these values instead (0 .. 1 of the sound range, see MotorSoundConfigurator.onMotorizedUpdate); first step = live
MotorSoundConfiguratorDialog.PREVIEW_LIVE = -1
MotorSoundConfiguratorDialog.PREVIEW_STEPS = { -1, 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0 }
-- live display: time constant of the smoothing (ms) and step of the shown values; a shown value only changes when
-- the smoothed value is more than 0.8 steps away from it (hysteresis against flickering between two numbers)
MotorSoundConfiguratorDialog.LIVE_SMOOTHING_TIME = 150
MotorSoundConfiguratorDialog.LIVE_RPM_STEP = 10
MotorSoundConfiguratorDialog.LIVE_LOAD_STEP = 0.01
MotorSoundConfiguratorDialog.LIVE_HYSTERESIS = 0.8


function MotorSoundConfiguratorDialog.new(target, customMt)
    local self = MessageDialog.new(target, customMt or MotorSoundConfiguratorDialog_mt)

    self.vehicleData = nil
    self.scopeIndex = MotorSoundConfiguratorDialog.SCOPE_GLOBAL
    self.page = MotorSoundConfiguratorDialog.PAGE_SOUND
    -- settings when the dialog was opened, restored by "Cancel"
    self.settingsCopy = nil
    self.isCancelled = false
    -- a deferred close is pending (onApplyAnswer)
    self.isClosePending = false
    -- per layer row: active catalog layer (or nil)
    self.rowActiveLayers = {}
    -- rows of the tables ("Other sounds") per block: vehicle data of the attached model per shown row, false = the
    -- global row ("All vehicles"); filled in updateTables
    self.tableRows = {}
    self.lastLiveTexts = {}
    -- live display: smoothed rpm (absolute) / load (0 .. 1) and the values shown with hysteresis, nil = start anew
    self.smoothRpm = nil
    self.smoothLoad = nil
    self.shownRpm = nil
    self.shownLoad = nil
    -- input help mode the "Apply" key was set for (GS_INPUT_HELP_MODE_*), nil = not set yet
    self.lastInputMode = nil
    -- "Engine swap" page: shown list (SWAP_VIEW_*) and page of the mod list (1 based); chosen on the first update after
    -- opening (isSwapViewChosen false), so the list of an active swap is shown
    self.swapView = MotorSoundConfiguratorDialog.SWAP_VIEW_BASE
    self.swapPageIndex = 1
    self.isSwapViewChosen = false

    return self
end


function MotorSoundConfiguratorDialog.register()
    local xmlFilename = MotorSoundConfigurator.modDirectory .. MotorSoundConfiguratorDialog.XML_FILENAME
    g_gui:loadGui(xmlFilename, MotorSoundConfiguratorDialog.NAME, MotorSoundConfiguratorDialog.new(nil, nil))

    -- loadGui only logs on failure, so check the result explicitly
    if g_gui.guis[MotorSoundConfiguratorDialog.NAME] == nil then
        MotorSoundConfigurator.logError("dialog could not be loaded from %s", xmlFilename)
        return false
    end
    return true
end


function MotorSoundConfiguratorDialog.show(vehicleData)
    local gui = g_gui.guis[MotorSoundConfiguratorDialog.NAME]
    if gui == nil or gui.target == nil then
        MotorSoundConfigurator.logError("dialog is not loaded")
        return
    end

    -- data must be set before showDialog, the open callback fills the elements
    gui.target:setVehicleData(vehicleData)
    g_gui:showDialog(MotorSoundConfiguratorDialog.NAME)
end


function MotorSoundConfiguratorDialog:setVehicleData(vehicleData)
    self.vehicleData = vehicleData
    -- taken here and not in the open callback: a dialog opened on top ("Reset model" question) must not renew it
    self.settingsCopy = MotorSoundConfigurator.copySettings()
    self.isCancelled = false
    self.isClosePending = false
    -- always opens for the model the player sits in (user 2026-10-02)
    self.scopeIndex = MotorSoundConfiguratorDialog.SCOPE_MODEL
    self.isSwapViewChosen = false
end


function MotorSoundConfiguratorDialog:onGuiSetupFinished()
    MotorSoundConfiguratorDialog:superClass().onGuiSetupFinished(self)

    self:connectHelpText(self.scopeOption, "msc_help_scope")
    self:connectHelpText(self.tabSoundButton, "msc_help_tab_sound")
    self:connectHelpText(self.tabOtherButton, "msc_help_tab_other")
    self:connectHelpText(self.tabFilterButton, "msc_help_tab_filter")
    self:connectHelpText(self.tabLayersButton, "msc_help_tab_layers")
    self:connectHelpText(self.tabPresetsButton, "msc_help_tab_presets")
    self:connectHelpText(self.tabSwapButton, "msc_help_tab_swap")
    self:connectHelpText(self.originalButton, "msc_help_original")

    self:connectHelpText(self.previewLiveButton, "msc_help_previewReset")
    for _, preview in ipairs({ { self.previewRpmOption, "msc_help_previewRpm" }, { self.previewLoadOption, "msc_help_previewLoad" } }) do
        if preview[1] ~= nil then
            self:extendSliderDrag(preview[1])
            self:connectHelpText(preview[1], preview[2])
        end
    end

    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
            local slider = self:getOption(category, parameter.name)
            if slider ~= nil then
                self:extendSliderDrag(slider)
                -- engine and transmission share the help texts, the other categories have their own
                local isShared = category == MotorSoundConfigurator.CATEGORY_MOTOR or category == MotorSoundConfigurator.CATEGORY_GEARBOX
                self:connectHelpText(slider, isShared and ("msc_help_" .. parameter.name) or ("msc_help_" .. category .. "_" .. parameter.name))
            end
        end
    end

    -- tables: one help text per column
    for _, block in ipairs(MotorSoundConfiguratorDialog.TABLE_BLOCKS) do
        for row = 1, MotorSoundConfiguratorDialog.TABLE_ROWS do
            for _, cell in ipairs(block.cells) do
                local option = self:getTableCellElements(block, row, cell)
                if option ~= nil then
                    self:extendSliderDrag(option)
                    self:connectHelpText(option, "msc_help_" .. cell.category .. "_volume")
                end
            end
        end
    end

    for row = 1, MotorSoundConfiguratorDialog.LAYER_ROWS do
        local choice, volume = self:getLayerRowElements(row)
        -- the texts are replaced per row in updateLayerRows
        self:connectHelpText(choice, "msc_help_layer")
        if volume ~= nil then
            self:extendSliderDrag(volume)
            self:connectHelpText(volume, "msc_help_layerVolume")
        end
    end

    -- the texts are replaced per preset in updatePresetButtons
    for index = 1, MotorSoundConfiguratorDialog.PRESET_BUTTONS do
        self:connectHelpText(self["presetButton" .. index], "msc_help_tab_presets")
    end

    -- engine swap: the texts of the engine buttons are replaced per engine in updateSwapPage
    self:connectHelpText(self.swapButton1, "msc_help_swap_own")
    for index = 2, MotorSoundConfiguratorDialog.SWAP_BUTTONS do
        self:connectHelpText(self["swapButton" .. index], "msc_help_tab_swap")
    end
    if self.swapVolumeOption ~= nil then
        self:extendSliderDrag(self.swapVolumeOption)
        self:connectHelpText(self.swapVolumeOption, "msc_help_swap_volume")
    end
    self:connectHelpText(self.swapViewBaseButton, "msc_help_swap_viewBase")
    self:connectHelpText(self.swapViewModButton, "msc_help_swap_viewMod")
    self:connectHelpText(self.swapViewOtherButton, "msc_help_swap_viewOther")
    self:connectHelpText(self.swapPagePrevButton, "msc_help_swap_page")
    self:connectHelpText(self.swapPageNextButton, "msc_help_swap_page")
    self:connectHelpText(self.swapMissingButton, "msc_help_swap_removeMissing")

    -- full width of the meter bars, the fill is resized to rpm / load
    if self.rpmMeterFill ~= nil then
        self.meterWidth = self.rpmMeterFill.size[1]
    end

    -- fixed up / down order inside each page (the links to the scope row and the tabs depend on the page, see
    -- updateFocusLinks); FocusManager:linkElements, a link to an element that cannot be focused (hidden, disabled)
    -- is followed further (FocusManager:updateFocus)
    for page, _ in pairs(MotorSoundConfiguratorDialog.FOCUS_ORDER) do
        local elements = self:getFocusElements(page)
        for index = 1, #elements - 1 do
            FocusManager:linkElements(elements[index], FocusManager.BOTTOM, elements[index + 1])
            FocusManager:linkElements(elements[index + 1], FocusManager.TOP, elements[index])
        end
    end
end


-- elements of a page in focus order (FOCUS_ORDER), only those that exist and can hold focus links
function MotorSoundConfiguratorDialog:getFocusElements(page)
    local elements = {}
    for _, id in ipairs(MotorSoundConfiguratorDialog.FOCUS_ORDER[page] or {}) do
        local element = self[id]
        if element ~= nil and element.focusChangeData ~= nil then
            table.insert(elements, element)
        end
    end
    return elements
end


-- links between the current tab, the scope row and the page: right from any tab = first control of the page,
-- up from the first control = the current tab, down from the last control = back to the first (wrap)
function MotorSoundConfiguratorDialog:updateFocusLinks()
    -- disabled controls (engine swap volume without a swap, hidden sliders of the "Sound" / "Filter" pages) cannot take
    -- the focus: first / last are the enabled ones (wrap from the last to the first); links between neighbours pass
    -- over the others. When one is enabled again, the links point back to it
    local elements = {}
    for _, element in ipairs(self:getFocusElements(self.page)) do
        if not element:getIsDisabled() then
            table.insert(elements, element)
        end
    end
    if self.page == MotorSoundConfiguratorDialog.PAGE_SWAP and elements[2] ~= nil then
        FocusManager:linkElements(elements[2], FocusManager.TOP, elements[1])
    end
    if self.scopeOption ~= nil and self.scopeOption.focusChangeData ~= nil and not self.scopeOption:getIsDisabled() then
        table.insert(elements, 1, self.scopeOption)
        if elements[2] ~= nil then
            FocusManager:linkElements(self.scopeOption, FocusManager.BOTTOM, elements[2])
            FocusManager:linkElements(elements[2], FocusManager.TOP, self.scopeOption)
        end
    end
    local first, last = elements[1], elements[#elements]
    local currentTab = self:getTabButton(self.page)
    if first == nil then
        return
    end
    for page = 1, MotorSoundConfiguratorDialog.PAGE_COUNT do
        local tab = self:getTabButton(page)
        if tab ~= nil and tab.focusChangeData ~= nil then
            FocusManager:linkElements(tab, FocusManager.RIGHT, first)
        end
    end
    if currentTab ~= nil then
        FocusManager:linkElements(first, FocusManager.TOP, currentTab)
    end
    -- presets / engine swap: only the first button is listed, the others use the automatic order
    if last ~= first and self.page ~= MotorSoundConfiguratorDialog.PAGE_PRESETS and self.page ~= MotorSoundConfiguratorDialog.PAGE_SWAP then
        FocusManager:linkElements(last, FocusManager.BOTTOM, first)
    end
end


function MotorSoundConfiguratorDialog:getTabButton(page)
    if page == MotorSoundConfiguratorDialog.PAGE_SOUND then
        return self.tabSoundButton
    elseif page == MotorSoundConfiguratorDialog.PAGE_OTHER then
        return self.tabOtherButton
    elseif page == MotorSoundConfiguratorDialog.PAGE_FILTER then
        return self.tabFilterButton
    elseif page == MotorSoundConfiguratorDialog.PAGE_LAYERS then
        return self.tabLayersButton
    elseif page == MotorSoundConfiguratorDialog.PAGE_SWAP then
        return self.tabSwapButton
    end
    return self.tabPresetsButton
end


-- "Apply" key by input help mode (K2): controller = right stick press, otherwise Enter; the button shows the glyph of
-- its input action (ButtonElement:setInputAction reloads it). force = set even if the mode did not change
function MotorSoundConfiguratorDialog:updateApplyInput(force)
    if self.applyButton == nil or g_inputBinding == nil then
        return
    end
    local mode = g_inputBinding:getInputHelpMode()
    if force or mode ~= self.lastInputMode then
        self.lastInputMode = mode
        local actionName = mode == GS_INPUT_HELP_MODE_GAMEPAD and MotorSoundConfiguratorDialog.APPLY_ACTION_GAMEPAD
            or MotorSoundConfiguratorDialog.APPLY_ACTION_KEYBOARD
        self.applyButton:setInputAction(actionName)
    end
end


function MotorSoundConfiguratorDialog:isGamepadMode()
    return g_inputBinding ~= nil and g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
end


-- GuiElement:onGuiSetupFinished resolves toolTipElementId (RAW elements/GuiElement.lua:568), but
-- MultiTextOptionElement:onGuiSetupFinished does not call it (MultiTextOptionElement.lua:222), so for
-- MultiTextOption / OptionSlider the link is set here. Showing and clearing the text on focus / mouse over
-- is done by GuiElement:onFocusEnter / onHighlight (GuiElement.lua:942-991).
function MotorSoundConfiguratorDialog:connectHelpText(element, l10nKey)
    if element == nil or self.helpText == nil then
        return
    end
    element.toolTipElement = self.helpText
    element.toolTipText = g_i18n:getText(l10nKey)

    -- a focused element is never highlighted on mouse over (OptionSliderElement.lua:201 / MultiTextOption:
    -- "not self:getIsFocused()"), so its text would not reappear after the mouse visited another control.
    -- Show / clear the text of the focused element on mouse over / mouse out here.
    local helpText = self.helpText
    local originalMouseEvent = element.mouseEvent
    element.mouseEvent = function(el, posX, posY, isDown, isUp, button, eventUsed)
        local result = originalMouseEvent(el, posX, posY, isDown, isUp, button, eventUsed)

        local isInside = GuiUtils.checkOverlayOverlap(posX, posY, el.absPosition[1], el.absPosition[2], el.absSize[1], el.absSize[2], nil)
        if el:getIsFocused() then
            if isInside and not el.mscHelpShown then
                helpText:setText(el.toolTipText)
                el.mscHelpShown = true
            elseif not isInside and el.mscHelpShown then
                -- only clear our own text; another control may have set its text in the same mouse event
                if helpText:getText() == el.toolTipText then
                    helpText:setText("")
                end
                el.mscHelpShown = false
            end
        else
            el.mscHelpShown = false
        end
        return result
    end
end


-- changes the help text of an element; shown at once if the element is focused
function MotorSoundConfiguratorDialog:setHelpText(element, text)
    if element == nil then
        return
    end
    element.toolTipText = text
    if self.helpText ~= nil and element:getIsFocused() then
        self.helpText:setText(text)
    end
end


-- OptionSliderElement:mouseEvent only handles dragging while the mouse is inside the element
-- (RAW elements/OptionSliderElement.lua:200), so the first / last step needs pixel-exact mouse positions.
-- While dragging, keep the position inside the element and jump to the first / last step beyond its ends.
-- Only for an active slider; the slider is remembered for resetSliderDrags.
function MotorSoundConfiguratorDialog:extendSliderDrag(slider)
    local originalMouseEvent = slider.mouseEvent
    self.dragSliders = self.dragSliders or {}
    table.insert(self.dragSliders, slider)

    slider.mouseEvent = function(element, posX, posY, isDown, isUp, button, eventUsed)
        local edgeState = nil
        if element.isSliderAreaPressed and not isDown and not isUp and element:getIsActive() then
            local left = element.absPosition[1]
            local right = left + element.absSize[1]
            local bottom = element.absPosition[2]
            local top = bottom + element.absSize[2]

            if posX <= left then
                edgeState = 1
            elseif posX >= right then
                edgeState = #element.texts
            end
            posX = math.clamp(posX, left + g_pixelSizeX, right - g_pixelSizeX)
            posY = math.clamp(posY, bottom + g_pixelSizeY, top - g_pixelSizeY)
        end

        local result = originalMouseEvent(element, posX, posY, isDown, isUp, button, eventUsed)

        if edgeState ~= nil and edgeState >= 1 and element.state ~= edgeState then
            element:setState(edgeState, true)
            element:updateSlider()
        end
        -- OptionSliderElement:mouseEvent resets the drag on release only while the slider is active (:155 / 183-196): a
        -- slider disabled during the drag would keep it and follow the mouse later (review #24)
        if isUp then
            MotorSoundConfiguratorDialog.resetSliderDrag(element)
        end
        return result
    end
end


-- drag state of OptionSliderElement:mouseEvent (fields set on press, cleared on release)
function MotorSoundConfiguratorDialog.resetSliderDrag(slider)
    slider.isSliderPressed = false
    slider.isSliderAreaPressed = false
    slider.sliderMousePosX = nil
end


-- a slider hidden or closed during a drag gets no release event any more (GuiElement passes mouse events to visible
-- elements only): called on page changes and when the dialog closes (review #24)
function MotorSoundConfiguratorDialog:resetSliderDrags()
    for _, slider in ipairs(self.dragSliders or {}) do
        MotorSoundConfiguratorDialog.resetSliderDrag(slider)
    end
end


---------------------------------------------------------------------------
-- Lifecycle (bound from the <GUI> root)
---------------------------------------------------------------------------

function MotorSoundConfiguratorDialog:onMscDialogOpen()
    -- base lifecycle (mouse cursor etc.), normally reached through onOpen="onOpen"
    self:onOpen()
    -- after onOpen: ButtonElement:onOpen reloads the glyphs of the buttons
    self:updateApplyInput(true)
    self:updateAll()
    -- the FocusManager gives the focus back to the last focused element before this callback (Gui.lua:557-559); after
    -- updateAll it may be disabled or hidden (work sound slider of a tractor, swap volume without a swap): then the
    -- current tab gets it (review #35)
    local focused = FocusManager:getFocusedElement()
    if focused == nil or focused:getIsDisabled() or not focused:getIsVisible() then
        local tab = self:getTabButton(self.page)
        if tab ~= nil then
            FocusManager:setFocus(tab)
        end
    end
end


function MotorSoundConfiguratorDialog:onMscDialogClose()
    self:onClose()
    self:resetSliderDrags()

    -- "hear original" and the preview never outlive the dialog
    MotorSoundConfigurator.isOriginalMode = false
    MotorSoundConfigurator.previewVehicle = nil
    MotorSoundConfigurator.previewRpm = nil
    MotorSoundConfigurator.previewLoad = nil

    if self.isCancelled and self.settingsCopy ~= nil then
        -- also re-attaches / detaches layers and applies the factors
        MotorSoundConfigurator.restoreSettings(self.settingsCopy)
    else
        MotorSoundConfigurator.applyToAllVehicles()
        -- written at once (not only with the savegame), but only if something changed (review 2026-10-03)
        if self.settingsCopy == nil or MotorSoundConfigurator.hasSettingsChanged(self.settingsCopy) then
            MotorSoundConfigurator.saveSettings(MotorSoundConfigurator.getSettings())
        end
    end

    self.settingsCopy = nil
    self.isCancelled = false
    self.isClosePending = false
    self.vehicleData = nil
end


-- live rpm / load (Gui:update calls update(dt) of every open dialog, RAW base/Gui.lua)
function MotorSoundConfiguratorDialog:update(dt)
    MotorSoundConfiguratorDialog:superClass().update(self, dt)
    self:updateLiveValues(dt)
    -- switching between controller and keyboard / mouse while the dialog is open (polled like HUDPopupMessageMobile)
    self:updateApplyInput(false)
end


---------------------------------------------------------------------------
-- Display helpers
---------------------------------------------------------------------------

function MotorSoundConfiguratorDialog.formatPercent(factor)
    return string.format("%d %%", math.floor(factor * 100 + 0.5))
end


function MotorSoundConfiguratorDialog.isChanged(value)
    return value ~= nil and math.abs(value - 1.0) > 0.001
end


function MotorSoundConfiguratorDialog.getSteps(parameter)
    local steps = MotorSoundConfiguratorDialog.stepsByParameter[parameter.name]
    if steps == nil then
        steps = { parameter.min }
        for _, step in ipairs(MotorSoundConfiguratorDialog.FACTOR_STEPS) do
            if step > parameter.min and step <= parameter.max then
                table.insert(steps, step)
            end
        end
        -- inverted parameters run from their max (shown as 0 %) on the left to their min on the right
        if MotorSoundConfiguratorDialog.INVERTED_PARAMETERS[parameter.name] then
            local reversed = {}
            for index = #steps, 1, -1 do
                table.insert(reversed, steps[index])
            end
            steps = reversed
        end
        MotorSoundConfiguratorDialog.stepsByParameter[parameter.name] = steps
    end
    return steps
end


-- layer volume: 10 .. 300 % ("Off" is chosen in the sound selection of the row)
function MotorSoundConfiguratorDialog.getLayerVolumeSteps()
    local steps = MotorSoundConfiguratorDialog.layerVolumeSteps
    if steps == nil then
        steps = {}
        for _, step in ipairs(MotorSoundConfiguratorDialog.FACTOR_STEPS) do
            if step >= MotorSoundConfigurator.LAYER_VOLUME_MIN and step <= MotorSoundConfigurator.LAYER_VOLUME_MAX then
                table.insert(steps, step)
            end
        end
        MotorSoundConfiguratorDialog.layerVolumeSteps = steps
    end
    return steps
end


function MotorSoundConfiguratorDialog.getStepTexts(steps, parameterName)
    local texts = {}
    for _, step in ipairs(steps) do
        table.insert(texts, MotorSoundConfiguratorDialog.formatValue(parameterName, step))
    end
    return texts
end


-- value text of a factor; inverted parameters show 1 - value (indoorDamping 1.0 = "Cabin openness 0 %")
function MotorSoundConfiguratorDialog.formatValue(parameterName, value)
    if parameterName ~= nil and MotorSoundConfiguratorDialog.INVERTED_PARAMETERS[parameterName] then
        return MotorSoundConfiguratorDialog.formatPercent(1.0 - value)
    end
    return MotorSoundConfiguratorDialog.formatPercent(value)
end


-- index of the step closest to factor (values set by console may lie between steps)
function MotorSoundConfiguratorDialog.getStepIndex(steps, factor)
    local bestIndex = 1
    local bestDistance = math.huge
    for index, step in ipairs(steps) do
        local distance = math.abs(step - factor)
        if distance < bestDistance then
            bestIndex = index
            bestDistance = distance
        end
    end
    return bestIndex
end


-- l10n text with a fallback (a missing catalog translation must not show the l10n error text)
function MotorSoundConfiguratorDialog.getTextOrKey(key, fallback)
    if g_i18n:hasText(key) then
        return g_i18n:getText(key)
    end
    return fallback or key
end


function MotorSoundConfiguratorDialog.getGroupText(groupName)
    return MotorSoundConfiguratorDialog.getTextOrKey("msc_group_" .. groupName, groupName)
end


function MotorSoundConfiguratorDialog.getLayerText(layer)
    -- engines from mods and DLCs: brand + store name (not translated)
    if layer.isModEngine then
        return layer.fullName
    end
    return MotorSoundConfiguratorDialog.getTextOrKey("msc_layer_" .. layer.name, layer.name)
end


-- help line of a layer row: what the group does, plus the source vehicle of the chosen sound in its own line
-- (the l10n texts use &#10; for their line breaks, user 2026-10-02: one part per line)
function MotorSoundConfiguratorDialog.getLayerHelpText(group, layer)
    local text = MotorSoundConfiguratorDialog.getTextOrKey("msc_help_group_" .. group.name, g_i18n:getText("msc_help_layer"))
    local source = nil
    if layer ~= nil and not layer.isOwn then
        if layer.source ~= nil then
            source = layer.source
        elseif layer.baseGameFile ~= nil then
            source = string.format(g_i18n:getText("msc_layer_baseGame"), layer.baseGameFile)
        end
    end
    if source ~= nil then
        text = text .. "\n" .. string.format(g_i18n:getText("msc_layer_source"), source)
    end
    return text
end


-- help line of a preset button: what it does, then the values it sets (engine in its own line, transmission and
-- cabin & fan together in one line) and one line for its extra sounds, at most 4 lines. No click hint
-- (user 2026-10-02: the green button and the context are enough).
function MotorSoundConfiguratorDialog.getPresetHelpText(preset)
    local lines = {}
    local description = MotorSoundConfiguratorDialog.getTextOrKey("msc_help_preset_" .. preset.name, "")
    if description ~= "" then
        table.insert(lines, description)
    end
    local lineFormat = g_i18n:getText("msc_preset_line")

    local otherParts = {}
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        local values = preset.values ~= nil and preset.values[category] or nil
        if values ~= nil then
            local parts = {}
            for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
                if values[parameter.name] ~= nil then
                    table.insert(parts, g_i18n:getText("msc_param_" .. parameter.name) .. " " .. MotorSoundConfiguratorDialog.formatValue(parameter.name, values[parameter.name]))
                end
            end
            local text = string.format(lineFormat, g_i18n:getText("msc_category_" .. category), table.concat(parts, ", "))
            if category == MotorSoundConfigurator.CATEGORY_MOTOR then
                table.insert(lines, text)
            else
                table.insert(otherParts, text)
            end
        end
    end
    if #otherParts > 0 then
        table.insert(lines, table.concat(otherParts, g_i18n:getText("msc_preset_separator")))
    end

    if preset.layers ~= nil then
        local parts = {}
        for _, presetLayer in ipairs(preset.layers) do
            local layer = MotorSoundConfigurator.getCatalogLayer(presetLayer.name)
            local layerText = layer ~= nil and MotorSoundConfiguratorDialog.getLayerText(layer) or presetLayer.name
            table.insert(parts, layerText .. " " .. MotorSoundConfiguratorDialog.formatPercent(presetLayer.volume))
        end
        table.insert(lines, string.format(lineFormat, g_i18n:getText("msc_tab_layers"), table.concat(parts, ", ")))
    end
    return table.concat(lines, "\n")
end


function MotorSoundConfiguratorDialog:isModelScope()
    return self.scopeIndex == MotorSoundConfiguratorDialog.SCOPE_MODEL
end


function MotorSoundConfiguratorDialog:getModelKey()
    return self.vehicleData ~= nil and self.vehicleData.modelKey or nil
end


function MotorSoundConfiguratorDialog:getOption(category, parameterName)
    return self[category .. "_" .. parameterName .. "Option"]
end


function MotorSoundConfiguratorDialog:getValueText(category, parameterName)
    return self[category .. "_" .. parameterName .. "Value"]
end


-- slider, value text and "-" (no such sound) of one cell of a table
function MotorSoundConfiguratorDialog:getTableCellElements(block, row, cell)
    local prefix = block.rowPrefix .. row .. cell.id
    return self[prefix .. "Option"], self[prefix .. "Value"], self[prefix .. "Dash"]
end


function MotorSoundConfiguratorDialog:getLayerRowElements(row)
    local prefix = "layerRow" .. row
    return self[prefix .. "Choice"], self[prefix .. "Volume"], self[prefix .. "Label"], self[prefix .. "Value"]
end


-- model override of a category, nil in global scope or without override
function MotorSoundConfiguratorDialog:getOverride(category, parameterName)
    if not self:isModelScope() or self.vehicleData == nil then
        return nil
    end
    local values = MotorSoundConfigurator.getModelValues(self.vehicleData.modelKey, category)
    return values ~= nil and values[parameterName] or nil
end


-- value shown on the "Sound" page: global scope = global value, model scope = effective value of the model
function MotorSoundConfiguratorDialog:getShownValue(category, parameterName)
    local global = MotorSoundConfigurator.getSettings().global[category][parameterName]
    return self:getOverride(category, parameterName) or global
end


-- parameters of a page that count for a category: none if the vehicle has no own samples of it (a changed global
-- work volume must not mark the tab of a tractor, review #34; same for any category, user 2026-10-13), work /
-- discharge only their volume. "Other sounds" holds the volume of cabin, rattle and work sounds (v0.19.0.0), "Sound" /
-- "Filter" the engine and transmission factors
function MotorSoundConfiguratorDialog:getPageParameters(page, category)
    if not self:hasCategoryEntries(category) then
        return {}
    end
    local isOther = MotorSoundConfiguratorDialog.OTHER_CATEGORIES[category] == true
    if page == MotorSoundConfiguratorDialog.PAGE_OTHER then
        return isOther and { "volume" } or {}
    end
    if MotorSoundConfigurator.isVolumeOnlyCategory(category) or (isOther and page == MotorSoundConfiguratorDialog.PAGE_SOUND) then
        return {}
    end
    -- "rpm character" only where an own sample follows the motor rpm (electric motors follow the speed)
    local parameters = {}
    for _, parameterName in ipairs(MotorSoundConfiguratorDialog.PAGE_PARAMETERS[page]) do
        if parameterName ~= "rpm" or self:hasRpmControlledEntries(category) then
            table.insert(parameters, parameterName)
        end
    end
    return parameters
end


-- an own sample of the category follows the motor rpm, so "rpm character" acts on it (MotorSoundConfigurator.isRpmControlled)
function MotorSoundConfiguratorDialog:hasRpmControlledEntries(category)
    if self.vehicleData == nil then
        return false
    end
    for _, entry in ipairs(self.vehicleData.entries) do
        if entry.category == category and not entry.isLayer and MotorSoundConfigurator.isRpmControlled(entry.sample) then
            return true
        end
    end
    return false
end


-- any factor of the page ("Sound" / "Filter") differs from the original for this vehicle's model (effective values)
function MotorSoundConfiguratorDialog:hasPageChanges(page)
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        local factors = MotorSoundConfigurator.getFactors(self:getModelKey(), category)
        for _, parameterName in ipairs(self:getPageParameters(page, category)) do
            if MotorSoundConfiguratorDialog.isChanged(factors[parameterName]) then
                return true
            end
        end
    end
    -- sounds of the attached trailers / implements (their own models)
    if page == MotorSoundConfiguratorDialog.PAGE_OTHER then
        for _, data in ipairs(MotorSoundConfigurator.getAttachedImplementData(self:getVehicle())) do
            for _, category in ipairs(MotorSoundConfigurator.IMPLEMENT_CATEGORIES) do
                if MotorSoundConfiguratorDialog.hasEntriesOf(data, category)
                    and MotorSoundConfiguratorDialog.isChanged(MotorSoundConfigurator.getFactors(data.modelKey, category).volume) then
                    return true
                end
            end
        end
    end
    return false
end


-- vehicle data has own samples of the category (layers not counted)
function MotorSoundConfiguratorDialog.hasEntriesOf(data, category)
    for _, entry in ipairs(data ~= nil and data.entries or {}) do
        if entry.category == category and not entry.isLayer then
            return true
        end
    end
    return false
end


-- the vehicle of the dialog has own samples of the category (layers not counted)
function MotorSoundConfiguratorDialog:hasCategoryEntries(category)
    if self.vehicleData == nil then
        return false
    end
    for _, entry in ipairs(self.vehicleData.entries) do
        if entry.category == category and not entry.isLayer then
            return true
        end
    end
    return false
end


function MotorSoundConfiguratorDialog:hasLayerChanges()
    local layers = MotorSoundConfigurator.getModelLayers(self:getModelKey())
    return layers ~= nil and next(layers) ~= nil
end


---------------------------------------------------------------------------
-- Display
---------------------------------------------------------------------------

function MotorSoundConfiguratorDialog:updateAll()
    local data = self.vehicleData
    if self.vehicleNameText ~= nil then
        self.vehicleNameText:setText(data ~= nil and tostring(data.name) or "")
    end

    if self.scopeOption ~= nil then
        self.scopeOption:setTexts({ g_i18n:getText("msc_scope_global"), g_i18n:getText("msc_scope_model") })
    end

    self.lastLiveTexts = {}
    self.lastMeterFactors = {}
    self.smoothRpm, self.smoothLoad, self.shownRpm, self.shownLoad = nil, nil, nil, nil
    self.formattedRpm, self.formattedLoad = nil, nil
    self:updatePage()
    self:updateOriginalButton()
    self:updatePreview()
    self:updateLiveValues(nil)
end


function MotorSoundConfiguratorDialog:updatePage()
    local page = self.page
    -- a drag on the page that is hidden now would never get its release (review #24)
    self:resetSliderDrags()
    for _, pageElement in ipairs({ { self.soundPage, MotorSoundConfiguratorDialog.PAGE_SOUND },
                                   { self.otherPage, MotorSoundConfiguratorDialog.PAGE_OTHER },
                                   { self.filterPage, MotorSoundConfiguratorDialog.PAGE_FILTER },
                                   { self.layerPage, MotorSoundConfiguratorDialog.PAGE_LAYERS },
                                   { self.presetPage, MotorSoundConfiguratorDialog.PAGE_PRESETS },
                                   { self.swapPage, MotorSoundConfiguratorDialog.PAGE_SWAP } }) do
        if pageElement[1] ~= nil then
            pageElement[1]:setVisible(page == pageElement[2])
        end
    end

    -- one scope row for all pages (UI review #6): extra sounds and presets are always for this model, there it shows
    -- "This model only" locked; self.scopeIndex stays for the "Sound" / "Filter" pages. The engine swap page has its
    -- volume row in that place, so the scope row is hidden there (and disabled, so updateFocusLinks skips it)
    if self.scopeOption ~= nil then
        local isSwap = page == MotorSoundConfiguratorDialog.PAGE_SWAP
        local isLocked = isSwap or page == MotorSoundConfiguratorDialog.PAGE_LAYERS or page == MotorSoundConfiguratorDialog.PAGE_PRESETS
        self.scopeOption:setState(isLocked and MotorSoundConfiguratorDialog.SCOPE_MODEL or self.scopeIndex)
        self.scopeOption:setDisabled(isLocked)
        self.scopeOption:setVisible(not isSwap)
        if self.scopeLabel ~= nil then
            self.scopeLabel:setVisible(not isSwap)
        end
    end
    -- the engine swap page links its focus in updateSwapPage (the volume slider is enabled there), once (review #38)
    if page ~= MotorSoundConfiguratorDialog.PAGE_SWAP then
        self:updateFocusLinks()
    end

    if page == MotorSoundConfiguratorDialog.PAGE_LAYERS then
        self:updateLayerRows()
    elseif page == MotorSoundConfiguratorDialog.PAGE_PRESETS then
        self:updatePresetButtons()
    elseif page == MotorSoundConfiguratorDialog.PAGE_SWAP then
        self:updateSwapPage()
    else
        self:updateSoundRows()
    end
    self:updateTabs()
end


-- tab texts with the changed marker; the current tab is selected (light grey) and has the green bar left of it
function MotorSoundConfiguratorDialog:updateTabs()
    local marker = MotorSoundConfiguratorDialog.CHANGED_MARKER
    local tabs = {
        { self.tabSoundButton, self.tabSoundMarker, MotorSoundConfiguratorDialog.PAGE_SOUND, "msc_tab_sound",
          self:hasPageChanges(MotorSoundConfiguratorDialog.PAGE_SOUND) },
        { self.tabOtherButton, self.tabOtherMarker, MotorSoundConfiguratorDialog.PAGE_OTHER, "msc_tab_other",
          self:hasPageChanges(MotorSoundConfiguratorDialog.PAGE_OTHER) },
        { self.tabFilterButton, self.tabFilterMarker, MotorSoundConfiguratorDialog.PAGE_FILTER, "msc_tab_filter",
          self:hasPageChanges(MotorSoundConfiguratorDialog.PAGE_FILTER) },
        { self.tabLayersButton, self.tabLayersMarker, MotorSoundConfiguratorDialog.PAGE_LAYERS, "msc_tab_layers", self:hasLayerChanges() },
        { self.tabPresetsButton, self.tabPresetsMarker, MotorSoundConfiguratorDialog.PAGE_PRESETS, "msc_tab_presets", false },
        { self.tabSwapButton, self.tabSwapMarker, MotorSoundConfiguratorDialog.PAGE_SWAP, "msc_tab_swap",
          MotorSoundConfigurator.getActiveSwap(self:getModelKey()) ~= nil }
    }
    for _, tab in ipairs(tabs) do
        local button, tabMarker, page, l10nKey, isChanged = tab[1], tab[2], tab[3], tab[4], tab[5]
        if button ~= nil then
            button:setText(g_i18n:getText(l10nKey) .. (isChanged and marker or ""))
            button:setSelected(self.page == page)
        end
        if tabMarker ~= nil then
            tabMarker:setVisible(self.page == page)
        end
    end
end


function MotorSoundConfiguratorDialog:updateOriginalButton()
    if self.originalButton ~= nil then
        local isOriginal = MotorSoundConfigurator.isOriginalMode
        self.originalButton:setText(g_i18n:getText(isOriginal and "msc_original_on" or "msc_original_off"))
        self.originalButton:setSelected(isOriginal)
    end
    -- "now" of the info panel follows the playing values ("hear original" = original)
    self:updateFilterInfo()
end


-- "Sound" page: one row per parameter, engine and transmission slider side by side
function MotorSoundConfiguratorDialog:updateSoundRows()
    for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
        local steps = MotorSoundConfiguratorDialog.getSteps(parameter)
        local texts = MotorSoundConfiguratorDialog.getStepTexts(steps, parameter.name)
        for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
            local option = self:getOption(category, parameter.name)
            if option ~= nil then
                option:setTexts(texts)
                option:setState(MotorSoundConfiguratorDialog.getStepIndex(steps, self:getShownValue(category, parameter.name)))
                -- in "This model only" without own samples of the category (work sounds of a tractor, engine of a
                -- vehicle without engine samples) a value would have no effect, so the slider is hidden (v0.18.1.0,
                -- user 2026-10-15; before disabled and dimmed); "All vehicles" shows all. Disabled as well, so the
                -- focus order skips it (updateFocusLinks)
                local isUsable = self:isParameterUsable(category, parameter.name)
                option:setVisible(isUsable)
                option:setDisabled(not isUsable)
                -- own row label per column (v0.18.1.0), hidden with its slider
                local label = self[category .. "_" .. parameter.name .. "Label"]
                if label ~= nil then
                    label:setVisible(isUsable)
                end
            end
        end
        self:updateSoundRowTexts(parameter.name)
    end
    self:updateSoundLabels()
    self:updateTables()
    self:updateOutdoorHelpTexts()
    self:updateFilterInfo()
    -- the hidden (disabled) sliders change with the scope, first / last of the focus order with them
    if self.page == MotorSoundConfiguratorDialog.PAGE_SOUND or self.page == MotorSoundConfiguratorDialog.PAGE_OTHER
        or self.page == MotorSoundConfiguratorDialog.PAGE_FILTER then
        self:updateFocusLinks()
    end
end


-- block and column headers of the "Sound" / "Other sounds" / "Filter" pages (ids in the XML): visible while at least one of their sliders
-- is (category_parameter), so a block or column without usable sliders disappears completely; the row labels are
-- hidden with their own slider (updateSoundRows, v0.18.1.0)
MotorSoundConfiguratorDialog.SOUND_LABELS = {
    soundMotorHeader = { "motor_volume", "motor_pitch", "motor_rpm" },
    soundGearboxHeader = { "gearbox_volume", "gearbox_pitch", "gearbox_rpm" },
    vehicleBlockHeader = { "cabin_volume", "rattle_volume", "work_volume", "discharge_volume" },
    vehicleVolumeHeader = { "cabin_volume", "rattle_volume", "work_volume", "discharge_volume" },
    indoorBlockHeader = { "motor_cutoffIndoor", "motor_gainIndoor", "motor_indoorDamping", "gearbox_cutoffIndoor", "gearbox_gainIndoor",
        "gearbox_indoorDamping" },
    filterMotorHeader = { "motor_cutoffIndoor", "motor_gainIndoor", "motor_indoorDamping", "motor_cutoffOutdoor", "motor_gainOutdoor" },
    filterGearboxHeader = { "gearbox_cutoffIndoor", "gearbox_gainIndoor", "gearbox_indoorDamping", "gearbox_cutoffOutdoor", "gearbox_gainOutdoor" },
    outdoorBlockHeader = { "motor_cutoffOutdoor", "motor_gainOutdoor", "gearbox_cutoffOutdoor", "gearbox_gainOutdoor" }
}


function MotorSoundConfiguratorDialog:updateSoundLabels()
    for id, controls in pairs(MotorSoundConfiguratorDialog.SOUND_LABELS) do
        local element = self[id]
        if element ~= nil then
            local isVisible = false
            for _, control in ipairs(controls) do
                local category, parameterName = control:match("^(%a+)_(%a+)$")
                if self:getOption(category, parameterName) ~= nil and self:isParameterUsable(category, parameterName) then
                    isVisible = true
                end
            end
            element:setVisible(isVisible)
        end
    end
end


-- rows of the vehicle block of the "Other sounds" page, top to bottom (XML positions: all four rows shown)
MotorSoundConfiguratorDialog.VEHICLE_ROWS = { MotorSoundConfigurator.CATEGORY_CABIN, MotorSoundConfigurator.CATEGORY_RATTLE,
    MotorSoundConfigurator.CATEGORY_WORK, MotorSoundConfigurator.CATEGORY_DISCHARGE }


-- the original y of an element of the "Other sounds" page (normalized, GuiElement.position[2] as loaded from the XML),
-- remembered on first use so the layout always starts from the XML positions
function MotorSoundConfiguratorDialog:getOriginalY(element)
    self.originalY = self.originalY or {}
    if self.originalY[element] == nil then
        self.originalY[element] = element.position[2]
    end
    return self.originalY[element]
end


-- moves an element of the "Other sounds" page to its XML y plus offset (normalized; GuiElement:setPosition updates the
-- anchor deltas and the absolute positions of the element and its children, GuiElement.lua:1121-1126)
function MotorSoundConfiguratorDialog:setOffsetY(element, offset)
    if element == nil then
        return
    end
    local y = self:getOriginalY(element) + offset
    if math.abs(element.position[2] - y) > 0.000001 then
        element:setPosition(nil, y)
        if element.updateSlider ~= nil then
            element:updateSlider()
        end
    end
end


-- layout of the "Other sounds" page in XML pixels (y downwards negative): first line, line of the first row below a
-- header, row step, gap from the last row to the next header, lowest row line above the help line, template header
-- line of the table blocks
MotorSoundConfiguratorDialog.LAYOUT_TOP = -165
MotorSoundConfiguratorDialog.LAYOUT_HEADER_TO_ROW = 38
MotorSoundConfiguratorDialog.LAYOUT_ROW = 42
MotorSoundConfiguratorDialog.LAYOUT_BLOCK_GAP = 51
MotorSoundConfiguratorDialog.LAYOUT_LOWEST_ROW = -590
MotorSoundConfiguratorDialog.LAYOUT_TABLE_TEMPLATE = -380


-- normalized units per XML pixel, from the distance of the first two vehicle rows in the XML (42px)
function MotorSoundConfiguratorDialog:getPixelUnit()
    local first, second = self.cabin_volumeLabel, self.rattle_volumeLabel
    if first == nil or second == nil then
        return nil
    end
    return (self:getOriginalY(first) - self:getOriginalY(second)) / MotorSoundConfiguratorDialog.LAYOUT_ROW
end


-- vehicle block: the shown rows move up into the places of hidden ones. Returns the header line of the next block
function MotorSoundConfiguratorDialog:layoutVehicleBlock(pixel)
    local shown = 0
    for index, category in ipairs(MotorSoundConfiguratorDialog.VEHICLE_ROWS) do
        local option = self:getOption(category, "volume")
        if option ~= nil and self:isParameterUsable(category, "volume") then
            shown = shown + 1
            local offset = (index - shown) * MotorSoundConfiguratorDialog.LAYOUT_ROW * pixel
            self:setOffsetY(self[category .. "_volumeLabel"], offset)
            self:setOffsetY(option, offset)
            self:setOffsetY(self:getValueText(category, "volume"), offset)
        end
    end
    if shown == 0 then
        return MotorSoundConfiguratorDialog.LAYOUT_TOP
    end
    local lastRow = MotorSoundConfiguratorDialog.LAYOUT_TOP - MotorSoundConfiguratorDialog.LAYOUT_HEADER_TO_ROW
        - (shown - 1) * MotorSoundConfiguratorDialog.LAYOUT_ROW
    return lastRow - MotorSoundConfiguratorDialog.LAYOUT_BLOCK_GAP
end


-- a cell has a slider: global row for every cell shown in "All vehicles", a model row if the model has such sounds
function MotorSoundConfiguratorDialog.isTableCellUsable(data, cell)
    if data == nil then
        return false
    elseif data == false then
        return cell.inGlobal ~= false
    end
    return MotorSoundConfiguratorDialog.hasEntriesOf(data, cell.category)
end


-- rows of both tables: "This model only" = attached models, with work or drive sounds as implement, otherwise
-- (only driving rattle) as trailer; "All vehicles" = one global row per block
function MotorSoundConfiguratorDialog:getTableData()
    if not self:isModelScope() then
        return { { false }, { false } }
    end
    local lists = { {}, {} }
    for _, data in ipairs(MotorSoundConfigurator.getAttachedImplementData(self:getVehicle())) do
        local isImplement = MotorSoundConfiguratorDialog.hasEntriesOf(data, MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK)
            or MotorSoundConfiguratorDialog.hasEntriesOf(data, MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE)
        table.insert(lists[isImplement and MotorSoundConfiguratorDialog.BLOCK_IMPLEMENTS or MotorSoundConfiguratorDialog.BLOCK_TRAILERS], data)
    end
    return lists
end


-- "Other sounds" page (v0.19.0.0, user 2026-10-19): vehicle block, then the blocks "Implements" and "Trailers" directly
-- below each other; a block without rows and a column without any slider are left out, rows that do not fit above the
-- help line as well (debug log)
function MotorSoundConfiguratorDialog:updateTables()
    local pixel = self:getPixelUnit()
    if pixel == nil then
        return
    end
    local header = self:layoutVehicleBlock(pixel)
    local lists = self:getTableData()
    local steps = MotorSoundConfiguratorDialog.getSteps(MotorSoundConfigurator.getParameter("volume"))
    local texts = MotorSoundConfiguratorDialog.getStepTexts(steps)

    for blockIndex, block in ipairs(MotorSoundConfiguratorDialog.TABLE_BLOCKS) do
        local firstRow = header - MotorSoundConfiguratorDialog.LAYOUT_HEADER_TO_ROW
        local fitting = math.floor((firstRow - MotorSoundConfiguratorDialog.LAYOUT_LOWEST_ROW) / MotorSoundConfiguratorDialog.LAYOUT_ROW) + 1
        local maxRows = math.max(0, math.min(MotorSoundConfiguratorDialog.TABLE_ROWS, fitting))
        local rows = {}
        for _, data in ipairs(lists[blockIndex]) do
            if #rows < maxRows then
                table.insert(rows, data)
            end
        end
        if #lists[blockIndex] > #rows then
            MotorSoundConfigurator.logDebug("%d rows for table %d, only %d fit into the dialog", #lists[blockIndex], blockIndex, #rows)
        end
        self.tableRows[blockIndex] = rows

        local hasRows = #rows > 0
        local offset = (header - MotorSoundConfiguratorDialog.LAYOUT_TABLE_TEMPLATE) * pixel
        if self[block.header] ~= nil then
            self[block.header]:setVisible(hasRows)
            self:setOffsetY(self[block.header], offset)
        end
        for _, cell in ipairs(block.cells) do
            -- a column is shown when at least one row has a slider in it
            cell.isShown = false
            for _, data in ipairs(rows) do
                if MotorSoundConfiguratorDialog.isTableCellUsable(data, cell) then
                    cell.isShown = true
                end
            end
            if self[cell.header] ~= nil then
                self[cell.header]:setVisible(cell.isShown)
                self:setOffsetY(self[cell.header], offset)
            end
        end

        for row = 1, MotorSoundConfiguratorDialog.TABLE_ROWS do
            local data = rows[row]
            local nameText = self[block.rowPrefix .. row .. "Name"]
            if nameText ~= nil then
                self:setOffsetY(nameText, offset)
                nameText:setVisible(data ~= nil)
                if data ~= nil then
                    nameText:setText(data and tostring(data.name) or g_i18n:getText(block.allText))
                end
            end
            for _, cell in ipairs(block.cells) do
                local option, valueText, dash = self:getTableCellElements(block, row, cell)
                self:setOffsetY(option, offset)
                self:setOffsetY(valueText, offset)
                self:setOffsetY(dash, offset)
                local isUsable = MotorSoundConfiguratorDialog.isTableCellUsable(data, cell)
                if option ~= nil then
                    option:setVisible(isUsable)
                    -- disabled as well, so the focus order skips it (updateFocusLinks)
                    option:setDisabled(not isUsable)
                    if isUsable then
                        option:setTexts(texts)
                        option:setState(MotorSoundConfiguratorDialog.getStepIndex(steps, self:getTableValue(data, cell.category)))
                    end
                end
            end
        end

        if hasRows then
            header = firstRow - (#rows - 1) * MotorSoundConfiguratorDialog.LAYOUT_ROW - MotorSoundConfiguratorDialog.LAYOUT_BLOCK_GAP
        end
    end
    self:updateTableValueTexts()
end


-- model override of a table row (nil for the global row or without override)
function MotorSoundConfiguratorDialog:getTableOverride(data, category)
    if not data then
        return nil
    end
    local values = MotorSoundConfigurator.getModelValues(data.modelKey, category)
    return values ~= nil and values.volume or nil
end


-- value of a cell: global row = global value, model row = effective value of the model
function MotorSoundConfiguratorDialog:getTableValue(data, category)
    return self:getTableOverride(data, category) or MotorSoundConfigurator.getSettings().global[category].volume
end


-- value texts of the tables, colors as on the other rows (updateSoundRowTexts); "-" in a shown column of a row without
-- such a sound
function MotorSoundConfiguratorDialog:updateTableValueTexts()
    for blockIndex, block in ipairs(MotorSoundConfiguratorDialog.TABLE_BLOCKS) do
        local rows = self.tableRows[blockIndex] or {}
        for row = 1, MotorSoundConfiguratorDialog.TABLE_ROWS do
            local data = rows[row]
            for _, cell in ipairs(block.cells) do
                local _, valueText, dash = self:getTableCellElements(block, row, cell)
                local isUsable = MotorSoundConfiguratorDialog.isTableCellUsable(data, cell)
                if dash ~= nil then
                    dash:setVisible(data ~= nil and cell.isShown == true and not isUsable)
                end
                if valueText ~= nil then
                    valueText:setVisible(isUsable)
                    if isUsable then
                        local value = self:getTableValue(data, cell.category)
                        local marker = MotorSoundConfiguratorDialog.isChanged(value) and MotorSoundConfiguratorDialog.CHANGED_MARKER or ""
                        valueText:setText(MotorSoundConfiguratorDialog.formatPercent(value) .. marker)
                        local isOwn = not data or self:getTableOverride(data, cell.category) ~= nil
                        local color = isOwn and MotorSoundConfiguratorDialog.VALUE_COLOR_OWN or MotorSoundConfiguratorDialog.VALUE_COLOR_INHERITED
                        valueText:setTextColor(color[1], color[2], color[3], color[4])
                    end
                end
            end
        end
    end
end


-- false in "This model only" when the vehicle has no own samples of the category (slider disabled; since 2026-10-13
-- for all categories, before only for the work sounds)
function MotorSoundConfiguratorDialog:isCategoryUsable(category)
    return not self:isModelScope() or self:hasCategoryEntries(category)
end


-- like isCategoryUsable; "rpm character" in "This model only" also needs an own sample that follows the motor rpm
-- (electric motors follow the driving speed, user 2026-10-13)
function MotorSoundConfiguratorDialog:isParameterUsable(category, parameterName)
    if not self:isCategoryUsable(category) then
        return false
    end
    return parameterName ~= "rpm" or not self:isModelScope() or self:hasRpmControlledEntries(category)
end


-- help line of "Outside: tone / presence" of engine and transmission: the general text plus whether this vehicle
-- muffles that part outside at all (user 2026-10-02: values above 100 % seemed to do nothing)
function MotorSoundConfiguratorDialog:updateOutdoorHelpTexts()
    for _, category in ipairs({ MotorSoundConfigurator.CATEGORY_MOTOR, MotorSoundConfigurator.CATEGORY_GEARBOX }) do
        local line = nil
        if self.vehicleData ~= nil then
            local isFiltered, gain, cutoff = MotorSoundConfigurator.getOutdoorFilter(self.vehicleData, category)
            local categoryText = g_i18n:getText("msc_category_" .. category)
            if isFiltered == true then
                line = string.format(g_i18n:getText("msc_help_outdoor_filtered"), categoryText, math.floor(gain * 100 + 0.5), math.floor(cutoff + 0.5))
            elseif isFiltered == false then
                line = string.format(g_i18n:getText("msc_help_outdoor_unfiltered"), categoryText)
            end
        end
        for _, parameterName in ipairs({ "cutoffOutdoor", "gainOutdoor" }) do
            local text = g_i18n:getText("msc_help_" .. parameterName)
            self:setHelpText(self:getOption(category, parameterName), line ~= nil and (text .. "\n" .. line) or text)
        end
    end
end


-- info panel "This vehicle" of the "Filter" page (v0.20.0.0): per category and place the muffling of the original in
-- words, plus ", now <level>" when the playing values give another level; a category without own samples shows "-",
-- the whole panel is hidden without a vehicle
MotorSoundConfiguratorDialog.FILTER_INFO = {
    { category = MotorSoundConfigurator.CATEGORY_MOTOR, isIndoor = true, id = "filterInfoMotorIndoor" },
    { category = MotorSoundConfigurator.CATEGORY_MOTOR, isIndoor = false, id = "filterInfoMotorOutdoor" },
    { category = MotorSoundConfigurator.CATEGORY_GEARBOX, isIndoor = true, id = "filterInfoGearboxIndoor" },
    { category = MotorSoundConfigurator.CATEGORY_GEARBOX, isIndoor = false, id = "filterInfoGearboxOutdoor" }
}


function MotorSoundConfiguratorDialog:updateFilterInfo()
    local data = self.vehicleData
    if self.filterInfoHeader ~= nil then
        self.filterInfoHeader:setVisible(data ~= nil)
    end
    for _, info in ipairs(MotorSoundConfiguratorDialog.FILTER_INFO) do
        local textElement = self[info.id]
        local label = self[info.id .. "Label"]
        if textElement ~= nil then
            local text = "-"
            if data ~= nil then
                local original = MotorSoundConfigurator.getMuffleLevel(data, info.category, info.isIndoor, true)
                local now = MotorSoundConfigurator.getMuffleLevel(data, info.category, info.isIndoor, false)
                if original ~= nil then
                    text = g_i18n:getText("msc_muffle_" .. original)
                    if now ~= nil and now ~= original then
                        text = string.format(g_i18n:getText("msc_filterInfo_now"), text, g_i18n:getText("msc_muffle_" .. now))
                    end
                end
            end
            textElement:setText(text)
            textElement:setVisible(data ~= nil)
        end
        if label ~= nil then
            label:setVisible(data ~= nil)
        end
    end
end


-- value texts of one parameter row (UI review #2 / #3): the changed marker behind the value ("120 % *" = differs
-- from the original); in model scope a value without override (the slider sits at the global value) is grey, an
-- own value of the model white. Row labels are fixed texts in the XML.
function MotorSoundConfiguratorDialog:updateSoundRowTexts(parameterName)
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        local valueText = self:getValueText(category, parameterName)
        if valueText ~= nil then
            local value = self:getShownValue(category, parameterName)
            local marker = MotorSoundConfiguratorDialog.isChanged(value) and MotorSoundConfiguratorDialog.CHANGED_MARKER or ""
            -- hidden with its slider when the value has no effect (see isParameterUsable)
            local isUsable = self:isParameterUsable(category, parameterName)
            valueText:setVisible(isUsable)
            valueText:setText(isUsable and (MotorSoundConfiguratorDialog.formatValue(parameterName, value) .. marker) or "-")
            local isInherited = not isUsable or (self:isModelScope() and self:getOverride(category, parameterName) == nil)
            local color = isInherited and MotorSoundConfiguratorDialog.VALUE_COLOR_INHERITED or MotorSoundConfiguratorDialog.VALUE_COLOR_OWN
            valueText:setTextColor(color[1], color[2], color[3], color[4])
            -- cabin tone / presence act no more at 100 % cabin openness (indoor filter = outdoor filter): slider, label
            -- and value dimmed and the slider locked like a layer volume without layer (user test 2026-10-19: grey
            -- value text alone was hard to see); runs after updateSoundRows set the usable state
            if MotorSoundConfiguratorDialog.OPENNESS_DEPENDENT_PARAMETERS[parameterName] then
                local isOverridden = self:isOpennessFull(category)
                local alpha = isOverridden and MotorSoundConfiguratorDialog.DISABLED_ALPHA or 1
                local option = self:getOption(category, parameterName)
                local label = self[category .. "_" .. parameterName .. "Label"]
                if option ~= nil then
                    option:setDisabled(not isUsable or isOverridden)
                    option:setAlpha(alpha)
                end
                if label ~= nil then
                    label:setAlpha(alpha)
                end
                valueText:setAlpha(alpha)
            end
        end
    end
end


-- cabin openness at 100 % (shown value of the category): cabin tone and presence have no effect then
function MotorSoundConfiguratorDialog:isOpennessFull(category)
    local damping = self:getShownValue(category, "indoorDamping")
    return damping ~= nil and 1.0 - damping >= MotorSoundConfiguratorDialog.OPENNESS_GREY_FROM
end


-- "Extra sounds" page: one row per layer group (choice incl. "Off" + volume), one layer per group active
function MotorSoundConfiguratorDialog:updateLayerRows()
    local groups = MotorSoundConfigurator.getLayerGroups()
    local modelLayers = MotorSoundConfigurator.getModelLayers(self:getModelKey()) or {}
    local volumeSteps = MotorSoundConfiguratorDialog.getLayerVolumeSteps()
    local volumeTexts = MotorSoundConfiguratorDialog.getStepTexts(volumeSteps)

    for row = 1, MotorSoundConfiguratorDialog.LAYER_ROWS do
        local choice, volume, label, valueText = self:getLayerRowElements(row)
        local group = groups[row]
        local visible = group ~= nil
        for _, element in ipairs({ choice, volume, label, valueText }) do
            element:setVisible(visible)
        end

        self.rowActiveLayers[row] = nil
        if visible then
            -- first active layer of the group in catalog order (older settings may hold several)
            local activeIndex = nil
            local texts = { g_i18n:getText("msc_layer_off") }
            for index, layer in ipairs(group.layers) do
                table.insert(texts, MotorSoundConfiguratorDialog.getLayerText(layer))
                if activeIndex == nil and modelLayers[layer.name] ~= nil then
                    activeIndex = index
                end
            end
            local activeLayer = activeIndex ~= nil and group.layers[activeIndex] or nil
            self.rowActiveLayers[row] = activeLayer

            -- "Engine (more)" with an engine whose mod is missing: shown "Off" (no sound), marked and with the hint of
            -- the swap page in the help line, as the setting is kept (review 2026-10-20)
            local missingText = nil
            if activeLayer == nil and group.name == MotorSoundConfigurator.MOD_ENGINE_GROUP then
                missingText = MotorSoundConfiguratorDialog.getMissingModEngineText(self:getModelKey())
            end
            local isChanged = activeLayer ~= nil or missingText ~= nil
            label:setText(MotorSoundConfiguratorDialog.getGroupText(group.name) .. (isChanged and MotorSoundConfiguratorDialog.CHANGED_MARKER or ""))
            choice:setTexts(texts)
            choice:setState(activeIndex ~= nil and activeIndex + 1 or 1)
            local helpText = MotorSoundConfiguratorDialog.getLayerHelpText(group, activeLayer)
            if missingText ~= nil then
                helpText = missingText .. "\n" .. helpText
            end
            self:setHelpText(choice, helpText)

            volume:setTexts(volumeTexts)
            local layerVolume = activeLayer ~= nil and modelLayers[activeLayer.name].volume or MotorSoundConfiguratorDialog.LAYER_DEFAULT_VOLUME
            -- keep the slider position of a row switched off, so switching on uses it again
            if activeLayer ~= nil or volume.mscInitialized == nil then
                volume:setState(MotorSoundConfiguratorDialog.getStepIndex(volumeSteps, layerVolume))
                volume.mscInitialized = true
            end
            volume:setDisabled(activeLayer == nil)
            -- the slider has no disabled colors (fs25_optionSlider), so it is dimmed (GuiElement:setAlpha, children too)
            volume:setAlpha(activeLayer ~= nil and 1 or MotorSoundConfiguratorDialog.DISABLED_ALPHA)
            valueText:setText(activeLayer ~= nil and MotorSoundConfiguratorDialog.formatPercent(volumeSteps[volume:getState()]) or "-")
        end
    end

    if #groups > MotorSoundConfiguratorDialog.LAYER_ROWS then
        MotorSoundConfigurator.logWarning("%d layer groups, only %d fit into the dialog", #groups, MotorSoundConfiguratorDialog.LAYER_ROWS)
    end
end


-- "Presets" page: button text = preset name, selected (green) = active for this model; buttons without preset hidden
function MotorSoundConfiguratorDialog:updatePresetButtons()
    local presets = MotorSoundConfigurator.PRESETS
    local modelKey = self:getModelKey()
    for index = 1, MotorSoundConfiguratorDialog.PRESET_BUTTONS do
        local button = self["presetButton" .. index]
        local preset = presets[index]
        if button ~= nil then
            button:setVisible(preset ~= nil)
            if preset ~= nil then
                button:setText(MotorSoundConfiguratorDialog.getTextOrKey("msc_preset_" .. preset.name, preset.name))
                button:setSelected(MotorSoundConfigurator.isPresetActive(modelKey, preset))
                self:setHelpText(button, MotorSoundConfiguratorDialog.getPresetHelpText(preset))
            end
        end
    end

    if #presets > MotorSoundConfiguratorDialog.PRESET_BUTTONS then
        MotorSoundConfigurator.logWarning("%d presets, only %d fit into the dialog", #presets, MotorSoundConfiguratorDialog.PRESET_BUTTONS)
    end
end


-- help line of an engine button: what the swap does, with the full name of the source vehicle
function MotorSoundConfiguratorDialog.getSwapHelpText(layer)
    -- engines from mods and DLCs: full name and the mod / DLC it comes from
    if layer.isModEngine then
        return string.format(g_i18n:getText("msc_help_swap_modEngine"), layer.fullName, layer.modTitle)
    end
    return string.format(g_i18n:getText("msc_help_swap_engine"), layer.source or MotorSoundConfigurator.getSwapEngineName(layer))
end


-- mod / DLC folder of a donor key ("$moddir$FS25_X/..." -> "FS25_X"), for the hint on a missing engine
function MotorSoundConfiguratorDialog.getDonorSourceName(donorKey)
    local name = donorKey
    for _, prefix in ipairs({ "$moddir$", "$pdlcdir$" }) do
        if string.startsWith(name, prefix) then
            name = string.sub(name, string.len(prefix) + 1)
        end
    end
    local slash = string.find(name, "/", 1, true)
    if slash ~= nil and slash > 1 then
        name = string.sub(name, 1, slash - 1)
    end
    return name
end


-- hint on the model's mod / DLC engines whose mod is missing ("Mod missing: FS25_X, ..."), nil if none; swap page and
-- the "Engine (more)" row of the "Extra sounds" page
function MotorSoundConfiguratorDialog.getMissingModEngineText(modelKey)
    local missing = MotorSoundConfigurator.getMissingModEngines(modelKey)
    if #missing == 0 then
        return nil
    end
    local sourceNames = {}
    for _, layerName in ipairs(missing) do
        table.insert(sourceNames, MotorSoundConfiguratorDialog.getDonorSourceName(MotorSoundConfigurator.getModEngineDonorKey(layerName)))
    end
    return string.format(g_i18n:getText("msc_swap_missing"), table.concat(sourceNames, ", "))
end


-- engines per page of the mod list ("Own engine" takes the first button)
function MotorSoundConfiguratorDialog.getSwapPageSize()
    return MotorSoundConfiguratorDialog.SWAP_BUTTONS - 1
end


-- all engines of a list: base game catalog, tractors from mods / DLCs or their other vehicles
function MotorSoundConfiguratorDialog.getSwapViewEngines(view)
    if view == MotorSoundConfiguratorDialog.SWAP_VIEW_MOD then
        return MotorSoundConfigurator.getModEnginesOfKind(true)
    elseif view == MotorSoundConfiguratorDialog.SWAP_VIEW_OTHER then
        return MotorSoundConfigurator.getModEnginesOfKind(false)
    end
    return MotorSoundConfigurator.getSwapEngines()
end


-- pages of a mod list (the base game list has one page)
function MotorSoundConfiguratorDialog.getSwapPageCount(view)
    if view == MotorSoundConfiguratorDialog.SWAP_VIEW_BASE then
        return 1
    end
    local count = #MotorSoundConfiguratorDialog.getSwapViewEngines(view)
    return math.max(1, math.ceil(count / MotorSoundConfiguratorDialog.getSwapPageSize()))
end


-- engines on the buttons 2 .. SWAP_BUTTONS for the shown list / page
function MotorSoundConfiguratorDialog:getShownSwapEngines()
    if self.swapView == MotorSoundConfiguratorDialog.SWAP_VIEW_BASE then
        return MotorSoundConfigurator.getSwapEngines()
    end
    local engines = MotorSoundConfiguratorDialog.getSwapViewEngines(self.swapView)
    local pageSize = MotorSoundConfiguratorDialog.getSwapPageSize()
    local shown = {}
    local first = (self.swapPageIndex - 1) * pageSize + 1
    for index = first, math.min(first + pageSize - 1, #engines) do
        table.insert(shown, engines[index])
    end
    return shown
end


-- list shown when the page is first updated after opening: the one of the active swap (its page for a mod engine),
-- otherwise the base game
function MotorSoundConfiguratorDialog:chooseSwapView()
    self.isSwapViewChosen = true
    self.swapView = MotorSoundConfiguratorDialog.SWAP_VIEW_BASE
    self.swapPageIndex = 1
    local activeLayer = MotorSoundConfigurator.getActiveSwap(self:getModelKey())
    if activeLayer ~= nil and activeLayer.isModEngine then
        self.swapView = MotorSoundConfigurator.isModTractorEngine(activeLayer) and MotorSoundConfiguratorDialog.SWAP_VIEW_MOD
            or MotorSoundConfiguratorDialog.SWAP_VIEW_OTHER
        for index, layer in ipairs(MotorSoundConfiguratorDialog.getSwapViewEngines(self.swapView)) do
            if layer == activeLayer then
                self.swapPageIndex = math.ceil(index / MotorSoundConfiguratorDialog.getSwapPageSize())
            end
        end
    end
end


-- a swap needs own engine samples to mute (electric motors count as "motor" since 2026-10-13, ELECTRIC_MOTOR_KEYWORDS);
-- without them a swap engine would only be added (review #23, user 2026-10-12: lock the tab with a hint)
function MotorSoundConfiguratorDialog:canSwapEngine()
    return self:hasCategoryEntries(MotorSoundConfigurator.CATEGORY_MOTOR)
end


-- "Engine swap" page: "Own engine" + one button per engine (green = active for this model, buttons without engine
-- hidden), the volume slider only usable during a swap; without own engine samples the engines are locked and a hint
-- replaces the volume row
function MotorSoundConfiguratorDialog:updateSwapPage()
    if not self.isSwapViewChosen then
        self:chooseSwapView()
    end
    if #MotorSoundConfiguratorDialog.getSwapViewEngines(self.swapView) == 0 then
        self.swapView = MotorSoundConfiguratorDialog.SWAP_VIEW_BASE
    end
    local pageCount = MotorSoundConfiguratorDialog.getSwapPageCount(self.swapView)
    self.swapPageIndex = math.clamp(self.swapPageIndex, 1, pageCount)
    local isModView = self.swapView ~= MotorSoundConfiguratorDialog.SWAP_VIEW_BASE

    local engines = self:getShownSwapEngines()
    local activeLayer, activeVolume = MotorSoundConfigurator.getActiveSwap(self:getModelKey())
    local canSwap = self:canSwapEngine()

    -- list toggle (green = shown list), only with the volume row; a mod list without engines is locked
    for _, toggle in ipairs({ { self.swapViewBaseButton, MotorSoundConfiguratorDialog.SWAP_VIEW_BASE, "msc_help_swap_viewBase" },
                              { self.swapViewModButton, MotorSoundConfiguratorDialog.SWAP_VIEW_MOD, "msc_help_swap_viewMod" },
                              { self.swapViewOtherButton, MotorSoundConfiguratorDialog.SWAP_VIEW_OTHER, "msc_help_swap_viewOther" } }) do
        local button, view, helpKey = toggle[1], toggle[2], toggle[3]
        if button ~= nil then
            local hasEngines = #MotorSoundConfiguratorDialog.getSwapViewEngines(view) > 0
            button:setVisible(canSwap)
            button:setSelected(self.swapView == view)
            button:setDisabled(not hasEngines)
            self:setHelpText(button, g_i18n:getText(hasEngines and helpKey or "msc_help_swap_viewModNone"))
        end
    end
    -- pages of the mod lists
    local hasPages = isModView and pageCount > 1
    for _, elementId in ipairs({ "swapPagePrevButton", "swapPageText", "swapPageNextButton" }) do
        if self[elementId] ~= nil then
            self[elementId]:setVisible(hasPages)
        end
    end
    if hasPages and self.swapPageText ~= nil then
        self.swapPageText:setText(string.format(g_i18n:getText("msc_swap_page"), self.swapPageIndex, pageCount))
    end
    -- engines from mods / DLCs set for this model whose mod is missing: hint with "Remove", no popup (user 2026-10-20)
    local missingText = MotorSoundConfiguratorDialog.getMissingModEngineText(self:getModelKey())
    if self.swapMissingButton ~= nil then
        self.swapMissingButton:setVisible(missingText ~= nil)
    end
    if self.swapMissingText ~= nil then
        self.swapMissingText:setVisible(missingText ~= nil)
        self.swapMissingText:setText(missingText or "")
    end

    if self.swapButton1 ~= nil then
        self.swapButton1:setText(g_i18n:getText("msc_swap_own"))
        self.swapButton1:setSelected(activeLayer == nil)
    end
    for index = 2, MotorSoundConfiguratorDialog.SWAP_BUTTONS do
        local button = self["swapButton" .. index]
        local layer = engines[index - 1]
        if button ~= nil then
            button:setVisible(layer ~= nil)
            if layer ~= nil then
                button:setText(MotorSoundConfigurator.getSwapEngineName(layer))
                button:setSelected(layer == activeLayer)
                button:setDisabled(not canSwap)
                self:setHelpText(button, canSwap and MotorSoundConfiguratorDialog.getSwapHelpText(layer) or g_i18n:getText("msc_swap_unavailable"))
            end
        end
    end
    for _, id in ipairs({ "swapVolumeLabel", "swapVolumeOption", "swapVolumeValue" }) do
        if self[id] ~= nil then
            self[id]:setVisible(canSwap)
        end
    end
    if self.swapHintText ~= nil then
        self.swapHintText:setVisible(not canSwap)
    end
    -- once per catalog list (getSwapEngines builds a new table after loadLayerCatalog), not on every update (review #37);
    -- the mod list has pages
    if not isModView and #engines > MotorSoundConfiguratorDialog.SWAP_BUTTONS - 1 and self.swapOverflowWarned ~= engines then
        self.swapOverflowWarned = engines
        MotorSoundConfigurator.logWarning("%d swap engines, only %d fit into the dialog", #engines, MotorSoundConfiguratorDialog.SWAP_BUTTONS - 1)
    end

    local slider = self.swapVolumeOption
    if slider ~= nil then
        local steps = MotorSoundConfiguratorDialog.getLayerVolumeSteps()
        slider:setTexts(MotorSoundConfiguratorDialog.getStepTexts(steps))
        slider:setState(MotorSoundConfiguratorDialog.getStepIndex(steps, activeVolume or MotorSoundConfigurator.SWAP_DEFAULT_VOLUME))
        slider:setDisabled(activeLayer == nil or not canSwap)
        -- dimmed like the volume of a layer row that is off (no disabled colors in fs25_optionSlider)
        slider:setAlpha(activeLayer ~= nil and 1 or MotorSoundConfiguratorDialog.DISABLED_ALPHA)
    end
    if self.swapVolumeValue ~= nil then
        self.swapVolumeValue:setText(activeLayer ~= nil and MotorSoundConfiguratorDialog.formatPercent(activeVolume) or "-")
    end
    -- the volume slider takes part in the focus order only while it is enabled
    if self.page == MotorSoundConfiguratorDialog.PAGE_SWAP then
        self:updateFocusLinks()
    end
end


function MotorSoundConfiguratorDialog:getVehicle()
    return self.vehicleData ~= nil and self.vehicleData.vehicle or nil
end


-- VehicleMotor of the vehicle (spec_motorized.motor, RAW VehicleMotor.lua getMinRpm / getMaxRpm), or nil
function MotorSoundConfiguratorDialog:getMotor()
    local vehicle = self:getVehicle()
    local spec = vehicle ~= nil and vehicle.spec_motorized or nil
    return spec ~= nil and spec.motor or nil
end


-- absolute rpm of a position in the sound range (0 .. 1 = minRpm .. maxRpm, as in Motorized:onUpdate)
function MotorSoundConfiguratorDialog:getPreviewRpm(factor)
    return MotorSoundConfigurator.getPreviewRpm(self:getVehicle(), factor) or 0
end


function MotorSoundConfiguratorDialog:formatRpm(rpm)
    return string.format("%d %s", math.floor(rpm + 0.5), g_i18n:getText("msc_live_rpmUnit"))
end


-- slider positions and value texts of the preview (from the current preview values)
function MotorSoundConfiguratorDialog:updatePreview()
    local steps = MotorSoundConfiguratorDialog.PREVIEW_STEPS
    local texts = {}
    for _, step in ipairs(steps) do
        table.insert(texts, step < 0 and g_i18n:getText("msc_preview_live") or MotorSoundConfiguratorDialog.formatPercent(step))
    end

    local rpm, load = self:getOwnPreview()
    local live = MotorSoundConfiguratorDialog.PREVIEW_LIVE

    if self.previewRpmOption ~= nil then
        self.previewRpmOption:setTexts(texts)
        self.previewRpmOption:setState(MotorSoundConfiguratorDialog.getStepIndex(steps, rpm or live))
    end
    if self.previewLoadOption ~= nil then
        self.previewLoadOption:setTexts(texts)
        self.previewLoadOption:setState(MotorSoundConfiguratorDialog.getStepIndex(steps, load or live))
    end
    self:updatePreviewTexts()
end


-- preview rpm / load of this dialog's vehicle (nil = live)
function MotorSoundConfiguratorDialog:getOwnPreview()
    local vehicle = self:getVehicle()
    if vehicle == nil or MotorSoundConfigurator.previewVehicle ~= vehicle then
        return nil, nil
    end
    return MotorSoundConfigurator.previewRpm, MotorSoundConfigurator.previewLoad
end


function MotorSoundConfiguratorDialog:updatePreviewTexts()
    local rpm, load = self:getOwnPreview()
    if self.previewRpmValue ~= nil then
        self.previewRpmValue:setText(rpm ~= nil and self:formatRpm(self:getPreviewRpm(rpm)) or g_i18n:getText("msc_preview_live"))
    end
    if self.previewLoadValue ~= nil then
        self.previewLoadValue:setText(load ~= nil and MotorSoundConfiguratorDialog.formatPercent(load) or g_i18n:getText("msc_preview_live"))
    end
end


-- value moved towards target with the time constant of the live display; dt nil = jump
function MotorSoundConfiguratorDialog.smooth(value, target, dt)
    if value == nil or dt == nil then
        return target
    end
    return value + (target - value) * (1 - math.exp(-dt / MotorSoundConfiguratorDialog.LIVE_SMOOTHING_TIME))
end


-- shown value in steps of stepSize, changed only when value is more than LIVE_HYSTERESIS steps away from it
function MotorSoundConfiguratorDialog.applyHysteresis(shown, value, stepSize)
    if shown == nil or math.abs(value - shown) > stepSize * MotorSoundConfiguratorDialog.LIVE_HYSTERESIS then
        return math.floor(value / stepSize + 0.5) * stepSize
    end
    return shown
end


-- rpm and load top right: what the engine sound gets right now (real values or the preview). The rpm bar runs from
-- 0 to maxRpm, so idle is visible (getMotorRpmPercentage starts at minRpm and is 0 in idle). Texts only set when
-- they change.
function MotorSoundConfiguratorDialog:updateLiveValues(dt)
    local vehicle = self:getVehicle()
    local motor = self:getMotor()
    local isRunning = vehicle ~= nil and motor ~= nil and vehicle.getIsMotorStarted ~= nil and vehicle:getIsMotorStarted()

    if not isRunning then
        self.smoothRpm, self.smoothLoad, self.shownRpm, self.shownLoad = nil, nil, nil, nil
        self.formattedRpm, self.formattedLoad = nil, nil
        self:setLiveText(self.rpmValueText, "rpm", g_i18n:getText("msc_live_off"))
        self:setLiveText(self.loadValueText, "load", "-")
        self:setMeter(self.rpmMeterFill, 0)
        self:setMeter(self.loadMeterFill, 0)
        return
    end

    local previewRpm, previewLoad = self:getOwnPreview()
    local rpm = previewRpm ~= nil and self:getPreviewRpm(previewRpm) or vehicle:getMotorRpmReal()
    -- getMotorLoadPercentage = smoothed load, -1 .. 1 (negative while braking with the engine)
    local load = previewLoad or math.clamp(vehicle:getMotorLoadPercentage(), 0, 1)

    self.smoothRpm = MotorSoundConfiguratorDialog.smooth(self.smoothRpm, rpm, dt)
    self.smoothLoad = MotorSoundConfiguratorDialog.smooth(self.smoothLoad, load, dt)
    self.shownRpm = MotorSoundConfiguratorDialog.applyHysteresis(self.shownRpm, self.smoothRpm, MotorSoundConfiguratorDialog.LIVE_RPM_STEP)
    self.shownLoad = MotorSoundConfiguratorDialog.applyHysteresis(self.shownLoad, self.smoothLoad, MotorSoundConfiguratorDialog.LIVE_LOAD_STEP)

    -- texts only formatted when the shown number changed, not every frame (review #42)
    if self.shownRpm ~= self.formattedRpm then
        self.formattedRpm = self.shownRpm
        self:setLiveText(self.rpmValueText, "rpm", self:formatRpm(self.shownRpm))
    end
    if self.shownLoad ~= self.formattedLoad then
        self.formattedLoad = self.shownLoad
        self:setLiveText(self.loadValueText, "load", MotorSoundConfiguratorDialog.formatPercent(self.shownLoad))
    end
    local maxRpm = motor:getMaxRpm()
    self:setMeter(self.rpmMeterFill, maxRpm > 0 and math.clamp(self.smoothRpm / maxRpm, 0, 1) or 0)
    self:setMeter(self.loadMeterFill, math.clamp(self.smoothLoad, 0, 1))
end


function MotorSoundConfiguratorDialog:setLiveText(element, key, text)
    if element ~= nil and self.lastLiveTexts[key] ~= text then
        element:setText(text)
        self.lastLiveTexts[key] = text
    end
end


-- difference of a meter fill below which it is not resized (about one pixel of the bar)
MotorSoundConfiguratorDialog.METER_MIN_CHANGE = 0.002


function MotorSoundConfiguratorDialog:setMeter(element, factor)
    if element == nil or self.meterWidth == nil then
        return
    end
    -- only set when it changed visibly (review #42); lastMeterFactors is cleared in updateAll
    self.lastMeterFactors = self.lastMeterFactors or {}
    local lastFactor = self.lastMeterFactors[element]
    if lastFactor ~= nil and math.abs(factor - lastFactor) < MotorSoundConfiguratorDialog.METER_MIN_CHANGE then
        return
    end
    self.lastMeterFactors[element] = factor
    element:setVisible(factor > 0.005)
    element:setSize(self.meterWidth * math.max(factor, 0.01), nil)
end


---------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------

-- any change of a value switches "hear original" off, the change should be audible
function MotorSoundConfiguratorDialog:endOriginalMode()
    if MotorSoundConfigurator.isOriginalMode then
        MotorSoundConfigurator.isOriginalMode = false
        MotorSoundConfigurator.applyToAllVehicles()
        self:updateOriginalButton()
    end
end


function MotorSoundConfiguratorDialog:onClickTabSound()
    self.page = MotorSoundConfiguratorDialog.PAGE_SOUND
    self:updatePage()
end


function MotorSoundConfiguratorDialog:onClickTabOther()
    self.page = MotorSoundConfiguratorDialog.PAGE_OTHER
    self:updatePage()
end


function MotorSoundConfiguratorDialog:onClickTabFilter()
    self.page = MotorSoundConfiguratorDialog.PAGE_FILTER
    self:updatePage()
end


-- LB / RB on the controller, Q / E on the keyboard (MENU_PAGE_PREV / NEXT, profileTemplate/inputBindingDefault_*.xml):
-- previous / next tab. Handled before the focused element, which would otherwise use them for coarse steps
-- (MultiTextOptionElement:inputEvent); Gui:notifyControls passes input to the dialog first (RAW base/Gui.lua).
-- With a controller (K2) the right stick press (MENU_EXTRA_2) applies and A activates the focused element, both handled
-- here, so they do not depend on the button lookup of ScreenElement.
function MotorSoundConfiguratorDialog:inputEvent(action, value, eventUsed)
    if not eventUsed and not self.isClosePending then
        if action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT then
            local step = action == InputAction.MENU_PAGE_NEXT and 1 or -1
            local count = MotorSoundConfiguratorDialog.PAGE_COUNT
            self.page = (self.page - 1 + step) % count + 1
            self:updatePage()
            -- the focused control may be on the hidden page now: focus the current tab
            local tab = self:getTabButton(self.page)
            if tab ~= nil then
                FocusManager:setFocus(tab)
            end
            return true
        elseif (action == InputAction.MENU_LIST_PAGE_PREV or action == InputAction.MENU_LIST_PAGE_NEXT)
            and self.page == MotorSoundConfiguratorDialog.PAGE_SWAP then
            -- pages of the mod list on the "Engine swap" page (v1.1.0.0): LT / RT on the controller, Page up / down on the
            -- keyboard (profileTemplate/inputBindingDefault_*.xml; Gui.NAV_ACTIONS passes them to the dialog, dataS.gar
            -- gui/base/Gui.lua); LB / RB stay the tab switch
            if self:changeSwapPage(action == InputAction.MENU_LIST_PAGE_NEXT and 1 or -1) then
                return true
            end
        elseif action == InputAction[MotorSoundConfiguratorDialog.APPLY_ACTION_GAMEPAD] and self:isGamepadMode() then
            self:onClickApply()
            return true
        elseif action == InputAction.MENU_ACCEPT and self:isGamepadMode() then
            -- A = activate the focused element, as FocusManager:inputEvent does (RAW base/FocusManager.lua:356); done
            -- here because the body of ScreenElement.callButtonsWithAction, which runs before it, is not visible
            local focused = FocusManager:getFocusedElement()
            if focused ~= nil and focused:getIsFocused() and focused:getIsVisible() and focused.onFocusActivate ~= nil then
                focused:onFocusActivate()
                return true
            end
            -- nothing activated: the input stays with the default handling (review #36)
        end
    end
    return MotorSoundConfiguratorDialog:superClass().inputEvent(self, action, value, eventUsed)
end


function MotorSoundConfiguratorDialog:onClickTabLayers()
    self.page = MotorSoundConfiguratorDialog.PAGE_LAYERS
    self:updatePage()
end


function MotorSoundConfiguratorDialog:onClickTabPresets()
    self.page = MotorSoundConfiguratorDialog.PAGE_PRESETS
    self:updatePage()
end


function MotorSoundConfiguratorDialog:onClickTabSwap()
    self.page = MotorSoundConfiguratorDialog.PAGE_SWAP
    self:updatePage()
end


function MotorSoundConfiguratorDialog:onClickOriginal()
    MotorSoundConfigurator.isOriginalMode = not MotorSoundConfigurator.isOriginalMode
    MotorSoundConfigurator.applyToAllVehicles()
    self:updateOriginalButton()
end


-- preview sliders: only the sound of this vehicle, not saved, ended when the dialog closes; "hear original" stays
-- as it is, so the original can be compared at the same rpm / load
function MotorSoundConfiguratorDialog:onPreviewChanged()
    local vehicle = self:getVehicle()
    if vehicle == nil then
        return
    end
    local steps = MotorSoundConfiguratorDialog.PREVIEW_STEPS
    local rpm = self.previewRpmOption ~= nil and steps[self.previewRpmOption:getState()] or nil
    local load = self.previewLoadOption ~= nil and steps[self.previewLoadOption:getState()] or nil
    if rpm ~= nil and rpm < 0 then
        rpm = nil
    end
    if load ~= nil and load < 0 then
        load = nil
    end

    if rpm ~= nil or load ~= nil then
        -- normally done in loadMap already, repeated in case the modifier types were registered later
        MotorSoundConfigurator.wrapPreviewModifierTypes()
    end
    MotorSoundConfigurator.previewVehicle = (rpm ~= nil or load ~= nil) and vehicle or nil
    MotorSoundConfigurator.previewRpm = rpm
    MotorSoundConfigurator.previewLoad = load
    self:updatePreviewTexts()
end


-- "Back to live": both preview values live again (user 2026-10-02). Always enabled: ButtonElement:setDisabled
-- removes the focus (RAW elements/ButtonElement.lua:349), which would break keyboard navigation after the click.
function MotorSoundConfiguratorDialog:onClickPreviewLive()
    MotorSoundConfigurator.previewVehicle = nil
    MotorSoundConfigurator.previewRpm = nil
    MotorSoundConfigurator.previewLoad = nil
    self:updatePreview()
end


function MotorSoundConfiguratorDialog:onPreviewRpmChanged()
    self:onPreviewChanged()
end


function MotorSoundConfiguratorDialog:onPreviewLoadChanged()
    self:onPreviewChanged()
end


function MotorSoundConfiguratorDialog:onScopeChanged()
    self.scopeIndex = self.scopeOption:getState()
    self:updateSoundRows()
end


function MotorSoundConfiguratorDialog:onSoundValueChanged(category, parameterName)
    local option = self:getOption(category, parameterName)
    if option == nil then
        return
    end
    self:endOriginalMode()

    local steps = MotorSoundConfiguratorDialog.getSteps(MotorSoundConfigurator.getParameter(parameterName))
    local value = steps[option:getState()]

    if self:isModelScope() then
        if self.vehicleData == nil then
            return
        end
        -- back on the global value (its nearest step) = no override any more
        local global = MotorSoundConfigurator.getSettings().global[category][parameterName]
        if value == steps[MotorSoundConfiguratorDialog.getStepIndex(steps, global)] then
            value = nil
        end
        MotorSoundConfigurator.setModelValue(self.vehicleData, category, parameterName, value)
    else
        MotorSoundConfigurator.setGlobalValue(category, parameterName, value)
    end

    -- live: applied now, saved with "Apply"
    MotorSoundConfigurator.applyToAllVehicles()
    -- after the settings change, so "(global)" and the markers are correct
    self:updateSoundRowTexts(parameterName)
    if MotorSoundConfiguratorDialog.INVERTED_PARAMETERS[parameterName] then
        for dependentName, _ in pairs(MotorSoundConfiguratorDialog.OPENNESS_DEPENDENT_PARAMETERS) do
            self:updateSoundRowTexts(dependentName)
        end
        -- locked sliders leave the focus order
        self:updateFocusLinks()
    end
    self:updateFilterInfo()
    self:updateTabs()
end


-- slider of a table cell: model row = value of the attached model (back on the global value = no override), global
-- row = global value
function MotorSoundConfiguratorDialog:onTableValueChanged(blockIndex, row, cellIndex)
    local block = MotorSoundConfiguratorDialog.TABLE_BLOCKS[blockIndex]
    local rows = self.tableRows[blockIndex] or {}
    local data = rows[row]
    local cell = block ~= nil and block.cells[cellIndex] or nil
    local option = cell ~= nil and self:getTableCellElements(block, row, cell) or nil
    if data == nil or option == nil or not MotorSoundConfiguratorDialog.isTableCellUsable(data, cell) then
        return
    end
    self:endOriginalMode()

    local category = cell.category
    local steps = MotorSoundConfiguratorDialog.getSteps(MotorSoundConfigurator.getParameter("volume"))
    local value = steps[option:getState()]
    if data then
        local global = MotorSoundConfigurator.getSettings().global[category].volume
        if value == steps[MotorSoundConfiguratorDialog.getStepIndex(steps, global)] then
            value = nil
        end
        MotorSoundConfigurator.setModelValue(data, category, "volume", value)
    else
        MotorSoundConfigurator.setGlobalValue(category, "volume", value)
    end

    MotorSoundConfigurator.applyToAllVehicles()
    self:updateTableValueTexts()
    self:updateTabs()
end


-- choice of a layer row: the chosen layer is attached, all other layers of the group are removed
function MotorSoundConfiguratorDialog:onLayerChoiceChanged(row)
    local group = MotorSoundConfigurator.getLayerGroups()[row]
    local choice, volume = self:getLayerRowElements(row)
    if group == nil or choice == nil or self.vehicleData == nil then
        return
    end
    self:endOriginalMode()

    local chosenLayer = group.layers[choice:getState() - 1]
    if chosenLayer ~= nil then
        local layerVolume = MotorSoundConfiguratorDialog.getLayerVolumeSteps()[volume:getState()] or MotorSoundConfiguratorDialog.LAYER_DEFAULT_VOLUME
        MotorSoundConfigurator.setGroupLayer(self.vehicleData, chosenLayer.name, layerVolume)
    else
        MotorSoundConfigurator.clearLayerGroup(self.vehicleData, group.name, nil)
        -- "Off" in the engine row also ends a swap whose engine it was (own engine back from 0 %, review #18)
        if MotorSoundConfigurator.isSwapGroup(group.name) and MotorSoundConfigurator.endSwapWithoutEngine(self.vehicleData) then
            MotorSoundConfigurator.applyToAllVehicles()
        end
    end

    self:updateLayerRows()
    self:updateTabs()
end


function MotorSoundConfiguratorDialog:onLayerVolumeChanged(row)
    local layer = self.rowActiveLayers[row]
    local _, volume, _, valueText = self:getLayerRowElements(row)
    if layer == nil or volume == nil or self.vehicleData == nil then
        return
    end
    self:endOriginalMode()

    local layerVolume = MotorSoundConfiguratorDialog.getLayerVolumeSteps()[volume:getState()]
    MotorSoundConfigurator.setModelLayer(self.vehicleData, layer.name, layerVolume)
    valueText:setText(MotorSoundConfiguratorDialog.formatPercent(layerVolume))
end


-- preset button: applies the preset to this model, or removes it if it is active (user 2026-10-02). Presets are
-- always for the model, so the "Sound" page switches to "This model only" to show the values.
function MotorSoundConfiguratorDialog:onClickPreset(index)
    local preset = MotorSoundConfigurator.PRESETS[index]
    if preset == nil or self.vehicleData == nil then
        return
    end
    self:endOriginalMode()

    if MotorSoundConfigurator.isPresetActive(self.vehicleData.modelKey, preset) then
        MotorSoundConfigurator.removePreset(self.vehicleData, preset)
    else
        MotorSoundConfigurator.applyPreset(self.vehicleData, preset)
    end

    -- the "Sound" / "Filter" pages then show the model values the preset set (the scope row shows it on updatePage)
    self.scopeIndex = MotorSoundConfiguratorDialog.SCOPE_MODEL

    -- live: applied now (layers are synced by setModelLayer), saved with "Apply"
    MotorSoundConfigurator.applyToAllVehicles()
    self:updatePresetButtons()
    self:updateTabs()
end


-- engine swap button: 1 = own engine (ends a swap), otherwise swaps to that engine at 100 % (each engine is
-- calibrated on its own); a click on the active engine ends the swap as well
function MotorSoundConfiguratorDialog:onClickSwap(index)
    if self.vehicleData == nil then
        return
    end
    local layer = index > 1 and self:getShownSwapEngines()[index - 1] or nil
    -- engines are locked without own engine samples (review #23); "Own engine" still ends a leftover swap
    if index > 1 and (layer == nil or not self:canSwapEngine()) then
        return
    end
    self:endOriginalMode()

    local modelKey = self.vehicleData.modelKey
    if layer == nil or layer == MotorSoundConfigurator.getActiveSwap(modelKey) then
        -- also switches off an engine left over without a muted own engine ("Own engine" is green then)
        if MotorSoundConfigurator.hasSwapToRemove(modelKey) then
            MotorSoundConfigurator.removeSwap(self.vehicleData)
        end
    else
        MotorSoundConfigurator.applySwap(self.vehicleData, layer.name, MotorSoundConfigurator.SWAP_DEFAULT_VOLUME)
    end

    -- the "Sound" page then shows the engine volume of the model (0 %)
    self.scopeIndex = MotorSoundConfiguratorDialog.SCOPE_MODEL

    MotorSoundConfigurator.applyToAllVehicles()
    self:updateSwapPage()
    self:updateTabs()
end


function MotorSoundConfiguratorDialog:onSwapVolumeChanged()
    local slider = self.swapVolumeOption
    if slider == nil or self.vehicleData == nil then
        return
    end
    local activeLayer = MotorSoundConfigurator.getActiveSwap(self.vehicleData.modelKey)
    if activeLayer == nil then
        return
    end
    self:endOriginalMode()

    local volume = MotorSoundConfiguratorDialog.getLayerVolumeSteps()[slider:getState()]
    MotorSoundConfigurator.setModelLayer(self.vehicleData, activeLayer.name, volume)
    if self.swapVolumeValue ~= nil then
        self.swapVolumeValue:setText(MotorSoundConfiguratorDialog.formatPercent(volume))
    end
end


-- list toggle of the "Engine swap" page: base game / mods & DLCs (v1.1.0.0)
function MotorSoundConfiguratorDialog:setSwapView(view)
    if #MotorSoundConfiguratorDialog.getSwapViewEngines(view) == 0 then
        return
    end
    self.isSwapViewChosen = true
    if self.swapView ~= view then
        self.swapView = view
        self.swapPageIndex = 1
    end
    self:updateSwapPage()
    self:keepSwapFocus()
end


function MotorSoundConfiguratorDialog:onClickSwapViewBase()
    self:setSwapView(MotorSoundConfiguratorDialog.SWAP_VIEW_BASE)
end


function MotorSoundConfiguratorDialog:onClickSwapViewMod()
    self:setSwapView(MotorSoundConfiguratorDialog.SWAP_VIEW_MOD)
end


function MotorSoundConfiguratorDialog:onClickSwapViewOther()
    self:setSwapView(MotorSoundConfiguratorDialog.SWAP_VIEW_OTHER)
end


-- previous / next page of the mod list, wraps around; buttons "<" / ">", LT / RT and Page up / down (inputEvent)
function MotorSoundConfiguratorDialog:changeSwapPage(step)
    if self.swapView == MotorSoundConfiguratorDialog.SWAP_VIEW_BASE then
        return false
    end
    local pageCount = MotorSoundConfiguratorDialog.getSwapPageCount(self.swapView)
    if pageCount <= 1 then
        return false
    end
    self.swapPageIndex = (self.swapPageIndex - 1 + step) % pageCount + 1
    self:updateSwapPage()
    self:keepSwapFocus()
    return true
end


function MotorSoundConfiguratorDialog:onClickSwapPagePrev()
    self:changeSwapPage(-1)
end


function MotorSoundConfiguratorDialog:onClickSwapPageNext()
    self:changeSwapPage(1)
end


-- the focused engine button may be hidden on the new page (fewer engines): focus "Own engine"
function MotorSoundConfiguratorDialog:keepSwapFocus()
    local focused = FocusManager:getFocusedElement()
    if self.swapButton1 ~= nil and (focused == nil or not focused:getIsVisible() or focused:getIsDisabled()) then
        FocusManager:setFocus(self.swapButton1)
    end
end


-- "Remove" next to the hint on missing mod / DLC engines: their entries go, a swap with one of them ends
function MotorSoundConfiguratorDialog:onClickSwapRemoveMissing()
    if self.vehicleData == nil then
        return
    end
    self:endOriginalMode()
    if MotorSoundConfigurator.removeMissingModEngines(self.vehicleData) then
        MotorSoundConfigurator.applyToAllVehicles()
    end
    self:updateSwapPage()
    self:updateTabs()
    self:keepSwapFocus()
end


-- the XML binds callbacks by name at load time, so they must exist before loadGui
for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
    for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
        local categoryName = category
        local parameterName = parameter.name
        MotorSoundConfiguratorDialog["onChanged_" .. categoryName .. "_" .. parameterName] = function(self)
            self:onSoundValueChanged(categoryName, parameterName)
        end
    end
end
for blockIndex, block in ipairs(MotorSoundConfiguratorDialog.TABLE_BLOCKS) do
    for row = 1, MotorSoundConfiguratorDialog.TABLE_ROWS do
        for cellIndex, _ in ipairs(block.cells) do
            local blockNumber, rowIndex, cellNumber = blockIndex, row, cellIndex
            MotorSoundConfiguratorDialog["onTableChanged_" .. blockNumber .. "_" .. rowIndex .. "_" .. cellNumber] = function(self)
                self:onTableValueChanged(blockNumber, rowIndex, cellNumber)
            end
        end
    end
end
for row = 1, MotorSoundConfiguratorDialog.LAYER_ROWS do
    local rowIndex = row
    MotorSoundConfiguratorDialog["onLayerChoiceChanged_" .. rowIndex] = function(self)
        self:onLayerChoiceChanged(rowIndex)
    end
    MotorSoundConfiguratorDialog["onLayerVolumeChanged_" .. rowIndex] = function(self)
        self:onLayerVolumeChanged(rowIndex)
    end
end
for index = 1, MotorSoundConfiguratorDialog.PRESET_BUTTONS do
    local presetIndex = index
    MotorSoundConfiguratorDialog["onClickPreset_" .. presetIndex] = function(self)
        self:onClickPreset(presetIndex)
    end
end
for index = 1, MotorSoundConfiguratorDialog.SWAP_BUTTONS do
    local swapIndex = index
    MotorSoundConfiguratorDialog["onClickSwap_" .. swapIndex] = function(self)
        self:onClickSwap(swapIndex)
    end
end


-- "Reset": the current tab only; "Sound" / "Filter" the parameters of that page in the current scope (all
-- categories), "Extra sounds" all layers of the model; on "Presets" the same as "Reset model" (presets set values on
-- the other tabs, user 2026-10-02); on "Engine swap" back to the own engine
function MotorSoundConfiguratorDialog:onClickReset()
    if self.page == MotorSoundConfiguratorDialog.PAGE_PRESETS then
        self:onClickResetAll()
        return
    end
    self:endOriginalMode()
    if self.page == MotorSoundConfiguratorDialog.PAGE_SWAP then
        if self.vehicleData ~= nil and MotorSoundConfigurator.hasSwapToRemove(self.vehicleData.modelKey) then
            MotorSoundConfigurator.removeSwap(self.vehicleData)
            MotorSoundConfigurator.applyToAllVehicles()
        end
    elseif self.page == MotorSoundConfiguratorDialog.PAGE_LAYERS then
        if self.vehicleData ~= nil then
            local hadSwapEngine = MotorSoundConfigurator.hasSwapEngine(self.vehicleData.modelKey)
            MotorSoundConfigurator.resetModelLayers(self.vehicleData.modelKey)
            -- also removes the engine of a swap: the own engine comes back from 0 % (review #18)
            if hadSwapEngine and MotorSoundConfigurator.endSwapWithoutEngine(self.vehicleData) then
                MotorSoundConfigurator.applyToAllVehicles()
            end
        end
    else
        local isModelScope = self:isModelScope()
        if not isModelScope or self.vehicleData ~= nil then
            for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
                local isVolumeOnly = MotorSoundConfigurator.isVolumeOnlyCategory(category)
                -- "Sound" = engine and transmission, "Other sounds" = cabin, rattle, work and implement volumes (v0.19.0.0)
                local isOther = MotorSoundConfiguratorDialog.OTHER_CATEGORIES[category] == true
                local isOnPage = self.page == MotorSoundConfiguratorDialog.PAGE_FILTER
                    or (self.page == MotorSoundConfiguratorDialog.PAGE_OTHER) == isOther
                for _, parameterName in ipairs(MotorSoundConfiguratorDialog.PAGE_PARAMETERS[self.page]) do
                    -- work / discharge: only their volume exists (review #34)
                    if isOnPage and (not isVolumeOnly or parameterName == "volume") then
                        if isModelScope then
                            -- nil = back to the global value
                            MotorSoundConfigurator.setModelValue(self.vehicleData, category, parameterName, nil)
                        else
                            MotorSoundConfigurator.setGlobalValue(category, parameterName, 1.0)
                        end
                    end
                end
            end
            -- "This model only" on "Other sounds": also the values of all attached trailer / implement models
            if isModelScope and self.page == MotorSoundConfiguratorDialog.PAGE_OTHER then
                for _, data in ipairs(MotorSoundConfigurator.getAttachedImplementData(self:getVehicle())) do
                    for _, category in ipairs(MotorSoundConfigurator.IMPLEMENT_CATEGORIES) do
                        MotorSoundConfigurator.setModelValue(data, category, "volume", nil)
                    end
                end
            end
        end
        MotorSoundConfigurator.applyToAllVehicles()
    end
    self:updatePage()
end


-- "Reset model" (resetAll): everything of the current vehicle model (values of both categories and all extra
-- sounds), after a question; global values stay (user 2026-10-02)
function MotorSoundConfiguratorDialog:onClickResetAll()
    if self.vehicleData == nil then
        return
    end
    local text = string.format(g_i18n:getText("msc_resetAll_question"), tostring(self.vehicleData.name))
    YesNoDialog.show(self.onResetAllAnswer, self, text)
end


function MotorSoundConfiguratorDialog:onResetAllAnswer(yes)
    if yes and self.vehicleData ~= nil then
        self:endOriginalMode()
        -- also detaches the layers of the loaded vehicles of this model
        MotorSoundConfigurator.resetModel(self.vehicleData.modelKey, nil)
        MotorSoundConfigurator.applyToAllVehicles()
        self:updatePage()
    end
end


-- "Cancel" (also Esc): if something changed since the dialog was opened, asks "Apply changes?" (user 2026-10-02:
-- yes = save, no = discard, both close; Esc in the question = no); without changes it closes at once
function MotorSoundConfiguratorDialog:onClickCancel()
    if self.isClosePending then
        return
    end
    if self.settingsCopy ~= nil and MotorSoundConfigurator.hasSettingsChanged(self.settingsCopy) then
        YesNoDialog.show(self.onApplyAnswer, self, g_i18n:getText("msc_apply_question"))
        return
    end
    self.isCancelled = true
    self:close()
end


-- yes = keep the changes (saved by the close callback), no = restore the snapshot
function MotorSoundConfiguratorDialog:onApplyAnswer(yes)
    -- set before the check: if the vehicle was deleted while the question was open (closing already pending), an
    -- explicit "No" still discards the changes (review #30, user 2026-10-12)
    self.isCancelled = not yes
    if self.isClosePending then
        return
    end
    self:closeDeferred()
end


-- the question dialog may still be on the GUI stack while its callback runs (not visible in the RAW sources), so
-- closing is deferred by a few frames with a mission updateable, as RepairDialog:onPayCashConfirmed in the UsedPlus
-- mod does (Gui:update iterates the open dialogs with pairs, so the dialog's own update() is not used for it).
-- It also waits while another dialog lies on top: Gui:closeDialog reverts the input context of the topmost dialog
-- (RAW base/Gui.lua closeDialog / showDialog), so only the top dialog may be closed.
function MotorSoundConfiguratorDialog:closeDeferred()
    if self.isClosePending then
        return
    end
    self.isClosePending = true

    local dialog = self
    g_currentMission:addUpdateable({
        frameWait = MotorSoundConfiguratorDialog.CLOSE_FRAME_WAIT,
        update = function(updateable, dt)
            updateable.frameWait = updateable.frameWait - 1
            if not dialog.isClosePending then
                -- closed meanwhile
                g_currentMission:removeUpdateable(updateable)
                return
            end
            local gui = g_gui.guis[MotorSoundConfiguratorDialog.NAME]
            if updateable.frameWait > 0 or (gui ~= nil and g_gui.currentListener ~= gui) then
                return
            end
            g_currentMission:removeUpdateable(updateable)
            dialog:close()
        end
    })
end


-- the vehicle of the open dialog was deleted (e.g. sold or reset by another player in multiplayer): the dialog lets
-- go of it at once and closes like "Apply" (changes of the model and global values stay), after a question on top
-- of it was answered
function MotorSoundConfiguratorDialog.onVehicleDeleted(vehicle)
    local gui = g_gui ~= nil and g_gui.guis[MotorSoundConfiguratorDialog.NAME] or nil
    local dialog = gui ~= nil and gui.target or nil
    if dialog == nil or vehicle == nil or dialog:getVehicle() ~= vehicle then
        return
    end
    MotorSoundConfigurator.logWarning("the vehicle of the open dialog was deleted, the dialog closes (changes kept unless discarded in the question)")
    dialog.vehicleData = nil
    -- a close already decided ("No" in the question) keeps its answer
    if not dialog.isClosePending then
        dialog.isCancelled = false
    end
    dialog:closeDeferred()
end


-- settings from when the open dialog was opened (not applied yet), nil if the dialog is closed: settingsCopy is set
-- in setVehicleData and cleared in onMscDialogClose (savegame save while the dialog is open, review #21)
function MotorSoundConfiguratorDialog.getOpenSettingsCopy()
    local gui = g_gui ~= nil and g_gui.guis[MotorSoundConfiguratorDialog.NAME] or nil
    local dialog = gui ~= nil and gui.target or nil
    return dialog ~= nil and dialog.settingsCopy or nil
end


-- Esc / back: same as "Cancel" (DialogElement:onClickBack would close and the close callback would save)
function MotorSoundConfiguratorDialog:onClickBack()
    self:onClickCancel()
    return false
end


function MotorSoundConfiguratorDialog:onClickApply()
    self.isCancelled = false
    self:close()
end
