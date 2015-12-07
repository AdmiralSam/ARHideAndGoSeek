//
//  Animation.hpp
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/5/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once

#include "glm/glm.hpp"
#include "glm/gtc/quaternion.hpp"

#include <vector>

class Animation
{
public:
    Animation(float frameRate);
    ~Animation();
    
    void Reset();
    void Update(float deltaTime);
    
    void AddFrame(std::vector<glm::vec3> translation, std::vector<glm::quat> rotation);
    
    void GetPose(std::vector<glm::mat4>& pose);
    
private:
    float time;
    float frameTime;
    std::vector<std::vector<glm::vec3> > translations;
    std::vector<std::vector<glm::quat> > rotations;
};