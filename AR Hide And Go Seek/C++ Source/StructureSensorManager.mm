//
//  StructureSensorManager.cpp
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "StructureSensorManager.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "StructureSensorS.h"
#include <GLKit/GLKit.h>

using namespace glm;

StructureSensorManager::StructureSensorManager(TextureManager* manager, int screenWidth, int screenHeight)
{
	width  = screenWidth;
	height = screenHeight;
	
    basicShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    roomModel = new BasicMesh("classroom.obj", manager);
    roomModel->SetRotation(vec3(0.0f, -pi<float>() / 2.0f, -pi<float>() / 2.0f));
    
    [[StructureSensorS sharedSensorInstance] connectAndStartStreaming];
}

StructureSensorManager::~StructureSensorManager()
{
    delete roomModel;
    delete basicShader;
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
    GLKMatrix4 view = [[StructureSensorS sharedSensorInstance] getPose];
    
    mat4 glView;
    for (int i = 0; i < 4; i++)
    {
        for(int j = 0; j < 4; j++)
        {
            glView[i][j] = view.m[4 * i + j];
        }
    }
    /*mat4 flipY = scale(mat4(), vec3(1.0f, -1.0f, -1.0f));
    mat4 swapXandZ = mat4();
    swapXandZ[0][0] = 0;
    swapXandZ[0][1] = 1;
    swapXandZ[1][0] = 1;
    swapXandZ[1][1] = 0;
    return swapXandZ * flipY * glView;*/
    
    return glView;
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