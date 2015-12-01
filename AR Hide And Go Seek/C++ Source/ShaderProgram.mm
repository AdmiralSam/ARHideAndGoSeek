//
//  ShaderProgram.mm
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/10/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#include "ShaderProgram.hpp"
#include "Utility.h"

using namespace std;

ShaderProgram::ShaderProgram(string name, vector<string> attributes, vector<string> uniforms)
{
    shaderName = name;
    shaderProgramID = glCreateProgram();
    Load();
    for(int i = 0; i < attributes.size(); i++)
    {
        locations[attributes[i]] = glGetAttribLocation(shaderProgramID, attributes[i].c_str());
        glEnableVertexAttribArray(locations[attributes[i]]);
    }
    for(int i = 0; i < uniforms.size(); i++)
    {
        locations[uniforms[i]] = glGetUniformLocation(shaderProgramID, uniforms[i].c_str());
    }
}

ShaderProgram::~ShaderProgram()
{
    glDeleteProgram(shaderProgramID);
}

void ShaderProgram::Load()
{
    GLuint vertexShaderID = LoadShader(GL_VERTEX_SHADER);
    GLuint fragmentShaderID = LoadShader(GL_FRAGMENT_SHADER);
    glCompileShader(vertexShaderID);
    glCompileShader(fragmentShaderID);
    glAttachShader(shaderProgramID, vertexShaderID);
    glAttachShader(shaderProgramID, fragmentShaderID);
    glLinkProgram(shaderProgramID);
    glDeleteShader(vertexShaderID);
    glDeleteShader(fragmentShaderID);
}

void ShaderProgram::Use()
{
    glUseProgram(shaderProgramID);
}

GLuint ShaderProgram::GetLocation(string name)
{
    return locations[name];
}

bool ShaderProgram::Valid()
{
    glValidateProgram(shaderProgramID);
    GLint validationStatus;
    glGetProgramiv(shaderProgramID, GL_VALIDATE_STATUS, &validationStatus);
    return validationStatus == GL_TRUE;
}

GLuint ShaderProgram::LoadShader(GLenum shaderType){
    GLuint shaderID = glCreateShader(shaderType);
    string shaderFilename = shaderName;
    switch (shaderType){
        case GL_VERTEX_SHADER:
            shaderFilename += ".vsh";
            break;
        case GL_FRAGMENT_SHADER:
            shaderFilename += ".fsh";
            break;
    }
    GLchar* shaderSource = (GLchar*)[Utility LoadFileAsString:shaderFilename.c_str()];
    glShaderSource(shaderID, 1, &shaderSource, NULL);
    return shaderID;
}