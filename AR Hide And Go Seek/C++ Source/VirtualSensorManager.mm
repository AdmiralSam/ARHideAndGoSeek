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

#define JoystickStartingRadius 50
#define JoystickMaximumRadius 60
#define TurnVelocity pi<float>()
#define MaximumPitch pi<float>() / 3
#define Speed 2.0f

using namespace std;
using namespace glm;

VirtualSensorManager::VirtualSensorManager(TextureManager* manager, int screenWidth, int screenHeight)
{
    width = 2 * screenWidth;
    height = 2 * screenHeight;
    
    leftCenter = vec2(screenWidth * 0.2f, screenHeight * 0.8f);
    rightCenter = vec2(screenWidth * 0.8f, screenHeight * 0.8f);
    debugLocation = vec2(screenWidth * 0.2f, screenHeight * 0.2f);
    freezeLocation = vec2(screenWidth * 0.8f, screenHeight * 0.2f);
    
    basicShader = new ShaderProgram("BasicMesh", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    roomModel = new BasicMesh("classroom.obj", manager);
    roomModel->SetRotation(vec3(0.0f, -pi<float>() / 2.0f, -pi<float>() / 2.0f));
    
    depthShader = new ShaderProgram("DepthShader", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
    depthBuffer = (unsigned char*)malloc(sizeof(unsigned char) * 4 * width * height);
    
    position = vec3(0.0f, 1.65f, 0.0f);
    yawAngle = 0.0f;
    pitchAngle = 0.0f;
    
    Setup2DDrawing();
    
    debug = false;
    freezeDepth = false;
    
    joystickBaseID = manager->LoadTexture("joystickOuter.png");
    joystickStickID = manager->LoadTexture("joystickInner.png");
    debugButtonFalseID = manager->LoadTexture("joystickOuter.png");
    debugButtonTrueID = manager->LoadTexture("joystickInner.png");
    freezeButtonFalseID = manager->LoadTexture("joystickOuter.png");
    freezeButtonTrueID = manager->LoadTexture("joystickInner.png");
    
    glGenFramebuffers(1, &shadowFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, shadowFrameBuffer);
    glGenTextures(1, &depthTexture);
    glBindTexture(GL_TEXTURE_2D, depthTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32F, width, height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthTexture, 0);
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
    RenderShadowMap();
    depthShader->Use();
    glUniformMatrix4fv(depthShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(GetProjectionMatrix()));
    glUniformMatrix4fv(depthShader->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
    roomModel->Draw(depthShader);
    depthShader->Finish();
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, depthBuffer);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    basicShader->Use();
    glUniformMatrix4fv(basicShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(GetProjectionMatrix()));
    glUniformMatrix4fv(basicShader->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
    roomModel->Draw(basicShader);
    basicShader->Finish();
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
    DrawImage(leftCenter.x, leftCenter.y, 100, 100, joystickBaseID);
    DrawImage(rightCenter.x, rightCenter.y, 100, 100, joystickBaseID);
    vec2 leftLocation = leftCenter + (float)JoystickMaximumRadius * leftJoystick;
    vec2 rightLocation = rightCenter + (float)JoystickMaximumRadius * rightJoystick;
    DrawImage(leftLocation.x, leftLocation.y, 100, 100, joystickStickID);
    DrawImage(rightLocation.x, rightLocation.y, 100, 100, joystickStickID);
    
    DrawImage(debugLocation.x, debugLocation.y, 150, 100, debug ? debugButtonTrueID : debugButtonFalseID);
    DrawImage(freezeLocation.x, freezeLocation.y, 150, 100, freezeDepth ? freezeButtonTrueID : freezeButtonFalseID);
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

void VirtualSensorManager::CheckVisibility(vector<vec3>& points, vector<int>& visibility)
{
    mat4 projectionMatrix = GetProjectionMatrix();
    mat4 viewMatrix = GetViewMatrix();
    for (int i = 0; i < points.size(); i++)
    {
        vec4 transformedPoint = projectionMatrix * viewMatrix * vec4(points[i].x, points[i].y, points[i].z, 1.0f);
        transformedPoint /= transformedPoint.w;
        if(InFrustrum(transformedPoint) && !freezeDepth)
        {
            int row = (int)((transformedPoint.y + 1) / 2 * height);
            int column = (int)((transformedPoint.x + 1) / 2 * width);
            float depth = depthBuffer[4 * (row * width + column)] / 255.0f;
            visibility[i] = (depth > transformedPoint.z * 0.99f) ? 1 : 0;
        }
        else
        {
            visibility[i] = 0;
        }
    }
}

bool VirtualSensorManager::IsDebugMode()
{
    return debug;
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

void VirtualSensorManager::Tapped(int x, int y)
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

void VirtualSensorManager::Setup2DDrawing()
{
    float positions[] = {-1, -1, 0, 1, 1, -1, 0, 1, 1, 1, 0, 1, -1, 1, 0, 1};
    float uvs[] = {0, 0, 1, 0, 1, 1, 0, 1};
    unsigned int indicies[] = {0, 1, 2, 2, 3, 0};
    
    glGenBuffers(1, &positionBufferID);
    glGenBuffers(1, &uvBufferID);
    glGenBuffers(1, &indexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(positions), positions, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, uvBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(uvs), uvs, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indicies), indicies, GL_STATIC_DRAW);
}

void VirtualSensorManager::DrawImage(int x, int y, int drawWidth, int drawHeight, GLuint textureID)
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
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferID);
    glVertexAttribPointer(basicShader->GetLocation("position"), 4, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ARRAY_BUFFER, uvBufferID);
    glVertexAttribPointer(basicShader->GetLocation("uv"), 2, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
    glActiveTexture(GL_TEXTURE0);
    glUniform1i(basicShader->GetLocation("uvMap"), 0);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, NULL);
    basicShader->Finish();
    glEnable(GL_DEPTH_TEST);
}

void VirtualSensorManager::RenderShadowMap()
{
    glBindFramebuffer(GL_FRAMEBUFFER, shadowFrameBuffer);
    mat4 projection = perspectiveFov<float>(pi<float>() / 3.0f, width, height, 0.1f, 15.0f);
    mat4 cameraMatrix = translate(mat4(), vec3(-1.0f, 2.95f, -1.0f));
    cameraMatrix = rotate(cameraMatrix, -pi<float>() / 2, vec3(1.0f, 0.0f, 0.0f));
    mat4 viewMatrix = inverse(cameraMatrix);
    depthShader->Use();
    glUniformMatrix4fv(depthShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(projection));
    glUniformMatrix4fv(depthShader->GetLocation("view"), 1, GL_FALSE, value_ptr(viewMatrix));
    roomModel->Draw(depthShader);
    depthShader->Finish();
    glBindFramebuffer(GL_FRAMEBUFFER, 2);
    glActiveTexture(GL_TEXTURE9);
    glBindTexture(GL_TEXTURE_2D, depthTexture);
}