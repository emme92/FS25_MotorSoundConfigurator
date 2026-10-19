# Motor Sound Configurator – Guide

*Deutsche Version: [ANLEITUNG.md](ANLEITUNG.md)*

The Motor Sound Configurator lets you adjust the engine and transmission sound of your vehicles directly in game:
volume, pitch, RPM character and the sound inside the cabin and from outside, plus the volume of other sounds: cabin & fan,
rattling, work sounds of harvesters, implements and trailers. No XML editing needed.

All values are **relative to the vehicle's original sound**. 100 % means "as intended by the game or by the mod
author". A value of 120 % makes every vehicle a bit louder, and each one still sounds like itself.

---

## Usage

1. Get into a motorized vehicle (tractor, truck, combine …).
2. Press **Alt + M**. For a controller, assign a button in *Options → Controls* ("Adjust engine
   sound"); the keyboard key can be changed there too.
3. Adjust the values. **Every change is audible immediately**, best with the engine running.
4. **Apply** (Enter) saves and closes the menu. **Cancel** (Esc) closes right away if nothing changed. If you
   changed something, the menu asks "Apply changes?": **Yes** saves, **No** discards all changes since you opened
   the menu, both close it.

The menu always opens with **"This model only"**, i.e. for the vehicle you are sitting in.

Hover a control with the mouse and the **help line** at the bottom of the menu explains what it does.

### Menu layout

- On the left the tabs **Engine & gearbox**, **Other sounds**, **Filter**, **Extra sounds**, **Presets** and **Engine swap** (the current one is light with a green
  bar; switch also with **Q / E** or **LB / RB** on a controller). A `*` on a tab or behind a value shows that
  something there differs from the original.
- At the top **Applies to**: "All vehicles" or "This model only" (see below). Extra sounds, presets and the engine swap
  always apply to the model, there the choice is locked or hidden.
- Below them the **Preview**: you cannot drive while the menu is open. With the **RPM** and **Load** controls the
  engine sounds as if it ran at this RPM or under this load, without really revving. So you can hear at standstill
  how your setting sounds at full throttle or when pulling. **Live** = real values, **Back to live** resets both
  controls at once. The preview only affects the
  engine and extra sounds (transmission sounds depend on the speed) and ends when you close the menu. The engine
  must be running.
- Below that **Hear original**: switches all changes and extra sounds off for a moment so you can compare directly
  with the original, also together with the preview. Click again to get your sound back. Any change to a control
  ends the comparison as well.
- Top right you see the **RPM** and **load** the engine sound gets right now (real values or the preview), so you
  can tell when an "under load" sound kicks in.
- At the bottom: **Reset** (current tab only), **Reset model** (everything for this vehicle model: its own engine,
  transmission, cabin & fan, rattle and work sound values and all extra sounds, with a safety question; the values for "All vehicles"
  and those of the attached implements and trailers stay), **Cancel**
  and **Apply**.
- **Controller:** d-pad / left stick selects the element (up / down: first the engine column, then the transmission;
  left / right changes the value of a slider), **A** activates tabs, presets and buttons, **press the right stick** =
  Apply, **B** = Cancel, **LB / RB** = switch tabs. The button bar shows the keys of the device in use.

### Tabs "Engine & gearbox" and "Filter"

Engine and transmission are side by side, each row is one control (see *The controls* below).

| Column | What it contains |
|---|---|
| **Engine** | The engine sound (idle, load, acceleration, with some mods also the turbo). |
| **Transmission** | The transmission sound, e.g. the whine while driving. |

- **Engine & gearbox**: block **Basic sound** with volume, pitch & speed and RPM character.
- **Filter**: how muffled the sound is. Think of the cabin as a wall between you and the engine.
  - Block **In the cabin**: **Openness** (how much of the wall is left; 0 % = original, 100 % = no wall, sounds like
    outside, only quieter), below it **Tone** (how dull it sounds through the wall) and **Presence** (how much the wall
    swallows the sound) for fine tuning. At 100 % openness both are locked. The engine openness also applies to the fans.
  - Block **Outside**: **Tone** and **Presence** in the outside view.
  - **This vehicle** (display only): how muffled engine and transmission sound in the cabin and outside in the original
    and, if your settings change that, now (open / slightly muffled / muffled / strongly muffled).

### Tab "Other sounds"

The volume of all other sounds, as a list: the name on the left, the controls on the right. Rows without such a sound
are left out, so is a whole block when there is nothing for it.

- Block **Vehicle** (the vehicle you are sitting in):
  - **Cabin & fan**: cabin sound, cabin rumble and fan. These sounds belong neither to the engine nor to the
    transmission and otherwise stay audible even with engine and transmission at 0 %.
  - **Parts rattle**: rattling of attached parts on the vehicle itself (e.g. hitch, linkage), triggered by bumps;
    quite loud on some mods.
  - **Work unit** (harvesters): threshing or chopping unit with spin-up and run-down, straw chopper; also the
    switched-on work unit of other machines, e.g. Krone BiG M. Cutting and lifting sounds of the machine itself, e.g.
    of a beet harvester, stay unchanged.
  - **Discharge & filling** (harvesters): forage harvester spout, chopping or dropping straw, filling the grain tank,
    signal when unloading starts. The flowing grain while unloading stays unchanged.
- Block **Implements**: one row per attached implement with a work or drive sound (header, corn header, pickup,
  mower, seeder, cultivator, sprayer, baler …), also behind a forage harvester or a trailer.
  - **Work**: cutting, mowing, sowing, cultivating, plowing, rolling, spraying, baling, tedding, raking, wrapping.
  - **Drive**: what runs while it is switched on, e.g. PTO, seeder blower, sprayer pump, with spin-up and run-down.
  - **Driving rattle**: only when an attached implement rattles while driving (e.g. cultivators, seeders).
- Block **Trailers**: one row per attached trailer or implement that only has **driving rattle** (rattling and
  rumbling while it rolls).

The values of an implement or trailer row apply to **its model**, not to the towing vehicle: a quieter Kemper is
quieter on every forage harvester. Two identical implements share one row. Under "All vehicles" there is one row
**All implements** (work, drive) and one row **All trailers & implements** (driving rattle). A "-" means: the implement
has no such sound. Hydraulics, folding, attaching, plow turning and the baler door stay unchanged.

**Not** changed are single sounds such as starter, gear shifts, retarder, blow-off valve or compressed air.

**Applies to:**

| Option | Meaning |
|---|---|
| **All vehicles** | The values apply to every vehicle. |
| **This model only** | Own values for all vehicles of this model, e.g. all *John Deere 3650*. A **grey** value comes from "All vehicles", a **white** one is an own value of the model. As soon as you move the control, the model has its own value; move it back to the global value and "All vehicles" applies again. |

Example: under "All vehicles" the volume is 80 %. For the Arion you set 110 % under "This model only". Then all
vehicles play at 80 %, only the Arion at 110 %.

**Reset** only resets the controls of the current tab ("Engine & gearbox", "Other sounds" or "Filter"). Under "All
vehicles" they go back to 100 %. Under "This model only" the model's own values are deleted, "All vehicles" applies
again; on "Other sounds" also those of the attached implements and trailers.

### Tab "Extra sounds"

Here you mix additional sounds from the game into the vehicle. There is one row per kind: on the left you choose
the sound (or **Off**), on the right its volume (10–300 %). One sound per kind plays at a time.

| Kind | Content |
|---|---|
| **Engine** | Engines of other vehicles, the older (rougher, punchier) ones come first |
| **Own Engine** | The vehicle's own engine a second time: an octave or fifth lower or under load only |
| **Exhaust** | Exhaust sounds, each steady or "(Load)" (loud when the engine works) |
| **Load & Tone** | Sounds that mainly become audible under load, also old engines that only set in under load |
| **Transmission** | Other transmission sounds, e.g. a mechanical truck transmission instead of a modern one |
| **Parts rattle** | Rattling of attached parts over bumps (as on the JD 3650 or Deutz AgroStar) |
| **Rumble** | Rumble over bumps, only audible inside the cabin |
| **Fan** | Engine fan, old or modern, gets louder with driving speed and load |

Parts rattle and rumble follow the cabin or seat suspension and are only audible on vehicles with a suspended cabin or
seat.

- Sound names follow the scheme *era: source*: **Classic:** old vehicles, **Modern:** new vehicles, **Generic:**
  general base game sounds without a specific vehicle, **Own:** the vehicle's own engine. **(Load)** means "sets in
  under load". Example: *Classic: JD 3650 (Load)*.
- The help line shows which vehicle the chosen sound comes from ("Source: …").
- Extra sounds **always apply to the model**.
- They start and stop with the engine automatically. Their volume is set only here: if e.g. *Transmission →
  Volume* is at 0 %, a mixed-in transmission stays audible. The other controls on "Engine & gearbox" and "Filter" (pitch, RPM,
  tone, presence) affect them too.
- **Reset** on the "Extra sounds" tab switches off all extra sounds of this model.

Tip: extra sounds work best mixed in subtly (20–60 %). If the vehicle's own transmission sounds too shrill, turn it
down on "Engine & gearbox" or darker (tone) on "Filter" and mix in a mechanical one under *Transmission*.

### Tab "Presets"

Ready-made settings to click, the easiest way to start. Presets **always apply to the model**.

| Column | Presets |
|---|---|
| **Engine** | Punchier, Deeper, More bass, More punch under load |
| **Exhaust** | Open, Big |
| **Transmission** | Quieter, More present, Less shrill, More muffled |
| **Cabin** | Insulated, Open / vintage |

- A click applies the preset, audible immediately. The help line shows which values it sets.
- A preset **only changes its own values**, everything else stays. So you can combine several, e.g. *More bass* +
  *Cabin: Insulated*. If two presets set the same value, the last one chosen wins.
- **Green** = active, i.e. all values of the preset are still set like that. If you change one of them on the
  "Engine & gearbox" or "Filter" tab afterwards, it is no longer green.
- Clicking a green preset again removes it: its values go back to "All vehicles" (grey), its extra sounds off.
- Many presets mix in extra sounds (own engine, general sounds, exhausts). They replace another sound of the same
  kind.
- **Reset** on the "Presets" tab works like **Reset model**.

### Tab "Engine swap"

Replaces the engine sound of the model **completely** with the engine of another vehicle: all tractor engines of the
base game (vehicles with the same engine only once), plus the MF 8570 combine and two trucks, sorted alphabetically.

- A click on an engine swaps it in: the own engine goes to **0 %** (on "Engine & gearbox", *Engine → Volume* then shows 0 %), the
  other engine plays at 100 %. **Green** = active engine, only one can be active.
- An extra sound of the kind **Own Engine** (e.g. from the preset *More bass*) is switched off by the swap, otherwise
  the own engine would stay audible.
- If you switch the swapped-in engine off on the "Extra sounds" tab (row *Engine* to **Off** or **Reset**), the swap
  ends as well and the own engine comes back.
- Electric drives (e.g. Volvo FH Electric) count as engine: their whine can be adjusted on "Engine & gearbox" / "Filter" (except
  *RPM character*: the whine follows the driving speed, not the RPM, the slider is hidden in "This model only") and
  replaced by a combustion engine with a swap. Vehicles **without any own engine sound** cannot swap: the engines are
  locked and a hint is shown at the top; on "Engine & gearbox" / "Filter" the engine sliders are hidden in "This model only"
  (as is every other kind the vehicle has no sounds of).
- **Own engine** (top left) or a click on the green engine ends the swap: *Engine → Volume* goes back to "All
  vehicles", the other engine off. If the model had its own value for *Engine → Volume* before the swap (e.g.
  120 %), it does not come back. Set it again on "Engine & gearbox" afterwards.
- If you change *Engine → Volume* during a swap (or a preset does), the other engine keeps playing as an extra sound
  and "Own engine" is green. A click on "Own engine" then switches the other engine off.
- **Swap engine** (slider at the top) controls the volume of the swapped-in engine (10–300 %, 100 % ≈ as loud as in its own vehicle).
- Pitch, RPM character, tone and presence from "Engine & gearbox" / "Filter" also act on the swapped-in engine.
- The swapped-in engine is also listed on the "Extra sounds" tab under *Engine*. There you can **mix in** another
  engine instead, without muting the own one.
- **Reset** on the "Engine swap" tab works like **Own engine**.

---

## The controls

All controls range from 0 % to 300 %, 100 % is the original. Pitch & speed and RPM character start at 5 %.
*Cabin: tone* goes up to 1000 %, because the cabin is strongly filtered in the original; *Cabin: openness* goes from 0 %
(original) to 100 %. "Cabin: …" and "Outside: …" are on the "Filter" tab under "In the cabin" and "Outside".

| Control | What it does | Tips |
|---|---|---|
| **Volume** | How loud the sound is. | 0 % = muted. |
| **Pitch & speed** | Plays the sound faster or slower. Higher sounds brighter and faster, lower darker and slower. | Also changes the engine's **firing rhythm**. For just a darker sound use *tone* instead. Good for small corrections on the transmission. |
| **RPM character** | Above 100 % the engine sounds like it revs higher. Below 100 % it sounds like a bigger, slower revving engine. Tone and rhythm change together, but naturally. | Acts with rising RPM, **idle stays the same**. Usually no effect on the transmission. |
| **Cabin: openness** | How much of the cabin wall is left. 0 % = original, 100 % = no wall: sounds inside the cabin like outside, only quieter. | The easiest way to a more open cabin. For the engine it also applies to the fans. Cabin sound and cabin rumble stay (volume under "Cabin & fan" on the "Other sounds" tab). |
| **Cabin: tone** | How dull it sounds through the cabin wall. Less = duller, only a hum; more = brighter, more detail from the engine. | For fine tuning; acts less the higher the openness, locked at 100 %. |
| **Cabin: presence** | How much the cabin wall swallows the sound. Less = further away, muffled; more = more direct, closer. | Like *Cabin: tone* for fine tuning, locked at 100 % openness. |
| **Outside: tone** | How the sound is shaped in the outside view. Lower sounds duller. | Only has an effect **if Outside: presence is below 100 %**. Outside, the original sound is usually not muffled, then values above 100 % change nothing. |
| **Outside: presence** | How much the sound is muffled in the outside view. Lower = more muffled. | Most vehicles are not muffled outside at all (that is already the maximum), so **only values below 100 % have an effect**. Above 100 % only helps vehicles that also muffle outside. Go below 100 % here first, then shape the character with *Outside: tone*. |

---

## Examples

| Goal | Setting |
|---|---|
| Cabin sounds as open as outside | Engine (and transmission if wanted) → *Cabin: openness* to 100 % |
| Engine more punchy inside the cabin | Engine → *Cabin: tone* to 150–200 % |
| Engine louder in the cabin without being louder outside | Engine → *Cabin: presence* to 130–150 % |
| Quieter transmission whine | Transmission → *Volume* to 50 % |
| Engine duller outside, as if from a distance | Engine → *Outside: presence* to 50 %, then *Outside: tone* to 20–40 % |
| Sounds like a bigger, slower revving engine | Engine → *RPM character* to 85–90 % |
| Adjust only one vehicle model | *Applies to* "This model only", then as above |

Change one control at a time and listen at idle **and** under load.

---

## Saving

- Settings are stored **per savegame**: with **Apply** and when saving the game, in the file
  `motorSoundConfigurator.xml` in the savegame folder (e.g. `Documents\My Games\FarmingSimulator2025\savegame1`).
- **New savegame:** there is no folder until the first save. Your settings still apply and are written with the
  first save.
- Model settings are matched by the vehicle file, so they apply to all vehicles of that model, including newly bought ones.

## Multiplayer

The mod works **on your side only**: sounds only play on your computer, nothing is sent to other players. As with
every multiplayer mod, all players need it installed, but each one has **their own settings**.

| You are … | Saved in |
|---|---|
| Single player or host | `motorSoundConfigurator.xml` in the savegame (see above) |
| Joining player | `Documents\My Games\FarmingSimulator2025\modSettings\FS25_MotorSoundConfigurator\settings.xml`, **one file for all servers**, saved with **Apply** |

On a dedicated server (no player, no sound) the mod is inactive.

---

## Known limitations

- **Pitch & speed** always changes the engine's rhythm as well. The game offers no pitch change without a speed change.
- **RPM character** does not change idle.
- **Outside: tone** only works together with *Outside: presence* below 100 %.
- For **mod vehicles** the mod assigns engine and transmission sounds by their sound file. With unusually built mods
  a sound may end up in the wrong category or stay unchanged.
- Very high values (200–300 %) can sound distorted or unnatural depending on the vehicle.

---

## Advanced: console commands

The game's developer console offers these commands (factor 1.0 = 100 %):

| Command | Effect |
|---|---|
| `mscSet <category> <parameter> <factor>` | Sets a value for all vehicles. Categories: `motor`, `gearbox`, `cabin` (cabin & fan), `rattle` (parts rattle), `work` / `discharge` (work unit / discharge & filling), `implementWork` / `implementDrive` / `implementRattle` (work / drive / driving rattle of implements and trailers); all but engine, transmission and cabin `volume` only. |
| `mscSetVehicle <category> <parameter> <factor>` | Sets a value for the model you are sitting in. |
| `mscResetVehicle [<category>]` | Removes the own values of this model. |
| `mscInfo` | Writes the current values of the vehicle to `log.txt`. |
| `mscReload` | Reloads the settings file (`motorSoundConfigurator.xml` in the savegame, as a multiplayer client `modSettings/FS25_MotorSoundConfigurator/settings.xml`), e.g. after editing it by hand. |
| `mscLayer <name> [volume\|remove]` | Switches an extra sound on for the model (volume as factor; replaces the sound of the same group) or off; without a name it lists all available ones. |
| `mscDebug` | Switches the detailed log on / off (detected sounds per vehicle, extra sounds, all values). |

Parameters: `volume`, `pitch`, `rpm`, `cutoffIndoor` (Cabin: tone), `gainIndoor` (Cabin: presence),
`cutoffOutdoor` (Outside: tone), `gainOutdoor` (Outside: presence), `indoorDamping` (cabin damping: 1.0 = original =
openness 0 %, 0.0 = openness 100 %).

## Reporting problems

All messages of the mod are in `Documents\My Games\FarmingSimulator2025\log.txt` and start with
`[MotorSoundConfigurator]`. Normally these are only a few lines (start, load, save, errors). For a problem with a
vehicle: get in, enter `mscInfo` in the console (writes the detected sounds and their values to the log) and include
these lines. `mscDebug` additionally switches on detailed lines when vehicles and extra sounds are loaded.
