#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("Błąd: Biblioteka Pillow nie jest zainstalowana.")
    sys.exit(1)

# Nasza "Złota Paleta Pit Stop F1" w formacie 12-bit HEX zdefiniowana na sztywno
F1_PALETTE_HEX = [
    "000", "333", "777", "CCC", "FFF", "F00", "900", "FF0", 
    "F80", "0B0", "03A", "0AF", "FCA", "631", "F0A", "F0F"
]

def hex12_to_rgb8(hex_str):
    """Zamienia kolor 12-bit (np. F0A) na standardowe wartości RGB (0-255)."""
    r = int(hex_str[0], 16) * 17
    g = int(hex_str[1], 16) * 17
    b = int(hex_str[2], 16) * 17
    return r, g, b

def apply_fixed_palette(input_path, output_dir):
    # Bezpieczne rozwinięcie ścieżek
    safe_input_path = os.path.abspath(os.path.expanduser(input_path))
    safe_output_dir = os.path.abspath(os.path.expanduser(output_dir))

    if not os.path.exists(safe_input_path):
        print(f"Błąd: Plik '{safe_input_path}' nie istnieje.")
        sys.exit(1)
        
    print(f"Przetwarzanie: {safe_input_path}")
    
    # 1. Wczytanie obrazu oryginalnego
    img = Image.open(safe_input_path)
    
    # 2. Obsługa przezroczystości (zastąpienie przezroczystych pikseli magentą)
    # Sprawdzamy, czy obraz ma kanał alfa (RGBA, LA) lub przezroczystość w palecie
    if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
        img = img.convert('RGBA')
        # Tworzymy nowe tło wypełnione Magentą (255, 0, 255) z pełnym kryciem (255)
        # Ten kolor zostanie zmapowany na 'F0F' w naszej palecie
        magenta_bg = Image.new('RGBA', img.size, (255, 0, 255, 255))
        # Kładziemy obraz z przezroczystością na magentowe tło
        img = Image.alpha_composite(magenta_bg, img)
        
    # Teraz możemy bezpiecznie wymusić RGB
    img = img.convert('RGB')
    
    width, height = img.size
    
    # Utworzenie płaskiej listy kolorów RGB dla palety PIL
    flat_palette = []
    for color in F1_PALETTE_HEX:
        r, g, b = hex12_to_rgb8(color)
        flat_palette.extend([r, g, b])
        
    # Dopełnienie do 256 kolorów
    flat_palette.extend([0] * (256 * 3 - len(flat_palette)))
    
    pal_img = Image.new('P', (1, 1))
    pal_img.putpalette(flat_palette)
    
    # Kwantyzacja (mapowanie kolorów na naszą paletę)
    img_indexed = img.quantize(palette=pal_img, dither=0)
    
    # Przygotowanie katalogu i ścieżek wyjściowych
    os.makedirs(safe_output_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(safe_input_path))[0]
    
    pal_filename = os.path.join(safe_output_dir, f"{base_name}_paleta.mem")
    sprite_filename = os.path.join(safe_output_dir, f"{base_name}_sprite.mem")
    
    # Zapis palety
    with open(pal_filename, 'w') as f:
        f.write("// LUT wygenerowany dla projektu (Stala paleta F1)\n")
        for color in F1_PALETTE_HEX:
            f.write(f"{color}\n")
            
    # Zapis pikseli
    pixels = list(img_indexed.getdata())
    with open(sprite_filename, 'w') as f:
        f.write(f"// Dane sprite'a ({width}x{height})\n")
        for y in range(height):
            row = pixels[y*width : (y+1)*width]
            # Używamy dużej litery dla HEX formatu
            hex_row = [f"{p:01X}" for p in row]
            f.write(" ".join(hex_row) + "\n")
            
    print(f"[*] Wygenerowano LUT: {pal_filename}")
    print(f"[*] Wygenerowano Sprite: {sprite_filename}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Wymuszanie stałej palety 16-kolorów na pliku graficznym PNG. Przezroczystość zamieniana na magentę (F0F).")
    parser.add_argument("-i", "--input", required=True, help="Ścieżka do pliku wejściowego PNG")
    parser.add_argument("-o", "--out_dir", required=True, help="Katalog docelowy dla plików .mem")
    
    args = parser.parse_args()
    apply_fixed_palette(args.input, args.out_dir)