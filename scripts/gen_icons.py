"""
PSG icon generator
Design: bold black "P" + red diagonal capsule + gold dot + gray nav dots
Palette: black / PSG-red / German-gold on light-gray background
"""
from PIL import Image, ImageDraw, ImageFont
import os, math

# ── Brand palette ─────────────────────────────────────────────────────────────
PSG_RED    = (221,   0,   0, 255)   # #DD0000
PSG_GOLD   = (255, 204,   0, 255)   # #FFCC00
NEAR_BLACK = (  0,   0,   0, 255)   # #000000
LIGHT_BG   = (243, 244, 246, 255)   # #F3F4F6
NAV_GRAY   = (156, 163, 175, 255)   # #9CA3AF
WHITE      = (255, 255, 255, 255)
MUTED_RED  = (160,  40,  40, 255)
MID_GRAY   = (110, 110, 110, 255)
TRANSPARENT= (  0,   0,   0,   0)

BASE = r"d:\FlClash--main"

FONT_PATH = r"C:\Windows\Fonts\ariblk.ttf"   # Arial Black — best match

# ── Helpers ───────────────────────────────────────────────────────────────────

def get_font(pt):
    return ImageFont.truetype(FONT_PATH, pt)


def rrect(draw, x0, y0, x1, y1, r, fill):
    """Filled rounded rectangle."""
    r = min(r, (x1-x0)//2, (y1-y0)//2)
    draw.rectangle([x0+r, y0, x1-r, y1], fill=fill)
    draw.rectangle([x0, y0+r, x1, y1-r], fill=fill)
    for ex, ey in [(x0,y0),(x1-2*r,y0),(x0,y1-2*r),(x1-2*r,y1-2*r)]:
        draw.ellipse([ex, ey, ex+2*r, ey+2*r], fill=fill)


def capsule(draw, x0, y0, x1, y1, thick, color):
    """Thick rounded bar from (x0,y0) to (x1,y1)."""
    a  = math.atan2(y1-y0, x1-x0)
    r  = thick / 2
    px = -math.sin(a) * r
    py =  math.cos(a) * r
    pts = [(x0+px,y0+py),(x0-px,y0-py),(x1-px,y1-py),(x1+px,y1+py)]
    draw.polygon([(int(x),int(y)) for x,y in pts], fill=color)
    for ex,ey in [(x0,y0),(x1,y1)]:
        draw.ellipse([int(ex-r),int(ey-r),int(ex+r),int(ey+r)], fill=color)


# ── Core mark drawing ─────────────────────────────────────────────────────────

def draw_mark(draw, size,
              p_color=NEAR_BLACK,
              leg_color=PSG_RED,
              dot_color=PSG_GOLD,
              nav_color=NAV_GRAY):
    """
    PSG mark matching the SVG logo (200×200 coordinate space):
      • Geometric stroke P: M70 140 V60 H110 Q130 60 130 85 T110 110 H70
      • Red diagonal line (110,110)→(140,140)
      • Gold circle at (140,140) r=12
      • Three gray dots at (50,50),(70,50),(50,70) r=4
    """
    s = size / 200.0

    def sc(v): return int(v * s)
    def spt(x, y): return (sc(x), sc(y))

    def qbez(p0, p1, p2, n=20):
        pts = []
        for i in range(n + 1):
            t = i / n
            u = 1 - t
            x = u*u*p0[0] + 2*u*t*p1[0] + t*t*p2[0]
            y = u*u*p0[1] + 2*u*t*p1[1] + t*t*p2[1]
            pts.append((int(x * s), int(y * s)))
        return pts

    sw = max(2, sc(16))   # P stroke width (SVG stroke-width=16)

    # Full P path as polyline: stem + top bar + bowl + bottom bar
    # SVG: M70,140 V60 H110 Q130,60 130,85 T110,110 H70
    # T reflected control: (130,110) from prev ctrl (130,60) → end (130,85)
    p_pts = (
        [spt(70, 140), spt(70, 60), spt(110, 60)]
        + qbez((110, 60),  (130,  60), (130,  85))
        + qbez((130,  85), (130, 110), (110, 110))
        + [spt(70, 110)]
    )
    draw.line(p_pts, fill=p_color, width=sw, joint="curve")

    # Red diagonal: (110,110)→(140,140), stroke-width=12
    rw = max(2, sc(12))
    capsule(draw, *spt(110, 110), *spt(140, 140), rw, leg_color)

    # Gold circle at (140,140) r=12
    dr = max(2, sc(12))
    gx, gy = spt(140, 140)
    draw.ellipse([gx - dr, gy - dr, gx + dr, gy + dr], fill=dot_color)

    # Gray dots: (50,50),(70,50),(50,70) r=4
    if size >= 32:
        gr = max(1, sc(4))
        for dx, dy in [(50, 50), (70, 50), (50, 70)]:
            cx, cy = spt(dx, dy)
            draw.ellipse([cx - gr, cy - gr, cx + gr, cy + gr], fill=nav_color)


# ── Icon factories ────────────────────────────────────────────────────────────

def icon_square(size):
    """Matches psg_logo.svg: gray rounded rect with 10% margin on transparent bg.
    SVG: rect x=20 y=20 w=160 h=160 rx=30 on 200px canvas."""
    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    m = int(0.10 * size)    # 20/200 = 10%
    r = int(0.15 * size)    # rx=30/200 = 15%
    rrect(draw, m, m, size-1-m, size-1-m, r, LIGHT_BG)
    draw_mark(draw, size)
    return img


def icon_circle(size):
    """Circular clip version (Android round launcher) — same padded mark."""
    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw.ellipse([0, 0, size-1, size-1], fill=LIGHT_BG)
    draw_mark(draw, size)
    return img


def status_icon(size, state):
    """
    Bauhaus hard-geometric tray icon — black bg + white rectangular P.
    Connection polygon shows state color:
      1 = connected   → emerald  #10B981
      2 = connecting  → amber    #F59E0B
      3 = idle/off    → dark gray
    """
    CONN_COLOR = {
        1: ( 16, 185, 129, 255),
        2: (245, 158,  11, 255),
        3: ( 80,  80,  80, 255),
    }

    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    s    = size / 200.0

    def sc(v): return int(v * s)
    def spt(x, y): return (sc(x), sc(y))
    def srect(x, y, w, h): return [sc(x), sc(y), sc(x + w), sc(y + h)]

    # Black background
    draw.rectangle([0, 0, size - 1, size - 1], fill=(0, 0, 0, 255))

    W = (255, 255, 255, 255)

    # Hard geometric P (all white rectangles)
    draw.rectangle(srect(50,  40, 30, 120), fill=W)   # vertical stem
    draw.rectangle(srect(80,  40, 70,  30), fill=W)   # top bar
    draw.rectangle(srect(80,  85, 70,  30), fill=W)   # middle bar
    draw.rectangle(srect(120, 70, 30,  15), fill=W)   # right connector

    # Speed/connection polygon — state color
    # M150,115 L180,160 H140 L110,115 Z
    poly = [spt(150, 115), spt(180, 160), spt(140, 160), spt(110, 115)]
    draw.polygon(poly, fill=CONN_COLOR[state])

    # Precision dots (white squares, upper-left)
    draw.rectangle(srect(25, 25, 10, 10), fill=W)
    draw.rectangle(srect(40, 25, 10, 10), fill=W)
    draw.rectangle(srect(25, 40, 10, 10), fill=W)

    return img


def banner(width, height):
    """Android TV / desktop banner: light bg, icon left, PSG wordmark right."""
    img  = Image.new("RGBA", (width, height), LIGHT_BG)
    draw = ImageDraw.Draw(img)

    # Red accent stripe on left
    draw.rectangle([0, 0, 5, height-1], fill=PSG_RED)

    # Embedded square icon
    ih = height - 16
    ic = icon_square(ih)
    img.paste(ic, (12, 8), ic)

    # "PSG" wordmark to the right
    tx   = 12 + ih + 14
    font = get_font(int(height * 0.45))
    bb   = draw.textbbox((0, 0), "PSG", font=font)
    ty   = (height - (bb[3] - bb[1])) // 2 - bb[1]
    draw.text((tx, ty), "PSG", fill=NEAR_BLACK, font=font)

    # Red underline below wordmark
    bbl = draw.textbbox((tx, ty), "PSG", font=font)
    draw.rectangle([tx, bbl[3]+3, bbl[2], bbl[3]+5], fill=PSG_RED)

    return img


# ── Save helpers ──────────────────────────────────────────────────────────────

def save_ico(path, sizes=(256,128,64,48,32,16)):
    imgs = [icon_square(s) for s in sizes]
    imgs[0].save(path, format="ICO", append_images=imgs[1:])
    print(f"  {path}")

def save_png(img, path):
    img.save(path, format="PNG")
    print(f"  {path}")

def save_webp(img, path, quality=92):
    img.save(path, format="WEBP", quality=quality, method=6)
    print(f"  {path}")


# ── Generate everything ───────────────────────────────────────────────────────

print("Main app icons …")
save_png(icon_square(550), os.path.join(BASE, r"assets\images\icon.png"))
save_ico(os.path.join(BASE, r"assets\images\icon.ico"))

print("Windows runner icon …")
save_ico(os.path.join(BASE, r"windows\runner\resources\app_icon.ico"))

print("Status / tray icons …")
for state in (1, 2, 3):
    bp = os.path.join(BASE, rf"assets\images\icon\status_{state}")
    save_png(status_icon(108, state), bp + ".png")
    imgs = [status_icon(sz, state) for sz in (64, 32, 22, 16)]
    imgs[0].save(bp + ".ico", format="ICO", append_images=imgs[1:])
    print(f"  {bp}.ico")

print("Android launcher icons …")
android_res = os.path.join(BASE, r"android\app\src\main\res")
for folder, sz in {
        "mipmap-mdpi":48,"mipmap-hdpi":72,"mipmap-xhdpi":96,
        "mipmap-xxhdpi":144,"mipmap-xxxhdpi":192}.items():
    d = os.path.join(android_res, folder)
    save_webp(icon_square(sz), os.path.join(d, "ic_launcher.webp"))
    save_webp(icon_circle(sz), os.path.join(d, "ic_launcher_round.webp"))

print("Android TV banner …")
save_png(banner(320, 180), os.path.join(android_res, r"mipmap-xhdpi\ic_banner.png"))

print("\nDone — PSG P+connection mark generated.")
