import math
import random
from time import time
import pygame
from pygame.math import Vector2

from utils import get_animations

from pygame.locals import *
from config import *


class Asteroid(pygame.sprite.Sprite):
    def __init__(self, group):
        super().__init__(group)

        # Randomly select an edge of the screen
        edge = random.choice(["top", "bottom", "left", "right"])
        if edge == "top":
            x = random.randint(-ASTEROID_SPAWN_AREA, SCREEN_WIDTH + ASTEROID_SPAWN_AREA)
            y = -ASTEROID_SPAWN_AREA
        elif edge == "bottom":
            x = random.randint(-ASTEROID_SPAWN_AREA, SCREEN_WIDTH + ASTEROID_SPAWN_AREA)
            y = SCREEN_HEIGHT + ASTEROID_SPAWN_AREA
        elif edge == "left":
            x = -ASTEROID_SPAWN_AREA
            y = random.randint(
                -ASTEROID_SPAWN_AREA, SCREEN_HEIGHT + ASTEROID_SPAWN_AREA
            )
        else:  # edge == "right"
            x = SCREEN_WIDTH + ASTEROID_SPAWN_AREA
            y = random.randint(
                -ASTEROID_SPAWN_AREA, SCREEN_HEIGHT + ASTEROID_SPAWN_AREA
            )

        # Randomly select a size
        self.scale = random.uniform(ASTEROID_MIN_SCALE, ASTEROID_MAX_SCALE)

        self.image = pygame.transform.scale_by(
            pygame.image.load(IMGS_DIR + "asteroids/1.png"), self.scale
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

        # Randomly select a speed
        self.speed = random.randint(ASTEROID_MIN_SPEED, ASTEROID_MAX_SPEED)
        self.speed = Vector2(math.cos(angle) * self.speed, math.sin(angle) * self.speed)

        self.born = time()

    def update(self, scroll, dt):
        age = time() - self.born
        if (
            self.rect.centerx > SCREEN_WIDTH + ASTEROID_SPAWN_AREA
            or self.rect.centerx < -ASTEROID_SPAWN_AREA
            or self.rect.centery > SCREEN_HEIGHT + ASTEROID_SPAWN_AREA
            or self.rect.centery < -ASTEROID_SPAWN_AREA
        ) and age > 5:
            self.kill()

        self.rect.move_ip(self.speed * dt + scroll)


class Explosion(pygame.sprite.Sprite):
    def __init__(self, group, pos, scale):
        super().__init__(group)

        self.frames = get_animations(IMGS_DIR + "asteroids", 16)["explosion"]
        for i, frame in enumerate(self.frames):
            self.frames[i] = pygame.transform.scale_by(frame, scale)
        self.frame = 0

        self.image = self.frames[self.frame]
        self.rect = self.image.get_frect(center=pos)

    def animate(self, dt):
        self.frame += ANIMATION_SPEED * dt
        self.image = self.frames[int(self.frame)]

    def update(self, scroll, dt):
        if self.frame >= len(self.frames) - 1:
            self.kill()

        self.rect.move_ip(scroll)
        self.animate(dt)
