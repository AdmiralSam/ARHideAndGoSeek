#version 300 es

in vec4 position;
in vec2 uv;
 
out vec2 uv_varying;
 
void main()
{
    gl_Position = position;
    uv_varying = uv;
}