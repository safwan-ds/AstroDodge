import math
from typing import Any
import pygame
from pygame.math import Vector2

from pygame.locals import *
from config import *


class Player(pygame.sprite.Sprite):
    def __init__(self, pos):
        super().__init__()

        self.image = pygame.image.load(IMGS_DIR + "player.png")
        self.original_image = self.image.copy()
        self.rect = self.image.get_frect(center=pos)
        self.hit_box = self.rect.inflate(-15, -15)

        self.speed = Vector2(0, 0)
        self.rotated_images = {}

    def get_input(self):
        keys = pygame.key.get_pressed()

        if keys[K_d]:
            self.speed.x = PLAYER_SPEED
        elif keys[K_a]:
            self.speed.x = -PLAYER_SPEED
        else:
            self.speed.x = 0

        if keys[K_s]:
            self.speed.y = PLAYER_SPEED
        elif keys[K_w]:
            self.speed.y = -PLAYER_SPEED
        else:
            self.speed.y = 0

    def move(self, scroll, dt):
        self.hit_box.move_ip(self.speed * dt + scroll)

    def rotate(self):
        screen_size = pygame.display.get_window_size()
        mouse_pos = pygame.mouse.get_pos()
        mouse_pos = Vector2(
            mouse_pos[0] / (screen_size[0] / SCREEN_WIDTH),
            mouse_pos[1] / (screen_size[1] / SCREEN_HEIGHT),
        )

        direction = Vector2(
            mouse_pos.x - self.rect.centerx, mouse_pos.y - self.rect.centery
        )
        angle = int(math.degrees(math.atan2(direction.y, direction.x)))

        # Rotate the spaceship image
        try:
            if self.image != self.rotated_images[angle]:
                self.image = self.rotated_images[angle]
        except KeyError:
            self.rotated_images[angle] = pygame.transform.rotate(
                self.original_image, -angle - 90
            )
            self.image = self.rotated_images[angle]

        self.rect = self.image.get_frect(center=self.rect.center)

    def update(self, scroll, dt):
        self.get_input()
        self.move(scroll, dt)
        self.rotate()
        self.rect.center = self.hit_box.center


class Bullet(pygame.sprite.Sprite):
    def __init__(self, pos, group):
        super().__init__(group)

        self.image = pygame.image.load(IMGS_DIR + "misc/bullet.png")
        self.rect = self.image.get_frect(center=pos)

        screen_size = pygame.display.get_window_size()
        mouse_pos = pygame.mouse.get_pos()
        mouse_pos = Vector2(
            mouse_pos[0] / (screen_size[0] / SCREEN_WIDTH),
            mouse_pos[1] / (screen_size[1] / SCREEN_HEIGHT),
        )
        direction = Vector2(
            mouse_pos.x - self.rect.centerx, mouse_pos.y - self.rect.centery
        )
        angle = math.atan2(direction.y, direction.x)
        self.image = pygame.transform.rotate(self.image, -math.degrees(angle) - 90)
        self.speed = Vector2(
            math.cos(angle) * BULLET_SPEED, math.sin(angle) * BULLET_SPEED
        )

    def update(self, scroll, dt):
        if (
            self.rect.centerx > SCREEN_WIDTH
            or self.rect.centerx < 0
            or self.rect.centery > SCREEN_HEIGHT
            or self.rect.centery < 0
        ):
            self.kill()
        self.rect.move_ip(self.speed * dt + scroll)
