#if defined __cplusplus		/* Declare as C symbols for C++ users. */
extern "C" {
#endif
/*       GL draw helpers      */
/* -------------------------- */

extern void r_init(void *(*glGetProcAddr)(const char* proc));

extern boolean r_extension_test(const char *string);
extern void *r_extension_get_address(const char* proc);

typedef enum{
	SUI_INT8,
	SUI_UINT8,
	SUI_INT16,
	SUI_UINT16,
	SUI_INT32,
	SUI_UINT32,
	SUI_FLOAT,
	SUI_DOUBLE
}SUIFormats;

extern uint 	r_array_vertex_size(SUIFormats *vertex_format_types, uint *vertex_format_size, uint vertex_format_count);

/* allocate a big array of vertex */

struct SUIArraySection;

extern void 	*r_array_allocate(uint vertex_count, SUIFormats *vertex_format_types, uint *vertex_format_size, uint vertex_format_count);
extern void		r_array_free(void *pool);
extern boolean	r_array_defrag(void *pool);
extern void 	*r_array_section_allocate(void *pool, uint size);
extern uint		r_array_section_reference_start(void *section);
extern void		r_array_section_free(void *pool, void *section);
extern void		r_array_deactivate();
extern void		r_array_section_draw(void *pool, void *section, uint primitive_type, uint vertex_start, uint vertex_count);
extern void		r_array_reference_draw(void *pool, void *section, uint primitive_type, uint vertex_start, uint vertex_count);
extern void		r_array_load_vertex(void *pool, struct SUIArraySection *section, void *data, uint start, uint length);
extern void		r_array_load_reference(void *pool, void *section, uint *data, uint length);

extern uint		r_array_get_size(void *pool);
extern uint		r_array_get_used(void *pool);
extern uint		r_array_get_left(void *pool);
extern uint		r_array_get_vertex_size(void *pool);
extern uint		r_array_section_get_vertex_count(void *section);
extern uint		r_array_section_get_vertex_start(void *section);

extern void		r_array_print_out(void *pool);

/* Matrix management */

#define R_MATRIX_STACK_SIZE 8

typedef struct{
	float matrix[R_MATRIX_STACK_SIZE][16];
	float projection[16];
	float aspect;
	float frustum[4];
	boolean multiplied;
	float modelviewprojection[16];	
	uint current;
}RMatrix;

extern void		r_matrix_identity(RMatrix *matrix);
extern void		r_matrix_push(RMatrix *matrix);
extern void		r_matrix_pop(RMatrix *matrix);
extern void		r_matrix_matrix_mult(RMatrix *matrix, float *mult);
extern void		r_matrix_rotate(RMatrix *matrix, float angle, float x, float y, float z);
extern void		r_matrix_scale(RMatrix *matrix, float x, float y, float z);
extern void		r_matrix_translate(RMatrix *matrix, float x, float y, float z);
extern void		r_matrix_normalize_scale(RMatrix *matrix);

extern void		r_matrix_frustum(RMatrix *matrix, float left, float right, float bottom, float top, float znear, float zfar);
extern void		r_matrix_ortho(RMatrix *matrix, float left, float right, float bottom, float top, float znear, float zfar);

extern void		r_matrix_set(RMatrix *matrix);
extern RMatrix	*r_matrix_get();

extern void r_matrix_projection_screend(RMatrix *matrix, double *output, double x, double y, double z);
extern void r_matrix_projection_screenf(RMatrix *matrix, float *output, float x, float y, float z);
extern void r_matrix_projection_worldf(RMatrix *matrix, float *output, float x, float y, float z);
extern void r_matrix_projection_vertexd(RMatrix *matrix, double *output, double *vertex, double x, double y);
extern void r_matrix_projection_vertexf(RMatrix *matrix, float *output, float *vertex, float x, float y);

extern boolean r_matrix_projection_surfacef(RMatrix *matrix, float *output, float *pos, uint axis, float x, float y);
extern boolean r_matrix_projection_axisf(RMatrix *matrix, float *output, float *pos, uint axis, float x, float y);
extern boolean r_matrix_projection_vectorf(RMatrix *matrix, float *output, float *pos, float *vec, float x, float y);

extern void r_viewport(uint x_start, uint y_start, uint x_end, uint y_end);

/* Shader management */

#ifndef R_INTERNAL

typedef void RShader;

#endif

extern RShader	*r_shader_create(char *debug_output, uint output_size, char *vertex, char *fragment, char *name);
extern RShader	*r_shader_create_from_file(char *debug_output, uint output_size, const char *vertex_file, const char *fragment_file, char *name);
extern void		r_shader_destroy(RShader *shader);
extern boolean	r_shader_set(RShader *shader);
//extern void		r_shader_attrib_bind(RShader *shader, uint id, char *name);
extern void		r_shader_texture_set(RShader *shader, uint slot, uint texture_id);

/*extern void		r_shader_active_texture(uint id);
extern void		r_shader_texture_unit_set(RShader *shader, char *name, uint id);*/

extern uint		r_shader_uniform_location(RShader *shader, char *name);

extern void		r_shader_mat4v_set(uint location, float *matrix);
extern void		r_shader_mat3v_set(uint location, float *matrix);
extern void		r_shader_mat2v_set(uint location, float *matrix);

extern void		r_shader_vec4_set(uint location, float v0, float v1, float v2, float v3);
extern void		r_shader_vec3_set(uint location, float v0, float v1, float v2);
extern void		r_shader_vec2_set(uint location, float v0, float v1);
extern void		r_shader_float_set(uint location, float f);

extern void		r_shader_int_set(uint location, int i);
extern void		r_shader_int2_set(uint location, int i0, int i1);
extern void		r_shader_int3_set(uint location, int i0, int i1, int i2);
extern void		r_shader_int4_set(uint location, int i0, int i1, int i2, int i3);

typedef enum{
	P_SP_COLOR_UNIFORM,
	P_SP_COLOR_VERTEX,
	P_SP_TEXTURE,
	P_SP_COLORED_UNIFORM_TEXTURE
}RShaderPresets;

extern RShader	*r_shader_presets_get(RShaderPresets preset);


/* Frame buffer objects */


extern uint		r_framebuffer_depth_buffer_allocate(uint size_x, uint size_y);
extern uint		r_framebuffer_allocate(boolean multilayer, uint *buffers, uint buffer_count, uint depth_buffer);
extern void		r_framebuffer_bind(uint id, uint buffers);


/* Draw primitives */

extern void		r_primitive_surface(float pos_x, float pos_y, float pos_z, float size_x, float size_y, float red, float green, float blue, float alpha);
extern void		r_primitive_image(float pos_x, float pos_y, float pos_z, float size_x, float size_y, float u_start, float v_start, float u_end, float v_end, uint texture_id, float red, float green, float blue, float alpha);
extern void		r_primitive_line_3d(float start_x, float start_y, float start_z, float end_x, float end_y, float end_z, float red, float green, float blue, float alpha);
extern void		r_primitive_line_2d(float start_x, float start_y, float end_x, float end_y, float red, float green, float blue, float alpha);
extern void		r_primitive_line_fade_3d(float start_x, float start_y, float start_z, float end_x, float end_y, float end_z, float start_red, float start_green, float start_blue, float start_alpha, float end_red, float end_green, float end_blue, float end_alpha);
extern void		r_primitive_line_fade_2d(float start_x, float start_y, float end_x, float end_y, float start_red, float start_green, float start_blue, float start_alpha, float end_red, float end_green, float end_blue, float end_alphaa);
extern void		r_primitive_line_flush();
extern void		r_primitive_line_clear();

extern void		r_primitive_sprite(float pos_x, float pos_y, float pos_z, uint texture_id, float size_x, float size_y, float red, float green, float blue, float alpha);
extern void		r_primitive_sprite_uv(float pos_x, float pos_y, float pos_z, uint texture_id, float size_x, float size_y, float u_start, float v_start, float u_end, float v_end, float red, float green, float blue, float alpha);
extern void		r_primitive_sprite_flush();

typedef enum{
	R_IF_RGB_UINT8,
	R_IF_RGBA_UINT8,
	R_IF_RGB_FLOAT16,
	R_IF_RGBA_FLOAT16,
	R_IF_RGB_FLOAT32,
	R_IF_RGBA_FLOAT32,
	R_IF_DEPTH16,
	R_IF_DEPTH24,
	R_IF_DEPTH32,
	R_IF_DEPTH24_STENCIL8,
}PImageFormat;

#define R_IB_IMAGE_CUBE -1

extern uint		r_framebuffer_allocate(boolean multilayer, uint *buffers, uint buffer_count, uint depth_buffer);
extern void		r_framebuffer_free(uint fbo);
extern void		r_framebuffer_bind(uint id, uint buffers);
extern uint		r_texture_allocate(PImageFormat format, uint x, uint y, uint z, boolean filter, boolean tile, void *data);
extern void		r_texture_free(uint texture_id);

#if defined __cplusplus
}
#endif
