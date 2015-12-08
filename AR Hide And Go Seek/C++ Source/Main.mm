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
#include "VirtualSensorManager.hpp"
#include "StructureSensorManager.hpp"
#include "VisibilityGrid.hpp"
#include "AdvancedMesh.hpp"
#include "Animal.hpp"

#include <vector>
#include <set>
#include <queue>

using namespace std;
using namespace glm;

TextureManager* textureManager;
SensorManager* sensorManager;

ShaderProgram* basicMeshShader;
ShaderProgram* advancedMeshShader;
ShaderProgram* pointShader;

VisibilityGrid* grid;

Animal* animal;

int currentRow, currentColumn;
int targetRow, targetColumn;

vector<int> rows;
vector<int> columns;

void Initialize(float width, float height)
{
    glViewport(0, 0, width, height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    textureManager = new TextureManager();
    //sensorManager = new VirtualSensorManager(textureManager, width, height);
	sensorManager = new StructureSensorManager(textureManager, width, height);
	
    basicMeshShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    
    advancedMeshShader = new ShaderProgram("AdvancedMesh", {"position", "uv", "normal", "bone1Index", "bone2Index", "bone3Index", "bone4Index", "weight1", "weight2", "weight3", "weight4"}, {"projection", "view", "model", "bind", "pose", "uvMap", "ambientColor", "lightColor"});
    
    pointShader = new ShaderProgram("Shader", {"position", "visible"}, {"projection", "view", "model"});
    
    grid = new VisibilityGrid(-5.4f, 3.4f, -2.9f, 0.9f, 0.1f, 90, 40);
    
    animal = new Animal(grid, textureManager);
}

void Dispose()
{
    delete textureManager;
    delete sensorManager;
}

void Draw()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    sensorManager->Draw();
    glUniformMatrix4fv(basicMeshShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(sensorManager->GetProjectionMatrix()));
    glUniformMatrix4fv(basicMeshShader->GetLocation("view"), 1, GL_FALSE, value_ptr(sensorManager->GetViewMatrix()));
    advancedMeshShader->Use();
    glUniformMatrix4fv(advancedMeshShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(sensorManager->GetProjectionMatrix()));
    glUniformMatrix4fv(advancedMeshShader->GetLocation("view"), 1, GL_FALSE, value_ptr(sensorManager->GetViewMatrix()));
    glUniform3f(advancedMeshShader->GetLocation("ambientColor"), 0.25f, 0.25f, 0.25f);
    glUniform3f(advancedMeshShader->GetLocation("lightColor"), 1.0f, 1.0f, 1.0f);
    animal->Draw(advancedMeshShader);
    advancedMeshShader->Finish();
    glDisable(GL_DEPTH_TEST);
    pointShader->Use();
    glUniformMatrix4fv(pointShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(sensorManager->GetProjectionMatrix()));
    glUniformMatrix4fv(pointShader->GetLocation("view"), 1, GL_FALSE, value_ptr(sensorManager->GetViewMatrix()));
    grid->Draw(pointShader);
    pointShader->Finish();
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    sensorManager->DrawUI();
    glDisable(GL_BLEND);
}

void Update(float deltaTime)
{
    grid->UpdateVisibility(sensorManager);
    sensorManager->Update(deltaTime);
    animal->Update(deltaTime);
}

void PanStarted(int x, int y)
{
    sensorManager->PanStarted(x, y);
}

void PanMoved(int deltaX, int deltaY)
{
    sensorManager->PanMoved(deltaX, deltaY);
}

void PanEnded()
{
    sensorManager->PanEnded();
}