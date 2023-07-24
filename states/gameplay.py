import json
from typing import Any
import random
from time import time
import pygame
from pygame.math import Vector2

from classes.player import Player, Bullet
from classes.asteroid import Asteroid, Explosion
from classes.particles import Emitter
from classes.ui import Score, Arrow
from classes.state import State
from utils import onscreen_debug, console_debug

from pygame.locals import *
from config import *


class Gameplay(State):
    def __init__(self, app):
        super().__init__(app)
        self.screen: pygame.Surface = self.app.screen

        self.start_time = time()
        self.level = LEVEL

        self.player = pygame.sprite.GroupSingle()
        Player(self.player, (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
        self.bullets = pygame.sprite.Group()
        self.last_shot = 0
        self.asteroids = pygame.sprite.Group()
        self.gained_points = GainedPoints()
        self.explosions = pygame.sprite.Group()
        self.last_asteroid = time()
        self.score = 0

        self.particles = Emitter(SCREEN_HEIGHT)

        self.shake = 0

        self.font = pygame.Font(DEFAULT_FONT, 40)
        self.s_font = pygame.Font(DEFAULT_FONT, 30)

        # Gameplay states
        self.paused = False
        self.paused_text = self.font.render(
            "Paused! Click the mouse to continue", False, "white"
        )
        self.paused_text_rect = self.paused_text.get_frect(
            center=(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        )

        self.game_over = False
        self.game_over_text1 = self.font.render(
            "Game Over! Click the mouse to try again", False, "white"
        )
        self.game_over_text2 = self.font.render(
            "or press ESC to exit to title screen", False, "white"
        )
        # Calculate positions for each line of text
        self.line1_x = SCREEN_WIDTH / 2 - self.game_over_text1.get_width() / 2
        self.line1_y = SCREEN_HEIGHT / 2 - self.game_over_text1.get_height()
        self.line2_x = SCREEN_WIDTH / 2 - self.game_over_text2.get_width() / 2
        self.line2_y = SCREEN_HEIGHT / 2

        # UI
        self.ui = pygame.sprite.Group()
        self.score_text = Score(self.ui, (SCREEN_WIDTH / 2, 50))
        self.arrow = Arrow(self.ui, (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))

        # Sounds
        pygame.mixer.music.load(MUSIC_DIR + "gameplay.wav")
        self.music_volume = 0
        pygame.mixer.music.set_volume(self.music_volume)
        self.shoot_sound = pygame.mixer.Sound(SFX_DIR + "shoot")
        self.shoot_sound.set_volume(0.1)
        self.player_explosion = pygame.mixer.Sound(SFX_DIR + "heavy_explosion")
        self.asteroid_kill = pygame.mixer.Sound(SFX_DIR + "mid_explosion")
        self.asteroid_kill.set_volume(0.7)
        self.asteroid_collision = pygame.mixer.Sound(SFX_DIR + "explosion")
        self.asteroid_collision.set_volume(0.2)

    def add(self):
        super().add()

        # pygame.mixer.music.play(-1)

    def remove(self):
        super().remove()

        pygame.mixer.music.fadeout(500)

    def get_input(self):
        if (
            self.app.mousebuttondown == 1
            and time() - self.last_shot >= SHOOTING_INTERVAL
            and not self.game_over
            and not self.paused
        ):
            self.shoot_sound.play()
            Bullet(
                self.bullets,
                self.player.sprite.rect.center,
                self.player.sprite.target_angle,
                self.player.sprite.velocity,
            )
            self.last_shot = time()
            self.shake = SHAKE / 3

        if self.game_over and self.app.keydown == K_ESCAPE:
            self.save_data()
            self.remove()

        elif self.game_over and self.app.mousebuttondown:
            self.save_data()
            self.asteroids.empty()
            Player(self.player, (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
            self.arrow = Arrow(self.ui, (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
            self.level = LEVEL
            self.score = 0
            self.asteroids.empty()
            self.game_over = False

        if self.paused:
            if self.app.mousebuttondown:
                self.paused = False
            elif self.app.keydown == K_ESCAPE:
                self.remove()
        elif not self.game_over and self.app.keydown == K_ESCAPE:
            self.paused = True

    def move_camera(self, dt, x, y):
        self.scroll = Vector2(
            -round(
                ((x - SCREEN_WIDTH / 2) / 5 * dt)
                + (random.uniform(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
            -round(
                ((y - SCREEN_HEIGHT / 2) / 5 * dt)
                + (random.uniform(-self.shake, self.shake) if self.shake > 0 else 0)
            ),
        )

    def collide(self):
        for asteroid in self.asteroids:
            if not self.game_over:
                if self.player.sprite.hit_box.colliderect(asteroid.rect):
                    self.save_data()
                    self.player_explosion.play()
                    Explosion(self.explosions, self.player.sprite.hit_box.center, 10)
                    self.player.sprite.kill()
                    self.bullets.empty()
                    self.arrow.kill()
                    self.shake = SHAKE * 1.5
                    self.game_over = True
                    break

            if pygame.sprite.spritecollide(asteroid, self.bullets, True):
                self.asteroid_kill.play()
                added_points = SCORE * self.level * asteroid.scale
                self.score += added_points
                self.gained_points.add_point(
                    asteroid.rect.center, self.font, int(added_points)
                )
                asteroid.kill()
                Explosion(self.explosions, asteroid.rect.center, 5)
                self.shake = SHAKE
                break

            # Check for collisions between asteroids
            for asteroid2 in self.asteroids.copy():
                if (
                    asteroid != asteroid2
                    and pygame.sprite.collide_rect(asteroid, asteroid2)
                    and (
                        (
                            0 <= asteroid.rect.centerx <= SCREEN_WIDTH
                            and 0 <= asteroid.rect.centery <= SCREEN_HEIGHT
                        )
                        or (
                            0 <= asteroid2.rect.centerx <= SCREEN_WIDTH
                            and 0 <= asteroid2.rect.centery <= SCREEN_HEIGHT
                        )
                    )
                ):
                    self.asteroid_collision.play()
                    asteroid.kill()
                    asteroid2.kill()
                    Explosion(self.explosions, asteroid.rect.center, asteroid.scale)
                    Explosion(self.explosions, asteroid2.rect.center, asteroid2.scale)
                    self.shake = SHAKE / 2
                    break  # Exit the inner loop since each asteroid can only collide with one other asteroid

    def save_data(self):
        try:
            if self.score > self.app.highest_score:
                data = {"highest_score": int(self.score)}
                with open("data/user.json", "w") as f:
                    json.dump(data, f)
                self.app.load_data()

        except IOError as e:
            print(f"Error saving high score: {e}")

    def update(self, dt):
        super().update()

        if not self.paused:
            if not self.game_over:
                self.level += LEVEL_INCREASE_SPEED * dt
                self.score += self.level * dt

                # Music
                if pygame.mixer.music.get_volume() < 0.1:
                    self.music_volume += 0.001 * self.app.dt
                    pygame.mixer.music.set_volume(self.music_volume)

            # Camera
            try:
                self.player_x = self.player.sprite.rect.centerx
                self.player_y = self.player.sprite.rect.centery
            except AttributeError:
                self.player_x += self.scroll.x
                self.player_y += self.scroll.y
            self.move_camera(dt, self.player_x, self.player_y)

        if self.shake > 0:
            self.shake -= 1 * dt
        else:
            self.shake = 0

        # Collisions
        self.collide()
        self.app.glitch = self.shake / SHAKE + 0.05

        # Background
        self.app.screen.fill("black")
        self.particles.update(self.scroll, dt, 2, 0.1)
        self.particles.draw(self.screen)

        # Player
        try:
            if not self.paused:
                self.player.update(self.scroll, dt)
                self.bullets.update(self.scroll, dt)

            self.player.draw(self.screen)
            self.bullets.draw(self.screen)
        except AttributeError as e:
            # Handle the AttributeError
            print("AttributeError occurred:", e)
        except TypeError as e:
            # Handle the TypeError
            print("TypeError occurred:", e)
        except Exception as e:
            # Catch any other unexpected exceptions
            print("Unexpected exception occurred:", e)

        # Asteroids
        if not self.paused:
            self.explosions.update(self.scroll, dt)
            if time() - self.last_asteroid >= 1:
                if self.level <= MAX_LEVEL:
                    for _ in range(
                        random.randint(0, int(ASTEROID_SPAWN_INTERVAL * self.level))
                    ):
                        Asteroid(self.asteroids)
                        self.last_asteroid = time()
                else:
                    for _ in range(
                        random.randint(0, ASTEROID_SPAWN_INTERVAL * MAX_LEVEL)
                    ):
                        Asteroid(self.asteroids)
                        self.last_asteroid = time()
                    try:
                        self.player.sprite.velocity = (
                            PLAYER_VELOCITY * self.level / MAX_LEVEL
                        )
                    except AttributeError:
                        pass

            self.asteroids.update(self.scroll, dt)
        self.asteroids.draw(self.screen)
        self.explosions.draw(self.screen)
        self.gained_points.update(self.scroll, dt)
        self.gained_points.draw(self.screen)

        # UI
        level = self.font.render(f"Level: {self.level:.1f}", False, "white")
        self.screen.blit(level, level.get_frect(center=(SCREEN_WIDTH / 2, 30)))
        self.score_text.update(self.font, int(self.score))
        highest_score = self.s_font.render(
            f"Highest Score: {self.app.highest_score}", False, "white"
        )
        self.screen.blit(
            highest_score, highest_score.get_frect(center=(SCREEN_WIDTH / 2, 70))
        )
        try:
            self.arrow.update(self.player.sprite.target_angle)
        except AttributeError:
            pass
        self.ui.draw(self.screen)

        # Game states
        if self.paused:
            self.scroll = (0, 0)
            self.screen.blit(self.paused_text, self.paused_text_rect)
        if self.game_over:
            self.screen.blit(self.game_over_text1, (self.line1_x, self.line1_y))
            self.screen.blit(self.game_over_text2, (self.line2_x, self.line2_y))

        # Debugging
        # pygame.draw.rect(self.screen, "green", self.player.sprite.hit_box, 1)

        # onscreen_debug(self.screen, f"Bullets: {len(self.bullets.sprites())}", y=50)
        # onscreen_debug(
        #     self.screen,
        #     f"Cached rotations: {len(self.player.sprite.rotated_images)}",
        #     y=70,
        # )
        # onscreen_debug(self.screen, f"Asteroids: {len(self.asteroids.sprites())}", y=90)
        # onscreen_debug(self.screen, f"Level: {self.level:.2f}", y=110)


class GainedPoints(pygame.sprite.Group):
    def __init__(self):
        super().__init__()

    def add_point(self, pos, font: pygame.Font, points):
        text = font.render(f"+{points}", False, "green")
        rect = text.get_frect(midbottom=pos)
        sprite = pygame.sprite.Sprite(self)
        sprite.image = text
        sprite.rect = rect
        sprite.alpha = 255

    def update(self, scroll, dt):
        for sprite in self.sprites():
            if sprite.alpha <= 0:
                sprite.kill()
                continue
            sprite.rect.move_ip(scroll)
            sprite.alpha -= 5 * dt
            sprite.image.set_alpha(sprite.alpha)
