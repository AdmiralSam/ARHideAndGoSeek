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

ShaderProgram* pointDrawer;
GLuint positionBuffer;
vector<vec4> points;
vector<vec4> visiblePoints, invisiblePoints;

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
    vector<float> pointPositions;
    for (auto point : points) {
        pointPositions.push_back(point.x);
        pointPositions.push_back(point.y);
        pointPositions.push_back(point.z);
        pointPositions.push_back(point.w);
    }
    glGenBuffers(1, &positionBuffer);
    
    pointDrawer = new ShaderProgram("Shader", {"position"}, {"color", "projection", "view", "model"});
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
    pointDrawer->Use();
    glDisable(GL_DEPTH_TEST);
    glUniformMatrix4fv(pointDrawer->GetLocation("projection"), 1, GL_FALSE, value_ptr(trackerHandler->GetProjectionMatrix()));
    glUniformMatrix4fv(pointDrawer->GetLocation("view"), 1, GL_FALSE, value_ptr(trackerHandler->GetViewMatrix()));
    glUniformMatrix4fv(pointDrawer->GetLocation("model"), 1, GL_FALSE, value_ptr(mat4()));
    glBindBuffer(GL_ARRAY_BUFFER, positionBuffer);
    glVertexAttribPointer(pointDrawer->GetLocation("position"), 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glUniform4f(pointDrawer->GetLocation("color"), 0.0f, 1.0f, 0.0f, 1.0f);
    vector<float> visiblePositions;
    for(auto visiblePoint : visiblePoints) {
        visiblePositions.push_back(visiblePoint.x);
        visiblePositions.push_back(visiblePoint.y);
        visiblePositions.push_back(visiblePoint.z);
        visiblePositions.push_back(visiblePoint.w);
    }
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * visiblePositions.size(), &visiblePositions[0], GL_DYNAMIC_DRAW);
    glDrawArrays(GL_POINTS, 0, (int)visiblePoints.size());
    
    glUniform4f(pointDrawer->GetLocation("color"), 1.0f, 0.0f, 0.0f, 1.0f);
    vector<float> invisiblePositions;
    for(auto invisiblePoint : invisiblePoints) {
        invisiblePositions.push_back(invisiblePoint.x);
        invisiblePositions.push_back(invisiblePoint.y);
        invisiblePositions.push_back(invisiblePoint.z);
        invisiblePositions.push_back(invisiblePoint.w);
    }
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * invisiblePositions.size(), &invisiblePositions[0], GL_DYNAMIC_DRAW);
    glDrawArrays(GL_POINTS, 0, (int)invisiblePoints.size());
    glEnable(GL_DEPTH_TEST);
}

void Update(float deltaTime)
{
    trackerHandler->Update(deltaTime);
    vector<bool> visible = trackerHandler->CheckVisibility(points);
    visiblePoints.clear();
    invisiblePoints.clear();
    for(int i = 0; i < points.size(); i++) {
        if(visible[i]) {
            visiblePoints.push_back(points[i]);
        }
        else {
            invisiblePoints.push_back(points[i]);
        }
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