-- Motor Sound Configurator: extra sound layers
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- Catalog sounds/layers.xml, engine class of a vehicle, attaching / detaching layers according to the settings.

---------------------------------------------------------------------------
-- Layers: additional samples from the catalog sounds/layers.xml, saved per model (settings.models[key].layers)
---------------------------------------------------------------------------

MotorSoundConfigurator.LAYER_FILENAME = "sounds/layers.xml"
MotorSoundConfigurator.LAYER_GROUP_DEFAULT = "other"
-- source="own": clone of the vehicle's own main engine sample instead of a sound file
MotorSoundConfigurator.LAYER_SOURCE_OWN = "own"

-- catalog: list of { name, index (0 based, "layers.layer(i)"), group, category, source, baseGameFile, shortName,
-- isOwn, pitchFactor, rpmFactor, volumeFactor }, loaded in loadMap
MotorSoundConfigurator.layerCatalog = {}
-- groups in catalog order: list of { name, layers = list of catalog layers }
MotorSoundConfigurator.layerGroups = {}
-- handle of sounds/layers.xml, open from loadLayerCatalog until deleteMap: every layer is loaded from it, so stepping
-- through the extra sounds does not open the file each time (review #26; the SoundManager keeps its
-- soundTemplateXMLFile open the same way, SoundManager.lua:104-131)
MotorSoundConfigurator.layerXmlFile = nil


-- the open catalog file, opened if needed; nil and the path if it cannot be opened
function MotorSoundConfigurator.getLayerXmlFile()
    if MotorSoundConfigurator.layerXmlFile == nil then
        local path = MotorSoundConfigurator.modDirectory .. MotorSoundConfigurator.LAYER_FILENAME
        local xmlFile = loadXMLFile("motorSoundConfiguratorLayers", path)
        if xmlFile == nil or xmlFile == 0 then
            return nil, path
        end
        MotorSoundConfigurator.layerXmlFile = xmlFile
    end
    return MotorSoundConfigurator.layerXmlFile
end


function MotorSoundConfigurator.closeLayerXmlFile()
    if MotorSoundConfigurator.layerXmlFile ~= nil then
        delete(MotorSoundConfigurator.layerXmlFile)
        MotorSoundConfigurator.layerXmlFile = nil
    end
end


function MotorSoundConfigurator.loadLayerCatalog()
    local catalog = {}
    local groups = {}
    local groupsByName = {}
    -- read fresh (e.g. after an edit of the file during development)
    MotorSoundConfigurator.closeLayerXmlFile()
    local xmlFile, path = MotorSoundConfigurator.getLayerXmlFile()
    if xmlFile == nil then
        MotorSoundConfigurator.logError("cannot open %s", path)
        MotorSoundConfigurator.layerCatalog = catalog
        MotorSoundConfigurator.layerGroups = groups
        return
    end

    local index = 0
    while true do
        local key = string.format("layers.layer(%d)", index)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local name = getXMLString(xmlFile, key .. "#name")
        if name ~= nil and name ~= "" then
            local source = getXMLString(xmlFile, key .. "#source")
            local layer = {
                name = name,
                index = index,
                group = getXMLString(xmlFile, key .. "#group") or MotorSoundConfigurator.LAYER_GROUP_DEFAULT,
                -- nil: from the template / file name like the vehicle's own samples
                category = getXMLString(xmlFile, key .. "#category"),
                source = source,
                -- base game sound without source vehicle: file / template name, shown as "base game (...)"
                baseGameFile = getXMLString(xmlFile, key .. "#baseGameFile"),
                -- button text on the "Engine swap" tab (group "engine")
                shortName = getXMLString(xmlFile, key .. "#shortName"),
                isOwn = source == MotorSoundConfigurator.LAYER_SOURCE_OWN,
                pitchFactor = getXMLFloat(xmlFile, key .. "#pitchFactor") or 1.0,
                rpmFactor = getXMLFloat(xmlFile, key .. "#rpmFactor") or 1.0,
                volumeFactor = getXMLFloat(xmlFile, key .. "#volumeFactor") or 1.0,
                -- uses the SUSPENSION modifier, only for vehicles with spec_suspensions (see addLayer)
                needsSuspension = getXMLBool(xmlFile, key .. "#needsSuspension") == true
            }
            if layer.category ~= nil and not MotorSoundConfigurator.isCategory(layer.category) then
                MotorSoundConfigurator.logWarning("layer '%s' has unknown category '%s', using the template", name, layer.category)
                layer.category = nil
            end
            table.insert(catalog, layer)

            local group = groupsByName[layer.group]
            if group == nil then
                group = { name = layer.group, layers = {} }
                groupsByName[layer.group] = group
                table.insert(groups, group)
            end
            table.insert(group.layers, layer)
        end
        index = index + 1
    end
    -- the file stays open for addLayer (closed in deleteMap)

    MotorSoundConfigurator.layerCatalog = catalog
    MotorSoundConfigurator.layerGroups = groups
    -- sorted list of the engine swap tab, built again from the new catalog (EngineSwap.lua)
    MotorSoundConfigurator.swapEngines = nil
    MotorSoundConfigurator.log("Layer catalog: %d layers in %d groups", #catalog, #groups)
end


function MotorSoundConfigurator.getLayerGroups()
    -- normally loaded in loadMap
    if #MotorSoundConfigurator.layerCatalog == 0 then
        MotorSoundConfigurator.loadLayerCatalog()
    end
    return MotorSoundConfigurator.layerGroups
end


function MotorSoundConfigurator.getCatalogLayer(layerName)
    -- normally loaded in loadMap; vehicles loading earlier would find it empty
    if #MotorSoundConfigurator.layerCatalog == 0 then
        MotorSoundConfigurator.loadLayerCatalog()
    end
    for _, layer in ipairs(MotorSoundConfigurator.layerCatalog) do
        if layer.name == layerName then
            return layer
        end
    end
    return nil
end


-- main engine sample of the vehicle (source of the "own engine" layers): the first own motor entry, preferring
-- an engine* template, then a loop synthesis (.gls) file; nil if the vehicle has no motor entry
function MotorSoundConfigurator.getOwnEngineEntry(data)
    local best = nil
    local bestScore = -1
    for _, entry in ipairs(data.entries) do
        if not entry.isLayer and entry.category == MotorSoundConfigurator.CATEGORY_MOTOR then
            local sample = entry.sample
            local score = 0
            if sample.templateName ~= nil and string.startsWith(string.lower(sample.templateName), "engine") then
                score = score + 2
            end
            if sample.isGlsFile then
                score = score + 1
            end
            if score > bestScore then
                best = entry
                bestScore = score
            end
        end
    end
    return best
end


-- clones the vehicle's main engine sample for a source="own" layer. SoundManager:cloneSample copies the sample
-- table flat (table.clone) and only creates a new audio source, so the attribute, offset and modifier tables
-- would be shared with the original; they are copied here, so the factors and the catalog modifiers only change
-- the clone. Starts from the original values of the source entry (the source sample carries the mod's factors).
function MotorSoundConfigurator.cloneOwnEngine(data, vehicle, catalogLayer, xmlFile, key)
    local source = MotorSoundConfigurator.getOwnEngineEntry(data)
    if source == nil then
        return nil, "no engine sample to clone"
    end
    local original = source.sample

    local sample = g_soundManager:cloneSample(original, original.linkNode, vehicle)
    if sample == nil then
        return nil, "cloneSample failed"
    end

    if original.indoorAttributes ~= nil then
        sample.indoorAttributes = table.clone(original.indoorAttributes, math.huge)
        sample.indoorAttributes.lowpassCutoffFrequency = source.cutoffIndoor
        sample.indoorAttributes.lowpassGain = source.gainIndoor
        sample.indoorAttributes.lowpassResonance = source.resonanceIndoor
    end
    if original.outdoorAttributes ~= nil then
        sample.outdoorAttributes = table.clone(original.outdoorAttributes, math.huge)
        sample.outdoorAttributes.lowpassCutoffFrequency = source.cutoffOutdoor
        sample.outdoorAttributes.lowpassGain = source.gainOutdoor
        sample.outdoorAttributes.lowpassResonance = source.resonanceOutdoor
    end
    if original.current == original.indoorAttributes then
        sample.current = sample.indoorAttributes
    else
        sample.current = sample.outdoorAttributes
    end
    sample.offsets = { volume = 0, pitch = 0, lowpassGain = 0 }

    -- one table per attribute; the curves inside are only read and can stay shared
    local modifiers = {}
    for attribute, modifier in pairs(original.modifiers or {}) do
        modifiers[attribute] = table.clone(modifier)
    end
    sample.modifiers = modifiers

    sample.volumeScale = source.volumeScale * catalogLayer.volumeFactor
    sample.pitchScale = source.pitchScale * catalogLayer.pitchFactor
    sample.loopSynthesisRPMRatio = source.rpmRatio * catalogLayer.rpmFactor

    -- extra modifiers from the catalog (e.g. louder under load); a type defined there replaces the copied
    -- curve of the same type, loadModifiersFromXML would otherwise add the keyframes to the shared curve
    local motorKey = key .. ".motor"
    if hasXMLProperty(xmlFile, motorKey) then
        for _, attribute in pairs(SoundManager.SAMPLE_MODIFIER_ATTRIBUTES) do
            local modifier = sample.modifiers[attribute]
            if modifier ~= nil then
                local i = 0
                while true do
                    local modKey = string.format("%s.%s.modifier(%d)", motorKey, attribute, i)
                    if not hasXMLProperty(xmlFile, modKey) then
                        break
                    end
                    local typeIndex = SoundModifierType[getXMLString(xmlFile, modKey .. "#type") or ""]
                    if typeIndex ~= nil then
                        modifier[typeIndex] = nil
                    end
                    i = i + 1
                end
            end
        end
        g_soundManager:loadModifiersFromXML(sample, xmlFile, motorKey)
    end

    return sample, nil
end


-- attaches / detaches / updates the layers of one loaded vehicle according to the settings of its model
function MotorSoundConfigurator.syncVehicleLayers(data)
    local wanted = MotorSoundConfigurator.getModelLayers(data.modelKey) or {}

    local toRemove = {}
    for layerName, _ in pairs(data.layers) do
        if wanted[layerName] == nil then
            table.insert(toRemove, layerName)
        end
    end
    for _, layerName in ipairs(toRemove) do
        MotorSoundConfigurator.removeLayer(data, data.vehicle, layerName)
    end

    for layerName, layerSettings in pairs(wanted) do
        if data.layers[layerName] == nil then
            local message = MotorSoundConfigurator.addLayer(data, data.vehicle, layerName)
            if data.layers[layerName] == nil then
                MotorSoundConfigurator.logWarning("%s", message)
            else
                MotorSoundConfigurator.logDebug("%s", message)
            end
        end
        if data.layers[layerName] ~= nil then
            data.layers[layerName].entry.layerVolume = layerSettings.volume
        end
    end

    MotorSoundConfigurator.applyToVehicleData(data)
end


-- all loaded vehicles: layers according to the settings, factors applied
function MotorSoundConfigurator.syncAllVehicles()
    for _, data in pairs(MotorSoundConfigurator.vehicleData) do
        MotorSoundConfigurator.syncVehicleLayers(data)
    end
end


function MotorSoundConfigurator.syncLayers(modelKey)
    for _, data in pairs(MotorSoundConfigurator.vehicleData) do
        if data.modelKey == modelKey then
            MotorSoundConfigurator.syncVehicleLayers(data)
        end
    end
end


-- adds the catalog layer to the vehicle's motorSamples: Motorized starts / stops it with the motor, updates rpm / load
-- every frame and deletes it with the vehicle; the mod's factors apply like for the vehicle's own samples.
-- Returns a message for the log / console.
function MotorSoundConfigurator.addLayer(data, vehicle, layerName)
    if data.layers[layerName] ~= nil then
        return string.format("Layer '%s' is already attached", layerName)
    end

    local catalogLayer = MotorSoundConfigurator.getCatalogLayer(layerName)
    if catalogLayer == nil then
        return string.format("Unknown layer '%s'", tostring(layerName))
    end
    -- checked before loading, so nothing is created that could not be attached (review #19)
    local spec = vehicle.spec_motorized
    if spec == nil or type(spec.motorSamples) ~= "table" then
        return string.format("Layer '%s': %s has no motor sample list", layerName, tostring(data.name))
    end
    -- the SUSPENSION modifier (Suspensions:getSuspensionModfier, dataS.gar Suspensions.lua:267) indexes
    -- spec_suspensions without a nil check; all base game drivables have it (vehicleTypes.xml baseDrivable), a mod
    -- vehicle type may not. Without suspension nodes it returns 0, the sound stays silent
    if catalogLayer.needsSuspension and vehicle.spec_suspensions == nil then
        return string.format("Layer '%s': %s has no suspensions specialization", layerName, tostring(data.name))
    end

    local xmlFile, path = MotorSoundConfigurator.getLayerXmlFile()
    if xmlFile == nil then
        return "Cannot open " .. path
    end
    local key = string.format("layers.layer(%d)", catalogLayer.index)
    local sample, err
    if catalogLayer.isOwn then
        -- returns nil and a reason if there is no engine sample to clone or cloneSample fails
        sample, err = MotorSoundConfigurator.cloneOwnEngine(data, vehicle, catalogLayer, xmlFile, key)
    else
        sample = g_soundManager:loadSampleFromXML(xmlFile, key, "motor", MotorSoundConfigurator.modDirectory, vehicle.components, 0,
            AudioGroup.VEHICLE, vehicle.i3dMappings, vehicle)
    end

    if sample == nil then
        return string.format("Layer '%s' could not be loaded: %s", layerName, err or "see log")
    end

    table.insert(spec.motorSamples, sample)

    local category = catalogLayer.category or MotorSoundConfigurator.getSampleCategory(sample, false) or MotorSoundConfigurator.CATEGORY_MOTOR
    local entry = MotorSoundConfigurator.createEntry(sample, category)
    -- never used as source of an "own engine" layer
    entry.isLayer = true
    table.insert(data.entries, entry)
    data.layers[layerName] = { sample = sample, entry = entry }
    MotorSoundConfigurator.applyToVehicleData(data)

    -- Motorized starts its samples when the motor starts; a layer added while the motor runs is started here. During
    -- MotorState.STARTING (getIsMotorStarted = ON only, Motorized.lua:1952) the motor samples may already have been
    -- started without it: it is started once the motor is ON, unless it plays by then (review #25)
    local isRunning = vehicle:getIsMotorStarted()
    if isRunning then
        g_soundManager:playSample(sample)
    elseif vehicle.getMotorState ~= nil and vehicle:getMotorState() == MotorState.STARTING then
        data.pendingLayerStarts = data.pendingLayerStarts or {}
        table.insert(data.pendingLayerStarts, layerName)
    end

    return string.format("Layer '%s' (%s) attached to %s, motor running: %s", layerName, category, data.name, tostring(isRunning))
end


-- layers attached while the motor was starting (addLayer): played when the motor is ON, dropped when the start was
-- aborted (the next start plays them with the other motor samples). Called from onMotorizedUpdate while some are left
function MotorSoundConfigurator.startPendingLayers(data, vehicle)
    local motorState = vehicle:getMotorState()
    if motorState == MotorState.STARTING then
        return
    end
    if motorState == MotorState.ON then
        for _, layerName in ipairs(data.pendingLayerStarts) do
            -- removed again meanwhile: no entry any more
            local layer = data.layers[layerName]
            if layer ~= nil and not g_soundManager:getIsSamplePlaying(layer.sample) then
                g_soundManager:playSample(layer.sample)
            end
        end
    end
    data.pendingLayerStarts = nil
end


function MotorSoundConfigurator.removeLayer(data, vehicle, layerName)
    local layer = data.layers[layerName]
    if layer == nil then
        return string.format("Layer '%s' is not attached", tostring(layerName))
    end

    g_soundManager:stopSample(layer.sample)
    table.removeElement(vehicle.spec_motorized.motorSamples, layer.sample)
    table.removeElement(data.entries, layer.entry)
    g_soundManager:deleteSample(layer.sample)
    data.layers[layerName] = nil

    return string.format("Layer '%s' removed from %s", layerName, data.name)
end
