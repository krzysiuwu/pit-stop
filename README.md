# pit-stop

Gra VGA dla Basys 3 z obsluga myszy PS/2.

## Opcje gry

Ekran `OPTS` pokazuje ustawienia odczytywane na zywo ze switchy Basys 3:

| Switche | Znaczenie |
| --- | --- |
| `SW15` | `0` single-player, `1` multiplayer |
| `SW14:13` | `00` time attack, `01` point race, `10` speed up, `11` best of |
| `SW12` | sprzetowy tryb testowy UART |
| `SW7:0` | binarna wartosc celu od 1 do 255; `0` jest wyswietlane jako `1` |
| `SW11:8` | wolne na kolejne ustawienia |

`TIME ATTACK` zlicza ukonczone pit-stopy przez zadana liczbe sekund. Gracz
wygrywa, jezeli zdobedzie przynajmniej jeden punkt. `POINT RACE` konczy sie po
osiagnieciu zadanej liczby punktow. `SPEED UP` rozpoczyna od ustawionego limitu
sekund, zmniejsza go o sekunde po kazdej wymianie i wymaga pieciu udanych rund.
`BEST OF` konczy sie po zadanej liczbie pit-stopow i pokazuje laczny, ostatni
oraz najlepszy czas.

Poza rozgrywka wyswietlacz 7-segmentowy pokazuje ustawiony cel. W trybie
testowym UART pokazuje wartosc odebrana z drugiego Basysa. Podczas gry
pokazuje pozostaly czas w `TIME ATTACK` i `SPEED UP` albo aktualny wynik w
`POINT RACE` i `BEST OF`. Na ekranie koncowym pokazuje wynik.

## Multiplayer UART

Oba Basysy uzywaja dokladnie tego samego bitstreamu. Lacze pracuje jako
`115200 8N1`. Plytki okresowo wysylaja ramki z suma kontrolna, identyfikatorem
sesji, wybranym trybem, celem, aktualnym wynikiem i flaga zakonczenia.

Po nacisnieciu `PLAY` na jednej plytce druga automatycznie rozpoczyna te sama
konfiguracje. Jezeli polaczenie nie jest jeszcze gotowe, gra pokazuje ekran
`WAITING FOR UART LINK`. Po zakonczeniu obie strony wymieniaja koncowe wyniki,
zatrzymuja lokalna gre i pokazuja `YOU WIN`, `YOU LOSE` albo `DRAW` wraz z
wynikiem przeciwnika.

Polaczenie Pmod JB:

| Funkcja | Zlacze | Pin FPGA |
| --- | --- | --- |
| UART TX | `JB1` | `A14` |
| UART RX | `JB2` | `A16` |

Nalezy polaczyc `JB1` plytki A z `JB2` plytki B, `JB1` plytki B z `JB2`
plytki A oraz `GND` z `GND`. Nie wolno laczyc pinow `VCC`.

Diody diagnostyczne:

| Diody | Znaczenie |
| --- | --- |
| `LED7:0` | ostatni wynik odebrany z drugiego Basysa |
| `LED12` | druga plytka ma wlaczony test UART |
| `LED13` | zapamietany blad ramki lub sumy kontrolnej |
| `LED14` | zmienia stan po kazdej poprawnej ramce |
| `LED15` | aktywne polaczenie UART |

Do testu bez drugiego monitora ustaw `SW12=1` na obu plytkach. `SW7:0` jest
wtedy wartoscia wysylana, a wyswietlacz 7-segmentowy pokazuje wartosc odebrana.
Zmiana switchy na kazdej plytce i odczyt wyswietlacza na drugiej sprawdza oba
kierunki transmisji.

Pelna sciezke zakonczenia gry mozna sprawdzic jednym monitorem:

1. Basys A: `SW15=1`, `SW12=0`, monitor i mysz podlaczone normalnie.
2. Basys B: `SW15=1`, `SW12=1`, a na `SW7:0` ustaw testowy wynik rywala.
3. Nacisnij `PLAY` na Basysie A i rozegraj dowolny fragment pit-stopu.
4. Nacisnij `BTNU` na Basysie B. Jego wynik zostanie wyslany jako koncowy.
5. Basys A powinien pokazac ekran `YOU WIN`, `YOU LOSE` albo `DRAW` z oboma
   wynikami.

W ten sposob jeden monitor wystarcza do sprawdzenia transmisji, synchronizacji
sesji, zatrzymania gry, porownania i ekranu koncowego. Do normalnej,
jednoczesnej gry dwoch osob nadal potrzebne sa dwa ekrany VGA.

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
- `rtl/Uart/uart_game_link.sv` opakowuje nadajnik i odbiornik w symetryczny
  protokol sesji gry.
- `rtl/Game_logic/multiplayer_result.sv` zamyka mecz po wymianie wynikow i
  wyznacza `WIN/LOSE/DRAW`.
- `rtl/Game_logic/Sprite_control/bolid_anim_ctl.sv` odpowiada za ruch bolidu.
- `wheel_service_fsm.sv` realizuje cykl stare/nowe kolo, a
  `wheel_physics.sv` odpowiada tylko za przeciaganie i rzut.
- `rtl/pit_stop_core.sv` laczy logike z potokiem renderowania.
- `top_fsm.sv` jest cienka warstwa sprzetowa dla myszy PS/2.

Renderer przyciskow wspoldzieli jedna pamiec sprite'u i jedna pamiec fontu
dla `PLAY`, `OPTS` oraz `BACK`. Ekrany opcji i podsumowania korzystaja z
jednego renderera panelu i wspolnej pamieci fontu. Konwersje wartosci binarnych
na trzy cyfry BCD realizuje wspolny modul `bin_to_bcd3` zamiast wielu operatorow
dzielenia i modulo.

Interfejs `low_res_if` nie jest uzywany w aktywnym potoku. Kazdy renderer
wylicza wspolrzedne 256x192 z wlasnego, opoznionego etapu `vga_if`, dzieki czemu
kolor i synchronizacja pozostaja wyrownane. `mouse_limits` programuje kontroler
PS/2 na zakres 0..1023 i 0..767, wiec przy krawedziach ekranu nie wystepuje
martwy obszar ruchu kursora.

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
| `T` | przelacza sprzetowy tryb diagnostyczny (`SW12`) |
| `1`...`4` | wybiera tryb gry (`SW14:13`) |
| `+`, `-` lub strzalki | zmienia cel o 1 (`SW7:0`) |
| `Page Up`, `Page Down` | zmienia cel o 10 |

Symulator startuje z ustawieniem single-player, time attack i celem `60`.
Aktualna wartosc wyswietlacza 7-segmentowego jest widoczna w tytule okna.

Test logiki trybow gry oraz dwoch polaczonych instancji UART:

```bash
./tools/test_game_controller.sh
./tools/test_uart.sh
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

Skrypt zapisuje w `results/` nowy bitstream oraz raporty:

- `synthesis_utilization.rpt`,
- `implementation_utilization.rpt`,
- `timing_summary.rpt`,
- `clock_utilization.rpt`,
- `methodology.rpt`.

Bitstream dolaczony do starszych wersji projektu nie zawieral UART-u. Przed
wgraniem na plytki trzeba wygenerowac nowy `results/top_vga_basys3.bit` i wgrac
ten sam plik na oba Basysy.

Czyste archiwum zrodlowe bez `.git`, `obj_dir`, wynikow symulacji i starych
bitstreamow mozna przygotowac poleceniem:

```bash
./tools/package_source.sh
```
