/*****************************************************************************
*                                                                            *
*  OpenNI 2.x Alpha                                                          *
*  Copyright (C) 2012 PrimeSense Ltd.                                        *
*                                                                            *
*  This file is part of OpenNI.                                              *
*                                                                            *
*  Licensed under the Apache License, Version 2.0 (the "License");           *
*  you may not use this file except in compliance with the License.          *
*  You may obtain a copy of the License at                                   *
*                                                                            *
*      http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                            *
*  Unless required by applicable law or agreed to in writing, software       *
*  distributed under the License is distributed on an "AS IS" BASIS,         *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  *
*  See the License for the specific language governing permissions and       *
*  limitations under the License.                                            *
*                                                                            *
*****************************************************************************/
#include <OpenNI.h>

/*****************************************************************************
*                                                                            *
*  OpenNI 2.x Alpha                                                          *
*  Copyright (C) 2012 PrimeSense Ltd.                                        *
*                                                                            *
*  This file is part of OpenNI.                                              *
*                                                                            *
*  Licensed under the Apache License, Version 2.0 (the "License");           *
*  you may not use this file except in compliance with the License.          *
*  You may obtain a copy of the License at                                   *
*                                                                            *
*      http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                            *
*  Unless required by applicable law or agreed to in writing, software       *
*  distributed under the License is distributed on an "AS IS" BASIS,         *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  *
*  See the License for the specific language governing permissions and       *
*  limitations under the License.                                            *
*                                                                            *
*****************************************************************************/
#ifndef _ONI_SAMPLE_VIEWER_H_
#define _ONI_SAMPLE_VIEWER_H_

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_DEPTH 10000

enum DisplayModes
{
	DISPLAY_MODE_OVERLAY,
	DISPLAY_MODE_DEPTH,
	DISPLAY_MODE_IMAGE
};

class SampleViewer
{
public:
	SampleViewer(const char* strSampleName, openni::Device& device, openni::VideoStream& depth, openni::VideoStream& color);
	virtual ~SampleViewer();

	virtual openni::Status init(int argc, char **argv);
	virtual openni::Status run();	//Does not return

protected:
	virtual void display();
	virtual void displayPostDraw(){};	// Overload to draw over the screen image

	virtual void onKey(unsigned char key, int x, int y);

	virtual openni::Status initOpenGL(int argc, char **argv);
	void initOpenGLHooks();

	openni::VideoFrameRef		m_depthFrame;
	openni::VideoFrameRef		m_colorFrame;

	openni::Device&			m_device;
	openni::VideoStream&			m_depthStream;
	openni::VideoStream&			m_colorStream;
	openni::VideoStream**		m_streams;

private:
	SampleViewer(const SampleViewer&);
	SampleViewer& operator=(SampleViewer&);

	static SampleViewer* ms_self;
	static void glutIdle();
	static void glutDisplay();
	static void glutKeyboard(unsigned char key, int x, int y);

	float			m_pDepthHist[MAX_DEPTH];
	char			m_strSampleName[ONI_MAX_STR];
	unsigned int		m_nTexMapX;
	unsigned int		m_nTexMapY;
	DisplayModes		m_eViewState;
	openni::RGB888Pixel*	m_pTexMap;
	int			m_width;
	int			m_height;
};


#endif // _ONI_SAMPLE_VIEWER_H_



typedef struct{
	openni::VideoMode depthVideoMode;
	openni::VideoMode colorVideoMode;
	openni::Device device;
	openni::VideoFrameRef frame;
	openni::DepthPixel* depth_buffer;
	openni::RGB888Pixel* color_buffer;
	openni::VideoStream depth_stream;
	openni::VideoStream color_stream;
	unsigned int depth_size[2];
} OpenNIContext;

static OpenNIContext context;


int OpenNI_camera_init()
{
	openni::Status rc = openni::STATUS_OK;
	const char* deviceURI = openni::ANY_DEVICE;
	

	rc = openni::OpenNI::initialize();

	printf("After initialization:\n%s\n", openni::OpenNI::getExtendedError());

	rc = context.device.open(deviceURI);
	if (rc != openni::STATUS_OK)
	{
		printf("SimpleViewer: Device open failed:\n%s\n", openni::OpenNI::getExtendedError());
		openni::OpenNI::shutdown();
		return 1;
	}

	rc = context.depth_stream.create(context.device, openni::SENSOR_DEPTH);
	if (rc == openni::STATUS_OK)
	{
		rc = context.depth_stream.start();
		if (rc != openni::STATUS_OK)
		{
			printf("SimpleViewer: Couldn't start depth stream:\n%s\n", openni::OpenNI::getExtendedError());
			context.depth_stream.destroy();
		}
	}
	else
	{
		printf("SimpleViewer: Couldn't find depth stream:\n%s\n", openni::OpenNI::getExtendedError());
	}

	rc = context.color_stream.create(context.device, openni::SENSOR_COLOR);
	if (rc == openni::STATUS_OK)
	{
		rc = context.color_stream.start();
		if (rc != openni::STATUS_OK)
		{
			printf("SimpleViewer: Couldn't start color stream:\n%s\n", openni::OpenNI::getExtendedError());
			context.color_stream.destroy();
		}
	}
	else
	{
		printf("SimpleViewer: Couldn't find color stream:\n%s\n", openni::OpenNI::getExtendedError());
	}

	if (!context.depth_stream.isValid() || !context.color_stream.isValid())
	{
		printf("SimpleViewer: No valid streams. Exiting\n");
		openni::OpenNI::shutdown();
		return 2;
	}
	context.depthVideoMode = context.depth_stream.getVideoMode();
	context.colorVideoMode = context.color_stream.getVideoMode();
	
	context.depth_size[0] = context.depthVideoMode.getResolutionX();
	context.depth_size[1] = context.depthVideoMode.getResolutionY();
	printf("Depth %u\n", context.depthVideoMode.getResolutionX());
	printf("Depth %u\n", context.depthVideoMode.getResolutionY());
	printf("color %u\n", context.colorVideoMode.getResolutionX());
	printf("color %u\n", context.colorVideoMode.getResolutionY());

	context.depthVideoMode.getPixelFormat();
	context.depth_stream.start();
	return 1138;
}

unsigned short *OpenNI_camera_read(unsigned int *x, unsigned int *y)
{
	openni::VideoFrameRef frame;
	openni::DepthPixel* depth_buffer;
	openni::RGB888Pixel* color_buffer;

	context.depth_stream.readFrame(&frame); 
	depth_buffer = (openni::DepthPixel*)frame.getData();
	*x = context.depth_size[0];
	*y = context.depth_size[1];

	return (unsigned short *)depth_buffer;
}
#ifdef __cplusplus
} // extern "C"
#endif