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

#include <vector>

class TrackerHandler
{
public:
    TrackerHandler();
    virtual ~TrackerHander();
    
    void Draw(ShaderProgram* program);
    void Update(float deltaTime);
    
    std::vector<std::vector<bool> > CheckVisibility(std::vector<std::vector<glm::vec3> > testPoints);
    
private:
    void FillDepthBuffer();//depth=A/Z+B where A=zFar*zNear/(zFar-zNear) and B=zFar/(zFar-zNear)
    
    inline bool InFrustrum(glm::vec3 point)
    {
        return point.x <= 1.0f && point.x >= -1.0f && point.y <= 1.0f && point.y >= -1.0f && point.z >= 0;
    }
};