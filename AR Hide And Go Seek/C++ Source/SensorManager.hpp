//
//  SensorManager.hpp
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once

#include "glm/glm.hpp"
#include "ShaderProgram.hpp"

#include <vector>

class SensorManager
{
public:
    virtual ~SensorManager();
    
    virtual void Draw() = 0;
    virtual void Update(float deltaTime) = 0;
    
    virtual void DrawUI() = 0;
    
    virtual glm::mat4 GetProjectionMatrix() = 0;
    virtual glm::mat4 GetViewMatrix() = 0;
    
    virtual void CheckVisibility(std::vector<glm::vec3>& points, std::vector<int>& visibility) = 0;
    
    virtual bool IsDebugMode() = 0;
    
    virtual void PanStarted(int x, int y) = 0;
    virtual void PanMoved(int deltaX, int deltaY) = 0;
    virtual void PanEnded() = 0;
    virtual void Tapped(int x, int y) = 0;
    
protected:
    inline bool InFrustrum(glm::vec4 point)
    {
        return point.x <= 1.0f && point.x >= -1.0f && point.y <= 1.0f && point.y >= -1.0f && point.z >= 0;
    }
};