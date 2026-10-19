-- Motor Sound Configurator: settings
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- Global factors and per model overrides / layers, loaded from and saved to <savegame>/motorSoundConfigurator.xml
-- (multiplayer client: <profile>/modSettings/FS25_MotorSoundConfigurator/settings.xml, see getConfigPath).

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------

function MotorSoundConfigurator.getDefaultSettings()
    local settings = { global = {}, models = {} }
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        settings.global[category] = {}
        for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
            settings.global[category][parameter.name] = 1.0
        end
    end
    return settings
end



-- multiplayer client (not the host): no savegame directory, the settings go to the user profile
-- (g_currentMission:getIsServer / getIsClient as in FarmlandManager, LUADOC Economy/FarmlandManager.md)
function MotorSoundConfigurator.isMultiplayerClient()
    return g_currentMission ~= nil and g_currentMission.getIsServer ~= nil and not g_currentMission:getIsServer()
end


-- dedicated server: g_dedicatedServer is set there (created at startup, as used by FS25_AdditionalContracts hlUtils,
-- RealisticLivestock, parkVehicle); g_currentMission:getIsClient() is true on a dedicated server too (GPortal server
-- log 2026-10-12: isServer true, isClient true), so it cannot tell the dedicated server apart
function MotorSoundConfigurator.isDedicatedServer()
    return g_dedicatedServer ~= nil
end


-- false on a dedicated server (no player, no sound there, the mod does nothing)
function MotorSoundConfigurator.hasClient()
    if MotorSoundConfigurator.isDedicatedServer() then
        return false
    end
    return g_currentMission == nil or g_currentMission.getIsClient == nil or g_currentMission:getIsClient()
end


-- role of this game instance for the start line in the log (multiplayer test, docs/CODE_REVIEW.md #17); the raw
-- values follow in the log line, missionDynamicInfo.isMultiplayer as in FarmlandManager / PlaceableSystem
function MotorSoundConfigurator.getRoleText()
    if not MotorSoundConfigurator.hasClient() then
        return "dedicated server"
    elseif MotorSoundConfigurator.isMultiplayerClient() then
        return "multiplayer client"
    elseif MotorSoundConfigurator.isMultiplayer() then
        return "multiplayer host"
    end
    return "single player"
end


function MotorSoundConfigurator.isMultiplayer()
    local mission = g_currentMission
    return mission ~= nil and mission.missionDynamicInfo ~= nil and mission.missionDynamicInfo.isMultiplayer == true
end


-- one file for all multiplayer games (user 2026-10-02: the settings are per vehicle model and fit everywhere),
-- in <profile>/modSettings/ like other mods do (e.g. RealisticHarvesting client.xml, LumberJack, realDirtColor)
-- createDirectory: only when writing, so a player who never uses the mod gets no folder (review #39)
function MotorSoundConfigurator.getClientConfigPath(createDirectory)
    local modSettingsDirectory = getUserProfileAppPath() .. "modSettings/"
    local directory = modSettingsDirectory .. MotorSoundConfigurator.CLIENT_SETTINGS_DIRECTORY .. "/"
    if createDirectory then
        createFolder(modSettingsDirectory)
        createFolder(directory)
    end
    return directory .. MotorSoundConfigurator.CLIENT_SETTINGS_FILENAME
end


function MotorSoundConfigurator.getConfigPath(createDirectory)
    if MotorSoundConfigurator.isMultiplayerClient() then
        return MotorSoundConfigurator.getClientConfigPath(createDirectory)
    end
    if g_currentMission == nil or g_currentMission.missionInfo == nil then
        return nil
    end

    local directory = g_currentMission.missionInfo.savegameDirectory
    if directory == nil then
        return nil
    end

    return directory .. "/" .. MotorSoundConfigurator.CONFIG_FILENAME
end


-- clamps all factors present in values (global values are complete, model values partial)
function MotorSoundConfigurator.clampValues(values)
    for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
        if values[parameter.name] ~= nil then
            values[parameter.name] = math.clamp(values[parameter.name], parameter.min, parameter.max)
        end
    end
end


-- parameters that are read and written for a category: work / discharge only have their volume (the others are never
-- applied, review #34), all other categories all of PARAMETERS
function MotorSoundConfigurator.getStoredParameters(category)
    if MotorSoundConfigurator.isVolumeOnlyCategory(category) then
        return { MotorSoundConfigurator.getParameter("volume") }
    end
    return MotorSoundConfigurator.PARAMETERS
end


-- reads the factors of one category element; missing attributes keep the value from defaults (may be nil), as do
-- the parameters a volume-only category does not store
function MotorSoundConfigurator.loadValues(xmlFile, key, defaults, category)
    local values = {}
    for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
        values[parameter.name] = defaults ~= nil and defaults[parameter.name] or nil
    end
    for _, parameter in ipairs(MotorSoundConfigurator.getStoredParameters(category)) do
        values[parameter.name] = xmlFile:getFloat(key .. "#" .. parameter.name, values[parameter.name])
    end
    MotorSoundConfigurator.clampValues(values)
    return values
end


function MotorSoundConfigurator.saveValues(xmlFile, key, values, category)
    for _, parameter in ipairs(MotorSoundConfigurator.getStoredParameters(category)) do
        if type(values[parameter.name]) == "number" then
            xmlFile:setFloat(key .. "#" .. parameter.name, values[parameter.name])
        end
    end
end


function MotorSoundConfigurator.hasValues(values)
    return values ~= nil and next(values) ~= nil
end


function MotorSoundConfigurator.loadSettings()
    local settings = MotorSoundConfigurator.getDefaultSettings()
    local path = MotorSoundConfigurator.getConfigPath()

    if path == nil then
        MotorSoundConfigurator.log("No savegame directory yet (new savegame), using 100%%. %s is written when the game is saved", MotorSoundConfigurator.CONFIG_FILENAME)
    else
        local xmlFile = XMLFile.loadIfExists("motorSoundConfiguratorXML", path)
        if xmlFile ~= nil then
            local root = MotorSoundConfigurator.CONFIG_ROOT
            for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
                settings.global[category] = MotorSoundConfigurator.loadValues(xmlFile, root .. "." .. category, settings.global[category], category)
            end

            xmlFile:iterate(root .. ".vehicle", function(_, vehicleKey)
                local modelKey = xmlFile:getString(vehicleKey .. "#filename")
                if modelKey ~= nil and modelKey ~= "" then
                    local model = { name = xmlFile:getString(vehicleKey .. "#name") }
                    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
                        local values = MotorSoundConfigurator.loadValues(xmlFile, vehicleKey .. "." .. category, nil, category)
                        if MotorSoundConfigurator.hasValues(values) then
                            model[category] = values
                        end
                    end
                    -- <layer name="..." volume="1.0"/>: attached extra sounds of this model
                    xmlFile:iterate(vehicleKey .. ".layer", function(_, layerKey)
                        local layerName = xmlFile:getString(layerKey .. "#name")
                        -- layers removed from the catalog (e.g. the turbo group in v0.12.0.0 and again in v0.18.1.0) are dropped, the dialog
                        -- has no row to switch them off; the file is cleaned on the next save
                        if layerName ~= nil and layerName ~= "" and MotorSoundConfigurator.getCatalogLayer(layerName) == nil then
                            MotorSoundConfigurator.logWarning("layer '%s' is not in the catalog any more, removed from %s", layerName, modelKey)
                        elseif layerName ~= nil and layerName ~= "" then
                            model.layers = model.layers or {}
                            model.layers[layerName] = {
                                volume = math.clamp(xmlFile:getFloat(layerKey .. "#volume", 1.0), MotorSoundConfigurator.LAYER_VOLUME_MIN, MotorSoundConfigurator.LAYER_VOLUME_MAX)
                            }
                        end
                    end)
                    settings.models[modelKey] = model
                end
            end)

            xmlFile:delete()
            MotorSoundConfigurator.log("Loaded %s", path)
        elseif fileExists(path) then
            -- there but not readable (e.g. a broken write): said clearly, it is replaced by the next save (review #40)
            MotorSoundConfigurator.logError("Cannot read %s (broken file?), using 100%%. The file is replaced on the next save", path)
        else
            -- nothing written here: the file is created by the first "Apply" or savegame save (review 2026-10-03)
            MotorSoundConfigurator.log("No settings file yet (%s), using 100%%", path)
        end
    end

    MotorSoundConfigurator.settings = settings
    if MotorSoundConfigurator.debug then
        MotorSoundConfigurator.logSettings()
    end
end


-- structure check before writing: saveSettings also runs inside the game's savegame save, where an error must not
-- happen and no pcall is allowed (TestRunner, review 2026-10-12 #20). Returns an error text or nil
function MotorSoundConfigurator.getSettingsError(settings)
    if type(settings) ~= "table" or type(settings.global) ~= "table" or type(settings.models) ~= "table" then
        return "settings table incomplete"
    end
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        if type(settings.global[category]) ~= "table" then
            return string.format("global values of '%s' missing", category)
        end
    end
    for modelKey, model in pairs(settings.models) do
        if type(modelKey) ~= "string" or type(model) ~= "table" then
            return string.format("invalid model entry '%s'", tostring(modelKey))
        end
        for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
            if model[category] ~= nil and type(model[category]) ~= "table" then
                return string.format("invalid values of '%s' for %s", category, modelKey)
            end
        end
        if model.layers ~= nil then
            if type(model.layers) ~= "table" then
                return string.format("invalid layer list for %s", modelKey)
            end
            for layerName, layer in pairs(model.layers) do
                if type(layerName) ~= "string" or type(layer) ~= "table" or type(layer.volume) ~= "number" then
                    return string.format("invalid layer '%s' for %s", tostring(layerName), modelKey)
                end
            end
        end
    end
    return nil
end


-- path is optional, default is the current savegame directory (multiplayer client: modSettings, created here)
function MotorSoundConfigurator.saveSettings(settings, path)
    path = path or MotorSoundConfigurator.getConfigPath(true)
    if path == nil then
        MotorSoundConfigurator.log("No savegame directory yet, settings are kept until the game is saved")
        return false
    end

    -- checked before XMLFile.create, so an existing file is not replaced by a broken one
    local settingsError = MotorSoundConfigurator.getSettingsError(settings)
    if settingsError ~= nil then
        MotorSoundConfigurator.logError("settings not saved to %s: %s", path, settingsError)
        return false
    end

    local root = MotorSoundConfigurator.CONFIG_ROOT
    local xmlFile = XMLFile.create("motorSoundConfiguratorXML", path, root, nil)
    if xmlFile == nil then
        MotorSoundConfigurator.logError("Cannot create %s", path)
        return false
    end

    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        MotorSoundConfigurator.saveValues(xmlFile, root .. "." .. category, settings.global[category], category)
    end

    -- sorted so the file stays stable between saves
    local modelKeys = {}
    for modelKey, _ in pairs(settings.models) do
        table.insert(modelKeys, modelKey)
    end
    table.sort(modelKeys)

    local index = 0
    for _, modelKey in ipairs(modelKeys) do
        local model = settings.models[modelKey]
        local vehicleKey = string.format("%s.vehicle(%d)", root, index)
        xmlFile:setString(vehicleKey .. "#filename", modelKey)
        if model.name ~= nil then
            xmlFile:setString(vehicleKey .. "#name", tostring(model.name))
        end
        for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
            if MotorSoundConfigurator.hasValues(model[category]) then
                MotorSoundConfigurator.saveValues(xmlFile, vehicleKey .. "." .. category, model[category], category)
            end
        end
        if model.layers ~= nil then
            local layerNames = {}
            for layerName, _ in pairs(model.layers) do
                table.insert(layerNames, layerName)
            end
            table.sort(layerNames)
            for layerIndex, layerName in ipairs(layerNames) do
                local layerKey = string.format("%s.layer(%d)", vehicleKey, layerIndex - 1)
                xmlFile:setString(layerKey .. "#name", layerName)
                xmlFile:setFloat(layerKey .. "#volume", model.layers[layerName].volume)
            end
        end
        index = index + 1
    end

    xmlFile:save()
    xmlFile:delete()
    MotorSoundConfigurator.log("Saved %s", path)
    return true
end


function MotorSoundConfigurator.getSettings()
    if MotorSoundConfigurator.settings == nil then
        MotorSoundConfigurator.loadSettings()
    end
    return MotorSoundConfigurator.settings
end


-- effective factors of a category for a model: model override, otherwise global
function MotorSoundConfigurator.getFactors(modelKey, category)
    local settings = MotorSoundConfigurator.getSettings()
    local global = settings.global[category]
    local model = modelKey ~= nil and settings.models[modelKey] or nil
    local override = model ~= nil and model[category] or nil

    local factors = {}
    for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
        local value = override ~= nil and override[parameter.name] or nil
        factors[parameter.name] = value or global[parameter.name]
    end
    return factors, override
end


-- overridden factors of a model for one category, or nil
function MotorSoundConfigurator.getModelValues(modelKey, category)
    local model = modelKey ~= nil and MotorSoundConfigurator.getSettings().models[modelKey] or nil
    return model ~= nil and model[category] or nil
end


function MotorSoundConfigurator.setGlobalValue(category, parameterName, factor)
    local values = MotorSoundConfigurator.getSettings().global[category]
    values[parameterName] = factor
    MotorSoundConfigurator.clampValues(values)
end


-- factor nil removes the override; empty categories / models are removed as well
function MotorSoundConfigurator.setModelValue(vehicleData, category, parameterName, factor)
    local settings = MotorSoundConfigurator.getSettings()
    local model = settings.models[vehicleData.modelKey]

    if factor == nil then
        if model ~= nil and model[category] ~= nil then
            model[category][parameterName] = nil
            MotorSoundConfigurator.removeEmptyOverrides(vehicleData.modelKey)
        end
        return
    end

    if model == nil then
        model = {}
        settings.models[vehicleData.modelKey] = model
    end
    model.name = vehicleData.name
    model[category] = model[category] or {}
    model[category][parameterName] = factor
    MotorSoundConfigurator.clampValues(model[category])
end


function MotorSoundConfigurator.removeEmptyOverrides(modelKey)
    local settings = MotorSoundConfigurator.getSettings()
    local model = settings.models[modelKey]
    if model == nil then
        return
    end

    local hasOverrides = false
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        if MotorSoundConfigurator.hasValues(model[category]) then
            hasOverrides = true
        else
            model[category] = nil
        end
    end
    if MotorSoundConfigurator.hasValues(model.layers) then
        hasOverrides = true
    else
        model.layers = nil
    end
    if not hasOverrides then
        settings.models[modelKey] = nil
    end
end


-- category nil removes all overrides of the model
function MotorSoundConfigurator.resetModel(modelKey, category)
    local settings = MotorSoundConfigurator.getSettings()
    local model = settings.models[modelKey]
    if model == nil then
        return
    end

    if category == nil then
        settings.models[modelKey] = nil
        -- also removes the layers, detach them from loaded vehicles
        MotorSoundConfigurator.syncLayers(modelKey)
    else
        model[category] = nil
        MotorSoundConfigurator.removeEmptyOverrides(modelKey)
    end
end


-- model layer settings: { [layerName] = { volume = factor } }, nil if none
function MotorSoundConfigurator.getModelLayers(modelKey)
    local model = modelKey ~= nil and MotorSoundConfigurator.getSettings().models[modelKey] or nil
    return model ~= nil and model.layers or nil
end


-- volume nil detaches the layer; changes are applied to all loaded vehicles of this model (skipSync: the caller
-- syncs once after several changes)
function MotorSoundConfigurator.setModelLayer(vehicleData, layerName, volume, skipSync)
    local settings = MotorSoundConfigurator.getSettings()
    local model = settings.models[vehicleData.modelKey]

    if volume == nil then
        if model ~= nil and model.layers ~= nil then
            model.layers[layerName] = nil
            MotorSoundConfigurator.removeEmptyOverrides(vehicleData.modelKey)
        end
    else
        if model == nil then
            model = {}
            settings.models[vehicleData.modelKey] = model
        end
        model.name = vehicleData.name
        model.layers = model.layers or {}
        model.layers[layerName] = { volume = math.clamp(volume, MotorSoundConfigurator.LAYER_VOLUME_MIN, MotorSoundConfigurator.LAYER_VOLUME_MAX) }
    end

    if not skipSync then
        MotorSoundConfigurator.syncLayers(vehicleData.modelKey)
    end
end


-- switches off all layers of a catalog group for the model, except keepLayerName (may be nil); synced once at the
-- end unless skipSync (review #38)
function MotorSoundConfigurator.clearLayerGroup(vehicleData, groupName, keepLayerName, skipSync)
    local modelLayers = MotorSoundConfigurator.getModelLayers(vehicleData.modelKey)
    if modelLayers == nil then
        return
    end
    local isChanged = false
    for _, group in ipairs(MotorSoundConfigurator.getLayerGroups()) do
        if group.name == groupName then
            for _, layer in ipairs(group.layers) do
                -- read again: removing the last layer of the model removes its layer table (removeEmptyOverrides)
                local layers = MotorSoundConfigurator.getModelLayers(vehicleData.modelKey)
                if layer.name ~= keepLayerName and layers ~= nil and layers[layer.name] ~= nil then
                    MotorSoundConfigurator.setModelLayer(vehicleData, layer.name, nil, true)
                    isChanged = true
                end
            end
        end
    end
    if isChanged and not skipSync then
        MotorSoundConfigurator.syncLayers(vehicleData.modelKey)
    end
end


-- attaches a catalog layer as the only sound of its group (one sound per group: dialog, presets, mscLayer);
-- false if the layer is not in the catalog
function MotorSoundConfigurator.setGroupLayer(vehicleData, layerName, volume)
    local catalogLayer = MotorSoundConfigurator.getCatalogLayer(layerName)
    if catalogLayer == nil then
        return false
    end
    -- one sync for both changes (setModelLayer syncs)
    MotorSoundConfigurator.clearLayerGroup(vehicleData, catalogLayer.group, layerName, true)
    MotorSoundConfigurator.setModelLayer(vehicleData, layerName, volume)
    return true
end


-- layerNames: only these layers (e.g. one dialog group), nil = all layers of the model
function MotorSoundConfigurator.resetModelLayers(modelKey, layerNames)
    local model = MotorSoundConfigurator.getSettings().models[modelKey]
    if model ~= nil and model.layers ~= nil then
        if layerNames == nil then
            model.layers = nil
        else
            for _, layerName in ipairs(layerNames) do
                model.layers[layerName] = nil
            end
        end
        MotorSoundConfigurator.removeEmptyOverrides(modelKey)
    end
    MotorSoundConfigurator.syncLayers(modelKey)
end


-- deep copy of all settings (dialog: restored by "Cancel")
function MotorSoundConfigurator.copySettings()
    local settings = MotorSoundConfigurator.getSettings()
    return { global = table.clone(settings.global, math.huge), models = table.clone(settings.models, math.huge) }
end


-- puts a copy from copySettings back and applies it to all loaded vehicles (layers included)
function MotorSoundConfigurator.restoreSettings(copy)
    local settings = MotorSoundConfigurator.getSettings()
    settings.global = copy.global
    settings.models = copy.models
    MotorSoundConfigurator.syncAllVehicles()
end


-- deep comparison of settings tables; the display name of a model is ignored (written again on every change)
local function isSettingsValueEqual(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        if type(a) == "number" and type(b) == "number" then
            return math.abs(a - b) < 0.0001
        end
        return a == b
    end
    for key, value in pairs(a) do
        if key ~= "name" and not isSettingsValueEqual(value, b[key]) then
            return false
        end
    end
    for key, _ in pairs(b) do
        if key ~= "name" and a[key] == nil then
            return false
        end
    end
    return true
end


-- true if the current settings differ from a copy from copySettings (dialog: question before "Cancel")
function MotorSoundConfigurator.hasSettingsChanged(copy)
    local settings = MotorSoundConfigurator.getSettings()
    return not isSettingsValueEqual(settings.global, copy.global) or not isSettingsValueEqual(settings.models, copy.models)
end


function MotorSoundConfigurator.formatValues(values)
    local parts = {}
    for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
        if values[parameter.name] ~= nil then
            table.insert(parts, string.format("%s %.2f", parameter.name, values[parameter.name]))
        end
    end
    return #parts > 0 and table.concat(parts, " ") or "-"
end


function MotorSoundConfigurator.logSettings()
    local settings = MotorSoundConfigurator.settings
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        MotorSoundConfigurator.log("global %s: %s", category, MotorSoundConfigurator.formatValues(settings.global[category]))
    end
    for modelKey, model in pairs(settings.models) do
        for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
            if MotorSoundConfigurator.hasValues(model[category]) then
                MotorSoundConfigurator.log("model %s %s: %s", modelKey, category, MotorSoundConfigurator.formatValues(model[category]))
            end
        end
        if model.layers ~= nil then
            for layerName, layerSettings in pairs(model.layers) do
                MotorSoundConfigurator.log("model %s layer %s: volume %.2f", modelKey, layerName, layerSettings.volume)
            end
        end
    end
end
