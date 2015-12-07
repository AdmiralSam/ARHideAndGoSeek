//
//  StructureSensor.h
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//
//  With code from the Unbounded Tracker API example program from Occipital

//#import <UIKit/UIKit.h>
//#import <GLKit/GLKit.h>

#define HAS_LIBCXX
#import <Structure/Structure.h>
#import <Structure/StructureSLAM.h>
#import "TrackerThread.h"

struct SlamData
{
    // Will set ISO automatically, but will force exposure to targetExposureTimeInSeconds.
    const bool useManualExposureAndAutoISO = true;
    
    // Reducing the exposure time by half helps getting a more accurate tracking by reducing motion
    // blur and rolling shutter. A multiple of 60Hz is best for countries using a 60Hz electric
    // current (e.g North America), since it would be in sync with potential light periods.
    //
    // If you observe tracking unstabilities when looking at scenes with little texture, you may
    // want to set it to 1./50. if you are in a country using 50Hz current, e.g. in Europe.
    const double targetExposureTimeInSeconds = 1./60.;
    
    STStreamConfig structureStreamConfig = STStreamConfigDepth320x240;
    
    // The tracker starts at a "normal" human height, ~1.5 meters. This will be adjusted later
    // on if we see the ground.
    GLKVector4 initialTrackerTranslation = GLKVector4Make (0, -1.5, 0, 1);
    
    bool initialized = false;
    bool shouldResetPose = true;
    bool isTracking = false;
    
    STScene *scene = nil;
    STCameraPoseInitializer *cameraPoseInitializer = nil;
    
    TrackerUpdate lastSceneKitTrackerUpdateProcessed;
    
    TrackerThread* trackerThread = nil;
    
    // OpenGL context.
    EAGLContext *context = nil;
    
    double previousFrameTimestamp = -1.0;
};

@interface StructureSensorS : NSObject <STSensorControllerDelegate>
{
	SlamData _slamState;
    GLKVector3 _lastGravity;
}

+ (id) sharedSensorInstance;

//What C++ can call
- (void) initializeSensor: (GLKViewController *)controller;
- (BOOL) connectAndStartStreaming;
- (void) InitializeSLAMWithContext:(EAGLContext *) context;
- (void)enterTrackingState;
- (void)onStructureSensorStartedStreamingWithContext:(EAGLContext *)context;
- (void)clearSLAM;
- (void)lockColorCameraExposure:(BOOL)exposureShouldBeLocked andLockWhiteBalance:(BOOL)whiteBalanceShouldBeLocked andLockFocus:(BOOL)focusShouldBeLocked;
void setManualExposureAndAutoISO (AVCaptureDevice* videoDevice, double targetExposureInSecs);
- (GLKMatrix4)GetPose;

@end