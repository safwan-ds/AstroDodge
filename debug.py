import pygame

from config import DEFAULT_FONT


def console_debug(
    info,
):
    print(info, end="\r")


pygame.font.init()
font = pygame.Font(DEFAULT_FONT, 20)


def onscreen_debug(
    surface,
    info,
    x=10,
    y=10,
    f_color="white",
    b_color="black",
    font=font,
):
    debug_surface = font.render(str(info), False, f_color)
    debug_rect = debug_surface.get_frect(topleft=(x, y))
    pygame.draw.rect(surface, b_color, debug_rect)
    surface.blit(debug_surface, debug_rect)
