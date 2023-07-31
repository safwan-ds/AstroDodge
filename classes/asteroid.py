import math
import random
from time import time
import pygame
from pygame.math import Vector2

from classes.trail import Trail
from utils import get_animations, resource_path

from pygame.locals import *
from globals import *


class Asteroid(pygame.sprite.Sprite):
    def __init__(self, group):
        super().__init__(group)

        # Randomly select an edge of the screen
        edge = random.choice(["top", "bottom", "left", "right"])
        if edge == "top":
            x = random.randint(-OUTSIDE_MARGIN, SCREEN_WIDTH + OUTSIDE_MARGIN)
            y = -OUTSIDE_MARGIN
        elif edge == "bottom":
            x = random.randint(-OUTSIDE_MARGIN, SCREEN_WIDTH + OUTSIDE_MARGIN)
            y = SCREEN_HEIGHT + OUTSIDE_MARGIN
        elif edge == "left":
            x = -OUTSIDE_MARGIN
            y = random.randint(-OUTSIDE_MARGIN, SCREEN_HEIGHT + OUTSIDE_MARGIN)
        else:  # edge == "right"
            x = SCREEN_WIDTH + OUTSIDE_MARGIN
            y = random.randint(-OUTSIDE_MARGIN, SCREEN_HEIGHT + OUTSIDE_MARGIN)

        # Randomly select a size
        self.scale = random.uniform(ASTEROID_MIN_SCALE, ASTEROID_MAX_SCALE)

        self.image = pygame.transform.scale_by(
            pygame.image.load(resource_path(IMGS_DIR + "asteroids\\1.png")), self.scale
        )
        self.rect = self.image.get_frect(center=(x, y))

        x = SCREEN_WIDTH / 2 - self.rect.centerx
        y = SCREEN_HEIGHT / 2 - self.rect.centery
        randomness = 500
        direction = Vector2(
            x + random.randint(-randomness, randomness),
            y + random.randint(-randomness, randomness),
        )
        angle = math.atan2(direction.y, direction.x)
        self.image = pygame.transform.rotate(self.image, -math.degrees(angle))
        self.rect = self.image.get_frect(center=self.rect.center)

        # Randomly select a speed
        self.speed = random.randint(ASTEROID_MIN_SPEED, ASTEROID_MAX_SPEED)
        self.speed = Vector2(math.cos(angle) * self.speed, math.sin(angle) * self.speed)

        self.born = time()

        self.last_trail = time()

    def update(self, scroll, dt, trail_group, trail_color):
        age = time() - self.born
        if (
            self.rect.centerx > SCREEN_WIDTH + OUTSIDE_MARGIN
            or self.rect.centerx < -OUTSIDE_MARGIN
            or self.rect.centery > SCREEN_HEIGHT + OUTSIDE_MARGIN
            or self.rect.centery < -OUTSIDE_MARGIN
        ) and age > 5:
            self.kill()

        if time() - self.last_trail >= 0.05:
            Trail(trail_group, self.image, self.rect.center, trail_color)
            self.last_trail = time()
        self.rect.move_ip(self.speed * dt + scroll)


class Explosion(pygame.sprite.Sprite):
    def __init__(self, group, pos, scale, color=None):
        super().__init__(group)

        self.frames = get_animations(resource_path(IMGS_DIR + "asteroids"), 16)[
            "explosion"
        ]
        for i, frame in enumerate(self.frames):
            self.frames[i] = pygame.transform.scale_by(frame, scale)
            if color:
                self.frames[i].fill(color, special_flags=BLEND_MULT)
        self.frame = 0

        self.image = self.frames[self.frame]
        self.rect = self.image.get_frect(center=pos)

        self.last_trail = time()

    def animate(self, dt):
        self.frame += ANIMATION_SPEED * dt
        self.image = self.frames[int(self.frame)]

    def update(self, scroll, dt):
        self.rect.move_ip(scroll)
        try:
            self.animate(dt)
        except IndexError:
            self.kill()
            return
