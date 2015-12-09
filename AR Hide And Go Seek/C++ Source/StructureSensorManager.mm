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
	
	cameraShader = new ShaderProgram("CameraShader", {"position", "uv"}, {"SamplerY", "SamplerUV"});
	const GLfloat vertices[] = {
		-1.0,  1.0, 0.0, 1.0,
		1.0,  1.0, 0.0, 1.0,
		-1.0, -1.0, 0.0, 1.0,
		1.0, -1.0, 0.0, 1.0
	};
	
	const GLfloat uvs[] = {
		0.0, 0.0,
		1.0, 0.0,
		0.0, 1.0,
		1.0, 1.0
	};
	
	const int indexList[] = {1, 0, 2, 2, 3, 1};
	
	glGenBuffers(1, &verticesID);
	glGenBuffers(1, &uvsID);
	glGenBuffers(1, &indexListID);
	
	glBindBuffer(GL_ARRAY_BUFFER, verticesID);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), &vertices[0], GL_STATIC_DRAW);
	
	glBindBuffer(GL_ARRAY_BUFFER, uvsID);
	glBufferData(GL_ARRAY_BUFFER, sizeof(uvs), &uvs[0], GL_STATIC_DRAW);
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexListID);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexList), &indexList[0], GL_STATIC_DRAW);

	
    [[StructureSensorS sharedSensorInstance] connectAndStartStreaming];
}

StructureSensorManager::~StructureSensorManager()
{
    delete roomModel;
    delete basicShader;
	delete cameraShader;
}

void StructureSensorManager::Draw()
{
	glDisable(GL_DEPTH_TEST);

	cameraShader->Use();
	glEnable(GL_TEXTURE_2D);
	glBindBuffer(GL_ARRAY_BUFFER, verticesID);
	glVertexAttribPointer(cameraShader->GetLocation("position"), 4, GL_FLOAT, GL_FALSE, 0, NULL);
	
	glBindBuffer(GL_ARRAY_BUFFER, uvsID);
	glVertexAttribPointer(cameraShader->GetLocation("uv"), 2, GL_FLOAT, GL_FALSE, 0, NULL); //bind to shader variable
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexListID);

	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, [[StructureSensorS sharedSensorInstance] getLumaTextureID]);
	
	glActiveTexture(GL_TEXTURE3);
	glBindTexture(GL_TEXTURE_2D, [[StructureSensorS sharedSensorInstance] getChromaTextureID]);
	
	glUniform1i(cameraShader->GetLocation("SamplerY"), 2);
	glUniform1i(cameraShader->GetLocation("SamplerUV"), 3);
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexListID);
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, NULL);
	cameraShader->Finish();
	
	glEnable(GL_DEPTH_TEST);
	
    basicShader->Use();
    glUniformMatrix4fv(basicShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(GetProjectionMatrix()));
    glUniformMatrix4fv(basicShader->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
    roomModel->Draw(basicShader);
	basicShader->Finish();
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
    
    // Y & Z need to be flipped and multiplied by inverse view
    mat4 flipY = scale(mat4(), vec3(1.0f, -1.0f, -1.0f));
    
    return flipY * inverse(glView) * flipY;
}

void StructureSensorManager::CheckVisibility(std::vector<glm::vec3>& points, std::vector<int>& visibility)
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