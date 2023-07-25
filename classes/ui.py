from typing import Any
import pygame

from utils import resource_path

from pygame.locals import *
from config import *


class Score(pygame.sprite.Sprite):
    def __init__(self, group, pos):
        super().__init__(group)
        self.pos = pos

        self.image = pygame.Surface((0, 0))
        self.rect = self.image.get_frect(center=self.pos)

    def update(self, font: pygame.Font, score):
        self.image = font.render(str(score), False, "white")
        self.rect = self.image.get_frect(center=self.pos)


class Arrow(pygame.sprite.Sprite):
    def __init__(self, group, pos):
        super().__init__(group)

        self.original_image = pygame.image.load(
            resource_path(IMGS_DIR + "misc\\arrow.png")
        )
        self.rect = self.original_image.get_frect(center=pos)

        self.cache = {}

    def update(self, angle):
        try:
            if self.image != self.cache[angle]:
                self.image = self.cache[angle]
        except KeyError:
            self.cache[angle] = pygame.transform.rotate(
                self.original_image, -angle - 90
            )
            self.image = self.cache[angle]
        self.rect = self.image.get_frect(center=self.rect.center)


class Bar(pygame.sprite.Sprite):
    def __init__(self, group, pos, width, height):
        super().__init__(group)
        self.width = width
        self.height = height

        self.image = pygame.Surface((width, height), SRCALPHA)
        self.rect = self.image.get_frect(center=pos)

    def update(self, percent, color="white"):
        self.image.fill((0, 0, 0, 0))

        if percent <= 1:
            pygame.draw.rect(
                self.image,
                color,
                (0, 0, self.width * percent, self.height),
            )
        else:
            pygame.draw.rect(self.image, color, (0, 0, self.width, self.height))

        pygame.draw.rect(self.image, color, (0, 0, self.width, self.height), 1)
