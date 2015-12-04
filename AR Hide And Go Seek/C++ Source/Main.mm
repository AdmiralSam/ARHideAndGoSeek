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
#include <set>
#include <queue>

using namespace std;
using namespace glm;

TextureManager* textureManager;
TrackerHandler* trackerHandler;

ShaderProgram* basicMeshShader;

BasicMesh* cube;

vector<vec4> points;
vector<bool> visible;

int currentRow, currentColumn;
int targetRow, targetColumn;

vec4 positionFromRowColumn(int row, int column);
int indexFromRowColumn(int row, int column);
void rowColumnFromIndex(int index, int& row, int& column);
void updateTarget();

void Initialize(float width, float height)
{
    glViewport(0, 0, width, height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    
    textureManager = new TextureManager();
    trackerHandler = new TrackerHandler(textureManager, width, height);
    
    basicMeshShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    
    for (int i = 0; i < 80; i++) {
        for (int j = 0; j < 40; j++) {
            points.emplace_back(-5.5f + 0.1f * i, 0.1f, -3.0f + 0.1f * j, 1.0f);
        }
    }
    
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
    trackerHandler->Draw(basicMeshShader);
    glUniformMatrix4fv(basicMeshShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(trackerHandler->GetProjectionMatrix()));
    glUniformMatrix4fv(basicMeshShader->GetLocation("view"), 1, GL_FALSE, value_ptr(trackerHandler->GetViewMatrix()));
    cube->Draw(basicMeshShader);
}

void Update(float deltaTime)
{
    visible = trackerHandler->CheckVisibility(points);
    if(visible[indexFromRowColumn(targetRow, targetColumn)]){
        updateTarget();
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
        vec4 newPosition = positionFromRowColumn(currentRow, currentColumn);
        cube->SetPosition(vec3(newPosition.x, 0.05f, newPosition.z));
    }
    trackerHandler->Update(deltaTime);
}

void updateTarget() {
    set<int> lookedAt;
    queue<int> frontier;
    int dx[] = {1, 0, -1, 0};
    int dy[] = {0, 1, 0, -1};
    frontier.push(indexFromRowColumn(currentRow, currentColumn));
    while(frontier.size() > 0) {
        int current = frontier.front();
        frontier.pop();
        if(!visible[current]) {
            rowColumnFromIndex(current, targetRow, targetColumn);
            return;
        }
        if (lookedAt.find(current) != lookedAt.end()) {
            continue;
        }
        lookedAt.insert(current);
        for(int i = 0; i < 4; i++) {
            int row, column;
            rowColumnFromIndex(current, row, column);
            row += dy[i];
            column += dx[i];
            if (row >= 0 && row < 80 && column >= 0 && column < 40) {
                frontier.push(indexFromRowColumn(row, column));
            }
        }
    }
}

int indexFromRowColumn(int row, int column) {
    return row * 40 + column;
}

void rowColumnFromIndex(int index, int& row, int& column) {
    row = index / 40;
    column = index % 40;
}

vec4 positionFromRowColumn(int row, int column) {
    return points[indexFromRowColumn(row, column)];
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