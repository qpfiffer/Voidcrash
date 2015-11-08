#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include "forge.h"
#include "r_include.h"
#include "relinquish.h"



char *r_type_names[R_SIT_COUNT] = {"bool",
									"vbool2",
									"vbool3",
									"vbool4",
									"int",
									"vint2",
									"vint3",
									"vint4",
									"uint",
									"vuint2",
									"vuint3",
									"vuint4",
									"float",
									"vec2",
									"vec3",
									"vec4",
									"double",
									"vdouble2",
									"vdouble3",
									"vdouble4",
									"mat2",
									"mat2x3",
									"mat2x4",
									"mat3x2",
									"mat3",
									"mat3x4",
									"mat4x2",
									"mat4x3",
									"mat4",
									"dmat2",
									"dmat2x3",
									"dmat2x4",
									"dmat3x2",
									"dmat3",
									"dmat3x4",
									"dmat4x2",
									"dmat4x3",
									"dmat4",
									"sampler1D",
									"sampler2D",
									"sampler3D",
									"samplerCube",
									"sampler2DRect",
									"sampler1DArray",
									"sampler2DArray",
									"samplerCubeArray",
									"samplerBuffer",
									"sampler2DMS",
									"sampler2DMSArray"};


uint r_sampler_names[] = {0x0DE0, /*GL_TEXTURE_1D*/
										GL_TEXTURE_2D,
										0x806F/*GL_TEXTURE_3D*/,
										0x8513/*GL_TEXTURE_CUBE_MAP*/,
										0x84F5 /*GL_TEXTURE_RECTANGLE*/,
										-1/*GL_TEXTURE_1D_ARRAY*/,
										-1/*GL_TEXTURE_2D_ARRAY*/,
										0x9009 /*GL_TEXTURE_CUBE_MAP_ARRAY*/,
										0x8C2A /*GL_TEXTURE_BUFFER*/,
										0x9100 /*GL_TEXTURE_2D_MULTISAMPLE*/,
										0x9102 /*GL_TEXTURE_2D_MULTISAMPLE_ARRAY*/};

GLhandleARB (APIENTRY *r_glCreateShaderObjectARB)(GLenum  shaderType);
GLvoid      (APIENTRY *r_glDeleteObjectARB)(GLhandleARB obj);
GLhandleARB (APIENTRY *r_glCreateProgramObjectARB)(GLvoid);
GLvoid      (APIENTRY *r_glAttachObjectARB)(GLhandleARB containerObj, GLhandleARB obj);
GLvoid      (APIENTRY *r_glShaderSourceARB)(GLhandleARB shaderObj, GLsizei count, const char **string, const GLint *length);
GLvoid      (APIENTRY *r_glCompileShaderARB)(GLhandleARB shaderObj);
GLvoid      (APIENTRY *r_glLinkProgramARB)(GLhandleARB programObj);
GLvoid      (APIENTRY *r_glUseProgramObjectARB)(GLhandleARB programObj);
GLint       (APIENTRY *r_glGetUniformLocationARB)(GLhandleARB programObj, const char *name);
GLvoid      (APIENTRY *r_glUniform4fARB)(GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
GLvoid      (APIENTRY *r_glUniform3fARB)(GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
GLvoid      (APIENTRY *r_glUniform2fARB)(GLint location, GLfloat v0, GLfloat v1);
GLvoid      (APIENTRY *r_glUniform1fARB)(GLint location, GLfloat v0);
GLvoid      (APIENTRY *r_glUniform1iARB)(GLint location, GLint i);
GLvoid		(APIENTRY *r_glUniformMatrix4fvARB)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
GLvoid		(APIENTRY *r_glUniformMatrix3fvARB)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
GLvoid		(APIENTRY *r_glUniformMatrix2fvARB)(GLint location, GLsizei count, GLboolean transpose, GLfloat *value);
GLvoid		(APIENTRY *r_glGetShaderivARB)(GLuint shader,  GLenum pname,  GLint *params);
GLvoid		(APIENTRY *r_glGetProgramivARB)(GLuint shader,  GLenum pname,  GLint *params);

GLint       (APIENTRY *r_glGetAttribLocationARB)(GLhandleARB programObj, const char *name);
GLvoid		(APIENTRY *r_glVertexAttrib4fARB)(GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
GLvoid		(APIENTRY *r_glActiveTextureARB)(GLenum texture);

GLvoid		(APIENTRY *r_glBindAttribLocationARB)(GLhandleARB programObj, GLuint index, const char *name);
GLvoid		(APIENTRY *r_glVertexAttribPointerARB)(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);
GLvoid		(APIENTRY *r_glEnableVertexAttribArrayARB)(GLuint index);
GLvoid		(APIENTRY *r_glDisableVertexAttribArrayARB)(GLuint index);

GLvoid		(APIENTRY *r_glGetShaderInfoLog)(GLhandleARB object, GLsizei maxLenght, GLsizei *length, char *infoLog);
GLvoid		(APIENTRY *r_glGetProgramInfoLog)(GLhandleARB object, GLsizei maxLenght, GLsizei *length, char *infoLog);


RShader *p_current_shader = NULL;
uint p_current_textures[64] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
								-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
								-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
								-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};

/*
glGetShaderiv(shader, GL_COMPILE_STATUS, &bDidCompile)
glGetProgramiv(program, GL_LINK_STATUS, &bDidLink).*/

void r_shader_init(void)
{
	uint i;
#ifdef RELINQUISH_CONTEXT_OPENGLES
	r_glCreateShaderObjectARB =			glCreateShader;
	r_glDeleteObjectARB =				glDeleteShader;
	r_glCreateProgramObjectARB =		glCreateProgram;
	r_glAttachObjectARB =				glAttachShader;
	r_glShaderSourceARB =				glShaderSource;
	r_glCompileShaderARB =				glCompileShader;
	r_glLinkProgramARB =				glLinkProgram;
	r_glUseProgramObjectARB =			glUseProgram;
	r_glGetUniformLocationARB =			glGetUniformLocation;
	r_glUniform4fARB =					glUniform4f;
	r_glUniform3fARB =					glUniform3f;
	r_glUniform2fARB =					glUniform2f;
	r_glUniform1fARB =					glUniform1f;
	r_glUniform1iARB =					glUniform1i;
	r_glUniformMatrix4fvARB =			glUniformMatrix4fv;
	r_glUniformMatrix3fvARB =			glUniformMatrix3fv;
	r_glUniformMatrix2fvARB =			glUniformMatrix2fv;
	r_glGetShaderivARB =				glGetShaderiv;
	r_glGetProgramivARB =				glGetProgramiv;
	r_glBindAttribLocationARB =			glBindAttribLocation;
	r_glGetAttribLocationARB =			glGetAttribLocation;
	r_glVertexAttrib4fARB =				glVertexAttrib4f;
	r_glVertexAttribPointerARB =		glVertexAttribPointer;
	r_glEnableVertexAttribArrayARB =	glEnableVertexAttribArray;
	r_glDisableVertexAttribArrayARB =	glDisableVertexAttribArray;
	r_glActiveTextureARB =				glActiveTexture;
	r_glGetShaderInfoLog =					glGetShaderInfoLog;
	r_glGetProgramInfoLog =					glGetProgramInfoLog;

#endif
#ifdef RELINQUISH_CONTEXT_OPENGL
	if(r_extension_test("GL_ARB_shading_language_100"))
	{
		r_glCreateShaderObjectARB =			r_extension_get_address("glCreateShaderObjectARB");
		r_glDeleteObjectARB =				r_extension_get_address("glDeleteObjectARB");
		r_glCreateProgramObjectARB =		r_extension_get_address("glCreateProgramObjectARB");
		r_glAttachObjectARB =				r_extension_get_address("glAttachObjectARB");
		r_glShaderSourceARB =				r_extension_get_address("glShaderSourceARB");
		r_glCompileShaderARB =				r_extension_get_address("glCompileShaderARB");
		r_glLinkProgramARB =				r_extension_get_address("glLinkProgramARB");
		r_glUseProgramObjectARB =			r_extension_get_address("glUseProgramObjectARB");
		r_glGetUniformLocationARB =			r_extension_get_address("glGetUniformLocationARB");
		r_glUniform4fARB =					r_extension_get_address("glUniform4fARB");
		r_glUniform3fARB =					r_extension_get_address("glUniform3fARB");
		r_glUniform2fARB =					r_extension_get_address("glUniform2fARB");
		r_glUniform1fARB =					r_extension_get_address("glUniform1fARB");
		r_glUniform1iARB =					r_extension_get_address("glUniform1iARB");
		r_glUniformMatrix4fvARB =			r_extension_get_address("glUniformMatrix4fvARB");
		r_glUniformMatrix3fvARB =			r_extension_get_address("glUniformMatrix3fvARB");
		r_glUniformMatrix2fvARB =			r_extension_get_address("glUniformMatrix2fvARB");
		r_glGetShaderivARB =				r_extension_get_address("glGetShaderivARB");
		r_glGetProgramivARB =				r_extension_get_address("glGetProgramivARB");
		r_glBindAttribLocationARB =			r_extension_get_address("glBindAttribLocationARB");
		r_glGetAttribLocationARB =			r_extension_get_address("glGetAttribLocationARB");
		r_glVertexAttrib4fARB =				r_extension_get_address("glVertexAttrib4fARB");
		r_glVertexAttribPointerARB =		r_extension_get_address("glVertexAttribPointerARB");
		r_glEnableVertexAttribArrayARB =	r_extension_get_address("glEnableVertexAttribArrayARB");
		r_glDisableVertexAttribArrayARB =	r_extension_get_address("glDisableVertexAttribArrayARB");
		r_glActiveTextureARB =				r_extension_get_address("glActiveTextureARB");
		r_glGetShaderInfoLog =					r_extension_get_address("glGetInfoLogARB");
		r_glGetProgramInfoLog = r_glGetShaderInfoLog;
	}else
	{
		printf("RELINQUISH Error: Shaders not supported.\n");
		exit(0);
	}
#endif
	p_current_shader = NULL;
	for(i = 0; i < 64; i++)
		p_current_textures[i] = -1;
}

void r_shader_parse(RShaderInput *input, uint *count, char *source, char *key, uint start, uint end)
{
	uint i, j, k;
	for(i = 0; source[i] != 0; i++)
	{
		for(j = 0; source[i + j] != 0 && source[i + j] == key[j]; j++);
		if(key[j] == 0)
		{
			i += j;
			while(source[++i] <= 32);

			for(j = start; j < end; j++)
			{
				
				for(k = 0; source[i + k] != 0 && source[i + k] == r_type_names[j][k]; k++);
				if(r_type_names[j][k] == 0)
				{
					i += k;
					for(++i; source[i] <= 32 && source[i] != 0 && source[i] != ';'; i++);
					input[*count].type = j; 
					for(j = 0; source[i + j] > 32 && source[i + j] != 0 && source[i + j] != ';' && j < 32; j++)
						input[*count].name[j] = source[i + j];
					input[*count].name[j] = 0;
					(*count)++;
					break;
				}
			}
		}
	}
}


void r_shader_matrix_parse(RShader	*shader)
{
	char *name, *types[] = {"NormalMatrix", "ModelViewMatrix", "ProjectionMatrix", "ModelViewProjectionMatrix"};
	uint i, j;
	shader->normal_matrix = -1;
	shader->model_view_matrix = -1;
	shader->projection_matrix = -1;
	shader->model_view_projection_matrix = -1;
	for(i = 0; i < shader->uniform_count; i++)
	{
		if(shader->uniforms[i].type == R_SIT_MAT4)
		{
			name = shader->uniforms[i].name;
			for(j = 0; name[j] == types[0][j] && name[j] != 0; j++);
			if(name[j] == types[0][j])
				shader->normal_matrix = shader->uniforms[i].id;
			for(j = 0; name[j] == types[1][j] && name[j] != 0; j++);
			if(name[j] == types[1][j])
				shader->model_view_matrix = shader->uniforms[i].id;
			for(j = 0; name[j] == types[2][j] && name[j] != 0; j++);
			if(name[j] == types[2][j])
				shader->projection_matrix = shader->uniforms[i].id;
			for(j = 0; name[j] == types[3][j] && name[j] != 0; j++);
			if(name[j] == types[3][j])
				shader->model_view_projection_matrix = shader->uniforms[i].id;
		}
	}
}


#define GL_COMPILE_STATUS  0x8B81
//#define GL_LINK_STATUS    0x8b82

RShader	*r_shader_create(char *debug_output, uint output_size, char *vertex, char *fragment, char *name)
{
	uint vertex_obj, fragment_obj, prog_obj, i, attribute_count = 0, uniform_count = 0, texture_count = 0;
	int size = 0;
	RShaderInput input[256];
	RShader *shader;

	char output[1024];
	debug_output = output;
	output_size = 1024;

	prog_obj = r_glCreateProgramObjectARB();
	vertex_obj = r_glCreateShaderObjectARB(GL_VERTEX_SHADER_ARB);
	fragment_obj = r_glCreateShaderObjectARB(GL_FRAGMENT_SHADER_ARB);
	r_glAttachObjectARB(prog_obj, vertex_obj);
	r_glAttachObjectARB(prog_obj, fragment_obj);
	r_glShaderSourceARB(vertex_obj, 1, (const char **)&vertex, NULL);
	r_glCompileShaderARB(vertex_obj);
	if(debug_output != NULL)
	{
		printf("RELINQUISH: Shader Debug: %s\n", name);
		r_glGetShaderInfoLog(vertex_obj, output_size - size, &size, debug_output);
		//printf(debug_output);
	}
	output_size -= size;
	r_glShaderSourceARB(fragment_obj, 1, (const char **)&fragment, NULL);
	r_glCompileShaderARB(fragment_obj);
	if(debug_output != NULL)
	{
		r_glGetShaderInfoLog(fragment_obj, output_size - size, &size, debug_output);
		//printf(debug_output);
	}
	output_size -= size;
	r_shader_parse(input, &attribute_count, vertex, "attribute", 0, R_SIT_VDOUBLE4 + 1);
	r_shader_parse(&input[attribute_count], &uniform_count, vertex, "uniform", 0, R_SIT_DMAT4);
	r_shader_parse(&input[attribute_count], &uniform_count, fragment, "uniform", 0, R_SIT_DMAT4);
	r_shader_parse(&input[attribute_count + uniform_count], &texture_count, vertex, "uniform", R_SIT_SAMPLER_1D, R_SIT_COUNT);
	r_shader_parse(&input[attribute_count + uniform_count], &texture_count, fragment, "uniform", R_SIT_SAMPLER_1D, R_SIT_COUNT);

	shader = malloc(sizeof *shader);

	for(i = 0; i < 31 && name[i] != 0; i++)
		shader->name[i] = name[i];
	shader->name[i] = 0;
	shader->attribute_count = attribute_count;
	shader->attributes = malloc((sizeof *shader->attributes) * attribute_count);
	for(i = 0; i < attribute_count; i++)
	{
		shader->attributes[i] = input[i];
		shader->attributes[i].id = i;
		r_glBindAttribLocationARB(prog_obj, i, shader->attributes[i].name);
	}
	r_glLinkProgramARB(prog_obj);
	if(debug_output != NULL)
	{
		r_glGetProgramInfoLog(prog_obj, output_size - size, &size, debug_output);
		//printf(debug_output);
	}
	r_glUseProgramObjectARB(prog_obj);
	shader->uniform_count = uniform_count;
	shader->uniforms = malloc((sizeof *shader->uniforms) * uniform_count);
	for(i = 0; i < uniform_count; i++)
	{
		shader->uniforms[i] = input[i + attribute_count];
		shader->uniforms[i].id = r_glGetUniformLocationARB(prog_obj, shader->uniforms[i].name);
	}

	shader->texture_count = texture_count;
	shader->textures = malloc((sizeof *shader->textures) * texture_count);
	for(i = 0; i < texture_count; i++)
	{
		shader->textures[i] = input[i + attribute_count + uniform_count];
		shader->textures[i].id = i;
		r_glUniform1iARB(r_glGetUniformLocationARB(prog_obj, shader->textures[i].name), i);
	}
	shader->program = prog_obj;
	if(debug_output != NULL)
	{
		r_glGetProgramInfoLog(prog_obj, output_size - size, &size, debug_output);
		//printf(debug_output);
	}
	r_shader_matrix_parse(shader);
	return shader;
}


RShader	*r_shader_create_from_file(char *debug_output, uint output_size, const char *vertex_file, const char *fragment_file, char *name)
{
	RShader	*shader;
	uint size;
	char *vertex, *fragment;
	FILE *f;
	f = fopen(vertex_file, "r");
	if(f == NULL)
		return 0;
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	rewind(f);
	vertex = malloc(size + 1);
	size = fread(vertex, 1, size, f);
	fclose(f);
	vertex[size] = 0;
	f = fopen(fragment_file, "r");
	if(f == NULL)
	{
		free(vertex);
		return 0;
	}
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	rewind(f);
	fragment = malloc(size + 1);
	size = fread(fragment, 1, size, f);
	fclose(f);
	fragment[size] = 0;
//	printf(fragment);
//	printf(vertex);
	shader = r_shader_create(debug_output, output_size, vertex, fragment, name);
	free(fragment);
	free(vertex);
	return shader;
}

void r_shader_destroy(RShader	*s)
{
	if(s->attributes != NULL)
		free(s->attributes);
	if(s->uniforms != NULL)
		free(s->uniforms);
	if(s->textures != NULL)
		free(s->textures);
	r_glDeleteObjectARB(s->program);
	free(s);
}


/*
p_current_shader = 0;
static uint p_current_textures[64]*/

void r_matrix_shader_set(RMatrix *matrix, RShader *shader)
{ 
	if(shader->normal_matrix != -1)
	{
		float m[16], f, *m2;
		m2 = matrix->matrix[matrix->current];
		f = sqrt(m2[0] * m2[0] + m2[1] * m2[1] + m2[2] * m2[2]);
		m[0] = m2[0] / f;
		m[1] = m2[1] / f;
		m[2] = m2[2] / f;
		m[3] = 0.0;
		f = sqrt(m2[4] * m2[4] + m2[5] * m2[5] + m2[6] * m2[6]);
		m[4] = m2[4] / f;
		m[5] = m2[5] / f;
		m[6] = m2[6] / f;
		m[7] = 0.0;
		f = sqrt(m2[8] * m2[8] + m2[9] * m2[9] + m2[10] * m2[10]);
		m[8] = m2[8] / f;
		m[9] = m2[9] / f;
		m[10] = m2[10] / f;
		m[11] = 0.0;
		m[12] = 0.0;
		m[13] = 0.0;
		m[14] = 0.0;
		m[15] = 1.0;
		r_shader_mat4v_set(shader->normal_matrix, m);
	}
	if(shader->model_view_matrix != -1)
	{
		r_shader_mat4v_set(shader->model_view_matrix, matrix->matrix[matrix->current]);
	}
	if(shader->projection_matrix != -1)
	{
		r_shader_mat4v_set(shader->projection_matrix, matrix->projection);
	}
	if(shader->model_view_projection_matrix != -1)
	{
		if(!matrix->multiplied)
		{
			f_matrix_multiplyf(matrix->modelviewprojection, matrix->projection, matrix->matrix[matrix->current]);
			matrix->multiplied = TRUE;
		}
		r_shader_mat4v_set(shader->model_view_projection_matrix, matrix->modelviewprojection);
	}
}

boolean r_shader_set(RShader	*s)
{
	uint i;
/*	if(p_current_shader == s)
		return FALSE;
*/
	if(s == NULL)
	{
		r_glUseProgramObjectARB(0);
		p_current_shader = NULL;
		return TRUE;
	}

	for(i = 0; i < s->texture_count && i < 64; i++)
	{
		if(p_current_textures[i] != s->textures[i].id)
		{
			r_glActiveTextureARB(GL_TEXTURE0_ARB + i);
			glBindTexture(r_sampler_names[s->textures[i].type - R_SIT_SAMPLER_1D], s->textures[i].id);
		}
	}
	r_glUseProgramObjectARB(s->program);
	p_current_shader = s;
	return TRUE;
}
void unbind_textures()
{
	uint i;
	for(i = 0; i < 64; i++)
	{
		r_glActiveTextureARB(GL_TEXTURE0_ARB + i);
		glBindTexture(R_SIT_SAMPLER_2D, -1);
	}
}

void r_shader_texture_set(RShader *s, uint slot, uint texture_id)
{
	if(s == NULL)
	{
		printf("RELINQUISH Error: r_shader_active_texture shader is NULL.\n");
		return;
	}
	if(s->texture_count <= slot)
	{
		printf("RELINQUISH Error: r_shader_active_texture trying to set slot %u but %s only has %u slots.\n", slot, s->name, s->texture_count);
		return;
	}
	s->textures[slot].id = texture_id;
	if(p_current_shader == s)
	{
		r_glActiveTextureARB(GL_TEXTURE0_ARB + slot);
		glBindTexture(r_sampler_names[s->textures[slot].type - R_SIT_SAMPLER_1D], s->textures[slot].id);
	}

}

uint r_texture_gen(void *data, uint type, uint x_size, uint y_size, boolean alpha)
{
	uint texture_id;
	glEnable(GL_TEXTURE_2D);
	glGenTextures(1, &texture_id);
	glBindTexture(GL_TEXTURE_2D, texture_id);
	if(alpha)
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, x_size, y_size, 0, GL_RGBA, type, data);
	else
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, x_size, y_size, 0, GL_RGB, type, data);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glDisable(GL_TEXTURE_2D);
	return texture_id;
}

void r_shader_texture_unit_set(RShader	*s, char *name, uint id)
{

r_glUniform1iARB(r_glGetUniformLocationARB(s->program, name), id);
}

uint r_shader_uniform_location(RShader	*s, char *name)
{
	uint i, j;
	for(i = 0; i < s->texture_count; i++)
	{
		for(j = 0; name[j] != 0 && name[j] == s->textures[i].name[j]; j++);
		if(name[j] == s->textures[i].name[j])
			return i;
	}
	return r_glGetUniformLocationARB(s->program, name);
}

void r_shader_mat4v_set(uint location, float *matrix)
{
	r_glUniformMatrix4fvARB(location, 1, FALSE, matrix);
}

void r_shader_mat3v_set(uint location, float *matrix)
{
	r_glUniformMatrix3fvARB(location, 1, FALSE, matrix);
}

void r_shader_mat2v_set(uint location, float *matrix)
{
	r_glUniformMatrix2fvARB(location, 1, FALSE, matrix);
}

void r_shader_vec4_set(uint location, float v0, float v1, float v2, float v3)
{
	r_glUniform4fARB(location, v0, v1, v2, v3);
}

void r_shader_vec3_set(uint location, float v0, float v1, float v2)
{
	r_glUniform3fARB(location, v0, v1, v2);
}

void r_shader_vec2_set(uint location, float v0, float v1)
{
	r_glUniform2fARB(location, v0, v1);
}

void r_shader_float_set(uint location, float f)
{
	r_glUniform1fARB(location, f);
}
