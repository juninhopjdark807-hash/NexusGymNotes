#!/usr/bin/env python3
"""Prévia de validação visual (splash + header) — usa APENAS os assets reais:
- "icone" na splash (fundo dark, 240dp equivalentes, sem máscara/círculo)
- "iconeinicio.png" como marca do header (estilo da UI final do Flutter)
Também valida o header em largura estreita (320dp), onde o texto NEXUS GYM
escala para caber (FittedBox), sem quebra de linha.
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


def text_w(s, f, spacing=0.0):
    total = 0.0
    for ch in s:
        total += f.getlength(ch) + spacing
    return total - (spacing if s else 0.0)


def radial_glow(size, color, peak=0.12):
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    steps = 48
    max_r = int(size / 2)
    for i in range(steps, 0, -1):
        r = int(max_r * i / steps)
        a = int(255 * peak * (1 - i / steps) ** 1.6)
        gd.ellipse((size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r),
                   fill=color + (a,))
    return glow.filter(ImageFilter.GaussianBlur(size * 0.12))


def splash(scale=1.0):
    """Mock 390x760: asset 'icone' em 240px, completo (sem máscara), + glow."""
    W, H = int(390 * scale), int(760 * scale)
    img = Image.new("RGB", (W, H), SPLASH_BG)
    icon = int(240 * scale)
    g = radial_glow(int(icon * 1.65), ACCENT, 0.12)
    img.paste(g, ((W - g.width) // 2, (H - g.height) // 2), g)
    art = Image.open(ICONE).convert("RGBA").resize((icon, icon), Image.LANCZOS)
    img.paste(art, ((W - icon) // 2, (H - icon) // 2), art)
    return img


def header(scale=2.0, width_dp=390.0, dark=False):
    """Mock do header final (mesma estrutura/tokens do Flutter) em APP_BG."""
    compact = width_dp < 360 or dark
    W, H = int(width_dp * scale), int(340 * scale)
    img = Image.new("RGB", (W, H), APP_BG)
    d = ImageDraw.Draw(img, "RGBA")

    # glow roxo discreto (topo direito) + anel sutil (inferior esquerdo)
    g = radial_glow(int(460 * scale), ACCENT, 0.12)
    img.paste(g, (W - g.width + int(60 * scale), -int(110 * scale)), g)
    ring = Image.new("RGBA", (int(380 * scale),) * 2, (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse((0, 0, ring.width - 2, ring.height - 2),
               outline=ACCENT + (20,), width=max(2, int(2.4 * scale)))
    img.paste(ring, (-int(150 * scale), H - int(160 * scale)), ring)

    pad_l = int(24 * scale)
    pad_t = int(20 * scale)
    mark = int((compact and 34 or 40) * scale)
    gap = int((compact and 8 or 10) * scale)
    mark_img = Image.open(MARCA).resize((mark, mark), Image.LANCZOS).convert("RGBA")
    # glow atrás da marca (como no app)
    mg = radial_glow(int(200 * scale), ACCENT, 0.10)
    img.paste(mg, (pad_l - int(46 * scale), pad_t - int(50 * scale)), mg)

    # linha do logo: [marca] NEXUS GYM (marca centralizada com o texto)
    img.paste(mark_img, (pad_l, pad_t), mark_img)
    logo_size = int((compact and 24 or 27) * scale)
    logo_font = font(FONT_DISPLAY, logo_size, "Bold")
    label = "NEXUS GYM"
    nat_w = text_w("NEXUS", logo_font, 2.0 * scale) + \
        logo_font.getlength(" ") + 2.0 * scale + \
        text_w("GYM", font(FONT_DISPLAY, logo_size, "SemiBold"), 2.0 * scale)
    badge_w = int(118 * scale)
    avail = W - pad_l * 2 - badge_w - 12 * scale
    fit = 1.0
    need = mark + gap + nat_w
    if need > avail:
        fit = max(0.62, avail / need)
        logo_size = int(logo_size * fit)
        logo_font = font(FONT_DISPLAY, logo_size, "Bold")
    x = pad_l + mark + gap
    y_logo_top = pad_t + (mark - logo_size) // 2
    draw_text(d, (x, y_logo_top), "NEXUS", logo_font, TEXT, spacing=2.0 * scale)
    x += text_w("NEXUS", logo_font, 2.0 * scale) + \
        logo_font.getlength(" ") + 2.0 * scale
    gym_font = font(FONT_DISPLAY, logo_size, "SemiBold")
    draw_text(d, (x, y_logo_top), "GYM", gym_font, ACCENT, spacing=2.0 * scale)

    # tagline alinhada com o "N" de NEXUS (indent = marca + gap)
    tag_size = int((compact and 11.5 or 12.5) * scale)
    tag_font = font(FONT_BODY, tag_size, "Medium")
    tag_y = pad_t + mark + int(7 * scale)
    d.text((pad_l + mark + gap, tag_y), "Seu treino. Seu progresso.",
           font=tag_font, fill=TEXT_DIM)

    # badge de data (direita, alinhado ao topo do conjunto)
    b_font = font(FONT_BODY, int(10.5 * scale), "Bold")
    label_b = "TER · 1 SET"
    b_h = int(31 * scale)
    b_w = badge_w
    b_x = W - pad_l - b_w
    b_y = pad_t + (mark - b_h) // 2
    d.rounded_rectangle((b_x, b_y, b_x + b_w, b_y + b_h), radius=int(10 * scale),
                        fill=SURFACE2, outline=STROKE, width=int(1.2 * scale))
    ci = int(14 * scale)
    cx, cy = b_x + int(12 * scale), b_y + (b_h - ci) // 2
    d.rounded_rectangle((cx, cy, cx + ci, cy + ci), radius=int(3 * scale),
                        outline=ACCENT2, width=max(2, int(1.4 * scale)))
    d.line((cx + ci * 0.25, cy + ci * 0.35, cx + ci * 0.75, cy + ci * 0.35),
           fill=ACCENT2, width=max(2, int(1.4 * scale)))
    d.rounded_rectangle((cx + ci * 0.32, cy + ci * 0.42, cx + ci * 0.52, cy + ci * 0.58),
                        radius=int(1 * scale), fill=ACCENT2)
    d.text((b_x + int(30 * scale), b_y + (b_h - int(10.5 * scale)) // 2 - int(1 * scale)),
           label_b, font=b_font, fill=TEXT_DIM)

    # separador gradiente + TREINOS (respiro equilibrado)
    sep_y = tag_y + int(15 * scale) + int(18 * scale)
    sep_w = W - pad_l * 2
    for i in range(int(sep_w * 2)):
        t = i / (sep_w * 2)
        a = int(255 * (0.0 if t < 0.02 else (0.75 if t < 0.5 else max(0.0, (1 - t) * 2)) * 1.0))
        d.line((pad_l + i / 2, sep_y, pad_l + i / 2, sep_y), fill=STROKE + (a,), width=1)

    t_font = font(FONT_DISPLAY, int(22 * scale), "Bold")
    ty = sep_y + 1 + int(12 * scale)
    d.text((pad_l, ty), "TREINOS", font=t_font, fill=TEXT)
    bar_x = pad_l + d.textlength("TREINOS", font=t_font) + int(10 * scale)
    bar_w = W - pad_l - bar_x
    for i in range(int(bar_w * 2)):
        t = i / max(1, int(bar_w * 2))
        a = int(255 * 0.55 * max(0.0, 1 - t))
        d.line((bar_x + i / 2, ty + int(26 * scale), bar_x + i / 2, ty + int(29 * scale)),
               fill=ACCENT + (a,), width=1)

    return img


def main():
    splash_img = splash(1.0)
    header_img = header(2.0, width_dp=390.0)
    narrow_img = header(2.0, width_dp=320.0)
    gap = 40
    W = splash_img.width + gap + header_img.width + gap + narrow_img.width + 80
    H = max(splash_img.height, header_img.height, narrow_img.height) + 120
    canvas = Image.new("RGB", (W, H), (8, 8, 10))
    canvas.paste(splash_img, (40, 50))
    canvas.paste(header_img, (splash_img.width + gap + 40, 50))
    canvas.paste(narrow_img,
                 (splash_img.width + gap + 40 + header_img.width + gap, 50))
    d = ImageDraw.Draw(canvas)
    cap = font(FONT_BODY, 19, "Medium")
    d.text((40, 16), "SPLASH — asset \"icone\" 240dp, completo, sem máscara",
           font=cap, fill=(170, 170, 180))
    x2 = splash_img.width + gap + 40
    d.text((x2, 16), "HEADER 390dp — marca + NEXUS GYM (tagline alinhada ao N)",
           font=cap, fill=(170, 170, 180))
    x3 = x2 + header_img.width + gap
    d.text((x3, 16), "HEADER 320dp — FittedBox (sem quebra)",
           font=cap, fill=(170, 170, 180))
    canvas.save(OUT)
    print("preview:", OUT, canvas.size)


if __name__ == "__main__":
    main()
