//
//  AdvancedMesh.fsh
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/10/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#version 300 es

in mediump vec2 interpolatedUV;
in mediump vec4 interpolatedNormal;

out lowp vec4 fragmentColor;

uniform sampler2D uvMap;

uniform highp vec3 ambientColor;
uniform highp vec3 lightColor;

void main()
{
    mediump float intensity = max(dot(normalize(interpolatedNormal), vec4(0.0, 1.0, 0.0, 0.0)), 0.0);
    fragmentColor = vec4((ambientColor + intensity * lightColor) * texture(uvMap, interpolatedUV).xyz, 1.0);
}