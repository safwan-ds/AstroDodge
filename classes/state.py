import math
from time import time
import pygame
from pygame.locals import *

from globals import *


class State:
    def __init__(self, app):
        self.app = app

        self.fade_in = False
        self.fade_out = False
        self.transition = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), SRCALPHA)
        self.transition_progress = 1

    def add(self):
        self.fade_in = True
        self.app.state_stack.append(self)

    def remove(self):
        self.fade_out = True

    def update(self, dt):
        if self.transition_progress < 1 and self.fade_out:
            self.transition_progress += TRANSITION_SPEED * dt
        elif self.transition_progress >= 1 and self.fade_out:
            try:
                self.app.state_stack.remove(self)
            except ValueError:
                pass

        if self.transition_progress > 0 and self.fade_in:
            self.transition_progress -= TRANSITION_SPEED * dt
        else:
            self.fade_in = False

        self.transition_radius = int(
            math.sqrt(SCREEN_WIDTH**2 + SCREEN_HEIGHT**2)
            / 2
            * self.transition_progress
        )
        self.transition.fill((0, 0, 0, 0))
        pygame.draw.circle(
            self.transition,
            "black",
            (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2),
            self.transition_radius,
        )
        pygame.draw.circle(
            self.transition,
            "white",
            (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2),
            self.transition_radius * 1.2,
            100,
        )
        pygame.draw.circle(
            self.transition,
            (59 / 2, 101 / 2, 143 / 2),
            (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2),
            self.transition_radius * 1.5,
            50,
        )
