// vim: noet ts=4 sw=4
#pragma once

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <corange.h>

#include "constants.h"
#include "logging.h"

typedef struct {
	bool should_quit;
	renderer *renderer;
	asset_hndl config;
} void_game_state_t;

int void_game();