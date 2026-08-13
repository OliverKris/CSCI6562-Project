# Sengoku Jidai: RTS Territorial-Conquest and City-Management Game

A real-time strategy conquest game built in [Godot 4.6](https://godotengine.org/). Cities sit on a hex-based graph map connected by roads; you send troops between them to defend, reinforce, and capture enemy territory while racing an AI opponent for control of the map.

## Gameplay

- **Cities** are either neutral or are owned by a enemy or ally faction and passively generate troops and gold on every clock cycle.
- **Roads** connect cities. The player can drag from a city to send a portion of its army down a road to reinforce a friendly city or attack an enemy one.
- **Battles** occur when an army is intercepted on route to a city or when it arrives at an enemy a city.
- **Upgrades** spend gold at a city to boost its production, gold income, or defense.
- **The Cycle Clock** coordinates city production, AI decisions, and battles, and can be sped up, slowed down, or paused from the UI.
- **AI Opponents** periodically evaluates its cities, queues upgrades, and launches attacks/reinforcements against the player.
- **Levels** currently include a tutorial level plus two playable levels, selectable from a level-select menu.

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

### Level Editor

The project includes a custom **HexLevelEditor** plugin (enabled by default) that lets you click hex tiles in the 2D viewport to place and remove cities directly in a level's `LevelData` resource, which let's a developer create new levels or edit current ones.
