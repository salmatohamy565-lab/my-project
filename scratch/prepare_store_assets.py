from PIL import Image, ImageOps
import os

source_logo = r"C:\Users\bolad\.gemini\antigravity-ide\brain\0d8614b7-9b6f-410e-9986-ef88c43a2fc0\.user_uploaded\media_1788017051872.jpg"
output_dir = r"c:\Users\bolad\Desktop\bola app"

if os.path.exists(source_logo):
    img = Image.open(source_logo).convert('RGBA')

    # 1. Prepare 512x512 App Icon
    icon = Image.new('RGBA', (512, 512), (255, 255, 255, 255))
    # Resize preserving aspect ratio
    img_icon = img.copy()
    img_icon.thumbnail((460, 460), Image.Resampling.LANCZOS)
    x = (512 - img_icon.width) // 2
    y = (512 - img_icon.height) // 2
    icon.paste(img_icon, (x, y), img_icon)
    icon_path = os.path.join(output_dir, "store_icon_512.png")
    icon.convert('RGB').save(icon_path, 'PNG')
    print("Saved 512x512 icon:", icon_path)

    # 2. Prepare 1024x500 Feature Graphic
    fg = Image.new('RGBA', (1024, 500), (255, 255, 255, 255))
    img_fg = img.copy()
    img_fg.thumbnail((880, 440), Image.Resampling.LANCZOS)
    x_fg = (1024 - img_fg.width) // 2
    y_fg = (500 - img_fg.height) // 2
    fg.paste(img_fg, (x_fg, y_fg), img_fg)
    fg_path = os.path.join(output_dir, "store_feature_graphic_1024x500.png")
    fg.convert('RGB').save(fg_path, 'PNG')
    print("Saved 1024x500 Feature Graphic:", fg_path)
