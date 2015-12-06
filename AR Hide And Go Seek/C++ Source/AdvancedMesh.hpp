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
#include <vector>
#include <map>

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
    
    GLuint positionBufferID;
    GLuint uvBufferID;
    GLuint normalBufferID;
    GLuint indexBufferID;
    GLuint bone1BufferID;
    GLuint bone2BufferID;
    GLuint weightBufferID;
    GLuint textureID;
    
    int numberOfIndicies;
    
    std::map<int, std::vector<int> > rig;
    std::vector<glm::mat4> bindPose;
    std::vector<glm::mat4> testPose;
    
    void RecursePose(std::vector<glm::mat4>& individualPose, std::vector<glm::mat4>& resultantPose);
    
    void RecursePose(int bone, glm::mat4 currentMatrix, std::vector<glm::mat4>& individualPose, std::vector<glm::mat4>& resultantPose);
    
    glm::mat4 GetModelMatrix();
    
    void LoadMesh(std::string filename, TextureManager* manager, std::vector<float>& positionArray, std::vector<float>& uvArray, std::vector<float>& normalArray, std::vector<unsigned int>& indexArray, std::vector<int>& bone1Array, std::vector<int>& bone2Array, std::vector<float>& weightArray);
};