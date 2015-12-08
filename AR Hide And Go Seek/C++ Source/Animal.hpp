//
//  Animal.hpp
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/7/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once

#include "AdvancedMesh.hpp"
#include "VisibilityGrid.hpp"

class Animal
{
public:
    Animal(VisibilityGrid* grid, TextureManager* manager);
    ~Animal();
    
    void Draw(ShaderProgram* program);
    void Update(float deltaTime);
private:
    AdvancedMesh* mesh;
    VisibilityGrid* visibilityGrid;
    int targetRow, targetColumn;
    int currentRow, currentColumn;
    std::vector<int> pathRows, pathColumns;
};