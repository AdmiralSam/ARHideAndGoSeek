//
//  TextureManager.mm
//  Model Based Tracking
//
//  Created by Samuel Dong on 11/11/15.
//  Copyright © 2015 Samuel Dong. All rights reserved.
//

#include "TextureManager.hpp"
#include "Utility.h"

using namespace std;

TextureManager::TextureManager()
{
}

TextureManager::~TextureManager()
{
    for (auto textureName : loadedTextures)
    {
        DeleteTexture(textureName.first);
    }
}

GLuint TextureManager::LoadTexture(string textureName)
{
    if(loadedTextures.find(textureName) == loadedTextures.end())
    {
        loadedTextures[textureName] = [Utility LoadTexture:textureName.c_str()];
    }
    return loadedTextures[textureName];
}

void TextureManager::DeleteTexture(string textureName)
{
    if(loadedTextures.find(textureName) != loadedTextures.end())
    {
        glDeleteTextures(1, &loadedTextures[textureName]);
        loadedTextures.erase(textureName);
    }
}

void TextureManager::DeleteTexture(GLuint textureID)
{
    glDeleteTextures(1, &textureID);
    for(auto textureName : loadedTextures)
    {
        if (textureName.second == textureID) {
            loadedTextures.erase(textureName.first);
            break;
        }
    }
}