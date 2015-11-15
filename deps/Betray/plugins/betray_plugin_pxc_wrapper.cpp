#include <memory.h>

#include "PXC/pxcsession.h"
#include "PXC/pxcsmartptr.h"
#include "PXC/pxccapture.h"
#include "PXC/pxcface.h"
#include "PXC/util_capture.h"

#include "betray_plugin_pxc_wrapper.h"

typedef struct
{
	PXCSession *session;
	UtilCapture *capture;

	PXCImage *images[2];
	PXCImage::ImageData image_color_buf;
	PXCImage::ImageData image_depth_buf;

/*	PXCFaceAnalysis *face_analysis;
	PXCFaceAnalysis::Detection *face_detector;
	PXCFaceAnalysis::Landmark *landmark_detector;*/
} PXCContext;

static PXCContext context;

// -------------------+
// API implementation |
// -------------------+

extern "C" int pxc_init(unsigned int width, unsigned int height)
{
	pxcStatus status;

	status = PXCSession_Create(&context.session);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

	context.capture = new UtilCapture(context.session);
	PXCCapture::VideoStream::DataDesc input_request;
	memset(&input_request, 0, sizeof(input_request));
	input_request.streams[0].format = PXCImage::COLOR_FORMAT_DEPTH;
	status = context.capture->LocateStreams(&input_request);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

    PXCCapture::VideoStream::ProfileInfo profile_depth;
    status = context.capture->QueryVideoStream(0)->QueryProfile(&profile_depth);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

	return 0;

error:
	if(context.capture != NULL)
		delete context.capture;
	return -1;
}

extern "C" int pxc_get_frame(unsigned char **buf_color, short **buf_depth, short **buf_accuracy, float **uvmap, PXCFaceData *face)
{
	pxcStatus status = pxcStatus::PXC_STATUS_NO_ERROR;
	PXCSmartSPArray sps(1);

	status = context.capture->ReadStreamAsync(context.images, &sps[0]);
	if(status != PXC_STATUS_NO_ERROR)
		return -1;

	status = sps.SynchronizeEx();
	if(status != PXC_STATUS_NO_ERROR)
		return -1;

    context.images[0]->AcquireAccess(PXCImage::ACCESS_READ, &context.image_depth_buf);
	*buf_depth = (short*)context.image_depth_buf.planes[0];
	*buf_accuracy = (short*)context.image_depth_buf.planes[1];
	return 0;
}

extern "C" int pxc_release_frame()
{
    context.images[0]->ReleaseAccess(&context.image_depth_buf);
	delete context.images[0];
	return 0;
}

extern "C" int pxc_exit()
{
	delete context.session;
	return 0;
}
