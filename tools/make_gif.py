import glob
import os
from PIL import Image

def create_gif_from_tiffs():
    # Ścieżka do folderu z wynikami symulacji
    # Zakładamy, że skrypt uruchamiasz z folderu pit-stop/tools/
    results_dir = "../results/"
    
    # Znajdź wszystkie pliki TIFF i posortuj je alfabetycznie (frame000, frame001...)
    search_pattern = os.path.join(results_dir, "frame*.tif")
    tiff_files = sorted(glob.glob(search_pattern))
    
    if not tiff_files:
        print("Nie znaleziono żadnych klatek (.tif) w folderze results/")
        return

    print(f"Znaleziono {len(tiff_files)} klatek. Generowanie GIFa...")

    # Załaduj obrazy do pamięci
    frames = []
    for file in tiff_files:
        img = Image.open(file)
        frames.append(img)

    # Zapisz jako GIF
    output_path = os.path.join(results_dir, "simulation_preview.gif")
    
    # duration=250 oznacza 250ms na klatkę, dzięki czemu dokładnie zobaczysz 
    # każdy etap animacji. loop=0 oznacza nieskończone zapętlenie.
    frames[0].save(
        output_path,
        format='GIF',
        append_images=frames[1:],
        save_all=True,
        duration=250, 
        loop=0
    )

    print(f"Gotowe! GIF został zapisany jako: {output_path}")

if __name__ == "__main__":
    create_gif_from_tiffs()