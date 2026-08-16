# pit-stop

Gra VGA dla Basys 3 z obsluga myszy PS/2.

## Opcje gry

Ekran `OPTS` pokazuje ustawienia odczytywane na zywo ze switchy Basys 3:

| Switche | Znaczenie |
| --- | --- |
| `SW15` | `0` single-player, `1` multiplayer |
| `SW14:13` | `00` time attack, `01` point race, `10` speed up, `11` best of |
| `SW7:0` | binarna wartosc celu od 1 do 255; `0` jest wyswietlane jako `1` |
| `SW12:8` | wolne na kolejne ustawienia |

`TIME ATTACK` oznacza najwiecej punktow w zadanym czasie, `POINT RACE`
pierwszego gracza do zadanej liczby punktow, a `SPEED UP` coraz krotszy limit
czasu na pit stop. Czwarty tryb `BEST OF` jest przewidziany jako zadana liczba
pit stopow, po ktorych wygrywa nizszy laczny czas.

Wartosc celu jest jednoczesnie pokazywana na wyswietlaczu 7-segmentowym.
Tryb multiplayer pokazuje obecnie `UART OFFLINE`: wybor opcji jest gotowy,
ale lacznosc UART i reguly punktowania beda dodane jako osobny etap.

## Przebieg gry

1. W menu bolid przejezdza przez ekran bez zatrzymywania.
2. Po wybraniu `PLAY` bolid wjezdza od prawej strony i lagodnie hamuje.
3. Oba kola nalezy odkrecic rolka myszy skierowana w dol.
4. Odblokowane kola mozna chwycic lewym przyciskiem i wyrzucic poza ekran.
5. Po kliknieciu wheelracka pojawia sie nowe kolo. Nalezy przeniesc je w
   poblize dowolnej wolnej piasty, puscic przycisk i dokrecic rolka w gore.
6. Po dokreceniu obu kol bolid przyspiesza i odjezdza, a kolejny wjezdza
   automatycznie.

Kola mozna obslugiwac w dowolnej kolejnosci, odkladac na asfalt i ponownie
podnosic. Nowe kola sa wymienne i nie sa przypisane do konkretnej piasty.

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

W symulatorze fizyczne switche maja wygodne odpowiedniki na klawiaturze:

| Klawisz | Dzialanie |
| --- | --- |
| `P` | przelacza single-player / multiplayer (`SW15`) |
| `1`...`4` | wybiera tryb gry (`SW14:13`) |
| `+`, `-` lub strzalki | zmienia cel o 1 (`SW7:0`) |
| `Page Up`, `Page Down` | zmienia cel o 10 |

Symulator startuje z ustawieniem single-player, time attack i celem `60`.

Bitstream (po zaladowaniu srodowiska Vivado):

```bash
source env.sh
./tools/generate_bitstream.sh
```

Plik `results/top_vga_basys3.bit` dolaczony do repozytorium pochodzi z
poprzedniego buildu. Po zmianach logiki trzeba wygenerowac go ponownie.
