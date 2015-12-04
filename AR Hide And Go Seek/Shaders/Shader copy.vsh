//
//  Shader.vsh
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/18/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#version 300 es

in vec4 position;
in vec2 uv;

out vec2 interpolatedUV;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

void main()
{
    interpolatedUV = uv;
    gl_Position = projection * view * model * position;
}