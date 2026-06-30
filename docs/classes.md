# Classes

## Entity

extends Area2D. Base class for moving entities. Provides hp, movement, death effects (explosion particles, camera shake), and collectible spawning.

```mermaid
classDiagram
    Entity <|-- Asteroid : inherits
    Entity <|-- Player : inherits
    Entity <|-- Voltstar : inherits
    Entity <|-- Voltshot : inherits
    Entity --> EntityStats : uses
    Player --> Bullet : shoots
    Voltstar --> Voltshot : fires
    Entity "1" --> "*" Collectible : spawns

    class Entity{
        +EntityStats entity_stats
        +PackedScene j_unit, cap_unit, ddrx_chip, m2_chip, asm_unit
        +AnimatedSprite2D sprite
        +GPUParticles2D trail
        +GPUParticles2D explosion
        +AudioStreamPlayer2D audio_player
        +float hp
        +float speed
        -Vector2 _direction
        -Vector2 _velocity
        -Dictionary _collectibles_map
        -float _hp
        -bool _is_dying
        +_on_area_entered(area: Area2D)
        +_move(delta: float)
        +_be_hurt(damage: float)
        +_die()
        +_spawn_collectibles(type: CollectibleType, min: int, max: int)
    }
```

### Player

extends Entity. Player-controlled ship. Moves toward the mouse, shoots bullets, enters invulnerability on hit, emits `is_hurt`/`is_healed`/`is_dead` signals.

```mermaid
classDiagram
    class Player{
        +is_hurt(hp: float)
        +is_healed(hp: float)
        +is_dead
        +PackedScene bullet_scene
        +Marker2D gun
        +AnimationPlayer animation_player
        +Camera2D camera
        +ProgressBar cooldown_bar
        +float rotation_speed
        +float mouse_tracehold
        +float max_speed
        +float acceleration
        +float friction
        +float invulnerability_time
        +float shoot_cooldown
        +float target_angle
        +float current_shoot_cooldown
        +bool auto_fire
        -float _target_angle
        -float _forward
        -Vector2 _distance_to_mouse
        -bool _invulnerable
        -float _current_shoot_cooldown
        -bool _auto_fire
        -Tween _auto_fire_tween
        +_move(delta: float)
        +_be_hurt(damage: float)
        +_die()
        +_input(event: InputEvent)
        +_shoot()
    }
```

### Asteroid

extends Entity. Drifts toward the player with randomized drift angle. Explodes into shatter particles on death. Size varies (scale 1.0–4.0) — particle velocity and amount scale proportionally.

```mermaid
classDiagram
    class Asteroid{
        +GPUParticles2D shatter
        -bool _died
        -float _random_scale
        +_ready()
        +_on_area_entered(area: Area2D)
        +_die()
        +_on_screen_exited()
    }
```

### Voltstar

extends Entity. Orbiting enemy that maintains a fixed distance from the player. Fires Voltshot projectiles on a 5s timer. Drops J-unit collectibles on destruction by player bullets. Uses perpendicular repulsion to prevent overlap with other Voltstars.

```mermaid
classDiagram
    class Voltstar{
        +Node2D guns
        +PackedScene voltshot_scene
        +float distance_to_player
        +float orbit_correction_speed
        +float repel_threshold
        +float repel_strength
        -float _rotation_speed
        -int _movement_direction
        -float _speed
        +_move(delta: float)
        +_on_area_entered(area: Area2D)
        +_on_shooting_timer_timeout()
    }
```

### Voltshot

extends Entity. One-shot homing projectile fired by Voltstars. Rotates toward the player and self-destructs on contact or after a 5s lifetime timeout.

```mermaid
classDiagram
    class Voltshot{
        +float rotation_speed
        +_ready()
        +_move(delta: float)
        +_on_area_entered(area: Area2D)
        +_on_lifetime_timeout()
    }
```

---

## Direct Area2D classes (no Entity inheritance)

### Bullet

extends Area2D. Lightweight projectile fired by the Player. Flies forward and cleans up on enemy contact or when off-screen.

```mermaid
classDiagram
    class Bullet{
        +float speed
        +GPUParticles2D trail
        +_process(delta: float)
        +_on_area_entered(area: Area2D)
        +_on_screen_exited()
    }
```

### Collectible

extends Area2D. Accelerates toward the player on spawn. On pickup, increments the counter for its type and persists it via `DataSave`.

```mermaid
classDiagram
    class Collectible{
        +CollectibleType collectible_type
        +float initial_speed
        +float acceleration
        -Vector2 _direction
        -Vector2 _velocity
        +_ready()
        +_process(delta: float)
        +_on_area_entered(area: Area2D)
    }
```

---

## Other classes

### EntityStats

extends Resource. Defines an entity's stats: health, speed, camera shake intensities.

```mermaid
classDiagram
    class EntityStats{
        +float max_health
        +float base_speed
        +int hit_shake_intensity
        +int death_shake_intensity
    }
```

### EntitySpawner

extends Timer. Timer-based spawner that places entities just outside the camera viewport. Respects a per-spawner max count and spreads batches across frames to avoid spikes.

```mermaid
classDiagram
    class EntitySpawner{
        +bool outside_viewport
        +float padding
        +PackedScene entity
        +String entity_group
        +int spawn_count_min
        +int spawn_count_max
        +int max_count
        +bool spread_batch_sides
        -Camera2D camera
        -Vector2 viewport_size
        -int spawn_count
        -int _spread_side
        +_ready()
        +_on_timeout()
        +_spawn_tick()
        +_spawn_entity()
        +_position_entity(instance, side)
    }
```

### StaticObject

extends Area2D. Base class for non-moving interactive objects. Currently a bare skeleton with no behaviour (empty `_ready()` and `_process()` overrides).

```mermaid
classDiagram
    class StaticObject{
        +AnimatedSprite2D sprite
    }

    class OverchargeStation{
        # placeholder — no behaviour implemented
    }
    StaticObject <|-- OverchargeStation : inherits
```

### DataSave

extends Resource. Serializable resource for persistent collectible counters. Saved/loaded via `ResourceSaver`/`ResourceLoader`.

```mermaid
classDiagram
    class DataSave{
        +Array[int] collectibles_counter
        +save() int
    }
```

### AnimationComponent

extends Node. Button animation helper: hover/press scaling, font swap, click SFX, idle rotation wobble. Attach as child of a Button.

```mermaid
classDiagram
    class AnimationComponent{
        +Vector2 hovered_scale
        +Vector2 pressed_scale
        +float duration
        +Font hover_font
        +float min_rotation_speed
        +float max_rotation_speed
        +float max_rotation_angle
        -Tween tween
        -RandomNumberGenerator rng
        -Button button
        +_ready()
        +_init_pivot()
        +_entered()
        +_exited()
        +_pressed()
        +start_random_rotation()
    }
```
