//
//  VirtualSensorManager.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/4/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "VirtualSensorManager.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtx/rotate_vector.hpp"
#include "glm/gtc/type_ptr.hpp"

#define JoystickStartingRadius 100
#define JoystickMaximumRadius 150
#define TurnVelocity pi<float>()
#define MaximumPitch pi<float>() / 6
#define Speed 2.0f

using namespace std;
using namespace glm;

VirtualSensorManager::VirtualSensorManager(TextureManager* manager, int screenWidth, int screenHeight)
{
    width = 2 * screenWidth;
    height = 2 * screenHeight;
    
    leftCenter = vec2(screenWidth * 0.25f, screenHeight * 0.6f);
    rightCenter = vec2(screenWidth * 0.75f, screenHeight * 0.6f);
    
    basicShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    roomModel = new BasicMesh("classroom.obj", manager);
    roomModel->SetRotation(vec3(0.0f, -pi<float>() / 2.0f, -pi<float>() / 2.0f));
    
    depthShader = new ShaderProgram("DepthShader", {"position"}, {"projection", "view", "model"});
    depthBuffer = (unsigned char*)malloc(sizeof(unsigned char) * 4 * width * height);
    
    position = vec3(0.0f, 1.62f, 0.0f);
    yawAngle = 0.0f;
    pitchAngle = 0.0f;
}

VirtualSensorManager::~VirtualSensorManager()
{
    delete basicShader;
    delete roomModel;
    delete depthShader;
    delete depthBuffer;
}

void VirtualSensorManager::Draw()
{
    depthShader->Use();
    glUniformMatrix4fv(depthShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(GetProjectionMatrix()));
    glUniformMatrix4fv(depthShader->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
    roomModel->Draw(depthShader);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, depthBuffer);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    basicShader->Use();
    glUniformMatrix4fv(basicShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(GetProjectionMatrix()));
    glUniformMatrix4fv(basicShader->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
    roomModel->Draw(basicShader);
}

void VirtualSensorManager::Update(float deltaTime)
{
    yawAngle   += -TurnVelocity * deltaTime * rightJoystick.x;
    pitchAngle += -TurnVelocity * deltaTime * rightJoystick.y;
    pitchAngle = clamp(pitchAngle, -MaximumPitch, MaximumPitch);
    
    vec3 front = rotate(vec3(0.0, 0.0, 1.0), yawAngle, vec3(0.0, 1.0, 0.0));
    vec3 side = rotate(vec3(1.0, 0.0, 0.0), yawAngle, vec3(0.0, 1.0, 0.0));
    vec3 direction = front * leftJoystick.y + side * leftJoystick.x;
    position += Speed * direction * (float)deltaTime;
}

void VirtualSensorManager::DrawUI()
{
    //TODO
}

mat4 VirtualSensorManager::GetProjectionMatrix()
{
    return perspectiveFov<float>(pi<float>() / 3.0f, width, height, 0.1f, 15.0f);
}

mat4 VirtualSensorManager::GetViewMatrix()
{
    mat4 cameraMatrix = mat4();
    cameraMatrix = translate(cameraMatrix, position);
    cameraMatrix = rotate(cameraMatrix, yawAngle, vec3(0.0f, 1.0f, 0.0f));
    cameraMatrix = rotate(cameraMatrix, pitchAngle, vec3(1.0f, 0.0f, 0.0f));
    return inverse(cameraMatrix);
}

void VirtualSensorManager::CheckVisibility(vector<vec3>& points, vector<bool>& visibility)
{
    mat4 projectionMatrix = GetProjectionMatrix();
    mat4 viewMatrix = GetViewMatrix();
    for (int i = 0; i < points.size(); i++)
    {
        vec4 transformedPoint = projectionMatrix * viewMatrix * vec4(points[i].x, points[i].y, points[i].z, 1.0f);
        transformedPoint /= transformedPoint.w;
        if(InFrustrum(transformedPoint))
        {
            int row = (int)((transformedPoint.y + 1) / 2 * height);
            int column = (int)((transformedPoint.x + 1) / 2 * width);
            float depth = depthBuffer[4 * (row * width + column)] / 255.0f;
            visibility[i] = depth > transformedPoint.z;
        }
        else
        {
            visibility[i] = false;
        }
    }
}

void VirtualSensorManager::PanStarted(int x, int y)
{
    if (distance(leftCenter, vec2(x, y)) < JoystickStartingRadius)
    {
        joystickState = JoystickState::LeftJoystick;
        leftOffset = vec2(x, y) - leftCenter;
    }
    if (distance(rightCenter, vec2(x, y)) < JoystickStartingRadius) {
        joystickState = JoystickState::RightJoystick;
        rightOffset = vec2(x, y) - rightCenter;
    }
}

void VirtualSensorManager::PanMoved(int deltaX, int deltaY)
{
    switch (joystickState) {
        case JoystickState::LeftJoystick:
            leftJoystick = (vec2(deltaX, deltaY) + leftOffset) / (float)JoystickMaximumRadius;
            if (length(leftJoystick) > 1.0f)
            {
                leftJoystick = normalize(leftJoystick);
            }
            break;
            
        case JoystickState::RightJoystick:
            rightJoystick = (vec2(deltaX, deltaY) + rightOffset) / (float)JoystickMaximumRadius;
            if (length(rightJoystick) > 1.0f)
            {
                rightJoystick = normalize(rightJoystick);
            }

            break;
            
        default:
            break;
    }
}

void VirtualSensorManager::PanEnded()
{
    switch (joystickState) {
        case JoystickState::LeftJoystick:
            leftJoystick = vec2();
            leftOffset = vec2();
            break;
            
        case JoystickState::RightJoystick:
            rightJoystick = vec2();
            rightOffset = vec2();
            break;
            
        default:
            break;
    }
    joystickState = JoystickState::None;
}