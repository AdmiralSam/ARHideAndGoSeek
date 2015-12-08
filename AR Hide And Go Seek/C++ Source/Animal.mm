//
//  Animal.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/7/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "Animal.hpp"

using namespace glm;

Animal::Animal(VisibilityGrid* grid, TextureManager* manager)
{
    visibilityGrid = grid;
    mesh = new AdvancedMesh("Skitty.iqe", manager); //some2.iqe for iPad
    mesh->PlayAnimation("Idle");
    mesh->SetScale(vec3(0.1f, 0.1f, 0.1f));
    mesh->SetPosition(vec3(0.0f, 0.05f, 0.0f));
    currentRow = 55;
    currentColumn = 30;
    targetRow = 55;
    targetColumn = 30;
    idle = true;
}

Animal::~Animal()
{
    delete mesh;
}

void Animal::Draw(ShaderProgram* program)
{
    mesh->Draw(program);
}

void Animal::Update(float deltaTime)
{
    mesh->Update(deltaTime);
    if(visibilityGrid->IsVisible(targetRow, targetColumn)){
        visibilityGrid->ClosestInvisible(currentRow, currentColumn, targetRow, targetColumn);
        pathRows.clear();
        pathColumns.clear();
        visibilityGrid->FindPath(currentRow, currentColumn, targetRow, targetColumn, pathRows, pathColumns);
        pathRows.pop_back();
        pathColumns.pop_back();
        if (idle)
        {
            idle = false;
            mesh->PlayAnimation("Running");
        }
    }
    if(pathRows.size() > 0){
        vec3 oldPosition = visibilityGrid->PositionFromRowColumn(currentRow, currentColumn);
        vec3 newPosition = visibilityGrid->PositionFromRowColumn(pathRows.back(), pathColumns.back());
        currentRow = pathRows.back();
        currentColumn = pathColumns.back();
        pathRows.pop_back();
        pathColumns.pop_back();
        if (pathRows.size() == 0)
        {
            if (!idle)
            {
                idle = true;
                mesh->PlayAnimation("Idle");
            }
        }
        mesh->SetRotation(vec3(0.0f, atan(oldPosition.z - newPosition.z, newPosition.x - oldPosition.x), 0.0f));
        newPosition.y = 0.05f;
        mesh->SetPosition(newPosition);
    }
}