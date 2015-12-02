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
    TrackerHandler(TextureManager* manager);
    virtual ~TrackerHandler();
    
    void Draw(ShaderProgram* program);
    void Update(float deltaTime);
    
    std::vector<std::vector<bool> > CheckVisibility(std::vector<std::vector<glm::vec3> > testPoints);
    
    glm::mat4 GetProjectionMatrix();
    glm::mat4 GetViewMatrix();
    
    void PanStarted(int x, int y);
    void PanMoved(int deltaX, int deltaY);
    void PanEnded();
    
private:
#if Debug
    enum class JoystickState { None, LeftJoystick, RightJoystick };
#else
#endif
    glm::vec3 position;
    float yawAngle, pitchAngle;
    
    BasicMesh* roomModel;
    float* depthBuffer;
    
    void FillDepthBuffer();//depth=A/Z+B where A=zFar*zNear/(zFar-zNear) and B=zFar/(zFar-zNear)
    
    inline bool InFrustrum(glm::vec3 point)
    {
        return point.x <= 1.0f && point.x >= -1.0f && point.y <= 1.0f && point.y >= -1.0f && point.z >= 0;
    }
};