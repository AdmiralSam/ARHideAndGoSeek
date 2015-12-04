//
//  TrackerHandler.hpp
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/1/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once
#define Debug 1

#include "ShaderProgram.hpp"
#include "glm/glm.hpp"
#include "BasicMesh.hpp"

#include <vector>

class TrackerHandler
{
public:
    TrackerHandler(TextureManager* manager, int w, int h);
    virtual ~TrackerHandler();
    
    void Draw(ShaderProgram* program);
    void Update(float deltaTime);
    
    std::vector<bool> CheckVisibility(std::vector<glm::vec4> testPoints);
    
    glm::mat4 GetProjectionMatrix();
    glm::mat4 GetViewMatrix();
    
    void PanStarted(int x, int y);
    void PanMoved(int deltaX, int deltaY);
    void PanEnded();
    
private:
#if Debug
	#define MAX_DISTANCE 150.0
	
    enum class JoystickState { None, LeftJoystick, RightJoystick };
    JoystickState joystickState;
    
    glm::vec3 position;
    float yawAngle, pitchAngle;
	
	float joyStickRightx, joyStickRighty;
	float joyStickLeftx, joyStickLefty;
	void ToJoystickCoordinates(int x, int y, float &joystickX, float &joystickY);
    
    ShaderProgram* depthShader;
#else
#endif
	int width, height;
	
    BasicMesh* roomModel;
    unsigned char* depthBuffer;
    
    void FillDepthBuffer();//depth=A/Z+B where A=zFar*zNear/(zFar-zNear) and B=zFar/(zFar-zNear)
    
    inline bool InFrustrum(glm::vec4 point)
    {
        return point.x <= 1.0f && point.x >= -1.0f && point.y <= 1.0f && point.y >= -1.0f && point.z >= 0;
    }
};