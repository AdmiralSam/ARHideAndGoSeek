//
//  StructureSensor.m
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StructureSensorS.h"

@interface StructureSensorS () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
	GLKViewController *viewController;
	
	STSensorController *sensorController;
	
	AVCaptureSession *captureSession;
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
	
	return self;
}

- (void)initializeSensor: (GLKViewController *) controller
{
	viewController = controller;
	
	sensorController = [STSensorController sharedController];
	sensorController.delegate = self;
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

- (void)printMessage:(NSString *)message
{
	UIAlertController *theAlert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){}];
	[theAlert addAction:defaultAction];
	[viewController presentViewController:theAlert animated:YES completion:nil];
}

@end


































