-- Motor Sound Configurator: hooks into the game
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- Motorized (load, delete, update for the dialog preview, action events), Attachable (implements: load, delete),
-- VehicleSystem (savegame save) and the Alt+M action.

---------------------------------------------------------------------------
-- Hooks (SpecializationUtil.raiseEvent looks up Motorized[eventName] at call time)
---------------------------------------------------------------------------

-- vehicle.isClient is true on a dedicated server too (like g_currentMission:getIsClient(), GPortal log 2026-10-12),
-- hasClient also checks g_dedicatedServer; it does not depend on loadMap having run
function MotorSoundConfigurator.onMotorizedPostLoad(vehicle, savegame)
    if not vehicle.isClient or not MotorSoundConfigurator.hasClient() then
        return
    end
    -- preview vehicles of the shop configuration screen are loaded and deleted on every configuration change; no
    -- sound adjustments there (review #32; Vehicle:getIsInShowroom = propertyState SHOP_CONFIG, Vehicle.lua:3945, set
    -- in loadFinished before onPostLoad, :749)
    if vehicle.getIsInShowroom ~= nil and vehicle:getIsInShowroom() then
        return
    end

    -- not wrapped in a protected call (TestRunner PublicLuaCheck, 2026-10-03): registerVehicle only accepts registered
    -- sound samples from the spec tables (isSoundSample) and the settings are loaded in loadMap, not here (review #19)
    MotorSoundConfigurator.registerVehicle(vehicle)
end


-- implements (v0.19.0.0): Attachable is the specialization all of them share (headers, mowers, seeders, trailers ...);
-- onPostLoad runs after onLoad of all specializations, so their samples exist (SpecializationUtil.raiseEvent looks up
-- Attachable[eventName] at call time, SpecializationUtil.lua:53-56). Vehicles with Motorized are handled there
function MotorSoundConfigurator.onAttachablePostLoad(vehicle, savegame)
    if vehicle.spec_motorized ~= nil or not vehicle.isClient or not MotorSoundConfigurator.hasClient() then
        return
    end
    if vehicle.getIsInShowroom ~= nil and vehicle:getIsInShowroom() then
        return
    end
    MotorSoundConfigurator.registerImplement(vehicle)
end


-- the specializations delete the samples of the implement in their own onDelete
function MotorSoundConfigurator.onAttachableDelete(vehicle)
    local data = MotorSoundConfigurator.vehicleData[vehicle]
    if data ~= nil and data.isImplement then
        MotorSoundConfigurator.vehicleData[vehicle] = nil
    end
end


-- Motorized:onDelete has deleted the samples (layers included, they are part of motorSamples) and the motor
function MotorSoundConfigurator.onMotorizedDelete(vehicle)
    MotorSoundConfigurator.vehicleData[vehicle] = nil
    if MotorSoundConfigurator.previewVehicle == vehicle then
        MotorSoundConfigurator.previewVehicle = nil
    end
    if not MotorSoundConfigurator.isInactive then
        MotorSoundConfiguratorDialog.onVehicleDeleted(vehicle)
    end
end


-- rpm / load preview of the dialog. Motorized:onUpdate has just passed the real rpm / load (0 .. 1) to the motor
-- samples with g_soundManager:setSamplesLoopSynthesisParameters (LUADOC Motorized.md, onUpdate); the preview
-- values replace them for this frame. nil keeps the real value (SoundManager:setSampleLoopSynthesisParameters
-- skips nil). Same path as the game, so the "rpm character" factor (loopSynthesisRPMRatio) applies, and layers are
-- part of motorSamples. Volume / pitch curves over rpm / load are covered by wrapPreviewModifierTypes; transmission
-- sounds (DIFFERENTIAL_SPEED) stay live.
function MotorSoundConfigurator.onMotorizedUpdate(vehicle, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- layers attached during the motor start (review #25); one table lookup per motorized vehicle otherwise
    local data = MotorSoundConfigurator.vehicleData[vehicle]
    if data ~= nil and data.pendingLayerStarts ~= nil then
        MotorSoundConfigurator.startPendingLayers(data, vehicle)
    end

    if vehicle ~= MotorSoundConfigurator.previewVehicle then
        return
    end
    local rpm, load = MotorSoundConfigurator.previewRpm, MotorSoundConfigurator.previewLoad
    if (rpm == nil and load == nil) or not vehicle.isClient or not vehicle:getIsMotorStarted() then
        return
    end
    g_soundManager:setSamplesLoopSynthesisParameters(vehicle.spec_motorized.motorSamples, rpm, load)
end


-- modifier types (volume / pitch / ... curves in sound XMLs) whose value the preview replaces, as value in the unit of
-- the type: MOTOR_LOAD = load -1 .. 1 (e.g. template transmissionModern_04), MOTOR_RPM_REAL = absolute rpm
-- (e.g. 800 .. 2200 in sounds/layers.xml); nil = real value
MotorSoundConfigurator.PREVIEW_MODIFIER_TYPES = {
    MOTOR_LOAD = function(vehicle)
        return MotorSoundConfigurator.previewLoad
    end,
    MOTOR_RPM_REAL = function(vehicle)
        return MotorSoundConfigurator.getPreviewRpm(vehicle, MotorSoundConfigurator.previewRpm)
    end
}


-- SoundManager:updateSampleModifiers calls typeData.func(sample.modifierTargetObject) of every registered modifier
-- type on each update (SoundManager:getSampleModifierValue, LUADOC SoundManager.md); the descriptions live in
-- g_soundManager.modifierTypeIndexToDesc, indexed by SoundModifierType[name] (registerModifierType). Wrapping func
-- returns the preview value for the preview vehicle only and calls the original for everything else. Idempotent
-- (flag on the description), called in loadMap and before a preview starts.
function MotorSoundConfigurator.wrapPreviewModifierTypes()
    if g_soundManager == nil or g_soundManager.modifierTypeIndexToDesc == nil or SoundModifierType == nil then
        return
    end
    for typeName, getPreviewValue in pairs(MotorSoundConfigurator.PREVIEW_MODIFIER_TYPES) do
        local typeIndex = SoundModifierType[typeName]
        local desc = typeIndex ~= nil and g_soundManager.modifierTypeIndexToDesc[typeIndex] or nil
        if desc == nil or type(desc.func) ~= "function" then
            MotorSoundConfigurator.logWarning("sound modifier type %s not found, preview uses the real value", typeName)
        elseif not desc.mscPreviewWrapped then
            local originalFunc = desc.func
            desc.func = function(target, ...)
                if target ~= nil and target == MotorSoundConfigurator.previewVehicle then
                    local value = getPreviewValue(target)
                    if value ~= nil then
                        return value
                    end
                end
                return originalFunc(target, ...)
            end
            desc.mscPreviewWrapped = true
            MotorSoundConfigurator.logDebug("Preview: sound modifier type %s wrapped", typeName)
        end
    end
end


-- VehicleSystem:save writes vehicles.xml on every savegame save (into tempsavegame/, which the game then
-- moves to savegameN); our file goes into the same directory. This also covers new savegames.
-- settings nil = dedicated server (loaded in loadMap everywhere else)
function MotorSoundConfigurator.onVehicleSystemSave(vehicleSystem, xmlFilename, usedModNames)
    if MotorSoundConfigurator.settings == nil or type(xmlFilename) ~= "string" then
        return
    end

    local directory = xmlFilename:match("^(.*)[/\\]")
    if directory ~= nil then
        -- dialog open with changes not applied yet (e.g. autosave): the savegame gets the state from before the dialog,
        -- "Apply" writes the changes itself, "Cancel" keeps the file as it is (review 2026-10-12 #21)
        local settings = MotorSoundConfiguratorDialog.getOpenSettingsCopy() or MotorSoundConfigurator.settings
        -- saveSettings checks the structure and the XMLFile handle itself (no protected call, TestRunner PublicLuaCheck)
        MotorSoundConfigurator.saveSettings(settings, directory .. "/" .. MotorSoundConfigurator.CONFIG_FILENAME)
    end
end


-- Alt+M (action MSC_OPEN_CONFIGURATOR from modDesc.xml) while the player drives a vehicle with adjusted samples.
-- Pattern from Motorized:onRegisterActionEvents; own table, spec.actionEvents is cleared by Motorized itself.
function MotorSoundConfigurator.onMotorizedRegisterActionEvents(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
    if not vehicle.isClient or MotorSoundConfigurator.isInactive or InputAction.MSC_OPEN_CONFIGURATOR == nil then
        return
    end

    vehicle.mscActionEvents = vehicle.mscActionEvents or {}
    vehicle:clearActionEventsTable(vehicle.mscActionEvents)

    if isActiveForInputIgnoreSelection and MotorSoundConfigurator.vehicleData[vehicle] ~= nil then
        local _, actionEventId = vehicle:addActionEvent(vehicle.mscActionEvents, InputAction.MSC_OPEN_CONFIGURATOR, vehicle,
            MotorSoundConfigurator.actionEventOpenConfigurator, false, true, false, true, nil)
        if actionEventId ~= nil then
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_MSC_OPEN_CONFIGURATOR"))
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
        end
    end
end


function MotorSoundConfigurator.actionEventOpenConfigurator(vehicle, actionName, inputValue, callbackState, isAnalog)
    local data = MotorSoundConfigurator.vehicleData[vehicle]
    if data ~= nil then
        -- the dialog gets the vehicle data directly, the controlled vehicle is not reliable while a dialog is open
        MotorSoundConfiguratorDialog.show(data)
    end
end


Motorized.onPostLoad = Utils.appendedFunction(Motorized.onPostLoad, MotorSoundConfigurator.onMotorizedPostLoad)
Motorized.onRegisterActionEvents = Utils.appendedFunction(Motorized.onRegisterActionEvents, MotorSoundConfigurator.onMotorizedRegisterActionEvents)
Motorized.onDelete = Utils.appendedFunction(Motorized.onDelete, MotorSoundConfigurator.onMotorizedDelete)
Motorized.onUpdate = Utils.appendedFunction(Motorized.onUpdate, MotorSoundConfigurator.onMotorizedUpdate)
Attachable.onPostLoad = Utils.appendedFunction(Attachable.onPostLoad, MotorSoundConfigurator.onAttachablePostLoad)
Attachable.onDelete = Utils.appendedFunction(Attachable.onDelete, MotorSoundConfigurator.onAttachableDelete)
VehicleSystem.save = Utils.appendedFunction(VehicleSystem.save, MotorSoundConfigurator.onVehicleSystemSave)
