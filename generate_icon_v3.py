import urllib.request
from PIL import Image, ImageDraw
import os

def main():
    icon_path = 'assets/icon.png'
    size = 1024
    
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
    
    try:
        url = "https://img.icons8.com/ios-filled/600/ffffff/fingerprint.png"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        icon_data = urllib.request.urlopen(req).read()
        
        with open('temp_fp_v3.png', 'wb') as f:
            f.write(icon_data)
            
        fp_img = Image.open('temp_fp_v3.png').convert("RGBA")
        
        offset = ((size - fp_img.width) // 2, (size - fp_img.height) // 2)
        img.paste(fp_img, offset, fp_img)
        os.remove('temp_fp_v3.png')
        print("Success fetching fingerprint!")
    except Exception as e:
        print(f"Failed again: {e}")

    img.save(icon_path, 'PNG')

if __name__ == '__main__':
    main()
