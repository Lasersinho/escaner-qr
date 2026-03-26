import argparse
import urllib.request
import math
import os
from PIL import Image, ImageDraw

def create_gradient_square(size, color1, color2):
    image = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(image)

    for y in range(size):
        for x in range(size):
            dist = (x + y) / (2 * size)
            r = int(color1[0] * (1 - dist) + color2[0] * dist)
            g = int(color1[1] * (1 - dist) + color2[1] * dist)
            b = int(color1[2] * (1 - dist) + color2[2] * dist)
            draw.point((x, y), fill=(r, g, b))
    return image

def main():
    os.makedirs('assets', exist_ok=True)
    icon_path = 'assets/icon.png'
    
    size = 1024
    # AppColors: primary (0x00C4CC) to secondary (0xE0A9A5)
    img = create_gradient_square(size, (0, 196, 204), (224, 169, 165))
    
    # Try fetching a high-res fingerprint icon in white (or draw 'Pulse' 'P' fallback)
    try:
        url = "https://raw.githubusercontent.com/google/material-design-icons/master/png/action/fingerprint/materialicons/48dp/2x/baseline_fingerprint_white_48dp.png"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        icon_data = urllib.request.urlopen(req).read()
        
        with open('temp_fp.png', 'wb') as f:
            f.write(icon_data)
            
        fp_img = Image.open('temp_fp.png').convert("RGBA")
        # Scale up to 600x600 for a 1024x1024 canvas
        fp_img = fp_img.resize((600, 600), Image.Resampling.LANCZOS)
        
        # Calculate centering
        offset = ((size - 600) // 2, (size - 600) // 2)
        img.paste(fp_img, offset, fp_img)
        os.remove('temp_fp.png')
    except Exception as e:
        print(f"Fallback to drawing P: {e}")
        # Draw a big P
        draw = ImageDraw.Draw(img)
        draw.text((size//2 - 150, size//2 - 200), "P", fill=(255, 255, 255), font_size=400)

    img.save(icon_path, 'PNG')
    print(f"Icon generated at {icon_path}")

if __name__ == '__main__':
    main()
