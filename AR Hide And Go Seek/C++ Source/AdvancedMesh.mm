//
//  AdvancedMesh.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/5/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "AdvancedMesh.hpp"
#include "Utility.h"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtc/quaternion.hpp"

#include <sstream>

using namespace std;
using namespace glm;

AdvancedMesh::AdvancedMesh(string filename, TextureManager* manager)
{
    vector<float> positionArray, uvArray, normalArray;
    vector<unsigned int> indexArray;
    vector<int> bone1Array, bone2Array;
    vector<float> weightArray;
    LoadMesh(filename, manager, positionArray, uvArray, normalArray, indexArray, bone1Array, bone2Array, weightArray);
    
    glGenBuffers(1, &positionBufferID);
    glGenBuffers(1, &uvBufferID);
    glGenBuffers(1, &normalBufferID);
    glGenBuffers(1, &indexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * positionArray.size(), &positionArray[0], GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, uvBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * uvArray.size(), &uvArray[0], GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, normalBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * normalArray.size(), &normalArray[0], GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * indexArray.size(), &indexArray[0], GL_STATIC_DRAW);
    numberOfIndicies = (int)indexArray.size();
    
    glGenBuffers(1, &bone1BufferID);
    glGenBuffers(1, &bone2BufferID);
    glGenBuffers(1, &weightBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, bone1BufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(int) * bone1Array.size(), &bone1Array[0], GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, bone2BufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(int) * bone2Array.size(), &bone2Array[0], GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, weightBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * weightArray.size(), &weightArray[0], GL_STATIC_DRAW);
    
    position = vec3();
    rotation = vec3();
    scale = vec3(1, 1, 1);
}

void AdvancedMesh::Draw(ShaderProgram* program)
{
    glUniformMatrix4fv(program->GetLocation("model"), 1, GL_FALSE, value_ptr(GetModelMatrix()));
    
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferID);
    glVertexAttribPointer(program->GetLocation("position"), 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, uvBufferID);
    glVertexAttribPointer(program->GetLocation("uv"), 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, bone1BufferID);
    glVertexAttribPointer(program->GetLocation("bone1Index"), 1, GL_INT, GL_FALSE, 0, NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, bone2BufferID);
    glVertexAttribPointer(program->GetLocation("bone2Index"), 1, GL_INT, GL_FALSE, 0, NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, weightBufferID);
    glVertexAttribPointer(program->GetLocation("weight"), 1, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glUniformMatrix4fv(program->GetLocation("bind"), 15, GL_FALSE, value_ptr(bindPose[0]));
    glUniformMatrix4fv(program->GetLocation("pose"), 15, GL_FALSE, value_ptr(testPose[0]));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
    
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(program->GetLocation("uvMap"), 0);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    glDrawElements(GL_TRIANGLES, numberOfIndicies, GL_UNSIGNED_INT, NULL);
}

mat4 AdvancedMesh::GetModelMatrix()
{
    mat4 modelMatrix = translate(mat4(), position);
    modelMatrix = rotate(modelMatrix, rotation[2], vec3(0, 0, 1));
    modelMatrix = rotate(modelMatrix, rotation[0], vec3(1, 0, 0));
    modelMatrix = rotate(modelMatrix, rotation[1], vec3(0, 1, 0));
    modelMatrix = glm::scale(modelMatrix, scale);
    return modelMatrix;
}

void AdvancedMesh::LoadMesh(string filename, TextureManager* manager, vector<float>& positionArray, vector<float>& uvArray, vector<float>& normalArray, vector<unsigned int>& indexArray, vector<int>& bone1Array, vector<int>& bone2Array, vector<float>& weightArray)
{
    string fileContents = [Utility LoadFileAsString:filename.c_str()];
    istringstream fileReader(fileContents);
    string line;
    int jointCount = 0;
    vector<mat4> relativeBind;
    while (getline(fileReader, line))
    {
        if (line[0] == 'j' && line[1] == 'o')
        {
            int parent;
            sscanf(line.c_str(), "joint \"%*[^\"]\" %d", &parent);
            if (parent != -1)
            {
                rig[parent].push_back(jointCount);
            }
            rig[jointCount++] = vector<int>();
        }
        if (line[0] == '\t' && line[1] == 'p' && line[2] == 'q')
        {
            float x, y, z, qx, qy, qz, qw;
            sscanf(line.c_str(), "\tpq %f %f %f %f %f %f %f", &x, &y, &z, &qx, &qy, &qz, &qw);
            quat rotationQ(qw, qx, qy, qz);
            mat4 translation = translate(mat4(), vec3(x, y, z));
            mat4 rotation = mat4_cast(rotationQ);
            relativeBind.push_back(translation * rotation);
        }
        if (line[0] == 'v' && line[1] == 'p')
        {
            float x, y, z;
            sscanf(line.c_str(), "vp %f %f %f", &x, &y, &z);
            positionArray.push_back(x);
            positionArray.push_back(y);
            positionArray.push_back(z);
            positionArray.push_back(1.0f);
        }
        if (line[0] == '\t' && line[1] == 'v' && line[2] == 't')
        {
            float u, v;
            sscanf(line.c_str(), "\tvt %f %f", &u, &v);
            uvArray.push_back(u);
            uvArray.push_back(1-v);
        }
        if (line[0] == '\t' && line[1] == 'v' && line[2] == 'n')
        {
            float x, y, z;
            sscanf(line.c_str(), "\tvn %f %f %f", &x, &y, &z);
            normalArray.push_back(x);
            normalArray.push_back(y);
            normalArray.push_back(z);
            normalArray.push_back(0.0f);
        }
        if (line[0] == '\t' && line[1] == 'v' && line[2] == 'b')
        {
            int bone1, bone2;
            float weight;
            if (sscanf(line.c_str(), "\tvb %d %f %d", &bone1, &weight, &bone2) == 2)
            {
                bone1Array.push_back(bone1);
                bone2Array.push_back(-1);
                weightArray.push_back(1.0f);
            }
            else
            {
                bone1Array.push_back(bone1);
                bone2Array.push_back(bone2);
                weightArray.push_back(weight);
            }
        }
        if (line[0] == '\t' && line[1] == 'm' && line[2] == 'a')
        {
            char textureName[256];
            sscanf(line.c_str(), "\tmaterial \"%[^\"]", textureName);
            textureID = manager->LoadTexture(textureName);
        }
        if (line[0] == 'f' && line[1] == 'm')
        {
            int index1, index2, index3;
            sscanf(line.c_str(), "fm %d %d %d", &index1, &index2, &index3);
            indexArray.push_back(index1);
            indexArray.push_back(index2);
            indexArray.push_back(index3);
        }
    }
    bindPose.resize(15);
    testPose.resize(15);
    RecursePose(relativeBind, bindPose);
    relativeBind[1] = rotate(relativeBind[1], pi<float>() / 3, vec3(0, 0, 1));
    RecursePose(relativeBind, testPose);
}

void AdvancedMesh::RecursePose(vector<mat4>& individualPose, vector<mat4>& resultantPose)
{
    RecursePose(0, mat4(), individualPose, resultantPose);
}

void AdvancedMesh::RecursePose(int bone, mat4 currentMatrix, vector<mat4>& individualPose, vector<mat4>& resultantPose)
{
    resultantPose[bone] = currentMatrix * individualPose[bone];
    for (auto childBone : rig[bone])
    {
        RecursePose(childBone, currentMatrix * individualPose[bone], individualPose, resultantPose);
    }
}