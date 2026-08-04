import os
try:
    from PIL import Image
except ImportError:
    print("Błąd: Biblioteka Pillow nie jest zainstalowana.")
    print("Wpisz w terminalu: pip install Pillow")
    exit()

print("Wczytywanie pliku pitstop_logo.mem...")

# Konfiguracja (musi być zgodna z generatorem)
W = 128
H = 32
FRAMES = 4
SCALE = 4  # Skalujemy x4, żeby GIF nie był mikroskopijny (wyjdzie 512x128)

# Mapowanie Twoich kodów 4-bitowych na 24-bitowe kolory RGB (R, G, B)
palette = {
    'F': (255, 0, 255),    # Magenta
    '4': (255, 255, 255),  # Biały
    '1': (51, 51, 51),     # Ciemnoszary (Głęboki cień)
    '0': (0, 0, 0),        # Czarny
    '7': (255, 255, 0),    # Żółty
    '8': (255, 136, 0),    # Pomarańczowy
    '5': (255, 0, 0),      # Czerwony
    'B': (0, 170, 255)     # Jasnoniebieski
}

# Odczyt pliku .mem
try:
    with open("pitstop_logo.mem", "r") as file:
        lines = [line.strip() for line in file.readlines()]
except FileNotFoundError:
    print("Błąd: Nie znaleziono pliku pitstop_logo.mem!")
    exit()

# Generowanie klatek
images = []
line_idx = 0

for f in range(FRAMES):
    # Tworzymy pusty obraz RGB
    img = Image.new("RGB", (W, H))
    pixels = img.load()
    
    for y in range(H):
        for x in range(W):
            # Pobieramy zapis (np. "0F", "04") i bierzemy drugi znak
            hex_val = lines[line_idx][1].upper()
            
            # Kolorujemy piksel używając słownika (domyślnie czarny, jeśli błąd)
            pixels[x, y] = palette.get(hex_val, (0, 0, 0))
            line_idx += 1
            
    # Skalujemy klatkę (Nearest Neighbor zapobiega rozmyciu pikseli!)
    img_scaled = img.resize((W * SCALE, H * SCALE), Image.Resampling.NEAREST)
    images.append(img_scaled)

# Zapis do animowanego pliku GIF
output_filename = "pitstop_preview.gif"
images[0].save(
    output_filename,
    save_all=True,
    append_images=images[1:],
    optimize=False,
    duration=150,  # Czas trwania jednej klatki w milisekundach (150ms to ok. 6 FPS)
    loop=0         # 0 oznacza nieskończone zapętlenie
)

print(f"Sukces! Animacja została zapisana jako {output_filename}.")