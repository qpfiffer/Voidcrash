#include "betray_plugin_api.h"
#include "relinquish.h"
#define OVR_OS_WIN32
#include <Kernel/OVR_System.h>
#include "OVR_CAPI_GL.h"
#include <stdio.h>
#include <math.h>

ovrEyeRenderDesc eye_render_desc[2];
ovrHmd current_hmd;
uint render_size[2] = {1024 , 1024};
uint render_fbos[2];
ovrGLTexture render_textures[2];
uint depth_buffer[2];
ovrVector3f eye_vectors[2];

ovrSwapTextureSet *texture_set[2];

boolean betray_plugin_image_warp(BInputState *input)
{
		static FILE *file = NULL;
        // Keyboard inputs to adjust player orientation
        static float Yaw(3.141592f);  

		// Get eye poses, feeding in correct IPD offset
        ovrVector3f               ViewOffset[2] = { eye_render_desc[0].HmdToEyeViewOffset,
                                                    eye_render_desc[1].HmdToEyeViewOffset };
        ovrPosef                  EyeRenderPose[2];

        ovrFrameTiming   ftiming = ovrHmd_GetFrameTiming(current_hmd, 0);
        ovrTrackingState hmdState = ovrHmd_GetTrackingState(current_hmd, ftiming.DisplayMidpointSeconds);
        ovr_CalcEyePoses(hmdState.HeadPose.ThePose, ViewOffset, EyeRenderPose);

		if(file == NULL)
			file = fopen("Debug_file.txt", "w");

        {
			ovrTrackingState tracking_state;
			ovrHmd_GetFrameTiming(current_hmd, input->frame_number);
			tracking_state = ovrHmd_GetTrackingState(current_hmd, 0.0);
            for(int eye = 0; eye < 2; eye++)
            {
				uint fbo;
				float view[3] = {0, 0, 1}, vec[3];
				float matrix[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};
                // Increment to use next texture, just before writing
                texture_set[eye]->CurrentIndex = (texture_set[eye]->CurrentIndex + 1) % texture_set[eye]->TextureCount;
				ovrGLTexture* tex = (ovrGLTexture*)&texture_set[eye]->Textures[texture_set[eye]->CurrentIndex];
				fbo = r_framebuffer_allocate(FALSE, &tex->OGL.TexId, 1, depth_buffer[eye]);
				f_quaternion_to_matrixf(matrix, EyeRenderPose[eye].Orientation.x, EyeRenderPose[eye].Orientation.y, EyeRenderPose[eye].Orientation.z, EyeRenderPose[eye].Orientation.w); 
				matrix[12] = -EyeRenderPose[eye].Position.x * 1.0;
				matrix[13] = -EyeRenderPose[eye].Position.y * 1.0;
				matrix[14] = -EyeRenderPose[eye].Position.z * 1.0;

				fprintf(file, "Eye %f %f %f %f\n", current_hmd->DefaultEyeFov[eye].LeftTan, current_hmd->DefaultEyeFov[eye].RightTan, current_hmd->DefaultEyeFov[eye].UpTan, current_hmd->DefaultEyeFov[eye].DownTan);
				
				if(input->pointers[0].pointer_x > 0)
				{
					view[2] = 2 / (current_hmd->DefaultEyeFov[eye].LeftTan + current_hmd->DefaultEyeFov[eye].RightTan);
					view[1] = current_hmd->DefaultEyeFov[eye].UpTan / (current_hmd->DefaultEyeFov[eye].UpTan + current_hmd->DefaultEyeFov[eye].DownTan);
					view[0] = current_hmd->DefaultEyeFov[eye].LeftTan / (current_hmd->DefaultEyeFov[eye].LeftTan + current_hmd->DefaultEyeFov[eye].RightTan);
				}
				betray_plugin_application_draw(fbo, render_size[0], render_size[1], view, TRUE, matrix);
				r_framebuffer_free(fbo);
            	// Avoids an error when calling SetAndClearRenderSurface during next iteration.
            	// Without this, during the next while loop iteration SetAndClearRenderSurface
            	// would bind a framebuffer with an invalid COLOR_ATTACHMENT0 because the texture ID
            	// associated with COLOR_ATTACHMENT0 had been unlocked by calling wglDXUnlockObjectsNV.
          //  	eyeRenderTexture[eye]->UnsetRenderSurface();
			
			/*	glBindFramebuffer(GL_FRAMEBUFFER, fboId);
		        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);	
		        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, 0, 0);*/
            }
        }

        // Do distortion rendering, Present and flush/sync

        // Set up positional data.
        ovrViewScaleDesc viewScaleDesc;
        viewScaleDesc.HmdSpaceToWorldScaleInMeters = 1.0f;
        viewScaleDesc.HmdToEyeViewOffset[0] = ViewOffset[0];
        viewScaleDesc.HmdToEyeViewOffset[1] = ViewOffset[1];

        ovrLayerEyeFov ld;
        ld.Header.Type  = ovrLayerType_EyeFov;
        ld.Header.Flags = ovrLayerFlag_TextureOriginAtBottomLeft;   // Because OpenGL.

        for (int eye = 0; eye < 2; eye++)
        {
            ld.ColorTexture[eye] = texture_set[eye];
            ld.Viewport[eye].Size.w = render_size[0];
            ld.Viewport[eye].Size.h = render_size[1];
            ld.Viewport[eye].Pos.x = 0;
            ld.Viewport[eye].Pos.y = 0;
            ld.Fov[eye]          = current_hmd->DefaultEyeFov[eye];
            ld.RenderPose[eye]   = EyeRenderPose[eye];
        }

        ovrLayerHeader* layers = &ld.Header;
        ovrResult result = ovrHmd_SubmitFrame(current_hmd, 0, &viewScaleDesc, &layers, 1);
      //  isVisible = result == ovrSuccess;

        // Blit mirror texture to back buffer
    /*    glBindFramebuffer(GL_READ_FRAMEBUFFER, mirrorFBO);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
        GLint w = mirrorTexture->OGL.Header.TextureSize.w;
        GLint h = mirrorTexture->OGL.Header.TextureSize.h;
        glBlitFramebuffer(0, h, w, 0,
                          0, 0, w, h,
                          GL_COLOR_BUFFER_BIT, GL_NEAREST);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);*/

/*	ovrPosef outEyePoses[2];
	ovrTrackingState outHmdTrackingState;
	ovrFrameTiming time;
	ovrVector3f hmdToEyeViewOffset[2];
	float matrix[16];
	float view[3] = {0, 0, 1};
	uint i;
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	time = ovrHmd_BeginFrame(current_hmd, 0);
	ovrHmd_GetEyePoses(current_hmd, 0, eye_vectors,
                                   outEyePoses, &outHmdTrackingState);
	
	for(i = 0; i < 2; i++)
	{
		f_quaternion_to_matrixf(matrix, outEyePoses[i].Orientation.x, outEyePoses[i].Orientation.y, outEyePoses[i].Orientation.z, outEyePoses[i].Orientation.w);
		matrix[12] = outEyePoses[i].Position.x;
		matrix[13] = outEyePoses[i].Position.y;
		matrix[14] = outEyePoses[i].Position.z;
		betray_plugin_application_draw(render_fbos[i], render_size[0], render_size[1], view, TRUE, matrix);
	}
	ovrHmd_EndFrame(current_hmd, outEyePoses, (ovrTexture *)render_textures);*/
	return TRUE;
}


extern "C" void betray_plugin_init(void)
{
	uint i;
    OVR::System::Init();
	ovrResult result;
     // Initialise rift
    if(ovr_Initialize(nullptr) != ovrSuccess)
	{
		MessageBoxA(NULL, "Unable to initialize libOVR.", "", MB_OK); 
		return;
	}
	
    result = ovrHmd_Create(0, &current_hmd);
    if(result != ovrSuccess)
        result = ovrHmd_CreateDebug(ovrHmd_DK2, &current_hmd);

    if(result != ovrSuccess) 
	{   
		MessageBoxA(NULL,"Oculus Rift not detected.","", MB_OK); ovr_Shutdown();
		return;
	}
    if (current_hmd->ProductName[0] == '\0')
	{
		MessageBoxA(NULL,"Rift detected, display not enabled.","", MB_OK);
		return;
	}

    // Setup Window and Graphics
    // Note: the mirror window can be any size, for this sample we use 1/2 the HMD resolution
	betray_plugin_callback_set_image_warp(betray_plugin_image_warp, "Occulus Rift");
	r_init((void *(*)(const char*))betray_plugin_gl_proc_address_get());
 
	

    // Make eye render buffers
	uint eyeRenderTexture[2];
    uint eyeDepthBuffer[2];
    for(i = 0; i < 2; i++)
    {
        ovrSizei idealTextureSize = ovrHmd_GetFovTextureSize(current_hmd, (ovrEyeType)i, current_hmd->DefaultEyeFov[i], 1);
		
		ovrHmd_CreateSwapTextureSetGL(current_hmd, GL_RGBA, idealTextureSize.w, idealTextureSize.h, &texture_set[i]);
		render_size[0] = idealTextureSize.w;
		render_size[1] = idealTextureSize.h;
		eyeRenderTexture[i] = r_texture_allocate(R_IF_RGBA_UINT8, idealTextureSize.w, idealTextureSize.h, 1, TRUE, TRUE, NULL);
    }

    // Create mirror texture and an FBO used to copy mirror texture to back buffer
    ovrGLTexture* mirrorTexture;
    ovrHmd_CreateMirrorTextureGL(current_hmd, GL_RGBA, current_hmd->Resolution.w / 2, current_hmd->Resolution.h / 2, (ovrTexture**)&mirrorTexture);
    // Configure the mirror read buffer
    GLuint mirrorFBO = 0;
 /*   glGenFramebuffers(1, &mirrorFBO);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, mirrorFBO);
    glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, mirrorTexture->OGL.TexId, 0);
    glFramebufferRenderbuffer(GL_READ_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);*/
	
	if(mirrorTexture != NULL)
		mirrorFBO = r_framebuffer_allocate(FALSE, &(mirrorTexture->OGL.TexId), 1, -1);
	
    ovrEyeRenderDesc EyeRenderDesc[2]; 
    eye_render_desc[0] = ovrHmd_GetRenderDesc(current_hmd, ovrEye_Left, current_hmd->DefaultEyeFov[0]);
    eye_render_desc[1] = ovrHmd_GetRenderDesc(current_hmd, ovrEye_Right, current_hmd->DefaultEyeFov[1]);
		
    ovrHmd_SetEnabledCaps(current_hmd, ovrHmdCap_LowPersistence | ovrHmdCap_DynamicPrediction);

    // Start the sensor
    ovrHmd_ConfigureTracking(current_hmd, ovrTrackingCap_Orientation | ovrTrackingCap_MagYawCorrection | ovrTrackingCap_Position, 0);
/*

	uint x, y, i;
	SUIFormats vertex_format_types[3] = {SUI_FLOAT, SUI_FLOAT};
	uint vertex_format_size[3] = {3, 2};
//	ovr_InitializeRenderingShim();

	if(ovr_Initialize())
	{
		union{	
		    ovrRenderAPIConfig Config;
		    ovrGLConfigData    OGL;
		}cfg;
		ovrFovPort eye_fov[2];
		uint distortion_caps, result, depth_buffer, x, y;
		ovrSizei size;
		current_hmd = ovrHmd_Create(0);
		if(current_hmd != NULL)
		{
			ovrHmd_AttachToWindow(current_hmd, betray_plugin_windows_window_handle_get(), NULL, NULL);

			eye_fov[0] = current_hmd->DefaultEyeFov[0];
			eye_fov[1] = current_hmd->DefaultEyeFov[1];
			memset(&cfg, 0, sizeof cfg);
			cfg.OGL.Header.API = ovrRenderAPI_OpenGL;
			betray_plugin_screen_mode_get(&x, &y, NULL);
			cfg.OGL.Header.RTSize.w = 1920;
			cfg.OGL.Header.RTSize.h = 1920;
			cfg.OGL.Header.Multisample = 1;
			distortion_caps = ovrDistortionCap_Chromatic | ovrDistortionCap_TimeWarp |  ovrDistortionCap_Vignette | ovrDistortionCap_NoRestore |  ovrDistortionCap_Overdrive | ovrDistortionCap_HqDistortion;
			distortion_caps = 0;
			result = ovrHmd_ConfigureRendering(current_hmd, &cfg.Config, current_hmd->DistortionCaps, current_hmd->MaxEyeFov, eye_render_desc);
		
			size = ovrHmd_GetFovTextureSize(current_hmd, ovrEye_Left, current_hmd->DefaultEyeFov[0], 1);
			render_size[0] = size.h;
			render_size[1] = size.w;

			r_init(betray_plugin_gl_proc_address_get());
			depth_buffer = r_texture_allocate(R_IF_DEPTH24_STENCIL8, render_size[0], render_size[1], 1, TRUE, TRUE, NULL);

			for(i = 0; i < 2; i++)
			{
				eye_vectors[i] = eye_render_desc[i].HmdToEyeViewOffset;
				render_textures[i].OGL.Header.API = ovrRenderAPI_OpenGL;
				render_textures[i].OGL.Header.RenderViewport.Pos.x = 0;
				render_textures[i].OGL.Header.RenderViewport.Pos.y = 0;
				render_textures[i].OGL.Header.RenderViewport.Size.w = render_size[0];
				render_textures[i].OGL.Header.RenderViewport.Size.h = render_size[1];
				render_textures[i].OGL.Header.TextureSize.w = render_size[0];
				render_textures[i].OGL.Header.TextureSize.h = render_size[1];
				render_textures[i].OGL.TexId = r_texture_allocate(R_IF_RGBA_UINT8, render_size[0], render_size[1], 1, TRUE, TRUE, NULL);
				render_fbos[i] = r_framebuffer_allocate(FALSE, &render_textures[i].OGL.TexId, 1, depth_buffer);
			}
		}
	}*/
}
