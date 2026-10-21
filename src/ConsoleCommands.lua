-- Motor Sound Configurator: console commands (testing and advanced use)
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).

---------------------------------------------------------------------------
-- Console commands (for testing without restarting the game)
---------------------------------------------------------------------------

function MotorSoundConfigurator.getCurrentVehicleData()
    local vehicle = g_localPlayer ~= nil and g_localPlayer:getCurrentVehicle() or nil
    if vehicle == nil then
        return nil, "Enter a vehicle first"
    end

    local data = MotorSoundConfigurator.vehicleData[vehicle]
    if data == nil then
        return nil, string.format("No adjusted samples for %s", tostring(MotorSoundConfigurator.getModelKey(vehicle)))
    end
    return data, nil, vehicle
end


-- mscLayer <name> [volume|remove]: attaches / removes a catalog layer for the model of the entered vehicle (saved)
function MotorSoundConfigurator:consoleCommandLayer(layerName, arg)
    local data, err = MotorSoundConfigurator.getCurrentVehicleData()
    if data == nil then
        return err
    end

    -- an engine whose mod / DLC is missing can still be removed (review 2026-10-20)
    local isMissingRemove = arg == "remove" and MotorSoundConfigurator.isModEngineMissing(layerName)
    if layerName == nil or (MotorSoundConfigurator.getCatalogLayer(layerName) == nil and not isMissingRemove) then
        local groupTexts = {}
        for _, group in ipairs(MotorSoundConfigurator.getLayerGroups()) do
            local names = {}
            -- mod / DLC engines can be many: only their count and the name form
            if group.name == MotorSoundConfigurator.MOD_ENGINE_GROUP then
                table.insert(names, string.format("%d engines, %s<donor vehicle key>", #group.layers, MotorSoundConfigurator.MOD_ENGINE_PREFIX))
            else
                for _, layer in ipairs(group.layers) do
                    table.insert(names, layer.name)
                end
            end
            table.insert(groupTexts, string.format("%s: %s", group.name, table.concat(names, ", ")))
        end
        return string.format("Usage: mscLayer <name> [volume|remove]   layers by group: %s", table.concat(groupTexts, " | "))
    end

    local volume = nil
    if arg ~= "remove" then
        volume = tonumber(arg) or 1.0
    end

    -- attaching replaces the other sounds of the group (one sound per group, as in the dialog)
    local setLayer = volume ~= nil and MotorSoundConfigurator.setGroupLayer or MotorSoundConfigurator.setModelLayer
    setLayer(data, layerName, volume)
    -- removing the engine of a swap brings the own engine back from 0 % (as in the dialog, review #18)
    if volume == nil and MotorSoundConfigurator.isSwapGroup(MotorSoundConfigurator.getLayerGroupName(layerName))
        and MotorSoundConfigurator.endSwapWithoutEngine(data) then
        MotorSoundConfigurator.applyToAllVehicles()
    end
    MotorSoundConfigurator.saveSettings(MotorSoundConfigurator.getSettings())
    return string.format("%s: layer %s %s", data.name, layerName, volume ~= nil and string.format("volume %.2f", volume) or "removed")
end


-- sets one factor in target (global or model table); returns error text or nil
-- accepts <parameter> <factor> or the short form <volume> [pitch]; volume-only categories (rattle, work, discharge) only accept the volume
function MotorSoundConfigurator.setValues(target, arg1, arg2, category)
    local isVolumeOnly = MotorSoundConfigurator.isVolumeOnlyCategory(category)
    local shortVolume = tonumber(arg1)
    if shortVolume ~= nil then
        local pitch = tonumber(arg2)
        if pitch ~= nil and isVolumeOnly then
            return "volume only"
        end
        target.volume = shortVolume
        if pitch ~= nil then
            target.pitch = pitch
        end
    else
        local parameter = MotorSoundConfigurator.getParameter(arg1)
        local factor = tonumber(arg2)
        if parameter == nil or factor == nil or (isVolumeOnly and parameter.name ~= "volume") then
            return "invalid parameter or factor"
        end
        target[parameter.name] = factor
    end

    MotorSoundConfigurator.clampValues(target)
    return nil
end


function MotorSoundConfigurator:consoleCommandReload()
    MotorSoundConfigurator.loadSettings()
    -- layers of the reloaded file attached / detached, factors applied
    MotorSoundConfigurator.syncAllVehicles()
    local count = 0
    for _, _ in pairs(MotorSoundConfigurator.vehicleData) do
        count = count + 1
    end
    return string.format("Reloaded settings, applied to %d vehicles", count)
end


-- mscDebug: details per vehicle, layer and model in the log on / off (not saved)
function MotorSoundConfigurator:consoleCommandDebug()
    MotorSoundConfigurator.debug = not MotorSoundConfigurator.debug
    if MotorSoundConfigurator.debug and MotorSoundConfigurator.settings ~= nil then
        MotorSoundConfigurator.logSettings()
    end
    return string.format("Debug log %s", MotorSoundConfigurator.debug and "on" or "off")
end


MotorSoundConfigurator.SET_USAGE = "Usage: mscSet motor|gearbox|cabin|rattle|work|discharge|implementWork|implementDrive|implementRattle <parameter> <factor>"
    .. "   parameter: volume|pitch|cutoffIndoor|cutoffOutdoor|gainIndoor|gainOutdoor|indoorDamping|rpm (rattle / work / discharge / implement*: volume only), 1.0 = unchanged"
    .. "   (short form: mscSet <category> <volume> [pitch])"


-- implement categories belong to the model of the implement, not of the entered vehicle (review #52)
function MotorSoundConfigurator.isImplementCategory(category)
    for _, implementCategory in ipairs(MotorSoundConfigurator.IMPLEMENT_CATEGORIES) do
        if implementCategory == category then
            return true
        end
    end
    return false
end


MotorSoundConfigurator.IMPLEMENT_MODEL_HINT = "implementWork / implementDrive / implementRattle belong to the implement or trailer model:"
    .. " set them in the dialog (tab 'Other sounds') or globally with mscSet"


-- mscSet <category> <parameter> <factor>: global factor for all vehicles
function MotorSoundConfigurator:consoleCommandSet(category, arg1, arg2)
    if not MotorSoundConfigurator.isCategory(category) or arg1 == nil then
        return MotorSoundConfigurator.SET_USAGE
    end

    local settings = MotorSoundConfigurator.getSettings()
    local values = settings.global[category]
    if MotorSoundConfigurator.setValues(values, arg1, arg2, category) ~= nil then
        return MotorSoundConfigurator.SET_USAGE
    end

    MotorSoundConfigurator.saveSettings(settings)
    local count = MotorSoundConfigurator.applyToAllVehicles()
    return string.format("global %s: %s, applied to %d vehicles", category, MotorSoundConfigurator.formatValues(values), count)
end


MotorSoundConfigurator.SET_VEHICLE_USAGE = "Usage: mscSetVehicle motor|gearbox|cabin|rattle|work|discharge <parameter> <factor>   sets a factor for the model of the entered vehicle"


-- mscSetVehicle <category> <parameter> <factor>: override for the model of the entered vehicle
function MotorSoundConfigurator:consoleCommandSetVehicle(category, arg1, arg2)
    if MotorSoundConfigurator.isImplementCategory(category) then
        return MotorSoundConfigurator.IMPLEMENT_MODEL_HINT
    end
    if not MotorSoundConfigurator.isCategory(category) or arg1 == nil then
        return MotorSoundConfigurator.SET_VEHICLE_USAGE
    end

    local data, err = MotorSoundConfigurator.getCurrentVehicleData()
    if data == nil then
        return err
    end

    local values = {}
    if MotorSoundConfigurator.setValues(values, arg1, arg2, category) ~= nil then
        return MotorSoundConfigurator.SET_VEHICLE_USAGE
    end
    for parameterName, factor in pairs(values) do
        MotorSoundConfigurator.setModelValue(data, category, parameterName, factor)
    end

    MotorSoundConfigurator.saveSettings(MotorSoundConfigurator.getSettings())
    local count = MotorSoundConfigurator.applyToAllVehicles()
    return string.format("%s %s: %s, applied to %d vehicles", data.name, category,
        MotorSoundConfigurator.formatValues(MotorSoundConfigurator.getModelValues(data.modelKey, category) or {}), count)
end


-- mscResetVehicle [category]: removes the overrides of the entered vehicle's model (all or one category)
function MotorSoundConfigurator:consoleCommandResetVehicle(category)
    local data, err = MotorSoundConfigurator.getCurrentVehicleData()
    if data == nil then
        return err
    end
    if MotorSoundConfigurator.isImplementCategory(category) then
        return MotorSoundConfigurator.IMPLEMENT_MODEL_HINT
    end
    if category ~= nil and not MotorSoundConfigurator.isCategory(category) then
        return "Usage: mscResetVehicle [motor|gearbox|cabin|rattle|work|discharge]"
    end

    MotorSoundConfigurator.resetModel(data.modelKey, category)

    MotorSoundConfigurator.saveSettings(MotorSoundConfigurator.getSettings())
    MotorSoundConfigurator.applyToAllVehicles()
    return string.format("%s: overrides removed (%s), global factors apply", data.name, category or "all")
end


-- logs effective factors and current sound attributes of all adjusted samples of the entered vehicle
function MotorSoundConfigurator:consoleCommandInfo()
    local data, err = MotorSoundConfigurator.getCurrentVehicleData()
    if data == nil then
        return err
    end

    MotorSoundConfigurator.log("%s [%s] (sound manager indoor: %s)", data.name, tostring(data.modelKey), tostring(g_soundManager.isIndoor))
    -- rpm the motor samples get (Motorized:onUpdate maps getMotorRpmReal into minRpm .. maxRpm, Motorized.lua:947-950)
    local motor = data.vehicle.spec_motorized ~= nil and data.vehicle.spec_motorized.motor or nil
    if motor ~= nil then
        MotorSoundConfigurator.log("  motor: rpm %.0f (min %.0f, max %.0f), load %.2f, motor state %s", data.vehicle:getMotorRpmReal(),
            motor.minRpm or 0, motor.maxRpm or 0, data.vehicle:getMotorLoadPercentage(), tostring(data.vehicle:getMotorState()))
    end
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        local factors, override = MotorSoundConfigurator.getFactors(data.modelKey, category)
        MotorSoundConfigurator.log("  %s factors: %s | model overrides: %s", category,
            MotorSoundConfigurator.formatValues(factors), override ~= nil and MotorSoundConfigurator.formatValues(override) or "-")
    end

    for _, entry in ipairs(data.entries) do
        local sample = entry.sample
        local indoor = sample.indoorAttributes or {}
        local outdoor = sample.outdoorAttributes or {}
        -- volume played right now: volume modifier (rpm / load / speed curves) x current volume, as SoundManager:playSample
        -- passes it (SoundManager.lua:1186 / 1386 / 1471)
        local currentVolume = 0
        if sample.current ~= nil and sample.offsets ~= nil then
            currentVolume = g_soundManager:getModifierFactor(sample, "volume") * g_soundManager:getCurrentSampleVolume(sample)
        end
        MotorSoundConfigurator.log("  %s %s (playing: %s, volume now %.2f%s): volumeScale %.2f pitchScale %.2f rpmRatio %.2f lowpassGainScale %.2f"
            .. " | indoor: cutoff %.0f gain %.2f resonance %.2f | outdoor: cutoff %.0f gain %.2f resonance %.2f",
            entry.category, MotorSoundConfigurator.getSampleLabel(sample), tostring(g_soundManager:getIsSamplePlaying(sample)),
            currentVolume, entry.isLayer and ", layer" or "",
            sample.volumeScale or 0, sample.pitchScale or 0, sample.loopSynthesisRPMRatio or 0, sample.lowpassGainScale or 0,
            indoor.lowpassCutoffFrequency or 0, indoor.lowpassGain or 0, indoor.lowpassResonance or 0,
            outdoor.lowpassCutoffFrequency or 0, outdoor.lowpassGain or 0, outdoor.lowpassResonance or 0)
    end

    local otherCount = MotorSoundConfigurator.logOtherSamples(data)
    local implementCount = MotorSoundConfigurator.logImplementSamples(data.vehicle)
    return string.format("Logged %d adjusted and %d other samples, %d implement samples", #data.entries, otherCount, implementCount)
end


-- adjusted work sounds of the attached implements (v0.19.0.0): model, factors and every sample with its volumeScale.
-- Returns the number of logged samples
function MotorSoundConfigurator.logImplementSamples(vehicle)
    local count = 0
    for _, data in ipairs(MotorSoundConfigurator.getAttachedImplementData(vehicle)) do
        MotorSoundConfigurator.log("  implement %s [%s]", tostring(data.name), tostring(data.modelKey))
        for _, category in ipairs(MotorSoundConfigurator.IMPLEMENT_CATEGORIES) do
            local factors, override = MotorSoundConfigurator.getFactors(data.modelKey, category)
            MotorSoundConfigurator.log("    %s volume %.2f%s", category, factors.volume, override ~= nil and override.volume ~= nil and " (model)" or "")
        end
        for _, entry in ipairs(data.entries) do
            local sample = entry.sample
            MotorSoundConfigurator.log("    %s %s (playing: %s): volumeScale %.2f (original %.2f)", entry.category,
                MotorSoundConfigurator.getSampleLabel(sample), tostring(g_soundManager:getIsSamplePlaying(sample)),
                sample.volumeScale or 0, entry.volumeScale)
            count = count + 1
        end
    end
    return count
end


-- depth limit of the walk over the spec tables (Combine: spec_combine.samples.work = depth 2, configuration
-- entries one or two levels deeper)
MotorSoundConfigurator.SAMPLE_PATH_MAX_DEPTH = 6


-- remembers the first table path (e.g. spec_combine.samples.chopperWork) of every registered sample below value.
-- A sample is a table registered in g_soundManager.samples (SoundManager:loadSampleFromXML / cloneSample:
-- self.samples[sample] = sample); tables with a metatable (vehicles, motor, other class instances) are not entered
function MotorSoundConfigurator.collectSamplePaths(value, path, depth, paths, visited)
    if visited[value] or depth > MotorSoundConfigurator.SAMPLE_PATH_MAX_DEPTH then
        return
    end
    visited[value] = true
    if MotorSoundConfigurator.isSoundSample(value) then
        paths[value] = path
        return
    end
    if depth > 0 and getmetatable(value) ~= nil then
        return
    end
    for key, child in pairs(value) do
        if type(child) == "table" then
            MotorSoundConfigurator.collectSamplePaths(child, path .. "." .. tostring(key), depth + 1, paths, visited)
        end
    end
end


-- logs all samples of the entered vehicle itself that are not adjusted (work sounds of combines and forage
-- harvesters, pipe, fans, animations ...), attached implements excluded. Sources: samples with the vehicle as
-- modifierTargetObject (set by loadSampleFromXML / cloneSample) plus samples found in the spec_* tables of the
-- vehicle (also those loaded without modifierTargetObject). Returns the number of logged samples
function MotorSoundConfigurator.logOtherSamples(data)
    local vehicle = data.vehicle
    if g_soundManager == nil or g_soundManager.samples == nil then
        MotorSoundConfigurator.log("  other samples: sound manager has no sample list")
        return 0
    end

    local adjusted = {}
    for _, entry in ipairs(data.entries) do
        adjusted[entry.sample] = true
    end

    local paths = {}
    local visited = {}
    for key, value in pairs(vehicle) do
        if type(key) == "string" and string.startsWith(key, "spec_") and type(value) == "table" then
            MotorSoundConfigurator.collectSamplePaths(value, key, 0, paths, visited)
        end
    end

    -- orderedSamples keeps the load order (stable output), samples only found by the walk follow
    local samples = {}
    local isListed = {}
    for _, sample in ipairs(g_soundManager.orderedSamples or {}) do
        if (sample.modifierTargetObject == vehicle or paths[sample] ~= nil) and not isListed[sample] then
            table.insert(samples, sample)
            isListed[sample] = true
        end
    end
    for sample, _ in pairs(paths) do
        if not isListed[sample] then
            table.insert(samples, sample)
            isListed[sample] = true
        end
    end

    local count = 0
    MotorSoundConfigurator.log("  other samples of the vehicle (not adjusted, implements excluded):")
    for _, sample in ipairs(samples) do
        if not adjusted[sample] then
            local indoor = sample.indoorAttributes or {}
            local outdoor = sample.outdoorAttributes or {}
            MotorSoundConfigurator.log("  - %s [%s] %s (playing: %s, loops %s): volumeScale %.2f pitchScale %.2f"
                .. " | indoor: cutoff %.0f gain %.2f | outdoor: cutoff %.0f gain %.2f | file %s",
                paths[sample] or "?", tostring(sample.sampleName), tostring(sample.templateName or "-"),
                tostring(g_soundManager:getIsSamplePlaying(sample)), tostring(sample.loops),
                sample.volumeScale or 0, sample.pitchScale or 0,
                indoor.lowpassCutoffFrequency or 0, indoor.lowpassGain or 0,
                outdoor.lowpassCutoffFrequency or 0, outdoor.lowpassGain or 0,
                tostring(sample.filename))
            count = count + 1
        end
    end
    if count == 0 then
        MotorSoundConfigurator.log("  - none")
    end
    return count
end


-- registered in loadMap, removed in deleteMap (src/main.lua)
MotorSoundConfigurator.CONSOLE_COMMANDS = {
    { "mscReload", "Reloads the settings file (savegame or modSettings) and applies it", "consoleCommandReload" },
    { "mscSet", "Sets a global factor (volume, pitch, rpm, cutoffIndoor, cutoffOutdoor, gainIndoor, gainOutdoor, indoorDamping) for motor, gearbox,"
      .. " cabin & fan, rattle, work, discharge or implement sounds (all but motor / gearbox / cabin: volume only)",
      "consoleCommandSet", "motor|gearbox|cabin|rattle|work|discharge|implementWork|implementDrive|implementRattle; parameter; factor" },
    { "mscSetVehicle", "Sets a factor for the model of the entered vehicle (overrides the global factor)", "consoleCommandSetVehicle",
      "motor|gearbox|cabin|rattle|work|discharge; parameter; factor" },
    { "mscResetVehicle", "Removes the overrides of the entered vehicle's model", "consoleCommandResetVehicle", "[motor|gearbox|cabin|rattle|work|discharge]" },
    { "mscInfo", "Logs factors and sound attributes of the entered vehicle", "consoleCommandInfo" },
    { "mscLayer", "Attaches / removes a sound layer from sounds/layers.xml for the model of the entered vehicle", "consoleCommandLayer", "name; [volume|remove]" },
    { "mscDebug", "Switches the detailed log (vehicles, sounds, settings) on / off", "consoleCommandDebug" }
}


function MotorSoundConfigurator.registerConsoleCommands()
    for _, command in ipairs(MotorSoundConfigurator.CONSOLE_COMMANDS) do
        addConsoleCommand(command[1], command[2], command[3], MotorSoundConfigurator, command[4])
    end
end


function MotorSoundConfigurator.unregisterConsoleCommands()
    for _, command in ipairs(MotorSoundConfigurator.CONSOLE_COMMANDS) do
        removeConsoleCommand(command[1])
    end
end
