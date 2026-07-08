# md_AdminJail

FiveM AdminJail Resource mit **Ingame-Panel** und **Commands** zur Verwaltung von Regelverstößen.

## Features

- Spieler per Command ins AdminJail setzen
- Automatische Freilassung nach Ablauf der Haftzeit
- Ingame-Panel zur Übersicht aller eingesperrten Spieler
- Freilassen direkt aus dem Panel
- Teleport zurück ins Jail bei Fluchtversuch
- Waffen deaktiviert während der Haft
- Haftzeit-Anzeige auf dem Bildschirm
- Reconnect-Persistenz über License-Identifier

## Installation

1. Ordner `md_AdminJail` in deinen `resources` Ordner legen
2. In der `server.cfg` hinzufügen:

```cfg
ensure md_AdminJail

# Admin-Rechte für AdminJail
add_ace group.admin adminjail.admin allow
add_principal identifier.license:DEINE_LICENSE group.admin
```

3. Server neu starten

## Commands

| Command | Beschreibung | Beispiel |
|---------|--------------|----------|
| `/adminjail` | Spieler einsperren | `/adminjail 5 30 RDM im Safezone` |
| `/adminjailrelease` | Spieler freilassen | `/adminjailrelease 5` |
| `/adminjailpanel` | Admin-Panel öffnen | `/adminjailpanel` |

## Konfiguration

Alle Einstellungen findest du in `config.lua`:

- Jail- und Release-Position
- Maximale Haftzeit
- Command-Namen
- Framework (`standalone`, `esx`, `qbcore`)
- Deutsche Texte / Benachrichtigungen

## Berechtigungen

Nur Spieler mit der ACE-Permission `adminjail.admin` können:

- `/adminjail` nutzen
- `/unjail` nutzen
- das AdminJail Panel öffnen

## Abhängigkeiten

Keine – funktioniert standalone. Optional kompatibel mit ESX oder QBCore für Spielernamen.
