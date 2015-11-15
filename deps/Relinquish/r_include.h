#include "betray.h"

#ifdef BETRAY_CONTEXT_OPENGLES
#define RELINQUISH_CONTEXT_OPENGLES
#endif
#ifdef BETRAY_CONTEXT_OPENGL
#define RELINQUISH_CONTEXT_OPENGL
#endif

#define R_INTERNAL

#define GL_TEXTURE0_ARB								0x84C0

#define GL_FRAMEBUFFER_EXT                     0x8D40
#define GL_RENDERBUFFER_EXT                    0x8D41

#define GL_STENCIL_INDEX1_EXT                  0x8D46
#define GL_STENCIL_INDEX4_EXT                  0x8D47
#define GL_STENCIL_INDEX8_EXT                  0x8D48
#define GL_STENCIL_INDEX16_EXT                 0x8D49

#define GL_RENDERBUFFER_WIDTH_EXT              0x8D42
#define GL_RENDERBUFFER_HEIGHT_EXT             0x8D43
#define GL_RENDERBUFFER_INTERNAL_FORMAT_EXT    0x8D44
#define GL_RENDERBUFFER_RED_SIZE_EXT           0x8D50
#define GL_RENDERBUFFER_GREEN_SIZE_EXT         0x8D51
#define GL_RENDERBUFFER_BLUE_SIZE_EXT          0x8D52
#define GL_RENDERBUFFER_ALPHA_SIZE_EXT         0x8D53
#define GL_RENDERBUFFER_DEPTH_SIZE_EXT         0x8D54
#define GL_RENDERBUFFER_STENCIL_SIZE_EXT       0x8D55

#define GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE_EXT            0x8CD0
#define GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_EXT            0x8CD1
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL_EXT          0x8CD2
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE_EXT  0x8CD3
#define GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_3D_ZOFFSET_EXT     0x8CD4

#define GL_COLOR_ATTACHMENT0_EXT                0x8CE0
#define GL_DEPTH_ATTACHMENT_EXT                 0x8D00
#define GL_STENCIL_ATTACHMENT_EXT               0x8D20

#define GL_FRAMEBUFFER_COMPLETE_EXT                          0x8CD5
#define GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT             0x8CD6
#define GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT     0x8CD7
#define GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT             0x8CD9
#define GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT                0x8CDA
#define GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT            0x8CDB
#define GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT            0x8CDC
#define GL_FRAMEBUFFER_UNSUPPORTED_EXT                       0x8CDD

#define GL_FRAMEBUFFER_BINDING_EXT             0x8CA6
#define GL_RENDERBUFFER_BINDING_EXT            0x8CA7
#define GL_MAX_COLOR_ATTACHMENTS_EXT           0x8CDF
#define GL_MAX_RENDERBUFFER_SIZE_EXT           0x84E8

#define GL_DEPTH_COMPONENT16				0x81A5
#define GL_DEPTH_COMPONENT24              0x81A6
#define GL_DEPTH_COMPONENT32              0x81A7
#define GL_STENCIL_INDEX8	             0x8D48
#define GL_CLAMP_TO_EDGE                  0x812F

#define GL_EXT_texture_cube_map             1 
#define GL_NORMAL_MAP_EXT                   0x8511 
#define GL_REFLECTION_MAP_EXT               0x8512 
#define GL_TEXTURE_CUBE_MAP_EXT             0x8513 
#define GL_TEXTURE_BINDING_CUBE_MAP_EXT     0x8514 
#define GL_TEXTURE_CUBE_MAP_POSITIVE_X_EXT  0x8515 
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_X_EXT  0x8516 
#define GL_TEXTURE_CUBE_MAP_POSITIVE_Y_EXT  0x8517 
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_EXT  0x8518 
#define GL_TEXTURE_CUBE_MAP_POSITIVE_Z_EXT  0x8519 
#define GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_EXT  0x851A 
#define GL_PROXY_TEXTURE_CUBE_MAP_EXT       0x851B 
#define GL_MAX_CUBE_MAP_TEXTURE_SIZE_EXT    0x851C 

#define GL_VERTEX_SHADER_ARB                        0x8B31
#define GL_FRAGMENT_SHADER_ARB                      0x8B30

typedef uint GLhandleARB;

typedef enum{
	R_SIT_BOOL,
	R_SIT_VBOOL2,
	R_SIT_VBOOL3,
	R_SIT_VBOOL4,
	R_SIT_INT,
	R_SIT_VINT2,
	R_SIT_VINT3,
	R_SIT_VINT4,
	R_SIT_UINT,
	R_SIT_VUINT2,
	R_SIT_VUINT3,
	R_SIT_VUINT4,
	R_SIT_FLOAT,
	R_SIT_VEC2,
	R_SIT_VEC3,
	R_SIT_VEC4,
	R_SIT_DOUBLE,
	R_SIT_VDOUBLE2,
	R_SIT_VDOUBLE3,
	R_SIT_VDOUBLE4,
	R_SIT_MAT2,
	R_SIT_MAT2X3,
	R_SIT_MAT2X4,
	R_SIT_MAT3X2,
	R_SIT_MAT3,
	R_SIT_MAT3X4,
	R_SIT_MAT4X2,
	R_SIT_MAT4X3,
	R_SIT_MAT4,
	R_SIT_DMAT2,
	R_SIT_DMAT2X3,
	R_SIT_DMAT2X4,
	R_SIT_DMAT3X2,
	R_SIT_DMAT3,
	R_SIT_DMAT3X4,
	R_SIT_DMAT4X2,
	R_SIT_DMAT4X3,
	R_SIT_DMAT4,
	R_SIT_SAMPLER_1D,
	R_SIT_SAMPLER_2D,
	R_SIT_SAMPLER_3D,
	R_SIT_SAMPLER_CUBE,
	R_SIT_SAMPLER_RECTANGLE,
	R_SIT_SAMPLER_1D_ARRAY,
	R_SIT_SAMPLER_2D_ARRAY,
	R_SIT_SAMPLER_CUBE_MAP_ARRAY,
	R_SIT_SAMPLER_BUFFER,
	R_SIT_SAMPLER_2D_MULTISAMPLE,
	R_SIT_SAMPLER_2D_MULTISAMPLE_ARRAY,
	R_SIT_COUNT
}RShaderInputType;



typedef struct{
	char name[32];
	RShaderInputType type;
	uint id;
}RShaderInput;

typedef struct{
	uint program;
	char name[32];
	RShaderInput *textures;
	uint texture_count;
	RShaderInput *attributes;
	uint attribute_count;
	RShaderInput *uniforms;
	uint uniform_count;
	uint normal_matrix;
	uint model_view_matrix;
	uint projection_matrix;
	uint model_view_projection_matrix;
}RShader;

extern RShader *p_current_shader; 
extern void *r_matrix_state;

