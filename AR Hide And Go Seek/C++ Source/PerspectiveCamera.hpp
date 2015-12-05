//
//  PerspectiveCamera.hpp
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/11/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#pragma once

#include "glm/glm.hpp"
#include "ShaderProgram.hpp"

class PerspectiveCamera
{
public:
    PerspectiveCamera(float fieldOfView, float width, float height, float near, float far);
    ~PerspectiveCamera();
    
    glm::vec3 GetPosition() {return position;}
    glm::vec3 GetRotation() {return rotation;}
    
    void SetPosition(glm::vec3 newPosition) {position = newPosition;}
    void SetRotation(glm::vec3 newRotation) {rotation = newRotation;}
    
    void Translate(glm::vec3 translation) {position += translation;}
    void Rotate(glm::vec3 rotate) {rotation += rotate;}
    
    void BindToShader(ShaderProgram* program);
private:
    glm::vec3 position;
    glm::vec3 rotation;
    glm::mat4 perspectiveMatrix;
    
    glm::mat4 GetViewMatrix();
};