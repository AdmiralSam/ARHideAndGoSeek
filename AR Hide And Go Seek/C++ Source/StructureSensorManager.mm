//
//  StructureSensorManager.cpp
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "StructureSensorManager.hpp"
#include "StructureSensorS.h"
#include "glm/gtc/type_ptr.hpp"
#include "glm/gtc/matrix_transform.hpp"

using namespace glm;

StructureSensorManager::StructureSensorManager(TextureManager* manager, int screenWidth, int screenHeight)
{
	textureManager = manager;
	width  = screenWidth;
	height = screenHeight;
    basicShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    roomModel = new BasicMesh("classroom.obj", manager);
    roomModel->SetRotation(vec3(0.0f, -pi<float>() / 2.0f, -pi<float>() / 2.0f));
}

StructureSensorManager::~StructureSensorManager()
{
	free(textureManager);
}

void StructureSensorManager::Draw()
{
    basicShader->Use();
    glUniformMatrix4fv(basicShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(GetProjectionMatrix()));
    glUniformMatrix4fv(basicShader->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
    roomModel->Draw(basicShader);
}

void StructureSensorManager::Update(float deltaTime)
{
	
}

void StructureSensorManager::DrawUI()
{
	
}

mat4 StructureSensorManager::GetProjectionMatrix()
{
	 return perspectiveFov<float>(pi<float>() / 3.0f, width, height, 0.1f, 15.0f);
}

mat4 StructureSensorManager::GetViewMatrix()
{
	mat4 m;
    GLKMatrix4 pose;
    
    pose = [[StructureSensorS sharedSensorInstance] GetPose];
    
    for (int i = 0; i < 16; i++)
    {
        int row = i % 4;
        int column = i / 4;
        m[column][row] = pose.m[i];
    }
    
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





























