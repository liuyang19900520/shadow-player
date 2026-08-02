"""Generate the ShadowPlayer app icon.

Minimalist concept: a white "play" triangle wrapped by a circular loop arrow
(the A-B repeat motif) on an indigo -> violet gradient. Drawn at 4x and
downscaled with LANCZOS for crisp anti-aliasing.
"""

import math
from PIL import Image, ImageDraw

SIZE = 1024
SS = 4                      # supersampling factor
S = SIZE * SS              # working resolution
C = S // 2                 # center

TOP = (99, 102, 241)       # #6366F1 indigo
BOTTOM = (139, 92, 246)    # #8B5CF6 violet
GLYPH = (255, 255, 255, 255)


def gradient(size: int) -> Image.Image:
    """Vertical top->bottom gradient."""
    base = Image.new("RGB", (1, size))
    px = base.load()
    for y in range(size):
        t = y / (size - 1)
        px[0, y] = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
    return base.resize((size, size))


def draw_loop(draw: ImageDraw.ImageDraw) -> None:
    """A near-full circular arrow suggesting repeat/loop."""
    r = int(S * 0.30)
    width = int(S * 0.055)
    box = [C - r, C - r, C + r, C + r]

    # Arc leaves a gap at the top-right where the arrowhead sits.
    start, end = 300, 210          # clockwise 300 -> 360 -> 210 (~270 deg)
    draw.arc(box, start, end, fill=GLYPH, width=width)

    # Arrowhead at the `start` end (top-right), pointing along the tangent.
    a = math.radians(start)
    tip = (C + r * math.cos(a), C + r * math.sin(a))
    # tangent (clockwise travel) direction at this point
    tang = a - math.pi / 2
    head = width * 1.9
    back = (tip[0] - head * math.cos(tang), tip[1] - head * math.sin(tang))
    perp = tang + math.pi / 2
    w = width * 1.15
    p1 = (back[0] + w * math.cos(perp), back[1] + w * math.sin(perp))
    p2 = (back[0] - w * math.cos(perp), back[1] - w * math.sin(perp))
    fwd = (tip[0] + width * 0.9 * math.cos(tang), tip[1] + width * 0.9 * math.sin(tang))
    draw.polygon([fwd, p1, p2], fill=GLYPH)


def draw_play(draw: ImageDraw.ImageDraw) -> None:
    """Rounded-ish play triangle centered inside the loop."""
    h = int(S * 0.165)         # half height
    left = C - int(S * 0.075)
    right = C + int(S * 0.115)
    draw.polygon([(left, C - h), (left, C + h), (right, C)], fill=GLYPH)


def main() -> None:
    img = gradient(S).convert("RGBA")
    overlay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw_loop(draw)
    draw_play(draw)
    img = Image.alpha_composite(img, overlay).convert("RGB")
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    out = "scripts/icon-1024.png"
    img.save(out)
    print("wrote", out)


if __name__ == "__main__":
    main()
