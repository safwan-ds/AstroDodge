from typing import Any
import random
import pygame
from pygame.math import Vector2

from classes.player import Player, Bullet
from classes.state import State
from debug import onscreen_debug

from pygame.locals import *
from config import *


class Gameplay(State):
    def __init__(self, app):
        super().__init__(app)
        self.screen = self.app.screen

        self.player = pygame.sprite.GroupSingle(
            Player((SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
        )
        self.bullets = pygame.sprite.Group()

        self.shake = 0

        self.font = pygame.Font(DEFAULT_FONT, 20)

        # UI
        ...

        # Sounds
        pygame.mixer.music.load(MUSIC_DIR + "gameplay.wav")
        self.music_volume = 0
        pygame.mixer.music.set_volume(self.music_volume)
        self.shoot_sound = pygame.mixer.Sound(SFX_DIR + "shoot")

    def add(self):
        super().add()

        pygame.mixer.music.play(-1)

    def remove(self):
        super().remove()

        pygame.mixer.music.fadeout(500)

    def get_input(self):
        if self.app.keys["esc"]:
            self.remove()
        if self.app.mouse_buttons[1]:
            self.shoot_sound.play()
            self.shake = 15
            Bullet(self.player.sprite.rect.center, self.bullets)

    def move_camera(self):
        self.scroll = Vector2(
            -round(
                (self.player.sprite.rect.centerx - SCREEN_WIDTH / 2)
                + (random.randint(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
            -round(
                (self.player.sprite.rect.centery - SCREEN_HEIGHT / 2)
                + (random.randint(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
        )

    def update(self, dt):
        super().update()

        # Music
        if pygame.mixer.music.get_volume() < 0.1:
            self.music_volume += 0.001 * self.app.dt
            pygame.mixer.music.set_volume(self.music_volume)

        # Camera
        self.move_camera()
        if self.shake > 0:
            self.shake -= round(2 * dt)
        else:
            self.shake = 0

        # Background
        self.app.screen.fill("black")

        # Player
        self.player.update(self.scroll, dt)
        self.player.draw(self.screen)
        self.bullets.update(self.scroll, dt)
        self.bullets.draw(self.screen)

        # UI
        ...

        # Debugging
        onscreen_debug(self.screen, f"Bullets: {len(self.bullets.sprites())}", y=50)
