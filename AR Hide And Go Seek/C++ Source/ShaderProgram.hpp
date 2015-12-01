//
//  ShaderProgram.hpp
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/10/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#pragma once

#include "OpenGLES/ES3/gl.h"

#include <string>
#include <vector>
#include <map>

class ShaderProgram
{
public:
    ShaderProgram(std::string name, std::vector<std::string> attributes, std::vector<std::string> uniforms);
    virtual ~ShaderProgram();
    
    void Use();
    
    GLuint GetLocation(std::string name);
    
    bool Valid();

private:
    std::string shaderName;
    std::map<std::string, GLuint> locations;
    
    GLuint shaderProgramID;
    
    void Load();
    GLuint LoadShader(GLenum shaderType);
};