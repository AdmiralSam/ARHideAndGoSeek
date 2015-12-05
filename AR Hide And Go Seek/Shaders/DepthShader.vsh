//
//  DepthShader.vsh
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/18/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#version 300 es

in vec4 position;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

void main()
{
    gl_Position = projection * view * model * position;
}