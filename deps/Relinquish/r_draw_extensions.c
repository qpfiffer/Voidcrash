#include <GL/gl.h>
#include <GL/glext.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "forge.h"
#include "r_include.h"
#include "relinquish.h"


void *(*sui_gl_GetProcAddress)(const char* proc) = NULL;

void r_extension_init(void *(*glGetProcAddr)(const char* proc))
{
	sui_gl_GetProcAddress = glGetProcAddr;
}

void *r_extension_get_address(const char* proc)
{
	if(sui_gl_GetProcAddress == NULL)
		return NULL;
	else
		return sui_gl_GetProcAddress(proc);
}

boolean r_extension_test(const char *string)
{
	PFNGLGETSTRINGIPROC glGetStringi = (PFNGLGETSTRINGIPROC)sui_gl_GetProcAddress("glGetStringi");
	uint i = 0;
	int maximum = 0;
	glGetIntegerv(GL_NUM_EXTENSIONS, &maximum);
	for (i = 0; i < maximum; i++) {
		const unsigned char *extension = glGetStringi(GL_EXTENSIONS, i);
		printf("Extension: %s\n", extension);
		if (strcmp(string, (char *)extension) == 0)
			return TRUE;
	}

	return FALSE;
}

void r_primitive_init(void);
void r_shader_init(void);
void r_array_init(void);
void r_framebuffer_init(void);

void r_init(void *(*glGetProcAddr)(const char* proc))
{
	GLboolean (APIENTRY *SwapInterval)(int interval) = NULL;
	float fov = 9.0 / 16.0;
	r_matrix_set(NULL);
	r_matrix_identity(NULL);
	r_matrix_frustum(NULL, -0.05, 0.05, -0.05 * fov, 0.05 * fov, 0.05, 100.0f);
	r_extension_init(glGetProcAddr);
	SwapInterval = r_extension_get_address("wglSwapIntervalEXT");
	if(SwapInterval == NULL)
		SwapInterval = r_extension_get_address("glXSwapIntervalEXT");
//	if(SwapInterval != NULL)
//		SwapInterval(1); 
	r_shader_init();
	r_array_init();
	r_framebuffer_init();
	r_primitive_init();

}
