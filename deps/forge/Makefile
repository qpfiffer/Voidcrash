CFLAGS=-Werror -Wall -DF_DOUBLE_PRECISION
DEBUG_CFLAGS=-DF_MEMORY_DEBUG -DF_EXIT_CRASH -O0 -g3
RELEASE_CFLAGS=-O3
INCLUDES=-I./
LIBS=-lm -lrt
NAME=libforge.a
COMMON_OBJ=f_math.o f_matrix_make.o f_matrix_operations.o f_mem_debug.o f_noise.o f_sort.o f_text.o f_types.o


debug: forge_debug

release: forge_release $(NAME)

forge_debug: CFLAGS += $(DEFAULT_CFLAGS) $(DEBUG_CFLAGS)
forge_debug: $(NAME)

forge_release: CFLAGS += $(DEFAULT_CFLAGS) $(RELEASE_CFLAGS)
forge_release: $(NAME)

clean:
	rm -f *.o
	rm -f $(NAME)

%.o: ./src/%.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(INCLUDES) -c $<

$(NAME): $(COMMON_OBJ)
	ar rcs $(NAME) $^
