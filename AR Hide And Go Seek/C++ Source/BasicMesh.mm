//
//  BasicMesh.mm
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/11/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#include "BasicMesh.hpp"
#include "Utility.h"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"

#include <sstream>

using namespace std;
using namespace glm;

BasicMesh::BasicMesh(string filename, TextureManager* manager)
{
    vector<float> positionArray;
    vector<float> uvArray;
    vector<unsigned int> indexArray;
    ParseOBJ([Utility LoadFileAsString:filename.c_str()], manager, positionArray, uvArray, indexArray);
    
    glGenBuffers(1, &positionBufferID);
    glGenBuffers(1, &uvBufferID);
    glGenBuffers(1, &indexBufferID);
    
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * positionArray.size(), &positionArray[0], GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, uvBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * uvArray.size(), &uvArray[0], GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * indexArray.size(), &indexArray[0], GL_STATIC_DRAW);
    
    position = vec3();
    rotation = vec3();
    scale = vec3(1, 1, 1);
    
    textureManager = manager;
}

BasicMesh::~BasicMesh()
{
    glDeleteBuffers(1, &positionBufferID);
    glDeleteBuffers(1, &uvBufferID);
    glDeleteBuffers(1, &indexBufferID);
}

void BasicMesh::Draw(ShaderProgram* program)
{
    glUniformMatrix4fv(program->GetLocation("model"), 1, GL_FALSE, value_ptr(GetModelMatrix()));
    
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferID);
    glVertexAttribPointer(program->GetLocation("position"), 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, uvBufferID);
    glVertexAttribPointer(program->GetLocation("uv"), 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
    
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(program->GetLocation("uvMap"), 0);
    
    int finished = 0;
    for(int i = 0; i < textureIDs.size(); i++)
    {
        glBindTexture(GL_TEXTURE_2D, textureIDs[i]);
        glDrawElements(GL_TRIANGLES, textureCount[i] * 3, GL_UNSIGNED_INT, (void*)(finished * 3 * sizeof(unsigned int)));
        finished += textureCount[i];
    }
}

mat4 BasicMesh::GetModelMatrix()
{
    mat4 modelMatrix = translate(mat4(), position);
    modelMatrix = rotate(modelMatrix, rotation[2], vec3(0, 0, 1));
    modelMatrix = rotate(modelMatrix, rotation[0], vec3(1, 0, 0));
    modelMatrix = rotate(modelMatrix, rotation[1], vec3(0, 1, 0));
    modelMatrix = glm::scale(modelMatrix, scale);
    return modelMatrix;
}

void BasicMesh::ParseOBJ(string objContents, TextureManager*  manager, vector<float>& positionArray, vector<float>& uvArray, vector<unsigned int>& indexArray)
{
    istringstream objReader(objContents);
    vector<vec3> positions;
    vector<vec2> uvs;
    map<string, int> vertexMap;
    
    int count = 0;
    string line;
    while(getline(objReader, line))
    {
        if(line[0] == 'v' && line[1] == 't')
        {
            float u, v;
            sscanf(line.c_str(), "vt %f %f", &u, &v);
            uvs.emplace_back(u, v);
        }
        else if(line[0] == 'v' && line[1] == ' ')
        {
            float x, y, z;
            sscanf(line.c_str(), "v %f %f %f", &x, &y, &z);
            positions.emplace_back(x, y, z);
        }
        else if(line[0] == 'u' && line[1] == 's')
        {
            char textureFilename[256];
            sscanf(line.c_str(), "usemtl %[^\n]", textureFilename);
            if (!textureIDs.empty()){
                textureCount.push_back(count);
                count = 0;
            }
            textureIDs.push_back(manager->LoadTexture(textureFilename));
        }
        else if(line[0] == 'f' && line[1] == ' ')
        {
            count++;
            int vertex1[2];
            int vertex2[2];
            int vertex3[2];
            sscanf(line.c_str(), "f %d/%d %d/%d %d/%d", &vertex1[0], &vertex1[1], &vertex2[0], &vertex2[1],&vertex3[0], &vertex3[1]);
            AddFace(vertexMap, positions, uvs, positionArray, uvArray, indexArray, vertex1);
            AddFace(vertexMap, positions, uvs, positionArray, uvArray, indexArray, vertex2);
            AddFace(vertexMap, positions, uvs, positionArray, uvArray, indexArray, vertex3);
        }
    }
    if(textureIDs.size() > textureCount.size())
    {
        textureCount.push_back(count);
    }
}

void BasicMesh::AddFace(map<string, int>& vertexMap, vector<vec3>& positions, vector<vec2>& uvs, vector<float>& positionArray, vector<float>& uvArray, vector<unsigned int>& indexArray, int vertexInfo[2])
{
    string hash;
    VertexHash(vertexInfo, hash);
    if (vertexMap.find(hash) == vertexMap.end())
    {
        vertexMap[hash] = (int)(positionArray.size() / 4);
        positionArray.push_back(positions[vertexInfo[0] - 1][0]);
        positionArray.push_back(positions[vertexInfo[0] - 1][1]);
        positionArray.push_back(positions[vertexInfo[0] - 1][2]);
        positionArray.push_back(1);
        uvArray.push_back(uvs[vertexInfo[1] - 1][0]);
        uvArray.push_back(uvs[vertexInfo[1] - 1][1]);
    }
    indexArray.push_back(vertexMap[hash]);
}

void BasicMesh::VertexHash(int vertexInfo[2], string& output)
{
    ostringstream hasher;
    hasher << vertexInfo[0] << "/" << vertexInfo[1];
    output = hasher.str();
}