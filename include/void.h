// vim: noet ts=4 sw=4
#pragma once

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <forge.h>
#include <SDL.h>

#include "constants.h"
#include "logging.h"

typedef struct {
    bool should_quit;
} void_game_state_t;

int void_init(SDL_Window **window, SDL_GLContext **gl_context);
void void_update(void_game_state_t *state);
void void_draw(SDL_Window *window);
