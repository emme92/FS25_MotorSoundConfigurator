-- Motor Sound Configurator: engines from mods and DLCs
-- Copyright (C) 2026 Emme92. Licensed under the GNU General Public License v3 (https://www.gnu.org/licenses/gpl-3.0.html).
-- v1.1.0.0 (user 2026-10-20, docs/CONCEPT.md "Motoren aus Mods und DLCs"): the engine samples of every motorized store
-- item that is not base game (mods, unlocked DLCs, no bundle items) are offered on the "Engine swap" tab ("Mods & DLCs")
-- and as the extra sound group MOD_ENGINE_GROUP. Nothing is copied: the samples are loaded from the donor's own sound
-- XML and files. If the donor is gone, its engine is gone too (the settings keep the entry, see isModEngineMissing).

-- catalog group of the mod engines ("Extra sounds" row below "Engine", "Mods & DLCs" on the "Engine swap" tab)
MotorSoundConfigurator.MOD_ENGINE_GROUP = "modEngine"
-- layer name of a mod engine = prefix + donor key (NetworkUtil.convertToNetworkFilename of the donor vehicle XML, the
-- same key as the model key); saved as <layer donor="<donor key>"/> (Settings.lua)
MotorSoundConfigurator.MOD_ENGINE_PREFIX = "mod:"
-- sound position like the catalog engines (sounds/layers.xml linkNodeOffset="0 1.5 1.2"): the donor's linkNode is
-- resolved against the receiving vehicle's i3d mappings (SoundManager:validateSampleDefinition), which would place it
-- anywhere, so every mod engine sample is linked to the first component with this offset
MotorSoundConfigurator.MOD_ENGINE_OFFSET = { 0, 1.5, 1.2 }
-- volume calibration (user 2026-10-20): attached as a layer, a donor engine sounded as loud as the vehicle's own engine
-- only at about 250 %, the same deficit the base game catalog had (about half of the source vehicle's volumeScale,
-- calibrated x2 ... x3 in sounds/layers.xml, docs/CONCEPT.md "Lautstärke-Kalibrierung des Katalogs"); 2.5 was a bit
-- too loud in the hearing test, so 100 % = 2 x donor volume
MotorSoundConfigurator.MOD_ENGINE_VOLUME_FACTOR = 2.0
-- longest button text on the "Engine swap" tab (155px at 15px), longer store names are cut with "..."
MotorSoundConfigurator.MOD_ENGINE_SHORT_NAME_LENGTH = 17
-- prefix of the tractor shop categories (isTractorStoreItem)
MotorSoundConfigurator.MOD_ENGINE_TRACTOR_CATEGORY = "TRACTORS"
-- where the engine samples are, checked in this order; Vehicle.xmlSchemaSounds replaces the root "vehicle" of the
-- external sound file by "sounds" (Vehicle.lua:289-291, 598-601); Motorized:onLoad loads "vehicle.motorized.sounds"
-- and the sounds of the motor configuration on top (Motorized.lua:398-406); then the motor configurations in order, the
-- first one with engine samples is used (review 2026-10-20: some vehicles have them only in a later configuration)
MotorSoundConfigurator.MOD_ENGINE_SOUND_KEYS = { "motorized.sounds" }
MotorSoundConfigurator.MOD_ENGINE_CONFIGURATION_KEY = "motorized.motorConfigurations.motorConfiguration(%d)"
-- deepest chain of parent templates followed for a sample's file (guard against a parent loop)
MotorSoundConfigurator.MOD_ENGINE_TEMPLATE_DEPTH = 8
-- attributes of a sample definition that change its sound (SoundManager:loadSampleAttributesFromXML), part of the
-- identical-engine check together with template, file and the modifier curves (review 2026-10-20)
MotorSoundConfigurator.MOD_ENGINE_SIGNATURE_ATTRIBUTES = { "#volumeScale", "#pitchScale", "#lowpassGainScale", "#loopSynthesisRPMRatio",
    ".volume#indoor", ".volume#outdoor", ".pitch#indoor", ".pitch#outdoor", ".lowpassGain#indoor", ".lowpassGain#outdoor",
    ".lowpassCutoffFrequency#indoor", ".lowpassCutoffFrequency#outdoor", ".lowpassResonance#indoor", ".lowpassResonance#outdoor" }

-- detected engines sorted by button text: list of layer tables like the catalog ones (Layers.lua) plus isModEngine,
-- donorKey, fullName, modTitle, soundFilename, baseKey, sampleNames, baseDir, donorVolumeFactor
MotorSoundConfigurator.modEngines = {}
MotorSoundConfigurator.modEnginesByName = {}
-- layer name of a left-out identical engine -> layer name of the kept one (detectModEngines)
MotorSoundConfigurator.modEngineAliases = {}
-- donor keys already warned about as missing (one warning per engine)
MotorSoundConfigurator.missingModEngineWarned = {}


function MotorSoundConfigurator.isModEngineName(layerName)
    return type(layerName) == "string" and string.startsWith(layerName, MotorSoundConfigurator.MOD_ENGINE_PREFIX)
end


function MotorSoundConfigurator.getModEngineLayerName(donorKey)
    return MotorSoundConfigurator.MOD_ENGINE_PREFIX .. donorKey
end


function MotorSoundConfigurator.getModEngineDonorKey(layerName)
    return string.sub(layerName, string.len(MotorSoundConfigurator.MOD_ENGINE_PREFIX) + 1)
end


-- a mod engine saved for a model whose donor is not available now (mod removed or not active, multiplayer client)
function MotorSoundConfigurator.isModEngineMissing(layerName)
    return MotorSoundConfigurator.isModEngineName(layerName) and MotorSoundConfigurator.modEnginesByName[layerName] == nil
end


-- layer names of the model's mod engines whose donor is missing (sorted), empty list if none
function MotorSoundConfigurator.getMissingModEngines(modelKey)
    local names = {}
    for layerName, _ in pairs(MotorSoundConfigurator.getModelLayers(modelKey) or {}) do
        if MotorSoundConfigurator.isModEngineMissing(layerName) then
            table.insert(names, layerName)
        end
    end
    table.sort(names)
    return names
end


-- the model has a mod engine whose donor is missing (without building the list, called on every apply)
function MotorSoundConfigurator.hasMissingModEngine(modelKey)
    for layerName, _ in pairs(MotorSoundConfigurator.getModelLayers(modelKey) or {}) do
        if MotorSoundConfigurator.isModEngineMissing(layerName) then
            return true
        end
    end
    return false
end


-- one log warning per missing engine (loadSettings), the entry stays in the settings
function MotorSoundConfigurator.warnMissingModEngine(layerName, modelKey)
    local donorKey = MotorSoundConfigurator.getModEngineDonorKey(layerName)
    if not MotorSoundConfigurator.missingModEngineWarned[donorKey] then
        MotorSoundConfigurator.missingModEngineWarned[donorKey] = true
        MotorSoundConfigurator.logWarning("engine of %s is not available (mod / DLC missing or not active), kept in the settings; %s uses its own engine",
            donorKey, tostring(modelKey))
    end
end


-- text cut to maxLength characters (UTF-8, engine functions utf8Strlen / utf8Substr with 0 based start)
function MotorSoundConfigurator.shortenText(text, maxLength)
    if utf8Strlen(text) <= maxLength then
        return text
    end
    return utf8Substr(text, 0, maxLength - 1) .. "..."
end


-- file of a sample or template element: its own file=, otherwise the one of its parent template (#parent, resolved
-- in soundTemplates.xml like SoundManager:loadSampleAttributesFromXML does), nil if none
local function getElementFile(xmlFile, key, depth)
    local file = getXMLString(xmlFile, key .. "#file")
    if file ~= nil and file ~= "" then
        return file
    end
    local parent = getXMLString(xmlFile, key .. "#parent")
    local parentKey = parent ~= nil and g_soundManager.soundTemplates[parent] or nil
    if parentKey ~= nil and g_soundManager.soundTemplateXMLFile ~= nil and depth < MotorSoundConfigurator.MOD_ENGINE_TEMPLATE_DEPTH then
        return getElementFile(g_soundManager.soundTemplateXMLFile, parentKey, depth + 1)
    end
    return nil
end


-- file of a sample definition: its own file= (or of its parent), otherwise the one of its template, nil if none; the
-- game loads the template first and the sample's own attributes on top
local function getSampleDefinitionFile(xmlFile, key, template)
    local file = getElementFile(xmlFile, key, 0)
    if file == nil and template ~= nil and g_soundManager.soundTemplateXMLFile ~= nil then
        file = getElementFile(g_soundManager.soundTemplateXMLFile, g_soundManager.soundTemplates[template], 0)
    end
    return file
end


-- tuning of a sample definition (MOD_ENGINE_SIGNATURE_ATTRIBUTES and every modifier point) as text for the identical-
-- engine check, and whether a modifier uses SUSPENSION (Layers.lua addLayer: only for vehicles with spec_suspensions)
local function readSampleTuning(xmlFile, key)
    local parts = {}
    for _, attribute in ipairs(MotorSoundConfigurator.MOD_ENGINE_SIGNATURE_ATTRIBUTES) do
        table.insert(parts, attribute .. "=" .. (getXMLString(xmlFile, key .. attribute) or ""))
    end
    local usesSuspension = false
    for _, attribute in pairs(SoundManager.SAMPLE_MODIFIER_ATTRIBUTES) do
        local i = 0
        while true do
            local modifierKey = string.format("%s.%s.modifier(%d)", key, attribute, i)
            if not hasXMLProperty(xmlFile, modifierKey) then
                break
            end
            local modifierType = getXMLString(xmlFile, modifierKey .. "#type")
            usesSuspension = usesSuspension or modifierType == "SUSPENSION"
            table.insert(parts, string.format("%s(%d)=%s:%s:%s", attribute, i, tostring(modifierType),
                tostring(getXMLString(xmlFile, modifierKey .. "#value")), tostring(getXMLString(xmlFile, modifierKey .. "#modifiedValue"))))
            i = i + 1
        end
    end
    -- the modifier attributes come in table order (pairs)
    table.sort(parts)
    return table.concat(parts, ","), usesSuspension
end


-- engine samples below baseKey of xmlFile: list of { sampleName = "motor(i)", path, template, tuning, isOwnFile } of the
-- samples that are
-- engines by the same classification as the vehicle's own samples (getSampleCategory). Samples with a template the
-- game does not know are left out (loadSampleFromXML would log an error)
local function collectEngineSamples(xmlFile, baseKey, baseDir)
    local samples = {}
    local needsSuspension = false
    local i = 0
    while true do
        local sampleName = string.format("motor(%d)", i)
        local key = baseKey .. "." .. sampleName
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local template = getXMLString(xmlFile, key .. "#template")
        if template == nil or g_soundManager.soundTemplates[template] ~= nil then
            local file = getSampleDefinitionFile(xmlFile, key, template)
            if file ~= nil then
                local path = Utils.getFilename(file, baseDir)
                local category = MotorSoundConfigurator.getSampleCategory({ templateName = template, filename = path }, false)
                if category == MotorSoundConfigurator.CATEGORY_MOTOR then
                    local tuning, usesSuspension = readSampleTuning(xmlFile, key)
                    -- a file= without "$" lies in the donor's own folder (not a shared base game file)
                    table.insert(samples, { sampleName = sampleName, path = path, template = template, tuning = tuning,
                        isOwnFile = not string.startsWith(file, "$") })
                    needsSuspension = needsSuspension or usesSuspension
                end
            end
        end
        i = i + 1
    end
    return samples, needsSuspension
end


-- engine samples of one store item: the file holding them (vehicle XML or its external sound XML), its base key and
-- the samples, or nil. The open handles are closed here
local function readStoreItemEngine(item)
    local vehicleXml = loadXMLFile("motorSoundConfiguratorDonor", item.xmlFilename)
    if vehicleXml == nil or vehicleXml == 0 then
        return nil
    end
    local baseDir = item.baseDir or ""
    local soundsFilename = getXMLString(vehicleXml, "vehicle.base.sounds#filename")
    local volumeFactor = getXMLFloat(vehicleXml, "vehicle.base.sounds#volumeFactor")
    local soundsXml = nil
    local soundsPath = nil
    if soundsFilename ~= nil then
        soundsPath = Utils.getFilename(soundsFilename, baseDir)
        soundsXml = loadXMLFile("motorSoundConfiguratorDonorSounds", soundsPath)
        if soundsXml == 0 then
            soundsXml = nil
        end
    end

    local soundKeys = {}
    for _, soundKey in ipairs(MotorSoundConfigurator.MOD_ENGINE_SOUND_KEYS) do
        table.insert(soundKeys, soundKey)
    end
    local configIndex = 0
    while true do
        local configKey = string.format(MotorSoundConfigurator.MOD_ENGINE_CONFIGURATION_KEY, configIndex)
        if not hasXMLProperty(vehicleXml, "vehicle." .. configKey) and (soundsXml == nil or not hasXMLProperty(soundsXml, "sounds." .. configKey)) then
            break
        end
        table.insert(soundKeys, configKey .. ".sounds")
        configIndex = configIndex + 1
    end

    local result = nil
    for _, soundKey in ipairs(soundKeys) do
        -- as SoundManager:validateSampleDefinition: the vehicle XML first, then the external sound file
        local sources = { { xmlFile = vehicleXml, path = item.xmlFilename, baseKey = "vehicle." .. soundKey } }
        if soundsXml ~= nil then
            table.insert(sources, { xmlFile = soundsXml, path = soundsPath, baseKey = "sounds." .. soundKey })
        end
        for _, source in ipairs(sources) do
            if result == nil and hasXMLProperty(source.xmlFile, source.baseKey .. ".motor(0)") then
                local samples, needsSuspension = collectEngineSamples(source.xmlFile, source.baseKey, baseDir)
                if #samples > 0 then
                    result = { soundFilename = source.path, baseKey = source.baseKey, samples = samples, needsSuspension = needsSuspension,
                        donorVolumeFactor = volumeFactor }
                end
            end
        end
    end

    if soundsXml ~= nil then
        delete(soundsXml)
    end
    delete(vehicleXml)
    return result
end


-- files of the base game catalog engines (sounds/layers.xml, group SWAP_GROUP, layers.layer(i).motor#file), lower case
-- -> catalog layer name: engines using them only besides shared base game files are left out (already in the catalog),
-- a setting saved for one moves to the catalog engine (modEngineAliases)
local function getCatalogFiles()
    local files = {}
    local xmlFile = MotorSoundConfigurator.getLayerXmlFile()
    if xmlFile == nil then
        return files
    end
    local i = 0
    while true do
        local key = string.format("layers.layer(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local file = getXMLString(xmlFile, key .. ".motor#file")
        local name = getXMLString(xmlFile, key .. "#name")
        if file ~= nil and name ~= nil and getXMLString(xmlFile, key .. "#group") == MotorSoundConfigurator.SWAP_GROUP then
            local lowerPath = string.lower(Utils.getFilename(file, MotorSoundConfigurator.modDirectory))
            files[lowerPath] = files[lowerPath] or name
        end
        i = i + 1
    end
    return files
end


-- title of the mod / DLC of a store item, shown in the help line
local function getStoreItemSourceTitle(item)
    if item.dlcTitle ~= nil and item.dlcTitle ~= "" then
        return item.dlcTitle
    end
    local mod = item.customEnvironment ~= nil and g_modManager ~= nil and g_modManager:getModByName(item.customEnvironment) or nil
    if mod ~= nil and mod.title ~= nil then
        return mod.title
    end
    return tostring(item.customEnvironment)
end


-- brand + store name, like the shop shows it ("None" brand left out)
local function getStoreItemFullName(item)
    local brand = item.brandIndex ~= nil and g_brandManager ~= nil and g_brandManager:getBrandByIndex(item.brandIndex) or nil
    if brand ~= nil and brand.name ~= "NONE" and brand.title ~= nil and brand.title ~= "" then
        return brand.title .. " " .. item.name
    end
    return item.name
end


-- store item in a tractor shop category (base game: tractorsS, tractorsM, tractorsL; StoreManager:loadItem stores the
-- category names of StoreManager:getCategoryByName, compared upper case here)
function MotorSoundConfigurator.isTractorStoreItem(item)
    for _, categoryName in ipairs(item.categoryNames or {}) do
        if string.startsWith(string.upper(categoryName), MotorSoundConfigurator.MOD_ENGINE_TRACTOR_CATEGORY) then
            return true
        end
    end
    return false
end


-- engine of the swap list "Mods & DLCs" (tractor from a mod / DLC); false = "Other vehicles", base game tractors outside
-- the catalog included
function MotorSoundConfigurator.isModTractorEngine(layer)
    return layer.isTractor == true and not layer.isBaseGame
end


-- detected engines of one swap list, sorted like modEngines: isTractor true = tractors from mods / DLCs ("Mods & DLCs"),
-- false = all others ("Other vehicles": other mod / DLC vehicles and the base game vehicles not in the catalog)
function MotorSoundConfigurator.getModEnginesOfKind(isTractor)
    local engines = {}
    for _, layer in ipairs(MotorSoundConfigurator.modEngines) do
        if MotorSoundConfigurator.isModTractorEngine(layer) == isTractor then
            table.insert(engines, layer)
        end
    end
    return engines
end


-- scans the store items in loadMap (StoreManager:loadMapData loads the mod and DLC items before, StoreManager.lua:
-- 168-180; item fields StoreManager:loadItem :856-988); locked DLC items left out (getIsItemUnlocked :707). Base game
-- vehicles are included too (user 2026-10-20: e.g. the Prinoth Leitwolf under "Other vehicles"), the ones whose engine
-- is in the catalog drop out. Base game = the vehicle XML is not in a mod / DLC folder (network filename without
-- "$moddir$" / "$pdlcdir$"); customEnvironment does not tell, a map mod lists base game vehicles under its own one.
-- Items that cannot be read are skipped silently, one summary line in the log
function MotorSoundConfigurator.detectModEngines()
    local startTime = getTimeSec()
    local candidates = {}
    local counts = { vehicles = 0, duplicates = 0, inCatalog = 0 }
    local catalogFiles = getCatalogFiles()

    if g_storeManager ~= nil then
        for _, item in ipairs(g_storeManager:getItems()) do
            if item.species == StoreSpecies.VEHICLE and not item.isBundleItem and item.name ~= nil
                and g_storeManager:getIsItemUnlocked(item) then
                local engine = readStoreItemEngine(item)
                if engine ~= nil then
                    counts.vehicles = counts.vehicles + 1
                    engine.item = item
                    table.insert(candidates, engine)
                end
            end
        end
    end

    local layers = {}
    for _, engine in ipairs(candidates) do
        local item = engine.item
        local donorKey = NetworkUtil.convertToNetworkFilename(item.xmlFilename)
        local isBaseGame = not string.startsWith(donorKey, "$")
        local fullName = getStoreItemFullName(item)
        local modTitle = isBaseGame and g_i18n:getText("msc_swap_sourceBaseGame") or getStoreItemSourceTitle(item)
        local sampleNames = {}
        local signatureParts = {}
        local catalogNames = {}
        local hasOwnFile = false
        for _, sample in ipairs(engine.samples) do
            table.insert(sampleNames, sample.sampleName)
            local lowerPath = string.lower(sample.path)
            table.insert(signatureParts, string.lower(sample.template or "") .. "|" .. lowerPath .. "|" .. sample.tuning)
            if catalogFiles[lowerPath] ~= nil then
                table.insert(catalogNames, catalogFiles[lowerPath])
            end
            hasOwnFile = hasOwnFile or sample.isOwnFile
        end
        table.sort(signatureParts)
        -- already in the catalog: a catalog engine file and otherwise only shared base game files (an engine with own
        -- files of its mod stays, review 2026-10-20); base game vehicles drop out with any catalog file as before
        table.sort(catalogNames)
        local catalogName = nil
        if catalogNames[1] ~= nil and (isBaseGame or not hasOwnFile) then
            catalogName = catalogNames[1]
        end
        table.insert(layers, {
            name = MotorSoundConfigurator.getModEngineLayerName(donorKey),
            group = MotorSoundConfigurator.MOD_ENGINE_GROUP,
            category = MotorSoundConfigurator.CATEGORY_MOTOR,
            -- help line of the "Extra sounds" row ("Source: ...")
            source = string.format("%s (%s)", fullName, modTitle),
            shortName = MotorSoundConfigurator.shortenText(item.name, MotorSoundConfigurator.MOD_ENGINE_SHORT_NAME_LENGTH),
            isOwn = false,
            pitchFactor = 1.0,
            rpmFactor = 1.0,
            volumeFactor = 1.0,
            needsSuspension = engine.needsSuspension,
            isModEngine = true,
            donorKey = donorKey,
            fullName = fullName,
            modTitle = modTitle,
            soundFilename = engine.soundFilename,
            baseKey = engine.baseKey,
            sampleNames = sampleNames,
            baseDir = item.baseDir or "",
            donorVolumeFactor = engine.donorVolumeFactor,
            -- tractor = a shop category tractorsS / M / L (StoreManager keeps the category names upper case); the other
            -- vehicles (trucks, harvesters, loaders, cars, trains ...) get their own list on the swap tab (user 2026-10-20)
            isTractor = MotorSoundConfigurator.isTractorStoreItem(item),
            isBaseGame = isBaseGame,
            signature = table.concat(signatureParts, ";"),
            catalogName = catalogName
        })
    end
    -- natural order of the button text, the full name only between equal ones: isNaturalLess treats "Fendt 942" and
    -- "fendt 942" as equal, a check for different texts alone would make the order inconsistent (table.sort error)
    local function isNameLess(a, b)
        if MotorSoundConfigurator.isNaturalLess(a.shortName, b.shortName) then
            return true
        elseif MotorSoundConfigurator.isNaturalLess(b.shortName, a.shortName) then
            return false
        end
        return a.fullName < b.fullName
    end
    -- sorted first, so the kept one of identical engines does not depend on the store order; the base game vehicle wins
    -- (Leitwolf over the DLC Schouten G400 with the same file)
    table.sort(layers, function(a, b)
        if a.isBaseGame ~= b.isBaseGame then
            return a.isBaseGame
        end
        return isNameLess(a, b)
    end)

    local engines = {}
    local byName = {}
    local signatures = {}
    local aliases = {}
    for _, layer in ipairs(layers) do
        if layer.catalogName ~= nil then
            counts.inCatalog = counts.inCatalog + 1
            -- a setting saved with this donor uses the catalog engine, it is not "missing" (review 2026-10-20)
            aliases[layer.name] = layer.catalogName
        elseif signatures[layer.signature] ~= nil or byName[layer.name] ~= nil then
            counts.duplicates = counts.duplicates + 1
            -- a setting saved with this donor uses the kept engine (modEngineAliases, Settings.lua), it is not "missing"
            local kept = signatures[layer.signature] or byName[layer.name]
            if kept.name ~= layer.name then
                aliases[layer.name] = kept.name
            end
        else
            signatures[layer.signature] = layer
            byName[layer.name] = layer
            table.insert(engines, layer)
        end
    end
    table.sort(engines, isNameLess)

    MotorSoundConfigurator.modEngines = engines
    MotorSoundConfigurator.modEnginesByName = byName
    MotorSoundConfigurator.modEngineAliases = aliases
    MotorSoundConfigurator.missingModEngineWarned = {}
    MotorSoundConfigurator.log("Detected engines: %d (%d mod / DLC tractors) from %d vehicles (%d identical, %d already in the base game catalog) in %d ms",
        #engines, #MotorSoundConfigurator.getModEnginesOfKind(true), counts.vehicles, counts.duplicates, counts.inCatalog,
        math.floor((getTimeSec() - startTime) * 1000 + 0.5))
end


-- loads the engine samples of a mod engine for the vehicle (Layers.lua addLayer): the donor's sound file is opened, every
-- engine sample loaded with the donor folder as base directory (relative file= resolve there) and linked like the
-- catalog engines. Returns the list of samples (may be empty) or nil and a reason
function MotorSoundConfigurator.loadModEngineSamples(vehicle, modEngine)
    local xmlFile = loadXMLFile("motorSoundConfiguratorModEngine", modEngine.soundFilename)
    if xmlFile == nil or xmlFile == 0 then
        return nil, "cannot open " .. tostring(modEngine.soundFilename)
    end
    local linkNode = type(vehicle.components) == "table" and vehicle.components[1] ~= nil and vehicle.components[1].node or nil
    local offset = MotorSoundConfigurator.MOD_ENGINE_OFFSET
    local samples = {}
    for _, sampleName in ipairs(modEngine.sampleNames) do
        -- the donor's linkNode (often an index path like "0>6|1|0|0") would be resolved against the receiving vehicle and
        -- log "Index not found" (user log 2026-10-20); removed from this in-memory copy only, the sample falls back to
        -- the first component (SoundManager:validateSampleDefinition) and is placed below
        removeXMLProperty(xmlFile, modEngine.baseKey .. "." .. sampleName .. "#linkNode")
        local sample = g_soundManager:loadSampleFromXML(xmlFile, modEngine.baseKey, sampleName, modEngine.baseDir, vehicle.components, 0,
            AudioGroup.VEHICLE, vehicle.i3dMappings, vehicle)
        if sample ~= nil then
            if linkNode ~= nil and sample.soundNode ~= nil then
                -- as SoundManager:onCreateAudioSource does with linkNode / linkNodeOffset (SoundManager.lua:514-518)
                sample.linkNode = linkNode
                sample.linkNodeOffset = { offset[1], offset[2], offset[3] }
                link(linkNode, sample.soundNode)
                setTranslation(sample.soundNode, offset[1], offset[2], offset[3])
            end
            -- the receiving vehicle's sound volume factor is applied by loadSampleFromXML (as for the catalog), the
            -- donor's own one here, so the engine is as loud as in its own vehicle
            if modEngine.donorVolumeFactor ~= nil then
                sample.volumeScale = sample.volumeScale * modEngine.donorVolumeFactor
            end
            sample.volumeScale = sample.volumeScale * MotorSoundConfigurator.MOD_ENGINE_VOLUME_FACTOR
            table.insert(samples, sample)
        end
    end
    delete(xmlFile)
    return samples, nil
end
