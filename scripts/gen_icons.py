"""
PSG icon generator — Bauhaus hard-geometric design
All icons: black background + white rectangular P + colored connection polygon
Status polygon color varies by connection state; all other icons use white.
"""
from PIL import Image, ImageDraw
import os

BASE = r"d:\FlClash--main"

TRANSPARENT = (0, 0, 0, 0)
BLACK       = (0, 0, 0, 255)
WHITE       = (255, 255, 255, 255)


# ── Core drawing (200×200 coordinate space) ───────────────────────────────────

def draw_bauhaus(draw, size, conn_color=WHITE):
    """
    PSG Bauhaus mark on black background.
    Matches psg_logo.svg exactly — all shapes are rectangles or a polygon.
    conn_color: color of the connection polygon (white for logo, state-color for tray)
    """
    s = size / 200.0

    def sc(v): return int(v * s)
    def srect(x, y, w, h): return [sc(x), sc(y), sc(x + w), sc(y + h)]
    def spt(x, y): return (sc(x), sc(y))

    # Black background
    draw.rectangle([0, 0, size - 1, size - 1], fill=BLACK)

    W = WHITE

    # Geometric P
    draw.rectangle(srect(50,  40, 30, 120), fill=W)  # vertical stem
    draw.rectangle(srect(80,  40, 70,  30), fill=W)  # top bar
    draw.rectangle(srect(80,  85, 70,  30), fill=W)  # middle bar
    draw.rectangle(srect(120, 70, 30,  15), fill=W)  # right connector

    # Connection polygon: M150,115 L180,160 H140 L110,115 Z
    draw.polygon(
        [spt(150, 115), spt(180, 160), spt(140, 160), spt(110, 115)],
        fill=conn_color,
    )

    # Precision squares (upper-left)
    draw.rectangle(srect(25, 25, 10, 10), fill=W)
    draw.rectangle(srect(40, 25, 10, 10), fill=W)
    draw.rectangle(srect(25, 40, 10, 10), fill=W)


# ── Icon factories ────────────────────────────────────────────────────────────

def icon_square(size):
    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw_bauhaus(draw, size)
    return img


def icon_circle(size):
    """Circular clip (Android round launcher)."""
    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw_bauhaus(draw, size)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    img.putalpha(mask)
    return img


def status_icon(size, state):
    """
    Tray icon — same Bauhaus design, connection polygon shows state:
      1 = connected   → emerald  #10B981
      2 = connecting  → amber    #F59E0B
      3 = idle/off    → dark gray
    """
    CONN = {
        1: ( 16, 185, 129, 255),
        2: (245, 158,  11, 255),
        3: ( 80,  80,  80, 255),
    }
    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw_bauhaus(draw, size, conn_color=CONN[state])
    return img


# ── Save helpers ──────────────────────────────────────────────────────────────

def save_ico(path, sizes=(256, 128, 64, 48, 32, 16)):
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
        "mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192}.items():
    d = os.path.join(android_res, folder)
    save_webp(icon_square(sz), os.path.join(d, "ic_launcher.webp"))
    save_webp(icon_circle(sz), os.path.join(d, "ic_launcher_round.webp"))

print("Android TV banner …")
# Banner: black bg, icon left, PSG text right
bw, bh = 320, 180
banner = Image.new("RGBA", (bw, bh), BLACK)
ic = icon_square(bh - 16)
banner.paste(ic, (8, 8), ic)
save_png(banner, os.path.join(android_res, r"mipmap-xhdpi\ic_banner.png"))

print("\nDone — PSG Bauhaus icons generated.")
