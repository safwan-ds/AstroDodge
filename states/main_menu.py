from typing import Any
from math import sin
import sys
from time import time
import pygame

from classes.particles import Emitter
from classes.trail import Trail
from classes.state import State
from states.gameplay import Gameplay
from utils import get_animations, resource_path

from pygame.locals import *
from config import *


class MainMenu(State):
    def __init__(self, app):
        super().__init__(app)
        self.screen: pygame.Surface = self.app.screen

        self.starting = False
        self.quitting = False

        pos_x = self.app.screen_size[0] / 2

        self.logo = pygame.sprite.GroupSingle(Logo((pos_x, 100)))
        self.trails = pygame.sprite.Group()

        self.buttons = pygame.sprite.Group()
        Button("start", self.start, (pos_x, 180), self.buttons)
        Button("quit", self.quit, (pos_x, 250), self.buttons)

        self.particles = Emitter(SCREEN_HEIGHT)

    def start(self):
        self.fade_out = True
        self.starting = True

    def quit(self):
        self.fade_out = True
        self.quitting = True

    def update(self, dt):
        super().update(dt)

        if self.app.glitch > GLITCH:
            self.app.glitch -= 0.1 * dt
        if self.app.glitch < GLITCH:
            self.app.glitch = GLITCH
        if self.app.mousebuttondown == 1:
            self.app.glitch = 1.0
            self.particles.add_particle(5)
        self.screen.fill("black")
        self.particles.update((0, 0), self.app.dt, 5, 0.5)
        self.particles.draw(self.screen)
        self.trails.update((0, 0), dt, 5)
        self.trails.draw(self.screen)
        self.logo.update(self.trails, (59, 101, 143))
        self.logo.draw(self.screen)
        self.buttons.update(self.app)
        self.buttons.draw(self.screen)

        self.screen.blit(self.transition, (0, 0))
        if self.transition_progress >= 1 and self.fade_out:
            if self.starting:
                self.fade_out = False
                self.fade_in = True
                Gameplay(self.app).add()
            if self.quitting:
                self.app.running = False


class Logo(pygame.sprite.Sprite):
    def __init__(self, pos):
        super().__init__()

        self.image = pygame.image.load(resource_path(IMGS_DIR + "ui\\logo.png"))
        self.image = pygame.transform.scale_by(self.image, 3)
        self.rect = self.image.get_frect(center=pos)
        self.y = self.rect.y

        self.last_trail = time()

    def update(self, trail_group, trail_color):
        self.rect.y = self.y + sin(time() * 2) * 7

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
        self.rect = self.image.get_frect(midtop=pos)

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
