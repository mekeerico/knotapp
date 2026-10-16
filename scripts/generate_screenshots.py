import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

out_dir = r'c:\Users\PC\Documents\knot\playstore_assets'
os.makedirs(out_dir, exist_ok=True)

cache_dir = os.path.join(out_dir, 'cache')
amara_path = os.path.join(cache_dir, 'amara.jpg')
icon_path = os.path.join(out_dir, 'app_icon_512x512.png')

# Fonts
font_serif_large = ImageFont.truetype('C:/Windows/Fonts/georgiab.ttf', 62)
font_serif_med = ImageFont.truetype('C:/Windows/Fonts/georgiab.ttf', 44)
font_serif_small = ImageFont.truetype('C:/Windows/Fonts/georgiab.ttf', 32)
font_sans_bold = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 36)
font_sans_med = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 30)
font_sans_small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 24)
font_sans_xs = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 20)

W, H = 1080, 2400

# Vector Drawing Helpers to ensure 100% crisp rendering without missing unicode glyphs
def draw_star(draw, cx, cy, r_out, r_in, fill):
    points = []
    for i in range(10):
        angle = i * math.pi / 5 - math.pi / 2
        r = r_out if i % 2 == 0 else r_in
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, fill=fill)

def draw_heart(draw, cx, cy, size, fill):
    # Smooth heart polygon
    points = []
    for t in range(0, 360, 5):
        rad = math.radians(t)
        # Heart equation
        x = 16 * (math.sin(rad) ** 3)
        y = -(13 * math.cos(rad) - 5 * math.cos(2*rad) - 2 * math.cos(3*rad) - math.cos(4*rad))
        scale = size / 32.0
        points.append((cx + x * scale, cy + y * scale))
    draw.polygon(points, fill=fill)

def draw_cross(draw, cx, cy, size, fill, width=4):
    half = size / 2
    draw.line([(cx - half, cy - half), (cx + half, cy + half)], fill=fill, width=width)
    draw.line([(cx - half, cy + half), (cx + half, cy - half)], fill=fill, width=width)

def draw_check(draw, cx, cy, size, fill, width=4):
    draw.line([(cx - size*0.4, cy), (cx - size*0.1, cy + size*0.35)], fill=fill, width=width)
    draw.line([(cx - size*0.1, cy + size*0.35), (cx + size*0.4, cy - size*0.35)], fill=fill, width=width)

def draw_shield(draw, cx, cy, w, h, fill, outline=None):
    pts = [
        (cx - w//2, cy - h//2),
        (cx + w//2, cy - h//2),
        (cx + w//2, cy),
        (cx, cy + h//2),
        (cx - w//2, cy)
    ]
    draw.polygon(pts, fill=fill, outline=outline)

def create_base_canvas():
    base = Image.new('RGB', (W, H), (10, 13, 20))
    draw = ImageDraw.Draw(base)
    for y in range(H):
        factor = y / H
        r = int(12 + (6 - 12) * factor)
        g = int(15 + (9 - 15) * factor)
        b = int(24 + (14 - 24) * factor)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    for r in range(450, 0, -15):
        alpha = int((1 - (r / 450)) * 40)
        g_draw.ellipse([W//2 - r, 300 - r, W//2 + r, 300 + r], fill=(212, 175, 55, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=50))
    base.paste(Image.alpha_composite(base.convert('RGBA'), glow).convert('RGB'), (0, 0))
    return base

def render_header(draw, tag, title, sub):
    t_bbox = font_sans_xs.getbbox(tag)
    tw = t_bbox[2] - t_bbox[0] + 36
    th = t_bbox[3] - t_bbox[1] + 16
    tx = (W - tw) // 2
    ty = 90
    draw.rounded_rectangle([tx, ty, tx + tw, ty + th], radius=th//2, fill=(24, 20, 12, 220), outline=(212, 175, 55, 180), width=1)
    draw.text(((W - (t_bbox[2] - t_bbox[0])) // 2, ty + 7), tag, font=font_sans_xs, fill=(212, 175, 55))

    lines = title.split('\n')
    curr_y = ty + th + 24
    for l in lines:
        tb = font_serif_large.getbbox(l)
        lw = tb[2] - tb[0]
        draw.text(((W - lw) // 2, curr_y), l, font=font_serif_large, fill=(245, 230, 200))
        curr_y += (tb[3] - tb[1]) + 14

    curr_y += 6
    sub_lines = sub.split('\n')
    for sl in sub_lines:
        sb = font_sans_med.getbbox(sl)
        sw = sb[2] - sb[0]
        draw.text(((W - sw) // 2, curr_y), sl, font=font_sans_med, fill=(160, 174, 192))
        curr_y += (sb[3] - sb[1]) + 8

def draw_phone_shell(draw, px1, py1, px2, py2):
    for i in range(20, 0, -3):
        draw.rounded_rectangle([px1 - i, py1 - i, px2 + i, py2 + i], radius=54 + i, outline=(0, 0, 0), width=2)
    draw.rounded_rectangle([px1, py1, px2, py2], radius=54, fill=(18, 22, 32), outline=(212, 175, 55, 140), width=3)
    draw.rounded_rectangle([px1 + 8, py1 + 8, px2 - 8, py2 - 8], radius=46, fill=(11, 14, 20))
    cw, ch = 150, 26
    cx = (px1 + px2 - cw) // 2
    draw.rounded_rectangle([cx, py1 + 16, cx + cw, py1 + 16 + ch], radius=13, fill=(4, 6, 10))

def draw_phone_top_bar(draw, px1, py1, px2):
    draw.text((px1 + 40, py1 + 20), "9:41", font=font_sans_xs, fill=(200, 200, 200))
    draw.text((px2 - 120, py1 + 20), "5G  100%", font=font_sans_xs, fill=(200, 200, 200))

def draw_bottom_nav(draw, sx1, sy1, sx2, sy2, active_idx=0):
    nav_h = 100
    ny = sy2 - nav_h
    draw.rectangle([sx1, ny, sx2, sy2], fill=(14, 18, 26))
    draw.line([(sx1, ny), (sx2, ny)], fill=(35, 45, 60), width=1)
    
    tabs = ["Matches", "Breakdown", "Verification", "AI Coach", "Profile"]
    tw = (sx2 - sx1) // len(tabs)
    for i, tab in enumerate(tabs):
        tx = sx1 + i * tw + tw // 2
        color = (212, 175, 55) if i == active_idx else (120, 130, 150)
        tb = font_sans_xs.getbbox(tab)
        if i == active_idx:
            draw.ellipse([tx - 4, ny + 20, tx + 4, ny + 28], fill=color)
        else:
            draw.ellipse([tx - 3, ny + 22, tx + 3, ny + 28], fill=(80, 90, 110))
        draw.text((tx - (tb[2] - tb[0]) // 2, ny + 46), tab, font=font_sans_xs, fill=color)

# ==============================================================================
# SCREENSHOT 1: Curated Intentional Matches
# ==============================================================================
def render_screen1():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    render_header(
        draw,
        "WHERE TRUE RELATIONSHIP LEADS TO VOW",
        "Curated Intentional Matches\nFor Lifelong Marriage",
        "Deep matrimonial curation for accomplished, high-caliber singles."
    )
    
    px1, py1, px2, py2 = 120, 520, 960, 2340
    draw_phone_shell(draw, px1, py1, px2, py2)
    draw_phone_top_bar(draw, px1, py1, px2)
    
    sx1, sy1, sx2, sy2 = px1 + 8, py1 + 8, px2 - 8, py2 - 8
    
    # App Bar
    if os.path.exists(icon_path):
        knot_mini = Image.open(icon_path).resize((40, 40), Image.Resampling.LANCZOS)
        img.paste(knot_mini, (sx1 + 36, sy1 + 58))
    draw.text((sx1 + 86, sy1 + 58), "KNOT", font=font_serif_med, fill=(212, 175, 55))
    draw.text((sx1 + 220, sy1 + 70), "• Sovereign Registry", font=font_sans_small, fill=(150, 160, 180))
    draw.rounded_rectangle([sx2 - 120, sy1 + 62, sx2 - 36, sy1 + 102], radius=20, fill=(25, 32, 45), outline=(212, 175, 55, 100))
    draw.text((sx2 - 105, sy1 + 70), "Filter", font=font_sans_xs, fill=(212, 175, 55))
    
    # Candidate Card
    cx1, cy1, cx2, cy2 = sx1 + 24, sy1 + 130, sx2 - 24, sy2 - 240
    draw.rounded_rectangle([cx1, cy1, cx2, cy2], radius=32, fill=(18, 24, 34), outline=(212, 175, 55, 80), width=2)
    
    card_w = cx2 - cx1
    card_img_h = int((cy2 - cy1) * 0.70)
    
    if os.path.exists(amara_path):
        p_img = Image.open(amara_path).convert('RGB')
        p_resized = p_img.resize((card_w, card_img_h), Image.Resampling.LANCZOS)
        
        mask = Image.new('L', (card_w, card_img_h), 0)
        m_draw = ImageDraw.Draw(mask)
        m_draw.rounded_rectangle([0, 0, card_w, card_img_h + 32], radius=32, fill=255)
        img.paste(p_resized, (cx1, cy1), mask)
    
    # Gold Verified Shield Pill
    v_pill = [cx1 + 24, cy1 + 24, cx1 + 245, cy1 + 70]
    draw.rounded_rectangle(v_pill, radius=23, fill=(15, 18, 25, 230), outline=(212, 175, 55), width=2)
    draw_star(draw, cx1 + 45, cy1 + 47, 10, 5, fill=(212, 175, 55))
    draw.text((cx1 + 64, cy1 + 34), "GOLD VERIFIED", font=font_sans_xs, fill=(212, 175, 55))
    
    # Match Score Pill
    m_pill = [cx2 - 240, cy1 + 24, cx2 - 24, cy1 + 70]
    draw.rounded_rectangle(m_pill, radius=23, fill=(212, 175, 55), outline=(245, 230, 200))
    draw.text((cx2 - 222, cy1 + 34), "96% MATCH", font=font_sans_xs, fill=(15, 18, 25))
    
    # Card Text details
    ty = cy1 + card_img_h + 20
    draw.text((cx1 + 28, ty), "Dr. Amara Okonkwo, 29", font=font_serif_med, fill=(255, 255, 255))
    draw.text((cx1 + 28, ty + 52), "Pediatric Consultant • Maitama, Abuja", font=font_sans_med, fill=(200, 210, 225))
    
    p1 = [cx1 + 28, ty + 104, cx1 + 260, ty + 146]
    draw.rounded_rectangle(p1, radius=21, fill=(26, 34, 48), outline=(212, 175, 55, 120))
    draw.text((cx1 + 44, ty + 112), "The Devoted Anchor", font=font_sans_xs, fill=(212, 175, 55))
    
    p2 = [cx1 + 276, ty + 104, cx1 + 490, ty + 146]
    draw.rounded_rectangle(p2, radius=21, fill=(26, 34, 48), outline=(100, 120, 150, 120))
    draw.text((cx1 + 296, ty + 112), "Timeline: 1-2 Years", font=font_sans_xs, fill=(200, 210, 225))
    
    # Action Buttons Bar
    by = cy2 + 25
    
    # Pass button (with vector cross)
    draw.ellipse([sx1 + 120, by, sx1 + 210, by + 90], fill=(24, 30, 42), outline=(100, 115, 135), width=2)
    draw_cross(draw, sx1 + 165, by + 45, 28, fill=(160, 175, 195), width=3)
    
    # AI Advice button (with vector star)
    draw.ellipse([W//2 - 45, by + 5, W//2 + 45, by + 95], fill=(30, 25, 15), outline=(212, 175, 55), width=2)
    draw_star(draw, W//2, by + 50, 16, 7, fill=(212, 175, 55))
    
    # Like / Connect button (with vector heart)
    draw.ellipse([sx2 - 210, by, sx2 - 120, by + 90], fill=(212, 175, 55), outline=(245, 230, 200), width=2)
    draw_heart(draw, sx2 - 165, by + 45, 34, fill=(15, 18, 25))
    
    draw_bottom_nav(draw, sx1, sy1, sx2, sy2, active_idx=0)
    
    img.save(os.path.join(out_dir, 'screenshot_1_discovery.png'), 'PNG', quality=95)
    print("Saved refined screenshot_1_discovery.png")

# ==============================================================================
# SCREENSHOT 2: Gemini AI Compatibility Breakdown
# ==============================================================================
def render_screen2():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    render_header(
        draw,
        "DEEP PSYCHOLOGICAL SYNERGY",
        "Gemini AI Compatibility Radar\n& Values Alignment",
        "Mathematical synergy scoring across faith, communication & lifecycle goals."
    )
    
    px1, py1, px2, py2 = 120, 520, 960, 2340
    draw_phone_shell(draw, px1, py1, px2, py2)
    draw_phone_top_bar(draw, px1, py1, px2)
    
    sx1, sy1, sx2, sy2 = px1 + 8, py1 + 8, px2 - 8, py2 - 8
    
    # App Bar
    draw.text((sx1 + 36, sy1 + 60), "← Compatibility Breakdown", font=font_sans_bold, fill=(245, 230, 200))
    
    cy_box = sy1 + 130
    draw.rounded_rectangle([sx1 + 24, cy_box, sx2 - 24, cy_box + 260], radius=28, fill=(18, 24, 34), outline=(212, 175, 55, 100), width=2)
    
    ring_cx, ring_cy = sx1 + 140, cy_box + 130
    draw.ellipse([ring_cx - 75, ring_cy - 75, ring_cx + 75, ring_cy + 75], fill=(25, 20, 10), outline=(212, 175, 55), width=6)
    draw.text((ring_cx - 48, ring_cy - 36), "96%", font=font_serif_large, fill=(212, 175, 55))
    draw.text((ring_cx - 30, ring_cy + 24), "MATCH", font=font_sans_xs, fill=(180, 190, 200))
    
    draw.text((sx1 + 245, cy_box + 45), "Exceptional Synergy", font=font_serif_med, fill=(255, 255, 255))
    draw.text((sx1 + 245, cy_box + 100), "Dr. Amara Okonkwo & You", font=font_sans_med, fill=(212, 175, 55))
    draw.text((sx1 + 245, cy_box + 145), "High marital readiness, mutual faith,\nand complementary life vision.", font=font_sans_small, fill=(160, 175, 195))
    
    sy_start = cy_box + 290
    dims = [
        ("Faith & Core Values", 98, "Integrity, Permanent Vow, Monogamy"),
        ("Emotional Alignment", 96, "Warmth, Mutual Security & Empathy"),
        ("Communication Style", 95, "Constructive, Transparent, Respectful"),
        ("Lifestyle Compatibility", 94, "Career Harmony & Family Ambition"),
    ]
    
    curr_y = sy_start
    for label, score, detail in dims:
        draw.rounded_rectangle([sx1 + 24, curr_y, sx2 - 24, curr_y + 135], radius=22, fill=(16, 21, 30), outline=(50, 65, 85), width=1)
        draw.text((sx1 + 45, curr_y + 18), label, font=font_sans_bold, fill=(240, 245, 250))
        draw.text((sx2 - 130, curr_y + 18), f"{score}%", font=font_serif_med, fill=(212, 175, 55))
        draw.text((sx1 + 45, curr_y + 60), detail, font=font_sans_xs, fill=(140, 155, 175))
        
        bar_x1, bar_x2 = sx1 + 45, sx2 - 45
        bar_y = curr_y + 98
        draw.rounded_rectangle([bar_x1, bar_y, bar_x2, bar_y + 14], radius=7, fill=(30, 40, 55))
        fill_w = int((bar_x2 - bar_x1) * (score / 100))
        draw.rounded_rectangle([bar_x1, bar_y, bar_x1 + fill_w, bar_y + 14], radius=7, fill=(212, 175, 55))
        
        curr_y += 155
        
    draw.rounded_rectangle([sx1 + 24, curr_y + 10, sx2 - 24, curr_y + 240], radius=24, fill=(20, 26, 38), outline=(212, 175, 55, 120), width=1)
    draw_star(draw, sx1 + 60, curr_y + 40, 10, 4, fill=(212, 175, 55))
    draw.text((sx1 + 80, curr_y + 28), "GEMINI AI MATRIMONIAL VERDICT", font=font_sans_xs, fill=(212, 175, 55))
    narrative = (
        "\"Both profiles demonstrate exemplary dedication to lifelong\n"
        "commitment. Amara's anchor-style emotional grounding pairs\n"
        "effortlessly with your builder-style vision for family and\n"
        "purpose. Recommended for intentional courtship.\""
    )
    draw.text((sx1 + 48, curr_y + 65), narrative, font=font_sans_small, fill=(210, 220, 235))
    
    draw_bottom_nav(draw, sx1, sy1, sx2, sy2, active_idx=1)
    
    img.save(os.path.join(out_dir, 'screenshot_2_compatibility.png'), 'PNG', quality=95)
    print("Saved refined screenshot_2_compatibility.png")

# ==============================================================================
# SCREENSHOT 3: Bank-Grade Identity & Biometric Trust
# ==============================================================================
def render_screen3():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    render_header(
        draw,
        "BANK-GRADE DIDIT AI BIOMETRICS",
        "Zero Catfishing. 100% Real.\nSovereign Trust Registry",
        "Government ID verification & live 3D face liveness for total peace of mind."
    )
    
    px1, py1, px2, py2 = 120, 520, 960, 2340
    draw_phone_shell(draw, px1, py1, px2, py2)
    draw_phone_top_bar(draw, px1, py1, px2)
    
    sx1, sy1, sx2, sy2 = px1 + 8, py1 + 8, px2 - 8, py2 - 8
    
    draw.text((sx1 + 36, sy1 + 60), "Identity & Trust Verification", font=font_sans_bold, fill=(245, 230, 200))
    
    cy_box = sy1 + 130
    draw.rounded_rectangle([sx1 + 24, cy_box, sx2 - 24, cy_box + 300], radius=28, fill=(18, 24, 34), outline=(212, 175, 55, 140), width=2)
    
    # 5 Gold Stars
    for s_i in range(5):
        draw_star(draw, W//2 - 60 + s_i * 30, cy_box + 45, 10, 5, fill=(212, 175, 55))
        
    draw.text((W//2 - 180, cy_box + 85), "TRUST SCORE 98", font=font_serif_large, fill=(255, 255, 255))
    draw.text((W//2 - 160, cy_box + 155), "SOVEREIGN GOLD BADGE", font=font_sans_bold, fill=(212, 175, 55))
    draw.text((W//2 - 230, cy_box + 205), "Fully verified identity, credentials, and matrimonial intent.", font=font_sans_small, fill=(160, 175, 195))
    draw.text((W//2 - 180, cy_box + 245), "Didit AI Biometric Engine Certified", font=font_sans_xs, fill=(100, 180, 120))
    
    items = [
        ("National ID / Int'l Passport Verified", "Bank-grade OCR & government document class checked.", "VERIFIED"),
        ("Live 3D Biometric Liveness", "Active facial movement capture; zero deepfakes permitted.", "CONFIRMED"),
        ("Phone & Identity Registry Crosscheck", "Direct sovereign ledger identity alignment.", "MATCHED"),
        ("Matrimonial Readiness Pledge", "Confirmed single, unattached, seeking lifelong vows.", "COMMITTED"),
    ]
    
    curr_y = cy_box + 335
    for title, desc, tag in items:
        draw.rounded_rectangle([sx1 + 24, curr_y, sx2 - 24, curr_y + 140], radius=22, fill=(16, 21, 30), outline=(50, 65, 85), width=1)
        draw.text((sx1 + 45, curr_y + 22), title, font=font_sans_bold, fill=(240, 245, 250))
        draw.text((sx1 + 45, curr_y + 68), desc, font=font_sans_xs, fill=(140, 155, 175))
        
        tb = font_sans_xs.getbbox(tag)
        tw = tb[2] - tb[0] + 46
        draw.rounded_rectangle([sx2 - 45 - tw, curr_y + 20, sx2 - 45, curr_y + 60], radius=15, fill=(15, 35, 20), outline=(70, 200, 100), width=1)
        draw_check(draw, sx2 - 45 - tw + 18, curr_y + 40, 16, fill=(70, 220, 100), width=2)
        draw.text((sx2 - 45 - tw + 34, curr_y + 27), tag, font=font_sans_xs, fill=(70, 220, 100))
        
        curr_y += 160
        
    draw.rounded_rectangle([sx1 + 24, curr_y + 10, sx2 - 24, curr_y + 190], radius=24, fill=(24, 20, 12), outline=(212, 175, 55, 140), width=1)
    draw_shield(draw, sx1 + 65, curr_y + 45, 24, 28, fill=(212, 175, 55))
    draw.text((sx1 + 90, curr_y + 30), "KNOT SOVEREIGN TRUST GUARANTEE", font=font_sans_bold, fill=(212, 175, 55))
    draw.text((sx1 + 45, curr_y + 75), "Every profile you meet on Knot has passed rigorous ID\nauthentication and live biometric liveness.", font=font_sans_small, fill=(215, 225, 240))
    
    draw_bottom_nav(draw, sx1, sy1, sx2, sy2, active_idx=2)
    
    img.save(os.path.join(out_dir, 'screenshot_3_verification.png'), 'PNG', quality=95)
    print("Saved refined screenshot_3_verification.png")

# ==============================================================================
# SCREENSHOT 4: 24/7 AI Courtship Coach & Relationship Concierge
# ==============================================================================
def render_screen4():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    render_header(
        draw,
        "24/7 RELATIONSHIP CONCIERGE",
        "Your Private AI Courtship Coach\nFrom Spark To Vows",
        "Confidential guidance on meaningful discussions, boundaries, and alignment."
    )
    
    px1, py1, px2, py2 = 120, 520, 960, 2340
    draw_phone_shell(draw, px1, py1, px2, py2)
    draw_phone_top_bar(draw, px1, py1, px2)
    
    sx1, sy1, sx2, sy2 = px1 + 8, py1 + 8, px2 - 8, py2 - 8
    
    # App Bar
    draw_star(draw, sx1 + 55, sy1 + 80, 14, 6, fill=(212, 175, 55))
    draw.text((sx1 + 80, sy1 + 60), "Knot AI Courtship Coach", font=font_sans_bold, fill=(212, 175, 55))
    draw.text((sx2 - 130, sy1 + 65), "Online", font=font_sans_xs, fill=(70, 220, 100))
    
    curr_y = sy1 + 130
    
    # AI Message 1
    m1_box = [sx1 + 24, curr_y, sx2 - 120, curr_y + 190]
    draw.rounded_rectangle(m1_box, radius=24, fill=(20, 26, 38), outline=(212, 175, 55, 80), width=1)
    draw.text((sx1 + 45, curr_y + 20), "KNOT AI COACH", font=font_sans_xs, fill=(212, 175, 55))
    msg1 = (
        "Welcome Emeke. You and Dr. Amara share high faith\n"
        "alignment. Her 'Devoted Anchor' archetype cherishes\n"
        "clarity, emotional safety, and shared family goals.\n"
        "How can I assist your courtship preparation today?"
    )
    draw.text((sx1 + 45, curr_y + 55), msg1, font=font_sans_small, fill=(225, 235, 245))
    
    curr_y += 220
    
    # User Message
    m2_box = [sx1 + 120, curr_y, sx2 - 24, curr_y + 140]
    draw.rounded_rectangle(m2_box, radius=24, fill=(45, 36, 18), outline=(212, 175, 55), width=1)
    draw.text((sx1 + 145, curr_y + 20), "YOU", font=font_sans_xs, fill=(212, 175, 55))
    msg2 = (
        "How should I approach discussing career goals\n"
        "and family relocation in our next conversation?"
    )
    draw.text((sx1 + 145, curr_y + 55), msg2, font=font_sans_small, fill=(255, 255, 255))
    
    curr_y += 170
    
    # AI Message 2
    m3_box = [sx1 + 24, curr_y, sx2 - 100, curr_y + 320]
    draw.rounded_rectangle(m3_box, radius=24, fill=(20, 26, 38), outline=(212, 175, 55, 80), width=1)
    draw.text((sx1 + 45, curr_y + 20), "KNOT AI COACH", font=font_sans_xs, fill=(212, 175, 55))
    msg3 = (
        "Focus on shared long-term horizons rather than\n"
        "logistics first. Frame it as partnership:\n\n"
        "1. Ask what creating an ideal home looks like to her.\n"
        "2. Affirm her medical calling and discuss how both\n"
        "   careers can thrive symbiotically.\n"
        "3. Explore preferred cities with open curiosity."
    )
    draw.text((sx1 + 45, curr_y + 55), msg3, font=font_sans_small, fill=(225, 235, 245))
    
    curr_y += 350
    
    chips = ["Conversation Starters", "Family Vision", "Conflict Harmony"]
    cx = sx1 + 24
    for chip in chips:
        tb = font_sans_xs.getbbox(chip)
        cw = tb[2] - tb[0] + 32
        draw.rounded_rectangle([cx, curr_y, cx + cw, curr_y + 55], radius=27, fill=(26, 34, 48), outline=(212, 175, 55, 120))
        draw.text((cx + 16, curr_y + 14), chip, font=font_sans_xs, fill=(212, 175, 55))
        cx += cw + 16
        
    curr_y += 90
    draw.rounded_rectangle([sx1 + 24, curr_y, sx2 - 24, curr_y + 80], radius=40, fill=(16, 21, 30), outline=(60, 75, 95), width=1)
    draw.text((sx1 + 55, curr_y + 24), "Ask your coach for courtship advice...", font=font_sans_small, fill=(130, 145, 165))
    draw.ellipse([sx2 - 95, curr_y + 10, sx2 - 35, curr_y + 70], fill=(212, 175, 55))
    # Vector Arrow
    arr_cx, arr_cy = sx2 - 65, curr_y + 40
    draw.line([(arr_cx, arr_cy + 12), (arr_cx, arr_cy - 12)], fill=(15, 18, 25), width=3)
    draw.line([(arr_cx - 8, arr_cy - 4), (arr_cx, arr_cy - 12), (arr_cx + 8, arr_cy - 4)], fill=(15, 18, 25), width=3)
    
    draw_bottom_nav(draw, sx1, sy1, sx2, sy2, active_idx=3)
    
    img.save(os.path.join(out_dir, 'screenshot_4_coach.png'), 'PNG', quality=95)
    print("Saved refined screenshot_4_coach.png")

# ==============================================================================
# SCREENSHOT 5: Sovereign Membership Tiers
# ==============================================================================
def render_screen5():
    img = create_base_canvas()
    draw = ImageDraw.Draw(img)
    render_header(
        draw,
        "EXCLUSIVE SOVEREIGN MEMBERSHIP",
        "Transparent Sovereign Tiers\nInvest In Lifelong Marriage",
        "Transparent pricing with global settlement & local currency display."
    )
    
    px1, py1, px2, py2 = 120, 520, 960, 2340
    draw_phone_shell(draw, px1, py1, px2, py2)
    draw_phone_top_bar(draw, px1, py1, px2)
    
    sx1, sy1, sx2, sy2 = px1 + 8, py1 + 8, px2 - 8, py2 - 8
    
    draw.text((sx1 + 36, sy1 + 60), "Knot Sovereign Memberships", font=font_sans_bold, fill=(245, 230, 200))
    
    curr_y = sy1 + 130
    
    # Tier 1: Premium
    t1_box = [sx1 + 24, curr_y, sx2 - 24, curr_y + 250]
    draw.rounded_rectangle(t1_box, radius=24, fill=(16, 21, 30), outline=(50, 65, 85), width=1)
    draw.text((sx1 + 45, curr_y + 20), "PREMIUM TIER", font=font_sans_xs, fill=(150, 165, 185))
    draw.text((sx1 + 45, curr_y + 55), "$14.99 / mo", font=font_serif_med, fill=(255, 255, 255))
    draw.text((sx2 - 250, curr_y + 65), "(or ₦19,200 / $12)", font=font_sans_small, fill=(212, 175, 55))
    draw.text((sx1 + 45, curr_y + 125), "• Unlimited Curated Matches & Discoveries\n• Gemini AI Psychological Radar & Synergy Scoring\n• Verified Sovereign Registry Access", font=font_sans_small, fill=(190, 205, 220))
    
    curr_y += 280
    
    # Tier 2: Elite (Featured Gold Card)
    t2_box = [sx1 + 24, curr_y, sx2 - 24, curr_y + 340]
    draw.rounded_rectangle(t2_box, radius=26, fill=(28, 24, 14), outline=(212, 175, 55), width=3)
    
    # Popular Tag
    pop_pill = [sx2 - 250, curr_y - 18, sx2 - 50, curr_y + 22]
    draw.rounded_rectangle(pop_pill, radius=20, fill=(212, 175, 55))
    draw_star(draw, sx2 - 230, curr_y + 2, 7, 3, fill=(15, 18, 25))
    draw.text((sx2 - 215, curr_y - 10), "MOST POPULAR", font=font_sans_xs, fill=(15, 18, 25))
    
    draw.text((sx1 + 45, curr_y + 24), "ELITE TIER", font=font_sans_xs, fill=(212, 175, 55))
    draw.text((sx1 + 45, curr_y + 62), "$39.99 / mo", font=font_serif_large, fill=(255, 255, 255))
    draw.text((sx2 - 275, curr_y + 75), "(or ₦40,000 / $25 Africa)", font=font_sans_small, fill=(212, 175, 55))
    draw.text((sx1 + 45, curr_y + 145), "• Everything in Premium Included\n• Unlimited 24/7 AI Courtship Coach & Prompts\n• Sovereign Gold Verification Priority Badge\n• Direct Connect & Read Status Notifications", font=font_sans_small, fill=(245, 235, 215))
    
    curr_y += 370
    
    # Tier 3: Executive
    t3_box = [sx1 + 24, curr_y, sx2 - 24, curr_y + 250]
    draw.rounded_rectangle(t3_box, radius=24, fill=(16, 21, 30), outline=(50, 65, 85), width=1)
    draw.text((sx1 + 45, curr_y + 20), "EXECUTIVE TIER", font=font_sans_xs, fill=(150, 165, 185))
    draw.text((sx1 + 45, curr_y + 55), "$199.00 / mo", font=font_serif_med, fill=(255, 255, 255))
    draw.text((sx1 + 45, curr_y + 125), "• Dedicated Private Matrimonial Matchmaker\n• VIP Concierge & Direct Executive Intros\n• Bespoke Background & Credential Vetting", font=font_sans_small, fill=(190, 205, 220))
    
    curr_y += 280
    
    # Subscribe Gold Button
    btn_box = [sx1 + 36, curr_y, sx2 - 36, curr_y + 80]
    draw.rounded_rectangle(btn_box, radius=40, fill=(212, 175, 55))
    b_txt = "SUBSCRIBE VIA GOOGLE PLAY"
    bb = font_sans_bold.getbbox(b_txt)
    draw.text(((W - (bb[2] - bb[0])) // 2, curr_y + 20), b_txt, font=font_sans_bold, fill=(15, 18, 25))
    
    # Footnote
    draw.text((W//2 - 210, curr_y + 105), "Secure checkout processed via Google Play Store subscriptions.\nBilled in USD or local currency equivalent.", font=font_sans_xs, fill=(130, 145, 165))
    
    draw_bottom_nav(draw, sx1, sy1, sx2, sy2, active_idx=4)
    
    img.save(os.path.join(out_dir, 'screenshot_5_pricing.png'), 'PNG', quality=95)
    print("Saved refined screenshot_5_pricing.png")

if __name__ == '__main__':
    render_screen1()
    render_screen2()
    render_screen3()
    render_screen4()
    render_screen5()
    print('All 5 refined showcase screenshots re-rendered successfully!')
