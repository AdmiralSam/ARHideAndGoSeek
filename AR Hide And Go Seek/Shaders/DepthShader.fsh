//
//  DepthShader.fsh
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/18/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#version 300 es

out highp vec4 fragmentColor;

uniform sampler2D uvMap;

void main()
{
    highp vec4 temp = texture(uvMap, vec2(0.0, 0.0));
    int depth = int(256.0 * gl_FragCoord.z);
    fragmentColor = vec4(float(depth) / 256.0, float(depth) / 256.0, float(depth) / 256.0, 1.0);
}