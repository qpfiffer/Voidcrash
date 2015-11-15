#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include "betray.h"
#include "relinquish.h" 

#define CRYSTAL_SIDES 6
#define CRYSTAL_COUNT 10000

typedef struct{
	float pos[3];
	float vector[3];
	float age;
}Crystal;

void crystal_gen_crystal_create(uint seed, float *array, float *matrix, float middle, float edge, float star)
{
	float circle[CRYSTAL_SIDES * 3], f, pos[3], normal[3], n[3], width, m[16];
	uint i, ii , vertex = 0;
	if(middle < 0)
		middle = 0;
	if(edge < 0)
		edge = 0;
	for(i = 0; i < CRYSTAL_SIDES; i++)
	{
		if(i % 2)
			width = 1 + f_randf(seed + 93 + i) * star;
		else
			width = 1 - f_randf(seed + 93 + i) * star;
		f = PI * 2.0 * ((float)i + f_randf(seed + i)) / CRYSTAL_SIDES;
		circle[i * 3 + 0] = width * sin(f);
		circle[i * 3 + 1] = f_randnf(seed + 9 + i) * 0.4 + edge;
		circle[i * 3 + 2] = width * cos(f);
	}
	for(i = 0; i < 12; i++)
		m[i] = matrix[i] * 1000.0;
	m[12] = 0;
	m[13] = 0;
	m[14] = 0;
	m[15] = 1;
	
	for(i = 0; i < CRYSTAL_SIDES; i++)
	{
		ii = (i + 1) % CRYSTAL_SIDES;
		f_transform3f(normal, m, circle[i * 3 + 2] - circle[ii * 3 + 2], 0, 
										circle[ii * 3 + 0] - circle[i * 3 + 0]); 


		n[0] = -matrix[4] * 1000.0 / edge + normal[0];
		n[1] = -matrix[5] * 1000.0 / edge + normal[1];
		n[2] = -matrix[6] * 1000.0 / edge + normal[2];
		f_normalize3f(n);	
		f_normalize3f(normal);
		pos[0] = 0;
		pos[1] = 0;
		pos[2] = 0;
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1];
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1];
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]);
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1];
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1] + middle;
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1] + middle;
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1];
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1] + middle;
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1];
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];


		n[0] = matrix[4] * 1000.0 / edge + normal[0];
		n[1] = matrix[5] * 1000.0 / edge + normal[1];
		n[2] = matrix[6] * 1000.0 / edge + normal[2];
		f_normalize3f(n);

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1] + middle;
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1] + middle;
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];

		pos[0] = 0;
		pos[1] = edge * 2.0 + middle;
		pos[2] = 0;
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];

	}
}

void crystal_gen_crystal_scale(float *array, float *center, float scale)
{
	float f;
	uint i;	
	for(i = 0; i < CRYSTAL_SIDES * 3 * 4; i++)
	{
		f = *array - center[0];
		*array++ = f * scale + center[0];
		f = *array - center[1];
		*array++ = f * scale + center[1];
		f = *array - center[2];
		*array = f * scale + center[2];
		array += 4;
	}
}

void crystal_gen_crystal_stretch(float *array, float *vector, float dist)
{
	float v[3], *a, center[3];
	uint i;	
	v[0] = vector[0] * dist;
	v[1] = vector[1] * dist;
	v[2] = vector[2] * dist;
	center[0] = array[11 * 6 + 0] + v[0];
	center[1] = array[11 * 6 + 1] + v[1];
	center[2] = array[11 * 6 + 2] + v[2];
	for(i = 0; i < CRYSTAL_SIDES; i++)
	{
		a = &array[i * 4 * 3 * 6];
		a[9 * 6 + 0] = a[4 * 6 + 0] = a[4 * 6 + 0] + v[0];
		a[9 * 6 + 1] = a[4 * 6 + 1] = a[4 * 6 + 1] + v[1];
		a[9 * 6 + 2] = a[4 * 6 + 2] = a[4 * 6 + 2] + v[2];

		a[10 * 6 + 0] = a[7 * 6 + 0] = a[5 * 6 + 0] = a[5 * 6 + 0] + v[0];
		a[10 * 6 + 1] = a[7 * 6 + 1] = a[5 * 6 + 1] = a[5 * 6 + 1] + v[1];
		a[10 * 6 + 2] = a[7 * 6 + 2] = a[5 * 6 + 2] = a[5 * 6 + 2] + v[2];

		a[11 * 6 + 0] = center[0];
		a[11 * 6 + 1] = center[1];
		a[11 * 6 + 2] = center[2];
	}
}


void crystal_gen_crystal_update(Crystal *c, float *array, float delta)
{
	if(c->age > 1.0)
		return;
	delta *= 0.2;
	c->age += delta;
	if(c->age < 0.3)
		crystal_gen_crystal_scale(array, c->pos, c->age / (c->age - delta));
	else
		crystal_gen_crystal_stretch(array, c->vector, delta * 0.25);
}

void crystal_gen_crystal_add(Crystal *c, float *array, float delta, float x, float y)
{
	float vec[3] = {1, 1, 1}, matrix[16];
	static uint seed = 0;
	uint i;
	c->age = delta;
	c->pos[0] = x;
	c->pos[1] = y;
	c->pos[2] = 0;
	c->vector[0] = f_randnf(seed++);
	c->vector[1] = f_randnf(seed++);
	c->vector[2] = f_randnf(seed++);
	f_matrixyzf(matrix, NULL, c->vector, vec);
	for(i = 0; i < 11; i++)
		matrix[i] *= 0.1 * delta;
	matrix[12] = c->pos[0]; 
	matrix[13] = c->pos[1]; 
	matrix[14] = c->pos[2]; 
	crystal_gen_crystal_create(seed++, array, matrix, 0, 0.5, 0.3);
}

void crystal_gen_crystal_draw(float *array, uint vertex_count)
{
	uint i;
	vertex_count *= 6;
	for(i = 0; i < vertex_count; i += 6 * 3)
	{
		r_primitive_line_3d(array[i + 0],
							array[i + 1],
							array[i + 2],
							array[i + 6],
							array[i + 7],
							array[i + 8], 1, 0, 0, 1);
		r_primitive_line_3d(array[i + 6],
							array[i + 7],
							array[i + 8],
							array[i + 12],
							array[i + 13],
							array[i + 14], 1, 0, 0, 1);
		r_primitive_line_3d(array[i + 12],
							array[i + 13],
							array[i + 14],
							array[i + 0],
							array[i + 1],
							array[i + 2], 1, 0, 0, 1);


		r_primitive_line_3d(array[i + 0],
							array[i + 1],
							array[i + 2],
							array[i + 0] + array[i + 3],
							array[i + 1] + array[i + 4],
							array[i + 2] + array[i + 5], 0, 1, 1, 1);
		r_primitive_line_3d(array[i + 6],
							array[i + 7],
							array[i + 8],
							array[i + 6] + array[i + 9],
							array[i + 7] + array[i + 10],
							array[i + 8] + array[i + 11], 0, 1, 1, 1);
		r_primitive_line_3d(array[i + 12],
							array[i + 13],
							array[i + 14],
							array[i + 12] + array[i + 15],
							array[i + 13] + array[i + 16],
							array[i + 14] + array[i + 17], 0, 1, 1, 1);
	}
}

void b_test_context_update(void)
{
/*	glMatrixMode(GL_MODELVIEW);	
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	glEnableClientState(GL_VERTEX_ARRAY);
	r_init(betray_gl_proc_address_get());*/
}


/* This is the main loop of the application. It can be triggerd for 3 reasons:
 BAM_MAIN Time has progressed
 BAM_DRAW TThe screen needs to be drawn
 BAM_EVENT Input needs to be parsed
*/

float my_test_value = 0;

void b_test_input_handler(BInputState *input, void *user_pointer)
{
	static float time = 0, pos[3] = {0, 0, -1}, vec[3] = {0, 0, 0};
	static uint sound_source = -1;
	uint i, j, k;
	float f, aspect,  matrix[16];
	/* Move arround a 3D sound source. */

	if(input->mode == BAM_DRAW)
	{
		uint x, y, up_axis, forward_axis;
		float aspect, view[3] = {0, 0, 1}, matrix[16];
//		glClearColor(0.2, 0.2, 0.2, 0);
	//	betray_view_vantage(view);
		aspect = betray_screen_mode_get(&x, &y, NULL);
		r_viewport(0, 0, x, y);
		r_matrix_set(NULL);
		r_matrix_identity(NULL);
		r_matrix_frustum(NULL, -0.01 - view[0] * 0.01, 0.01 - view[0] * 0.01, -0.01 * aspect - view[1] * 0.01, 0.01 * aspect - view[1] * 0.01, 0.01 * view[2], 100.0); /* set frustum */
		glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		/* Add direction matrix so that its possible to implement different view direction*/
		betray_view_direction(matrix); 
		r_matrix_matrix_mult(NULL, matrix);
		r_matrix_translate(NULL, -view[0], -view[1], -view[2]); /* move the camera if betray wants us to. */

		for(forward_axis = 0; forward_axis < input->axis_count; forward_axis++)
			if(input->axis[forward_axis].axis_count == 3 && input->axis[forward_axis].axis_type == B_AXIS_SCREEN_FORWARD)
				break;
		for(up_axis = 0; up_axis < input->axis_count; up_axis++)
			if(input->axis[up_axis].axis_count == 3 && input->axis[up_axis].axis_type == B_AXIS_SCREEN_UP)
				break;
		if(forward_axis < input->axis_count && up_axis < input->axis_count)
		{
			float m[16], output[16];
			f_matrixzyf(m, NULL, input->axis[forward_axis].axis, input->axis[up_axis].axis); 
			f_matrix_reverse4f(output, m); 
			r_matrix_matrix_mult(NULL, output);
		}


		{
			static Crystal *crystals = NULL;
			static float *array;
			static uint crystal_count = 0;
			static void *pool = NULL;
			static RShader *shader;
			static uint texture_id;
			uint fingers = 0;
			SUIFormats vertex_format_types[2] = {SUI_FLOAT, SUI_FLOAT};
			uint vertex_format_size[2] = {3, 3};
			float matrix[16] = {0.1, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 0.1, 0, 0, 0, 0, 1}, time;

			if(crystals == NULL)
			{
				char debug_output[2048];
				uint x = 256, y = 256;
				void *data;
				boolean hdr;
				array = (float *)malloc((sizeof *array) * 6 * 3 * 4 * CRYSTAL_SIDES * CRYSTAL_COUNT);
				crystals = (Crystal *)malloc((sizeof *crystals) * CRYSTAL_COUNT);
				pool = r_array_allocate(3 * 4 * CRYSTAL_SIDES * CRYSTAL_COUNT, vertex_format_types, vertex_format_size, 2);
			/*	shader = r_shader_create_from_file(debug_output, 2048, "crystal_vertex_shader.txt", "crystal_fragment_shader.txt", "Crystal");
				if(shader == NULL)
				{
					printf(debug_output);
					exit(0);
				}*/
				data = NULL;//gather_image_load("reflection.jpg", &x, &y, &hdr); 
				texture_id = r_texture_allocate(R_IF_RGBA_UINT8, 256, 256, 1, TRUE, TRUE, data);
				r_shader_texture_set(shader, 0, texture_id);
			}

			for(i = 0; i < input->pointer_count; i++)
			{
				if(!input->pointers[i].last_button[1] && input->pointers[i].button[1])
					crystal_count = 0;
				if(crystal_count < CRYSTAL_COUNT && input->pointers[i].button[0])
				{
					crystal_gen_crystal_add(&crystals[crystal_count], &array[crystal_count * 6 * 3 * 4 * CRYSTAL_SIDES], input->delta_time,
						input->pointers[i].pointer_x, 
						input->pointers[i].pointer_y);
					crystal_count++;
				}
				if(input->pointers[i].button[0])
					fingers++;
			}
			if(fingers >= 3)
				crystal_count = 0;
			for(i = 0; i < crystal_count; i++)
				crystal_gen_crystal_update(&crystals[i], &array[i * 6 * 3 * 4 * CRYSTAL_SIDES], input->delta_time);

		//	crystal_gen_crystal_draw(array, crystal_count * 3 * 4 * CRYSTAL_SIDES);
			r_array_load_vertex(pool, NULL, array, 0, i * 3 * 4 * CRYSTAL_SIDES);
				
			r_shader_set(/*shader*/r_shader_presets_get(P_SP_COLOR_VERTEX));
			r_array_section_draw(pool, NULL, GL_TRIANGLES, 0, i * 3 * 4 * CRYSTAL_SIDES);

		}
	}
/*	if(input->mode == BAM_EVENT)
		if(betray_button_get(-1, BETRAY_BUTTON_Q))
			exit(0);
			*/
/* flush all line draws! */
	if(input->mode == BAM_DRAW)
		r_primitive_line_flush();
}

int main(int argc, char **argv)
{
	float f;
	int16 *buffer;
	uint i;
	char *clip_buffer;

	/* initialize betray by opening a screen */
//	betray_init(B_CT_OPENGL_OR_ES, argc, argv, 0, 0, 1, TRUE, "Betray Relinquish Test Application");
	betray_init(B_CT_OPENGL_OR_ES, argc, argv, 800, 600, 0, FALSE, "Betray Relinquish Test Application");
	
	/* Accessing clip board */

	r_init((void *(*)(const char *))betray_gl_proc_address_get());
//	gather_init();

	betray_gl_context_update_func_set(b_test_context_update);
	betray_action_func_set(b_test_input_handler, NULL);
	betray_launch_main_loop();
	return TRUE;
}