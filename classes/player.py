import math
from time import time
from pygame.math import Vector2
from pygame.locals import *
import pygame

from classes.trail import Trail
from globals import *


class Player(pygame.sprite.Sprite):
    def __init__(self, pos):
        super().__init__()
        self.image = pygame.image.load(IMGS_DIR + "player.png")
        self.original_image = self.image.copy()
        self.rect = self.original_image.get_frect(center=pos)
        self.hit_box = self.rect.inflate(-20, -20)

        self.velocity = PLAYER_VELOCITY
        self.speed = Vector2(PLAYER_VELOCITY, 0)
        self.cache = {}
        self.last_trail = time()
        self.angle = 0
        self.target_angle = 0

    def get_input(self):
        keys = pygame.key.get_pressed()
        self.speed.x = (
            PLAYER_VELOCITY if keys[K_d] else -PLAYER_VELOCITY if keys[K_a] else 0
        )
        self.speed.y = (
            PLAYER_VELOCITY if keys[K_s] else -PLAYER_VELOCITY if keys[K_w] else 0
        )

    def move(self, scroll, dt):
        movement = (self.speed.x * dt + scroll.x, self.speed.y * dt + scroll.y)
        self.hit_box.move_ip(movement)

    def rotate(self, dt):
        screen_size = pygame.display.get_window_size()
        mouse_pos = pygame.mouse.get_pos()
        scaled_mouse = Vector2(
            mouse_pos[0] / (screen_size[0] / SCREEN_WIDTH),
            mouse_pos[1] / (screen_size[1] / SCREEN_HEIGHT),
        )

        if (
            abs(scaled_mouse.x - SCREEN_WIDTH / 2) > 10
            or abs(scaled_mouse.y - SCREEN_HEIGHT / 2) > 10
        ):
            direction = Vector2(
                scaled_mouse.x - SCREEN_WIDTH / 2, scaled_mouse.y - SCREEN_HEIGHT / 2
            )
            self.target_angle = math.degrees(math.atan2(direction.y, direction.x))

            angle_diff = (self.target_angle - self.angle) % 360
            if angle_diff > 180:
                angle_diff -= 360

            rotation_step = min(
                abs(angle_diff),
                self.velocity / PLAYER_VELOCITY * MAX_ROTATION_SPEED * dt,
            )
            self.angle += rotation_step * (1 if angle_diff > 0 else -1)
            self.angle %= 360

            # Update sprite rotation
            if self.angle not in self.cache:
                self.cache[self.angle] = pygame.transform.rotate(
                    self.original_image, -self.angle - 90
                )
            self.image = self.cache[self.angle]
            self.rect = self.image.get_frect(center=self.rect.center)

            # Update movement direction
            self.speed.x = math.cos(math.radians(self.angle)) * self.velocity
            self.speed.y = math.sin(math.radians(self.angle)) * self.velocity

    def update(self, scroll, dt, trail_group, trail_color):
        self.rotate(dt)
        self.move(scroll, dt)

        if time() - self.last_trail >= 0.01:
            Trail(trail_group, self.image, self.rect.center, trail_color)
            self.last_trail = time()

        self.rect.center = self.hit_box.center


class Bullet(pygame.sprite.Sprite):
    def __init__(self, group, pos, angle, player_velocity):
        super().__init__(group)
        self.image = pygame.image.load(IMGS_DIR + "misc\\bullet.png")
        self.image = pygame.transform.rotate(self.image, -angle - 90)

        direction = Vector2(
            math.cos(math.radians(angle)), math.sin(math.radians(angle))
        )
        self.speed = direction * (player_velocity / PLAYER_VELOCITY) * BULLET_SPEED
        self.rect = self.image.get_frect(center=pos)
        self.last_trail = time()

    def update(self, scroll, dt, trail_group, trail_color):
        if any(
            (
                self.rect.centerx > SCREEN_WIDTH + OUTSIDE_MARGIN,
                self.rect.centerx < -OUTSIDE_MARGIN,
                self.rect.centery > SCREEN_HEIGHT + OUTSIDE_MARGIN,
                self.rect.centery < -OUTSIDE_MARGIN,
            )
        ):
            self.kill()

        if time() - self.last_trail >= 0.01:
            Trail(trail_group, self.image, self.rect.center, trail_color)
            self.last_trail = time()

        self.rect.move_ip(self.speed * dt + scroll)
