//
//  BasicMesh.vsh
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/10/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
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