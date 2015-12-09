//
//  PointShader.vsh
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/18/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#version 300 es

in vec4 position;
in int visible;

out vec4 color;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

void main()
{
    if (visible == 1)
    {
        color = vec4(0.0, 1.0, 0.0, 1.0);
    }
    else
    {
        color = vec4(1.0, 0.0, 0.0, 1.0);
    }
    gl_Position = projection * view * model * position;
    gl_PointSize = 4.0;
}