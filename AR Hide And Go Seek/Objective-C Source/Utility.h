//
//  Utility.h
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/10/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#import "OpenGLES/ES3/gl.h"

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (const char*) LoadFileAsString:(const char*) filename;

+ (GLuint) LoadTexture:(const char*) filename;

@end