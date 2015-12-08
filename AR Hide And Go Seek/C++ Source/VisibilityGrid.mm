//
//  VisibilityGrid.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "VisibilityGrid.hpp"
#include "glm/gtc/type_ptr.hpp"

#include <set>
#include <queue>

using namespace std;
using namespace glm;

VisibilityGrid::VisibilityGrid(float minX, float maxX, float minZ, float maxZ, float y, int xPoints, int zPoints)
{
    vector<float> positionArray;
    grid = (bool*)malloc(sizeof(bool) * xPoints * zPoints);
    for (int i = 0; i < xPoints; i++)
    {
        float x = minX + i * (maxX - minX) / (xPoints - 1);
        for (int j = 0; j < zPoints; j++)
        {
            float z = minZ + j * (maxZ - minZ) / (zPoints - 1);
            gridPoints.emplace_back(x, y, z);
            positionArray.push_back(x);
            positionArray.push_back(y);
            positionArray.push_back(z);
            positionArray.push_back(1.0f);
            gridVisibility.push_back(0);
            if (x >= 2.95f && x <= 3.45f && z >= 0.44f && z <= 0.99f)
            {
                grid[i * zPoints + j] = false; //Desk in corner
            }
            else if(x >= 2.365f && x <= 3.45f && z >= -1.6895 && z <= -0.945)
            {
                grid[i * zPoints + j] = false; //Podium
            }
            else
            {
                grid[i * zPoints + j] = true;
            }
        }
    }
    numberOfRows = xPoints;
    numberOfColumns = zPoints;
    
    glGenBuffers(1, &positionBufferID);
    glGenBuffers(1, &visibleBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * positionArray.size(), &positionArray[0], GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, visibleBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(int) * gridVisibility.size(), &gridVisibility[0], GL_DYNAMIC_DRAW);
}

VisibilityGrid::~VisibilityGrid()
{
    delete grid;
}

void VisibilityGrid::Draw(ShaderProgram* program)
{
    glUniformMatrix4fv(program->GetLocation("model"), 1, GL_FALSE, value_ptr(mat4()));
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferID);
    glVertexAttribPointer(program->GetLocation("position"), 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ARRAY_BUFFER, visibleBufferID);
    glVertexAttribPointer(program->GetLocation("visible"), 1, GL_INT, GL_FALSE, 0, NULL);
    glDrawArrays(GL_POINTS, 0, numberOfRows * numberOfColumns);
}

void VisibilityGrid::UpdateVisibility(SensorManager* manager)
{
    manager->CheckVisibility(gridPoints, gridVisibility);
    glBindBuffer(GL_ARRAY_BUFFER, visibleBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(int) * gridVisibility.size(), &gridVisibility[0], GL_DYNAMIC_DRAW);
}

vec3 VisibilityGrid::PositionFromRowColumn(int row, int column)
{
    return gridPoints[indexFromRowColumn(row, column)];
}

bool VisibilityGrid::IsVisible(int row, int column)
{
    if (!grid[indexFromRowColumn(row, column)])
    {
        return true;
    }
    return gridVisibility[indexFromRowColumn(row, column)] == 1;
}

void VisibilityGrid::ClosestInvisible(int row, int column, int& invisibleRow, int& invisibleColumn)
{
    set<int> lookedAt;
    queue<int> frontier;
    int dx[] = {1, 0, -1, 0};
    int dy[] = {0, 1, 0, -1};
    frontier.push(indexFromRowColumn(row, column));
    while(frontier.size() > 0) {
        int current = frontier.front();
        frontier.pop();
        if(grid[current] && gridVisibility[current] == 0) {
            rowColumnFromIndex(current, invisibleRow, invisibleColumn);
            return;
        }
        if (lookedAt.find(current) != lookedAt.end() || !grid[current]) {
            continue;
        }
        lookedAt.insert(current);
        for(int i = 0; i < 4; i++) {
            int currentRow, currentColumn;
            rowColumnFromIndex(current, currentRow, currentColumn);
            currentRow += dy[i];
            currentColumn += dx[i];
            if (currentRow >= 0 && currentRow < numberOfRows && currentColumn >= 0 && currentColumn < numberOfColumns) {
                frontier.push(indexFromRowColumn(currentRow, currentColumn));
            }
        }
    }
}

void VisibilityGrid::RandomInvisible(int row, int column, int& invisibleRow, int& invisibleColumn)
{
    vector<int> invisible;
    for (int i = 0; i < gridVisibility.size(); i++)
    {
        if (grid[i] && gridVisibility[i] == 0)
        {
            invisible.push_back(i);
        }
    }
    rowColumnFromIndex(invisible[(int)(random() % invisible.size()
                                       )], invisibleRow, invisibleColumn);
}

void VisibilityGrid::FindPath(int row, int column, int targetRow, int targetColumn, vector<int>& pathRows, vector<int>& pathColumns)
{
    int dx[] = {1, 1, 0, -1, -1, -1, 0, 1};
    int dy[] = {0, -1, -1, -1, 0, 1, 1, 1};
    set<int> closedSet;
    set<int> openSet;
    map<int, int> cameFrom;
    vector<float> distanceSoFar;
    vector<float> estimatedDistance;
    for (int i = 0; i < gridPoints.size(); i++)
    {
        distanceSoFar.push_back(1000000);
        estimatedDistance.push_back(1000000);
    }
    openSet.insert(indexFromRowColumn(row, column));
    distanceSoFar[indexFromRowColumn(row, column)] = 0;
    estimatedDistance[indexFromRowColumn(row, column)] = distance(PositionFromRowColumn(row, column), PositionFromRowColumn(targetRow, targetColumn));
    while (openSet.size() > 0)
    {
        int lowestF = 1000000;
        int lowestIndex = 0;
        for (auto index : openSet)
        {
            if (estimatedDistance[index] < lowestF)
            {
                lowestF = estimatedDistance[index];
                lowestIndex = index;
            }
        }
        int lowestRow, lowestColumn;
        rowColumnFromIndex(lowestIndex, lowestRow, lowestColumn);
        if (targetRow == lowestRow && targetColumn == lowestColumn)
        {
            int pathIndex = lowestIndex;
            while (pathIndex != -1)
            {
                int pathRow, pathColumn;
                rowColumnFromIndex(pathIndex, pathRow, pathColumn);
                pathRows.push_back(pathRow);
                pathColumns.push_back(pathColumn);
                if (cameFrom.find(pathIndex) != cameFrom.end())
                {
                    pathIndex = cameFrom[pathIndex];
                }
                else
                {
                    pathIndex = -1;
                }
            }
            return;
        }
        openSet.erase(lowestIndex);
        closedSet.insert(lowestIndex);
        for (int i = 0; i < 8; i++)
        {
            int neighborRow = lowestRow + dy[i];
            int neighborColumn = lowestColumn + dx[i];
            int neighborIndex = indexFromRowColumn(neighborRow, neighborColumn);
            if (neighborRow >= 0 && neighborRow < numberOfRows && neighborColumn >= 0 && neighborColumn <= numberOfColumns)
            {
                if (closedSet.find(neighborIndex) == closedSet.end() && grid[neighborIndex])
                {
                    float tentativeDistance = distanceSoFar[lowestIndex] + distance(gridPoints[lowestIndex], gridPoints[neighborIndex]);
                    if (openSet.find(neighborIndex) == openSet.end())
                    {
                        openSet.insert(neighborIndex);
                        cameFrom[neighborIndex] = lowestIndex;
                        distanceSoFar[neighborIndex] = tentativeDistance;
                        estimatedDistance[neighborIndex] = tentativeDistance + distance(gridPoints[neighborIndex], PositionFromRowColumn(targetRow, targetColumn));
                    }
                    else if (tentativeDistance < distanceSoFar[neighborIndex])
                    {
                        cameFrom[neighborIndex] = lowestIndex;
                        distanceSoFar[neighborIndex] = tentativeDistance;
                        estimatedDistance[neighborIndex] = tentativeDistance + distance(gridPoints[neighborIndex], PositionFromRowColumn(targetRow, targetColumn));
                    }
                }
            }
        }
    }
}