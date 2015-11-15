#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include "betray.h"
#include "relinquish.h" /*little opengl wrapper i use, in the case only to draw lines*/
#include "crystal_image_file.h" 


#define CRYSTAL_SIDES_MAX 15
#define CRYSTAL_VERTEX_FORMAT 7
#define CRYSTAL_COUNT 10000

typedef struct{
	float pos[3];
	float vector[3];
	float age;
	float break_point;
}Crystal;

typedef struct{
	float crystal_aspect;
	float crystal_aspect_rand;
	float crystal_edge;
	float crystal_spread;
	float crystal_direction;
	float crystal_expand;
	uint crystal_sides;
	uint crystal_shape;
	uint crystal_count;
	uint crystal_group;
}GlobalSettings;

GlobalSettings crystal_global_settings;
static Crystal *crystals = NULL;

void crystal_restart(RShader *shader)
{
	static uint rand = 0;
	float rgb[3], f;
	crystal_global_settings.crystal_count = 0;
	rand++;
	f_hsv_to_rgb(rgb, f_randf(rand), f_randf(rand + 1) * 0.5 + 0.5, f_randf(rand + 2) * 0.5 + 0.5);
	r_shader_vec4_set(r_shader_uniform_location(shader, "color_a"), rgb[0], rgb[1], rgb[2], 0);
	rand++;
	f_hsv_to_rgb(rgb, f_randf(rand), f_randf(rand + 1), f_randf(rand + 2) * 0.5 + 0.5);
	r_shader_vec4_set(r_shader_uniform_location(shader, "color_b"), rgb[0], rgb[1], rgb[2], 0);
	crystal_global_settings.crystal_aspect = f_randf(++rand) * 0.7 + 0.3;
	crystal_global_settings.crystal_aspect *= crystal_global_settings.crystal_aspect;
	f = f_randf(++rand);
	crystal_global_settings.crystal_sides = 3 + (uint)(f * 12.0);
	crystal_global_settings.crystal_shape = f_randf(++rand);
	f = f_randf(++rand);
	crystal_global_settings.crystal_edge = 0.2 + 10.0 * f * f * f;
	f = f_randf(++rand);
	if(f < 0.4)
		f = 0;
	crystal_global_settings.crystal_group = 1 + (uint)(f * f * 40.0);
	f = f_randf(++rand);
	if(f < 0.4)
		f = 0;
	crystal_global_settings.crystal_spread = 0.3 * f;
	f = f_randf(++rand);
	if(f < 0.4)
		f = 0.4;
	f = f_randf(++rand);
	if(f < 0.4)
		f = 0.4;
	crystal_global_settings.crystal_direction = f;

	f = f_randf(++rand);
	if(f < 0.7)
		f = 0.0;
	crystal_global_settings.crystal_expand = f * 2.0;
	f = f_randf(++rand);
	if(f < 0.4)
		f *= 0.4;
	crystal_global_settings.crystal_aspect_rand = f * 0.4;
}

char *crystal_shader_vertex =
"attribute vec3 vertex;\n"
"attribute vec4 normal;\n"
"varying vec4 col;\n"
"varying vec4 shade;\n"
"varying vec4 pos;\n"
"varying vec3 reflection_uv;\n"
"varying vec3 refraction_uv;\n"
"uniform mat4 ModelViewProjectionMatrix;\n"
"uniform mat4 NormalMatrix;\n"
"\n"
"void main()\n"
"{\n"
"	vec4 n, p;\n"
"	col = vec4(normal.xyz, 1.0);\n"
"	n = NormalMatrix * vec4(normal.xyz, 1.0);\n"
"	p = ModelViewProjectionMatrix * vec4(vertex, 1.0);\n"
"	col = vec4(vec3(dot(n, n)), 1.0);\n"
"	shade = normal.aaaa;\n"
"	reflection_uv = vec3(0.5) + reflect(p.xyz, n.xyz) * vec3(0.5);\n"
"	gl_Position = p;\n"
"	pos = p - vec4(0, 0, 0.5, 0);\n"
"	refraction_uv = vec3(0.5) + (p.xyz - n.xyz * vec3(0.1)) * vec3(0.5);\n"
"}\n";

char *crystal_shader_fragment =
"varying vec4 col;\n"
"varying vec4 shade;\n"
"varying vec4 pos;\n"
"varying vec3 reflection_uv;\n"
"varying vec3 refraction_uv;\n"
"uniform sampler2D image;\n"
"uniform vec4 color_a;\n"
"uniform vec4 color_b;\n"
"\n"
"void main()\n"
"{\n"
"	vec4 ref;\n"
"	ref = texture2D(image, reflection_uv.xy);\n"
"	gl_FragColor = col * ref * ref + (vec4(1.0) - texture2D(image, refraction_uv.xy)) * (vec4(1.0) - shade * shade) * mix(color_b, color_a, shade);\n"
"//	gl_FragColor = mix(color_b, color_a, shade);\n"
"//	gl_FragColor = reflection_uv.xyxy;\n"
"//	gl_FragColor = texture2D(image, reflection_uv.xy);\n"
"}\n\n";


void crystal_gen_crystal_create(uint seed, float *array, float *matrix, float middle, float edge, float star, float dark)
{
	float circle[CRYSTAL_SIDES_MAX * 3], f, pos[3], normal[3], n[3], width, m[16];
	uint i, ii , vertex = 0;
	if(middle < 0)
		middle = 0;
	if(edge < 0)
		edge = 0;
	for(i = 0; i < crystal_global_settings.crystal_sides; i++)
	{
		if(i % 2)
			width = 1 + f_randf(seed + 93 + i) * star;
		else
			width = 1 - f_randf(seed + 93 + i) * star;
		f = PI * 2.0 * ((float)i + f_randf(seed + i)) / (float)crystal_global_settings.crystal_sides;
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
	
	for(i = 0; i < crystal_global_settings.crystal_sides; i++)
	{
		ii = (i + 1) % crystal_global_settings.crystal_sides;
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
		array[vertex++] = 1.0;

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1];
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];
		array[vertex++] = 1.0;

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1];
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]);
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];
		array[vertex++] = 1.0;

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1];
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];
		array[vertex++] = 1.0;

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1] + middle;
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];
		array[vertex++] = 0.0 + dark;

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1] + middle;
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];
		array[vertex++] = 0.0 + dark;

		pos[0] = circle[i * 3 + 0];
		pos[1] = circle[i * 3 + 1];
		pos[2] = circle[i * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];
		array[vertex++] = 1.0;

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1] + middle;
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];
		array[vertex++] = 0.0 + dark;

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1];
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = normal[0];
		array[vertex++] = normal[1];
		array[vertex++] = normal[2];
		array[vertex++] = 1.0;


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
		array[vertex++] = 0.0 + dark;

		pos[0] = circle[ii * 3 + 0];
		pos[1] = circle[ii * 3 + 1] + middle;
		pos[2] = circle[ii * 3 + 2];
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];
		array[vertex++] = 0.0 + dark;

		pos[0] = 0;
		pos[1] = edge * 2.0 + middle;
		pos[2] = 0;
		f_transform3f(&array[vertex], matrix, pos[0], pos[1], pos[2]); 
		vertex += 3;
		array[vertex++] = n[0];
		array[vertex++] = n[1];
		array[vertex++] = n[2];
		array[vertex++] = 0.0 + dark;

	}
}

void crystal_gen_crystal_scale(float *array, float *center, float scale)
{
	float f;
	uint i;	
	for(i = 0; i < crystal_global_settings.crystal_sides * 3 * 4; i++)
	{
		f = *array - center[0];
		*array++ = f * scale + center[0];
		f = *array - center[1];
		*array++ = f * scale + center[1];
		f = *array - center[2];
		*array = f * scale + center[2];
		array += 5;
	}
}

void crystal_gen_crystal_stretch(float *array, float *vector, float dist)
{
	float v[3], *a, center[3];
	uint i;	
	v[0] = vector[0] * dist;
	v[1] = vector[1] * dist;
	v[2] = vector[2] * dist;
	center[0] = array[11 * 7 + 0] + v[0];
	center[1] = array[11 * 7 + 1] + v[1];
	center[2] = array[11 * 7 + 2] + v[2];
	for(i = 0; i < crystal_global_settings.crystal_sides; i++)
	{
		a = &array[i * 4 * 3 * 7];
		a[9 * 7 + 0] = a[4 * 7 + 0] = a[4 * 7 + 0] + v[0];
		a[9 * 7 + 1] = a[4 * 7 + 1] = a[4 * 7 + 1] + v[1];
		a[9 * 7 + 2] = a[4 * 7 + 2] = a[4 * 7 + 2] + v[2];

		a[10 * 7 + 0] = a[7 * 7 + 0] = a[5 * 7 + 0] = a[5 * 7 + 0] + v[0];
		a[10 * 7 + 1] = a[7 * 7 + 1] = a[5 * 7 + 1] = a[5 * 7 + 1] + v[1];
		a[10 * 7 + 2] = a[7 * 7 + 2] = a[5 * 7 + 2] = a[5 * 7 + 2] + v[2];

		a[11 * 7 + 0] = center[0];
		a[11 * 7 + 1] = center[1];
		a[11 * 7 + 2] = center[2];
	}
}


void crystal_gen_crystal_update(Crystal *c, float *array, float delta)
{
	if(c->age > 1.0)
		return;
	delta *= 0.2;
	c->age += delta;
	if(c->age < c->break_point)
		crystal_gen_crystal_scale(array, c->pos, c->age / (c->age - delta));
	else
		crystal_gen_crystal_stretch(array, c->vector, delta * 0.4);
}

void crystal_gen_crystal_add(Crystal *c, float *array, float delta, float x, float y, float z)
{
	float vec[3] = {1, 1, 1}, matrix[16];
	static float last[3] = {0, 0, 0};
	static uint seed = 0;
	uint i;
	c->age = delta;
	if(crystal_global_settings.crystal_count % crystal_global_settings.crystal_group > 0)
	{
		Crystal *parent;
		i = (crystal_global_settings.crystal_count / crystal_global_settings.crystal_group) * crystal_global_settings.crystal_group;
		parent = &crystals[i];
		c->pos[0] = parent->pos[0] + 0.15 * f_randnf(seed++) * crystal_global_settings.crystal_aspect;
		c->pos[1] = parent->pos[1] + 0.15 * f_randnf(seed++) * crystal_global_settings.crystal_aspect;
		c->pos[2] = parent->pos[2] + 0.15 * f_randnf(seed++) * crystal_global_settings.crystal_aspect;
		c->vector[0] = parent->vector[0] + crystal_global_settings.crystal_spread * f_randnf(seed++);
		c->vector[1] = parent->vector[1] + crystal_global_settings.crystal_spread * f_randnf(seed++);
		c->vector[2] = parent->vector[2] + crystal_global_settings.crystal_spread * f_randnf(seed++);
	}else
	{
		c->pos[0] = x;
		c->pos[1] = y;
		c->pos[2] = z;
		c->vector[0] = 5 + f_randnf(seed++);
		c->vector[1] = f_randnf(seed++);
		c->vector[2] = f_randnf(seed++);
		c->vector[0] = x - last[0];
		c->vector[1] = y - last[1];
		c->vector[2] = z - last[2];
		f_normalize3f(c->vector);
		c->vector[0] *= crystal_global_settings.crystal_direction;
		c->vector[1] *= crystal_global_settings.crystal_direction;
		c->vector[2] *= crystal_global_settings.crystal_direction;
		c->vector[0] += f_randnf(seed++) * 0.7;
		c->vector[1] += f_randnf(seed++) * 0.7;
		c->vector[2] += f_randnf(seed++) * 0.7;
		c->vector[0] += c->pos[0] * crystal_global_settings.crystal_expand;
		c->vector[1] += c->pos[1] * crystal_global_settings.crystal_expand;
		c->vector[2] += c->pos[2] * crystal_global_settings.crystal_expand;
		last[0] = x;
		last[1] = y;
		last[2] = z;
		f_normalize3f(c->vector);
	/*	c->vector[0] = f_randnf(seed++);
		c->vector[1] = f_randnf(seed++);
		c->vector[2] = f_randnf(seed++);*/
	}
	f_matrixyzf(matrix, NULL, c->vector, c->vector);
	for(i = 0; i < 11; i++)
		matrix[i] *= 0.05 * delta;
	matrix[12] = c->pos[0]; 
	matrix[13] = c->pos[1]; 
	matrix[14] = c->pos[2]; 

	c->break_point = crystal_global_settings.crystal_aspect + crystal_global_settings.crystal_aspect * crystal_global_settings.crystal_aspect_rand * f_randnf(seed++);
	crystal_gen_crystal_create(seed++, array, matrix, 0, crystal_global_settings.crystal_edge, crystal_global_settings.crystal_shape, crystal_global_settings.crystal_count % 2);
}

void crystal_gen_crystal_draw(float *array, uint vertex_count)
{
	uint i;
	vertex_count *= 7;
	for(i = 0; i < vertex_count; i += 7 * 3)
	{
		r_primitive_line_fade_3d(array[i + 0],
							array[i + 1],
							array[i + 2],
							array[i + 7],
							array[i + 8],
							array[i + 9], 1, array[6], 0, 1, 1, array[13], 0, 1);
		r_primitive_line_fade_3d(array[i + 7],
							array[i + 8],
							array[i + 9],
							array[i + 14],
							array[i + 15],
							array[i + 16], 1, array[13], 0, 1, 1, array[20], 0, 1);
		r_primitive_line_fade_3d(array[i + 14],
							array[i + 15],
							array[i + 16],
							array[i + 0],
							array[i + 1],
							array[i + 2], 1, array[20], 0, 1, 1, array[6], 0, 1);

		/*
		r_primitive_line_3d(array[i + 0],
							array[i + 1],
							array[i + 2],
							array[i + 0] + array[i + 3] * 0.02,
							array[i + 1] + array[i + 4] * 0.02,
							array[i + 2] + array[i + 5] * 0.02, 0, 1, 1, 1);
		r_primitive_line_3d(array[i + 7],
							array[i + 8],
							array[i + 9],
							array[i + 7] + array[i + 10] * 0.02,
							array[i + 8] + array[i + 11] * 0.02,
							array[i + 9] + array[i + 12] * 0.02, 0, 1, 1, 1);
		r_primitive_line_3d(array[i + 14],
							array[i + 15],
							array[i + 16],
							array[i + 14] + array[i + 17] * 0.02,
							array[i + 15] + array[i + 18] * 0.02,
							array[i + 16] + array[i + 19] * 0.02, 0, 1, 1, 1);
*/	}
}

void b_test_context_update(void)
{
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
	if(input->mode == BAM_MAIN)
		time += input->delta_time;
	/* Move arround a 3D sound source. */
	if(input->mode == BAM_DRAW)
	{
		uint x, y, forward_axis, up_axis;
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
			f_matrix_reverse4f(matrix, m); 
		}else
		{
			static float m[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}, pos[4] = {1, 0, 0, 1}, f;
			f_wiggle3df(pos, time * 0.3, 1);
			f = pos[0] * m[0] + pos[1] * m[1] + pos[2] * m[2];
			pos[0] -= m[0] * f;
			pos[1] -= m[1] * f;
			pos[2] -= m[2] * f;
			f_normalize4f(pos);
			m[0] += pos[0] * 0.2 * input->delta_time;
			m[1] += pos[1] * 0.2 * input->delta_time;
			m[2] += pos[2] * 0.2 * input->delta_time;
			f_matrixxyf(m, NULL, &m[0], &m[4]); 
			for(i = 0; i < 16; i++)
				matrix[i] = m[i];
		}
		r_matrix_matrix_mult(NULL, matrix);
	//	r_matrix_rotate(NULL, input->minute_time * 360 * 10, 1, 0, 0);
		{
			static float *array;
			static void *pool = NULL;
			static RShader *shader;
			static uint texture_id;
			SUIFormats vertex_format_types[2] = {SUI_FLOAT, SUI_FLOAT};
			uint vertex_format_size[2] = {3, 4}, touch_count = 0;

			if(crystals == NULL)
			{
				char debug_output[2048];
				uint x = 256, y = 256;
				void *data;
				boolean hdr;
				FILE *file;
				array = (float *)malloc((sizeof *array) * 7 * 3 * 4 * CRYSTAL_SIDES_MAX * CRYSTAL_COUNT);
				crystals = (Crystal *)malloc((sizeof *crystals) * CRYSTAL_COUNT);
				pool = r_array_allocate(3 * 4 * CRYSTAL_SIDES_MAX * CRYSTAL_COUNT, vertex_format_types, vertex_format_size, 2);
				shader = r_shader_create(debug_output, 2048, crystal_shader_vertex, crystal_shader_fragment, "Crystal");
			//	shader = r_shader_create_from_file(debug_output, 2048, "crystal_vertex_shader.txt", "crystal_fragment_shader.txt", "Crystal");
				if(shader == NULL)
				{
					printf(debug_output);
					exit(0);
				}
				texture_id = r_texture_allocate(R_IF_RGB_UINT8, 128, 128, 1, TRUE, TRUE, image_buffer);
			//	texture_id = r_texture_allocate(R_IF_RGBA_UINT8, x, y, 1, TRUE, TRUE, data);
				
				r_shader_vec4_set(r_shader_uniform_location(shader, "color_a"), 1, 0, 0, 0);
				r_shader_vec4_set(r_shader_uniform_location(shader, "color_b"), 0, 0, 1, 0);
				r_shader_texture_set(shader, 0, texture_id);
				crystal_restart(shader);
			}

			for(i = 0; i < input->pointer_count; i++)
			{
				if(!input->pointers[i].last_button[1] && input->pointers[i].button[1])
					touch_count = 4;
				if(crystal_global_settings.crystal_count < CRYSTAL_COUNT && input->pointers[i].button[0])
				{
					float output[3], m[16];
					f_matrix_reverse4f(m, matrix); 
					f_transform3f(output, m, input->pointers[i].pointer_x, input->pointers[i].pointer_y, 0);
					for(j = 0; j < 3; j++)
					{
						crystal_gen_crystal_add(&crystals[crystal_global_settings.crystal_count], &array[crystal_global_settings.crystal_count * 7 * 3 * 4 * crystal_global_settings.crystal_sides], input->delta_time,
							output[0], 
							output[1], 
							output[2]);
						crystal_global_settings.crystal_count++;
					}
					touch_count++;
				}		
			}
			r_shader_set(shader);
			if(touch_count > 3)
				crystal_restart(shader);

			for(i = 0; i < crystal_global_settings.crystal_count; i++)
				crystal_gen_crystal_update(&crystals[i], &array[i * 7 * 3 * 4 * crystal_global_settings.crystal_sides], input->delta_time);

		//	crystal_gen_crystal_draw(array, crystal_global_settings.crystal_count * 3 * 4 * CRYSTAL_SIDES);
			r_array_load_vertex(pool, NULL, array, 0, crystal_global_settings.crystal_count * 3 * 4 * crystal_global_settings.crystal_sides);	
		//	r_shader_set(r_shader_presets_get(P_SP_COLOR_VERTEX));
		//	r_shader_set(r_shader_presets_get(P_SP_TEXTURE/*P_SP_COLOR_VERTEX*/));
			r_shader_texture_set(shader, 0, texture_id);
			r_array_section_draw(pool, NULL, GL_TRIANGLES, 0, crystal_global_settings.crystal_count * 3 * 4 * crystal_global_settings.crystal_sides);
		}
	}
#ifdef _WIN32
	if(input->mode == BAM_EVENT)
		if(betray_button_get(-1, BETRAY_BUTTON_Q))
			exit(0);
#endif
/* flush all line draws! */
	if(input->mode == BAM_DRAW)
		r_primitive_line_flush();
}

int main(int argc, char **argv)
{
	float f;
	int16 *buffer;
	uint i, x, y;
	uint8 *data;
	FILE *file;
	char *clip_buffer;

	/* initialize betray by opening a screen */
//	betray_init(B_CT_OPENGL_OR_ES, argc, argv, 0, 0, 1, TRUE, "Betray Relinquish Test Application");
	betray_init(B_CT_OPENGL_OR_ES, argc, argv, 1800, 1000, 0, FALSE, "Betray Relinquish Test Application");
	
	/* Accessing clip board */

	r_init((void *(*)(const char*))betray_gl_proc_address_get());
/*	gather_init();
	file = fopen("image_file.txt", "w");
	data = gather_image_load("reflection2.jpg", &x, &y, &hdr); 
	fprintf(file, "uint8 image_buffer[] = {%u, %u, %u", ((uint8 *)data)[0], ((uint8 *)data)[1], ((uint8 *)data)[2]);
	for(i = 1; i < x * y; i++)
	{
		fprintf(file, ", %u, %u, %u", ((uint8 *)data)[i * 4 + 0], ((uint8 *)data)[i * 4 + 1], ((uint8 *)data)[i * 4 + 2]);
		if(i % 16 == 0)
			fprintf(file, "\n\t\t\t\t");
	}
	fprintf(file, "};\n");*/

	betray_gl_context_update_func_set(b_test_context_update);
	betray_action_func_set(b_test_input_handler, NULL);
	betray_launch_main_loop();
	return TRUE;
}

