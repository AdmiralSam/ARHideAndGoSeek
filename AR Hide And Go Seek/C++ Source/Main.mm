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

#include <vector>
#include <set>
#include <queue>

using namespace std;
using namespace glm;

TextureManager* textureManager;
SensorManager* sensorManager;

ShaderProgram* basicMeshShader;
ShaderProgram* advancedMeshShader;

VisibilityGrid* grid;

AdvancedMesh* test;

int currentRow, currentColumn;
int targetRow, targetColumn;

float sesTime = 0;
bool idle = true;

void Initialize(float width, float height)
{
    glViewport(0, 0, width, height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    textureManager = new TextureManager();
    sensorManager = new VirtualSensorManager(textureManager, width, height);
	//sensorManager = new StructureSensorManager(textureManager, width, height);
	
    basicMeshShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    
    advancedMeshShader = new ShaderProgram("AdvancedMesh", {"position", "uv", "normal", "bone1Index", "bone2Index", "bone3Index", "bone4Index", "weight1", "weight2", "weight3", "weight4"}, {"projection", "view", "model", "bind", "pose", "uvMap", "ambientColor", "lightColor"});
    
    grid = new VisibilityGrid(-5.5f, 3.5f, -3.0f, 1.0f, 0.1f, 90, 40);
    
    currentRow = 55;
    currentColumn = 30;
    targetRow = 55;
    targetColumn = 30;
    
    test = new AdvancedMesh("some2.iqe", textureManager);
    test->PlayAnimation("Idle");
    test->SetScale(vec3(0.2f, 0.2f, 0.2f));
    test->SetPosition(vec3(0.0f, 0.05f, 0.0f));
    test->SetRotation(vec3(0.0f, -pi<float>() / 2.0f, -pi<float>() / 2.0f));
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
    glUniform3f(advancedMeshShader->GetLocation("lightColor"), 0.75f, 0.75f, 0.75f);
    test->Draw(advancedMeshShader);
    advancedMeshShader->Finish();
    glEnable(GL_BLEND);
    sensorManager->DrawUI();
    glDisable(GL_BLEND);
}

void Update(float deltaTime)
{
    sesTime += deltaTime;
    if(sesTime > 20)
    {
        sesTime = 0;
        idle = !idle;
        if(idle)
        {
            test->PlayAnimation("Idle");
        }
        else
        {
            test->PlayAnimation("Running");
        }
    }
    grid->UpdateVisibility(sensorManager);
    if(grid->IsVisible(targetRow, targetColumn)){
        grid->RandomInvisible(currentRow, currentColumn, targetRow, targetColumn);
    }
    int columnMovements = abs(targetColumn - currentColumn);
    int rowMovements = abs(targetRow - currentRow);
    if(columnMovements > 0 || rowMovements > 0){
        if(rowMovements > columnMovements) {
            currentRow += (targetRow - currentRow) / rowMovements;
        }
        else
        {
            currentColumn += (targetColumn - currentColumn) / columnMovements;
        }
        vec3 newPosition = grid->PositionFromRowColumn(currentRow, currentColumn);
        newPosition.y = 0.05f;
        test->SetPosition(newPosition);
    }
    sensorManager->Update(deltaTime);
    test->Update(deltaTime);
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