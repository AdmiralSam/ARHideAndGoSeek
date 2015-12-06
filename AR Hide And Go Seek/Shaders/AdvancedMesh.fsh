//
//  AdvancedMesh.fsh
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/10/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#version 300 es

in lowp vec2 interpolatedUV;

out lowp vec4 fragmentColor;

uniform sampler2D uvMap;

void main()
{
    fragmentColor = texture(uvMap, interpolatedUV);
}