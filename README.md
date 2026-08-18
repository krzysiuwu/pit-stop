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

`TIME ATTACK` zlicza ukonczone pit-stopy przez zadana liczbe sekund. Gracz
wygrywa, jezeli zdobedzie przynajmniej jeden punkt. `POINT RACE` konczy sie po
osiagnieciu zadanej liczby punktow. `SPEED UP` rozpoczyna od ustawionego limitu
sekund, zmniejsza go o sekunde po kazdej wymianie i wymaga pieciu udanych rund.
`BEST OF` konczy sie po zadanej liczbie pit-stopow i pokazuje laczny, ostatni
oraz najlepszy czas.

Poza rozgrywka wyswietlacz 7-segmentowy pokazuje ustawiony cel. Podczas gry
pokazuje pozostaly czas w `TIME ATTACK` i `SPEED UP` albo aktualny wynik w
`POINT RACE` i `BEST OF`. Na ekranie koncowym pokazuje wynik.
Tryb multiplayer pokazuje obecnie `UART OFFLINE`: wybor opcji jest gotowy,
ale lacznosc UART i reguly punktowania beda dodane jako osobny etap.

## Przebieg gry

1. W menu bolid przejezdza przez ekran bez zatrzymywania.
2. Po wybraniu `PLAY` bolid wjezdza od prawej strony i lagodnie hamuje.
3. Oba kola nalezy odkrecic rolka myszy skierowana w dol.
4. Odblokowane kola mozna chwycic lewym przyciskiem i wyrzucic poza ekran.
5. Po kliknieciu wheelracka pojawia sie nowe kolo. Nalezy przeniesc je w
   poblize dowolnej wolnej piasty, puscic przycisk i dokrecic rolka w gore.
6. Po dokreceniu obu kol naliczany jest punkt, bolid odjezdza, a jezeli warunek
   konca nie zostal osiagniety, kolejny wjezdza automatycznie.
7. Po zakonczeniu rozgrywki pojawia sie wynik, czas ostatniej wymiany, najlepszy
   czas i przycisk powrotu do menu. Przycisk `BACK` nie przerywa aktywnej gry.

Kola mozna obslugiwac w dowolnej kolejnosci, odkladac na asfalt i ponownie
podnosic. Nowe kola sa wymienne i nie sa przypisane do konkretnej piasty.

## Architektura

- `rtl/Game_logic/system_fsm.sv` steruje ekranami i sekwencja rundy.
- `rtl/Game_logic/singleplayer_game_controller.sv` przechowuje ustawienia
  aktywnej gry, liczy czas, punkty i warunki zwyciestwa.
- `rtl/Game_logic/Sprite_control/bolid_anim_ctl.sv` odpowiada za ruch bolidu.
- `wheel_service_fsm.sv` realizuje cykl stare/nowe kolo, a
  `wheel_physics.sv` odpowiada tylko za przeciaganie i rzut.
- `rtl/pit_stop_core.sv` laczy logike z potokiem renderowania.
- `top_fsm.sv` jest cienka warstwa sprzetowa dla myszy PS/2.

## Uruchomienie

Interaktywny symulator SDL:

```bash
./tools/build_interactive.sh
```

Skrypt wypisuje sciezke do gotowego programu. Standardowo jest to
`obj_dir/interactive_sdl/Vtop_interactive`, a w MSYS2 z GCC 16:
`obj_dir/interactive_sdl_msys2_abi0/Vtop_interactive.exe`.

W symulatorze fizyczne switche maja wygodne odpowiedniki na klawiaturze:

| Klawisz | Dzialanie |
| --- | --- |
| `P` | przelacza single-player / multiplayer (`SW15`) |
| `1`...`4` | wybiera tryb gry (`SW14:13`) |
| `+`, `-` lub strzalki | zmienia cel o 1 (`SW7:0`) |
| `Page Up`, `Page Down` | zmienia cel o 10 |

Symulator startuje z ustawieniem single-player, time attack i celem `60`.
Aktualna wartosc wyswietlacza 7-segmentowego jest widoczna w tytule okna.

Test logiki trybow gry:

```bash
./tools/test_game_controller.sh
```

Skrypty automatycznie wykrywaja MSYS2 UCRT64/MINGW z GCC 16 i wlaczaja zgodne
ABI `libstdc++`. Zapobiega to bledom linkera z symbolami
`std::__cxx11::basic_string`; katalog kompilacji dla tego wariantu jest osobny,
wiec nie trzeba recznie usuwac poprzedniego `obj_dir/game_controller`.

Bitstream (po zaladowaniu srodowiska Vivado):

```bash
source env.sh
./tools/generate_bitstream.sh
```

Plik `results/top_vga_basys3.bit` dolaczony do repozytorium pochodzi z
poprzedniego buildu. Po zmianach logiki trzeba wygenerowac go ponownie.
