-- Motor Sound Configurator: sample classification and scaling
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- Sorts the vehicle's samples into motor / gearbox / cabin / rattle and its work sounds into work / discharge (implements:
-- implementWork / implementDrive / implementRattle), remembers their original values and applies the factors.

---------------------------------------------------------------------------
-- Sample classification and scaling
---------------------------------------------------------------------------

-- keywords in template names and file names (checked in this order); cabin = cabin sound, cabin rumble and fan
-- (category "Cabin & fan" since v0.12.0.0, before they stayed unchanged)
MotorSoundConfigurator.CABIN_KEYWORDS = { "fan", "cabin", "rumble" }
-- rattling parts: template attacherClanks, file vehAttacherClanks_01.wav (the only such sound of the base game)
MotorSoundConfigurator.RATTLE_KEYWORDS = { "clank" }
MotorSoundConfigurator.GEARBOX_FILENAME_KEYWORDS = { "transmission", "trasmission", "gearbox", "getriebe" }
-- electric motors are "motor" too (user 2026-10-13): Volvo FH Electric / L120H Electric use the templates
-- volvoElectric / volvoElectric02 inside <motor>, the only non-engine motor templates of the base game besides cabin,
-- fan and attacher sounds (all base game vehicle XMLs checked 2026-10-13)
MotorSoundConfigurator.ELECTRIC_MOTOR_KEYWORDS = { "electric" }
-- signal tones among the motor samples stay unchanged (JD 9700: johnDeereTractor_cabinBeep.wav would be "cabin")
MotorSoundConfigurator.SKIP_FILENAME_KEYWORDS = { "beep" }

-- work sounds outside the motorized samples (categories work / discharge): spec table of the vehicle, sample fields
-- of its "samples" table, category and whether the fields hold lists. All are loaded in onLoad, so they exist in
-- Motorized.onPostLoad: TurnOnVehicle.lua:240-242 (lists from loadSamplesFromXML, empty if none are defined),
-- Combine.lua:906-917 (single samples from loadSampleFromXML, nil if not defined). Forage harvesters only use
-- spec_turnOnVehicle, combines spec_turnOnVehicle and spec_combine (mscInfo logs 2026-10-12); other machines with
-- TurnOnVehicle (mowers, beet harvesters, sprayers) are included on purpose (user 2026-10-12, variant A).
-- No spec changes the volumeScale of these samples itself, so the factor stays.
MotorSoundConfigurator.WORK_SAMPLE_SOURCES = {
    { spec = "spec_turnOnVehicle", category = MotorSoundConfigurator.CATEGORY_WORK, isList = true, fields = { "start", "stop", "work" } },
    { spec = "spec_combine", category = MotorSoundConfigurator.CATEGORY_WORK,
      fields = { "start", "stop", "work", "chopperStart", "chopperStop", "chopperWork" } },
    { spec = "spec_combine", category = MotorSoundConfigurator.CATEGORY_DISCHARGE, fields = { "chopStraw", "dropStraw", "fill" } }
}


-- work sounds of implements (categories implementWork / implementDrive / implementRattle, v0.19.0.0): path from the vehicle to a table
-- of samples ("*" = every element of a list), the sample fields in it (a single sample or a list from
-- loadSamplesFromXML) and the category. All are loaded in onLoad with the implement as modifierTargetObject, so they
-- exist in Attachable.onPostLoad (base game sources, line = loadSample(s)FromXML): TurnOnVehicle.lua:240-242,
-- PowerTakeOffs.lua:235, SowingMachine.lua:209-210, Sprayer.lua:241-242 / 775-776 (work = pump, played in
-- onTurnedOn :1131; spray = while spraying :614), Mulcher.lua:95-96, StrawBlower.lua:89-91, StumpCutter.lua:155-158,
-- WoodCrusher.lua:444-447, BaleWrapper.lua:502-504 (roundBaleWrapper / squareBaleWrapper :290-294),
-- InlineWrapper.lua:248-250, Cutter.lua:307, Mower.lua:122, Cultivator.lua:131, Plow.lua:228, Roller.lua:109,
-- Baler.lua:487 / 491, Tedder.lua:126 / 134, Windrower.lua:120 / 134, FruitPreparer.lua:94, Weeder.lua:80,
-- StonePicker.lua:102-103, RidgeFormer.lua:81, TreePlanter.lua:156; rattle while rolling: Attachable.lua:492 (played
-- while lastSpeed > 0.00027, :839-847; base game: trailerRattle / generalRattle in 139 vehicle XMLs).
-- Not included (user 2026-10-18): plow turning, baler door / unload / eject, hydraulics, folding, attaching. None of
-- the specs changes the volumeScale of these samples itself.
MotorSoundConfigurator.IMPLEMENT_SAMPLE_SOURCES = {
    { path = { "spec_turnOnVehicle", "samples" }, fields = { "start", "stop", "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_powerTakeOffs", "samples" }, fields = { "turnedOn" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_sowingMachine", "samples" }, fields = { "airBlower" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_sprayer", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_sprayer", "sprayTypes", "*", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_mulcher", "samples" }, fields = { "idle" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_strawBlower", "samples" }, fields = { "start", "stop" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_stumpCutter", "samples" }, fields = { "start", "stop", "idle" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_woodCrusher", "samples" }, fields = { "start", "stop", "idle" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_baleWrapper", "roundBaleWrapper", "samples" }, fields = { "start", "stop" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_baleWrapper", "squareBaleWrapper", "samples" }, fields = { "start", "stop" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },
    { path = { "spec_inlineWrapper", "samples" }, fields = { "start", "stop" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_DRIVE },

    { path = { "spec_cutter", "samples" }, fields = { "cut" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_mower", "samples" }, fields = { "cut" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_sowingMachine", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_cultivator", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_plow", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_roller", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_baler", "samples" }, fields = { "work", "knotCleaning" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_tedder", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_tedder", "effects", "*", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_windrower", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_windrower", "effects", "*", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_sprayer", "samples" }, fields = { "spray" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_sprayer", "sprayTypes", "*", "samples" }, fields = { "spray" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_fruitPreparer", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_mulcher", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_weeder", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_stonePicker", "samples" }, fields = { "work", "stone" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_ridgeFormer", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_strawBlower", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_stumpCutter", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_woodCrusher", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_treePlanter", "samples" }, fields = { "work" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_baleWrapper", "roundBaleWrapper", "samples" }, fields = { "wrap" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_baleWrapper", "squareBaleWrapper", "samples" }, fields = { "wrap" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },
    { path = { "spec_inlineWrapper", "samples" }, fields = { "wrap" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_WORK },

    { path = { "spec_attachable", "samples" }, fields = { "active" }, category = MotorSoundConfigurator.CATEGORY_IMPLEMENT_RATTLE }
}


function MotorSoundConfigurator.containsAny(text, keywords)
    for _, keyword in ipairs(keywords) do
        if text:find(keyword, 1, true) then
            return true
        end
    end
    return false
end


-- Base game vehicles define transmission, fan and cabin sounds as <motor> or <gearbox> entries with
-- different templates (e.g. MF 8570: fanHarvester02 / cabinHarvester01 inside <gearbox>), so the
-- template name decides first (fanModern_01, cabinTractor_01, indoorCabinRumble = cabin; attacherClanks = rattle
-- since v0.18.0.0; others stay unchanged). Without a template the filename decides, then the XML element.
-- Returns the category or nil (sample stays unchanged).
function MotorSoundConfigurator.getSampleCategory(sample, isGearboxEntry)
    if sample.templateName ~= nil then
        local template = string.lower(sample.templateName)
        if string.startsWith(template, "engine") or MotorSoundConfigurator.containsAny(template, MotorSoundConfigurator.ELECTRIC_MOTOR_KEYWORDS) then
            return MotorSoundConfigurator.CATEGORY_MOTOR
        elseif string.startsWith(template, "transmission") then
            return MotorSoundConfigurator.CATEGORY_GEARBOX
        elseif MotorSoundConfigurator.containsAny(template, MotorSoundConfigurator.CABIN_KEYWORDS) then
            return MotorSoundConfigurator.CATEGORY_CABIN
        elseif MotorSoundConfigurator.containsAny(template, MotorSoundConfigurator.RATTLE_KEYWORDS) then
            return MotorSoundConfigurator.CATEGORY_RATTLE
        end
        return nil
    end

    -- only the file name, the path may contain anything (mod folder names)
    local filename = string.lower(MotorSoundConfigurator.getSampleLabel(sample))
    if MotorSoundConfigurator.containsAny(filename, MotorSoundConfigurator.SKIP_FILENAME_KEYWORDS) then
        return nil
    elseif MotorSoundConfigurator.containsAny(filename, MotorSoundConfigurator.RATTLE_KEYWORDS) then
        return MotorSoundConfigurator.CATEGORY_RATTLE
    elseif MotorSoundConfigurator.containsAny(filename, MotorSoundConfigurator.CABIN_KEYWORDS) then
        return MotorSoundConfigurator.CATEGORY_CABIN
    elseif isGearboxEntry or MotorSoundConfigurator.containsAny(filename, MotorSoundConfigurator.GEARBOX_FILENAME_KEYWORDS) then
        return MotorSoundConfigurator.CATEGORY_GEARBOX
    end

    return MotorSoundConfigurator.CATEGORY_MOTOR
end


-- the "rpm character" factor (loopSynthesisRPMRatio) only acts on loop synthesis samples (.gls) whose rpm Motorized
-- sets (setSampleLoopSynthesisParameters, SoundManager.lua:1331-1338); a loopSynthesisRpm modifier overwrites that rpm
-- on every update (:1006-1008), e.g. volvoElectric follows the driving speed (user test 2026-10-13: no effect)
function MotorSoundConfigurator.isRpmControlled(sample)
    if not sample.isGlsFile then
        return false
    end
    local modifier = sample.modifiers ~= nil and sample.modifiers.loopSynthesisRpm or nil
    return modifier == nil or not modifier.hasModification
end


function MotorSoundConfigurator.getSampleLabel(sample)
    if sample.templateName ~= nil then
        return sample.templateName
    end
    local filename = tostring(sample.filename)
    return filename:match("[^/\\]+$") or filename
end


function MotorSoundConfigurator.collectEntries(entries, skipped, samples, isGearboxEntry)
    if type(samples) ~= "table" then
        return
    end

    for _, sample in ipairs(samples) do
        local category = MotorSoundConfigurator.isSoundSample(sample) and MotorSoundConfigurator.getSampleCategory(sample, isGearboxEntry) or nil
        if category ~= nil then
            table.insert(entries, MotorSoundConfigurator.createEntry(sample, category))
        elseif type(sample) == "table" then
            table.insert(skipped, MotorSoundConfigurator.getSampleLabel(sample))
        end
    end
end


-- adds a work sound entry (volume only) for a sample (isList false) or each sample of a list, each sample once
function MotorSoundConfigurator.addWorkEntries(entries, seen, value, category, isList)
    if type(value) ~= "table" then
        return
    end
    local samples = isList and value or { value }
    for _, sample in ipairs(samples) do
        -- only registered samples: a foreign table would get an entry without effect (review #33)
        if MotorSoundConfigurator.isSoundSample(sample) and not seen[sample] then
            seen[sample] = true
            table.insert(entries, MotorSoundConfigurator.createEntry(sample, category))
        end
    end
end


-- work sounds of the vehicle itself (WORK_SAMPLE_SOURCES, discharge nodes), see CATEGORY_WORK
function MotorSoundConfigurator.collectWorkEntries(entries, vehicle)
    local seen = {}
    for _, entry in ipairs(entries) do
        seen[entry.sample] = true
    end

    for _, source in ipairs(MotorSoundConfigurator.WORK_SAMPLE_SOURCES) do
        local spec = vehicle[source.spec]
        local samples = spec ~= nil and spec.samples or nil
        if type(samples) == "table" then
            for _, field in ipairs(source.fields) do
                MotorSoundConfigurator.addWorkEntries(entries, seen, samples[field], source.category, source.isList == true)
            end
        end
    end

    -- discharge nodes (Dischargeable.lua:233 / 851 / 858): the extra discharge sound (forage harvester spout) and the
    -- one-shot sounds when discharging starts (harvesterDischargeStartCabin). The fill type sound of a node
    -- (dischargeNode.sample) is cloned only while discharging (Dischargeable.lua:1749) and stays unchanged
    local dischargeable = vehicle.spec_dischargeable
    if dischargeable ~= nil and type(dischargeable.dischargeNodes) == "table" then
        for _, dischargeNode in ipairs(dischargeable.dischargeNodes) do
            MotorSoundConfigurator.addWorkEntries(entries, seen, dischargeNode.dischargeSample, MotorSoundConfigurator.CATEGORY_DISCHARGE, false)
            MotorSoundConfigurator.addWorkEntries(entries, seen, dischargeNode.dischargeStateSamples, MotorSoundConfigurator.CATEGORY_DISCHARGE, true)
        end
    end
end


-- tables at the end of path below value ("*" = every element of a list), appended to result
function MotorSoundConfigurator.collectPathTables(value, path, index, result)
    if type(value) ~= "table" then
        return
    end
    if index > #path then
        table.insert(result, value)
        return
    end
    local key = path[index]
    if key == "*" then
        for _, child in ipairs(value) do
            MotorSoundConfigurator.collectPathTables(child, path, index + 1, result)
        end
    else
        MotorSoundConfigurator.collectPathTables(value[key], path, index + 1, result)
    end
end


-- work sounds of an implement (IMPLEMENT_SAMPLE_SOURCES), each sample once
function MotorSoundConfigurator.collectImplementEntries(entries, vehicle)
    local seen = {}
    for _, source in ipairs(MotorSoundConfigurator.IMPLEMENT_SAMPLE_SOURCES) do
        local sampleTables = {}
        MotorSoundConfigurator.collectPathTables(vehicle, source.path, 1, sampleTables)
        for _, samples in ipairs(sampleTables) do
            for _, field in ipairs(source.fields) do
                local value = samples[field]
                -- a single sample (loadSampleFromXML) or a list (loadSamplesFromXML)
                MotorSoundConfigurator.addWorkEntries(entries, seen, value, source.category, not MotorSoundConfigurator.isSoundSample(value))
            end
        end
    end
end


-- implements (Attachable without Motorized): their work sounds get the implement categories, applied like the
-- vehicles' own samples (applyToAllVehicles); no layers. Implements without such sounds are not registered
function MotorSoundConfigurator.registerImplement(vehicle)
    local entries = {}
    MotorSoundConfigurator.collectImplementEntries(entries, vehicle)
    local modelKey = MotorSoundConfigurator.getModelKey(vehicle)

    if MotorSoundConfigurator.debug then
        local labels = {}
        for _, entry in ipairs(entries) do
            table.insert(labels, string.format("%s=%s", entry.category, MotorSoundConfigurator.getSampleLabel(entry.sample)))
        end
        MotorSoundConfigurator.logDebug("implement %s: %s", tostring(modelKey), #labels > 0 and table.concat(labels, ", ") or "-")
    end

    if #entries > 0 and modelKey ~= nil then
        local data = {
            vehicle = vehicle,
            modelKey = modelKey,
            name = vehicle:getFullName(),
            entries = entries,
            layers = {},
            isImplement = true
        }
        MotorSoundConfigurator.vehicleData[vehicle] = data
        MotorSoundConfigurator.applyToVehicleData(data)
    end
end


-- registered implements attached to the vehicle (directly or further down the chain, Vehicle:getChildVehicles =
-- the vehicle and all attached children, Vehicle.lua:1012 / 3027), one per model (two mowers of the same model share
-- their values), in attaching order
function MotorSoundConfigurator.getAttachedImplementData(vehicle)
    local result = {}
    if vehicle == nil or vehicle.getChildVehicles == nil then
        return result
    end
    local seenModels = {}
    for _, child in ipairs(vehicle:getChildVehicles() or {}) do
        local data = child ~= vehicle and MotorSoundConfigurator.vehicleData[child] or nil
        if data ~= nil and data.isImplement and not seenModels[data.modelKey] then
            seenModels[data.modelKey] = true
            table.insert(result, data)
        end
    end
    return result
end


-- remembers the original values of a sample, the factors are always applied to these
function MotorSoundConfigurator.createEntry(sample, category)
    local indoor = sample.indoorAttributes or {}
    local outdoor = sample.outdoorAttributes or {}
    return {
        sample = sample,
        category = category,
        -- fans of the cabin category follow the engine's cabin openness (user 2026-10-19), cabin sound and rumble not
        isFan = category == MotorSoundConfigurator.CATEGORY_CABIN
            and string.lower(MotorSoundConfigurator.getSampleLabel(sample)):find("fan", 1, true) ~= nil,
        volumeScale = sample.volumeScale or 1.0,
        pitchScale = sample.pitchScale or 1.0,
        cutoffIndoor = indoor.lowpassCutoffFrequency or 0,
        cutoffOutdoor = outdoor.lowpassCutoffFrequency or 0,
        gainIndoor = indoor.lowpassGain or 1.0,
        gainOutdoor = outdoor.lowpassGain or 1.0,
        resonanceIndoor = indoor.lowpassResonance or 0,
        resonanceOutdoor = outdoor.lowpassResonance or 0,
        rpmRatio = sample.loopSynthesisRPMRatio or 1.0
    }
end


function MotorSoundConfigurator.getScaledCutoff(original, factor)
    if factor == 1.0 then
        -- restore exactly, including 0 (= audio group default)
        return original
    end
    if original <= 0 then
        original = MotorSoundConfigurator.DEFAULT_CUTOFF_FREQUENCY
    end
    return math.clamp(original * factor, MotorSoundConfigurator.CUTOFF_FREQUENCY_MIN, MotorSoundConfigurator.CUTOFF_FREQUENCY_MAX)
end


function MotorSoundConfigurator.getScaledGain(original, factor)
    if factor == 1.0 then
        return original
    end
    return math.clamp(original * factor, MotorSoundConfigurator.LOWPASS_GAIN_MIN, MotorSoundConfigurator.LOWPASS_GAIN_MAX)
end


-- all factors 1.0, used while "hear original" is active
function MotorSoundConfigurator.getNeutralFactors()
    local factors = {}
    for _, parameter in ipairs(MotorSoundConfigurator.PARAMETERS) do
        factors[parameter.name] = 1.0
    end
    return factors
end


function MotorSoundConfigurator.applyToVehicleData(data)
    local isOriginal = MotorSoundConfigurator.isOriginalMode
    local neutral = isOriginal and MotorSoundConfigurator.getNeutralFactors() or nil
    -- swap to a mod engine whose donor is missing (v1.1.0.0): the own engine plays at its global volume instead of the
    -- 0 % of the swap, the setting itself stays (implements have no swap)
    local ownEngineVolume = nil
    if neutral == nil and not data.isImplement and MotorSoundConfigurator.isSwapDonorMissing(data.modelKey) then
        ownEngineVolume = MotorSoundConfigurator.getSettings().global[MotorSoundConfigurator.CATEGORY_MOTOR].volume
    end
    for _, entry in ipairs(data.entries) do
        local factors = neutral or MotorSoundConfigurator.getFactors(data.modelKey, entry.category)
        if ownEngineVolume ~= nil and entry.category == MotorSoundConfigurator.CATEGORY_MOTOR and not entry.isLayer then
            factors.volume = ownEngineVolume
        end
        if entry.isFan and neutral == nil then
            -- getFactors builds a new table, changing it here is safe
            factors.indoorDamping = MotorSoundConfigurator.getFactors(data.modelKey, MotorSoundConfigurator.CATEGORY_MOTOR).indoorDamping
        end
        local sample = entry.sample
        -- an attached layer only uses its own volume (layerVolume), independent of the category volume, so the
        -- vehicle's own transmission can be muted and replaced by a layer (user 2026-10-02); pitch, rpm and
        -- filters still follow the category (keeps "own engine" clones in step with the original).
        -- "Hear original": layers keep running silently, so switching back needs no reload
        local volume = factors.volume
        if entry.isLayer then
            volume = isOriginal and 0 or (entry.layerVolume or 1.0)
        end
        g_soundManager:setSampleVolumeScale(sample, entry.volumeScale * volume)
        -- work sounds: volume only, their other attributes stay as loaded
        if not MotorSoundConfigurator.isVolumeOnlyCategory(entry.category) then
            MotorSoundConfigurator.applySoundFactors(entry, factors)
        end
    end
end


-- pitch, rpm character and filters of a motor / gearbox / cabin entry
function MotorSoundConfigurator.applySoundFactors(entry, factors)
    local sample = entry.sample
    -- no setters in SoundManager for the following; updateSampleAttributes reads the fields directly
    -- (pitch via getCurrentSamplePitch, cutoff and gain via sample.current = indoor / outdoor attributes)
    sample.pitchScale = entry.pitchScale * factors.pitch
    -- SoundManager:setSampleLoopSynthesisParameters uses rpm / loopSynthesisRPMRatio (clamped to 0..1),
    -- called by Motorized every frame for motorSamples; samples with a loopSynthesisRpm modifier ignore it
    sample.loopSynthesisRPMRatio = entry.rpmRatio / math.max(factors.rpm, 0.05)
    local cutoffOutdoor = MotorSoundConfigurator.getScaledCutoff(entry.cutoffOutdoor, factors.cutoffOutdoor)
    local gainOutdoor = MotorSoundConfigurator.getScaledGain(entry.gainOutdoor, factors.gainOutdoor)
    if sample.indoorAttributes ~= nil then
        local cutoff = MotorSoundConfigurator.getScaledCutoff(entry.cutoffIndoor, factors.cutoffIndoor)
        local gain = MotorSoundConfigurator.getScaledGain(entry.gainIndoor, factors.gainIndoor)
        local resonance = entry.resonanceIndoor
        -- cabin effect below 100 %: towards the outdoor filter (resonance is read in updateSampleAttributes too,
        -- SoundManager.lua:1004)
        local openness = 1.0 - math.clamp(factors.indoorDamping or 1.0, 0.0, 1.0)
        if openness > 0.001 then
            cutoff = MotorSoundConfigurator.blendCutoff(cutoff, cutoffOutdoor, openness)
            gain = gain + (gainOutdoor - gain) * openness
            resonance = MotorSoundConfigurator.blendResonance(resonance, entry.resonanceOutdoor, openness)
        end
        sample.indoorAttributes.lowpassCutoffFrequency = cutoff
        sample.indoorAttributes.lowpassGain = gain
        sample.indoorAttributes.lowpassResonance = resonance
    end
    if sample.outdoorAttributes ~= nil then
        sample.outdoorAttributes.lowpassCutoffFrequency = cutoffOutdoor
        sample.outdoorAttributes.lowpassGain = gainOutdoor
    end
end


-- cutoff between indoor and outdoor on a logarithmic scale (250 Hz .. 20000 Hz: 50 % = about 2200 Hz, linear would be
-- 10000 Hz and sound open almost at once); 0 = audio group default (DEFAULT_CUTOFF_FREQUENCY)
function MotorSoundConfigurator.blendCutoff(indoor, outdoor, openness)
    if openness >= 0.999 then
        return outdoor
    end
    local from = indoor > 0 and indoor or MotorSoundConfigurator.DEFAULT_CUTOFF_FREQUENCY
    local to = outdoor > 0 and outdoor or MotorSoundConfigurator.DEFAULT_CUTOFF_FREQUENCY
    return math.exp(math.log(from) + (math.log(to) - math.log(from)) * openness)
end


-- resonance 0 = audio group default (comment in SoundManager:loadSampleAttributesFromXML), which cannot be blended
-- with a number: then indoor below 50 %, outdoor from 50 %
function MotorSoundConfigurator.blendResonance(indoor, outdoor, openness)
    if indoor > 0 and outdoor > 0 then
        return indoor + (outdoor - indoor) * openness
    end
    return openness < 0.5 and indoor or outdoor
end


function MotorSoundConfigurator.applyToAllVehicles()
    local count = 0
    for _, data in pairs(MotorSoundConfigurator.vehicleData) do
        MotorSoundConfigurator.applyToVehicleData(data)
        count = count + 1
    end
    return count
end


function MotorSoundConfigurator.registerVehicle(vehicle)
    local spec = vehicle.spec_motorized
    if spec == nil then
        return
    end

    local entries = {}
    local skipped = {}
    MotorSoundConfigurator.collectEntries(entries, skipped, spec.motorSamples, false)
    MotorSoundConfigurator.collectEntries(entries, skipped, spec.gearboxSamples, true)
    MotorSoundConfigurator.collectWorkEntries(entries, vehicle)

    local modelKey = MotorSoundConfigurator.getModelKey(vehicle)

    -- the text is only built with mscDebug on (review #42)
    if MotorSoundConfigurator.debug then
        local labels = {}
        for _, entry in ipairs(entries) do
            -- original lowpass cutoff indoor/outdoor in Hz, 0 = audio group default
            table.insert(labels, string.format("%s=%s(%.0f/%.0f)", entry.category, MotorSoundConfigurator.getSampleLabel(entry.sample),
                entry.cutoffIndoor, entry.cutoffOutdoor))
        end
        MotorSoundConfigurator.logDebug("%s: %s | unchanged: %s", tostring(modelKey),
            #labels > 0 and table.concat(labels, ", ") or "-", #skipped > 0 and table.concat(skipped, ", ") or "-")
    end

    if #entries > 0 then
        local data = {
            vehicle = vehicle,
            modelKey = modelKey,
            name = vehicle:getFullName(),
            entries = entries,
            layers = {}
        }
        MotorSoundConfigurator.vehicleData[vehicle] = data
        -- attach the saved layers of this model, applies the factors to all entries
        MotorSoundConfigurator.syncVehicleLayers(data)
    end
end


-- muffling in words for the info panel of the "Filter" page (v0.20.0.0, user 2026-10-19): openness 0 .. 1 of a lowpass
-- = gain + (1 - gain) x brightness (cutoff on a log scale, 200 Hz = 0, from 8000 Hz = 1: above that the cutoff is
-- hardly audible), then one of MUFFLE_LEVELS (first with openness >= min). The gain only lowers what lies above the
-- cutoff (v1.1.0.0, user 2026-10-20: JD 6R outside 12000 Hz / 0.5 showed "muffled", 20000 Hz / 1.0 sounded the same),
-- so a high cutoff counts as open whatever the gain. Engine templates: cabin 250 Hz / 0.3 .. 0.35 = 0.34 .. 0.39
-- (strong), outside 20000 Hz / 1.0 = 1 (open); an approximation, the resonance is left out
MotorSoundConfigurator.MUFFLE_CUTOFF_LOW = 200
MotorSoundConfigurator.MUFFLE_CUTOFF_HIGH = 8000
MotorSoundConfigurator.MUFFLE_LEVELS = {
    { name = "open", min = 0.9 },
    { name = "light", min = 0.65 },
    { name = "medium", min = 0.45 },
    { name = "strong", min = -1 }
}


function MotorSoundConfigurator.getFilterOpenness(cutoff, gain)
    if cutoff == nil or cutoff <= 0 then
        cutoff = MotorSoundConfigurator.DEFAULT_CUTOFF_FREQUENCY
    end
    local low = math.log(MotorSoundConfigurator.MUFFLE_CUTOFF_LOW)
    local high = math.log(MotorSoundConfigurator.MUFFLE_CUTOFF_HIGH)
    local brightness = math.clamp((math.log(cutoff) - low) / (high - low), 0, 1)
    local clampedGain = math.clamp(gain or 1.0, 0, 1)
    return clampedGain + (1 - clampedGain) * brightness
end


-- level name of the vehicle's own samples of a category (average openness; layers left out), indoor or outdoor, from
-- the original values or the values playing now (factors applied); nil without such samples
function MotorSoundConfigurator.getMuffleLevel(data, category, isIndoor, isOriginal)
    local sum = 0
    local count = 0
    for _, entry in ipairs(data.entries) do
        if not entry.isLayer and entry.category == category then
            local cutoff, gain
            if isOriginal then
                cutoff = isIndoor and entry.cutoffIndoor or entry.cutoffOutdoor
                gain = isIndoor and entry.gainIndoor or entry.gainOutdoor
            else
                local attributes = isIndoor and entry.sample.indoorAttributes or entry.sample.outdoorAttributes
                if attributes ~= nil then
                    cutoff = attributes.lowpassCutoffFrequency
                    gain = attributes.lowpassGain
                end
            end
            sum = sum + MotorSoundConfigurator.getFilterOpenness(cutoff, gain)
            count = count + 1
        end
    end
    if count == 0 then
        return nil
    end
    local openness = sum / count
    for _, level in ipairs(MotorSoundConfigurator.MUFFLE_LEVELS) do
        if openness >= level.min then
            return level.name
        end
    end
    return nil
end


-- outside lowpass of the vehicle's own samples of a category (dialog help line of "Outside: tone / presence"):
-- nil without such samples, otherwise isFiltered and the strongest filtering (lowest openness, its gain and cutoff in
-- Hz). Only a gain below 1.0 together with a cutoff in the audible range muffles (the cutoff alone had no effect in the
-- tests, a gain below 1.0 above 8000 Hz neither: JD 6R 12000 Hz / 0.5, v1.1.0.0), the engine templates use
-- 20000 Hz / 1.0 outside, so for most vehicles factors above 1.0 are clamped to the same values (user 2026-10-02)
function MotorSoundConfigurator.getOutdoorFilter(data, category)
    local minOpenness = nil
    local minGain = nil
    local cutoff = nil
    for _, entry in ipairs(data.entries) do
        if not entry.isLayer and entry.category == category then
            local entryCutoff = entry.cutoffOutdoor > 0 and entry.cutoffOutdoor or MotorSoundConfigurator.DEFAULT_CUTOFF_FREQUENCY
            local openness = MotorSoundConfigurator.getFilterOpenness(entryCutoff, entry.gainOutdoor)
            if minOpenness == nil or openness < minOpenness then
                minOpenness = openness
                minGain = entry.gainOutdoor
                cutoff = entryCutoff
            end
        end
    end
    if minOpenness == nil then
        return nil
    end
    return minOpenness < MotorSoundConfigurator.MUFFLE_LEVELS[1].min, minGain, cutoff
end
