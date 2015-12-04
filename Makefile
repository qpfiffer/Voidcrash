CFLAGS=-Werror -Wextra -Wall
DEBUG_CFLAGS=-O0 -g3
RELEASE_CFLAGS=-O3
INCLUDES=-I./include `pkg-config --cflags sdl2 gl`
LIBS=-pthread -lm -lrt -lcorange -lSDL2 `pkg-config --libs sdl2 gl`
LIB_DIRS=
NAME=voidcrash
COMMON_OBJ=

debug: CFLAGS += $(DEBUG_CFLAGS)
debug: $(NAME)

release: CFLAGS += $(RELEASE_CFLAGS)
release: $(NAME)

clean:
	rm -f *.o
	rm -f $(NAME)

%.o: ./src/%.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(INCLUDES) -c $<

$(NAME): $(COMMON_OBJ) main.o
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(INCLUDES) -o $(NAME) $^ $(LIBS)
