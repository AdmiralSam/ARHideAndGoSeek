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
    if(visibilityGrid->IsVisible(targetRow, targetColumn)){
        visibilityGrid->ClosestInvisible(currentRow, currentColumn, targetRow, targetColumn);
        pathRows.clear();
        pathColumns.clear();
        visibilityGrid->FindPath(currentRow, currentColumn, targetRow, targetColumn, pathRows, pathColumns);
        mesh->PlayAnimation("Running");
    }
    if(pathRows.size() > 0){
        vec3 newPosition = visibilityGrid->PositionFromRowColumn(pathRows.back(), pathColumns.back());
        vec3 destination = visibilityGrid->PositionFromRowColumn(targetRow, targetColumn);
        currentRow = pathRows.back();
        currentColumn = pathColumns.back();
        pathRows.pop_back();
        pathColumns.pop_back();
        if (pathRows.size() == 0)
        {
            mesh->PlayAnimation("Idle");
        }
        else
        {
            mesh->SetRotation(vec3(0.0f, atan(newPosition.z - destination.z, destination.x - newPosition.x), 0.0f));
        }
        newPosition.y = 0.05f;
        mesh->SetPosition(newPosition);
    }
}