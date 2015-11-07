// vim: noet ts=4 sw=4
#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <forge.h>
#include <GL/gl.h>
#include <SDL.h>

#include "constants.h"
#include "logging.h"
#include "vector.h"

/* --- General --- */

typedef struct {
	freal x;
	freal y;
} void_vector2_t;

typedef struct {
	freal x;
	freal y;
	freal z;
} void_vector3_t;

/* --- Asset importing --- */

typedef struct {
	vector *vertices;
	vector *uvs;
	vector *normals;
} void_asset_mesh_t;

typedef struct {
	GLuint program_id;
} void_asset_shader_t;

int void_asset_import_shader(const char *vertex_shader, const char *fragment_shader, void_asset_shader_t *out_shader);
int void_asset_import_mesh(const char *path, void_asset_mesh_t *out_mesh);

/* --- Main game functions. --- */
typedef struct {
	void_asset_mesh_t mesh;
	void_asset_shader_t shader;
	/* TODO: Add matrices from forge for translation/rotation */
} void_game_entity_t;

/* Used for storing game state. */
typedef struct {
	int should_quit;
	vector *entities;
} void_game_state_t;

int void_init(SDL_Window **window, SDL_GLContext **gl_context);
void void_update(void_game_state_t *state);
void void_draw(SDL_Window *window, const void_game_state_t *game_state);
