-- Motor Sound Configurator: engine swap
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- Tab "Engine swap" (user 2026-10-11, replaces the engine swap presets of v0.13.0.0): the own engine of the model at
-- 0 % (before: 10 %, still audible) and one engine of the catalog group "engine" instead, at its own volume.
-- Always for the model of the current vehicle. Nothing about the swap is saved: it counts as active while the model's
-- engine volume is 0 and an engine of the group is set. Ending it sets the engine volume back to "(global)" and
-- switches the engine layer off.

-- catalog group whose layers are the swap engines (sounds/layers.xml)
MotorSoundConfigurator.SWAP_GROUP = "engine"
-- catalog group of the clones of the vehicle's own engine (source="own"), switched off by a swap
MotorSoundConfigurator.OWN_ENGINE_GROUP = "ownEngine"
-- engine volume of the model during a swap
MotorSoundConfigurator.SWAP_OWN_VOLUME = 0.0
-- volume of a newly chosen engine: 100 % = about as loud as in its own vehicle (catalog calibration)
MotorSoundConfigurator.SWAP_DEFAULT_VOLUME = 1.0
-- layers of the swap group sorted by button text, nil = build again (reset by loadLayerCatalog)
MotorSoundConfigurator.swapEngines = nil


-- button text of a swap engine: l10n msc_swap_<layer> if there is one (names with words to translate, e.g. "Truck"),
-- otherwise shortName of the catalog, otherwise the source vehicle
function MotorSoundConfigurator.getSwapEngineName(layer)
    -- engines from mods and DLCs: the shortened store name (ModEngines.lua)
    if layer.isModEngine then
        return layer.shortName
    end
    local key = "msc_swap_" .. layer.name
    if g_i18n ~= nil and g_i18n:hasText(key) then
        return g_i18n:getText(key)
    end
    return layer.shortName or layer.source or layer.name
end


-- natural order of two texts (case-insensitive): runs of digits compare as numbers, so "Fendt 200" comes before
-- "Fendt 1000" (user 2026-10-13); true if a comes before b
function MotorSoundConfigurator.isNaturalLess(a, b)
    a, b = string.lower(a), string.lower(b)
    local indexA, indexB = 1, 1
    while indexA <= #a and indexB <= #b do
        local startA, endA = string.find(a, "^%d+", indexA)
        local startB, endB = string.find(b, "^%d+", indexB)
        if startA ~= nil and startB ~= nil then
            local numberA, numberB = tonumber(string.sub(a, startA, endA)), tonumber(string.sub(b, startB, endB))
            if numberA ~= numberB then
                return numberA < numberB
            end
            indexA, indexB = endA + 1, endB + 1
        else
            local charA, charB = string.sub(a, indexA, indexA), string.sub(b, indexB, indexB)
            if charA ~= charB then
                return charA < charB
            end
            indexA, indexB = indexA + 1, indexB + 1
        end
    end
    -- one text is the start of the other: the shorter one first
    return #a - indexA < #b - indexB
end


-- catalog layers of the swap group, sorted by button text in natural order
function MotorSoundConfigurator.getSwapEngines()
    if MotorSoundConfigurator.swapEngines == nil then
        local engines = {}
        for _, group in ipairs(MotorSoundConfigurator.getLayerGroups()) do
            if group.name == MotorSoundConfigurator.SWAP_GROUP then
                for _, layer in ipairs(group.layers) do
                    table.insert(engines, layer)
                end
            end
        end
        table.sort(engines, function(a, b)
            return MotorSoundConfigurator.isNaturalLess(MotorSoundConfigurator.getSwapEngineName(a), MotorSoundConfigurator.getSwapEngineName(b))
        end)
        MotorSoundConfigurator.swapEngines = engines
    end
    return MotorSoundConfigurator.swapEngines
end


-- true if the model's own engine volume is the one of a swap (0 %)
function MotorSoundConfigurator.isSwapOwnVolume(modelKey)
    local values = modelKey ~= nil and MotorSoundConfigurator.getModelValues(modelKey, MotorSoundConfigurator.CATEGORY_MOTOR) or nil
    local ownVolume = values ~= nil and values.volume or nil
    return ownVolume ~= nil and math.abs(ownVolume - MotorSoundConfigurator.SWAP_OWN_VOLUME) <= MotorSoundConfigurator.PRESET_EPSILON
end


-- the two groups whose engines are swap engines: base game catalog "engine" and the mod engines
function MotorSoundConfigurator.isSwapGroup(groupName)
    return groupName == MotorSoundConfigurator.SWAP_GROUP or groupName == MotorSoundConfigurator.MOD_ENGINE_GROUP
end


-- engine of a swap group set for the model (also mixed in without a muted own engine): catalog layer and its
-- volume, or nil; base game engines first, then the mod engines (only available ones)
function MotorSoundConfigurator.getSwapEngineLayer(modelKey)
    local modelLayers = MotorSoundConfigurator.getModelLayers(modelKey)
    if modelLayers == nil then
        return nil, nil
    end
    for _, layer in ipairs(MotorSoundConfigurator.getSwapEngines()) do
        if modelLayers[layer.name] ~= nil then
            return layer, modelLayers[layer.name].volume
        end
    end
    -- the lowest name, so the result does not depend on the table order (a model normally has one); no temporary
    -- table, this runs on every apply (isSwapDonorMissing)
    local modName = nil
    for layerName, _ in pairs(modelLayers) do
        if MotorSoundConfigurator.modEnginesByName[layerName] ~= nil and (modName == nil or layerName < modName) then
            modName = layerName
        end
    end
    if modName ~= nil then
        return MotorSoundConfigurator.modEnginesByName[modName], modelLayers[modName].volume
    end
    return nil, nil
end


-- an engine of a swap group is set for the model, counting mod engines whose donor is missing
function MotorSoundConfigurator.hasSwapEngine(modelKey)
    return MotorSoundConfigurator.getSwapEngineLayer(modelKey) ~= nil or MotorSoundConfigurator.hasMissingModEngine(modelKey)
end


-- swap to a mod engine whose donor is missing (mod removed, multiplayer client without it): own engine at the 0 % of
-- the swap and no available swap engine. The swap is inactive then, applyToVehicleData plays the own engine at the
-- volume it would have without the swap (user 2026-10-20: not silent); the entry stays in the settings
function MotorSoundConfigurator.isSwapDonorMissing(modelKey)
    return MotorSoundConfigurator.isSwapOwnVolume(modelKey) and MotorSoundConfigurator.hasMissingModEngine(modelKey)
        and MotorSoundConfigurator.getSwapEngineLayer(modelKey) == nil
end


-- active swap of the model (own engine at 0 % and an engine of the group set): catalog layer and its volume, or nil
function MotorSoundConfigurator.getActiveSwap(modelKey)
    if not MotorSoundConfigurator.isSwapOwnVolume(modelKey) then
        return nil, nil
    end
    return MotorSoundConfigurator.getSwapEngineLayer(modelKey)
end


-- something to end on the swap tab: an active swap, an engine of the group left over without one (own engine
-- volume changed afterwards on "Sound", by a preset, or a swap preset of v0.13 .. v0.15 with 10 %), or an own engine
-- left at 0 % without an engine of the group (the engine was switched off elsewhere or removed from the catalog,
-- review 2026-10-12 #18: otherwise the vehicle had no engine sound and "Own engine" did nothing)
function MotorSoundConfigurator.hasSwapToRemove(modelKey)
    return MotorSoundConfigurator.hasSwapEngine(modelKey) or MotorSoundConfigurator.isSwapOwnVolume(modelKey)
end


-- the engines of the swap group were switched off outside the swap tab ("Extra sounds" row "Off" or reset, mscLayer
-- remove): an own engine left at the 0 % of a swap goes back to "(global)" as well (review #18, user 2026-10-12).
-- Returns true if the engine volume was changed (the caller applies it)
function MotorSoundConfigurator.endSwapWithoutEngine(vehicleData)
    if MotorSoundConfigurator.hasSwapEngine(vehicleData.modelKey) or not MotorSoundConfigurator.isSwapOwnVolume(vehicleData.modelKey) then
        return false
    end
    MotorSoundConfigurator.setModelValue(vehicleData, MotorSoundConfigurator.CATEGORY_MOTOR, "volume", nil)
    return true
end


-- own engine of the model to 0 %, the engine layerName instead (replaces the other engines of the group); the clones
-- of the own engine (group OWN_ENGINE_GROUP, e.g. preset "More bass") are switched off too, they would keep the own
-- engine audible (review #27, user 2026-10-12). False if the layer is not in the catalog
function MotorSoundConfigurator.applySwap(vehicleData, layerName, volume)
    local catalogLayer = MotorSoundConfigurator.getCatalogLayer(layerName)
    if catalogLayer == nil then
        return false
    end
    -- synced by setGroupLayer below; one swap engine at a time: the engines of the other swap group go as well (base
    -- game vs. mods & DLCs, v1.1.0.0), setGroupLayer clears the own group
    MotorSoundConfigurator.clearLayerGroup(vehicleData, MotorSoundConfigurator.OWN_ENGINE_GROUP, nil, true)
    local otherGroup = catalogLayer.group == MotorSoundConfigurator.MOD_ENGINE_GROUP and MotorSoundConfigurator.SWAP_GROUP
        or MotorSoundConfigurator.MOD_ENGINE_GROUP
    MotorSoundConfigurator.clearLayerGroup(vehicleData, otherGroup, nil, true)
    if not MotorSoundConfigurator.setGroupLayer(vehicleData, layerName, volume or MotorSoundConfigurator.SWAP_DEFAULT_VOLUME) then
        return false
    end
    MotorSoundConfigurator.setModelValue(vehicleData, MotorSoundConfigurator.CATEGORY_MOTOR, "volume", MotorSoundConfigurator.SWAP_OWN_VOLUME)
    return true
end


-- engines of the swap group off; the own engine back to "(global)" if it is at the 0 % of a swap (an engine volume
-- changed since then stays). An own engine value from before the swap is not restored (like removing a preset).
function MotorSoundConfigurator.removeSwap(vehicleData)
    if MotorSoundConfigurator.isSwapOwnVolume(vehicleData.modelKey) then
        MotorSoundConfigurator.setModelValue(vehicleData, MotorSoundConfigurator.CATEGORY_MOTOR, "volume", nil)
    end
    -- both swap groups, mod engines with a missing donor included (one sync at the end)
    MotorSoundConfigurator.clearLayerGroup(vehicleData, MotorSoundConfigurator.MOD_ENGINE_GROUP, nil, true)
    MotorSoundConfigurator.clearLayerGroup(vehicleData, MotorSoundConfigurator.SWAP_GROUP, nil, true)
    MotorSoundConfigurator.syncLayers(vehicleData.modelKey)
end


-- removes the model's mod engines whose donor is missing (hint on the swap tab, user 2026-10-20); a swap whose engine
-- that was ends as well (own engine back from 0 %). True if something was removed
function MotorSoundConfigurator.removeMissingModEngines(vehicleData)
    local names = MotorSoundConfigurator.getMissingModEngines(vehicleData.modelKey)
    if #names == 0 then
        return false
    end
    for _, layerName in ipairs(names) do
        MotorSoundConfigurator.setModelLayer(vehicleData, layerName, nil, true)
    end
    MotorSoundConfigurator.endSwapWithoutEngine(vehicleData)
    MotorSoundConfigurator.syncLayers(vehicleData.modelKey)
    return true
end
