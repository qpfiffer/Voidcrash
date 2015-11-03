// vim: noet ts=4 sw=4
#include "void.h"

int main(int argc, char *argv[]) {
	UNUSED(argc);
	UNUSED(argv);
	SDL_Window *window = NULL;
	SDL_GLContext *gl_context = NULL;
	void_game_state_t game_state = {0};

	if (void_init(&window, &gl_context) != 0)
		return -1;

	while (game_state.should_quit == false) {
		void_update(&game_state);
		void_draw(window);
	}

	return 0;
}
