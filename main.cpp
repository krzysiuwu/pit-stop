#define SDL_MAIN_HANDLED
#include <SDL2/SDL.h>
#include "Vtop_interactive.h"
#include "verilated.h"

// Rozwiązanie błędu sc_time_stamp
vluint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;
}

// Pełna rozdzielczość ramki z blankingiem
const int SCREEN_WIDTH = 1344;
const int SCREEN_HEIGHT = 806;

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

    top->rst = 1; top->clk = 0; top->eval();
    top->rst = 0; top->eval();
    top->rst = 1;

    while (!quit) {
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
        }

        bool frame_done = false;
        while (!frame_done && !quit) {
            main_time++;
            top->clk = 1; top->eval();
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
    }

    delete[] pixels;
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    delete top;
    return 0;
}