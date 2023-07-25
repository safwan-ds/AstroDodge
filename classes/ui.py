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


class IntervalBar(pygame.sprite.Sprite):
    def __init__(self, group, pos):
        super().__init__(group)

        self.image = pygame.Surface((SHOOTING_BAR_WIDTH, SHOOTING_BAR_HEIGHT), SRCALPHA)
        self.rect = self.image.get_frect(center=pos)
        # self.image.set_alpha(100)

    def update(self, percent):
        self.image.fill((0, 0, 0, 0))

        if percent <= 1:
            pygame.draw.rect(
                self.image,
                "red",
                (0, 0, SHOOTING_BAR_WIDTH * percent, SHOOTING_BAR_HEIGHT),
            )
        else:
            pygame.draw.rect(
                self.image, "white", (0, 0, SHOOTING_BAR_WIDTH, SHOOTING_BAR_HEIGHT)
            )

        pygame.draw.rect(
            self.image, "white", (0, 0, SHOOTING_BAR_WIDTH, SHOOTING_BAR_HEIGHT), 1
        )


class HealthBar(pygame.sprite.Sprite):
    def __init__(self, pos, font):
        super().__init__()
        self.font = font

        self.image = pygame.image.load(IMGS_DIR + "ui/health_bar.png")
        self.rect = self.image.get_frect(topright=pos)  #

        self.current_hp = 100

        self.static_color = pygame.Color(59, 155, 255)
        self.hurt_color = pygame.Color(255, 0, 0)
        self.heal_color = pygame.Color(0, 255, 0)
        self.text_color = pygame.Color(0, 255, 255)

        self.static_bar_rect = self.rect.inflate(-15, -15)
        self.animated_bar_rect = self.static_bar_rect.copy()
        self.initial_width = self.static_bar_rect.width

        self.hurt = False
        self.heal = False

    def update(self, hp, surface: pygame.Surface):
        if hp < self.current_hp:
            self.hurt = True
            self.heal = False
            self.static_bar_rect.width = self.initial_width * hp / 100
            self.current_hp = hp
        elif hp > self.current_hp:
            self.hurt = False
            self.heal = True
            self.animated_bar_rect.width = self.initial_width * hp / 100
            self.current_hp = hp

        if self.static_bar_rect.width < self.animated_bar_rect.width:
            if self.hurt:
                self.animated_bar_rect.width -= 1
                pygame.draw.rect(surface, self.hurt_color, self.animated_bar_rect)
            if self.heal:
                self.static_bar_rect.width += 1
                pygame.draw.rect(surface, self.heal_color, self.animated_bar_rect)

        pygame.draw.rect(surface, self.static_color, self.static_bar_rect)
        text = self.font.render(str(hp), False, self.text_color)
        text_rect = text.get_frect(center=self.rect.center)
        surface.blit(text, text_rect)
