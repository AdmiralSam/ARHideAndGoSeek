//
//  Main.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/30/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "Main.hpp"
#include "OpenGLES/ES3/gl.h"
#include "TrackerHandler.hpp"

TextureManager* textureManager;
TrackerHandler* trackerHandler;

ShaderProgram* basicMeshShader;

void Initialize(float width, float height)
{
    glViewport(0, 0, width, height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    
    textureManager = new TextureManager();
    trackerHandler = new TrackerHandler(textureManager, width, height);
    
    basicMeshShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
}

void Dispose()
{
    delete textureManager;
    delete trackerHandler;
}

void Draw()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    basicMeshShader->Use();
    trackerHandler->Draw(basicMeshShader);
}

void Update(float deltaTime)
{
    trackerHandler->Update(deltaTime);
}

void PanStarted(int x, int y)
{
    trackerHandler->PanStarted(x, y);
}

void PanMoved(int deltaX, int deltaY)
{
    trackerHandler->PanMoved(deltaX, deltaY);
}

void PanEnded()
{
    trackerHandler->PanEnded();
}