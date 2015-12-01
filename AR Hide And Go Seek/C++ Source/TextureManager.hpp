//
//  TextureManager.hpp
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/11/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#pragma once

#include "OpenGLES/ES3/gl.h"

#include <string>
#include <map>

class TextureManager
{
public:
    TextureManager();
    virtual ~TextureManager();
    
    GLuint LoadTexture(std::string textureName);
    void DeleteTexture(std::string textureName);
    void DeleteTexture(GLuint textureID);
private:
    std::map<std::string, GLuint> loadedTextures;
};