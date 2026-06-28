# Classes

## Entity

extends Area2D

```mermaid
classDiagram
    Entity <|-- Asteroid : inherits
    Entity <|-- Player : inherits
    Entity <|-- Bullet : inherits
    Entity <|-- Voltstar : inherits
    Entity <|-- Voltshot : inherits
    Entity --> EntityStats : uses
    Player --> Bullet : shoots
    Voltstar --> Voltshot : fires
    Entity "1" --> "*" collectible : spawns

    class Entity{
        +EntityStats entity_stats
        +PackedScene j_unit
        +PackedScene c_unit
        +PackedScene ddx6_chip
        +PackedScene mx3_chip
        +PackedScene asm_unit
        +AnimatedSprite2D sprite
        +GPUParticles2D trail
        +GPUParticles2D explosion
        +AudioStreamPlayer2D audio_player
        +float hp
        +float speed
        -Vector2 _direction
        -Dictionary _collectibles_map
        -float _hp
        -bool _is_dying
        -_on_area_entered(Area2D area)
        -_be_hurt(float damage)
        -_die()
        -_spawn_collectibles(CollectibleType collectible_type, int min_count, int max_count)
    }
    class Player{
        +is_hurt(hp float)
        +is_healed(hp float)
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
        -_input(InputEvent event)
        -_shoot()
    }
    class Asteroid{
        +GPUParticles2D shatter
        -bool _died
        -float _random_scale
        +_ready()
        +_on_area_entered(Area2D area)
        +_die()
        +_on_visible_on_screen_notifier_2d_screen_exited()
    }
    class Bullet{
        -_on_area_entered(Area2D area)
        -_on_visible_on_screen_notifier_2d_screen_exited()
    }
    class Voltstar{
        +Node2D guns
        +PackedScene voltshot_scene
        +float distance_to_player
        +float orbit_correction_speed
        -float _rotation_speed
        -int _movement_direction
        -float _speed
        -_process(float delta)
        -_on_area_entered(Area2D area)
        -_on_shooting_timer_timeout()
    }
    class Voltshot{
        +float rotation_speed
        -_ready()
        -_process(float delta)
        -_on_area_entered(Area2D area)
        -_on_lifetime_timeout()
    }
```

## EntityStats

extends Resource

```mermaid
classDiagram
    class EntityStats{
        +float max_health
        +float base_speed
        +int hit_shake_intensity
        +int death_shake_intensity
    }
```

## StaticObject

extends Area2D

```mermaid
classDiagram
    StaticObject <|-- OverchargeStation : inherits
    class StaticObject {
        +AnimatedSprite2D sprite
        +_ready()
        +_process(float delta)
    }
    class OverchargeStation {

    }
```
