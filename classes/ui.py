import pygame

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

        self.original_image = pygame.image.load(IMGS_DIR + "misc/arrow.png")
        self.rect = self.original_image.get_frect(center=pos)

    def update(self, angle):
        self.image = pygame.transform.rotate(self.original_image, -angle - 90)
        self.rect = self.image.get_frect(center=self.rect.center)
