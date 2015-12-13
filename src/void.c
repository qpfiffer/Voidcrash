// vim: noet ts=4 sw=4
#include <corange.h>
#include "void.h"

static inline int void_init(const char *assets_dir, void_game_state_t *game_state) {
	corange_init(assets_dir);

	graphics_viewport_set_title(WINDOW_NAME);
	graphics_viewport_set_size(WINDOW_WIDTH, WINDOW_HEIGHT);

	game_state->config = asset_hndl_new_load(P("./assets/graphics.cfg"));

	camera *default_camera = entity_new("camera", camera);
	default_camera->position = vec3_new(0, 0, -10);
	default_camera->target = vec3_new(0, 0, 0);

	game_state->renderer = renderer_new(game_state->config);
	renderer_set_camera(game_state->renderer, default_camera);
	renderer_set_tod(game_state->renderer, 0.15, 0);

	return 0;
}

static inline void void_update(void_game_state_t *game_state) {
	SDL_Event e = {0};
	while (SDL_PollEvent(&e)) {
		switch (e.type) {
			case SDL_QUIT:
				game_state->should_quit = true;
				break;
		}
	}
}

static inline void void_draw(const void_game_state_t *game_state) {
	renderer_render(game_state->renderer);
}

int void_game() {
	void_game_state_t game_state = {0};
	void_init("./assets/", &game_state);
	while (!game_state.should_quit) {
		frame_begin();

		void_update(&game_state);
		void_draw(&game_state);

		graphics_swap();

		frame_end();
	}
	return 0;
}

