# CSCI6562 Project — Hex Conquest

A real-time strategy conquest game built in [Godot 4.6](https://godotengine.org/). Cities sit on a hex-based graph map connected by roads; you send troops between them to defend, reinforce, and capture enemy territory while racing an AI opponent for control of the map.

## Gameplay

- **Cities** belong to one of three owners — you (faction 1), the AI (faction 2), or neutral (faction 0) — and passively generate **troops** and **gold** on every clock cycle.
- **Roads** connect cities. Drag from a city to send a portion of its army down a road to reinforce a friendly city or attack an enemy/neutral one.
- **Battles** play out along roads in real time; a city under attack pauses its troop production (but keeps generating gold) until the fight resolves.
- **Upgrades** — spend gold at a city to boost its production, gold income, or defense.
- **The Cycle Clock** is the game's heartbeat: everything (production, AI decisions, battles) advances on a shared tick, and its speed can be sped up, slowed down, or paused from the UI.
- **AI opponent** periodically evaluates its cities, queues upgrades, and launches attacks/reinforcements against the player.
- **Levels** — the game ships with a tutorial level plus two playable levels, selectable from a level-select menu.

## Project Structure

```
.
├── Audio/              # Music and SFX
├── Autoloads/           # Global singletons
│   ├── CycleClock.gd     # Shared game-speed tick that drives production/AI/battles
│   ├── FactionState.gd   # Per-faction gold tracking
│   ├── LevelSelection.gd # Remembers which level was chosen from the menu
│   └── AudioManager.gd   # Music/SFX playback
├── Core/                # Top-level game/AI orchestration
│   ├── GameController.gd # Loads levels, wires up the map, camera, and UI
│   ├── AIController.gd   # Enemy AI: upgrade and attack decisions each cycle
│   ├── Camera2D.gd        # Game camera controls
│   └── DragOverlay.gd     # Visual feedback while dragging a troop-send action
├── LevelData/            # Level definitions and the city/road graph
│   ├── GraphMap.gd         # Hex grid math, city/road graph, drag-to-send input
│   ├── LevelData.gd        # Level resource (cities, roads, cosmetics)
│   ├── GraphMap.gd, GenericLevel.tscn
│   └── Level1/, Level2/, LevelTutorial/
├── World/                # In-game entities
│   ├── City/               # City node, data, spawn data, and visuals
│   ├── Unit/                # Moving troop unit (walk/attack/death animations)
│   ├── Road/                # Road data and rendering layer
│   └── Battle/              # Battle resolution along a road
├── UI/                   # Menus, HUD, tutorial system, transitions
│   ├── MainMenu/, LevelSelect/, GameUI.gd/.tscn
│   ├── CityPopup/           # City stats/upgrade/production panel
│   ├── TutorialPopup/, TutorialVideos/, TextualTutorial/, TutorialManager.gd
│   └── Transition/, SceneFader.gd, Clock.gd
├── Sprites/              # 2D art (units, cities, tiles, icons, buttons, UI chrome)
├── addons/HexLevelEditor/ # Custom editor plugin: click hex tiles to place cities in LevelData
├── Game.tscn              # Root game scene
└── project.godot          # Godot project configuration
```

## Getting Started

### Prerequisites

- [Godot Engine 4.6](https://godotengine.org/download) (project uses the Forward+ renderer and Jolt Physics)

### Running the Project

1. Clone the repository:
   ```bash
   git clone <this-repo-url>
   ```
2. Open Godot 4.6, choose **Import**, and select `project.godot`.
3. Press **Run** (F5). The game boots into the main menu (`UI/MainMenu/MainMenu.tscn`), where you can pick a level from the level-select screen.

### Level Editor

The project includes a custom **HexLevelEditor** plugin (enabled by default) that lets you click hex tiles in the 2D viewport to place and remove cities directly in a level's `LevelData` resource — useful for building or tweaking `Level1`, `Level2`, or the tutorial level.

## How a Match Works

1. `GameController` loads the selected level and finds its `GraphMap`.
2. `GraphMap` builds the city/road graph from the level's `LevelData` and hooks up input (drag-to-send), the camera, and the UI.
3. Every tick of `CycleClock`, cities produce troops/gold, `AIController` makes decisions on a set cadence, and any active `Battle` nodes resolve combat.
4. The match ends when one faction controls the map, reported back through `GraphMap`'s `game_over` signal.

## Contributing

This is a course project for CSCI 6562. Collaborators are welcome to open pull requests or issues for bugs and feature ideas.

## License

_No license specified yet — add one (e.g. MIT) if you intend to share or open-source this project._
