import sys
from array import array
from time import time
import pygame
from pygame.math import Vector2
from pygame.locals import *
import moderngl

from classes.state import State
from states.main_menu import MainMenu
from utils import save_data, load_data

from globals import (
    APP_NAME,
    SCREEN_WIDTH,
    SCREEN_HEIGHT,
    DISPLAY_SCALE,
    FPS,
    VERTEX_SHADER,
    FRAGMENT_SHADER,
    IMGS_DIR,
    DEFAULT_FONT,
    GLITCH_AMOUNT,
)


class App:
    def __init__(self):
        # Pygame Initialize
        pygame.mixer.pre_init()
        pygame.init()
        pygame.display.set_caption(APP_NAME)
        pygame.display.set_icon(pygame.image.load(IMGS_DIR + "icon.png"))

        # User data with simplified loading
        data = load_data() or {}
        self.highest_score: int = data.get("highest_score", 0)
        self.fullscreen: bool = data.get("fullscreen", False)

        self.clock = pygame.time.Clock()
        self.font = pygame.Font(DEFAULT_FONT)

        # Screen setup
        self.screen_size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
        self.screen = pygame.Surface(self.screen_size, depth=32)
        self.display_size = Vector2(self.screen_size * DISPLAY_SCALE)

        flags = OPENGL | OPENGLBLIT | DOUBLEBUF | HWSURFACE
        if self.fullscreen:
            self.display = pygame.display.set_mode((0, 0), FULLSCREEN | flags)
            self.display_size = pygame.display.get_window_size()
        else:
            self.display = pygame.display.set_mode(self.display_size, flags)

        # Shaders initialization
        self.glitch = GLITCH_AMOUNT
        with open(f"shaders\\{VERTEX_SHADER}.vert", "r") as f:
            self.vertex_shader = f.read()
        with open(f"shaders\\{FRAGMENT_SHADER}.frag", "r") as f:
            fragment_shader = f.read()
        self.shaders_init(self.vertex_shader, fragment_shader)

        # Reusable texture for rendering
        self.frame_tex = self.ctx.texture(self.screen.get_size(), 4)
        self.frame_tex.filter = (moderngl.NEAREST, moderngl.NEAREST)
        self.frame_tex.swizzle = "BGRA"

        # Time management
        self.last_frame = time()
        self.elapsed_time = 0.0
        self.time_speed = 60
        self.dt = 1.0

        # Cursor setup (pre-scaled image)
        cursor_img = pygame.image.load(IMGS_DIR + "cursors\\crosshair.png")
        self.cursor = pygame.Cursor(
            (cursor_img.get_width() // 2 + 1, cursor_img.get_height() // 2 + 1),
            pygame.transform.scale_by(cursor_img, 2),
        )
        pygame.mouse.set_cursor(self.cursor)

        # Input handling
        self.keydown = None
        self.mousebuttondown = None
        self.running = True

        # Game states
        self.state_stack: list[State] = []
        MainMenu(self).add()

        # FPS text initialization
        self.last_fps = 0
        self.fps_surface = self.font.render(
            "0", False, "white"
        )  # Initial valid surface

    def handle_events(self):
        self.keydown = None
        self.mousebuttondown = None

        for event in pygame.event.get():
            if event.type == QUIT:
                self.quit()

            if event.type == KEYDOWN:
                self.keydown = event.key
                if event.key == K_F11:
                    self.toggle_fullscreen()

            if event.type == MOUSEBUTTONDOWN:
                self.mousebuttondown = event.button

    def toggle_fullscreen(self):
        self.fullscreen = not self.fullscreen
        flags = OPENGL | OPENGLBLIT | DOUBLEBUF | HWSURFACE

        if self.fullscreen:
            self.display = pygame.display.set_mode((0, 0), FULLSCREEN | flags)
            self.display_size = Vector2(pygame.display.get_window_size())
        else:
            self.display_size = Vector2(self.screen_size * DISPLAY_SCALE)
            self.display = pygame.display.set_mode(self.display_size, flags)

        # Update viewport for ModernGL
        self.ctx.viewport = (0, 0, int(self.display_size.x), int(self.display_size.y))

    def quit(self):
        save_data(
            {
                "highest_score": int(self.highest_score),
                "fullscreen": self.fullscreen,
            }
        )
        self.running = False

    def shaders_init(self, vertex_shader, fragment_shader):
        self.ctx = moderngl.create_context()
        quad_buffer = self.ctx.buffer(
            array(
                "f",
                [
                    -1.0,
                    1.0,
                    0.0,
                    0.0,  # topleft
                    1.0,
                    1.0,
                    1.0,
                    0.0,  # topright
                    -1.0,
                    -1.0,
                    0.0,
                    1.0,  # bottomleft
                    1.0,
                    -1.0,
                    1.0,
                    1.0,  # bottomright
                ],
            )
        )

        self.program = self.ctx.program(
            vertex_shader=vertex_shader, fragment_shader=fragment_shader
        )
        self.renderer = self.ctx.vertex_array(
            self.program, [(quad_buffer, "2f 2f", "vert", "texCoord")]
        )

    def render(self):
        # Update FPS display
        fps = int(self.clock.get_fps())
        if fps != self.last_fps:
            self.fps_surface = self.font.render(str(fps), False, "white")
            self.last_fps = fps

        # Blit FPS to screen
        self.screen.blit(self.fps_surface, (10, 10))

        # Update texture and render
        self.frame_tex.write(self.screen.get_view("1"))
        self.frame_tex.use(0)
        self.program["tex"] = 0

        # Uniform updates
        uniforms = {
            "u_resolution": self.display_size,
            "u_time": self.elapsed_time,
            "u_mouse": pygame.mouse.get_pos(),
            "glitch_intensity": self.glitch,
        }
        for name, value in uniforms.items():
            if name in self.program:
                self.program[name] = value

        self.renderer.render(moderngl.TRIANGLE_STRIP)
        pygame.display.flip()

    def get_dt(self):
        now = time()
        dt = now - self.last_frame
        self.last_frame = now
        return dt * self.time_speed

    def game_loop(self):
        self.dt = self.get_dt()
        self.time_speed = min(self.time_speed + 2 * self.dt, 60)
        self.elapsed_time += self.dt * 60

        self.handle_events()
        self.state_stack[-1].update(self.dt)
        self.render()
        self.clock.tick(FPS)

    def run(self):
        while self.running:
            self.game_loop()
        pygame.quit()
        sys.exit()
