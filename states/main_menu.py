import pygame
from pygame.math import Vector2
from pygame.locals import *

from classes.particles import Emitter
from classes.ui import Logo, Button
from classes.state import State
from states.gameplay import Gameplay
from utils import resource_path

from globals import MUSIC_DIR, GLITCH_AMOUNT, PARTICLE_AMOUNT


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
        Button("start", self.start, (pos_x, 220), self.buttons)
        Button("quit", self.quit, (pos_x, 290), self.buttons)

        self.particles = Emitter()

        self.main_menu_music = pygame.mixer.Sound(
            resource_path(MUSIC_DIR + "main_menu.wav")
        )
        self.music_volume = 0
        self.main_menu_music.set_volume(self.music_volume)

    def add(self):
        super().add()

        self.music_channel = self.main_menu_music.play(-1)

    def start(self):
        self.main_menu_music.fadeout(1000)
        self.fade_out = True
        self.starting = True

    def quit(self):
        self.fade_out = True
        self.quitting = True

    def update(self, dt):
        super().update(dt)

        # Music
        if not self.music_channel.get_busy():
            self.music_volume = 0
            self.main_menu_music.set_volume(self.music_volume)
            self.main_menu_music.play(-1)

        if self.main_menu_music.get_volume() < 1:
            self.music_volume += 0.01 * dt
            self.main_menu_music.set_volume(self.music_volume)

        if self.app.glitch > GLITCH_AMOUNT:
            self.app.glitch -= 0.1 * dt
        if self.app.glitch < GLITCH_AMOUNT:
            self.app.glitch = GLITCH_AMOUNT
        if self.app.mousebuttondown == 1:
            self.app.glitch = 1.0
            self.particles.add_particle(PARTICLE_AMOUNT)
        self.screen.fill("black")
        self.particles.update((0, 0), self.app.dt, PARTICLE_AMOUNT, 0.5)
        self.particles.draw(self.screen)
        self.trails.update(Vector2(0, 0), dt, 5)
        self.trails.draw(self.screen)
        self.logo.update(self.trails, (59, 101, 143))
        self.logo.draw(self.screen)
        if not self.fade_in:
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
