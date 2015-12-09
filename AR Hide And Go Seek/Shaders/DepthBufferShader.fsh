#version 300 es

uniform sampler2D uvMap;
uniform mediump float nearPlane;
uniform mediump float farPlane;
 
in lowp vec2 uv_varying;

mediump float z_b;
mediump float z_n;
mediump float z_e;
 
void main()
{
    z_b = texture(uvMap, uv_varying).r / 1000.0;
    z_n = 2.0 * z_b - 1.0;
    z_e = 2.0 * nearPlane * farPlane / (farPlane + nearPlane - z_n * (farPlane - nearPlane));
    
    gl_FragDepth = z_e;
}