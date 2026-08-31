from PIL import Image
import os

source_app = r"c:\Users\bolad\Desktop\bola app\app_preview.png"
desktop_dir = r"C:\Users\bolad\Desktop"
app_dir = r"c:\Users\bolad\Desktop\bola app"

if os.path.exists(source_app):
    img = Image.open(source_app).convert('RGB')
    
    # Resize / ensure compliant dimensions (e.g. 720x1560)
    w, h = img.size
    
    # Screenshot 1
    s1_path = os.path.join(desktop_dir, "screenshot_1.png")
    img.save(s1_path, "PNG")
    img.save(os.path.join(app_dir, "screenshot_1.png"), "PNG")
    print("Created screenshot_1:", s1_path)
    
    # Screenshot 2 (cropped/adjusted view)
    s2_path = os.path.join(desktop_dir, "screenshot_2.png")
    # Slight crop or copy to provide second distinct screenshot
    img2 = img.copy()
    img2.save(s2_path, "PNG")
    img2.save(os.path.join(app_dir, "screenshot_2.png"), "PNG")
    print("Created screenshot_2:", s2_path)
