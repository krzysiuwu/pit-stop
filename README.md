# pit-stop
<img width="3219" height="2038" alt="IMG_20260831_133148" src="https://github.com/user-attachments/assets/ec7cab54-466b-45c8-ac02-a8d98984f15c" />
Gra zręcznościowa inspirowana pitstopami w Formule 1 na płytki Basys3

## Spis treści
- [Opcje gry](#opcje-gry)
- [Multiplayer UART](#multiplayer-uart)
- [Przebieg gry](#przebieg-gry)
- [Architektura](#architektura)
- [Uruchomienie na płytce Basys3](#uruchomienie-na-płytce-basys3)
- [Uruchomienie w interaktywnym symulatorze](#uruchomienie-w-interaktywnym-symulatorze)

## Opcje gry

Ekran `OPTS` pokazuje ustawienia odczytywane na żywo ze switchy Basys3:

| Switche | Znaczenie |
| --- | --- |
| `SW15` | `0` single-player, `1` multiplayer |
| `SW14:13` | `00` time attack, `01` point race, `10` speed up, `11` best of |
| `SW12` | sprzętowy tryb testowy UART |
| `SW7:0` | binarna wartość celu od 1 do 255; `0` jest wyświetlane jako `1` |
| `SW11:8` | wolne na kolejne ustawienia |

`TIME ATTACK` zlicza ukończone pit-stopy przez zadaną liczbę sekund. Gracz
wygrywa, jeżeli zdobędzie przynajmniej jeden punkt. `POINT RACE` kończy sie po
osiągniąciu zadanej liczby punktów. `SPEED UP` rozpoczyna od ustawionego limitu
sekund, zmniejsza go o sekunde po każdym pit-stopie i wymaga pięciu udanych rund.
`BEST OF` kończy się po zadanej liczbie pit-stopów i pokazuje łączny, ostatni
oraz najlepszy czas.

Poza rozgrywką wyświetlacz 7-segmentowy pokazuje ustawiony cel. W trybie
testowym UART pokazuje wartość odebraną z drugiego Basysa. Podczas gry
pokazuje pozostały czas w `TIME ATTACK` i `SPEED UP` albo aktualny wynik w
`POINT RACE` i `BEST OF`. Na ekranie końcowym pokazuje wynik.

## Multiplayer UART

Oba Basysy używaja dokładnie tego samego bitstreamu. Łącze pracuje jako
`115200 8N1`. Płytki okresowo wysyłają ramki z sumą kontrolną, identyfikatorem
sesji, wybranym trybem, celem, aktualnym wynikiem i flagą zakończenia.

Po naciśnięciu `PLAY` na jednej płytce druga automatycznie rozpoczyna tą samą
konfiguracje. Jeżeli połączenie nie jest jeszcze gotowe, gra pokazuje ekran
`WAITING FOR UART LINK`. Po zakończeniu obie strony wymieniają końcowe wyniki,
zatrzymują lokalną grę i pokazują `YOU WIN`, `YOU LOSE` albo `DRAW` wraz z
wynikiem przeciwnika.

Połaczenie Pmod JB:

| Funkcja | Złącze | Pin FPGA |
| --- | --- | --- |
| UART TX | `JB1` | `A14` |
| UART RX | `JB2` | `A16` |

Należy połączyć `JB1` płytki A z `JB2` płytki B, `JB1` płytki B z `JB2`
płytki A oraz `GND` z `GND`. Nie wolno łączyć pinow `VCC`.

Diody diagnostyczne:

| Diody | Znaczenie |
| --- | --- |
| `LED7:0` | ostatni wynik odebrany z drugiego Basysa |
| `LED12` | druga płytka ma włączony test UART |
| `LED13` | zapamiętany błąd ramki lub sumy kontrolnej |
| `LED14` | zmienia stan po każdej poprawnej ramce |
| `LED15` | aktywne połączenie UART |

Do testu bez drugiego monitora ustaw `SW12=1` na obu płytkach. `SW7:0` jest
wtedy wartością wysyłaną, a wyświetlacz 7-segmentowy pokazuje wartość odebraną.
Zmiana switchy na każdej płytce i odczyt wyświetlacza na drugiej sprawdza oba
kierunki transmisji.

Pełną scieżkę zakończenia gry można sprawdzić jednym monitorem:

1. Basys A: `SW15=1`, `SW12=0`, monitor i mysz podłączone normalnie.
2. Basys B: `SW15=1`, `SW12=1`, a na `SW7:0` ustaw testowy wynik rywala.
3. Nacisnij `PLAY` na Basysie A i rozegraj dowolny fragment pit-stopu.
4. Nacisnij `BTNU` na Basysie B. Jego wynik zostanie wysłany jako końcowy.
5. Basys A powinien pokazać ekran `YOU WIN`, `YOU LOSE` albo `DRAW` z oboma
   wynikami.

W ten sposob jeden monitor wystarcza do sprawdzenia transmisji, synchronizacji
sesji, zatrzymania gry, porównania i ekranu końcowego. Do normalnej,
jednoczesnej gry dwóch osob nadal potrzebne są dwa ekrany VGA.

## Przebieg gry

1. Należy wcisnąć przycisk `OPTS` i wybrać ustawienia gry wedle uznania i wrócić do menu przyciskiem `BACK`
2. Po wybraniu `PLAY` bolid wjeżdża od prawej strony i zatrzymuje się na środku.
3. Oba koła należy odkręcić rolką myszy skierowaną w dół.
4. Odkręcone koła mozna chwycić przytrzymując lewy przycisk myszy i należy je z rozmachem wyrzucić poza ekran.
5. Po kliknięciu wheelracka pojawia sie nowe koło. Należy przenieść je w
   pobliże dowolnej wolnej piasty, puścić przycisk i dokręcić rolką w góre.
6. Po dokręceniu obu kół naliczany jest punkt, bolid odjeżdża, a jeżeli warunek
   końca gry nie został osiągnięty, kolejny wjeżdża automatycznie.
7. Po zakończeniu rozgrywki pojawia sie wynik, czas ostatniej wymiany, najlepszy
   czas i przycisk powrotu do menu.

Koła można obsługiwać w dowolnej kolejności, odkładać na asfalt i ponownie
podnosić. Nowe koła sa wymienne i nie sa przypisane do konkretnej piasty.

## Architektura

- `fpga/rtl/top_vga_basys3.sv` jest czysto strukturalnym modułem głównym.
  Łączy generator 65 MHz, kontroler resetu, wyjście zegara pikselowego, adapter
  wejść `top_fsm` oraz sterownik wyświetlacza 7-segmentowego.
- `rtl/top_fsm.sv` jest strukturalnym adapterem sprzętowym. Instancjonuje
  kontroler PS/2, ograniczenia myszy, skalowanie współrzędnych, synchronizator
  switchy i wspólny rdzeń gry.
- `rtl/pit_stop_core.sv` jest czysto strukturalnym integratorem logiki gry,
  obsługi dwóch kół, multiplayera i potoku renderowania VGA.
- `rtl/Hardware/vector_synchronizer.sv`, `mouse_coordinate_scaler.sv` oraz
  `rtl/Graphics/VGA/frame_tick_generator.sv` są małymi modułami funkcjonalnymi
  wydzielonymi z modułów integracyjnych.
- `multiplayer_session_control.sv`, `game_ui_control.sv` oraz
  `wheel_service_coordinator.sv` zawierają wydzieloną logikę proceduralną i nie
  instancjonują innych modułów.
- `rtl/Game_logic/system_fsm.sv` steruje ekranami i sekwencją rundy.
- `rtl/Game_logic/singleplayer_game_controller.sv` przechowuje ustawienia
  aktywnej gry, liczy czas, punkty i warunki zwycięstwa.
- `rtl/Uart/uart_game_link.sv` opakowuje nadajnik i odbiornik w symetryczny
  protokół sesji gry.
- `rtl/Game_logic/multiplayer_result.sv` zamyka mecz po wymianie wyników i
  wyznacza `WIN/LOSE/DRAW`.
- `rtl/Game_logic/Sprite_control/bolid_anim_ctl.sv` odpowiada za ruch bolidu.
- `wheel_service_fsm.sv` realizuje cykl stare/nowe koło, a
  `wheel_physics.sv` odpowiada tylko za przeciaganie i rzut.
- `wheel_service_coordinator.sv` rozstrzyga dostępność piast, priorytet racka
  i nakładające się hitboxy obu kół.

Renderer przyciskow współdzieli jedną pamięć sprite'u i jedną pamięć fontu
dla `PLAY`, `OPTS` oraz `BACK`. Ekrany opcji i podsumowania korzystaja z
jednego renderera panelu i wspólnej pamięci fontu. Konwersje wartosci binarnych
na trzy cyfry BCD realizuje wspólny moduł `bin_to_bcd3` zamiast wielu operatorów
dzielenia i modulo.

Interfejs `low_res_if` nie jest uzywany w aktywnym potoku. Kazdy renderer
wylicza wspolrzedne 256x192 z wlasnego, opóźnionego etapu `vga_if`, dzieki czemu
kolor i synchronizacja pozostają wyrównane. `mouse_limits` programuje kontroler
PS/2 na zakres 0..1023 i 0..767, wiec nie można wyjść myszką poza ekran.

## Uruchomienie na płytce Basys3
W katalogu results znajduje się gotowy bitstream. W celu samodzielnego wygenerowania bitstreamu należy użyć poniższego skryptu

```bash
source env.sh
generate_bitstream.sh
```
Następnie należy wgrać bitstream na płytke następującym skryptem
```bash
program_fpga.sh
```
Skrypt obsługuje sytuacje w której jest więcej niż jedna płytka podłączona do komputera i programuje je po kolei.

## Uruchomienie w interaktywnym symulatorze

Interaktywny symulator SDL:

```bash
./tools/build_interactive.sh
```

Skrypt wypisuje scieżkę do gotowego programu. Standardowo jest to
`obj_dir/interactive_sdl/Vtop_interactive`, a w MSYS2 z GCC 16:
`obj_dir/interactive_sdl_msys2_abi0/Vtop_interactive.exe`.

W symulatorze fizyczne switche maja wygodne odpowiedniki na klawiaturze:

| Klawisz | Działanie |
| --- | --- |
| `P` | przełącza single-player / multiplayer (`SW15`) |
| `T` | przełącza sprzętowy tryb diagnostyczny (`SW12`) |
| `1`...`4` | wybiera tryb gry (`SW14:13`) |
| `+`, `-` lub strzałki | zmienia cel o 1 (`SW7:0`) |
| `Page Up`, `Page Down` | zmienia cel o 10 |

Symulator startuje z ustawieniem single-player, time attack i celem `60`.
Aktualną wartość wyświetlacza 7-segmentowego jest widoczna w tytule okna.

Test logiki trybów gry oraz dwoch połączonych instancji UART:

```bash
./tools/test_game_controller.sh
./tools/test_uart.sh
```

Skrypty automatycznie wykrywają MSYS2 UCRT64/MINGW z GCC 16 i włączają zgodne
ABI `libstdc++`. Zapobiega to błędom linkera z symbolami
`std::__cxx11::basic_string`; katalog kompilacji dla tego wariantu jest osobny,
wiec nie trzeba ręcznie usuwać poprzedniego `obj_dir/game_controller`.

