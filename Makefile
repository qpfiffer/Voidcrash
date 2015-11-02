CFLAGS=-Werror -Wextra -Wall -O0 -g3
INCLUDES=-pthread -I./include/ `pkg-config --cflags sdl2`
LIBS=-lm -lrt -lSDL2 `pkg-config --libs sdl2`
NAME=aaaaaa
COMMON_OBJ=logging.o


all: $(NAME)

clean:
	rm -f *.o
	rm -f $(NAME)

%.o: ./src/%.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(INCLUDES) -c $<

$(NAME): $(COMMON_OBJ) main.o
	$(CC) $(CLAGS) $(LIB_INCLUDES) $(INCLUDES) -o $(NAME) $^ $(LIBS)
