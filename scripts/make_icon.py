"""Generate the ShadowPlayer app icon.

Minimalist concept: a "play" triangle wrapped by a circular loop arrow (the A-B
repeat motif), rendered in a flowing water-cyan gradient on a deep blue -> black
background. A few faint ripples at the bottom quietly evoke gentle water (Gui
water). Drawn at 4x and downscaled with LANCZOS for crisp anti-aliasing.
"""

import math
from PIL import Image, ImageDraw

SIZE = 1024
SS = 4                      # supersampling factor
S = SIZE * SS              # working resolution
C = S // 2                 # center

# Background: deep blue -> near-black (the color of the Water element).
BG_TOP = (12, 35, 80)      # #0C2350 deep blue
BG_BOTTOM = (4, 8, 18)     # #040812 near-black

# Glyph: luminous water-cyan gradient (flowing water).
GLYPH_TOP = (150, 233, 255)     # #96E9FF pale aqua
GLYPH_BOTTOM = (56, 149, 240)   # #3895F0 water blue

RIPPLE = (150, 233, 255)   # faint cyan ripples


def vgradient(size: int, top, bottom) -> Image.Image:
    """Vertical top->bottom gradient (RGB)."""
    base = Image.new("RGB", (1, size))
    px = base.load()
    for y in range(size):
        t = y / (size - 1)
        px[0, y] = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    return base.resize((size, size))


def glyph_mask() -> Image.Image:
    """White (255) mask of the loop arrow + play triangle on black."""
    mask = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(mask)

    # Loop arrow.
    r = int(S * 0.30)
    width = int(S * 0.052)
    box = [C - r, C - r, C + r, C + r]
    start, end = 300, 210          # clockwise 300 -> 360 -> 210 (~270 deg)
    d.arc(box, start, end, fill=255, width=width)

    # Arrowhead at the `start` end, along the tangent.
    a = math.radians(start)
    tip = (C + r * math.cos(a), C + r * math.sin(a))
    tang = a - math.pi / 2
    head = width * 1.9
    back = (tip[0] - head * math.cos(tang), tip[1] - head * math.sin(tang))
    perp = tang + math.pi / 2
    w = width * 1.15
    p1 = (back[0] + w * math.cos(perp), back[1] + w * math.sin(perp))
    p2 = (back[0] - w * math.cos(perp), back[1] - w * math.sin(perp))
    fwd = (tip[0] + width * 0.9 * math.cos(tang), tip[1] + width * 0.9 * math.sin(tang))
    d.polygon([fwd, p1, p2], fill=255)

    # Play triangle.
    h = int(S * 0.165)
    left = C - int(S * 0.075)
    right = C + int(S * 0.115)
    d.polygon([(left, C - h), (left, C + h), (right, C)], fill=255)
    return mask


def draw_ripples(img: Image.Image) -> None:
    """A few faint, shallow arcs across the lower area, like water ripples."""
    overlay = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    cx, cy = C, int(S * 1.18)              # center below the canvas -> shallow curves
    width = int(S * 0.008)
    for i, (radius_f, alpha) in enumerate([(0.62, 46), (0.72, 34), (0.82, 24)]):
        rr = int(S * radius_f)
        box = [cx - rr, cy - rr, cx + rr, cy + rr]
        d.arc(box, 232, 308, fill=RIPPLE + (alpha,), width=width)
    img.alpha_composite(overlay)


def main() -> None:
    img = vgradient(S, BG_TOP, BG_BOTTOM).convert("RGBA")
    draw_ripples(img)

    glyph = vgradient(S, GLYPH_TOP, GLYPH_BOTTOM).convert("RGBA")
    glyph.putalpha(glyph_mask())
    img = Image.alpha_composite(img, glyph).convert("RGB")

    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    out = "scripts/icon-1024.png"
    img.save(out)
    print("wrote", out)


if __name__ == "__main__":
    main()
