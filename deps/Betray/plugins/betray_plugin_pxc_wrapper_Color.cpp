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

	PXCFaceAnalysis *face_analysis;
	PXCFaceAnalysis::Detection *face_detector;
	PXCFaceAnalysis::Landmark *landmark_detector;
} PXCContext;

static PXCContext context;

// ---------------------+
// Local help functions |
// ---------------------+
/*
static void copy_landmark_data(PXCFaceAnalysis::Landmark::LandmarkData *landmark_data, float *position)
{
	position[0] = landmark_data->position.x;
	position[1] = landmark_data->position.y;
	position[2] = landmark_data->position.z;
}*/

// -------------------+
// API implementation |
// -------------------+

extern "C" int pxc_color_init(unsigned int width, unsigned int height)
{
	pxcStatus status;

	status = PXCSession_Create(&context.session);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

	// Create and configure video stream(s).
	context.capture = new UtilCapture(context.session);
	PXCCapture::VideoStream::DataDesc input_request;
	memset(&input_request, 0, sizeof(input_request));
	input_request.streams[0].format = PXCImage::COLOR_FORMAT_RGB24;
	input_request.streams[0].sizeMin.width = width;
	input_request.streams[0].sizeMin.height = height;
	input_request.streams[1].format = PXCImage::COLOR_FORMAT_DEPTH;
	status = context.capture->LocateStreams(&input_request);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

	PXCCapture::VideoStream::ProfileInfo profile_color;
    status = context.capture->QueryVideoStream(0)->QueryProfile(&profile_color);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;
	
    PXCCapture::VideoStream::ProfileInfo profile_depth;
    status = context.capture->QueryVideoStream(1)->QueryProfile(&profile_depth);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;
/*
	// Locate face analysis module implementation.
	context.face_analysis = 0;
	status = context.session->CreateImpl(PXCFaceAnalysis::CUID,(void**)&context.face_analysis);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

	// Initialize face analysis module.
	PXCFaceAnalysis::ProfileInfo profile_face_analysis;
	status = context.face_analysis->QueryProfile(0, &profile_face_analysis);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;
	//context.capture->LocateStreams(&profile_face_analysis.inputs);  // locate input device that matches module needs
	status = context.face_analysis->SetProfile(&profile_face_analysis);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

	// Initialize face tracking features.
	context.face_detector = context.face_analysis->DynamicCast<PXCFaceAnalysis::Detection>();
	if(!context.face_detector)
		goto error;

	PXCFaceAnalysis::Detection::ProfileInfo profile_face_detection;
	status = context.face_detector->QueryProfile(0, &profile_face_detection);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;
	profile_face_detection.viewAngles = PXCFaceAnalysis::Detection::VIEW_ANGLE_OMNI;
	status = context.face_detector->SetProfile(&profile_face_detection);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

	// Initialize landmark features.
	context.landmark_detector = context.face_analysis->DynamicCast<PXCFaceAnalysis::Landmark>();
	if(!context.landmark_detector)
		goto error;

	PXCFaceAnalysis::Landmark::ProfileInfo profile_landmark_detection;
	status = context.landmark_detector->QueryProfile(0, &profile_landmark_detection);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;
	profile_landmark_detection.labels =
		PXCFaceAnalysis::Landmark::LABEL_LEFT_EYE_INNER_CORNER |
		PXCFaceAnalysis::Landmark::LABEL_LEFT_EYE_OUTER_CORNER |
		PXCFaceAnalysis::Landmark::LABEL_RIGHT_EYE_INNER_CORNER |
		PXCFaceAnalysis::Landmark::LABEL_RIGHT_EYE_OUTER_CORNER;
	status = context.landmark_detector->SetProfile(&profile_landmark_detection);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;
		*/
	return 0;

error:
	if(context.capture != NULL)
		delete context.capture;
	return -1;
}

extern "C" int pxc_color_get_frame(unsigned char **buf_color, short **buf_depth, short **buf_accuracy, float **uvmap)
{
	pxcStatus status = pxcStatus::PXC_STATUS_NO_ERROR;
	PXCSmartSPArray sps(2);

	status = context.capture->ReadStreamAsync(context.images, &sps[0]);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;
/*
	status = context.face_analysis->ProcessImageAsync(context.images, &sps[1]);
	if(status != PXC_STATUS_NO_ERROR)
		goto error;
*/
	status = sps.SynchronizeEx();
	if(status != PXC_STATUS_NO_ERROR)
		goto error;

	// Access capture data.
	context.images[0]->AcquireAccess(PXCImage::ACCESS_READ_WRITE, PXCImage::COLOR_FORMAT_RGB24, &context.image_color_buf);
    context.images[1]->AcquireAccess(PXCImage::ACCESS_READ, &context.image_depth_buf);
	*buf_color = (unsigned char*)context.image_color_buf.planes[0];
	*buf_depth = (short*)context.image_depth_buf.planes[0];
	*buf_accuracy = (short*)context.image_depth_buf.planes[1];
	*uvmap = (float*)context.image_depth_buf.planes[2];
/*
	for(int fi = 0;; ++fi)
	{
		pxcUID face_id;
		pxcU64 timestamp;
		status = context.face_analysis->QueryFace(fi, &face_id, &timestamp);

		if(status < pxcStatus::PXC_STATUS_NO_ERROR)
			break;

		// Access face detection data.
		PXCFaceAnalysis::Detection::Data face_data;
		context.face_detector->QueryData(face_id, &face_data);
		face->confidence = face_data.confidence;
		face->rectangle[0] = face_data.rectangle.x;
		face->rectangle[1] = face_data.rectangle.y;
		face->rectangle[2] = face_data.rectangle.w;
		face->rectangle[3] = face_data.rectangle.h;
		face->view_angle = (PXCViewAngle)face_data.viewAngle;

		// Access landmark detection data.
		PXCFaceAnalysis::Landmark::LandmarkData landmark_data;
		context.landmark_detector->QueryLandmarkData(face_id, PXCFaceAnalysis::Landmark::LABEL_LEFT_EYE_INNER_CORNER, 0, &landmark_data);
		copy_landmark_data(&landmark_data, face->left_eye_inner_corner);
		context.landmark_detector->QueryLandmarkData(face_id, PXCFaceAnalysis::Landmark::LABEL_LEFT_EYE_OUTER_CORNER, 0, &landmark_data);
		copy_landmark_data(&landmark_data, face->left_eye_outer_corner);
		context.landmark_detector->QueryLandmarkData(face_id, PXCFaceAnalysis::Landmark::LABEL_RIGHT_EYE_INNER_CORNER, 0, &landmark_data);
		copy_landmark_data(&landmark_data, face->right_eye_inner_corner);
		context.landmark_detector->QueryLandmarkData(face_id, PXCFaceAnalysis::Landmark::LABEL_RIGHT_EYE_OUTER_CORNER, 0, &landmark_data);
		copy_landmark_data(&landmark_data, face->right_eye_outer_corner);

		PXCFaceAnalysis::Landmark::PoseData pose_data;
		context.landmark_detector->QueryPoseData(face_id, &pose_data);
		face->yaw = pose_data.yaw;
		face->roll = pose_data.roll;
		face->pitch = pose_data.pitch;
	}
	*/
	return 0;

error:
	return -1;
}

extern "C" int pxc_color_release_frame()
{
	context.images[0]->ReleaseAccess(&context.image_color_buf);
    context.images[1]->ReleaseAccess(&context.image_depth_buf);
	delete context.images[0];
	delete context.images[1];
	return 0;
}

extern "C" int pxc_color_exit()
{
	delete context.landmark_detector;
	delete context.face_detector;
	delete context.face_analysis;
	delete context.session;
	return 0;
}
