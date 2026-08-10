import math

print("Generowanie logo z szerokimi, pochylonymi literami i gradientem...")

# Paleta sprzętowa
BG = 'F'       # Magenta (Przezroczysty)
OUTLINE = '0'  # Black (Obrys)
SHADOW = '1'   # Dark Gray (Głęboki cień 3D)
FIRE_Y = '7'   # Yellow 
FIRE_O = '8'   # Orange 
FIRE_R = '5'   # Red 

# Gradient inspirowany "SPEED RACE" 
# Każdy z 7 bazowych wierszy czcionki dostaje swój własny kolor!
# Od góry: Jasnoniebieski(B), Jasnoniebieski(B), Biały(4), Biały(4), Czerwony(5), Pomarańczowy(8), Żółty(7)
TEXT_GRADIENT = ['B', 'B', '4', '4', '5', '8', '7']

# Nowa, kanciasta czcionka zaprojektowana specjalnie pod rozciąganie
font = {
    'P': ["1110", "1001", "1001", "1110", "1000", "1000", "1000"],
    'I': ["111", "010", "010", "010", "010", "010", "111"],
    'T': ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    'S': ["0111", "1000", "1000", "0110", "0001", "0001", "1110"],
    'O': ["0110", "1001", "1001", "1001", "1001", "1001", "0110"],
    ' ': ["00", "00", "00", "00", "00", "00", "00"]
}

W = 128
H = 32
FRAMES = 4

# Skalowanie asymetryczne (Litery 3 razy szersze, ale tylko 2 razy wyższe)
SCALE_X = 3   
SCALE_Y = 2   
START_X = 6
START_Y = 12

frames = [[[BG for _ in range(W)] for _ in range(H)] for _ in range(FRAMES)]

for f in range(FRAMES):
    # 1. Rysowanie szerokich, pochylonych liter (Italic) + Gradient
    cx = START_X
    for char in "PIT STOP":
        pattern = font[char]
        char_w = len(pattern[0])
        for py in range(7):
            # Prosta matematyka pochylenia: im wyżej (mniejsze py), tym bardziej ucieka w prawo
            slant = 6 - py 
            color = TEXT_GRADIENT[py]
            for px in range(char_w):
                if pattern[py][px] == '1':
                    for dy in range(SCALE_Y):
                        for dx in range(SCALE_X):
                            draw_x = cx + px * SCALE_X + dx + slant
                            draw_y = START_Y + py * SCALE_Y + dy
                            if 0 <= draw_x < W and 0 <= draw_y < H:
                                frames[f][draw_y][draw_x] = color
        cx += (char_w * SCALE_X) + (1 * SCALE_X)

    # 2. Dodawanie cienia 3D (skierowanego w dół, jak na obrazku referencyjnym)
    for y in range(H-3, -1, -1):
        for x in range(W):
            if frames[f][y][x] in TEXT_GRADIENT and frames[f][y+1][x] == BG:
                frames[f][y+1][x] = SHADOW
                frames[f][y+2][x] = SHADOW

    # 3. Czarny obrys dookoła liter i cienia
    temp = [row[:] for row in frames[f]]
    for y in range(1, H-1):
        for x in range(1, W-1):
            if temp[y][x] == BG:
                is_near = any(temp[ny][nx] in TEXT_GRADIENT + [SHADOW] for ny, nx in 
                              [(y-1,x), (y+1,x), (y,x-1), (y,x+1), (y-1,x-1), (y-1,x+1), (y+1,x-1), (y+1,x+1)])
                if is_near:
                    frames[f][y][x] = OUTLINE
                    
    # 4. Generowanie animowanego ognia (nasłuchującego na wszystkie kolory liter)
    for x in range(W):
        top_y = -1
        for y in range(H):
            if frames[f][y][x] in TEXT_GRADIENT or frames[f][y][x] == OUTLINE:
                top_y = y
                break
        
        if 4 < top_y < H: 
            angle = f * math.pi / 2.0
            fire_h = 4.5 + 2.5 * math.sin(x * 0.35 + angle) + 1.5 * math.cos(x * 0.7 - angle)
            
            for y in range(top_y - 1, 0, -1):
                dist = top_y - y
                gap = math.sin(x * 0.5 - y * 0.8 + angle)
                adjusted_h = fire_h
                if gap > 0.6: 
                    adjusted_h -= 2.0
                    
                if dist <= adjusted_h:
                    if dist <= adjusted_h * 0.3: frames[f][y][x] = FIRE_Y
                    elif dist <= adjusted_h * 0.6: frames[f][y][x] = FIRE_O
                    else: frames[f][y][x] = FIRE_R
                        
                if dist == int(adjusted_h) + 1 and gap > 0.8 and y > 0:
                    frames[f][y-1][x] = FIRE_R

# 5. Eksport
with open("pitstop_logo.mem", "w") as file:
    for f in range(FRAMES):
        for y in range(H):
            for x in range(W):
                file.write(f"0{frames[f][y][x]}\n")

print("Gotowe! Zapisano animowane logo do pitstop_logo.mem.")