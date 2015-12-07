//
//  Animation.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/5/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "Animation.hpp"
#include "glm/gtc/matrix_transform.hpp"

using namespace std;
using namespace glm;

Animation::Animation(float frameRate)
{
    frameTime = 1.0f / frameRate;
    time = 0.0f;
}

Animation::~Animation()
{
}

void Animation::Reset()
{
    time = 0.0f;
}

void Animation::Update(float deltaTime)
{
    time += deltaTime;
    if (time > translations.size() * frameTime)
    {
        time -= translations.size() * frameTime;
    }
}

void Animation::AddFrame(vector<vec3> translation, vector<quat> rotation)
{
    translations.push_back(translation);
    rotations.push_back(rotation);
}

void Animation::GetPose(vector<mat4>& pose)
{
    int frame = (int)(time / frameTime);
    float inBetween = time - frameTime * frame;
    vector<vec3> startingTranslation = translations[frame];
    vector<quat> startingRotation = rotations[frame];
    vector<vec3> endingTranslation;
    vector<quat> endingRotation;
    if (frame == translations.size() - 1)
    {
        endingTranslation = translations[0];
        endingRotation = rotations[0];
    }
    else
    {
        endingTranslation = translations[frame + 1];
        endingRotation = rotations[frame + 1];
    }
    for (int i = 0; i < startingTranslation.size(); i++)
    {
        vec3 resultingTranslation = mix(startingTranslation[i], endingTranslation[i], inBetween);
        quat resultingRotation = slerp(startingRotation[i], endingRotation[i], inBetween);
        pose[i] = translate(mat4(), resultingTranslation) * mat4_cast(resultingRotation);
    }
}