// vim: noet ts=4 sw=4
#include "void.h"

void *get_proc_address(const char *name) {
	void *p = glXGetProcAddress((const unsigned char *)name);
	return p;
}

static inline void _void_gl_init() {
	glewExperimental = TRUE;
	if (glewInit() != GLEW_OK)
		log_msg(LOG_ERR, "Could not init glew.");
	glViewport(0, 0, 1280, 720);
	//glEnable(GL_DEPTH_TEST);
	//glDepthFunc(GL_LESS);

	glClearColor(0.2f, 0.2f, 0.2f, 0.0f);

	//glEnable(GL_CULL_FACE);
	//glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

	r_init(get_proc_address);
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

	SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 2);
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 1);
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

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

	//PFNGLGENVERTEXARRAYSPROC glGenVertexArraysARB = (PFNGLGENVERTEXARRAYSPROC) SDL_GL_GetProcAddress("glGenVertexArrays");
	//PFNGLBINDVERTEXARRAYPROC glBindVertexArrayARB = (PFNGLBINDVERTEXARRAYPROC) SDL_GL_GetProcAddress("glBindVertexArray");
	//uint vao = 0;
	//glGenVertexArraysARB(1, &vao);
	//glBindVertexArrayARB(vao);

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
	r_shader_set(ent->shader.r_shader);
	glEnableVertexAttribArray(ent->mesh.vertex_buffer);
	glBindBuffer(GL_ARRAY_BUFFER, ent->mesh.vertex_buffer);
	glVertexAttribPointer(ent->mesh.vertex_buffer, 3, GL_FLOAT, GL_FALSE, 0, NULL);

	glDrawArrays(GL_TRIANGLES, 0, ent->mesh.vertices->count);
	log_msg(LOG_INFO, "GL Error: %s", glGetError());
}

extern void r_matrix_shader_set(RMatrix *matrix, RShader *shader);

void void_draw(SDL_Window *window, const void_game_state_t *game_state) {
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	glMatrixMode(GL_PROJECTION);
	RMatrix same;
	r_matrix_identity(&same);
	r_matrix_translate(&same, 0.0f, 0.0f, -10.0f);

	size_t i = 0;
	for (i = 0; i < game_state->entities->count; i++) {
		const void_game_entity_t *ent = vector_get(game_state->entities, i);
		r_matrix_shader_set(&same, ent->shader.r_shader);
		void_game_render_entity(ent);
	}

	r_primitive_line_3d(-2.0, -2.0, 1.0, 2.0, 2.0, -1.0, 1.0f, 0.5f, 0.0f, 0.0f);

	SDL_GL_SwapWindow(window);
}

