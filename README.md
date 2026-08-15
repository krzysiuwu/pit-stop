# pit-stop

Gra VGA dla Basys 3 z obsluga myszy PS/2.

## Przebieg gry

1. W menu bolid przejezdza przez ekran bez zatrzymywania.
2. Po wybraniu `PLAY` bolid wjezdza od prawej strony i lagodnie hamuje.
3. Oba kola nalezy odkrecic rolka myszy skierowana w dol.
4. Odblokowane kola mozna chwycic lewym przyciskiem i wyrzucic poza ekran.
5. Po kliknieciu wheelracka pojawia sie nowe kolo. Nalezy przeniesc je w
   poblize odpowiedniej piasty, puscic przycisk i dokrecic rolka w gore.
6. Po dokreceniu obu kol bolid przyspiesza i odjezdza, a kolejny wjezdza
   automatycznie.

Kola mozna obslugiwac w dowolnej kolejnosci. Jesli oba czekaja na zamiennik,
wheelrack najpierw wydaje kolo dla stanowiska, ktore zostalo oproznione jako
pierwsze.

## Architektura

- `rtl/Game_logic/system_fsm.sv` steruje ekranami i sekwencja rundy.
- `rtl/Game_logic/Sprite_control/bolid_anim_ctl.sv` odpowiada za ruch bolidu.
- `wheel_service_fsm.sv` realizuje cykl stare/nowe kolo, a
  `wheel_physics.sv` odpowiada tylko za przeciaganie i rzut.
- `rtl/pit_stop_core.sv` laczy logike z potokiem renderowania.
- `top_fsm.sv` jest cienka warstwa sprzetowa dla myszy PS/2.

## Uruchomienie

Interaktywny symulator SDL:

```bash
./tools/build_interactive.sh
./obj_dir/Vtop_interactive
```

Bitstream (po zaladowaniu srodowiska Vivado):

```bash
source env.sh
./tools/generate_bitstream.sh
```

Plik `results/top_vga_basys3.bit` dolaczony do repozytorium pochodzi z
poprzedniego buildu. Po zmianach logiki trzeba wygenerowac go ponownie.
