"""
PSG icon generator
Design: bold black "P" + red diagonal capsule + gold dot + gray nav dots
Palette: black / PSG-red / German-gold on light-gray background
"""
from PIL import Image, ImageDraw, ImageFont
import os, math

# ── Brand palette ─────────────────────────────────────────────────────────────
PSG_RED    = (204,   0,   0, 255)   # German red
PSG_GOLD   = (255, 204,   0, 255)   # German Bundesgold
NEAR_BLACK = ( 26,  26,  26, 255)
LIGHT_BG   = (242, 242, 247, 255)   # iOS-style light gray
NAV_GRAY   = (155, 155, 165, 255)
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
    Draw the PSG mark:
      • Bold "P" letterform (Arial Black)
      • Red diagonal capsule (the R-leg / connection line)
      • Gold endpoint dot
      • Three gray nav dots (upper-left)
    All coordinates are normalized to a 100-unit square.
    """
    s = size / 100.0

    # ── Bold "P" ──────────────────────────────────────────────────────────
    font = get_font(int(73 * s))
    bb   = draw.textbbox((0, 0), "P", font=font)
    # Position: slight inset from top-left, letter fills ~70% of icon
    tx = int(11 * s) - bb[0]
    ty = int(11 * s) - bb[1]
    draw.text((tx, ty), "P", fill=p_color, font=font)

    # ── Red diagonal capsule (starts at bowl-stem junction, goes lower-right)
    lx0, ly0 = int(57 * s), int(54 * s)
    lx1, ly1 = int(80 * s), int(75 * s)
    lt       = max(3, int(9 * s))
    capsule(draw, lx0, ly0, lx1, ly1, lt, leg_color)

    # ── Gold endpoint dot ─────────────────────────────────────────────────
    dr = max(2, int(8.5 * s))
    draw.ellipse([lx1-dr, ly1-dr, lx1+dr, ly1+dr], fill=dot_color)

    # ── Three navigation dots (upper-left, staggered) ─────────────────────
    if size >= 32:
        gr = max(1, int(2.7 * s))
        for dx, dy in [(13.0, 24.0), (18.5, 31.0), (13.0, 38.0)]:
            cx, cy = int(dx * s), int(dy * s)
            draw.ellipse([cx-gr, cy-gr, cx+gr, cy+gr], fill=nav_color)


# ── Icon factories ────────────────────────────────────────────────────────────

def icon_square(size):
    """Light-gray rounded-rect icon (for most platforms)."""
    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    rrect(draw, 0, 0, size-1, size-1, int(22*size/100), LIGHT_BG)
    draw_mark(draw, size)
    return img


def icon_circle(size):
    """Circular clip version (Android round launcher)."""
    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw.ellipse([0, 0, size-1, size-1], fill=LIGHT_BG)
    draw_mark(draw, size)
    return img


def status_icon(size, state):
    """
    Tray / system-bar status icon — white bg style.
    Design: white rounded-rect + bold black P + two pixel squares + colored dot.
      1 = connected   → teal dot
      2 = connecting  → amber dot
      3 = idle/off    → gray dot
    """
    DOT = {
        1: ( 46, 206, 138, 255),   # teal  — connected
        2: (255, 149,   0, 255),   # amber — connecting
        3: (160, 160, 160, 255),   # gray  — idle
    }

    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    s    = size / 100.0

    # ── White rounded-rect background ────────────────────────────────────
    rrect(draw, 0, 0, size-1, size-1, int(20 * s), (255, 255, 255, 255))

    # ── Bold "P" letterform ───────────────────────────────────────────────
    font = get_font(int(62 * s))
    bb   = draw.textbbox((0, 0), "P", font=font)
    # Nudge right so the two squares fit to its left
    tx = int(22 * s) - bb[0]
    ty = int(13 * s) - bb[1]
    draw.text((tx, ty), "P", fill=(0, 0, 0, 255), font=font)

    # ── Two small black squares (upper-left, pixel / bit effect) ─────────
    sq  = max(2, int(7 * s))      # square side length
    gap = max(1, int(2.5 * s))    # gap between squares
    sx  = int(10 * s)             # left edge of squares
    sy1 = int(20 * s)             # top of upper square
    sy2 = sy1 + sq + gap          # top of lower square
    draw.rectangle([sx, sy1, sx + sq, sy1 + sq], fill=(0, 0, 0, 255))
    draw.rectangle([sx, sy2, sx + sq, sy2 + sq], fill=(0, 0, 0, 255))

    # ── Status dot (lower-right, large) ──────────────────────────────────
    dr  = max(3, int(13 * s))
    dcx = int(72 * s)
    dcy = int(73 * s)
    draw.ellipse([dcx-dr, dcy-dr, dcx+dr, dcy+dr], fill=DOT[state])

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
