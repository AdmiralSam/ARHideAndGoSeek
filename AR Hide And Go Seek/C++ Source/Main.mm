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
SensorManager* trackerHandler;

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
    
    textureManager = new TextureManager();
    trackerHandler = new VirtualSensorManager(textureManager, width, height);
    
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
    delete trackerHandler;
}

void Draw()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    basicMeshShader->Use();
    trackerHandler->Draw();
    glUniformMatrix4fv(basicMeshShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(trackerHandler->GetProjectionMatrix()));
    glUniformMatrix4fv(basicMeshShader->GetLocation("view"), 1, GL_FALSE, value_ptr(trackerHandler->GetViewMatrix()));
    cube->Draw(basicMeshShader);
}

void Update(float deltaTime)
{
    grid->UpdateVisibility(trackerHandler);
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