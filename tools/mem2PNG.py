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

def hex12_to_rgb8(hex_str):
    """Konwertuje 12-bitowy kolor HEX na krotkę RGB (0-255)."""
    r = int(hex_str[0], 16) * 17
    g = int(hex_str[1], 16) * 17
    b = int(hex_str[2], 16) * 17
    return (r, g, b)

def reconstruct_image(sprite_path, palette_path, output_dir):
    # Bezpieczne rozwinięcie ścieżek
    safe_sprite = os.path.abspath(os.path.expanduser(sprite_path))
    safe_palette = os.path.abspath(os.path.expanduser(palette_path))
    safe_output_dir = os.path.abspath(os.path.expanduser(output_dir))

    # Odczyt palety
    palette = []
    if not os.path.exists(safe_palette):
        print(f"Błąd: Nie znaleziono pliku palety: {safe_palette}")
        return

    with open(safe_palette, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith("//") or not line:
                continue
            palette.append(hex12_to_rgb8(line))

    print(f"[*] Wczytano {len(palette)} kolorów z palety.")

    # Odczyt danych sprite'a
    if not os.path.exists(safe_sprite):
        print(f"Błąd: Nie znaleziono pliku sprite: {safe_sprite}")
        return

    pixels_indices = []
    width = 0
    height = 0

    with open(safe_sprite, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith("//") or not line:
                continue
            
            row = line.split()
            if width == 0:
                width = len(row)
            
            pixels_indices.extend([int(x, 16) for x in row])
            height += 1

    print(f"[*] Wykryto wymiary obrazu: {width}x{height}")

    # Rekonstrukcja obrazu
    rgb_data = []
    for idx in pixels_indices:
        if idx < len(palette):
            rgb_data.append(palette[idx])
        else:
            rgb_data.append((255, 0, 255))

    img = Image.new('RGB', (width, height))
    img.putdata(rgb_data)

    # Zapis w wybranym folderze
    os.makedirs(safe_output_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(safe_sprite))[0]
    
    if base_name.endswith('_sprite'):
        base_name = base_name[:-7]
        
    output_name = os.path.join(safe_output_dir, f"{base_name}_podglad.png")
    
    img.save(output_name, "PNG")
    print(f"[*] Sukces! Podgląd zapisany w: {output_name}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rekonstrukcja pliku PNG z plików .mem.")
    parser.add_argument("-s", "--sprite", required=True, help="Ścieżka do pliku z pikselami .mem")
    parser.add_argument("-p", "--palette", required=True, help="Ścieżka do pliku z paletą .mem")
    parser.add_argument("-o", "--out_dir", required=True, help="Katalog docelowy dla wygenerowanego pliku PNG")
    
    args = parser.parse_args()
    reconstruct_image(args.sprite, args.palette, args.out_dir)