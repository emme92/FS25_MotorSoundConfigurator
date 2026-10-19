# Motor Sound Configurator – Anleitung

*English version: [GUIDE.md](GUIDE.md)*

Mit dem Motor Sound Configurator stellst du den Klang von Motor und Getriebe deiner Fahrzeuge direkt im Spiel ein:
Lautstärke, Tonhöhe, Drehzahl-Charakter und den Klang in der Kabine und von außen. Dazu kommt die Lautstärke weiterer
Geräusche: Kabine & Lüfter, Klappern, Arbeitsgeräusche von Erntemaschinen, Anbaugeräten und Anhängern. Du musst dafür
keine XML-Dateien bearbeiten.

Alle Werte sind **relativ zum Original-Sound des Fahrzeugs**. 100 % heißt „so wie vom Hersteller der Mod bzw. vom
Spiel vorgesehen“. Ein Wert von 120 % macht also jedes Fahrzeug etwas lauter, und jedes klingt dabei weiter nach sich selbst.

---

## Bedienung

1. Steig in ein motorisiertes Fahrzeug (Traktor, LKW, Mähdrescher …).
2. Drück **Alt + M**. Für den Controller belegst du unter *Optionen → Steuerung* eine Taste
   („Motorsound einstellen“), dort lässt sich auch die Tastatur-Taste ändern.
3. Stell die Werte ein. **Jede Änderung ist sofort zu hören**, am besten bei laufendem Motor.
4. **Übernehmen** (Enter) speichert und schließt das Menü. **Abbrechen** (Esc) schließt ohne Änderungen sofort. Hast
   du etwas geändert, fragt das Menü „Änderungen übernehmen?“: **Ja** speichert, **Nein** verwirft alle Änderungen
   seit dem Öffnen, beide schließen das Menü.

Das Menü öffnet immer mit **„Nur dieses Modell“**, also für das Fahrzeug, in dem du sitzt.

Fährst du mit der Maus über einen Regler, erklärt die **Hilfezeile** unten im Menü, was er bewirkt.

### Aufbau des Menüs

- Links die Reiter **Motor & Getriebe**, **Geräusche**, **Dämpfung**, **Zusatz-Sounds**, **Presets** und **Motor-Tausch** (der aktuelle ist hell mit grünem Balken;
  wechseln auch mit **Q / E** bzw. am Controller **LB / RB**). Ein `*` am Reiter oder hinter einem Wert zeigt, dass dort
  etwas vom Original abweicht.
- Oben **Gilt für**: „Alle Fahrzeuge“ oder „Nur dieses Modell“ (siehe unten). Zusatz-Sounds, Presets und Motor-Tausch
  gelten immer für das Modell, dort ist die Auswahl gesperrt bzw. ausgeblendet.
- Darunter die **Vorschau**: Solange das Menü offen ist, kannst du nicht fahren. Mit den Reglern **Drehzahl** und
  **Last** klingt der Motor so, als liefe er mit dieser Drehzahl bzw. unter dieser Last, ohne wirklich hochzudrehen.
  So hörst du im Stand, wie deine Einstellung bei Vollgas oder beim Ziehen klingt. **Live** = echte Werte,
  **Zurück auf Live** setzt beide Regler auf einmal zurück. Die
  Vorschau gilt nur für Motor und Zusatz-Sounds (Getriebe-Sounds hängen von der Geschwindigkeit ab) und endet, wenn
  du das Menü schließt. Der Motor muss laufen.
- Darunter **Original anhören**: schaltet alle Änderungen und Zusatz-Sounds vorübergehend ab, damit du direkt mit dem
  Original vergleichen kannst, auch zusammen mit der Vorschau. Nochmal klicken schaltet deinen Klang wieder ein. Jede
  Änderung an einem Regler beendet den Vergleich ebenfalls.
- Oben rechts siehst du **Drehzahl** und **Last**, die der Motor-Sound gerade bekommt (echte Werte oder die
  Vorschau). So erkennst du, wann ein Sound „unter Last“ einsetzt.
- Unten: **Zurücksetzen** (nur der aktuelle Reiter), **Modell zurücksetzen** (alles für dieses Fahrzeugmodell: eigene
  Werte von Motor, Getriebe, Kabine & Lüfter, Klappern und Arbeitsgeräuschen und alle Zusatz-Sounds, mit Sicherheitsabfrage; die Werte für „Alle Fahrzeuge“
  und die der angehängten Anbaugeräte und Anhänger bleiben), **Abbrechen** und **Übernehmen**.
- **Controller:** Steuerkreuz / linker Stick wählt das Element (hoch / runter: erst die Spalte Motor, dann Getriebe;
  links / rechts ändert den Wert eines Reglers), **A** löst Reiter, Presets und Knöpfe aus, **rechten Stick drücken** =
  Übernehmen, **B** = Abbrechen, **LB / RB** = Reiter wechseln. Die Knopfleiste zeigt die Tasten des gerade benutzten
  Geräts.

### Reiter „Motor & Getriebe“ und „Dämpfung“

Motor und Getriebe stehen nebeneinander, jede Zeile ist ein Regler (siehe *Die Regler* unten).

| Spalte | Was dazugehört |
|---|---|
| **Motor** | Das Motorgeräusch (Leerlauf, Last, Beschleunigung, bei manchen Mods auch Turbo). |
| **Getriebe** | Das Getriebegeräusch, z. B. das Heulen beim Fahren. |

- **Motor & Getriebe**: Block **Grundklang** mit Lautstärke, Tonhöhe & Tempo und Drehzahl-Charakter.
- **Dämpfung**: wie gedämpft der Sound klingt. Stell dir die Kabine als Wand zwischen dir und dem Motor vor.
  - Block **In der Kabine**: **Offenheit** (wie viel von der Wand übrig ist; 0 % = Original, 100 % = keine Wand, klingt
    wie draußen, nur leiser), darunter **Klangfarbe** (wie dumpf es durch die Wand klingt) und **Präsenz** (wie stark
    die Wand den Klang schluckt) zum Nachjustieren. Bei 100 % Offenheit sind die beiden gesperrt. Die Offenheit beim
    Motor gilt auch für die Lüfter.
  - Block **Draußen**: **Klangfarbe** und **Präsenz** in der Außenansicht.
  - **Dieses Fahrzeug** (nur Anzeige): wie gedämpft Motor und Getriebe in der Kabine und draußen im Original klingen und,
    wenn deine Einstellungen das ändern, wie jetzt (offen / leicht gedämpft / gedämpft / stark gedämpft).

### Reiter „Geräusche“

Die Lautstärke aller übrigen Geräusche, als Liste: links der Name, rechts die Regler. Zeilen ohne passenden Sound fallen
weg, ebenso ein ganzer Block, wenn nichts dazu da ist.

- Block **Fahrzeug** (das Fahrzeug, in dem du sitzt):
  - **Kabine & Lüfter**: Kabinengeräusch, Kabinen-Rumpeln und Lüfter. Diese Sounds gehören weder zum Motor noch zum
    Getriebe und bleiben sonst auch bei Motor und Getriebe auf 0 % hörbar.
  - **Anbauteile-Klappern**: Klappern von Anbauteilen am Fahrzeug selbst (z. B. Hubwerk, Kupplung), ausgelöst bei
    Bodenwellen; bei manchen Mods recht laut.
  - **Arbeitswerk** (Erntemaschinen): Dresch- oder Häckselwerk mit Hoch- und Auslaufen, Strohhäcksler; auch das
    eingeschaltete Arbeitswerk anderer Maschinen, z. B. Krone BiG M. Schneid- und Rodegeräusche der Maschine selbst,
    z. B. eines Rübenroders, bleiben unverändert.
  - **Auswurf & Befüllen** (Erntemaschinen): Häcksler-Auswurf, Stroh häckseln bzw. ablegen, Korntank füllen, Signal
    beim Abtanken. Das fließende Korn beim Abtanken bleibt unverändert.
- Block **Anbaugeräte**: eine Zeile pro angehängtem Gerät mit Arbeits- oder Antriebsgeräusch (Schneidwerk,
  Maisgebiss, Pickup, Mähwerk, Sämaschine, Grubber, Spritze, Presse …), auch hinter einem Häcksler oder Anhänger.
  - **Arbeit**: Schneiden, Mähen, Säen, Grubbern, Pflügen, Walzen, Sprühen, Pressen, Wenden, Schwaden, Wickeln.
  - **Antrieb**: was beim Einschalten läuft, z. B. Zapfwelle, Gebläse der Sämaschine, Pumpe der Spritze, mit Hoch- und
    Auslaufen.
  - **Fahr-Klappern**: nur wenn ein angehängtes Gerät beim Fahren klappert (z. B. Grubber, Sämaschinen).
- Block **Anhänger**: eine Zeile pro angehängtem Anhänger oder Gerät, das nur **Fahr-Klappern** hat (Klappern und
  Rumpeln, solange er rollt).

Die Werte einer Anbaugeräte- oder Anhänger-Zeile gelten für **dessen Modell**, nicht für das Zugfahrzeug: ein
leiserer Kemper ist an jedem Häcksler leiser. Zwei gleiche Geräte teilen sich eine Zeile. Unter „Alle Fahrzeuge“ gibt es
je eine Zeile **Alle Anbaugeräte** (Arbeit, Antrieb) und **Alle Anhänger & Anbaugeräte** (Fahr-Klappern). Ein „-“
heißt: Das Gerät hat diesen Sound nicht. Hydraulik, Klappen, Ankuppeln, Pflug-Wenden und die Klappe der Presse bleiben
unverändert.

**Nicht** verändert werden Einzelgeräusche wie Anlasser, Schaltgeräusche, Retarder, Blow-off-Ventil oder Druckluft.

**Gilt für:**

| Auswahl | Bedeutung |
|---|---|
| **Alle Fahrzeuge** | Die Werte gelten für jedes Fahrzeug. |
| **Nur dieses Modell** | Eigene Werte für alle Fahrzeuge dieses Modells, z. B. alle *John Deere 3650*. Ein **grauer** Wert kommt von „Alle Fahrzeuge“, ein **weißer** ist ein eigener Wert des Modells. Sobald du den Regler verschiebst, hat das Modell einen eigenen Wert; schiebst du ihn zurück auf den globalen Wert, gilt wieder „Alle Fahrzeuge“. |

Beispiel: Unter „Alle Fahrzeuge“ steht die Lautstärke auf 80 %. Für den Arion stellst du unter „Nur dieses Modell“ 110 %
ein. Dann sind alle Fahrzeuge bei 80 %, nur der Arion bei 110 %.

**Zurücksetzen** setzt nur die Regler des aktuellen Reiters („Motor & Getriebe“, „Geräusche“ oder „Dämpfung“) zurück.
Unter „Alle Fahrzeuge“ gehen sie auf 100 %. Unter „Nur dieses Modell“ werden die eigenen Werte des Modells gelöscht,
danach gilt wieder „Alle Fahrzeuge“; im Reiter „Geräusche“ auch die der angehängten Anbaugeräte und Anhänger.

### Reiter „Zusatz-Sounds“

Hier mischst du dem Fahrzeug weitere Sounds aus dem Spiel dazu. Pro Art gibt es eine Zeile: links wählst du den
Sound (oder **Aus**), rechts die Lautstärke (10–300 %). Pro Art läuft ein Sound gleichzeitig.

| Art | Inhalt |
|---|---|
| **Motor** | Motoren anderer Fahrzeuge, die älteren (raueren, kernigeren) stehen vorne |
| **Eigener Motor** | Der eigene Motor ein zweites Mal: eine Oktave oder Quinte tiefer oder nur unter Last |
| **Auspuff** | Auspuffgeräusche, jeweils gleichmäßig oder „(Last)“ (laut, wenn der Motor arbeitet) |
| **Last & Ton** | Sounds, die vor allem bei Last hörbar werden, auch alte Motoren, die erst unter Last einsetzen |
| **Getriebe** | Andere Getriebegeräusche, z. B. ein mechanisches LKW-Getriebe statt eines modernen |
| **Anbauteile-Klappern** | Klappern von Anbauteilen bei Bodenwellen (wie bei JD 3650 oder Deutz AgroStar) |
| **Rumpeln** | Rumpeln bei Bodenwellen, nur in der Kabine hörbar |
| **Lüfter** | Motorlüfter, alt oder modern, wird mit Fahrgeschwindigkeit und Last lauter |

Anbauteile-Klappern und Rumpeln folgen der Kabinen- oder Sitzfederung und sind nur bei Fahrzeugen mit gefederter Kabine oder
gefedertem Sitz hörbar.

- Die Sound-Namen sind nach dem Schema *Zeit: Quelle* aufgebaut: **Klassisch:** alte Fahrzeuge, **Modern:** neue
  Fahrzeuge, **Allgemein:** allgemeine Basisspiel-Sounds ohne bestimmtes Fahrzeug, **Eigener:** der eigene Motor.
  **(Last)** heißt „setzt unter Last ein“. Beispiel: *Klassisch: JD 3650 (Last)*.
- Die Hilfezeile zeigt, aus welchem Fahrzeug der gewählte Sound stammt („Quelle: …“).
- Zusatz-Sounds gelten **immer für das Modell**.
- Sie laufen automatisch mit dem Motor an und aus. Ihre Lautstärke stellst du nur hier ein: Steht z. B. *Getriebe →
  Lautstärke* auf 0 %, bleibt ein zugemischtes Getriebe hörbar. Die übrigen Regler in „Motor & Getriebe“ und „Dämpfung“ (Tonhöhe,
  Drehzahl, Klangfarbe, Präsenz) wirken auch auf sie.
- **Zurücksetzen** schaltet im Reiter „Zusatz-Sounds“ alle Zusatz-Sounds dieses Modells aus.

Tipp: Zusatz-Sounds klingen am besten dezent dazugemischt (20–60 %). Klingt das eigene Getriebe zu schrill, stell es
in „Motor & Getriebe“ leiser oder in „Dämpfung“ dunkler (Klangfarbe) und misch unter *Getriebe* ein mechanisches dazu.

### Reiter „Presets“

Fertige Einstellungen zum Anklicken, der einfachste Einstieg. Presets gelten **immer für das Modell**.

| Spalte | Presets |
|---|---|
| **Motor** | Kerniger, Brummiger, Mehr Bass, Mehr Druck unter Last |
| **Auspuff** | Offen, Groß |
| **Getriebe** | Leiser, Präsenter, Weniger schrill, Gedämpfter |
| **Kabine** | Gedämmt, Offen / Oldtimer |

- Ein Klick wendet das Preset an, sofort hörbar. Die Hilfezeile zeigt, welche Werte es setzt.
- Ein Preset ändert **nur seine eigenen Werte**, alles andere bleibt. Deshalb kannst du mehrere kombinieren, z. B.
  *Mehr Bass* + *Kabine: Gedämmt*. Setzen zwei Presets denselben Wert, gilt das zuletzt gewählte.
- **Grün** = aktiv, d. h. alle Werte des Presets stehen noch so. Verstellst du danach einen davon in „Motor & Getriebe“ oder „Dämpfung“,
  ist es nicht mehr grün.
- Ein erneuter Klick auf ein grünes Preset entfernt es: seine Werte gehen zurück auf „Alle Fahrzeuge“ (grau), seine Zusatz-Sounds
  aus.
- Viele Presets mischen Zusatz-Sounds dazu (eigener Motor, allgemeine Sounds, Auspuff). Sie ersetzen einen anderen
  Sound derselben Art.
- **Zurücksetzen** wirkt im Reiter „Presets“ wie **Modell zurücksetzen**.

### Reiter „Motor-Tausch“

Ersetzt den Motor-Sound des Modells **ganz** durch den Motor eines anderen Fahrzeugs: alle Traktormotoren des
Basisspiels (Fahrzeuge mit gleichem Motor nur einmal), dazu der MF-8570-Mähdrescher und zwei LKW, alphabetisch sortiert.

- Ein Klick auf einen Motor tauscht ihn ein: der eigene Motor geht auf **0 %** (in „Motor & Getriebe“ steht *Motor → Lautstärke*
  dann auf 0 %), der andere Motor läuft mit 100 %. **Grün** = aktiver Motor, es ist immer nur einer aktiv.
- Ein Zusatz-Sound der Art **Eigener Motor** (z. B. vom Preset *Mehr Bass*) wird beim Tausch ausgeschaltet, sonst wäre
  der eigene Motor weiter zu hören.
- Schaltest du den eingetauschten Motor im Reiter „Zusatz-Sounds“ aus (Zeile *Motor* auf **Aus** oder
  **Zurücksetzen**), endet der Tausch ebenfalls und der eigene Motor kommt zurück.
- Elektroantriebe (z. B. Volvo FH Electric) zählen als Motor: ihr Surren lässt sich in „Motor & Getriebe“ / „Dämpfung“ einstellen
  (außer *Drehzahl-Charakter*: das Surren folgt der Fahrgeschwindigkeit, nicht der Drehzahl, der Regler ist bei „Nur dieses Modell“ ausgeblendet)
  und per Tausch durch einen Verbrennungsmotor ersetzen. Fahrzeuge **ganz ohne eigenen Motor-Sound** können nicht
  tauschen: die Motoren sind gesperrt, ein Hinweis steht oben; in „Motor & Getriebe“ / „Dämpfung“ sind die Motor-Regler bei
  „Nur dieses Modell“ ausgeblendet (ebenso jede andere Art, von der das Fahrzeug keine Sounds hat).
- **Eigener Motor** (oben links) oder ein Klick auf den grünen Motor beendet den Tausch: *Motor → Lautstärke* geht
  zurück auf „Alle Fahrzeuge“, der fremde Motor aus. Hatte das Modell vor dem Tausch einen eigenen Wert für *Motor →
  Lautstärke* (z. B. 120 %), kommt dieser nicht zurück. Stell ihn danach in „Motor & Getriebe“ wieder ein.
- Verstellst du während eines Tauschs *Motor → Lautstärke* (oder ein Preset tut es), läuft der fremde Motor als
  Zusatz-Sound weiter und „Eigener Motor“ ist grün. Ein Klick auf „Eigener Motor“ schaltet den fremden Motor dann ab.
- **Tausch-Motor** (Regler oben) regelt die Lautstärke des eingetauschten Motors (10–300 %, 100 % ≈ so laut wie in seinem eigenen Fahrzeug).
- Tonhöhe, Drehzahl-Charakter, Klangfarbe und Präsenz aus „Motor & Getriebe“ / „Dämpfung“ wirken auch auf den eingetauschten Motor.
- Der eingetauschte Motor steht auch im Reiter „Zusatz-Sounds“ unter *Motor*. Dort kannst du einen fremden Motor
  stattdessen **dazumischen**, ohne den eigenen stumm zu schalten.
- **Zurücksetzen** wirkt im Reiter „Motor-Tausch“ wie **Eigener Motor**.

---

## Die Regler

Alle Regler gehen von 0 % bis 300 %, 100 % ist das Original. Tonhöhe und Drehzahl-Charakter beginnen bei 5 %.
*Kabine: Klangfarbe* geht bis 1000 %, weil die Kabine im Original stark gefiltert ist; *Kabine: Offenheit* geht von 0 %
(Original) bis 100 %. „Kabine: …“ und „Außen: …“ stehen im Reiter „Dämpfung“ unter „In der Kabine“ bzw. „Draußen“.

| Regler | Was er macht | Tipps |
|---|---|---|
| **Lautstärke** | Wie laut der Sound ist. | 0 % = stumm. |
| **Tonhöhe & Tempo** | Spielt den Sound schneller oder langsamer ab. Höher klingt heller und schneller, tiefer dunkler und langsamer. | Ändert beim Motor auch den **Takt**. Wenn du nur einen dunkleren Klang willst, nimm lieber *Klangfarbe*. Beim Getriebe gut für kleine Korrekturen. |
| **Drehzahl-Charakter** | Über 100 % klingt der Motor, als würde er höher drehen. Unter 100 % klingt er wie ein größerer, langsamer drehender Motor. Klang und Takt ändern sich zusammen, aber natürlich. | Wirkt erst mit steigender Drehzahl, **der Leerlauf bleibt gleich**. Beim Getriebe meist ohne Wirkung. |
| **Kabine: Offenheit** | Wie viel von der Kabinenwand übrig ist. 0 % = Original, 100 % = keine Wand: klingt in der Kabine wie draußen, nur leiser. | Der einfachste Weg zu einer offeneren Kabine. Gilt beim Motor auch für die Lüfter. Kabinenton und Kabinenbrummen bleiben (Lautstärke unter „Kabine & Lüfter“ im Reiter „Geräusche“). |
| **Kabine: Klangfarbe** | Wie dumpf es durch die Kabinenwand klingt. Weniger = dumpfer, nur noch Brummen; mehr = heller, mehr Details vom Motor. | Zum Nachjustieren; wirkt umso weniger, je höher die Offenheit, bei 100 % gesperrt. |
| **Kabine: Präsenz** | Wie stark die Kabinenwand den Klang schluckt. Weniger = weiter weg, gedämpft; mehr = direkter, näher dran. | Wie *Kabine: Klangfarbe* zum Nachjustieren, bei 100 % Offenheit gesperrt. |
| **Außen: Klangfarbe** | Wie der Sound in der Außenansicht klingt. Niedriger klingt dumpfer. | Wirkt **nur, wenn Außen: Präsenz unter 100 %** liegt. Draußen ist der Sound im Original meist ungedämpft, Werte über 100 % ändern dann nichts. |
| **Außen: Präsenz** | Wie stark der Sound in der Außenansicht gedämpft wird. Niedriger = gedämpfter. | Die meisten Fahrzeuge sind draußen gar nicht gedämpft (das ist schon das Maximum), daher **wirken nur Werte unter 100 %**. Über 100 % hilft nur bei Fahrzeugen, die auch draußen dämpfen. Erst hier unter 100 % gehen, dann mit *Außen: Klangfarbe* den Charakter einstellen. |

---

## Beispiele

| Ziel | Einstellung |
|---|---|
| Kabine klingt so offen wie draußen | Motor (und ggf. Getriebe) → *Kabine: Offenheit* auf 100 % |
| Motor in der Kabine kerniger | Motor → *Kabine: Klangfarbe* auf 150–200 % |
| Motor in der Kabine lauter, ohne dass er draußen lauter wird | Motor → *Kabine: Präsenz* auf 130–150 % |
| Getriebe-Heulen leiser | Getriebe → *Lautstärke* auf 50 % |
| Motor draußen dumpfer, wie aus der Ferne | Motor → *Außen: Präsenz* auf 50 %, dann *Außen: Klangfarbe* auf 20–40 % |
| Klingt wie ein größerer, langsamer drehender Motor | Motor → *Drehzahl-Charakter* auf 85–90 % |
| Nur ein Fahrzeug-Modell anpassen | *Gilt für* auf „Nur dieses Modell“, dann wie oben |

Am besten änderst du immer nur einen Regler und hörst dir das Ergebnis im Leerlauf **und** unter Last an.

---

## Speichern

- Die Einstellungen gelten **pro Spielstand**. Gespeichert werden sie mit **Übernehmen** und beim Speichern des
  Spielstands, und zwar in der Datei `motorSoundConfigurator.xml` im Ordner des Spielstands
  (z. B. `Dokumente\My Games\FarmingSimulator2025\savegame1`).
- **Neuer Spielstand:** Bis zum ersten Speichern gibt es noch keinen Ordner. Deine Einstellungen gelten trotzdem und
  werden beim ersten Speichern mitgeschrieben.
- Einstellungen pro Modell werden über die Fahrzeug-Datei erkannt. Sie gelten also für alle Fahrzeuge dieses Modells,
  auch für neu gekaufte.

## Multiplayer

Die Mod wirkt **nur bei dir**: Sounds laufen nur auf deinem Rechner, an andere Spieler wird nichts gesendet. Wie bei
jeder Multiplayer-Mod müssen alle Spieler sie installiert haben, jeder hat aber **eigene Einstellungen**.

| Du bist … | Gespeichert in |
|---|---|
| Einzelspieler oder Host | `motorSoundConfigurator.xml` im Spielstand (siehe oben) |
| Mitspieler | `Dokumente\My Games\FarmingSimulator2025\modSettings\FS25_MotorSoundConfigurator\settings.xml`, **eine Datei für alle Server**, gespeichert mit **Übernehmen** |

Auf einem dedizierten Server (ohne Spieler und ohne Ton) ist die Mod inaktiv.

---

## Bekannte Grenzen

- **Tonhöhe & Tempo** ändert beim Motor immer auch den Takt. Eine Tonhöhenänderung ohne Tempoänderung bietet das Spiel nicht.
- **Drehzahl-Charakter** ändert den Leerlauf nicht.
- **Außen: Klangfarbe** wirkt nur zusammen mit *Außen: Präsenz* unter 100 %.
- Bei **Mod-Fahrzeugen** ordnet die Mod Motor- und Getriebe-Sounds anhand der Sound-Datei zu. Bei ungewöhnlich
  aufgebauten Mods kann ein Sound in der falschen Kategorie landen oder unverändert bleiben.
- Sehr hohe Werte (200–300 %) können je nach Fahrzeug übersteuert oder unnatürlich klingen.

---

## Für Fortgeschrittene: Konsolenbefehle

Über die Entwicklerkonsole des Spiels gibt es zusätzlich diese Befehle (Faktor 1.0 = 100 %):

| Befehl | Wirkung |
|---|---|
| `mscSet <kategorie> <parameter> <faktor>` | Setzt einen Wert für alle Fahrzeuge. Kategorien: `motor`, `gearbox`, `cabin` (Kabine & Lüfter), `rattle` (Anbauteile-Klappern), `work` / `discharge` (Arbeitswerk / Auswurf & Befüllen), `implementWork` / `implementDrive` / `implementRattle` (Arbeit / Antrieb / Fahr-Klappern von Anbaugeräten und Anhängern); außer Motor, Getriebe und Kabine nur `volume`. |
| `mscSetVehicle <kategorie> <parameter> <faktor>` | Setzt einen Wert für das Modell, in dem du sitzt. |
| `mscResetVehicle [<kategorie>]` | Löscht die eigenen Werte dieses Modells. |
| `mscInfo` | Schreibt die aktuellen Werte des Fahrzeugs in die `log.txt`. |
| `mscReload` | Lädt die Einstellungsdatei neu (`motorSoundConfigurator.xml` im Spielstand, als Mitspieler `modSettings/FS25_MotorSoundConfigurator/settings.xml`), z. B. nach Bearbeiten von Hand. |
| `mscLayer <name> [lautstärke\|remove]` | Schaltet einen Zusatz-Sound für das Modell ein (Lautstärke als Faktor; ersetzt den Sound derselben Gruppe) oder aus; ohne Namen zeigt der Befehl alle verfügbaren. |
| `mscDebug` | Schaltet das ausführliche Log ein / aus (erkannte Sounds je Fahrzeug, Zusatz-Sounds, alle Werte). |

Parameter: `volume`, `pitch`, `rpm`, `cutoffIndoor` (Kabine: Klangfarbe), `gainIndoor` (Kabine: Präsenz),
`cutoffOutdoor` (Außen: Klangfarbe), `gainOutdoor` (Außen: Präsenz), `indoorDamping` (Kabinendämpfung: 1.0 = Original =
Offenheit 0 %, 0.0 = Offenheit 100 %).

## Probleme melden

Alle Meldungen der Mod stehen in `Dokumente\My Games\FarmingSimulator2025\log.txt` und beginnen mit
`[MotorSoundConfigurator]`. Normalerweise sind das nur wenige Zeilen (Start, Laden, Speichern, Fehler). Bei einem
Problem mit einem Fahrzeug: einsteigen, in der Konsole `mscInfo` eingeben (schreibt die erkannten Sounds und ihre
Werte ins Log) und diese Zeilen mitschicken. `mscDebug` schaltet zusätzlich ausführliche Zeilen beim Laden von
Fahrzeugen und Zusatz-Sounds ein.
