// vim: noet ts=4 sw=4
#include <SDL_opengl.h>
#include "void.h"

static inline void _void_gl_init() {
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);

	glEnable(GL_CULL_FACE);

	glEnable(GL_LIGHTING);
}

int void_init(SDL_Window **window, SDL_GLContext **gl_context) {
	srandom(time(NULL));

	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		log_msg(LOG_ERR, "Could not initialize SDL.");
		return -1;
	}

	*window = SDL_CreateWindow(WINDOW_NAME, SDL_WINDOWPOS_UNDEFINED,
			SDL_WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT,
			SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
	if (*window == NULL) {
		log_msg(LOG_ERR, "Could not create window.");
		return -1;
	}

	SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 3 );
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 3 );
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );

	gl_context = SDL_GL_CreateContext(*window);
	if (gl_context == NULL) {
		log_msg(LOG_ERR, "Could not create OpenGL context.");
		return -1;
	}

	if (SDL_GL_SetSwapInterval(1) < 0) {
		log_msg(LOG_ERR, "Could not turn on vsync.");
		return -1;
	}

	_void_gl_init();

	return 0;
}

void void_update(void_game_state_t *game_state) {
	SDL_Event e = {0};
	while (SDL_PollEvent(&e) != 0) {
		if (e.type == SDL_QUIT) {
			game_state->should_quit = TRUE;
		}
	}
}

static inline void void_game_render_entity(const void_game_entity_t *ent) {
	UNUSED(ent);
}

void void_draw(SDL_Window *window, const void_game_state_t *game_state) {
	SDL_Surface *main_surface = SDL_GetWindowSurface(window);
	SDL_FillRect(main_surface, NULL, SDL_MapRGB(main_surface->format, 0, 0, 0));

	size_t i = 0;
	for (i = 0; i < game_state->entities->count; i++) {
		const void_game_entity_t *ent = vector_get(game_state->entities, i);
		void_game_render_entity(ent);
	}

	SDL_UpdateWindowSurface(window);
}

