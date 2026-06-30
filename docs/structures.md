# Tree Structures

## Main File Tree

```mermaid
%%{ init: { 'flowchart': { 'curve': 'bumpX' } } }%%
flowchart LR
    r([root]) --> addons --> AsepriteWizard
    r --> audio
    audio --> music
    audio --> sfx

    r --> components
    r --> docs

    r --> e[entities]
    e --> asteroid
    e --> bullet
    e --> collectibles --> j_unit
    e --> player
    e --> static --> overcharge_station
    e --> voltstar --> voltshot
    e --> entity_spawner
    e --> entity_stats

    r --> fonts
    r --> globals

    r --> states
    states --> gameplay --> gui
    states --> loading
    states --> main_menu
    states --> overlays

    r --> themes
    themes --> primary

    r --> transitions

    r --> visuals
    visuals --> cursors
    visuals --> shaders
```

## Main Node Tree

```mermaid
%%{ init: { 'flowchart': { 'curve': 'bumpX' } } }%%
flowchart LR
    r([root]) --> M(Main)
    M --> BG & World & FX & GUI & Popups & Transitions & Overlays
    r --> G(Global)
    r --> A(AudioManager) --> SFX
    A --> Music
    r --> D(DevConsole)
    r --> P(Preloader)
```

## Scene Tree Details

| Node        | Type        | Purpose                                                   |
| ----------- | ----------- | --------------------------------------------------------- |
| Main        | Node        | Root scene controller, state transitions                  |
| BG          | CanvasLayer | Black background ColorRect                                |
| World       | CanvasLayer | Holds World2D (Node2D) — entity spawn area                |
| FX          | CanvasLayer | SpaceWarp distortion overlay (ColorRect + ShaderMaterial) |
| GUI         | CanvasLayer | MainMenu or GameplayGUI                                   |
| Popups      | CanvasLayer | Modal popups (QuitPopup)                                  |
| Transitions | CanvasLayer | Dissolve transition effect                                |
| Overlays    | CanvasLayer | VHS CRT shader overlay (ColorRect + ShaderMaterial)       |

The World and GUI subtrees are swapped on each `change_state` emission. Autoloads (Global, AudioManager, DevConsole, Preloader) persist across all transitions.
