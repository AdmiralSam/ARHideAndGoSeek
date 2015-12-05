//
//  DepthShader.fsh
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/18/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#version 300 es

out highp vec4 fragmentColor;

void main()
{
    int depth = int(256.0 * gl_FragCoord.z);
    fragmentColor = vec4(float(depth) / 256.0, float(depth) / 256.0, float(depth) / 256.0, 1.0);
}