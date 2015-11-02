// vim: noet ts=4 sw=4
#include "void.h"

int void_init(SDL_Window **window) {
	srandom(time(NULL));

	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		log_msg(LOG_ERR, "Could not initialize SDL.");
		return -1;
	}

	*window = SDL_CreateWindow(WINDOW_NAME, SDL_WINDOWPOS_UNDEFINED,
			SDL_WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT,
			SDL_WINDOW_SHOWN);
	if (*window == NULL) {
		log_msg(LOG_ERR, "Could not create window.");
		return -1;
	}

	return 0;
}

void void_update(void_game_state_t *game_state) {
    SDL_Event e = {0};
    while (SDL_PollEvent(&e) != 0) {
        if (e.type == SDL_QUIT) {
            game_state->should_quit = true;
        }
    }
}

void void_draw(SDL_Window *window) {
	SDL_Surface *main_surface = SDL_GetWindowSurface(window);
	SDL_FillRect(main_surface, NULL, SDL_MapRGB(main_surface->format, 0xFF, 0xFF, 0xFF));
	SDL_UpdateWindowSurface(window);
}
