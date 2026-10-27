"""Builds the app's logo and launcher icon images in sand and bronze.

Usage: python3 tool/brand/make_logo.py
       then: dart run flutter_launcher_icons

One palette that sits well on all five themes: a warm sand background
with a soft glow behind the book, the arch and stand in deep bronze, and
the Mushaf in a darker parchment so it reads clearly against the sand.
The shapes come from assets/icons/app_icon_foreground.original.png (the
first, gold-and-white foreground), recoloured by brightness. Writes:
  assets/icons/app_icon_foreground.png  adaptive icon foreground
  assets/icons/app_icon_background.png  adaptive icon background
  assets/icons/app_icon.png             full launcher image
  assets/icons/app_logo.png             in-app logo, 512 px
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ICONS = os.path.join(ROOT, 'assets/icons')


def rgb(hexa):
    return np.array([int(hexa[i:i + 2], 16) for i in (0, 2, 4)], dtype=float)


SAND_LIGHT, SAND_DARK = rgb('E9DCC0'), rgb('CDB58A')  # background, top-left to bottom-right
GLOW = 14.0                                          # added behind the book
BRONZE_DARK, BRONZE_LIGHT = rgb('5E401C'), rgb('946C33')  # arch and stand
BOOK_DARK, BOOK_LIGHT = rgb('7E6845'), rgb('CDB98F')      # the Mushaf's pages


def background(size):
    y, x = np.mgrid[0:size, 0:size] / (size - 1)
    out = SAND_LIGHT + (SAND_DARK - SAND_LIGHT) * ((x + y) / 2)[..., None]
    d = np.sqrt((x - 0.5) ** 2 + (y - 0.48) ** 2)
    out += (GLOW * np.clip(1 - d / 0.45, 0, 1) ** 2)[..., None]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), 'RGB')


def foreground(original):
    """The gold parts become bronze, the white pages parchment."""
    a = np.array(original).astype(float)
    colour = a[..., :3]
    top, low = colour.max(2), colour.min(2)
    saturation = np.where(top > 0, (top - low) / np.maximum(top, 1), 0)
    value = top / 255
    gilded = (saturation > 0.22)[..., None]
    t_arch = np.clip((value - 0.35) / 0.6, 0, 1)[..., None]
    t_book = np.clip((value - 0.55) / 0.45, 0, 1)[..., None]
    a[..., :3] = np.where(
        gilded,
        BRONZE_DARK + (BRONZE_LIGHT - BRONZE_DARK) * t_arch,
        BOOK_DARK + (BOOK_LIGHT - BOOK_DARK) * t_book,
    )
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')


def main():
    original = Image.open(
        os.path.join(ICONS, 'app_icon_foreground.original.png')).convert('RGBA')
    fg = foreground(original)
    fg.save(os.path.join(ICONS, 'app_icon_foreground.png'))
    bg = background(fg.width)
    bg.save(os.path.join(ICONS, 'app_icon_background.png'))
    full = bg.convert('RGBA')
    full.alpha_composite(fg)
    full.convert('RGB').save(os.path.join(ICONS, 'app_icon.png'))
    full.convert('RGB').resize((512, 512), Image.LANCZOS).save(
        os.path.join(ICONS, 'app_logo.png'))


if __name__ == '__main__':
    main()
