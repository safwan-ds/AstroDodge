import math
from time import time
import pygame
from pygame.locals import *

from classes.trail import Trail

from utils import resource_path, get_animations
from globals import SCREEN_WIDTH, SCREEN_HEIGHT, IMGS_DIR, SFX_DIR


class Logo(pygame.sprite.Sprite):
    def __init__(self, pos):
        super().__init__()

        self.image = pygame.image.load(resource_path(IMGS_DIR + "ui\\logo.png"))
        self.image = pygame.transform.scale_by(self.image, 3)
        self.rect = self.image.get_frect(center=pos)
        self.y = self.rect.y

        self.last_trail = time()

    def update(self, trail_group, trail_color):
        self.rect.y = self.y + math.sin(time() * 2) * 7

        if time() - self.last_trail >= 0.1:
            Trail(trail_group, self.image, self.rect.center, trail_color)
            self.last_trail = time()


class Button(pygame.sprite.Sprite):
    def __init__(self, name, method, pos, group):
        super().__init__(group)
        self.method = method

        self.animations = get_animations(resource_path(IMGS_DIR + "ui"), 90)[
            name + "_button"
        ]
        for index, animation in enumerate(self.animations):
            self.animations[index] = pygame.transform.scale_by(animation, 2)
        self.frame = 0

        self.image = self.animations[self.frame]
        self.rect = self.image.get_frect(center=pos)

        self.clicked = False
        self.hovered = False

        self.hover_sound = pygame.mixer.Sound(resource_path(SFX_DIR + "button_hover"))
        self.hover_sound.set_volume(0.3)
        self.click_sound = pygame.mixer.Sound(resource_path(SFX_DIR + "button_click"))

    def get_state(self):
        if self.hovered:
            self.frame = 1
        elif self.clicked:
            self.frame = 1
        else:
            self.frame = 0

        self.image = self.animations[self.frame]

    def update(self, app):
        mouse_pressed = pygame.mouse.get_pressed()[0]
        mouse_pos = (
            pygame.mouse.get_pos()[0] / (app.display_size[0] / SCREEN_WIDTH),
            pygame.mouse.get_pos()[1] / (app.display_size[1] / SCREEN_HEIGHT),
        )
        button_hovered = self.rect.collidepoint(mouse_pos)

        if (
            button_hovered
            and not mouse_pressed
            and not self.hovered
            and not self.clicked
        ):
            self.hover_sound.play()
            self.frame = 1
            self.hovered = True
        else:
            self.frame = 0

        if self.hovered and mouse_pressed:
            self.clicked = True
            self.hovered = False

        if self.clicked and not mouse_pressed:
            if button_hovered:
                self.click_sound.play()
                self.method()
                self.clicked = False
            else:
                self.clicked = False

        if not button_hovered:
            self.hovered = False

        self.get_state()


class Score(pygame.sprite.Sprite):
    def __init__(self, group, pos):
        super().__init__(group)
        self.pos = pos

        self.image = pygame.Surface((0, 0))
        self.rect = self.image.get_frect(center=self.pos)

    def update(self, font: pygame.Font, score, color="white"):
        self.image = font.render(str(score), False, color)
        self.rect = self.image.get_frect(center=self.pos)


class Arrow(pygame.sprite.Sprite):
    def __init__(self, group, pos):
        super().__init__(group)

        self.image = pygame.image.load(resource_path(IMGS_DIR + "misc\\arrow.png"))
        self.original_image = self.image.copy()
        self.rect = self.original_image.get_frect(center=pos)

        self.cache = {}

    def rotate(self, angle):
        try:
            if self.image != self.cache[angle]:
                self.image = self.cache[angle]
        except KeyError:
            self.cache[angle] = pygame.transform.rotate(
                self.original_image, -angle - 90
            )
            self.image = self.cache[angle]

        self.rect = self.image.get_frect(center=self.rect.center)

    def update(self, angle):
        self.rotate(angle)


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
