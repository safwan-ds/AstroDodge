import math
import random
from time import time
import pygame
from pygame.math import Vector2

from pygame.locals import *
from config import *


class Asteroid(pygame.sprite.Sprite):
    def __init__(self, group):
        super().__init__(group)

        scale = random.randint(10, 20)
        self.image = pygame.Surface((scale, scale))
        self.image.fill(
            (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
        )

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
        self.rect = self.image.get_frect(center=(x, y))

        direction = Vector2(
            SCREEN_WIDTH / 2 - self.rect.centerx, SCREEN_HEIGHT / 2 - self.rect.centery
        )
        angle = math.atan2(direction.y, direction.x)
        self.speed = random.randint(MIN_ASTEROID_SPEED, MAX_ASTEROID_SPEED)
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
