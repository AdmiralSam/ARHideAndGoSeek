//
//  PerspectiveCamera.mm
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/11/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#include "PerspectiveCamera.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"

using namespace glm;

PerspectiveCamera::PerspectiveCamera(float fieldOfView, float width, float height, float near, float far)
{
    perspectiveMatrix = perspectiveFov(fieldOfView, width, height, near, far);
    position = vec3();
    rotation = vec3();
}

PerspectiveCamera::~PerspectiveCamera() {}

mat4 PerspectiveCamera::GetViewMatrix()
{
    mat4 viewMatrix = translate(mat4(), position);
    viewMatrix = rotate(viewMatrix, rotation[2], vec3(0, 0, 1));
    viewMatrix = rotate(viewMatrix, rotation[0], vec3(1, 0, 0));
    viewMatrix = rotate(viewMatrix, rotation[1], vec3(0, 1, 0));
    return inverse(viewMatrix);
}

void PerspectiveCamera::BindToShader(ShaderProgram* program)
{
    glUniformMatrix4fv(program->GetLocation("projection"), 1, GL_FALSE, value_ptr(perspectiveMatrix));
    glUniformMatrix4fv(program->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
}