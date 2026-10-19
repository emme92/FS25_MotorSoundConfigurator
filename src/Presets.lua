-- Motor Sound Configurator: presets
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- Fixed sets of factors and extra sounds, always for the model of the current vehicle (user 2026-10-02).
-- Applying a preset sets only its own values (presets can be combined, the last one wins where they overlap),
-- nothing about presets is saved: a preset counts as active while all of its values are still set like that.
-- Removing an active preset sets its values back to "(global)" and switches its extra sounds off.

-- values[category][parameter] = factor (only steps of the dialog sliders, so they show exactly);
-- layers = list of { name = catalog layer, volume = factor }. First only generic sounds ("Generic: ...",
-- "Classic: Vintage Gearbox", the "Own: ..." clones of the own engine); after the first test (user 2026-10-02:
-- "too weak and too few") also exhausts of other vehicles (the engine swap presets moved to their own tab in v0.16.0.0).
-- Layer volumes: 100 % = about as loud as the original engine of a vehicle (catalog calibration v0.13.0.0).
-- l10n msc_preset_<name> / msc_help_preset_<name>; the order is the order of presetButton1 .. n in the dialog XML:
-- column 1 engine (1-4) and exhaust (5-6), column 2 transmission (7-10) and cabin (11-12);
-- the engine swaps (former column 4) have their own tab since v0.16.0.0 (src/EngineSwap.lua).
-- No situation presets ("road", "hearing protection"; user 2026-10-02)
MotorSoundConfigurator.PRESETS = {
    -- engine. Outside tone / presence only act on vehicles that filter their engine outside (templates: 20000 Hz,
    -- gain 1.0 = unfiltered, e.g. JD 6R gain 0.5); first test: 110 % volume, cabin 130 % / 120 % changed almost nothing.
    -- Cabin & fan 50 % (Arion test 2026-10-02: cabin rumble volumeScale 10 and fan 2 cover the engine a lot)
    { name = "punchy",
      values = { motor = { volume = 1.3, cutoffIndoor = 3.0, gainIndoor = 2.0, cutoffOutdoor = 1.5, gainOutdoor = 1.3 }, cabin = { volume = 0.5 } } },
    -- pitch 95 %: 90 % changed the firing rhythm too much (first test)
    { name = "deeper",
      values = { motor = { pitch = 0.95, cutoffIndoor = 0.7 } } },
    -- user 2026-10-02: 35 %, which is no step of the layer volume slider, so 40 %
    { name = "moreBass",
      layers = { { name = "ownEngineOctave", volume = 0.4 } } },
    -- "Generic: Load Loop" and not "Own: Under Load": that one is in the group of "Own: Octave Lower" (one sound
    -- per group), so "More bass" and "More punch under load" could not be combined
    { name = "morePunchUnderLoad",
      layers = { { name = "loadLoop", volume = 1.5 } } },

    -- exhaust
    { name = "exhaustOpen",
      layers = { { name = "exhaustPmTracLoad", volume = 1.0 } } },
    { name = "exhaustBig",
      layers = { { name = "exhaustXerionLoad", volume = 1.0 } } },

    -- transmission; outside tone only acts with outside presence below 100 % (original gain outside mostly 1.0).
    -- Benchmark (user 2026-10-02): CLAAS Arion 570 / 400, two transmissionModern_02 samples at volumeScale 1.8 (template
    -- 1.6), cabin 250 Hz / 30 %, outside unfiltered: "much too loud"; good values there = good presets
    { name = "gearboxQuieter",
      values = { gearbox = { volume = 0.5 } } },
    { name = "gearboxPresent",
      values = { gearbox = { volume = 1.5, cutoffIndoor = 2.0, gainIndoor = 2.0 } } },
    -- Arion test (user 2026-10-02): good with transmission volume 60 %, pitch 50 %; preset volume 70 %, pitch 50 %
    { name = "gearboxLessShrill",
      values = { gearbox = { volume = 0.7, pitch = 0.5, cutoffIndoor = 0.4, cutoffOutdoor = 0.2, gainOutdoor = 0.6 } } },
    -- user 2026-10-13: like "Less shrill" but more muffled (quieter, darker, less present in the cabin and outside)
    { name = "gearboxMuffled",
      values = { gearbox = { volume = 0.6, pitch = 0.5, cutoffIndoor = 0.3, gainIndoor = 0.5, cutoffOutdoor = 0.2, gainOutdoor = 0.4 } } },

    -- cabin. "Open" needs the cabin tone beyond 300 % (cabin filter of the templates at 250 Hz, presence 35 %;
    -- presence results are limited to 100 %)
    { name = "cabinInsulated",
      values = { motor = { cutoffIndoor = 0.7, gainIndoor = 0.7 }, gearbox = { cutoffIndoor = 0.7, gainIndoor = 0.7 }, cabin = { volume = 0.6 } } },
    { name = "cabinOpen",
      values = { motor = { cutoffIndoor = 6.0, gainIndoor = 3.0 }, gearbox = { cutoffIndoor = 6.0, gainIndoor = 3.0 } },
      layers = { { name = "transmissionVintage", volume = 0.5 } } }
    -- the character presets (old diesel, workhorse, quiet premium tractor) were removed in v0.17.1.0 (user 2026-10-13:
    -- "gefallen mir gar nicht mehr")
}

-- two values count as equal below this difference (factors are stored as floats in the settings XML)
MotorSoundConfigurator.PRESET_EPSILON = 0.001


-- true if every value and extra sound of the preset is set like that for the model (model values, not global)
function MotorSoundConfigurator.isPresetActive(modelKey, preset)
    if modelKey == nil then
        return false
    end
    local epsilon = MotorSoundConfigurator.PRESET_EPSILON
    for category, values in pairs(preset.values or {}) do
        local modelValues = MotorSoundConfigurator.getModelValues(modelKey, category)
        for parameterName, factor in pairs(values) do
            local value = modelValues ~= nil and modelValues[parameterName] or nil
            if value == nil or math.abs(value - factor) > epsilon then
                return false
            end
        end
    end
    local modelLayers = MotorSoundConfigurator.getModelLayers(modelKey)
    for _, presetLayer in ipairs(preset.layers or {}) do
        local layerSettings = modelLayers ~= nil and modelLayers[presetLayer.name] or nil
        if layerSettings == nil or math.abs(layerSettings.volume - presetLayer.volume) > epsilon then
            return false
        end
    end
    return true
end


-- sets the values of the preset for the model; an extra sound replaces the other sounds of its group
-- (one sound per group, as in the dialog)
function MotorSoundConfigurator.applyPreset(vehicleData, preset)
    for category, values in pairs(preset.values or {}) do
        for parameterName, factor in pairs(values) do
            MotorSoundConfigurator.setModelValue(vehicleData, category, parameterName, factor)
        end
    end

    for _, presetLayer in ipairs(preset.layers or {}) do
        if not MotorSoundConfigurator.setGroupLayer(vehicleData, presetLayer.name, presetLayer.volume) then
            MotorSoundConfigurator.logWarning("preset '%s' uses layer '%s', which is not in the catalog", preset.name, presetLayer.name)
        end
    end
end


-- values of the preset back to "(global)", its extra sounds off
function MotorSoundConfigurator.removePreset(vehicleData, preset)
    for category, values in pairs(preset.values or {}) do
        for parameterName, _ in pairs(values) do
            MotorSoundConfigurator.setModelValue(vehicleData, category, parameterName, nil)
        end
    end
    for _, presetLayer in ipairs(preset.layers or {}) do
        MotorSoundConfigurator.setModelLayer(vehicleData, presetLayer.name, nil)
    end
end
