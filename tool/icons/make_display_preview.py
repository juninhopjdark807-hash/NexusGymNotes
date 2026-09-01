#!/usr/bin/env python3
"""Prévia de validação visual (splash + header) — usa APENAS os assets reais:
- "icone" na splash (fundo dark, 200dp, sem círculo/moldura)
- "iconeinicio.png" como marca do header (estilo da UI final do Flutter)
Não é asset do app; é apenas referência para conferência.
"""

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ICONE = os.path.join(ROOT, "icone")
MARCA = os.path.join(ROOT, "iconeinicio.png")
OUT = os.path.join(ROOT, "tool/icons/display_preview.png")

SPLASH_BG = (11, 11, 13)          # #0B0B0D
APP_BG = (13, 13, 15)             # #0D0D0F
SURFACE2 = (35, 38, 43)           # #23262B
STROKE = (44, 48, 56)             # #2C3038
TEXT = (230, 230, 230)            # #E6E6E6
TEXT_DIM = (154, 154, 163)        # #9A9AA3
ACCENT = (108, 92, 255)           # #6C5CFF
ACCENT2 = (154, 140, 255)         # #9A8CFF

FONT_DISPLAY = os.path.join(ROOT, "assets/fonts/SpaceGrotesk.ttf")
FONT_BODY = os.path.join(ROOT, "assets/fonts/Inter.ttf")


def font(path, size, weight=None):
    try:
        f = ImageFont.truetype(path, size)
        if weight:
            try:
                f.set_variation_by_name(weight)
            except Exception:
                pass
        return f
    except Exception:
        return ImageFont.load_default()


def draw_text(d, xy, s, f, fill, spacing=0.0):
    if spacing <= 0:
        d.text(xy, s, font=f, fill=fill)
        return
    x, y = xy
    for ch in s:
        w = d.textlength(ch, font=f)
        d.text((x, y), ch, font=f, fill=fill)
        x += w + spacing


def radial_glow(size, color, radius=1.0):
    """Glow radial roxo discreto (para o mock do header)."""
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    steps = 48
    max_r = int(size / 2)
    for i in range(steps, 0, -1):
        r = int(max_r * i / steps)
        a = int(255 * 0.10 * (1 - i / steps) ** 1.6)
        gd.ellipse((size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r),
                   fill=color + (a,))
    return glow.filter(ImageFilter.GaussianBlur(size * 0.12))


def splash(scale=1.0):
    """Mock de tela de splash 390x760 com 'icone' em 200dp centralizado."""
    W, H = int(390 * scale), int(760 * scale)
    img = Image.new("RGB", (W, H), SPLASH_BG)
    icon = Image.open(ICONE).convert("RGBA").resize((int(200 * scale),) * 2, Image.LANCZOS)
    img.paste(icon, ((W - icon.width) // 2, (H - icon.height) // 2), icon)
    return img


def header(scale=2.0):
    """Mock do header final (mesma estrutura/tokens do Flutter) em APP_BG."""
    W, H = int(760 * scale), int(430 * scale)
    img = Image.new("RGB", (W, H), APP_BG)
    d = ImageDraw.Draw(img, "RGBA")

    # glow roxo discreto (topo direito) + anel sutil (inferior esquerdo)
    g = radial_glow(int(460 * scale), ACCENT)
    img.paste(g, (W - g.width + int(60 * scale), -int(110 * scale)), g)
    ring = Image.new("RGBA", (int(380 * scale),) * 2, (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse((0, 0, ring.width - 2, ring.height - 2),
               outline=ACCENT + (16,), width=max(2, int(2.4 * scale)))
    img.paste(ring, (-int(150 * scale), H - int(180 * scale)), ring)

    pad_l = int(24 * scale)
    pad_t = int(22 * scale)
    mark = Image.open(MARCA).resize((int(31 * scale),) * 2, Image.LANCZOS).convert("RGBA")
    # baseline mark / texto (centro vertical) — alinhados como no Flutter
    logo_font = font(FONT_DISPLAY, int(27 * scale), "Bold")
    y_logo_top = pad_t
    mark_y = y_logo_top + int((27 * scale) * 0.5) - mark.height // 2
    img.paste(mark, (pad_l, mark_y), mark)
    x = pad_l + mark.width + int(9 * scale)
    draw_text(d, (x, y_logo_top), "NEXUS", logo_font, TEXT, spacing=2.0 * scale)
    x += int(d.textlength("NEXUS", font=logo_font) + 2.0 * scale * max(0, len("NEXUS") - 1))
    # espaço explícito entre NEXUS e GYM (como no TextSpan ' GYM')
    x += int(d.textlength(" ", font=logo_font)) + 2.0 * scale
    gym_font = font(FONT_DISPLAY, int(27 * scale), "SemiBold")
    draw_text(d, (x, y_logo_top), "GYM", gym_font, ACCENT, spacing=2.0 * scale)

    # tagline
    tag_font = font(FONT_BODY, int(12.5 * scale), "Medium")
    tag_y = y_logo_top + int(27 * scale) + int(7 * scale)
    d.text((pad_l, tag_y), "Seu treino. Seu progresso.", font=tag_font, fill=TEXT_DIM)

    # badge de data (direita)
    b_font = font(FONT_BODY, int(10.5 * scale), "Bold")
    label = "TER · 1 SET"
    b_w = int(d.textlength(label, font=b_font) + 14 * scale + 6 * scale + 20 * scale + 20 * scale)
    b_h = int(31 * scale)
    b_x = W - pad_l - b_w
    b_y = pad_t + int(2 * scale)
    d.rounded_rectangle((b_x, b_y, b_x + b_w, b_y + b_h), radius=int(10 * scale),
                        fill=SURFACE2, outline=STROKE, width=int(1.2 * scale))
    # ícone calendário simples
    ci = int(14 * scale)
    cx, cy = b_x + int(12 * scale), b_y + (b_h - ci) // 2
    d.rounded_rectangle((cx, cy, cx + ci, cy + ci), radius=int(3 * scale),
                        outline=ACCENT2, width=max(2, int(1.4 * scale)))
    d.line((cx + ci * 0.25, cy + ci * 0.35, cx + ci * 0.75, cy + ci * 0.35),
           fill=ACCENT2, width=max(2, int(1.4 * scale)))
    d.rounded_rectangle((cx + ci * 0.32, cy + ci * 0.42, cx + ci * 0.52, cy + ci * 0.58),
                        radius=int(1 * scale), fill=ACCENT2)
    d.text((b_x + int(30 * scale), b_y + (b_h - int(10.5 * scale)) // 2 - int(1 * scale)),
           label, font=b_font, fill=TEXT_DIM)

    # separador gradiente
    sep_y = H - int(172 * scale)
    sep_w = int(612 * scale)
    for i in range(int(sep_w * 2)):
        t = i / (sep_w * 2)
        a = int(255 * max(0.0, 1 - abs(t - 0.5) * 2) * 0.75) if False else int(255 * (0.0 if t < 0.02 else (0.75 if t < 0.5 else max(0.0, (1 - t) * 2)) * 1.0))
        col = STROKE + (a,)
        d.line((pad_l + i / 2, sep_y, pad_l + i / 2, sep_y), fill=col, width=1)

    # TREINOS + linha gradiente accent
    t_font = font(FONT_DISPLAY, int(22 * scale), "Bold")
    ty = H - int(128 * scale)
    d.text((pad_l, ty), "TREINOS", font=t_font, fill=TEXT)
    bar_x = pad_l + d.textlength("TREINOS", font=t_font) + int(10 * scale)
    bar_w = W - pad_l - bar_x - 0
    for i in range(int(bar_w * 2)):
        t = i / max(1, int(bar_w * 2))
        a = int(255 * 0.55 * max(0.0, 1 - t))
        col = ACCENT + (a,)
        d.line((bar_x + i / 2, ty + int(26 * scale), bar_x + i / 2, ty + int(29 * scale)), fill=col, width=1)

    return img


def main():
    splash_img = splash(1.0)
    header_img = header(2.0)
    gap = 40
    W = splash_img.width + gap + header_img.width + 80
    H = max(splash_img.height, header_img.height) + 120
    canvas = Image.new("RGB", (W, H), (8, 8, 10))
    canvas.paste(splash_img, (40, 50))
    canvas.paste(header_img, (splash_img.width + gap + 40, 50))
    d = ImageDraw.Draw(canvas)
    cap = font(FONT_BODY, 19, "Medium")
    d.text((40, 16), "SPLASH — asset \"icone\", 200dp, sem círculo", font=cap, fill=(170, 170, 180))
    d.text((splash_img.width + gap + 40, 16),
           "HEADER — marca \"iconeinicial\" + NEXUS GYM + data",
           font=cap, fill=(170, 170, 180))
    canvas.save(OUT)
    print("preview:", OUT, canvas.size)


if __name__ == "__main__":
    main()
