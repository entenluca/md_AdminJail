# md_AdminJail

Modernes, leistungsstarkes und flexibles AdminJail-System für ESX Roleplay-Server mit mehreren Strafenarten, Aufgaben, Admin-Menü und Discord-Integration.

## Features

### Drei Jail-Typen
- **Standard Jail** – Klassische Zeitstrafe mit Countdown
- **Community Service** – Aufgaben an definierten Punkten (fegen, Müll sammeln)
- **Facility Management** – Toiletten/Oberflächen reinigen mit integriertem Minigame

### Rechteverwaltung (ESX-Gruppen)
- Berechtigungen pro Gruppe in `config.lua` (`menu`, `jail`, `unjail`, `edit`)
- Commands: `/adminjail` und `/ajail` öffnen das Menü

### Admin-Menü
- Übersicht aller aktiven Jails
- Strafen erstellen, bearbeiten und aufheben
- Anzeige von Typ, Grund, Zeit/Aufgaben und Admin

### Spieler-HUD
- Oben mittig wie im Referenz-Design
- Zeigt Admin, Grund, Jail-Typ und verbleibende Strafe

### Aufgaben & Sicherheit
- Marker und [E]-Interaktion für Community/Facility-Jails
- Automatische Entlassung nach Zeit oder abgeschlossenen Aufgaben
- Waffen-/Angriffssperre während des Aufenthalts

### Discord
- Logs für Jail, Unjail, Edit und Autorelease
- Serverstatistik beim Resource-Start

## Installation

1. Resource in `resources/[local]/md_AdminJail` legen
2. In `server.cfg`:

```cfg
ensure es_extended
ensure md_AdminJail
```

3. `config.lua` anpassen (Gruppen, Koordinaten, Webhooks)

## Commands

| Command | Beschreibung |
|---------|--------------|
| `/adminjail` | Admin-Menü öffnen |
| `/ajail` | Alias für das Admin-Menü |

Alle Aktionen (Strafe setzen, bearbeiten, freilassen) erfolgen **nur über das Menü**.

## Discord Webhooks

In `config.lua`:

```lua
Config.Discord = {
    enabled = true,
    logsWebhook = 'DEIN_LOG_WEBHOOK',
    statsWebhook = 'DEIN_STATS_WEBHOOK'
}
```

## ESX Gruppen

```lua
Config.ESXGroups = {
    superadmin = { menu = true, jail = true, unjail = true, edit = true },
    admin = { menu = true, jail = true, unjail = true, edit = true },
    mod = { menu = true, jail = true, unjail = false, edit = false }
}
```

## Standalone Modus

Setze `Config.Framework = 'standalone'` und nutze ACE-Permissions aus `Config.StandaloneAce`.
