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
#include "Animation.hpp"

#include <string>
#include <vector>
#include <map>

class AdvancedMesh
{
public:
    AdvancedMesh(std::string filename, TextureManager* manager);
    ~AdvancedMesh();
    
    void Draw(ShaderProgram* program);
    void Update(float deltaTime);
    
    void PlayAnimation(std::string animation);
    
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
    GLuint bone3BufferID;
    GLuint bone4BufferID;
    GLuint weight1BufferID;
    GLuint weight2BufferID;
    GLuint weight3BufferID;
    GLuint weight4BufferID;
    GLuint textureID;
    
    int numberOfIndicies;
    
    std::map<int, std::vector<int> > rig;
    std::vector<glm::mat4> bindPose;
    std::map<std::string, Animation*> animations;
    
    std::string currentAnimation;
    
    void RecursePose(std::vector<glm::mat4>& individualPose, std::vector<glm::mat4>& resultantPose);
    
    void RecursePose(int bone, glm::mat4 currentMatrix, std::vector<glm::mat4>& individualPose, std::vector<glm::mat4>& resultantPose);
    
    glm::mat4 GetModelMatrix();
    
    void LoadMesh(std::string filename, TextureManager* manager, std::vector<float>& positionArray, std::vector<float>& uvArray, std::vector<float>& normalArray, std::vector<unsigned int>& indexArray, std::vector<int>& bone1Array, std::vector<int>& bone2Array, std::vector<int>& bone3Array, std::vector<int>& bone4Array, std::vector<float>& weight1Array, std::vector<float>& weight2Array, std::vector<float>& weight3Array, std::vector<float>& weight4Array);
};