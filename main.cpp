#define SDL_MAIN_HANDLED
#include <SDL2/SDL.h>
#include "Vtop_interactive.h"
#include "verilated.h"
#include <cstdint>
#include <cstdio>

// Rozwiązanie błędu sc_time_stamp
vluint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;
}

// Pełna rozdzielczość ramki z blankingiem
const int SCREEN_WIDTH = 1344;
const int SCREEN_HEIGHT = 806;

static const char* gameModeName(uint16_t switches) {
    switch ((switches >> 13) & 0x3) {
        case 0: return "TIME ATTACK";
        case 1: return "POINT RACE";
        case 2: return "SPEED UP";
        default: return "BEST OF";
    }
}

static void updateWindowTitle(SDL_Window* window, uint16_t switches,
                              unsigned displayValue) {
    const unsigned target = (switches & 0xff) == 0
                          ? 1
                          : switches & 0xff;
    const char* player = (switches & 0x8000) ? "MULTIPLAYER" : "SINGLE";
    char title[192];
    std::snprintf(title, sizeof(title),
                  "FPGA VGA Simulator - Pit Stop | %s | %s | target %u | 7SEG %u",
                  player, gameModeName(switches), target, displayValue);
    SDL_SetWindowTitle(window, title);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vtop_interactive* top = new Vtop_interactive;

    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* window = SDL_CreateWindow("FPGA VGA Simulator - Pit Stop", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, 0);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, 0);
    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);

    uint32_t* pixels = new uint32_t[SCREEN_WIDTH * SCREEN_HEIGHT];
    bool quit = false;
    SDL_Event e;
    uint16_t virtual_switches = 60;

    top->mouse_x = 0;
    top->mouse_y = 0;
    top->mouse_btn_left = 0;
    top->mouse_scroll = 0;
    top->mouse_new_event = 0;
    top->switches = virtual_switches;
    updateWindowTitle(window, virtual_switches, virtual_switches & 0x00ff);

    top->rst = 1; top->clk = 0; top->eval();
    top->rst = 0; top->eval();
    top->rst = 1;

    while (!quit) {
        int pending_scroll = 0;

        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) quit = true;
            if (e.type == SDL_MOUSEMOTION) {
                top->mouse_x = e.motion.x; 
                top->mouse_y = e.motion.y;
            }
            if (e.type == SDL_MOUSEBUTTONDOWN && e.button.button == SDL_BUTTON_LEFT) {
                top->mouse_btn_left = 1;
            }
            if (e.type == SDL_MOUSEBUTTONUP && e.button.button == SDL_BUTTON_LEFT) {
                top->mouse_btn_left = 0;
            }
            if (e.type == SDL_MOUSEWHEEL) {
                int wheel_delta = e.wheel.y;
                if (e.wheel.direction == SDL_MOUSEWHEEL_FLIPPED) {
                    wheel_delta = -wheel_delta;
                }
                pending_scroll += wheel_delta;
            }
            if (e.type == SDL_KEYDOWN) {
                bool switches_changed = true;

                switch (e.key.keysym.sym) {
                    case SDLK_p:
                        if (e.key.repeat == 0)
                            virtual_switches ^= 0x8000;
                        else
                            switches_changed = false;
                        break;

                    case SDLK_1:
                    case SDLK_2:
                    case SDLK_3:
                    case SDLK_4: {
                        if (e.key.repeat == 0) {
                            const uint16_t mode =
                                static_cast<uint16_t>(e.key.keysym.sym - SDLK_1);
                            virtual_switches =
                                (virtual_switches & ~0x6000) | (mode << 13);
                        } else {
                            switches_changed = false;
                        }
                        break;
                    }

                    case SDLK_UP:
                    case SDLK_RIGHT:
                    case SDLK_EQUALS:
                    case SDLK_KP_PLUS: {
                        uint16_t target = virtual_switches & 0x00ff;
                        if (target < 255) ++target;
                        virtual_switches =
                            (virtual_switches & 0xff00) | target;
                        break;
                    }

                    case SDLK_DOWN:
                    case SDLK_LEFT:
                    case SDLK_MINUS:
                    case SDLK_KP_MINUS: {
                        uint16_t target = virtual_switches & 0x00ff;
                        if (target > 1) --target;
                        virtual_switches =
                            (virtual_switches & 0xff00) | target;
                        break;
                    }

                    case SDLK_PAGEUP: {
                        uint16_t target = virtual_switches & 0x00ff;
                        target = (target > 245) ? 255 : target + 10;
                        virtual_switches =
                            (virtual_switches & 0xff00) | target;
                        break;
                    }

                    case SDLK_PAGEDOWN: {
                        uint16_t target = virtual_switches & 0x00ff;
                        target = (target <= 11) ? 1 : target - 10;
                        virtual_switches =
                            (virtual_switches & 0xff00) | target;
                        break;
                    }

                    default:
                        switches_changed = false;
                        break;
                }

                if (switches_changed) {
                    top->switches = virtual_switches;
                    updateWindowTitle(window, virtual_switches,
                                      top->seven_segment_value);
                }
            }
        }

        // Interfejs PS/2 dostarcza impuls new_event przez jeden takt. Symulator
        // odwzorowuje to samo zachowanie, aby jeden ruch rolki liczyl sie raz.
        if (pending_scroll > 7) pending_scroll = 7;
        if (pending_scroll < -7) pending_scroll = -7;
        top->mouse_scroll = pending_scroll & 0x0f;
        top->mouse_new_event = (pending_scroll != 0);

        bool frame_done = false;
        bool scroll_event_sent = false;
        while (!frame_done && !quit) {
            main_time++;
            top->clk = 1; top->eval();

            if (!scroll_event_sent && top->mouse_new_event) {
                top->mouse_new_event = 0;
                top->mouse_scroll = 0;
                scroll_event_sent = true;
            }

            main_time++;
            top->clk = 0; top->eval();

            // Pobieranie prawdziwych współrzędnych sprzętowych
            int x = top->vga_x;
            int y = top->vga_y;

            uint8_t red   = (top->r << 4) | top->r;
            uint8_t green = (top->g << 4) | top->g;
            uint8_t blue  = (top->b << 4) | top->b;

            if (x < SCREEN_WIDTH && y < SCREEN_HEIGHT) {
                pixels[y * SCREEN_WIDTH + x] = (red << 16) | (green << 8) | blue;
            }

            // Klatka kończy się dokładnie na ostatnim pikselu
            if (x == SCREEN_WIDTH - 1 && y == SCREEN_HEIGHT - 1) {
                frame_done = true;
            }
        }

        SDL_UpdateTexture(texture, NULL, pixels, SCREEN_WIDTH * sizeof(uint32_t));
        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
        updateWindowTitle(window, virtual_switches,
                          top->seven_segment_value);
    }

    delete[] pixels;
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    delete top;
    return 0;
}
