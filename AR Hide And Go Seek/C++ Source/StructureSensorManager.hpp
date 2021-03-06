//
//  StructureSensorManager.hpp
//  AR Hide And Go Seek
//
//  Created by Nataly Moreno on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once

#include "SensorManager.hpp"
#include "ShaderProgram.hpp"
#include "TextureManager.hpp"
#include "BasicMesh.hpp"

class StructureSensorManager: public SensorManager
{
public:
	StructureSensorManager(TextureManager* manager, int screenWidth, int screenHeight);
	~StructureSensorManager();
	
	void Draw() override;
	void Update(float deltaTime) override;
	
	void DrawUI() override;
	
	glm::mat4 GetProjectionMatrix() override;
	glm::mat4 GetViewMatrix() override;
	
	void CheckVisibility(std::vector<glm::vec3>& points, std::vector<int>& visibility) override;
    
    bool IsDebugMode() override;
	
	void PanStarted(int x, int y) override;
	void PanMoved(int deltaX, int deltaY) override;
	void PanEnded() override;
    void Tapped(int x, int y) override;
	
private:
	int width, height;
	ShaderProgram* basicShader;
	ShaderProgram* cameraShader;
    ShaderProgram *depthBufferShader;
    BasicMesh* roomModel;
    
    bool debug;
    bool freezeDepth;
    GLuint debugButtonTrueID, debugButtonFalseID, freezeButtonTrueID, freezeButtonFalseID;
    glm::vec2 debugLocation;
    glm::vec2 freezeLocation;
	
	GLuint verticesID, uvsID, indexListID;
    
    void DrawImage(int x, int y, int drawWidth, int drawHeight, GLuint textureID);
};