//
//  StructureSensor.m
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//
//  With code from the Unbounded Tracker API example program from Occipital

#import <Foundation/Foundation.h>
#import "StructureSensorS.h"
#import <mach/mach_time.h>

@interface StructureSensorS () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
	GLKViewController *viewController;
	
	STSensorController *sensorController;
	
	AVCaptureSession *captureSession;
    
    GLKMatrix4 lastPose;
}

- (void)printMessage:(NSString *)message;
double nowInSeconds();

@end


@implementation StructureSensorS


+ (id) sharedSensorInstance
{
	static StructureSensorS *sharedSensorInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSensorInstance = [[self alloc] init];
	});
	
	return sharedSensorInstance;
}

- (id) init
{
	if(self == [super init])
	{
		
	}
	
	return self;
}

#pragma mark - STSensorController

- (void)initializeSensor: (GLKViewController *) controller
{
	viewController = controller;
	
	sensorController = [STSensorController sharedController];
	sensorController.delegate = self;
    
    _lastGravity = GLKVector3Make (0,0,0); // Will be done by IMU initialization if IMU is added
}

- (BOOL) connectAndStartStreaming
{
	STSensorControllerInitStatus result = [sensorController initializeSensorConnection];
	
	BOOL didSucceed = (result == STSensorControllerInitStatusSuccess || result == STSensorControllerInitStatusAlreadyInitialized);
	
	NSString *temp;
	temp = @"it worked!";
	
	if (didSucceed)
	{
		// There's no status about the sensor that we need to display anymore
		//_appStatus.sensorStatus = AppStatus::SensorStatusOk;
		//[self updateAppStatusMessage];
		
		// Start the color camera, setup if needed
		//[self startColorCamera]; //FOR NOW
		
		// Set sensor stream quality
		STStreamConfig streamConfig = STStreamConfigDepth320x240;
		
		// Request that we receive depth frames with synchronized color pairs
		// After this call, we will start to receive frames through the delegate methods
		NSError* error = nil;
		BOOL optionsAreValid = [sensorController startStreamingWithOptions:@{kSTStreamConfigKey : @(streamConfig),
																			  kSTFrameSyncConfigKey : @(STFrameSyncDepthAndRgb),
																			  kSTHoleFilterConfigKey: @TRUE} // looks better without holes
																	  error:&error];
		if (!optionsAreValid)
		{
			NSLog(@"Error during streaming start: %s", [[error localizedDescription] UTF8String]);
			return false;
		}
		
		// Allocate the depth -> surface normals converter class
		//_normalsEstimator = [[STNormalEstimator alloc] init];
	}
	else
	{
		if (result == STSensorControllerInitStatusSensorNotFound)
		{
			NSLog(@"[Debug] No Structure Sensor found!");
			temp = @"No structure sensor found";
		}
		else if (result == STSensorControllerInitStatusOpenFailed)
		{
			NSLog(@"[Error] Structure Sensor open failed.");
			temp = @"structure failed to open";
		}
		else if (result == STSensorControllerInitStatusSensorIsWakingUp)
		{
			NSLog(@"[Debug] Structure Sensor is waking from low power.");
			temp = @"waking from low power";
		}
		else if (result != STSensorControllerInitStatusSuccess)
		{
			NSLog(@"[Debug] Structure Sensor failed to init with status %d.", (int)result);
			temp = @"failed to init with status";
		}
		//_appStatus.sensorStatus = AppStatus::SensorStatusNeedsUserToConnect;
		//[self updateAppStatusMessage];
	}
	

	[self printMessage:temp];
	
	[self setupColorCamera];
	[self startColorCamera];
	
	return didSucceed;
}


- (void)sensorDidDisconnect
{
	// Stop the color camera when there isn't a connected Structure Sensor
	[self stopColorCamera];
	[self printMessage:@"Sensor was Disconnected"];
    [self clearSLAM];
}

- (void)sensorDidConnect
{
	[self connectAndStartStreaming];
}

- (void)sensorDidLeaveLowPowerMode
{

}


- (void)sensorBatteryNeedsCharging
{
	// Notify the user that the sensor needs to be charged.
	[self printMessage:@"Quick! Charge the sensor!"];
}

- (void)sensorDidStopStreaming:(STSensorControllerDidStopStreamingReason)reason
{
	//If needed, change any UI elements to account for the stopped stream
	
	// Stop the color camera when we're not streaming from the Structure Sensor
	//[self stopColorCamera];
}

- (void)sensorDidOutputDepthFrame:(STDepthFrame *)depthFrame
{
	//[self renderDepthFrame:depthFrame];
	//[self renderNormalsFrame:depthFrame];
}

// This synchronized API will only be called when two frames match. Typically, timestamps are within 1ms of each other.
// Two important things have to happen for this method to be called:
// Tell the SDK we want framesync with options @{kSTFrameSyncConfigKey : @(STFrameSyncDepthAndRgb)} in [STSensorController startStreamingWithOptions:error:]
// Give the SDK color frames as they come in:     [_ocSensorController frameSyncNewColorBuffer:sampleBuffer];
- (void)sensorDidOutputSynchronizedDepthFrame:(STDepthFrame *)depthFrame
								andColorFrame:(STColorFrame *)colorFrame
{
	NSLog(@"begin - sensorDidOutputSynchronizedDepthFrame:");
	
	
	//[self printMessage:@"Synchronized Depth Frame"];

	
	//[self renderDepthFrame:depthFrame];
	//[self renderNormalsFrame:depthFrame];
	//[self renderColorFrame:colorFrame.sampleBuffer];
    
    
    if (_slamState.initialized)
    {
        if (!_slamState.isTracking) // Initially, we are in the waiting state.
        {
            // Estimate the new initial position. The cameraPoseInitializer will make sure the initial
            // orientation is aligned with gravity.
            [_slamState.cameraPoseInitializer updateCameraPoseWithGravity:_lastGravity depthFrame:nil error:nil];
            
            // Starting tracking right away.
            [self enterTrackingState];
        }
        else
        {
            if (_slamState.shouldResetPose)
            {
                _slamState.shouldResetPose = NO;
                
                if (!_slamState.cameraPoseInitializer.hasValidPose)
                {
                    NSLog(@"Something is wrong - we don't have a pose from the cube initializer.");
                }
                else
                {
                    GLKMatrix4 initialCameraPose = _slamState.cameraPoseInitializer.cameraPose;
                    
                    // Set the initial camera translation to human height (1.5m). GLKMatrix4 is column-major.
                    initialCameraPose = GLKMatrix4SetColumn (initialCameraPose, 3, _slamState.initialTrackerTranslation);
                    
                    [_slamState.trackerThread setInitialTrackerPose:initialCameraPose timestamp:depthFrame.timestamp];
                }
            }
            else
            {
                double newTimestamp = nowInSeconds();
                // This test is trying to avoid processing frames which arrive in batch. Sometimes scheduling becomes messy
                // and instead of getting a frame after 33ms, we get no frames for 66ms, and then two frames at the same time.
                // Trying to process them both will make the SceneKit thread starve, so we'll just skip one if we receive two
                // frames in less than 5 milliseconds.
                if (_slamState.previousFrameTimestamp < 0 || (newTimestamp - _slamState.previousFrameTimestamp) > 0.005)
                {
                    const int timeoutSeconds = 20/1000.; // don't allow it to eat more than 20ms of the main thread.
                    
                    // We need to take a copy of the depth frame since it won't survive the callback scope.
                    // However the color frame will live long enough since the AVFoundation pool is quite big.
                    [_slamState.trackerThread updateWithDepthFrame:[depthFrame copy] colorFrame:colorFrame maxWaitTimeSeconds:timeoutSeconds];
                }
                _slamState.previousFrameTimestamp = newTimestamp;
            }
        }
    }
	
	NSLog(@"end - sensorDidOutputSynchronizedDepthFrame:");
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	[sensorController frameSyncNewColorBuffer:sampleBuffer];
}

- (void)setupColorCamera
{
	captureSession = [[AVCaptureSession alloc] init];
	[captureSession beginConfiguration];
	[captureSession setSessionPreset:AVCaptureSessionPreset640x480];
	
	AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if([captureDevice lockForConfiguration:nil])
	{
		if([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
		{
			[captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
		}
		if([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
		{
			[captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
		}
		
		[captureDevice setFocusModeLockedWithLensPosition:1.0f completionHandler:nil];
		[captureDevice unlockForConfiguration];
	}
	
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
	[captureSession addInput:input];
	
	AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
	[output setAlwaysDiscardsLateVideoFrames:YES];
	[output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	[output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	[captureSession addOutput:output];
	
	if([captureDevice lockForConfiguration:nil])
	{
		[captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 30)];
		[captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
		[captureDevice unlockForConfiguration];
	}
	
	[captureSession commitConfiguration];
}

- (void)startColorCamera
{
	[captureSession startRunning];
}

- (void)stopColorCamera
{
	[captureSession stopRunning];
}

#pragma mark - STTracker

- (void) InitializeSLAMWithContext:(EAGLContext *) context
{
    if (_slamState.initialized)
        return;
    
    // Create an EAGLContext to use with the tracker.
    _slamState.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_slamState.context)
    {
        NSLog(@"Failed to create ES context");
        return;
    }
    
    // Initialize the scene.
    _slamState.scene = [[STScene alloc] initWithContext:_slamState.context
                                      freeGLTextureUnit:GL_TEXTURE2];
    
    NSDictionary* trackerOptions = @{
                                     kSTTrackerTypeKey: @(STTrackerDepthAndColorBased),
                                     kSTTrackerTrackAgainstModelKey: @FALSE, // not creating a global model
                                     kSTTrackerQualityKey: @(STTrackerQualityAccurate),
                                     kSTTrackerBackgroundProcessingEnabledKey: @YES,
                                     kSTTrackerAvoidPitchRollDriftKey: @YES,
                                     kSTTrackerAvoidHeightDriftKey: @YES,
                                     };
    
    NSError* trackerInitError = nil;
    STTracker* tracker = [[STTracker alloc] initWithScene:_slamState.scene options:trackerOptions error:&trackerInitError];
    NSAssert (tracker != nil, @"Could not create a tracker.");
    
    if (!tracker)
    {
        NSLog(@"Could not create tracker: %@", [trackerInitError localizedDescription]);
        
        NSString *alertTitle = @"Fatal Error";
        NSString *alertText = @"Could not create a tracker.";
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertText
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [viewController presentViewController:alert animated:YES completion:nil];
    }
    
    _slamState.trackerThread = [[TrackerThread alloc] init];
    _slamState.trackerThread.tracker = tracker;
    [_slamState.trackerThread start];
    
    // Setup the cube placement initializer.
    _slamState.cameraPoseInitializer = [[STCameraPoseInitializer alloc]
                                        initWithVolumeSizeInMeters:GLKVector3Make(1.f,1.f,1.f) // not used
                                        options:@{kSTCameraPoseInitializerStrategyKey: @(STCameraPoseInitializerStrategyGravityAlignedAtOrigin)}
                                        error:nil];
    
    _slamState.initialized = true;
    
    _slamState.isTracking = NO;
    
    // Restore automatic color camera parameters.
    [self lockColorCameraExposure:false andLockWhiteBalance:false andLockFocus:true];
}

- (void)onStructureSensorStartedStreamingWithContext:(EAGLContext *)context
{
    [self clearSLAM];
    
    // We cannot initialize SLAM objects before a sensor is ready to be used, so now is a good time
    // to do it.
    if (!_slamState.initialized)
    {
        // One-time setup of SLAM related members now that we have a sensor connected
        [self InitializeSLAMWithContext:context];
    }
    else
    {
        // Here we need to reset the tracker because the user may have moved far away, and
        // exposure might be different too.
        [self gracefullyResetTrackerWhileKeepingPreviousPose];
    }
}

- (void)enterTrackingState
{
    _slamState.shouldResetPose = YES;
    
    // Lock color camera settings to ensure smoother transitions between keyframes.
    [self lockColorCameraExposure:true andLockWhiteBalance:true andLockFocus:true];
    
    _slamState.isTracking = YES;
}

- (GLKMatrix4)GetPose
{
    if (_slamState.lastSceneKitTrackerUpdateProcessed.couldEstimatePose) {
        lastPose =_slamState.lastSceneKitTrackerUpdateProcessed.cameraPose;
        [self printMessage:@"aC"];
    }
        return lastPose;
}

- (void)clearSLAM
{
    _slamState.initialized = false;
    _slamState.scene = nil;
    [_slamState.trackerThread reset];
    [_slamState.trackerThread stop];
    _slamState.trackerThread.tracker = nil;
}

// Lock exposure time and white balance. This will be called once we start tracking to make sure that the tracker sees consistent images.
- (void)lockColorCameraExposure:(BOOL)exposureShouldBeLocked andLockWhiteBalance:(BOOL)whiteBalanceShouldBeLocked andLockFocus:(BOOL)focusShouldBeLocked
{
    NSError *error;
    
    AVCaptureDevice *_videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [_videoDevice lockForConfiguration:&error];
    
    // If the manual exposure option is enabled, we've already locked exposure permanently, so do nothing here.
    if (exposureShouldBeLocked)
    {
        if (_slamState.useManualExposureAndAutoISO)
        {
            // locks the video device to 1/60th of a second exposure time
            setManualExposureAndAutoISO (_videoDevice, _slamState.targetExposureTimeInSeconds);
        }
        else
        {
            NSLog(@"Locking Camera Exposure");
            // Exposure locked to its current value.
            if([_videoDevice isExposureModeSupported:AVCaptureExposureModeLocked])
                [_videoDevice setExposureMode:AVCaptureExposureModeLocked];
        }
    }
    else
    {
        NSLog(@"Unlocking Camera Exposure");
        // Auto-exposure
        [_videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    }
    
    // Lock in the white balance here
    if (whiteBalanceShouldBeLocked)
    {
        // White balance locked to its current value.
        if([_videoDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked])
            [_videoDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
    }
    else
    {
        // Auto-white balance.
        [_videoDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    }
    
    // Lock focus
    if (focusShouldBeLocked)
    {
        // Set focus at the 0.75 to get the best image quality for mid-range scene
        [_videoDevice setFocusModeLockedWithLensPosition:0.75f completionHandler:nil];
    }
    else
    {
        [_videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    }
    
    [_videoDevice unlockForConfiguration];
}

// This method locks exposure to the desired time (or as close as it can), and tries to set
//   an ISO that gives a similar brighness (at the cost of noise, potentially).
//
// Important: This method assumes the current exposure/ISO ratio is appropriate for
//            the scene.  If you didn't let the camera auto-expose, this might not be the case.
void setManualExposureAndAutoISO (AVCaptureDevice* videoDevice, double targetExposureInSecs)
{
    CMTime targetExposureTime = CMTimeMakeWithSeconds(targetExposureInSecs, 1000);
    CMTime currentExposureTime = videoDevice.exposureDuration;
    double exposureFactor = CMTimeGetSeconds(currentExposureTime) / targetExposureInSecs;
    
    CMTime minExposureTime = videoDevice.activeFormat.minExposureDuration;
    
    if( CMTimeCompare(minExposureTime, targetExposureTime) > 0 /* means Time1 > Time2 */ ) {
        // if minExposure is longer than targetExposure, increase our target
        targetExposureTime = minExposureTime;
    }
    
    float currentISO = videoDevice.ISO;
    float targetISO = currentISO*exposureFactor;
    float maxISO = videoDevice.activeFormat.maxISO,
    minISO = videoDevice.activeFormat.minISO;
    
    // Clamp targetISO to [minISO ... maxISO]
    targetISO = targetISO > maxISO ? maxISO : targetISO < minISO ? minISO : targetISO;
    
    [videoDevice setExposureModeCustomWithDuration: targetExposureTime
                                               ISO: targetISO
                                 completionHandler: nil];
    
    //        NSLog(@"Set exposure duration to: %f s (min=%f old=%f) and ISO to %f (max=%f old=%f ideal=%f)",
    //               CMTimeGetSeconds(targetExposureTime),
    //               CMTimeGetSeconds(minExposureTime),
    //               CMTimeGetSeconds(currentExposureTime),
    //               targetISO, maxISO, currentISO, currentISO*exposureFactor);
}

// This will be called after resuming from background or if the sensor was unplugged. We want
// to reset the tracker because it won't be able to recover, but to keep the same pose in the
// virtual world.
- (void)gracefullyResetTrackerWhileKeepingPreviousPose
{
    TrackerUpdate lastUpdate = _slamState.trackerThread.lastUpdate;
    
    if (lastUpdate.couldEstimatePose)
    {
        [_slamState.trackerThread reset];
        [_slamState.trackerThread setInitialTrackerPose:lastUpdate.cameraPose timestamp:nowInSeconds()];
    }
    else
    {
        NSLog(@"Warning: could not reset the pose gracefully, there was no previous estimate.");
    }
}

#pragma mark - Utility

- (void)printMessage:(NSString *)message
{
	UIAlertController *theAlert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){}];
	[theAlert addAction:defaultAction];
	[viewController presentViewController:theAlert animated:YES completion:nil];
}

double nowInSeconds()
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    
    uint64_t newTime = mach_absolute_time();
    
    return ((double)newTime*timebase.numer)/((double)timebase.denom *1e9);
}

@end


































