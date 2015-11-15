#include "betray_plugin_api.h"
#include "relinquish.h"
#include <stdio.h>
#include <math.h>

#include "OVR.h"
//#include "Kernel/OVR_String.h"

#ifdef __cplusplus
extern "C" {
#endif
extern void betray_plugin_oculus_sensor_init(void);
extern void betray_plugin_oculus_sensor_read(float *quaternion);
#ifdef __cplusplus
} // extern "C"
#endif



void betray_plugin_oculus_sensor_read(float *quaternion)
{
	static int initialized = FALSE;
	using namespace OVR;

	if(!initialized)
		OVR::System::Init();

	
	{
		static SensorFusion FusionResult;
		static Ptr<DeviceManager> pManager = 0;
		static Ptr<HMDDevice>     pHMD = 0;
		static Ptr<SensorDevice>  pSensor = 0;
		
		if(!initialized)
		{
			pManager = *DeviceManager::Create();
			pHMD     = *pManager->EnumerateDevices<HMDDevice>().CreateDevice();
			if(!pHMD)
			{
				return;
			}
			pSensor = *pHMD->GetSensor();

		/*	HMDInfo hmdInfo;
			pHMD->GetDeviceInfo(&hmdInfo);*/
			if (pSensor)
				FusionResult.AttachToSensor(pSensor);

		}
		initialized = TRUE;

		Quatf q = FusionResult.GetOrientation();
	/*	if(FusionResult.IsMotionTrackingEnabled())
			exit(0);*/
		quaternion[0] = q.x;
		quaternion[1] = q.y;
		quaternion[2] = q.z;
		quaternion[3] = q.w;
	}
}
/*
void betray_plugin_oculus_sensor_read(float *quaternion)
{
    using namespace OVR;
    Quatf q = FusionResult.GetOrientation();
	quaternion[0] = q.x;
	quaternion[1] = q.y;
	quaternion[2] = q.z;
	quaternion[3] = q.w;
}*/
    // Create a matrix from quaternion,
    // where elements [0][0] through [3][3] contain rotation.
 //   Matrix4f bodyFrameMatrix(q); 

    // Get Euler angles from quaternion, in specified axis rotation order.
//    float yaw, pitch, roll;
//    q.GetEulerAngles<Axis_Y, Axis_X, Axis_Z>(&yaw, &pitch, &roll);

	
void betray_plugin_oculus_sensor_end()
{
    // *** Shutdown
 /*   pSensor.Clear();
    pHMD.Clear();
    pManager.Clear();

    OVR::System::Destroy();*/
}