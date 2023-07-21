from typing import Any
import random
from time import time
import pygame
from pygame.math import Vector2

from classes.player import Player, Bullet
from classes.asteroid import Asteroid
from classes.ui import Score
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
        self.last_asteroid = time()
        self.score = 0
        self.current_score = 0

        self.shake = 0

        self.font = pygame.Font(DEFAULT_FONT, 20)

        # UI
        self.ui = pygame.sprite.Group()
        self.score_text = Score(self.ui, (SCREEN_WIDTH / 2, 50))

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
        if self.app.mouse_buttons[1] and time() - self.last_shot >= SHOOTING_INTERVAL:
            self.shoot_sound.play()
            Bullet(self.player.sprite.rect.center, self.bullets)
            self.last_shot = time()

    def move_camera(self, dt):
        self.scroll = Vector2(
            -round(
                (self.player.sprite.rect.centerx - SCREEN_WIDTH / 2) / 15 * dt
                + (random.uniform(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
            -round(
                (self.player.sprite.rect.centery - SCREEN_HEIGHT / 2) / 15 * dt
                + (random.uniform(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
        )

    def collide(self):
        for asteroid in self.asteroids:
            if self.player.sprite.hit_box.colliderect(asteroid.rect):
                self.hit_sound.play()
                self.remove()

        if pygame.sprite.groupcollide(self.bullets, self.asteroids, True, True):
            self.asteroid_explosion_sound.play()
            self.score += 1
            self.shake = 15

    def update(self, dt):
        super().update()

        self.level += 0.001 * dt

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

        # Player
        self.bullets.update(self.scroll, dt)
        self.bullets.draw(self.screen)
        self.player.update(self.scroll, dt)
        self.player.draw(self.screen)

        # Asteroids
        if time() - self.last_asteroid >= 1:
            for _ in range(
                random.randint(0, int(self.level * ASTEROID_SPAWN_INTERVAL))
            ):
                Asteroid(self.asteroids)
                self.last_asteroid = time()
        self.asteroids.update(self.scroll, dt)
        self.asteroids.draw(self.screen)

        # UI
        if self.current_score != self.score:
            self.score_text.update(self.font, self.score)
            self.current_score = self.score
        self.ui.draw(self.screen)

        # Debugging
        # pygame.draw.rect(self.screen, "green", self.player.sprite.hit_box, 1)

        onscreen_debug(self.screen, f"Bullets: {len(self.bullets.sprites())}", y=50)
        onscreen_debug(
            self.screen,
            f"Cached rotations: {len(self.player.sprite.rotated_images)}",
            y=70,
        )
        onscreen_debug(self.screen, f"Asteroids: {len(self.asteroids.sprites())}", y=90)
        onscreen_debug(self.screen, f"Level: {self.level:.2f}", y=110)
