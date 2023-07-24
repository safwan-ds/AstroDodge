from array import array
import json
import math
from time import time
import pygame
from pygame.math import Vector2
import moderngl

from states.main_menu import MainMenu
from utils import onscreen_debug, console_debug

from pygame.locals import *
from config import *


class App:
    def __init__(self):
        # Pygame Initialize
        pygame.mixer.pre_init()
        pygame.init()
        pygame.display.set_caption("AstroDodge")
        pygame.display.set_icon(pygame.image.load(IMGS_DIR + "icon.png"))

        self.clock = pygame.time.Clock()
        self.fps = FPS
        self.screen_size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
        self.screen = pygame.Surface(self.screen_size, depth=32)
        # self.display_dimensions = SCREEN_WIDTH / SCREEN_HEIGHT
        self.display_size = Vector2(
            self.screen_size[0] * DISPLAY_SCALE,
            self.screen_size[1] * DISPLAY_SCALE,
        )
        self.display = pygame.display.set_mode(
            self.display_size,
            OPENGL | OPENGLBLIT | DOUBLEBUF | HWSURFACE,
            32,
        )
        self.fullscreen = False

        # Shaders
        self.glitch = 0.1
        with open(f"shaders/{VERTEX_SHADER_NAME}.vert", "r") as f:
            self.vertex_shader = f.read()
        with open(f"shaders/{FRAGMENT_SHADER_NAME}.frag", "r") as f:
            fragment_shader = f.read()
        self.shaders_init(self.vertex_shader, fragment_shader)

        # DT
        self.last_frame = time()
        self.elapsed_time = 0.0

        # Cursor
        cursor_img = pygame.image.load(IMGS_DIR + "cursors/crosshair.png")
        cursor_img = pygame.transform.scale_by(cursor_img, 2)
        cursor = pygame.Cursor(
            (cursor_img.get_width() // 2 + 1, cursor_img.get_height() // 2 + 1),
            cursor_img,
        )
        pygame.mouse.set_cursor(cursor)

        # User data
        self.load_data()

        # Game states
        self.state_stack = []
        MainMenu(self).add()

    def handle_events(self):
        self.keydown = None
        self.mousebuttondown = None

        for event in pygame.event.get():
            if event.type == QUIT:
                self.running = False

            if event.type == KEYDOWN:
                self.keydown = event.key

                if event.key == K_F1:
                    self.fps = 0 if self.fps else FPS

                if event.key == K_F11:
                    if self.fullscreen:
                        self.display_size = (
                            self.screen_size[0] * DISPLAY_SCALE,
                            self.screen_size[1] * DISPLAY_SCALE,
                        )
                        self.display = pygame.display.set_mode(
                            self.display_size,
                            OPENGL | OPENGLBLIT | HWSURFACE | DOUBLEBUF | RESIZABLE,
                            32,
                        )
                        self.display = pygame.display.set_mode(
                            self.display_size,
                            OPENGL | OPENGLBLIT | HWSURFACE | DOUBLEBUF,
                            32,
                        )
                        self.fullscreen = False
                    else:
                        self.display = pygame.display.set_mode(
                            flags=FULLSCREEN
                            | OPENGL
                            | OPENGLBLIT
                            | HWSURFACE
                            | DOUBLEBUF
                            | RESIZABLE,
                            depth=32,
                        )
                        self.display_size = pygame.display.get_window_size()
                        self.fullscreen = True

            if event.type == MOUSEBUTTONDOWN:
                self.mousebuttondown = event.button

    def load_data(self):
        try:
            with open("data/user.json") as f:
                data = json.load(f)
                self.highest_score = data.get("highest_score", 0)
        except (IOError, json.JSONDecodeError):
            self.highest_score = 0

    def shaders_init(self, vertex_shader, fragment_shader):
        self.ctx = moderngl.create_context()
        quad_buffer = self.ctx.buffer(
            array(
                "f",
                # fmt: off
                [
                    -1.0, 1.0, 0.0, 0.0,  # topleft
                    1.0, 1.0, 1.0, 0.0,  # topright
                    -1.0, -1.0, 0.0, 1.0,  # bottomleft
                    1.0, -1.0, 1.0, 1.0,  # bottomright
                ],
                # fmt: on
            )  # Position(x, y), UV(x, y)
        )

        self.program = self.ctx.program(
            vertex_shader=vertex_shader, fragment_shader=fragment_shader
        )
        self.renderer = self.ctx.vertex_array(
            self.program, [(quad_buffer, "2f 2f", "vert", "texCoord")]
        )

    def surface_to_texture(self, surface: pygame.Surface):
        texture = self.ctx.texture(surface.get_size(), 4)
        texture.filter = (moderngl.NEAREST, moderngl.NEAREST)
        texture.swizzle = "BGRA"
        texture.write(surface.get_view("1"))
        return texture

    def get_dt(self):
        dt = time() - self.last_frame
        self.last_frame = time()
        return min(dt * 60, 1.5)

    def render(self):
        mouse_pos = pygame.mouse.get_pos()
        # onscreen_debug(self.screen, mouse_pos, y=210)
        frame_tex = self.surface_to_texture(self.screen)
        frame_tex.use()
        self.program["tex"] = 0

        uniform_values = {
            "u_resolution": self.display_size,
            "u_time": self.elapsed_time,
            "u_mouse": mouse_pos,
            "glitch_intensity": self.glitch,
        }

        for uniform_name, value in uniform_values.items():
            try:
                self.program[uniform_name] = value
            except KeyError:
                pass

        self.renderer.render(moderngl.TRIANGLE_STRIP)
        pygame.display.flip()
        frame_tex.release()

    def game_loop(self):
        self.dt = self.get_dt()
        self.elapsed_time += self.dt * 60

        self.handle_events()

        self.state_stack[-1].update(self.dt)

        fps = self.clock.get_fps()

        # console_debug(f"FPS: {fps:.2f} " + ("locked" if self.fps else "unlocked"))
        # onscreen_debug(self.screen, f"DT: {self.dt:.2f}", y=30)
        pygame.display.set_caption(f"AstroDodge || FPS: {fps:.2f}")

        self.render()

        self.clock.tick(self.fps)

    def run(self):
        self.running = True
        while self.running:
            self.game_loop()

        pygame.quit()
        exit()
