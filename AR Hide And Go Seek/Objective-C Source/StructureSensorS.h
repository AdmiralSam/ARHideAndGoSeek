//
//  StructureSensor.h
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

//#import <UIKit/UIKit.h>
//#import <GLKit/GLKit.h>

#define HAS_LIBCXX
#import <Structure/Structure.h>

@interface StructureSensorS : NSObject <STSensorControllerDelegate>
{
    
}

+ (id) sharedSensorInstance;

//What C++ can call
- (void) initializeSensor: (GLKViewController *)controller withContext: (EAGLContext*) context;
- (BOOL) connectAndStartStreaming;
- (GLKMatrix4) getPose;
- (GLuint)getLumaTextureID;
- (GLuint)getChromaTextureID;

@end