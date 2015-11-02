// vim: noet ts=4 sw=4
#include <signal.h>

#include "void.h"

SDL_Window *window = NULL;

void void_term(int signum) {
	UNUSED(signum);

	if (window != NULL)
		SDL_DestroyWindow(window);

	SDL_Quit();

	exit(1);
}

int void_init() {
	srandom(time(NULL));

	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		log_msg(LOG_ERR, "Could not initialize SDL.");
		return -1;
	}

	window = SDL_CreateWindow(WINDOW_NAME, SDL_WINDOWPOS_UNDEFINED,
			SDL_WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT,
			SDL_WINDOW_SHOWN);
	if (window == NULL) {
		log_msg(LOG_ERR, "Could not create window.");
		return -1;
	}

	return 0;
}

int main(int argc, char *argv[]) {
	UNUSED(argc);
	UNUSED(argv);

	signal(SIGTERM, void_term);
	signal(SIGINT, void_term);
	signal(SIGCHLD, SIG_IGN);

	if (void_init() != 0)
		return -1;

	/* REMOVE */
	SDL_Surface *main_surface = SDL_GetWindowSurface(window);
	SDL_FillRect(main_surface, NULL, SDL_MapRGB(main_surface->format, 0xFF, 0xFF, 0xFF));
	SDL_UpdateWindowSurface(window);
	SDL_Delay(2000);

	/* ENDREMOVE */

	return 0;
}
