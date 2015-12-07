CFLAGS=-Werror -Wextra -Wall
DEBUG_CFLAGS=-O0 -g3
RELEASE_CFLAGS=-O3
INCLUDES=-I./include -I./deps/Corange/include/ `pkg-config --cflags sdl2 gl`
LIBS=-pthread -lm -lrt -lcorange -lSDL2 `pkg-config --libs sdl2 gl`
LIB_DIRS=-L./deps/Corange/
NAME=voidcrash
COMMON_OBJ=void.o

debug: CFLAGS += $(DEBUG_CFLAGS)
debug: corange $(NAME)

release: CFLAGS += $(RELEASE_CFLAGS)
release: corange $(NAME)

corange:
	@echo "Building Corange."
	@cd ./deps/Corange/; make

clean:
	rm -f *.o
	rm -f $(NAME)

%.o: ./src/%.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(INCLUDES) -c $<

$(NAME): $(COMMON_OBJ) main.o
	$(CC) $(CFLAGS) $(LIB_DIRS) $(INCLUDES) -o $(NAME) $^ $(LIBS)
