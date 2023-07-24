import math
from typing import Any
import pygame
from pygame.math import Vector2

from pygame.locals import *
from config import *


class Player(pygame.sprite.Sprite):
    def __init__(self, group, pos):
        super().__init__(group)

        self.original_image = pygame.image.load(IMGS_DIR + "player.png")
        self.rect = self.original_image.get_frect(center=pos)
        self.hit_box = self.rect.inflate(-20, -20)

        self.velocity = PLAYER_VELOCITY
        self.speed = Vector2(PLAYER_VELOCITY, 0)
        self.cache = {}

        self.angle = 0
        self.target_angle = 0

    def get_input(self):
        keys = pygame.key.get_pressed()

        if keys[K_d]:
            self.speed.x = PLAYER_VELOCITY
        elif keys[K_a]:
            self.speed.x = -PLAYER_VELOCITY
        else:
            self.speed.x = 0

        if keys[K_s]:
            self.speed.y = PLAYER_VELOCITY
        elif keys[K_w]:
            self.speed.y = -PLAYER_VELOCITY
        else:
            self.speed.y = 0

    def move(self, scroll, dt):
        self.hit_box.move_ip(self.speed * dt + scroll)

    def rotate(self, dt):
        screen_size = pygame.display.get_window_size()
        mouse_pos = pygame.mouse.get_pos()
        mouse_pos = Vector2(
            mouse_pos[0] / (screen_size[0] / SCREEN_WIDTH),
            mouse_pos[1] / (screen_size[1] / SCREEN_HEIGHT),
        )

        if (
            abs(mouse_pos.x - SCREEN_WIDTH / 2) > 10
            or abs(mouse_pos.y - SCREEN_HEIGHT / 2) > 10
        ):
            direction = Vector2(
                mouse_pos.x - SCREEN_WIDTH / 2, mouse_pos.y - SCREEN_HEIGHT / 2
            )
            self.target_angle = int(math.degrees(math.atan2(direction.y, direction.x)))

            # Calculate the difference between the current angle and the target angle
            angle_difference = self.target_angle - self.angle

            # Adjust the angle_difference to be between -180 and 180 degrees
            if angle_difference > 180:
                angle_difference -= 360
            elif angle_difference < -180:
                angle_difference += 360

            # Gradually rotate the player towards the target angle
            rotation_amount = min(
                abs(angle_difference),
                self.velocity / PLAYER_VELOCITY * MAX_ROTATION_SPEED,
            )
            rotation_sign = -1 if angle_difference < 0 else 1
            self.angle += rotation_sign * rotation_amount * dt

            self.speed.x = math.cos(math.radians(self.angle)) * self.velocity
            self.speed.y = math.sin(math.radians(self.angle)) * self.velocity

            # Rotate the spaceship image
            if self.angle > 359:
                self.angle = self.angle - 360
            if self.angle < 0:
                self.angle = 360 + self.angle
            try:
                if self.image != self.cache[self.angle]:
                    self.image = self.cache[self.angle]
            except KeyError:
                self.cache[self.angle] = pygame.transform.rotate(
                    self.original_image, -self.angle - 90
                )
                self.image = self.cache[self.angle]

            self.rect = self.image.get_frect(center=self.rect.center)

    def update(self, scroll, dt):
        # self.get_input()
        self.rotate(dt)
        self.move(scroll, dt)
        self.rect.center = self.hit_box.center


class Bullet(pygame.sprite.Sprite):
    def __init__(self, group, pos, angle, player_velocity):
        super().__init__(group)

        self.image = pygame.image.load(IMGS_DIR + "misc/bullet.png")
        self.rect = self.image.get_frect(center=pos)

        self.image = pygame.transform.rotate(self.image, -angle - 90)
        self.speed = Vector2(
            math.cos(math.radians(angle))
            * (player_velocity / PLAYER_VELOCITY)
            * BULLET_SPEED,
            math.sin(math.radians(angle)) * BULLET_SPEED,
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
