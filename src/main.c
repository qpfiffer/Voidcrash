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

	void_game_entity_t *sphere = NULL;
	void_asset_mesh_t *sphere_mesh = void_asset_import_mesh("./assets/models/sphere.obj");

	sphere = void_create_entity(sphere_mesh);
	vector_append(game_state.entities, sphere, sizeof(void_game_entity_t));

	while (game_state.should_quit == false) {
		void_update(&game_state);
		void_draw(window, &game_state);
	}

	return 0;
}
