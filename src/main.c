// vim: noet ts=4 sw=4
#include "void.h"

int main(int argc, char *argv[]) {
	UNUSED(argc);
	UNUSED(argv);

	void_init("./assets/");
	return void_draw();
}
