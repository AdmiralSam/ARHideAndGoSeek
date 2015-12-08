//
//  StructureSensor.m
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Structure/StructureSLAM.h>
#import "StructureSensorS.h"
#import <OpenGLES/ES3/glext.h>
//#import <OpenGLES/ES2/glext.h>

@interface StructureSensorS () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    GLKViewController *viewController;
    
    STSensorController *sensorController;
    
    CMMotionManager* motionManager;
    
    NSOperationQueue* imuQueue;
    
    STTracker* tracker;
    
    STCameraPoseInitializer* poser;
    
    CMAcceleration gravity;
    
    GLKMatrix4 pose;
    
    STScene* scene;
    
    BOOL ready;
    
    AVCaptureSession *captureSession;
    
    int badPoseCnt;
	
	
	//CGFloat screenWidth;
	//CGFloat screenHeight;
	//size_t textureWidth;
	//size_t textureHeight;
	CVOpenGLESTextureCacheRef videoTextureCache;
	CVOpenGLESTextureRef lumaTexture;
	CVOpenGLESTextureRef chromaTexture;
}

- (void)printMessage:(NSString *)message;

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
    
    badPoseCnt = 0;
    
    return self;
}

- (void)initializeSensor: (GLKViewController *) controller withContext: (EAGLContext*) context
{
    viewController = controller;
    
    sensorController = [STSensorController sharedController];
    sensorController.delegate = self;
    
    scene = [[STScene alloc] initWithContext:context freeGLTextureUnit:GL_TEXTURE10];
    NSDictionary* trackerOptions = @{
                                     kSTTrackerTypeKey: @(STTrackerDepthAndColorBased),
                                     kSTTrackerTrackAgainstModelKey: @FALSE, // not creating a global model
                                     kSTTrackerQualityKey: @(STTrackerQualityAccurate),
                                     kSTTrackerBackgroundProcessingEnabledKey: @YES,
                                     kSTTrackerAvoidPitchRollDriftKey: @YES,
                                     kSTTrackerAvoidHeightDriftKey: @YES,
                                     };
    tracker = [[STTracker alloc] initWithScene:scene options:trackerOptions error:nil];
    poser = [[STCameraPoseInitializer alloc]
             initWithVolumeSizeInMeters:GLKVector3Make(1.f,1.f,1.f) // not used
             options:@{kSTCameraPoseInitializerStrategyKey: @(STCameraPoseInitializerStrategyGravityAlignedAtOrigin)}
             error:nil];
    pose = GLKMatrix4MakeTranslation(0.0f, -1.5f, 0.0f);
    tracker.initialCameraPose = pose;
    ready = false;
	
	CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &videoTextureCache);
}

- (BOOL) connectAndStartStreaming
{
    STSensorControllerInitStatus result = [sensorController initializeSensorConnection];
    
    BOOL didSucceed = (result == STSensorControllerInitStatusSuccess || result == STSensorControllerInitStatusAlreadyInitialized);
    
    NSString *temp;
    temp = @"it worked!";
    
    if (didSucceed)
    {
        STStreamConfig streamConfig = STStreamConfigDepth320x240;
        
        NSError* error = nil;
        BOOL optionsAreValid = [sensorController startStreamingWithOptions:@{kSTStreamConfigKey : @(streamConfig), kSTFrameSyncConfigKey : @(STFrameSyncDepthAndRgb), kSTHoleFilterConfigKey: @TRUE} error:&error];
        if (!optionsAreValid)
        {
            NSLog(@"Error during streaming start: %s", [[error localizedDescription] UTF8String]);
            return false;
        }
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
    }
    
    
    [self printMessage:temp];
    
    [self setupColorCamera];
    [self startColorCamera];
    [self setupIMU];
    
    return didSucceed;
}


- (void)sensorDidDisconnect
{
    // Stop the color camera when there isn't a connected Structure Sensor
    [self stopColorCamera];
    [self printMessage:@"Sensor was Disconnected"];
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
    if (!ready)
    {
        /*
        [poser updateCameraPoseWithGravity:GLKVector3Make(gravity.x, gravity.y, gravity.z) depthFrame:depthFrame error:nil];
        pose = poser.cameraPose;
        pose = GLKMatrix4TranslateWithVector4(pose, GLKVector4Make(0.0f, -1.5f, 0.0f, 1.0f));
        tracker.initialCameraPose = pose;
         */
        ready = true;
    }
    else
    {
        if ([tracker updateCameraPoseWithDepthFrame:depthFrame colorFrame:colorFrame error:nil])
        {
            pose = tracker.lastFrameCameraPose;
            badPoseCnt = 0;
        }
        else
        {
            badPoseCnt++;
            if (badPoseCnt > 5) {
                [tracker reset];
                tracker.initialCameraPose = pose;
                badPoseCnt = 0;
            }
        }
    }
    
    //[self renderDepthFrame:depthFrame];
    //[self renderNormalsFrame:depthFrame];
    //[self renderColorFrame:colorFrame.sampleBuffer];
    
    NSLog(@"end - sensorDidOutputSynchronizedDepthFrame:");
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	if (lumaTexture)
	{
		CFRelease(lumaTexture);
		lumaTexture = NULL;
	}
	
	if (chromaTexture)
	{
		CFRelease(chromaTexture);
		chromaTexture = NULL;
	}
	
	// Periodic texture cache flush every frame
	CVOpenGLESTextureCacheFlush(videoTextureCache, 0);
	
	
	CVReturn err;
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	size_t width = CVPixelBufferGetWidth(pixelBuffer);
	size_t height = CVPixelBufferGetHeight(pixelBuffer);
	
	err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
													   videoTextureCache,
													   pixelBuffer,
													   NULL,
													   GL_TEXTURE_2D,
													   GL_LUMINANCE,
													   (int)width,
													   (int)height,
													   GL_LUMINANCE,
													   GL_UNSIGNED_BYTE,
													   0,
													   &lumaTexture);
	
	glBindTexture(CVOpenGLESTextureGetTarget(lumaTexture), CVOpenGLESTextureGetName(lumaTexture));
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	//glActiveTexture(GL_TEXTURE1);
	
	err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
													   videoTextureCache,
													   pixelBuffer,
													   NULL,
													   GL_TEXTURE_2D,
													   GL_LUMINANCE_ALPHA,
													   (int)width/2,
													   (int)height/2,
													   GL_LUMINANCE_ALPHA,
													   GL_UNSIGNED_BYTE,
													   1,
													   &chromaTexture);
	
	glBindTexture(CVOpenGLESTextureGetTarget(chromaTexture), CVOpenGLESTextureGetName(chromaTexture));
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
    [sensorController frameSyncNewColorBuffer:sampleBuffer];
}

- (void)setupColorCamera
{
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession beginConfiguration];
	//[captureSession setSessionPreset:AVCaptureSessionPresetHigh];

    [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if([captureDevice lockForConfiguration:nil])
    {
        if([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose])
        {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance])
        {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        
        [captureDevice setFocusModeLockedWithLensPosition:0.75f completionHandler:nil];
        [captureDevice unlockForConfiguration];
    }
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    [captureSession addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setAlwaysDiscardsLateVideoFrames:YES];
    [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
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

- (GLKMatrix4) getPose
{
    return pose;
}

- (void)printMessage:(NSString *)message
{
    UIAlertController *theAlert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){}];
    [theAlert addAction:defaultAction];
    [viewController presentViewController:theAlert animated:YES completion:nil];
}

- (void)setupIMU
{
    const float fps = 60.0;
    motionManager = [[CMMotionManager alloc] init];
    motionManager.accelerometerUpdateInterval = 1.0/fps;
    motionManager.gyroUpdateInterval = 1.0/fps;
    
    // Limiting the concurrent ops to 1 is a simple way to force serial execution
    imuQueue = [[NSOperationQueue alloc] init];
    [imuQueue setMaxConcurrentOperationCount:1];
    
    CMDeviceMotionHandler dmHandler = ^(CMDeviceMotion *motion, NSError *error)
    {
        [self processDeviceMotion:motion withError:error];
    };
    
    // We use X-arbitrary ref frame so that magnetometer corrections don't influence yaw
    [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical
                                                        toQueue:imuQueue
                                                    withHandler:dmHandler];
}

- (void)processDeviceMotion:(CMDeviceMotion *)motion withError:(NSError *)error
{
    if (error == nil)
    {
        gravity = motion.gravity;
        [tracker updateCameraPoseWithMotion:motion];
    }
}

- (GLuint)getLumaTextureID
{
	return CVOpenGLESTextureGetName(lumaTexture);
}

- (GLuint)getChromaTextureID
{
	return CVOpenGLESTextureGetName(chromaTexture);
}

@end

























