import urllib.request
from PIL import Image, ImageDraw, ImageColor
import os

def main():
    icon_path = 'assets/icon.png'
    size = 1024
    
    # 1. Background gradient
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)
    color1 = (0, 196, 204)
    color2 = (224, 169, 165)
    for y in range(size):
        for x in range(size):
            dist = (x + y) / (2 * size)
            r = int(color1[0] * (1 - dist) + color2[0] * dist)
            g = int(color1[1] * (1 - dist) + color2[1] * dist)
            b = int(color1[2] * (1 - dist) + color2[2] * dist)
            draw.point((x, y), fill=(r, g, b))
    
    # 2. Try better URL
    try:
        url = "https://raw.githubusercontent.com/google/material-design-icons/73420eb4/png/action/fingerprint/materialicons/48dp/2x/baseline_fingerprint_white_48dp.png"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        icon_data = urllib.request.urlopen(req).read()
        
        with open('temp_fp_v2.png', 'wb') as f:
            f.write(icon_data)
            
        fp_img = Image.open('temp_fp_v2.png').convert("RGBA")
        fp_img = fp_img.resize((600, 600), Image.Resampling.LANCZOS)
        
        offset = ((size - 600) // 2, (size - 600) // 2)
        img.paste(fp_img, offset, fp_img)
        os.remove('temp_fp_v2.png')
        print("Success fetching fingerprint!")
    except Exception as e:
        print(f"Still failed, keeping P: {e}")
        draw = ImageDraw.Draw(img)
        draw.text((size//2 - 150, size//2 - 200), "P", fill=(255, 255, 255), font_size=400)

    img.save(icon_path, 'PNG')

if __name__ == '__main__':
    main()
