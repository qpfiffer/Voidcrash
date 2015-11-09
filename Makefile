CFLAGS=-Werror -Wextra -Wall -DF_DOUBLE_PRECISION
DEBUG_CFLAGS=-O0 -g3 -DF_EXIT_CRASH
RELEASE_CFLAGS=-O3
INCLUDES=-pthread -I./deps/forge -I./deps/relinquish -I./include/ `pkg-config --cflags sdl2 gl`
LIBS=-lm -lrt -lSDL2 `pkg-config --libs sdl2 gl`
LIB_DIRS=-L./deps/forge -L./deps/relinquish
NAME=voidstar
COMMON_OBJ=asset_importer.o vector.o void.o logging.o

debug: CFLAGS += $(DEBUG_CFLAGS)
debug: forge_debug relinquish_debug $(NAME)

release: CFLAGS += $(RELEASE_CFLAGS)
release: forge_release relinquish_release $(NAME)

forge_debug:
	@echo "Building Forge in in debug mode."
	@cd ./deps/forge/; make debug

forge_release:
	@echo "Building Forge in in release mode."
	@cd ./deps/forge/; make release

relinquish_debug:
	@echo "Building Relinquish in in debug mode."
	@cd ./deps/relinquish/; make debug

relinquish_release:
	@echo "Building Relinquish in in release mode."
	@cd ./deps/relinquish/; make release

clean:
	rm -f *.o
	rm -f $(NAME)

%.o: ./src/%.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(INCLUDES) -c $<

$(NAME): $(COMMON_OBJ) ./deps/relinquish/librelinquish.a ./deps/forge/libforge.a main.o
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(INCLUDES) -o $(NAME) $^ $(LIBS)
