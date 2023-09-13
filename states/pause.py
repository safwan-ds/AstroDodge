import pygame
from pygame.math import Vector2
from pygame.locals import *

from classes.ui import Logo, Button
from classes.state import State

from globals import SCREEN_WIDTH, SCREEN_HEIGHT


class PauseMenu(State):
    def __init__(self, app, gameplay):
        super().__init__(app)
        self.gameplay = gameplay

        pos_x = SCREEN_WIDTH / 2

        # self.logo = pygame.sprite.GroupSingle(Logo((pos_x, 100)))
        self.trails = pygame.sprite.Group()

        self.buttons = pygame.sprite.Group()
        Button("start", self.start, (pos_x, SCREEN_HEIGHT / 2 - 35), self.buttons)
        Button("quit", self.quit, (pos_x, SCREEN_HEIGHT / 2 + 35), self.buttons)

    def start(self):
        self.gameplay.unpause()

    def quit(self):
        self.gameplay.exit_sound.play()
        self.gameplay.save_data()
        self.gameplay.remove()

    def update(self):
        # self.logo.draw(self.app.screen)
        self.buttons.update(self.app)
        self.buttons.draw(self.app.screen)
