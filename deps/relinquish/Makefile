CFLAGS=-Werror -Wall -DF_DOUBLE_PRECISION -DRELINQUISH_CONTEXT_OPENGL
DEBUG_CFLAGS=-DF_MEMORY_DEBUG -DF_EXIT_CRASH -O0 -g3
RELEASE_CFLAGS=-O3
INCLUDES=-I./ -I../forge/ -I../betray/
LIBS=-lm -lrt
NAME=librelinquish.a
COMMON_OBJ=r_draw_buffer.o r_draw_extensions.o r_draw_framebuffer.o r_draw_primitive.o r_draw_shader.o r_matrix.o

debug: relinquish_debug

release: relinquish_release $(NAME)

relinquish_debug: CFLAGS += $(DEFAULT_CFLAGS) $(DEBUG_CFLAGS)
relinquish_debug: $(NAME)

relinquish_release: CFLAGS += $(DEFAULT_CFLAGS) $(RELEASE_CFLAGS)
relinquish_release: $(NAME)

clean:
	rm -f *.o
	rm -f $(NAME)

%.o: ./%.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(INCLUDES) -c $<

$(NAME): $(COMMON_OBJ)
	ar rcs $(NAME) $^
