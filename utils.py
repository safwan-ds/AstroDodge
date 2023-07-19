import os
import pygame

from config import *


def import_sprite_sheets(path):
    files = os.listdir(path)
    sprite_sheets: dict[str, pygame.Surface] = {}

    for file in files:
        if file.endswith(".png"):
            sprite_sheets[file[:-4]] = pygame.image.load(os.path.join(path, file))

    return sprite_sheets


def extract_sprites(sprite_sheets: dict[str, pygame.Surface], tile_width):
    sprites: dict[str, list[pygame.Surface]] = {}
    for sprite_sheet in sprite_sheets.keys():
        sprites[sprite_sheet] = []

        sheet_width = sprite_sheets[sprite_sheet].get_width()
        sheet_height = sprite_sheets[sprite_sheet].get_height()

        for x in range(0, sheet_width, tile_width):
            sprite_rect = pygame.FRect(x, 0, tile_width, sheet_height)

            try:
                sprites[sprite_sheet].append(
                    pygame.transform.scale(
                        sprite_sheets[sprite_sheet].subsurface(sprite_rect),
                        (tile_width, sheet_height),
                    )
                )
            except ValueError:
                continue

    return sprites


def get_animations(path, tile_width):
    sprite_sheets = import_sprite_sheets(path)
    animations = extract_sprites(sprite_sheets, tile_width)
    return animations


def extract_parallax(path, tile_height, base_tile_bottom):
    layers: list[list[pygame.Surface, pygame.FRect]] = []
    image = pygame.image.load(path)
    width = image.get_width()
    height = image.get_height()

    for y in range(0, height, tile_height):
        rect = pygame.FRect(0, y, width, tile_height)

        try:
            layer = pygame.transform.scale_by(image.subsurface(rect), 2)
            layers.append(
                [
                    layer,
                    layer.get_frect(bottomleft=(0, base_tile_bottom)),
                ]
            )
        except ValueError:
            continue

    return layers
