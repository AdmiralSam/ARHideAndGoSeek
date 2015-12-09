//
//  ShaderProgram.mm
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/10/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#include "ShaderProgram.hpp"
#include "Utility.h"

#include <iostream>

using namespace std;

ShaderProgram::ShaderProgram(string name, vector<string> attributes, vector<string> uniforms)
{
    shaderName = name;
    shaderProgramID = glCreateProgram();
    Load();
    attributeList = attributes;
    for (auto attribute : attributes)
    {
        locations[attribute] = glGetAttribLocation(shaderProgramID, attribute.c_str());
    }
    for (auto uniform : uniforms)
    {
        locations[uniform] = glGetUniformLocation(shaderProgramID, uniform.c_str());
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
    
    GLint success;
    glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, &success);
    if (!success) {
        GLint loglength;
        glGetShaderiv(vertexShaderID, GL_INFO_LOG_LENGTH, &loglength);
        GLchar log[loglength];
        glGetShaderInfoLog(vertexShaderID, loglength, &loglength, log);
        NSLog(@"vertex shader failed to compile! :[ \n");
        NSLog(@"%@", [NSString stringWithCString:log encoding:NSUTF8StringEncoding]);
        exit(-1);
    }
    
    GLint success2;
    glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, &success2);
    if (!success2) {
        GLint loglength;
        glGetShaderiv(fragmentShaderID, GL_INFO_LOG_LENGTH, &loglength);
        GLchar log[loglength];
        glGetShaderInfoLog(fragmentShaderID, loglength, &loglength, log);
        NSLog(@"fragment shader failed to compile! :[ \n");
        NSLog(@"%@", [NSString stringWithCString:log encoding:NSUTF8StringEncoding]);
        exit(-1);
    }
    
    glAttachShader(shaderProgramID, vertexShaderID);
    glAttachShader(shaderProgramID, fragmentShaderID);
    glLinkProgram(shaderProgramID);
    glDeleteShader(vertexShaderID);
    glDeleteShader(fragmentShaderID);
}

void ShaderProgram::Use()
{
    glUseProgram(shaderProgramID);
    for (auto attribute : attributeList)
    {
        glEnableVertexAttribArray(locations[attribute]);
    }
}

void ShaderProgram::Finish()
{
    for (auto attribute : attributeList)
    {
        glDisableVertexAttribArray(locations[attribute]);
    }
}

GLuint ShaderProgram::GetLocation(string name)
{
    if(locations.find(name) == locations.end())
    {
        return -1;
    }
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