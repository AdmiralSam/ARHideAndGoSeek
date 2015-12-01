//
//  Utility.m
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/10/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#import "Utility.h"

#import <GLKit/GLKit.h>

@implementation Utility

+ (const char*) LoadFileAsString:(const char*) filename
{
    NSString* nsFilename = [NSString stringWithUTF8String:filename];
    NSArray<NSString*>* splitFilename = [nsFilename componentsSeparatedByString:@"."];
    NSString* pathToFile = [[NSBundle mainBundle] pathForResource:splitFilename[0] ofType:splitFilename[1]];
    NSString* fileContents = [NSString stringWithContentsOfFile:pathToFile encoding:NSUTF8StringEncoding error:nil];
    return [fileContents UTF8String];
}

+ (GLuint) LoadTexture:(const char *)filename
{
    NSString* nsFilename = [NSString stringWithUTF8String:filename];
    NSArray<NSString*>* splitFilename = [nsFilename componentsSeparatedByString:@"."];
    NSString* pathToFile = [[NSBundle mainBundle] pathForResource:splitFilename[0] ofType:splitFilename[1]];
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:pathToFile options:@{GLKTextureLoaderOriginBottomLeft:@YES} error:nil];
    return textureInfo.name;
}

@end