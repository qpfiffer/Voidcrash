// vim: noet ts=4 sw=4
#include <corange.h>
#include "void.h"

int void_init(const char *assets_dir) {
	corange_init(assets_dir);

	graphics_viewport_set_title(WINDOW_NAME);
	graphics_viewport_set_size(WINDOW_HEIGHT, WINDOW_WIDTH);

	return 0;
}

int void_game() {
	return 0;
}

