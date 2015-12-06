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
in vec4 normal;
in int bone1Index;
in int bone2Index;
in float weight;

out vec2 interpolatedUV;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

uniform mat4 bind[15];
uniform mat4 pose[15];

void main()
{
    vec4 posedPosition = position;
    if (bone2Index == -1)
    {
        posedPosition = pose[bone1Index] * inverse(bind[bone1Index]) * posedPosition;
    }
    else
    {
        posedPosition = weight * pose[bone1Index] * inverse(bind[bone1Index]) * posedPosition + (1.0 - weight) * pose[bone2Index] * inverse(bind[bone2Index]) * posedPosition;
    }
    interpolatedUV = uv;
    gl_Position = projection * view * model * posedPosition;
}