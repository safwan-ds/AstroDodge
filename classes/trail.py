import pygame

from pygame.locals import *


class Trail(pygame.sprite.Sprite):
    def __init__(self, group, image, pos, color="white"):
        super().__init__(group)

        self.image = image.copy()  # Trail particle size
        self.image.fill(color, special_flags=BLEND_MULT)
        self.rect = self.image.get_frect(center=pos)
        self.fade_alpha = 255

    def update(self, scroll, dt, fade):
        self.fade_alpha -= dt * fade  # Adjust the fading speed of the trail
        if self.fade_alpha <= 0:
            self.kill()
        self.image.set_alpha(max(0, int(self.fade_alpha)))
        self.rect.move_ip(scroll)
