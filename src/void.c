// vim: noet ts=4 sw=4
#include <corange.h>
#include "void.h"

int void_init(const char *assets_dir) {
	corange_init(assets_dir);

	graphics_viewport_set_title(WINDOW_NAME);
	graphics_viewport_set_size(WINDOW_WIDTH, WINDOW_HEIGHT);

	return 0;
}

inline void void_update(void_game_state_t *game_state) {
	SDL_Event e = {0};
	while (SDL_PollEvent(&e)) {
		switch (e.type) {
			case SDL_QUIT:
				game_state->should_quit = true;
				break;
		}
	}
}

int void_draw() {
	void_game_state_t game_state = {0};
	while (!game_state.should_quit) {
		frame_begin();

		void_update(&game_state);

		graphics_swap();

		frame_end();
	}
	return 0;
}

