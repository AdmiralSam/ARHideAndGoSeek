//
//  Main.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/30/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "Main.hpp"
#include "OpenGLES/ES3/gl.h"
#include "glm/gtc/type_ptr.hpp"
#include "TrackerHandler.hpp"

#include <vector>

using namespace std;
using namespace glm;

TextureManager* textureManager;
TrackerHandler* trackerHandler;

ShaderProgram* basicMeshShader;

vector<vec4> points;
vector<bool> visible;
int framesSinceVisibilityTest;

void Initialize(float width, float height)
{
    glViewport(0, 0, width, height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    
    textureManager = new TextureManager();
    trackerHandler = new TrackerHandler(textureManager, width, height);
    
    basicMeshShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    
    for (int i = 0; i < 180; i++) {
        for (int j = 0; j < 80; j++) {
            points.emplace_back(-5.5f + 0.05f * i, 0.05f, -3.0f + 0.05f * j, 1.0f);
        }
    }
    
    framesSinceVisibilityTest = 0;
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
    if(framesSinceVisibilityTest > 5) {
        visible = trackerHandler->CheckVisibility(points);
        framesSinceVisibilityTest = 0;
    } else{
        framesSinceVisibilityTest++;
    }
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