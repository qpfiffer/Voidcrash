#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "forge.h"
#include "r_include.h"
#include "relinquish.h"


#define GL_ARRAY_BUFFER_ARB                             0x8892
#define GL_DYNAMIC_DRAW_ARB                             0x88E8

boolean r_buffer_extension = FALSE;

GLvoid		(APIENTRY *r_glBindBufferARB)(uint target, uint buffer);
GLvoid		(APIENTRY *r_glDeleteBuffersARB)(uint n, const uint *buffers);
GLvoid		(APIENTRY *r_glGenBuffersARB)(uint n, uint *buffers);
GLvoid		(APIENTRY *r_glBufferDataARB)(uint target, uint size, const void *data, uint usage);
GLvoid		(APIENTRY *r_glBufferSubDataARB)(uint target, uint offset, uint size, const void *data);
GLvoid		(APIENTRY *r_glGetBufferSubDataARB)(uint target, uint offset, uint size, void *data);
GLvoid		(APIENTRY *r_glEnableVertexAttribArrayARB)(GLuint  index);
GLvoid		(APIENTRY *r_glDisableVertexAttribArrayARB)(GLuint  index);
GLvoid		(APIENTRY *r_glVertexAttribPointerARB)(GLuint  index,  GLint  size,  GLenum  type,  GLboolean  normalized,  GLsizei  stride,  const GLvoid *  pointer);

boolean r_array_attrib_mode[64] = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
									FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
									FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
									FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
									FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
									FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
									FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
									FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};
uint r_array_bound = 0;

typedef struct{
	uint vertex_start;
	uint vertex_count;
	void *prev;
	void *next;
}SUIArraySection;

typedef struct{
	uint gl_buffer;
	uint8 *data;
	SUIArraySection *sections_start;
	SUIArraySection *sections_end;
	uint array_length;
	uint array_used;
	uint vertex_size;
	SUIFormats vertex_format_types[64];
	uint vertex_format_size[64];
	uint vertex_format_count;
	boolean defragged;
}SUIArrayPool;

SUIArrayPool *r_array_pool_bound = NULL;

uint r_array_vertex_size(SUIFormats *vertex_format_types, uint *vertex_format_size, uint vertex_format_count)
{
	uint type_sizes[] = {sizeof(int8), sizeof(uint8), sizeof(int16), sizeof(uint16), sizeof(int32), sizeof(uint32), sizeof(float), sizeof(double)}, i, size = 0;
	for(i = 0; i < vertex_format_count; i++)
	{
/*		printf("vertex_format_types[%u] = %u\n", i, type_sizes[vertex_format_types[i]]);
		printf("vertex_format_size[%u] = %u\n", i, vertex_format_size[i]);
		printf("size %u\n", (type_sizes[vertex_format_types[i]] * vertex_format_size[i] + 3));
		printf("div %u\n", (type_sizes[vertex_format_types[i]] * vertex_format_size[i] + 3) / 4);
*/		size +=	(type_sizes[vertex_format_types[i]] * vertex_format_size[i] + 3) / 4; 
	}
	return size * 4;
}


void *r_array_allocate(uint vertex_count, SUIFormats *vertex_format_types, uint *vertex_format_size, uint vertex_format_count)
{
	uint i, size = 0;
	SUIArrayPool *p;
	p = malloc(sizeof *p);
	p->vertex_format_count = vertex_format_count;
	for(i = 0; i < vertex_format_count; i++)
	{
		p->vertex_format_types[i] = vertex_format_types[i];
		p->vertex_format_size[i] = vertex_format_size[i];
	}
	for(; i < 64; i++)
		p->vertex_format_size[i] = 0;

	size = r_array_vertex_size(vertex_format_types, vertex_format_size, vertex_format_count);

	if(r_buffer_extension)
	{
		r_glGenBuffersARB(1, &p->gl_buffer);
		r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, p->gl_buffer);
		r_glBufferDataARB(GL_ARRAY_BUFFER_ARB, vertex_count * size, NULL, GL_DYNAMIC_DRAW_ARB);
		r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, r_array_bound);
		p->data = NULL;
	}else
	{
		p->gl_buffer = 0;
		p->data = malloc(vertex_count * size);
	}
	p->sections_start = NULL;
	p->sections_end = NULL;
	p->array_length = vertex_count;
	p->array_used = 0;

	p->vertex_size = size;
	p->defragged = TRUE;
	return p;
}



void r_array_free(void *pool)
{
	SUIArraySection *sections, *next;
	SUIArrayPool *p;
	if(pool == NULL)
		return;
	
	p = pool;

	if(p->data != NULL)
		free(p->data);

	if(p->gl_buffer != 0)
		r_glDeleteBuffersARB(1, &p->gl_buffer);

	for(sections = p->sections_start; sections != NULL; sections = next)
	{
		next = sections->next;
		free(sections);
	}
	free(p);
}

void r_array_section_move(SUIArrayPool *pool, uint last_pos, uint new_pos, uint size)
{
	uint *from, *to, i;
	if(pool->data != NULL)
	{
		from = (uint *)&pool->data[last_pos / 4];
		to = (uint *)&pool->data[new_pos / 4];
		size /= 4;
		for(i = 0; i < size; i++)
			to[i] = from[i];
	}
	if(pool->gl_buffer != 0)
	{
		void *copy_array;
		copy_array = malloc(size);
		r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, pool->gl_buffer);
		r_glGetBufferSubDataARB(GL_ARRAY_BUFFER_ARB, last_pos, size, copy_array);
		r_glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, new_pos, size, copy_array);
		free(copy_array);
	}
}

boolean r_array_defrag(void *pool)
{
	SUIArrayPool *p;
	SUIArraySection *sections, *next;
	p = pool;
	if(p->defragged)
		return FALSE;
//	fprintf(stderr, "Working\n");

	if(r_array_bound != p->gl_buffer && p->gl_buffer != 0)
		r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, p->gl_buffer);

	for(sections = p->sections_start; sections != NULL; sections = sections->next)
	{
		next = sections->next;
		if(next == NULL)
			break;
		if(sections->vertex_start + sections->vertex_count != next->vertex_start)
		{
			/* found a gap so we will move a block down to close the gap */
			r_array_section_move(p, next->vertex_start * p->vertex_size, (sections->vertex_start + sections->vertex_count) * p->vertex_size, sections->vertex_count * p->vertex_size);
			next->vertex_start = sections->vertex_start + sections->vertex_count;
			if(r_array_bound != p->gl_buffer && p->gl_buffer != 0)
				r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, r_array_bound);
//	fprintf(stderr, "Defraging\n");	
			return TRUE;
		}
	}
	if(r_array_bound != p->gl_buffer && p->gl_buffer != 0)
		r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, r_array_bound);
	p->defragged = TRUE;
	return FALSE;
}

void *r_array_section_allocate(void *pool, uint size)
{
	SUIArrayPool *p;
	SUIArraySection *section, *s;
	uint pos;
	p = pool;

	if(p->array_used + size > p->array_length) /* there is no space no matter */
	{
		printf("there is no space no matter %u %u %u\n", p->array_used, size, p->array_length);
		exit(0);
		return NULL;
	}
	section = malloc(sizeof *section);
	section->vertex_count = size;
	p->array_used += size;

	if(p->sections_start == NULL) // no section exists
	{
		p->sections_start = section;
		p->sections_end = section;
		section->next = section->prev = NULL;
		section->vertex_start = 0;
		return section;
	}else
	{
		s = p->sections_end;
		if(p->array_length >= s->vertex_start + s->vertex_count + size) // add new section to end of array
		{
			s->next = section;
			p->sections_end = section;
			section->next = NULL;
			section->prev = s;
			section->vertex_start = s->vertex_start + s->vertex_count;
			return section;
		}
		/* try to find a hole in the array of sections where the new section fits */
		pos = 0;
		for(s = p->sections_start; s != NULL; s = s->next)
		{
			if(pos + size <= s->vertex_start) /* Found a hole */
			{
				if(s->prev == NULL)
					p->sections_start = section;
				else
					((SUIArraySection *)s->prev)->next = section;
				section->prev = s->prev;
				section->next = s;
				s->prev = section;
				section->vertex_start = pos;
				return section;
			}
			pos = s->vertex_start + s->vertex_count;
		}
		/* lets do it again, but this time we start to defrag the segments to eventiualy find a gap big enough */
		pos = 0;
		if(r_array_bound != p->gl_buffer && p->gl_buffer != 0)
			r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, p->gl_buffer);
		for(s = p->sections_start; s != NULL; s = s->next)
		{
			if(pos + size <= s->vertex_start) /* Found a hole big enough */
			{
				if(s->prev == NULL)
					p->sections_start = section;
				else
					((SUIArraySection *)s->prev)->next = section;
				section->prev = s->prev;
				section->next = s;
				s->prev = section;
				section->vertex_start = pos;
				return section;
			}
			if(pos != s->vertex_start) /* move back a section to close the gap. */
			{
				r_array_section_move(p, pos * p->vertex_size, s->vertex_start * p->vertex_size, s->vertex_count * p->vertex_size);
				s->vertex_start = pos;
			}
			pos = s->vertex_start + s->vertex_count;
		}
		if(r_array_bound != p->gl_buffer && p->gl_buffer != 0)
			r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, r_array_bound);
		/* add to the end */
		s = p->sections_end;
		s->next = section;
		p->sections_end = section;
		section->next = NULL;
		section->prev = s;
		section->vertex_start = s->vertex_start + s->vertex_count;
		return section;
	}
	return NULL;
}

void r_array_section_free(void *pool, void *section)
{
	SUIArrayPool *p;
	SUIArraySection *s;
	p = pool;
	s = section;
	p->array_used -= s->vertex_count;

	if(s->next == NULL)
		p->sections_end = s->prev;
	else
		((SUIArraySection *)s->next)->prev = s->prev;

	if(s->prev == NULL)
		p->sections_start = s->next;
	else
		((SUIArraySection *)s->prev)->next = s->next;
	free(s);
}


void  r_array_init(void)
{
	uint i;
#ifdef RELINQUISH_CONTEXT_OPENGLES
	r_glBindBufferARB = glBindBuffer;
	r_glDeleteBuffersARB = glDeleteBuffers;
	r_glGenBuffersARB = glGenBuffers;
	r_glBufferDataARB = glBufferData;
	r_glBufferSubDataARB = glBufferSubData;
//	r_glGetBufferSubDataARB = glGetBufferSubData;

	r_glVertexAttribPointerARB = glVertexAttribPointer;
	r_glEnableVertexAttribArrayARB = glEnableVertexAttribArray;
	r_glDisableVertexAttribArrayARB = glDisableVertexAttribArray;
	r_buffer_extension = TRUE;
#endif 
#ifdef RELINQUISH_CONTEXT_OPENGL
	r_buffer_extension = r_extension_test("GL_ARB_vertex_buffer_object");
	r_buffer_extension = FALSE;
	if(r_buffer_extension)
	{
		r_glBindBufferARB = r_extension_get_address("glBindBufferARB");
		r_glDeleteBuffersARB = r_extension_get_address("glDeleteBuffersARB");
		r_glGenBuffersARB = r_extension_get_address("glGenBuffersARB");
		r_glBufferDataARB = r_extension_get_address("glBufferDataARB");
		r_glBufferSubDataARB = r_extension_get_address("glBufferSubDataARB");
		r_glGetBufferSubDataARB = r_extension_get_address("glGetBufferSubDataARB");

	}
	r_glVertexAttribPointerARB = r_extension_get_address("glVertexAttribPointerARB");
	r_glEnableVertexAttribArrayARB = r_extension_get_address("glEnableVertexAttribArrayARB");
	r_glDisableVertexAttribArrayARB = r_extension_get_address("glDisableVertexAttribArrayARB");
#endif
	r_array_bound = 0;
	for(i = 0; i < 64; i++)
		r_array_attrib_mode[i] = FALSE;
}

float *sui_vertex_tmp = NULL;
/*
void r_array_active_vertex_normal_texcoord_color(void *pool)
{
	static uint types[] = {GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT, GL_UNSIGNED_SHORT, GL_INT, GL_UNSIGNED_INT, GL_FLOAT, GL_DOUBLE};
	uint type_sizes[] = {1, 1, 2, 2, 4, 4, 4, 8}, i, size;
	SUIArrayPool *p;
	p = pool;

	if(sui_array_bound != p->gl_buffer && p->gl_buffer != 0)
	{
		sui_glBindBufferARB(GL_ARRAY_BUFFER_ARB, p->gl_buffer);
		sui_array_bound = p->gl_buffer;
	}

	for(i = 0; i < 64; i++)
	{
		if(sui_array_attrib_mode[i])
		{
			sui_array_attrib_mode[i] = FALSE;
			r_glDisableVertexAttribArrayARB(i);
		}
	}
	glVertexPointer(p->vertex_format_size[0], types[p->vertex_format_types[0]], p->vertex_size, p->data);
	sui_vertex_tmp = p->data;
	if(!sui_array_fixed_mode[0])
	{
		glEnableClientState(GL_VERTEX_ARRAY);
		sui_array_fixed_mode[0] = TRUE;
	}

	size = (p->vertex_format_types[0] * p->vertex_format_size[0] + 3) / 4; 
	if(p->vertex_format_size[1] != 0)
	{
		if(!sui_array_fixed_mode[1])
		{
			glEnableClientState(GL_NORMAL_ARRAY);
			sui_array_fixed_mode[1] = TRUE;
		}
		glNormalPointer(types[p->vertex_format_types[1]], p->vertex_size, &p->data[size * 4]);
	}else if(sui_array_fixed_mode[1])
	{
		glDisableClientState(GL_NORMAL_ARRAY);
		sui_array_fixed_mode[1] = FALSE;
	}
	size +=	(p->vertex_format_types[1] * p->vertex_format_size[1] + 3) / 4; 

	if(p->vertex_format_size[2] != 0)
	{
		if(!sui_array_fixed_mode[2])
		{
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			sui_array_fixed_mode[2] = TRUE;
		}
		glTexCoordPointer(p->vertex_format_size[2], types[p->vertex_format_types[2]], p->vertex_size, &p->data[size * 4]);
	}else if(sui_array_fixed_mode[2])
	{
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		sui_array_fixed_mode[2] = FALSE;
	}
	size +=	(p->vertex_format_types[2] * p->vertex_format_size[2] + 3) / 4; 

	if(p->vertex_format_size[3] != 0)
	{
		if(!sui_array_fixed_mode[3])
		{
			glEnableClientState(GL_COLOR_ARRAY);
			sui_array_fixed_mode[3] = TRUE;
		}
		glColorPointer(p->vertex_format_size[3], types[p->vertex_format_types[3]], p->vertex_size, &p->data[size * 4]); 
	}else if(sui_array_fixed_mode[3])
	{
		glDisableClientState(GL_COLOR_ARRAY);
		sui_array_fixed_mode[3] = FALSE;
	}
}
*/

void r_array_vertex_atrib_set(void *pool)
{
	static uint types[] = {GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT, GL_UNSIGNED_SHORT, GL_INT, GL_UNSIGNED_INT, GL_FLOAT, GL_DOUBLE};
	uint type_sizes[] = {1, 1, 2, 2, 4, 4, 4, 8}, i, size = 0;
	SUIArrayPool *p;
	p = pool;
	r_array_pool_bound = pool;
	if(r_array_bound != p->gl_buffer && p->gl_buffer != 0)
	{
		r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, p->gl_buffer);
		r_array_bound = p->gl_buffer;
	}

	for(i = 0; i < p->vertex_format_count; i++)
	{
		r_glVertexAttribPointerARB(i, p->vertex_format_size[i], types[p->vertex_format_types[i]], FALSE, p->vertex_size, &p->data[size * 4]);
		if(!r_array_attrib_mode[i])
			r_glEnableVertexAttribArrayARB(i);
		r_array_attrib_mode[i] = TRUE;
		size += (type_sizes[p->vertex_format_types[i]] * p->vertex_format_size[i] + 3) / 4; 
	}
	for(; i < 64; i++)
	{
		if(r_array_attrib_mode[i])
		{
			r_array_attrib_mode[i] = FALSE;
			r_glDisableVertexAttribArrayARB(i);
		}
	}
}

void r_array_deactivate()
{
	uint i;
	r_array_pool_bound = NULL;
	if(r_array_bound != 0)
	{
		r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
		r_array_bound = 0;
	}
	for(i = 0; i < 64; i++)
		r_glDisableVertexAttribArrayARB(i);
}

void r_array_load_vertex(void *pool, struct SUIArraySection *section, void *data, uint start, uint length)
{
	SUIArrayPool *p;
	p = pool;
	if(section != NULL)
	{
		if(((SUIArraySection *)section)->vertex_count < length)
			length = ((SUIArraySection *)section)->vertex_count;

		if(p->data != NULL)
			memcpy(&p->data[(((SUIArraySection *)section)->vertex_start + start) * p->vertex_size], 
			data, 
			length * p->vertex_size);

		if(p->gl_buffer != 0)
		{
			if(r_array_bound != p->gl_buffer)
				r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, p->gl_buffer);
			r_glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, (((SUIArraySection *)section)->vertex_start + start) * p->vertex_size, length * p->vertex_size, data);
			if(r_array_bound != p->gl_buffer)
				r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, r_array_bound);
		}
	}else
	{
		if(p->array_length + start < length)
		{
			length = p->array_length - start;
		}
		if(p->data != NULL)
		{
			memcpy(&p->data[start * p->vertex_size], 
			data, 
			length * p->vertex_size);
		}
		if(p->gl_buffer != 0)
		{
			if(r_array_bound != p->gl_buffer)
				r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, p->gl_buffer);
			r_glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, start * p->vertex_size, length * p->vertex_size, data);
			if(r_array_bound != p->gl_buffer)
				r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, r_array_bound);
		}
	}
}

void r_array_load_reference(void *pool, void *section, uint *reference, uint length)
{
	SUIArrayPool *p;
	p = pool;

	if(r_array_pool_bound != pool)
		r_array_vertex_atrib_set(pool);

	if(p->data != NULL)
		memcpy(&p->data[((SUIArraySection *)section)->vertex_start * p->vertex_size], reference, length * sizeof(uint32));

	if(p->gl_buffer != 0)
	{
		if(r_array_bound != p->gl_buffer)
			r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, p->gl_buffer);
		r_glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, (((SUIArraySection *)section)->vertex_start) * p->vertex_size, length * sizeof(uint32), reference);
		if(r_array_bound != p->gl_buffer)
			r_glBindBufferARB(GL_ARRAY_BUFFER_ARB, r_array_bound);
	}
}/*
ern void		r_array_load_vertex(void *pool, void *section, void *data, uint start, uint length);
extern void		r_array_load_reference(void *pool, void *section, uint *data, void *vertex_section, uint length);

*/
uint r_array_get_size(void *pool)
{
	return ((SUIArrayPool *)pool)->array_length;
}

uint r_array_get_used(void *pool)
{
	return ((SUIArrayPool *)pool)->array_used;
}

uint r_array_get_left(void *pool)
{
	return ((SUIArrayPool *)pool)->array_length - ((SUIArrayPool *)pool)->array_used;
}

uint r_array_get_vertex_size(void *pool)
{
	return ((SUIArrayPool *)pool)->vertex_size;
}

uint r_array_section_get_vertex_count(void *section)
{
	return ((SUIArraySection *)section)->vertex_count;
}

uint r_array_section_get_vertex_start(void *section)
{
	return ((SUIArraySection *)section)->vertex_start;
}

extern void r_matrix_shader_set(RMatrix *matrix, RShader *shader);

void r_array_section_draw(void *pool, void *section, uint primitive_type, uint vertex_start, uint vertex_count)
{
//	if(r_array_pool_bound != pool)
		r_array_vertex_atrib_set(pool);
	r_matrix_shader_set(r_matrix_state, p_current_shader);
	if(section != NULL)
	{	
		SUIArraySection *s;
		s = section;
		if(vertex_count > s->vertex_count)
			vertex_count = s->vertex_count;

		glDrawArrays(primitive_type, s->vertex_start + vertex_start, vertex_count);
	}else
	{
		SUIArrayPool *p;
		p = pool;
		if(vertex_count > p->array_length)
			vertex_count = p->array_length;
		glDrawArrays(primitive_type, vertex_start, vertex_count);
	}
}

void r_array_reference_draw(void *pool, void *section, uint primitive_type, uint vertex_start, uint vertex_count)
{
//	if(r_array_pool_bound != pool)
		r_array_vertex_atrib_set(pool);
	if(p_current_shader != NULL)
		r_matrix_shader_set(r_matrix_state, p_current_shader);
	if(section != NULL)
	{	
		uint *p;
		if(vertex_count > ((SUIArraySection *)section)->vertex_count * ((SUIArrayPool *)pool)->vertex_size / 4 - vertex_start)
			vertex_count = ((SUIArraySection *)section)->vertex_count * ((SUIArrayPool *)pool)->vertex_size / 4 - vertex_start;
		p = (uint *)((SUIArrayPool *)pool)->data;
		p = &p[((SUIArraySection *)section)->vertex_start * ((SUIArrayPool *)pool)->vertex_size / 4 + vertex_start];
		glDrawElements(primitive_type, vertex_count, GL_UNSIGNED_INT, p);
	}
}

void sui_array_section_draw_element(void *vertex_section, uint primitive_type, uint ref_type, void *ref_section, uint ref_count)
{
	r_matrix_shader_set(r_matrix_state, p_current_shader);
/*	(((SUIArraySection *)section)->vertex_start + vertex_start) * 
	glDrawElements(primitive_type, ref_count, ref_type, ref_section);*/
}
