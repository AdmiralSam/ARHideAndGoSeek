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
        if(!gridVisibility[current]) {
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
        if (!gridVisibility[i])
        {
            invisible.push_back(i);
        }
    }
    rowColumnFromIndex(invisible[(int)(random() % invisible.size()
                                       )], invisibleRow, invisibleColumn);}