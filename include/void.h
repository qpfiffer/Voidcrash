// vim: noet ts=4 sw=4
#pragma once

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <forge.h>
#include <SDL.h>

#include "constants.h"
#include "logging.h"
#include "vector.h"

/* --- Asset importing --- */

typedef struct {
	freal x;
	freal y;
	freal z;
} void_vector3_t;

typedef struct {
	freal x;
	freal y;
} void_vector2_t;

typedef struct {
	vector *vertices;
	vector *uvs;
	vector *normals;
} void_asset_mesh_t;

void_asset_mesh_t *void_asset_import_mesh(const char *path);

/* --- Main game functions. --- */
typedef struct {
	const void_asset_mesh_t *mesh;
	/* TODO: Add matrices from forge for translation/rotation */
} void_game_entity_t;

/* Used for storing game state. */
typedef struct {
	bool should_quit;
	vector *entities;
} void_game_state_t;

void_game_entity_t *void_create_entity(const void_asset_mesh_t *mesh);
int void_init(SDL_Window **window, SDL_GLContext **gl_context);
void void_update(void_game_state_t *state);
void void_draw(SDL_Window *window, const void_game_state_t *game_state);
