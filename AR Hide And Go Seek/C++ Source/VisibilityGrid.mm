//
//  VisibilityGrid.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "VisibilityGrid.hpp"

#include <set>
#include <queue>

using namespace std;
using namespace glm;

VisibilityGrid::VisibilityGrid(float minX, float maxX, float minZ, float maxZ, float y, int xPoints, int zPoints)
{
    grid = (bool*)malloc(sizeof(bool) * xPoints * zPoints);
    for (int i = 0; i < xPoints; i++)
    {
        float x = minX + i * (maxX - minX) / (xPoints - 1);
        for (int j = 0; j < zPoints; j++)
        {
            float z = minZ + j * (maxZ - minZ) / (zPoints - 1);
            gridPoints.emplace_back(x, y, z);
            gridVisibility.push_back(false);
        }
    }
    numberOfRows = xPoints;
    numberOfColumns = zPoints;
}

VisibilityGrid::~VisibilityGrid()
{
    delete grid;
}

void VisibilityGrid::UpdateVisibility(SensorManager* manager)
{
    manager->CheckVisibility(gridPoints, gridVisibility);
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
    return gridVisibility[indexFromRowColumn(row, column)];
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
        if(grid[current] && !gridVisibility[current]) {
            rowColumnFromIndex(current, invisibleRow, invisibleColumn);
            return;
        }
        if (lookedAt.find(current) != lookedAt.end()) {
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
        if (grid[i] && !gridVisibility[i])
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
                if (closedSet.find(neighborIndex) == closedSet.end())
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