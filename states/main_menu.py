from typing import Any
from time import time
from math import sin
import pygame

from classes.particles import Emitter
from classes.state import State
from states.gameplay import Gameplay
from utils import get_animations

from pygame.locals import *
from config import *


class MainMenu(State):
    def __init__(self, app):
        super().__init__(app)

        pos_x = app.screen_size[0] / 2

        self.logo = pygame.sprite.GroupSingle(Logo((pos_x, 100)))

        self.buttons = pygame.sprite.Group()
        Button("start", self.start, (pos_x, 215), self.buttons)
        Button("quit", self.quit, (pos_x, 280), self.buttons)

        self.particles = Emitter(SCREEN_HEIGHT)

    def start(self):
        Gameplay(self.app).add()

    def quit(self):
        self.app.running = False

    def update(self, dt):
        if self.app.glitch > 0.1:
            self.app.glitch -= 0.1
        if self.app.glitch < 0.1:
            self.app.glitch = 0.1
        if self.app.mousebuttondown == 1:
            self.app.glitch = 1.0
            self.particles.add_particle(5)
        self.app.screen.fill("black")
        self.particles.update((0, 0), self.app.dt, 5, 0.5)
        self.particles.draw(self.app.screen)
        self.logo.update()
        self.logo.draw(self.app.screen)
        self.buttons.update(self.app)
        self.buttons.draw(self.app.screen)


class Logo(pygame.sprite.Sprite):
    def __init__(self, pos):
        super().__init__()

        self.image = pygame.image.load(IMGS_DIR + "ui/title_logo.png")
        self.image = pygame.transform.scale_by(self.image, 3)
        self.rect = self.image.get_frect(center=pos)
        self.y = self.rect.y

    def update(self):
        self.rect.y = self.y + sin(time() * 2) * 7


class Button(pygame.sprite.Sprite):
    def __init__(self, name, method, pos, group):
        super().__init__(group)
        self.method = method

        self.animations = get_animations(IMGS_DIR + "ui", 96)[name + "_button"]
        for index, animation in enumerate(self.animations):
            self.animations[index] = pygame.transform.scale_by(animation, 2)
        self.frame = 0

        self.image = self.animations[self.frame]
        self.rect = self.image.get_frect(midtop=pos)

        self.clicked = False
        self.hovered = False

        self.hover_sound = pygame.mixer.Sound(SFX_DIR + "button_hover")
        self.hover_sound.set_volume(0.3)
        self.click_sound = pygame.mixer.Sound(SFX_DIR + "button_click")

    def get_state(self):
        if self.hovered:
            self.frame = 1
        elif self.clicked:
            self.frame = 1
        else:
            self.frame = 0

        self.image = self.animations[self.frame]

    def update(self, game):
        mouse_pressed = pygame.mouse.get_pressed()[0]
        mouse_pos = (
            pygame.mouse.get_pos()[0] / (game.display_size[0] / SCREEN_WIDTH),
            pygame.mouse.get_pos()[1] / (game.display_size[1] / SCREEN_HEIGHT),
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
