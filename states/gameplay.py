import random
from time import time
import pygame
from pygame.math import Vector2
from pygame.locals import *

from classes.player import Player, Bullet
from classes.asteroid import Asteroid, Explosion
from classes.particles import Emitter
from classes.ui import Score, Arrow, Bar
from classes.state import State
from states.pause import PauseMenu
from utils import resource_path, save_data, load_data

from globals import (
    SCREEN_WIDTH,
    SCREEN_HEIGHT,
    SFX_DIR,
    MUSIC_DIR,
    DEFAULT_FONT,
    PLAYER_VELOCITY,
    SHOOTING_INTERVAL,
    SHOOTING_BAR_WIDTH,
    SHOOTING_BAR_HEIGHT,
    MAX_LEVEL,
    LEVEL_INCREASE_SPEED,
    ASTEROID_SPAWN_INTERVAL,
    ASTEROID_MAX_SCALE,
    SCORE,
    SHAKE,
    GLITCH_AMOUNT,
    PARTICLE_AMOUNT,
    LEVEL,
)


class Gameplay(State):
    def __init__(self, app):
        super().__init__(app)
        self.screen: pygame.Surface = self.app.screen

        self.start_time = time()
        self.level = LEVEL

        self.player = Player((SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
        self.player_sprite = pygame.sprite.GroupSingle(self.player)
        self.bullets = pygame.sprite.Group()
        self.trails = pygame.sprite.Group()
        self.shooting_interval = SHOOTING_INTERVAL
        self.last_shot = 0
        self.auto_fire = False
        self.asteroids = pygame.sprite.Group()
        self.gained_points = GainedPoints()
        self.explosions = pygame.sprite.Group()
        self.last_asteroid = time()
        self.score = 0

        self.particles = Emitter()

        self.shake = 0

        self.font = pygame.Font(resource_path(DEFAULT_FONT), 30)
        self.s_font = pygame.Font(resource_path(DEFAULT_FONT), 20)

        # Gameplay states
        self.paused = False
        self.pause_menu = PauseMenu(app, self)
        # Create a transparent surface for the rectangle
        self.dark_overlay = pygame.Surface(
            (SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA
        )
        transparent_color = (
            0,
            0,
            0,
            180,
        )  # Change alpha value as needed (0: fully transparent, 255: fully opaque)
        pygame.draw.rect(
            self.dark_overlay,
            transparent_color,
            (0, 0, SCREEN_WIDTH, SCREEN_HEIGHT),
        )

        self.game_over = False
        self.game_over_text1 = self.font.render(
            "Game Over! Click the mouse to try again", False, "white"
        )
        self.game_over_text2 = self.font.render(
            "or press ESC to exit to title screen", False, "white"
        )
        # Calculate positions for each line of text
        self.line1_x = SCREEN_WIDTH / 2 - self.game_over_text1.get_width() / 2
        self.line1_y = SCREEN_HEIGHT / 2 - self.game_over_text1.get_height()
        self.line2_x = SCREEN_WIDTH / 2 - self.game_over_text2.get_width() / 2
        self.line2_y = SCREEN_HEIGHT / 2

        # UI
        self.ui = pygame.sprite.Group()
        self.level_bar = Bar(self.ui, (SCREEN_WIDTH / 2, 15), 100, 10)
        self.score_text = Score(self.ui, (SCREEN_WIDTH / 2, 65))
        self.arrow = Arrow(self.ui, (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
        self.shooting_bar = Bar(
            self.ui,
            (SCREEN_WIDTH / 2, SCREEN_HEIGHT - 40),
            SHOOTING_BAR_WIDTH,
            SHOOTING_BAR_HEIGHT,
        )
        self.auto_text = self.font.render("Auto", False, "yellow")

        # Sounds
        self.music = pygame.mixer.Sound(resource_path(MUSIC_DIR + "gameplay.wav"))
        self.music_volume = 0
        self.music.set_volume(self.music_volume)

        self.shoot_sound = pygame.mixer.Sound(resource_path(SFX_DIR + "shoot"))
        self.player_explosion = pygame.mixer.Sound(
            resource_path(SFX_DIR + "heavy_explosion")
        )
        self.asteroid_kill = pygame.mixer.Sound(resource_path(SFX_DIR + "kill"))
        self.asteroid_collision = pygame.mixer.Sound(
            resource_path(SFX_DIR + "explosion")
        )
        self.exit_sound = pygame.mixer.Sound(SFX_DIR + "exit")

    def add(self):
        super().add()

        self.music.play(-1)

    def remove(self):
        super().remove()

        self.music.fadeout(1000)

    def get_input(self):
        if self.app.mousebuttondown == 3:
            self.auto_fire = not self.auto_fire

        if (
            time() - self.last_shot >= self.shooting_interval
            and not self.game_over
            and not self.paused
        ):
            if self.auto_fire or self.app.mousebuttondown == 1:
                self.shoot_sound.play()

                num_bullets = int(self.level // MAX_LEVEL + 1)
                angle_spacing = 5 * (num_bullets - 1)
                if num_bullets > 1:
                    angles = range(
                        -angle_spacing,
                        angle_spacing + 1,
                        angle_spacing // (num_bullets - 1) * 2,
                    )
                else:
                    angles = [0]

                for angle in angles:
                    Bullet(
                        self.bullets,
                        self.player.rect.center,
                        self.player.target_angle + angle,
                        self.player.velocity,
                    )

                self.last_shot = time()
                self.shake = SHAKE / 3

        if self.game_over:
            if self.app.keydown == K_ESCAPE:
                self.exit_sound.play()
                self.save_data()
                self.remove()

            elif self.app.mousebuttondown == 1:
                self.reset()

        if self.paused:
            if self.app.keydown == K_ESCAPE:
                self.unpause()
        elif not self.game_over and self.app.keydown == K_ESCAPE:
            self.paused = True
            self.music.set_volume(self.pause_music_volume)

    def unpause(self):
        self.paused = False
        self.music.set_volume(self.music_volume)

    def move_camera(self, dt, x, y):
        self.scroll = Vector2(
            -round(
                (x - SCREEN_WIDTH / 2)
                + (random.uniform(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
            -round(
                (y - SCREEN_HEIGHT / 2)
                + (random.uniform(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
        )

    def reset(self):
        self.save_data()
        self.music_volume = 0
        self.music.set_volume(self.music_volume)
        self.music.play(-1)
        self.player = Player((SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
        self.player_sprite = pygame.sprite.GroupSingle(self.player)
        self.arrow = Arrow(self.ui, (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
        self.level = LEVEL
        self.score = 0
        self.asteroids.empty()
        self.auto_fire = False
        self.game_over = False

    def collide(self):
        for asteroid in self.asteroids:
            if not self.game_over:
                if self.player.hit_box.colliderect(asteroid.rect):
                    self.save_data()
                    self.app.time_speed = 20
                    self.player_explosion.play()
                    self.music.fadeout(500)
                    Explosion(self.explosions, self.player.hit_box.center, 10, "red")
                    self.player.kill()
                    self.bullets.empty()
                    self.arrow.kill()
                    self.shake = SHAKE * 1.5
                    self.game_over = True
                    break

            # Check for collisions with bullets
            if pygame.sprite.spritecollide(asteroid, self.bullets, True):
                self.asteroid_kill.play()
                self.last_kill = time()
                added_points = (
                    SCORE * self.level * (ASTEROID_MAX_SCALE - asteroid.scale + 1)
                )
                self.score += added_points
                self.gained_points.add_point(
                    Vector2(
                        (
                            random.uniform(asteroid.rect.left, asteroid.rect.right),
                            random.uniform(asteroid.rect.top, asteroid.rect.bottom),
                        )
                    ),
                    self.font,
                    int(added_points),
                )
                asteroid.kill()
                Explosion(
                    self.explosions, asteroid.rect.center, asteroid.scale * 2, "white"
                )
                self.shake = SHAKE
                self.app.time_speed = asteroid.scale * 15
                break

            # Check for collisions between asteroids
            for asteroid2 in self.asteroids.copy():
                if (
                    asteroid != asteroid2
                    and pygame.sprite.collide_mask(asteroid, asteroid2)
                    and (
                        (
                            0 <= asteroid.rect.centerx <= SCREEN_WIDTH
                            and 0 <= asteroid.rect.centery <= SCREEN_HEIGHT
                        )
                        or (
                            0 <= asteroid2.rect.centerx <= SCREEN_WIDTH
                            and 0 <= asteroid2.rect.centery <= SCREEN_HEIGHT
                        )
                    )
                ):
                    self.asteroid_collision.play()
                    asteroid.kill()
                    asteroid2.kill()
                    Explosion(self.explosions, asteroid.rect.center, asteroid.scale)
                    Explosion(self.explosions, asteroid2.rect.center, asteroid2.scale)
                    self.shake = SHAKE / 2
                    break

    def save_data(self):
        data = {
            "highest_score": (
                int(self.score)
                if self.score > self.app.highest_score
                else self.app.highest_score
            ),
            "fullscreen": self.app.fullscreen,
        }
        save_data(data)
        self.app.highest_score = load_data()["highest_score"]  # type: ignore
        # Explosion(self.explosions, self.score_text.rect.center, 5, "yellow")

    def update(self, dt):
        super().update(dt)

        self.get_input()

        if not self.paused:
            if not self.game_over:
                self.level += LEVEL_INCREASE_SPEED * dt
                self.score += self.level * dt

                # Music
                if self.music_volume < 0.5:
                    self.music_volume += 0.01 * dt
                    self.pause_music_volume = self.music_volume / 2
                    self.music.set_volume(self.music_volume)

            # Camera
            if self.game_over:
                self.player_x += self.scroll.x
                self.player_y += self.scroll.y
            else:
                self.player_x = self.player.rect.centerx
                self.player_y = self.player.rect.centery
            self.move_camera(dt, self.player_x, self.player_y)

        if self.shake > 0:
            self.shake -= 1 * dt
        else:
            self.shake = 0

        # Collisions
        self.collide()
        self.app.glitch = self.shake / SHAKE + GLITCH_AMOUNT

        # Background
        self.particles.update(self.scroll, dt, PARTICLE_AMOUNT, 0.1)

        # Player
        try:
            if not (self.paused or self.game_over):
                ratio = self.player.velocity / PLAYER_VELOCITY
                self.shooting_interval = SHOOTING_INTERVAL * (1 + (ratio - 1) / 2)
                trail_color = (
                    (59, 101, 143)
                    if self.level <= MAX_LEVEL
                    else (min(59 * ratio, 255), 101, 143)
                )
                self.player.update(
                    self.scroll,
                    dt,
                    self.trails,
                    trail_color,
                )
                self.bullets.update(self.scroll, dt, self.trails, trail_color)

        except AttributeError as e:
            # Handle the AttributeError
            print("AttributeError occurred:", e)
        except TypeError as e:
            # Handle the TypeError
            print("TypeError occurred:", e)

        # Asteroids
        if not self.paused:
            self.explosions.update(self.scroll, dt)
            if time() - self.last_asteroid >= 1:
                if self.level <= MAX_LEVEL:
                    for _ in range(
                        random.randint(0, int(ASTEROID_SPAWN_INTERVAL * self.level))
                    ):
                        try:
                            Asteroid(self.asteroids, self.player.angle)
                        except AttributeError:
                            Asteroid(self.asteroids)
                        self.last_asteroid = time()
                else:
                    for _ in range(
                        random.randint(0, int(ASTEROID_SPAWN_INTERVAL * self.level / 2))
                    ):
                        Asteroid(self.asteroids)
                        self.last_asteroid = time()
                    try:
                        self.player.velocity = PLAYER_VELOCITY * self.level / MAX_LEVEL
                    except AttributeError:
                        pass

            self.asteroids.update(self.scroll, dt, self.trails, "red")
        self.gained_points.update(self.scroll, dt)

        # Trails
        try:
            self.trails.update(self.scroll, dt, 20)
        except AttributeError:
            pass

        # Drawing
        self.app.screen.fill("black")
        self.particles.draw(self.screen)
        try:
            self.trails.draw(self.screen)
            self.bullets.draw(self.screen)
            self.player_sprite.draw(self.screen)
        except TypeError as e:
            print("TypeError occurred:", e)
        self.asteroids.draw(self.screen)
        self.explosions.draw(self.screen)
        self.gained_points.draw(self.screen)

        # UI
        self.level_bar.update(
            round(self.level % 1, 2), "white" if self.level <= MAX_LEVEL else "red"
        )
        level = self.font.render(
            f"Level: {int(self.level)}",
            False,
            "white" if self.level <= MAX_LEVEL else "red",
        )
        self.screen.blit(level, level.get_frect(center=(SCREEN_WIDTH / 2, 40)))
        self.score_text.update(
            self.font,
            int(self.score),
            "white" if self.score <= self.app.highest_score else "yellow",
        )
        highest_score = self.s_font.render(
            f"Highest Score: {self.app.highest_score}", False, "white"
        )
        self.screen.blit(
            highest_score, highest_score.get_frect(center=(SCREEN_WIDTH / 2, 85))
        )
        try:
            self.arrow.update(self.player.target_angle)
        except AttributeError:
            pass
        self.shooting_bar.update(
            (time() - self.last_shot) / self.shooting_interval,
            color="yellow" if self.auto_fire else "white",
        )
        if self.auto_fire and not self.game_over:
            self.screen.blit(
                self.auto_text,
                self.auto_text.get_frect(center=(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 70)),
            )
        self.ui.draw(self.screen)

        # Game states
        if self.paused:
            self.scroll = Vector2(0, 0)

            # Blit the transparent surface onto the screen
            self.screen.blit(self.dark_overlay, (0, 0))
            self.pause_menu.update()

        if self.game_over:
            self.screen.blit(self.game_over_text1, (self.line1_x, self.line1_y))
            self.screen.blit(self.game_over_text2, (self.line2_x, self.line2_y))

        # Transition
        self.screen.blit(self.transition, (0, 0))

        # Debugging
        # pygame.draw.rect(self.screen, "green", self.player.hit_box, 1)

        # onscreen_debug(self.screen, f"Bullets: {len(self.bullets.sprites())}", y=50)
        # onscreen_debug(
        #     self.screen,
        #     f"Cached rotations: {len(self.player.rotated_images)}",
        #     y=70,
        # )
        # onscreen_debug(self.screen, f"Asteroids: {len(self.asteroids.sprites())}", y=90)
        # onscreen_debug(self.screen, f"Level: {self.level:.2f}", y=110)


class GainedPoints(pygame.sprite.Group):
    def __init__(self):
        super().__init__()

    def add_point(self, pos, font: pygame.Font, points):
        sprite = pygame.sprite.Sprite(self)
        sprite.image = font.render(f"+{points}", False, "green")
        sprite.rect = sprite.image.get_frect(center=pos)
        sprite.alpha = 255

    def update(self, scroll, dt):
        for sprite in self.sprites():
            if sprite.alpha <= 0:
                sprite.kill()
                continue
            sprite.rect.move_ip(scroll)
            sprite.alpha -= 5 * dt
            sprite.image.set_alpha(sprite.alpha)
