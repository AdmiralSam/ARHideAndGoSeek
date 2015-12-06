//
//  AdvancedMesh.hpp
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/5/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once

#include "glm/glm.hpp"
#include "ShaderProgram.hpp"
#include "TextureManager.hpp"

#include <string>

class AdvancedMesh
{
public:
    AdvancedMesh(std::string filename, TextureManager* manager);
    ~AdvancedMesh();
    
    void Draw(ShaderProgram* program);
    
    void SetPosition(glm::vec3 newPosition) {position = newPosition;}
    void SetRotation(glm::vec3 newRotation) {rotation = newRotation;}
    void SetScale(glm::vec3 newScale) {scale = newScale;}
    
private:
    glm::vec3 position;
    glm::vec3 rotation;
    glm::vec3 scale;
};