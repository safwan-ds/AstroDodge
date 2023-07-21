from typing import Any
import random
from time import time
import pygame
from pygame.math import Vector2

from classes.player import Player, Bullet
from classes.asteroid import Asteroid, Explosion
from classes.particles import Emitter
from classes.ui import Score, Arrow
from classes.state import State
from debug import onscreen_debug

from pygame.locals import *
from config import *


class Gameplay(State):
    def __init__(self, app):
        super().__init__(app)
        self.screen = self.app.screen

        self.start_time = time()
        self.level = 1

        self.player = pygame.sprite.GroupSingle(
            Player((SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
        )
        self.bullets = pygame.sprite.Group()
        self.last_shot = 0
        self.asteroids = pygame.sprite.Group()
        self.explosions = pygame.sprite.Group()
        self.last_asteroid = time()
        self.score = 0

        self.particles = Emitter(SCREEN_HEIGHT)

        self.shake = 0

        self.font = pygame.Font(DEFAULT_FONT, 30)
        self.game_over = False

        # UI
        self.ui = pygame.sprite.Group()
        self.score_text = Score(self.ui, (SCREEN_WIDTH / 2, 50))
        self.arrow = Arrow(self.ui, (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))

        # Sounds
        pygame.mixer.music.load(MUSIC_DIR + "gameplay.wav")
        self.music_volume = 0
        pygame.mixer.music.set_volume(self.music_volume)
        self.shoot_sound = pygame.mixer.Sound(SFX_DIR + "shoot")
        self.shoot_sound.set_volume(0.1)
        self.hit_sound = pygame.mixer.Sound(SFX_DIR + "hit")
        self.asteroid_explosion_sound = pygame.mixer.Sound(SFX_DIR + "kill")

    def add(self):
        super().add()

        # pygame.mixer.music.play(-1)

    def remove(self):
        super().remove()

        pygame.mixer.music.fadeout(500)

    def get_input(self):
        if self.app.keys["esc"]:
            self.remove()

    def move_camera(self, dt):
        self.scroll = Vector2(
            -round(
                (self.player.sprite.rect.centerx - SCREEN_WIDTH / 2) / 5 * dt
                + (random.uniform(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
            -round(
                (self.player.sprite.rect.centery - SCREEN_HEIGHT / 2) / 5 * dt
                + (random.uniform(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
        )

    def collide(self):
        for asteroid in self.asteroids:
            if not self.game_over:
                if self.player.sprite.hit_box.colliderect(asteroid.rect):
                    self.hit_sound.play()
                    Explosion(self.explosions, self.player.sprite.hit_box.center, 10)
                    self.player.sprite.kill()
                    self.arrow.kill()
                    self.scroll = (0, 0)
                    self.game_over = True
                    break

            if pygame.sprite.spritecollide(asteroid, self.bullets, True):
                self.asteroid_explosion_sound.play()
                asteroid.kill()
                Explosion(self.explosions, asteroid.rect.center, asteroid.scale)
                self.shake = SHAKE
                if asteroid.rect.height == ASTEROID_MAX_SCALE:
                    self.score += 100 * self.level
                elif asteroid.rect.height == ASTEROID_MIN_SCALE:
                    self.score += 200 * self.level
                else:
                    self.score += 150 * self.level
                break

            # Check for collisions between asteroids
            for asteroid2 in self.asteroids.copy():
                if (
                    asteroid != asteroid2
                    and pygame.sprite.collide_rect(asteroid, asteroid2)
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
                    self.asteroid_explosion_sound.play()
                    asteroid.kill()
                    asteroid2.kill()
                    Explosion(self.explosions, asteroid.rect.center, asteroid.scale)
                    Explosion(self.explosions, asteroid2.rect.center, asteroid2.scale)
                    self.shake = SHAKE
                    break  # Exit the inner loop since each asteroid can only collide with one other asteroid

    def update(self, dt):
        super().update()

        if not self.game_over:
            self.level += 0.001 * dt
            self.score += self.level * dt

            # Music
            if pygame.mixer.music.get_volume() < 0.1:
                self.music_volume += 0.001 * self.app.dt
                pygame.mixer.music.set_volume(self.music_volume)

            # Camera
            self.move_camera(dt)
            if self.shake > 0:
                self.shake -= 2 * dt
            else:
                self.shake = 0

        # Collisions
        self.collide()

        # Background
        self.app.screen.fill("black")
        self.particles.update(self.scroll, dt, 2, 0.1)
        self.particles.draw(self.screen)

        if not self.game_over:
            # Player
            self.player.update(self.scroll, dt)
            self.player.draw(self.screen)
            if time() - self.last_shot >= SHOOTING_INTERVAL:
                self.shoot_sound.play()
                Bullet(
                    self.bullets,
                    self.player.sprite.rect.center,
                    self.player.sprite.angle,
                )
                self.last_shot = time()
            self.bullets.update(self.scroll, dt)
            self.bullets.draw(self.screen)

        # Asteroids
        self.explosions.update(self.scroll, dt)
        self.explosions.draw(self.screen)
        if time() - self.last_asteroid >= 1:
            for _ in range(
                random.randint(0, int(self.level * ASTEROID_SPAWN_INTERVAL))
            ):
                Asteroid(self.asteroids)
                self.last_asteroid = time()
        self.asteroids.update(self.scroll, dt)
        self.asteroids.draw(self.screen)

        # UI
        self.score_text.update(self.font, int(self.score))
        if not self.game_over:
            self.arrow.update(self.player.sprite.target_angle)
        self.ui.draw(self.screen)

        # Game Over
        if self.game_over:
            ...

        # Debugging
        # pygame.draw.rect(self.screen, "green", self.player.sprite.hit_box, 1)

        onscreen_debug(self.screen, f"Bullets: {len(self.bullets.sprites())}", y=50)
        # onscreen_debug(
        #     self.screen,
        #     f"Cached rotations: {len(self.player.sprite.rotated_images)}",
        #     y=70,
        # )
        onscreen_debug(self.screen, f"Asteroids: {len(self.asteroids.sprites())}", y=90)
        onscreen_debug(self.screen, f"Level: {self.level:.2f}", y=110)
