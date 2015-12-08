//
//  VisibilityGrid.hpp
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once

#include "SensorManager.hpp"
#include "glm/glm.hpp"

#include <vector>

class VisibilityGrid
{
public:
    VisibilityGrid(float minX, float maxX, float minZ, float maxZ, float y, int xPoints, int zPoints);
    ~VisibilityGrid();
    
    void UpdateVisibility(SensorManager* manager);
    
    glm::vec3 PositionFromRowColumn(int row, int column);
    
    bool IsVisible(int row, int column);
    void ClosestInvisible(int row, int column, int& invisibileRow, int& invisibleColumn);
    void RandomInvisible(int row, int column, int& invisibleRow, int& invisibleColumn);
    void FindPath(int row, int column, int targetRow, int targetColumn, std::vector<int>& pathRows, std::vector<int>& pathColumns);
    
private:
    int numberOfRows, numberOfColumns;
    bool* grid;
    std::vector<glm::vec3> gridPoints;
    std::vector<bool> gridVisibility;
    
    inline int indexFromRowColumn(int row, int column)
    {
        return row * numberOfColumns + column;
    }
    
    inline void rowColumnFromIndex(int index, int& row, int& column)
    {
        row = index / numberOfColumns;
        column = index % numberOfColumns;
    }
};