-- Motor Sound Configurator
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- Factors for engine, transmission, cabin & fan and rattle sounds of all motorized vehicles: volume, pitch, rpm character
-- and the lowpass cutoff frequency and gain (indoor / outdoor separately), plus extra sounds (layers) per model.
-- Every factor multiplies the original value from the vehicle sound XML, 1.0 restores it exactly. Global factors
-- apply to every vehicle, a vehicle model (vehicle XML) can override single factors. Stored in
-- <savegame>/motorSoundConfigurator.xml (single player and multiplayer host) or in
-- <profile>/modSettings/FS25_MotorSoundConfigurator/settings.xml (multiplayer client) and applied on top of the
-- vehicle sound XML through sample.volumeScale / sample.pitchScale and the indoor / outdoor attribute tables, which
-- SoundManager:updateSampleAttributes evaluates every frame (see docs/CONCEPT.md). Client side only, nothing is
-- synchronized.

MotorSoundConfigurator = {}
MotorSoundConfigurator.modDirectory = g_currentModDirectory

MotorSoundConfigurator.LOG_PREFIX = "[MotorSoundConfigurator] "
MotorSoundConfigurator.CONFIG_FILENAME = "motorSoundConfigurator.xml"
MotorSoundConfigurator.CONFIG_ROOT = "motorSoundConfigurator"
-- multiplayer client: <profile>/modSettings/<CLIENT_SETTINGS_DIRECTORY>/<CLIENT_SETTINGS_FILENAME> (fixed name, not
-- the zip name, so a renamed zip keeps its settings)
MotorSoundConfigurator.CLIENT_SETTINGS_DIRECTORY = "FS25_MotorSoundConfigurator"
MotorSoundConfigurator.CLIENT_SETTINGS_FILENAME = "settings.xml"

MotorSoundConfigurator.CATEGORY_MOTOR = "motor"
MotorSoundConfigurator.CATEGORY_GEARBOX = "gearbox"
-- cabin sound, cabin rumble and fan (user 2026-10-02); the dialog only offers its volume, the other factors stay
-- available by console and default to 1.0
MotorSoundConfigurator.CATEGORY_CABIN = "cabin"
-- work sounds of harvesters (v0.16.0.0, user 2026-10-12, docs/ERNTEMASCHINEN_SOUND.md): the work unit
-- incl. its start / stop and the straw chopper ("work": threshing / chopping unit of harvesters, also mowing or
-- lifting units of other machines with TurnOnVehicle, user: variant A), discharge and filling ("discharge").
-- Volume only (the other factors are not applied to them); the vehicle itself only, implements have their own
-- categories (see CATEGORY_IMPLEMENT_WORK)
MotorSoundConfigurator.CATEGORY_WORK = "work"
MotorSoundConfigurator.CATEGORY_DISCHARGE = "discharge"
-- rattling parts (v0.18.0.0, user 2026-10-13): template attacherClanks among the motor samples, loud on some mod
-- vehicles (Arion 400 mod 2.45 vs. 1.3 .. 2.0 in the base game). Volume only (pitch makes no sense, user)
MotorSoundConfigurator.CATEGORY_RATTLE = "rattle"
-- work sounds of implements (v0.19.0.0, user 2026-10-18): vehicles without Motorized that are attached (Attachable),
-- e.g. headers, mowers, seeders, sprayers. "implementWork" = the working part (cutting, sowing, tilling, spraying,
-- baling ...), "implementDrive" = what runs while switched on (PTO, seeder blower, sprayer pump, start / stop).
-- Volume only, stored per implement model; the dialog shows them in the work sound block of the towing vehicle
MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK = "implementWork"
MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE = "implementDrive"
-- rattling of trailers and implements while they roll (Attachable "active" sound, user 2026-10-18), shown as "Driving
-- rattle" to keep it apart from the parts rattle of the vehicle itself (CATEGORY_RATTLE); also registers trailers without
-- work sounds
MotorSoundConfigurator.CATEGORY_IMPLEMENT_RATTLE = "implementRattle"
MotorSoundConfigurator.IMPLEMENT_CATEGORIES = { MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK, MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE,
    MotorSoundConfigurator.CATEGORY_IMPLEMENT_RATTLE }
MotorSoundConfigurator.CATEGORIES = { MotorSoundConfigurator.CATEGORY_MOTOR, MotorSoundConfigurator.CATEGORY_GEARBOX, MotorSoundConfigurator.CATEGORY_CABIN,
    MotorSoundConfigurator.CATEGORY_RATTLE, MotorSoundConfigurator.CATEGORY_WORK, MotorSoundConfigurator.CATEGORY_DISCHARGE,
    MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK, MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE, MotorSoundConfigurator.CATEGORY_IMPLEMENT_RATTLE }
-- categories of which only the volume factor is applied (dialog and console offer only that)
MotorSoundConfigurator.VOLUME_ONLY_CATEGORIES = {
    [MotorSoundConfigurator.CATEGORY_RATTLE] = true,
    [MotorSoundConfigurator.CATEGORY_WORK] = true,
    [MotorSoundConfigurator.CATEGORY_DISCHARGE] = true,
    [MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK] = true,
    [MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE] = true,
    [MotorSoundConfigurator.CATEGORY_IMPLEMENT_RATTLE] = true
}
-- adjustable factors per category (1.0 = unchanged); name is also the XML attribute and console parameter
-- range 0 .. 3x (agreed with the user). pitch and rpm stop at 5 %: pitch 0 would stop playback and
-- rpm 0 would divide by zero. A cutoff factor of 0 ends at CUTOFF_FREQUENCY_MIN.
MotorSoundConfigurator.PARAMETERS = {
    { name = "volume",        min = 0.0,  max = 3.0 },
    { name = "pitch",         min = 0.05, max = 3.0 },
    -- loop synthesis rpm mapping: > 1 sounds like higher engine speed, < 1 like a slower revving engine
    -- (tone and firing rhythm change together, unlike pitch; idle stays unchanged because rpm 0 / x = 0)
    { name = "rpm",           min = 0.05, max = 3.0 },
    -- cabin tone up to 10x (user 2026-10-02): the engine templates filter the cabin at 250 Hz, so 3x (750 Hz) still
    -- sounds closed; 10x = 2500 Hz, the result stays limited to CUTOFF_FREQUENCY_MAX
    { name = "cutoffIndoor",  min = 0.0,  max = 10.0 },
    { name = "gainIndoor",    min = 0.0,  max = 3.0 },
    { name = "cutoffOutdoor", min = 0.0,  max = 3.0 },
    { name = "gainOutdoor",   min = 0.0,  max = 3.0 },
    -- cabin effect (v0.20.0.0, user 2026-10-19: "the cabin should sound as open as outside"): 1.0 = the indoor filter
    -- as set above, 0.0 = indoor cutoff, gain and resonance equal the outdoor ones (volume stays), in between blended.
    -- Needed because cutoffIndoor ends at 2500 Hz for the engine templates (outside 20000 Hz) and the resonance
    -- (engineLarge 2.0 inside, 1.0 outside) had no factor
    { name = "indoorDamping", min = 0.0,  max = 1.0 }
}

-- a cutoff of 0 in the sound XML means "defined by the audio group", default 5000 Hz
-- (comment in SoundManager:loadSampleAttributesFromXML)
MotorSoundConfigurator.DEFAULT_CUTOFF_FREQUENCY = 5000
-- range of lowpassCutoffFrequency used in all base game sound XMLs and soundTemplates.xml. Values above
-- 20000 Hz (e.g. Turbo.gls 12000 Hz * 4 = 48000 Hz, above the Nyquist frequency) caused a loud whistling.
MotorSoundConfigurator.CUTOFF_FREQUENCY_MIN = 100
MotorSoundConfigurator.CUTOFF_FREQUENCY_MAX = 20000
-- range of lowpassGain used in all base game sound XMLs and soundTemplates.xml (1.0 = no damping)
MotorSoundConfigurator.LOWPASS_GAIN_MIN = 0.0
MotorSoundConfigurator.LOWPASS_GAIN_MAX = 1.0

-- volume factor of an attached layer (on top of its catalog volumeScale and the category factors)
MotorSoundConfigurator.LAYER_VOLUME_MIN = 0.1
MotorSoundConfigurator.LAYER_VOLUME_MAX = 3.0

-- "hear original" in the dialog: all factors 1.0 and layers muted while true (never saved)
-- true on a dedicated server (set in loadMap), the mod does nothing there
MotorSoundConfigurator.isInactive = false
MotorSoundConfigurator.isOriginalMode = false
-- rpm / load preview in the dialog for previewVehicle: 0 .. 1 of the sound range, nil = live value (never saved)
MotorSoundConfigurator.previewVehicle = nil
MotorSoundConfigurator.previewRpm = nil
MotorSoundConfigurator.previewLoad = nil


-- absolute rpm of a preview position (0 .. 1 = minRpm .. maxRpm, the range Motorized:onUpdate maps to the sound;
-- VehicleMotor:getMinRpm / getMaxRpm, RAW VehicleMotor.lua:486-496), nil without motor
function MotorSoundConfigurator.getPreviewRpm(vehicle, factor)
    local spec = vehicle ~= nil and vehicle.spec_motorized or nil
    local motor = spec ~= nil and spec.motor or nil
    if motor == nil or factor == nil then
        return nil
    end
    return motor:getMinRpm() + factor * (motor:getMaxRpm() - motor:getMinRpm())
end

-- loaded in loadMap (getSettings loads them if still nil), reset in deleteMap; stays nil on a dedicated server
-- settings.global[category][parameter] = factor (always complete)
-- settings.models[modelKey] = { name = "...", [category] = { [parameter] = factor } } (only overridden factors)
MotorSoundConfigurator.settings = nil
-- vehicle -> { modelKey, name, entries = list of { sample, category, volumeScale, pitchScale,
--              cutoffIndoor, cutoffOutdoor, gainIndoor, gainOutdoor } }
-- (entry values are the originals from the sound XML); implements have isImplement = true and only implement entries
MotorSoundConfigurator.vehicleData = {}


-- details per vehicle / layer / model in the log, switched with the console command mscDebug (never saved);
-- normally only errors, warnings and one line per load / save (ModHub review 2026-10-03)
MotorSoundConfigurator.debug = false


function MotorSoundConfigurator.log(text, ...)
    print(MotorSoundConfigurator.LOG_PREFIX .. string.format(text, ...))
end


-- warnings and errors through the game's Logging, which prepends "Warning:" / "Error:" (misc/Logging.lua:133-142),
-- so log tools and the console recognise them (review #41); the text is formatted here and passed as "%s"
function MotorSoundConfigurator.logWarning(text, ...)
    local message = MotorSoundConfigurator.LOG_PREFIX .. string.format(text, ...)
    if Logging ~= nil and Logging.warning ~= nil then
        Logging.warning("%s", message)
    else
        print("Warning: " .. message)
    end
end


function MotorSoundConfigurator.logError(text, ...)
    local message = MotorSoundConfigurator.LOG_PREFIX .. string.format(text, ...)
    if Logging ~= nil and Logging.error ~= nil then
        Logging.error("%s", message)
    else
        print("Error: " .. message)
    end
end


function MotorSoundConfigurator.logDebug(text, ...)
    if MotorSoundConfigurator.debug then
        MotorSoundConfigurator.log(text, ...)
    end
end


---------------------------------------------------------------------------
-- Shared helpers
---------------------------------------------------------------------------

-- version from modDesc.xml (the only place it is kept), for the start line in the log
function MotorSoundConfigurator.getModVersion()
    local xmlFile = loadXMLFile("motorSoundConfiguratorModDesc", MotorSoundConfigurator.modDirectory .. "modDesc.xml")
    if xmlFile == nil or xmlFile == 0 then
        return "?"
    end
    local version = getXMLString(xmlFile, "modDesc.version") or "?"
    delete(xmlFile)
    return version
end


function MotorSoundConfigurator.getParameter(name)
    for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
        if parameter.name == name then
            return parameter
        end
    end
    return nil
end


function MotorSoundConfigurator.isCategory(name)
    for _, category in ipairs(MotorSoundConfigurator.CATEGORIES) do
        if category == name then
            return true
        end
    end
    return false
end


function MotorSoundConfigurator.isVolumeOnlyCategory(category)
    return category ~= nil and MotorSoundConfigurator.VOLUME_ONLY_CATEGORIES[category] == true
end


-- a sample of the SoundManager: loadSample / loadSampleFromXML / cloneSample register it as samples[sample] = sample
-- (SoundManager.lua:193 / 241 / 361 / 432). Guards the sample lists of other specs against foreign tables (e.g. a mod
-- storing a list where the game has one sample); vehicle loading is not protected by pcall (TestRunner, review #19)
function MotorSoundConfigurator.isSoundSample(value)
    if type(value) ~= "table" then
        return false
    end
    if g_soundManager == nil or type(g_soundManager.samples) ~= "table" then
        return true
    end
    return g_soundManager.samples[value] == value
end


-- same key the game uses for vehicles.xml: "data/vehicles/..." or "$moddir$<modName>/<file>.xml",
-- independent of where the mods folder is
function MotorSoundConfigurator.getModelKey(vehicle)
    local filename = vehicle.configFileName
    if filename == nil then
        return nil
    end
    if NetworkUtil ~= nil and NetworkUtil.convertToNetworkFilename ~= nil then
        return NetworkUtil.convertToNetworkFilename(filename)
    end
    return filename
end
