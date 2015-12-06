//
//  StructureSensorManager.cpp
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "StructureSensorManager.hpp"

using namespace glm;

StructureSensorManager::StructureSensorManager(TextureManager* manager, int screenWidth, int screenHeight)
{
	textureManager = manager;
	width  = screenWidth;
	height = screenHeight;
	
}

StructureSensorManager::~StructureSensorManager()
{
	free(textureManager);
}

void StructureSensorManager::Draw()
{
	
}

void StructureSensorManager::Update(float deltaTime)
{
	
}

void StructureSensorManager::DrawUI()
{
	
}

mat4 StructureSensorManager::GetProjectionMatrix()
{
	mat4 m;
	
	return m;
}

mat4 StructureSensorManager::GetViewMatrix()
{
	mat4 m;
	
	return m;
}

void StructureSensorManager::CheckVisibility(std::vector<glm::vec3>& points, std::vector<bool>& visibility)
{
	
}

void StructureSensorManager::PanStarted(int x, int y)
{
	//n/a
}

void StructureSensorManager::PanMoved(int deltaX, int deltaY)
{
	//n/a
}

void StructureSensorManager::PanEnded()
{
	//n/a
}





























