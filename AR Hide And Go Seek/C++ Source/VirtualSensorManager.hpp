//
//  VirtualSensorManager.hpp
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once

#include "SensorManager.hpp"
#include "ShaderProgram.hpp"
#include "TextureManager.hpp"
#include "BasicMesh.hpp"

class VirtualSensorManager: public SensorManager
{
public:
    VirtualSensorManager(TextureManager* manager, int screenWidth, int screenHeight);
    ~VirtualSensorManager();
    
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
    BasicMesh* roomModel;
    
    ShaderProgram* depthShader;
    unsigned char* depthBuffer;
    
    glm::vec3 position;
    float yawAngle, pitchAngle;
    
    enum class JoystickState { None, LeftJoystick, RightJoystick };
    JoystickState joystickState;
    glm::vec2 leftJoystick, rightJoystick;
    glm::vec2 leftOffset, rightOffset;
    glm::vec2 leftCenter, rightCenter;
    
    GLuint joystickBaseID, joystickStickID;
    GLuint positionBufferID, uvBufferID, indexBufferID;
    
    bool debug;
    bool freezeDepth;
    GLuint debugButtonTrueID, debugButtonFalseID, freezeButtonTrueID, freezeButtonFalseID;
    glm::vec2 debugLocation;
    glm::vec2 freezeLocation;
    
    GLuint shadowFrameBuffer;
    GLint defaultFrameBuffer;
    GLuint depthTexture;
    
    void Setup2DDrawing();
    void DrawImage(int x, int y, int drawWidth, int drawHeight, GLuint textureID);
    void RenderShadowMap();
};