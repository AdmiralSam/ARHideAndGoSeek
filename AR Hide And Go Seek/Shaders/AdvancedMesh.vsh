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
in int bone3Index;
in int bone4Index;
in float weight1;
in float weight2;
in float weight3;
in float weight4;

out vec2 interpolatedUV;
out vec4 interpolatedNormal;
out vec4 shadowCoordinate;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

uniform mat4 light;

uniform mat4 bind[15];
uniform mat4 pose[15];

void main()
{
    vec4 posedPosition = position;
    vec4 posedNormal = normal;
    if (bone2Index == -1)
    {
        mat4 poseMatrix = pose[bone1Index] * inverse(bind[bone1Index]);
        posedPosition = poseMatrix * posedPosition;
        posedNormal = poseMatrix * posedNormal;
    }
    else if (bone3Index == -1)
    {
        mat4 poseMatrix1 = pose[bone1Index] * inverse(bind[bone1Index]);
        mat4 poseMatrix2 = pose[bone2Index] * inverse(bind[bone2Index]);
        posedPosition = weight1 * poseMatrix1 * posedPosition + weight2 * poseMatrix2 * posedPosition;
        posedNormal = weight1 * poseMatrix1 * posedNormal + weight2 * poseMatrix2 * posedNormal;
    }
    else if (bone4Index == -1)
    {
        mat4 poseMatrix1 = pose[bone1Index] * inverse(bind[bone1Index]);
        mat4 poseMatrix2 = pose[bone2Index] * inverse(bind[bone2Index]);
        mat4 poseMatrix3 = pose[bone3Index] * inverse(bind[bone3Index]);
        posedPosition = weight1 * poseMatrix1 * posedPosition + weight2 * poseMatrix2 * posedPosition + weight3 * poseMatrix3 * posedPosition;
        posedNormal = weight1 * poseMatrix1 * posedNormal + weight2 * poseMatrix2 * posedNormal + weight3 * poseMatrix3 * posedNormal;
    }
    else
    {
        mat4 poseMatrix1 = pose[bone1Index] * inverse(bind[bone1Index]);
        mat4 poseMatrix2 = pose[bone2Index] * inverse(bind[bone2Index]);
        mat4 poseMatrix3 = pose[bone3Index] * inverse(bind[bone3Index]);
        mat4 poseMatrix4 = pose[bone4Index] * inverse(bind[bone4Index]);
        posedPosition = weight1 * poseMatrix1 * posedPosition + weight2 * poseMatrix2 * posedPosition + weight3 * poseMatrix3 * posedPosition + weight4 * poseMatrix4 * posedPosition;
        posedNormal = weight1 * poseMatrix1 * posedNormal + weight2 * poseMatrix2 * posedNormal + weight3 * poseMatrix3 * posedNormal + weight4 * poseMatrix4 * posedNormal;
    }
    interpolatedUV = uv;
    interpolatedNormal = model * posedNormal;
    shadowCoordinate = light * model * posedPosition;
    gl_Position = projection * view * model * posedPosition;
}