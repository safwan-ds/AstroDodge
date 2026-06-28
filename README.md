# AstroDodge

A minimalist space survival game built with Godot Engine. Dodge asteroids, collect power-ups, and survive in endless space.

→ [GitHub Repository](https://github.com/safwan-ds/AstroDodge)

## Features

- Simple mouse + WASD controls
- Endless survival gameplay with increasing difficulty
- Entity system: Player, Asteroids, Bullets, Voltstars, Voltshots
- 5 collectible types (J-Unit, C-Unit, DDR6, M.2, ASM)
- Overcharge stations for temporary upgrades
- High score system with data persistence (save/load)
- Retro pixel graphics, HDR 2D rendering
- Camera shake, hit particles, screen transitions
- Dev console (debug builds)
- Horror framework (in development): VHS glitch effects, UI gaslighting, horror audio, lore system

## Engine

| Setting    | Value                                                                    |
| ---------- | ------------------------------------------------------------------------ |
| Engine     | Godot 4.7 (GL Compatibility)                                             |
| Viewport   | 640×360, viewport stretch mode                                           |
| Resolution | HDR 2D enabled                                                           |
| Physics    | 6 layers (player, enemies, weapons, anti_weapons, collectibles, statics) |

## Documentation

| File                                         | Contents                                                                 |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| [docs/architecture.md](docs/architecture.md) | Autoloads, scene tree, entity system, physics, state management          |
| [docs/classes.md](docs/classes.md)           | Class hierarchy with visibility, relationships, and inheritance diagrams |
| [docs/structures.md](docs/structures.md)     | File tree and node tree layouts                                          |

## Planned Features

- Gambling system, leveling & upgrading, new enemy types
- Richer space environment, radar, freeze frame
- Technical puzzles, horror lore framework
- Asteroid watching behavior, relic enemy type
- Complete horror system (audio, shaders, UI gaslighting, transitions)

## Controls

| Action      | Key                     |
| ----------- | ----------------------- |
| Move        | WASD / Arrow keys       |
| Shoot       | Left mouse              |
| Fullscreen  | F11                     |
| Dev Console | Backtick (debug builds) |

## Built With

- [Godot Engine](https://godotengine.org/)

## License

MIT License — see [LICENSE](LICENSE) for details.
