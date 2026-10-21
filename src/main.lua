-- Motor Sound Configurator: mod event listener (entry point, loaded last, see modDesc.xml)
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- Files (load order in modDesc.xml): MotorSoundConfigurator.lua (table, constants, shared helpers), Settings.lua,
-- SampleAdjuster.lua, Layers.lua, ModEngines.lua, Presets.lua, EngineSwap.lua, Hooks.lua, ConsoleCommands.lua,
-- MotorSoundConfiguratorDialog.lua, main.lua.

function MotorSoundConfigurator:loadMap(name)
    -- one start line: version and role (single player / multiplayer host / client / dedicated server) with the raw
    -- values it is derived from, so a multiplayer test shows which path was taken (docs/CODE_REVIEW.md #17)
    local mission = g_currentMission
    MotorSoundConfigurator.log("v%s started as %s (isServer %s, isClient %s, dedicatedServer %s, isMultiplayer %s) from %s",
        MotorSoundConfigurator.getModVersion(), MotorSoundConfigurator.getRoleText(),
        tostring(mission ~= nil and mission.getIsServer ~= nil and mission:getIsServer()),
        tostring(mission ~= nil and mission.getIsClient ~= nil and mission:getIsClient()),
        tostring(MotorSoundConfigurator.isDedicatedServer()), tostring(MotorSoundConfigurator.isMultiplayer()),
        tostring(MotorSoundConfigurator.modDirectory))

    -- dedicated server: no sound and no player, nothing to do (the vehicle hooks in Hooks.lua check hasClient too,
    -- vehicle.isClient alone is not enough there)
    if not MotorSoundConfigurator.hasClient() then
        MotorSoundConfigurator.isInactive = true
        MotorSoundConfigurator.log("Dedicated server, mod inactive")
        return
    end
    if MotorSoundConfigurator.isMultiplayerClient() then
        MotorSoundConfigurator.log("Multiplayer client, settings in modSettings/%s/%s", MotorSoundConfigurator.CLIENT_SETTINGS_DIRECTORY, MotorSoundConfigurator.CLIENT_SETTINGS_FILENAME)
    end
    -- engines from mods and DLCs before the catalog, which adds them as their own group (ModEngines.lua)
    MotorSoundConfigurator.detectModEngines()
    MotorSoundConfigurator.loadLayerCatalog()
    -- here and not on the first vehicle: no file access in the middle of vehicle loading, and the savegame save always
    -- has settings to write (review 2026-10-12 #19 / #22); after the catalog, unknown layers are dropped against it
    MotorSoundConfigurator.loadSettings()
    MotorSoundConfiguratorDialog.register()
    MotorSoundConfigurator.wrapPreviewModifierTypes()
    MotorSoundConfigurator.registerConsoleCommands()
end


function MotorSoundConfigurator:deleteMap()
    if MotorSoundConfigurator.isInactive then
        MotorSoundConfigurator.isInactive = false
        return
    end
    MotorSoundConfigurator.unregisterConsoleCommands()
    MotorSoundConfigurator.closeLayerXmlFile()
    MotorSoundConfigurator.settings = nil
    MotorSoundConfigurator.vehicleData = {}
    MotorSoundConfigurator.layerCatalog = {}
    MotorSoundConfigurator.layerGroups = {}
    MotorSoundConfigurator.modEngines = {}
    MotorSoundConfigurator.modEnginesByName = {}
    MotorSoundConfigurator.modEngineAliases = {}
    MotorSoundConfigurator.missingModEngineWarned = {}
    MotorSoundConfigurator.isOriginalMode = false
    MotorSoundConfigurator.debug = false
    MotorSoundConfigurator.previewVehicle = nil
    MotorSoundConfigurator.previewRpm = nil
    MotorSoundConfigurator.previewLoad = nil
end


addModEventListener(MotorSoundConfigurator)
