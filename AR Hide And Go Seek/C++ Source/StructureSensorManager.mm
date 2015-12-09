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
    
    depthBufferShader = new ShaderProgram("DepthBufferShader", {"position", "uv"}, {"uvMap", "nearPlane", "farPlane"});
	
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
    
    debugButtonFalseID = manager->LoadTexture("showGrid.png");
    debugButtonTrueID = manager->LoadTexture("hideGrid.png");
    freezeButtonFalseID = manager->LoadTexture("freeze.png");
    freezeButtonTrueID = manager->LoadTexture("unfreeze.png");
    debugLocation = vec2(screenWidth * 0.2f, screenHeight * 0.2f);
    freezeLocation = vec2(screenWidth * 0.8f, screenHeight * 0.2f);
    
    debug = false;
    freezeDepth = false;
}

StructureSensorManager::~StructureSensorManager()
{
    delete roomModel;
    delete basicShader;
	delete cameraShader;
}

void StructureSensorManager::Draw()
{
    
    /*
     
     Depth buffer modification commented out for final submission as it 
     doesn't work and hurts performance.
     
    depthBufferShader->Use();
    glBindBuffer(GL_ARRAY_BUFFER, verticesID);
    glVertexAttribPointer(depthBufferShader->GetLocation("position"), 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, uvsID);
    glVertexAttribPointer(depthBufferShader->GetLocation("uv"), 2, GL_FLOAT, GL_FALSE, 0, NULL); //bind to shader variable
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexListID);
    glActiveTexture(GL_TEXTURE6);
    glBindTexture(GL_TEXTURE_2D, [[StructureSensorS sharedSensorInstance] getDepthTextureID]);
    
    glUniform1i(depthBufferShader->GetLocation("uvMap"), 6);
    glUniform1i(depthBufferShader->GetLocation("nearPlane"), 0.1f);
    glUniform1i(depthBufferShader->GetLocation("farPlane"), 15.f);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, NULL);

    depthBufferShader->Finish();*/
    
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
    /*
    DrawImage(debugLocation.x, debugLocation.y, 150, 100, debug ? debugButtonTrueID : debugButtonFalseID);
    DrawImage(freezeLocation.x, freezeLocation.y, 150, 100, freezeDepth ? freezeButtonTrueID : freezeButtonFalseID);
     */
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
    for (int i = 0; i < visibility.size(); i++)
    {
        visibility[i] = 0;
    }
}

bool StructureSensorManager::IsDebugMode()
{
    return debug;
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

void StructureSensorManager::Tapped(int x, int y)
{
    if (x >= (debugLocation.x - 75) && x <= (debugLocation.x + 75) && y >= (debugLocation.y - 50) && y <= (debugLocation.y + 50))
    {
        debug = !debug;
    }
    if (x >= (freezeLocation.x - 75) && x <= (freezeLocation.x + 75) && y >= (freezeLocation.y - 50) && y <= (freezeLocation.y + 50))
    {
        freezeDepth = !freezeDepth;
    }
}

void StructureSensorManager::DrawImage(int x, int y, int drawWidth, int drawHeight, GLuint textureID)
{
    float screenX = 2.0f * x / width * 2.0f - 1.0f;
    float screenY = 2.0f * (height / 2 - y) / height * 2.0f - 1.0f;
    float xScale = 2.0f * drawWidth / width;
    float yScale = 2.0f * drawHeight / height;
    mat4 model = translate(mat4(), vec3(screenX, screenY, 0.0f));
    model = scale(model, vec3(xScale, yScale, 1.0f));
    glDisable(GL_DEPTH_TEST);
    basicShader->Use();
    glUniformMatrix4fv(basicShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(mat4()));
    glUniformMatrix4fv(basicShader->GetLocation("view"), 1, GL_FALSE, value_ptr(mat4()));
    glUniformMatrix4fv(basicShader->GetLocation("model"), 1, GL_FALSE, value_ptr(model));
    glBindBuffer(GL_ARRAY_BUFFER, verticesID);
    glVertexAttribPointer(basicShader->GetLocation("position"), 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ARRAY_BUFFER, uvsID);
    glVertexAttribPointer(basicShader->GetLocation("uv"), 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexListID);
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(basicShader->GetLocation("uvMap"), 0);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, NULL);
    basicShader->Finish();
    glEnable(GL_DEPTH_TEST);
}