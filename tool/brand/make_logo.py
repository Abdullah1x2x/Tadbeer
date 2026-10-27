"""Builds the app's charcoal logo and launcher icon images.

Usage: python3 tool/brand/make_logo.py
       then: dart run flutter_launcher_icons

Draws a charcoal diagonal gradient with a soft glow behind the book, and
lays the unchanged foreground (gold arch and white book,
assets/icons/app_icon_foreground.png) over it. Writes:
  assets/icons/app_icon_background.png  adaptive icon background
  assets/icons/app_icon.png             full launcher image
  assets/icons/app_logo.png             in-app logo, 512 px
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ICONS = os.path.join(ROOT, 'assets/icons')

LIGHT = np.array([0x3A, 0x38, 0x35], dtype=float)  # top-left
DARK = np.array([0x16, 0x15, 0x14], dtype=float)   # bottom-right
GLOW = 16.0                                         # added at the centre


def background(size):
    y, x = np.mgrid[0:size, 0:size] / (size - 1)
    t = ((x + y) / 2)[..., None]
    rgb = LIGHT + (DARK - LIGHT) * t
    d = np.sqrt((x - 0.5) ** 2 + (y - 0.48) ** 2)
    rgb += (GLOW * np.clip(1 - d / 0.45, 0, 1) ** 2)[..., None]
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), 'RGB')


def main():
    fg = Image.open(os.path.join(ICONS, 'app_icon_foreground.png')).convert('RGBA')
    size = fg.width
    bg = background(size)
    bg.save(os.path.join(ICONS, 'app_icon_background.png'))
    full = bg.convert('RGBA')
    full.alpha_composite(fg)
    full.convert('RGB').save(os.path.join(ICONS, 'app_icon.png'))
    full.convert('RGB').resize((512, 512), Image.LANCZOS).save(
        os.path.join(ICONS, 'app_logo.png'))


if __name__ == '__main__':
    main()
