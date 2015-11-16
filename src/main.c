// vim: noet ts=4 sw=4
#include "void.h"

int main(int argc, char *argv[]) {
	UNUSED(argc);
	UNUSED(argv);
	SDL_Window *window = NULL;
	SDL_GLContext *gl_context = NULL;
	void_game_state_t game_state = {
		.should_quit = FALSE,
		.entities = vector_new(sizeof(void_game_entity_t), 64)
	};

	if (void_init(&window, &gl_context) != 0)
		return -1;

	void_game_entity_t sphere;
	void_asset_import_mesh("./assets/models/sphere.obj", &sphere.mesh);
	void_asset_import_shader("./assets/shaders/basic.vertex", "./assets/shaders/basic.fragment", &sphere.shader);

	vector_append(game_state.entities, &sphere, sizeof(void_game_entity_t));

	while (game_state.should_quit == FALSE) {
		void_update(&game_state);
		void_draw(window, &game_state);
	}

	return 0;
}
