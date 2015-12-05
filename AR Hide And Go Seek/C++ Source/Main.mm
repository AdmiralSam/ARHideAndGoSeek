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
#include "VisibilityGrid.hpp"

#include <vector>
#include <set>
#include <queue>

using namespace std;
using namespace glm;

TextureManager* textureManager;
SensorManager* sensorManager;

ShaderProgram* basicMeshShader;

VisibilityGrid* grid;

BasicMesh* cube;

int currentRow, currentColumn;
int targetRow, targetColumn;

void Initialize(float width, float height)
{
    glViewport(0, 0, width, height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    textureManager = new TextureManager();
    sensorManager = new VirtualSensorManager(textureManager, width, height);
    
    basicMeshShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    
    grid = new VisibilityGrid(-5.5f, 3.5f, -3.0f, 1.0f, 0.1f, 90, 40);
    
    cube = new BasicMesh("light blue.obj", textureManager);
    cube->SetScale(vec3(0.05f, 0.05f, 0.05f));
    cube->SetPosition(vec3(0.0f, 0.05f, 0.0f));
    currentRow = 55;
    currentColumn = 30;
    targetRow = 55;
    targetColumn = 30;
}

void Dispose()
{
    delete textureManager;
    delete sensorManager;
}

void Draw()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    basicMeshShader->Use();
    sensorManager->Draw();
    glUniformMatrix4fv(basicMeshShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(sensorManager->GetProjectionMatrix()));
    glUniformMatrix4fv(basicMeshShader->GetLocation("view"), 1, GL_FALSE, value_ptr(sensorManager->GetViewMatrix()));
    cube->Draw(basicMeshShader);
    sensorManager->DrawUI();
}

void Update(float deltaTime)
{
    grid->UpdateVisibility(sensorManager);
    if(grid->IsVisible(targetRow, targetColumn)){
        grid->ClosestInvisible(currentRow, currentColumn, targetRow, targetColumn);
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
        cube->SetPosition(newPosition);
    }
    sensorManager->Update(deltaTime);
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