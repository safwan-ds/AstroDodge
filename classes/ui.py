import pygame

from pygame.locals import *
from config import DEFAULT_FONT


class Score(pygame.sprite.Sprite):
    def __init__(self, group, pos):
        super().__init__(group)
        self.pos = pos

        self.image = pygame.Surface((0, 0))
        self.rect = self.image.get_frect(center=self.pos)

    def update(self, font: pygame.Font, score):
        self.image = font.render(str(score), False, "white")
        self.rect = self.image.get_frect(center=self.pos)
