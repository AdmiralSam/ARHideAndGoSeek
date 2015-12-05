//
//  BasicMesh.hpp
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/11/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#pragma once

#import "OpenGLES/ES3/gl.h"
#import "glm/glm.hpp"
#import "ShaderProgram.hpp"
#import "TextureManager.hpp"

#import <string>
#import <vector>
#import <map>

class BasicMesh
{
public:
    BasicMesh(std::string filename, TextureManager* manager);
    ~BasicMesh();
    
    void Draw(ShaderProgram* program);
    
    void SetPosition(glm::vec3 newPosition) {position = newPosition;}
    void SetRotation(glm::vec3 newRotation) {rotation = newRotation;}
    void SetScale(glm::vec3 newScale) {scale = newScale;}
    
private:
    GLuint positionBufferID;
    GLuint uvBufferID;
    GLuint indexBufferID;
    std::vector<GLuint> textureIDs;
    std::vector<int> textureCount;
    
    TextureManager* textureManager;
    
    glm::vec3 position;
    glm::vec3 rotation;
    glm::vec3 scale;
    
    glm::mat4 GetModelMatrix();
    
    void ParseOBJ(std::string objContents, TextureManager* manager, std::vector<float>& positionArray, std::vector<float>& uvArray, std::vector<unsigned int>& indexArray);
    void AddFace(std::map<std::string, int>& vertexMap, std::vector<glm::vec3>& positions, std::vector<glm::vec2>& uvs, std::vector<float>& positionArray, std::vector<float>& uvArray, std::vector<unsigned int>& indexArray, int vertexInfo[2]);
    void VertexHash(int vertexInfo[2], std::string& output);
};