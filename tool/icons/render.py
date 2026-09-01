#!/usr/bin/env python3
"""Render tool/icons/spec.json as REAL app sizes (42px home, 28px lists).

Rows: 96px design check -> 42px (home) -> 28px (lists), all rendered with
the same pipeline as Flutter (supersampled, then downscaled).
"""
import json
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = json.load(open(os.path.join(HERE, "spec.json"), encoding="utf-8"))
OUT = os.path.join(HERE, "preview.png")

SS = 4
BG = (13, 13, 15, 255)
FILL_A = (26, 22, 48, 255)
FILL_I = (35, 38, 43, 255)
RING = (139, 124, 255, 255)
INK = (238, 234, 255, 255)

GROUPS = ["peito", "costas", "pernas", "ombros", "biceps", "triceps",
          "abdomen", "gluteos", "posterior", "panturrilha", "lombar",
          "antebraco", "trapezio", "pescoco", "cardio", "outros"]
LABELS = {
    "peito": "PEITO", "costas": "COSTAS", "pernas": "PERNAS",
    "ombros": "OMBROS", "biceps": "BÍCEPS", "triceps": "TRÍCEPS",
    "abdomen": "ABDÔMEN", "gluteos": "GLÚTEOS", "posterior": "POSTERIOR",
    "panturrilha": "PANTURRILHA", "lombar": "LOMBAR",
    "antebraco": "ANTEBRAÇO", "trapezio": "TRAPÉZIO", "pescoco": "PESCOÇO",
    "cardio": "CARDIO", "outros": "OUTROS",
}


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
    if active:
        fill = Image.new("RGBA", (total, total), (0, 0, 0, 0))
        fd = ImageDraw.Draw(fill)
        fd.ellipse([0, 0, total, total], fill=(42, 36, 96, 255))
        fd.ellipse([total * 0.2, total * 0.2, total * 0.8, total * 0.8],
                   fill=(34, 30, 78, 255))
        fd.ellipse([total * 0.4, total * 0.4, total * 0.6, total * 0.6],
                   fill=FILL_A)
        img.paste(fill, (0, 0))
    else:
        d.ellipse([0, 0, total, total], fill=FILL_I)

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
    bw = int(round(1.6 * SS))
    d.ellipse([0, 0, total, total], outline=RING, width=bw)

    icon_size = size * 0.72
    sw = max(2.0, min(2.8, size * 0.09))
    ic = draw_icon(name, icon_size, sw)
    x = int(round((size - icon_size) / 2 + pad))
    img.alpha_composite(ic, (int(round(x * SS)), int(round(x * SS))))
    return img.resize((int(round(size + pad * 2)),
                       int(round(size + pad * 2))), Image.LANCZOS)


def main():
    font = ImageFont.truetype(
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 11)
    cols = 4
    pad = 16

    rows = [(96, "96px — detalhe do desenho"),
            (42, "42px — home (tamanho real no aparelho)"),
            (28, "28px — listas (tamanho real no aparelho)")]

    cell = max(96, 42, 28) + 42
    gap = 20
    W = pad * 2 + cols * cell + (cols - 1) * gap
    H = pad
    sections = []
    for size, title in rows:
        nrows = (len(GROUPS) + cols - 1) // cols
        h = 20 + nrows * (size + 40) + 24
        sections.append((size, title, h))
        H += h
    H += pad

    img = Image.new("RGBA", (W, H), BG)
    d = ImageDraw.Draw(img)
    y = pad
    for size, title, h in sections:
        d.text((pad, y + 2), title, font=font, fill=(160, 158, 175, 255))
        yy = y + 22
        for i, name in enumerate(GROUPS):
            col, row = i % cols, i // cols
            cx = pad + col * cell + cell // 2
            cy = yy + row * (size + 40) + size // 2
            b = badge(name, size)
            img.alpha_composite(b, (int(cx - b.width / 2), int(cy - b.height / 2)))
            d.text((cx, cy + size / 2 + 5), LABELS[name], font=font,
                   fill=(214, 212, 228), anchor="ma")
        y += h

    img.convert("RGB").save(OUT)
    print("saved", OUT, img.size)


if __name__ == "__main__":
    main()
