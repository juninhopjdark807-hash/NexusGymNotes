#!/usr/bin/env python3
"""Render tool/icons/spec.json as faithful Flutter-like preview.

Supersamples 4x to emulate antialiasing, draws the badge gradient/glow as in
MuscleBadge, and composes a sheet at REAL app sizes (42px and 28px) so the
preview matches what runs on device.
"""
import json
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = json.load(open(os.path.join(HERE, "spec.json"), encoding="utf-8"))
OUT = os.path.join(HERE, "preview.png")

SS = 4  # supersample factor
BG = (13, 13, 15, 255)
FILL2 = (35, 38, 43, 255)          # inactive C.surface2 = 0xFF23262B
FILL_A = (26, 22, 48, 255)         # active gradient inner
RING = (139, 124, 255, 255)        # active border 0xFF8B7CFF
INK = (238, 234, 255, 255)         # active icon 0xFFE8E4FF

TOP = ["peito", "costas", "pernas", "ombros", "biceps",
       "triceps", "abdomen", "gluteos", "posterior",
       "panturrilha", "cardio", "outros"]


def _bez(p0, p1, p2, p3=None, n=48):
    pts = []
    for i in range(n + 1):
        t = i / n
        if p3 is None:
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        else:
            x = ((1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0]
                 + 3 * (1 - t) * t ** 2 * p2[0] + t ** 3 * p3[0])
            y = ((1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1]
                 + 3 * (1 - t) * t ** 2 * p2[1] + t ** 3 * p3[1])
        pts.append((x, y))
    return pts


def polylines(prim):
    out = []
    for p in prim:
        t = p["t"]
        if t == "line":
            x1, y1, x2, y2 = p["p"]
            out.append([(x1, y1), (x2, y2)])
        elif t == "circle":
            cx, cy, r = p["p"]
            out.append([(cx + r * math.cos(i / 64 * 2 * math.pi),
                         cy + r * math.sin(i / 64 * 2 * math.pi))
                        for i in range(65)])
        elif t == "rrect":
            x, y, w, h, r = p["p"]
            seg = 10
            def arc(ax, ay, a0, a1):
                return [(ax + r * math.cos(a0 + (a1 - a0) * i / seg),
                         ay + r * math.sin(a0 + (a1 - a0) * i / seg))
                        for i in range(seg + 1)]
            pts = []
            pts += arc(x + r, y + r, math.pi, 1.5 * math.pi)
            pts += arc(x + w - r, y + r, 1.5 * math.pi, 2 * math.pi)
            pts += arc(x + w - r, y + h - r, 0, 0.5 * math.pi)
            pts += arc(x + r, y + h - r, 0.5 * math.pi, math.pi)
            out.append(pts)
        elif t == "path":
            d = p["d"]
            pts = [tuple(d[0][1:])]
            for cmd in d[1:]:
                cur = pts[-1]
                if cmd[0] == "L":
                    pts.append(tuple(cmd[1:]))
                elif cmd[0] == "Q":
                    pts += _bez(cur, tuple(cmd[1:3]), tuple(cmd[3:5]))[1:]
                elif cmd[0] == "C":
                    pts += _bez(cur, tuple(cmd[1:3]), tuple(cmd[3:5]),
                                tuple(cmd[5:7]))[1:]
            out.append(pts)
    return out


def draw_icon(name, icon_size, sw_screen):
    """Draw at SS scale, emulating Flutter's strokeWidth compensation.
    Returns an SS-resolution image; downscale happens in badge()."""
    size = int(round(icon_size * SS))
    img = Image.new("RGBA", (size + 2 * SS, size + 2 * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    scale = icon_size / 100.0 * SS
    off = SS
    width = max(1, int(round(sw_screen * SS)))
    for poly in polylines(SPEC[name]):
        pts = [(off + x * scale, off + y * scale) for x, y in poly]
        d.line(pts, fill=INK, width=width, joint="curve")
    return img


def badge(name, size, active=True):
    pad = 4
    total = (size + pad * 2) * SS
    img = Image.new("RGBA", (total, total), BG)
    d = ImageDraw.Draw(img)

    # Radial-ish gradient / fill
    if active:
        fill = Image.new("RGBA", (total, total), (0, 0, 0, 0))
        fd = ImageDraw.Draw(fill)
        fd.ellipse([0, 0, total, total], fill=(42, 36, 96, 255))
        fd.ellipse([total * 0.18, total * 0.18, total * 0.82, total * 0.82],
                   fill=(34, 30, 78, 255))
        fd.ellipse([total * 0.38, total * 0.38, total * 0.62, total * 0.62],
                   fill=(26, 22, 48, 255))
        img.paste(fill, (0, 0))
    else:
        d.ellipse([0, 0, total, total], fill=FILL2)

    # Glow (only active) — BoxShadow blur 12, spread 0.5
    glow = img.filter(ImageFilter.GaussianBlur(total * 0.055))
    if active:
        ring_layer = Image.new("RGBA", (total, total), (0, 0, 0, 0))
        rd = ImageDraw.Draw(ring_layer)
        rd.ellipse([total * 0.03, total * 0.03, total * 0.97, total * 0.97],
                   outline=(108, 92, 255, 120), width=int(total * 0.012))
        glow = Image.alpha_composite(
            glow.filter(ImageFilter.GaussianBlur(total * 0.06)), ring_layer)
    img = Image.alpha_composite(img, glow)

    d = ImageDraw.Draw(img)
    # border 1.6px @1x
    bw = int(round(1.6 * SS))
    d.ellipse([0, 0, total, total], outline=RING, width=bw)

    icon_size = size * 0.64
    sw = max(1.6, min(2.4, size * 0.055))
    ic = draw_icon(name, icon_size, sw)
    x = int(round((size - icon_size) / 2 + pad))
    img.alpha_composite(ic, (int(round(x * SS)), int(round(x * SS))))
    return img.resize((int(round(size + pad * 2)),
                       int(round(size + pad * 2))), Image.LANCZOS)


def main():
    font = None
    try:
        font = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 11)
    except Exception:
        font = ImageFont.load_default()

    labels = {
        "peito": "PEITO", "costas": "COSTAS", "pernas": "PERNAS",
        "ombros": "OMBROS", "biceps": "BÍCEPS", "triceps": "TRÍCEPS",
        "abdomen": "ABDÔMEN", "gluteos": "GLÚTEOS", "posterior": "POSTERIOR",
        "panturrilha": "PANTURRILHA", "cardio": "CARDIO", "outros": "OUTROS",
    }

    big = 84
    small = 56
    gap = 10
    label_h = 16
    cell = big + gap
    cols = 4
    rows = ((len(TOP) + cols - 1) // cols)

    w = pad = 12
    w = pad * 2 + cols * cell
    h = pad * 2 + rows * (big + label_h + gap)

    img = Image.new("RGBA", (w, h), BG)
    d = ImageDraw.Draw(img)

    for i, name in enumerate(TOP):
        col, row = i % cols, i // cols
        cx = pad + col * cell + cell // 2
        cy = pad + row * (big + label_h + gap) + big // 2
        b = badge(name, big)
        img.alpha_composite(b, (int(cx - b.width / 2), int(cy - b.height / 2)))
        d.text((cx, cy + big / 2 + 2), labels[name], font=font,
               fill=(220, 218, 232, 255), anchor="ma")

    # Second row: real 28px badge to verify legibility
    y2 = pad + rows * (big + label_h + gap) + 6
    x = pad + cell // 2
    for name in TOP:
        b = badge(name, 28, active=True)
        img.alpha_composite(b, (int(x - b.width / 2), int(y2)))
        d.text((x, y2 + 32), labels[name], font=font,
               fill=(160, 158, 175, 255), anchor="ma")
        x += cell

    img.convert("RGB").save(OUT)
    print("saved", OUT, img.size)


if __name__ == "__main__":
    main()
