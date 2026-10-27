"""Builds the app's logo and launcher icon images in sand and bronze.

Usage: python3 tool/brand/make_logo.py
       then: dart run flutter_launcher_icons

One palette that sits well on all five themes: a warm sand background
with a soft glow behind the book, the arch and stand in deep bronze, and
the Mushaf in a darker parchment so it reads clearly against the sand.
Over the sand lies a faint lattice of eight-pointed stars and a soft
shadow under the stand; the arch carries a gold sheen. The shapes come
from assets/icons/app_icon_foreground.original.png (the first,
gold-and-white foreground), recoloured by brightness. Writes:
  assets/icons/app_icon_foreground.png  adaptive icon foreground
  assets/icons/app_icon_background.png  adaptive icon background
  assets/icons/app_icon.png             full launcher image
  assets/icons/app_logo.png             in-app logo, 512 px
  assets/icons/logo_editable.svg        the same logo in layers, to edit
"""
import os

import base64
import io
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ICONS = os.path.join(ROOT, 'assets/icons')


def rgb(hexa):
    return np.array([int(hexa[i:i + 2], 16) for i in (0, 2, 4)], dtype=float)


SAND_LIGHT, SAND_DARK = rgb('E9DCC0'), rgb('CDB58A')  # background, top-left to bottom-right
GLOW = 14.0                                          # added behind the book
BRONZE_DARK, BRONZE_LIGHT = rgb('5E401C'), rgb('946C33')  # arch and stand
BOOK_DARK, BOOK_LIGHT = rgb('7E6845'), rgb('CDB98F')      # the Mushaf's pages
PATTERN_ALPHA = 26     # the star lattice, out of 255
PATTERN_STEP = 1 / 8   # stars per side, as a fraction of the size
SHEEN = 70.0           # brightest added to the arch along its sheen
SHADOW_ALPHA = 90      # the shadow under the stand


def background(size):
    y, x = np.mgrid[0:size, 0:size] / (size - 1)
    out = SAND_LIGHT + (SAND_DARK - SAND_LIGHT) * ((x + y) / 2)[..., None]
    d = np.sqrt((x - 0.5) ** 2 + (y - 0.48) ** 2)
    out += (GLOW * np.clip(1 - d / 0.45, 0, 1) ** 2)[..., None]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), 'RGB')


def star_points(cx, cy, r):
    pts = []
    for i in range(16):
        rr = r if i % 2 == 0 else r * 0.72
        a = -math.pi / 2 + i * math.pi / 8
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return pts


def star_centres(size):
    step = size * PATTERN_STEP
    rows = int(size / step) + 2
    for row in range(-1, rows):
        for col in range(-1, rows):
            yield (col * step + (step / 2 if row % 2 else 0), row * step)


def pattern(size):
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    width = max(1, round(size / 256))
    colour = tuple(int(c) for c in BRONZE_DARK) + (PATTERN_ALPHA,)
    for cx, cy in star_centres(size):
        draw.polygon(star_points(cx, cy, size * PATTERN_STEP * 0.4),
                     outline=colour, width=width)
    return layer


def shadow(size):
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(
        [size * 0.29, size * 0.78, size * 0.71, size * 0.86],
        fill=(60, 40, 15, SHADOW_ALPHA))
    return layer.filter(ImageFilter.GaussianBlur(size / 50))


def foreground(original):
    """The gold parts become bronze with a sheen, the white pages
    parchment."""
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
    # A band of light across the gilded parts only, never the pages.
    n = a.shape[0]
    y, x = np.mgrid[0:n, 0:n] / n
    glint = (np.clip(1 - np.abs((x - y) + 0.15) / 0.35, 0, 1) * SHEEN)[..., None]
    a[..., :3] = np.where(gilded, a[..., :3] + glint * np.array([1.0, 0.85, 0.45]),
                          a[..., :3])
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')


def png_uri(image):
    buf = io.BytesIO()
    image.save(buf, 'PNG')
    return 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode()


def editable_svg(fg, size=1024):
    """The logo in named layers: the background, glow, stars and shadow
    are vectors with editable colours; the arch and book stay a picture."""
    def hexa(c):
        return '#%02X%02X%02X' % tuple(int(v) for v in c)
    stars = '\n'.join(
        '      <polygon points="%s"/>' % ' '.join(
            '%.1f,%.1f' % p for p in star_points(cx, cy, size * PATTERN_STEP * 0.4))
        for cx, cy in star_centres(size))
    art = png_uri(fg.resize((size, size), Image.LANCZOS))
    return f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" width="{size}" height="{size}" viewBox="0 0 {size} {size}">
  <defs>
    <linearGradient id="sand" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{hexa(SAND_LIGHT)}"/>
      <stop offset="1" stop-color="{hexa(SAND_DARK)}"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.48" r="0.45">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="{GLOW / 255:.3f}"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <filter id="soft"><feGaussianBlur stdDeviation="{size / 50:.1f}"/></filter>
    <clipPath id="tile"><rect width="{size}" height="{size}" rx="{size * 0.22:.0f}"/></clipPath>
  </defs>
  <g clip-path="url(#tile)">
    <g id="background" inkscape:groupmode="layer" inkscape:label="background">
      <rect width="{size}" height="{size}" fill="url(#sand)"/>
      <rect width="{size}" height="{size}" fill="url(#glow)"/>
    </g>
    <g id="stars" inkscape:groupmode="layer" inkscape:label="stars" fill="none" stroke="{hexa(BRONZE_DARK)}" stroke-opacity="{PATTERN_ALPHA / 255:.3f}" stroke-width="{max(1, size / 256):.1f}">
{stars}
    </g>
    <g id="shadow" inkscape:groupmode="layer" inkscape:label="shadow">
      <ellipse cx="{size / 2:.0f}" cy="{size * 0.82:.0f}" rx="{size * 0.21:.0f}" ry="{size * 0.04:.0f}" fill="#3C280F" fill-opacity="{SHADOW_ALPHA / 255:.3f}" filter="url(#soft)"/>
    </g>
    <g id="arch-and-book" inkscape:groupmode="layer" inkscape:label="arch and book">
      <image width="{size}" height="{size}" xlink:href="{art}"/>
    </g>
  </g>
</svg>
'''


def main():
    original = Image.open(
        os.path.join(ICONS, 'app_icon_foreground.original.png')).convert('RGBA')
    art = foreground(original)
    size = art.width
    # The shadow travels with the arch and book: launchers shrink the
    # foreground layer into their mask but not the background, so a
    # shadow left behind would sit far below the stand.
    fg = shadow(size)
    fg.alpha_composite(art)
    fg.save(os.path.join(ICONS, 'app_icon_foreground.png'))
    bg = background(size).convert('RGBA')
    bg.alpha_composite(pattern(size))
    bg.convert('RGB').save(os.path.join(ICONS, 'app_icon_background.png'))
    full = bg.copy()
    full.alpha_composite(fg)
    full.convert('RGB').save(os.path.join(ICONS, 'app_icon.png'))
    full.convert('RGB').resize((512, 512), Image.LANCZOS).save(
        os.path.join(ICONS, 'app_logo.png'))
    with open(os.path.join(ICONS, 'logo_editable.svg'), 'w') as out:
        out.write(editable_svg(art))


if __name__ == '__main__':
    main()
