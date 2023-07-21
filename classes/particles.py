import random
from time import time
import pygame
from pygame.locals import *
from pygame.math import Vector2

from debug import console_debug

from config import *


class Emitter(pygame.sprite.Group):
    def __init__(self, y):
        super().__init__()

        self.last_addition = 0

        self.y = y + 20
        # self.PARTICLE_EVENT = USEREVENT + 1

    def add_particle(self, amount):
        for _ in range(random.randint(1, amount)):
            self.add(
                Particle(
                    (
                        random.uniform(0, SCREEN_WIDTH) - 20,
                        random.uniform(0, self.y),
                    )
                )
            )

    def update(self, scroll, dt, amount, interval=None):
        super().update(scroll, dt)

        if interval:
            if time() - self.last_addition >= interval:
                self.add_particle(amount)
                self.last_addition = time()


class Particle(pygame.sprite.Sprite):
    def __init__(self, pos):
        super().__init__()

        self.image = pygame.image.load(IMGS_DIR + "misc/particle.png")
        self.image = pygame.transform.rotate(self.image, random.randint(0, 360))
        self.original_image = self.image.copy()
        self.rect = self.image.get_frect(center=pos)
        self.velocity = Vector2(
            PARTICLE_VELOCITY * random.uniform(0.1, 1),
            -PARTICLE_VELOCITY * random.uniform(0.1, 2),
        )
        self.age = 0
        self.alpha = 0

    def update(self, scroll, dt):
        if self.alpha < 255:
            self.alpha += (1 / 60) * dt
            self.image.set_alpha(int(self.alpha))

        self.rect.move_ip(self.velocity * dt + scroll)

        self.age += (1 / 60) * dt
        if self.age < PARTICLE_LIFETIME:
            scale_factor = 1.0 - (self.age / PARTICLE_LIFETIME)
            self.image = pygame.transform.scale_by(self.original_image, scale_factor)
            self.rect = self.image.get_rect(center=self.rect.center)
        else:
            self.kill()
