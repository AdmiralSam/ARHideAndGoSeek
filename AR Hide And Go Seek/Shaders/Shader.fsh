//
//  Shader.fsh
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/18/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#version 300 es

out lowp vec4 fragmentColor;

uniform lowp vec4 color;

void main()
{
    fragmentColor = color;
}