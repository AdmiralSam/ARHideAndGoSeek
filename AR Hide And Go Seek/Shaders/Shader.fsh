//
//  Shader.fsh
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/18/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#version 300 es

in vec4 colorVarying;

out vec4 fragmentColor;

void main()
{
    fragmentColor = colorVarying;
}