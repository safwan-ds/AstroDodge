from array import array
import math
from time import time
import pygame
import moderngl

from states.title import Title
from debug import onscreen_debug

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
        self.screen_size = (SCREEN_WIDTH, SCREEN_HEIGHT)
        self.screen = pygame.Surface(self.screen_size, depth=32)
        # self.display_dimensions = SCREEN_WIDTH / SCREEN_HEIGHT
        self.display_size = (
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
        with open("shaders/vertex_shader.vert", "r") as f:
            self.vertex_shader = f.read()
        with open("shaders/post_processing.frag", "r") as f:
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

        # Game states
        self.state_stack = []
        Title(self).add()

    def handle_events(self):
        self.keys = {
            "esc": False,
            "shift": False,
            "space": False,
            "d": False,
            "a": False,
            "f3": False,
        }
        self.mouse_buttons = {1: False, 2: False, 3: False}

        for event in pygame.event.get():
            if event.type == QUIT:
                self.running = False

            if event.type == KEYDOWN:
                self.keys = {
                    "esc": event.key == K_ESCAPE,
                    "shift": event.key == K_LSHIFT,
                    "space": event.key == K_SPACE,
                    "d": event.key == K_d,
                    "a": event.key == K_a,
                    "f3": event.key == K_F3,
                }

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
                self.mouse_buttons[1] = event.button == 1
                self.mouse_buttons[2] = event.button == 2
                self.mouse_buttons[3] = event.button == 3

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

    def texture_to_surface(self, texture):
        texture_data = texture.read()
        surface = pygame.image.fromstring(texture_data, texture.size, "RGBA", True)
        surface.set_colorkey((0, 0, 0))
        return surface

    def get_dt(self):
        dt = time() - self.last_frame
        self.last_frame = time()
        return min(dt * 60, 1.5)

    def game_loop(self):
        self.dt = self.get_dt()
        self.elapsed_time += self.dt * 60

        self.handle_events()

        self.state_stack[-1].update(self.dt)

        fps = self.clock.get_fps()
        mouse_pos = pygame.mouse.get_pos()
        # onscreen_debug(
        #     self.screen,
        #     f"FPS: {fps:.2f} " + ("locked" if self.fps else "unlocked"),
        #     f_color="green" if fps >= FPS else "red",
        # )
        # onscreen_debug(self.screen, f"DT: {self.dt:.2f}", y=30)
        # onscreen_debug(self.screen, mouse_pos, y=150)

        frame_tex = self.surface_to_texture(self.screen)
        frame_tex.use()
        self.program["tex"] = 0
        # self.program["u_resolution"] = self.display_size
        # self.program["u_time"] = self.elapsed_time
        # self.program["u_mouse"] = mouse_pos
        self.renderer.render(moderngl.TRIANGLE_STRIP)

        pygame.display.flip()

        frame_tex.release()

        self.clock.tick(self.fps)

    def run(self):
        self.running = True
        while self.running:
            self.game_loop()

        pygame.quit()
        exit()
