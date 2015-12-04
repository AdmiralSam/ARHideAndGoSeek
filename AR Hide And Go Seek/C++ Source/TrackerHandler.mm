//
//  TrackerHandler.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/1/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "TrackerHandler.hpp"
#include "glm/gtx/rotate_vector.hpp"
#include "glm/gtc/type_ptr.hpp"

#include <stdio.h>

using namespace std;
using namespace glm;

TrackerHandler::TrackerHandler(TextureManager* manager, int w, int h)
{
	roomModel = new BasicMesh("classroom.obj", manager);
	roomModel->SetRotation(vec3(0.0, -pi<float>()/2.0, -pi<float>()/2.0));
    
    depthBuffer = new unsigned char[w * h * 16];
    
    width = w;
    height = h;
#if Debug
	position  = vec3(0.0, 1.62, 0.0);
	yawAngle = pitchAngle = 0.0;
	
	joyStickRightx = joyStickRighty = 0.0;
	joyStickLeftx  = joyStickLefty  = 0.0;
    
    depthShader = new ShaderProgram("Shader copy", {"position", "uv"}, {"projection", "view", "model", "uvMap"});
#else
#endif
}

TrackerHandler::~TrackerHandler()
{
	free(roomModel);
	free(depthBuffer);
}

void TrackerHandler::Draw(ShaderProgram* program)
{
    depthShader->Use();
    glUniformMatrix4fv(depthShader->GetLocation("projection"), 1, GL_FALSE, value_ptr(GetProjectionMatrix()));
    glUniformMatrix4fv(depthShader->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
    roomModel->Draw(depthShader);
    glReadPixels(0, 0, 2 * width, 2 * height, GL_RGBA, GL_UNSIGNED_BYTE, depthBuffer);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    program->Use();
	glUniformMatrix4fv(program->GetLocation("projection"), 1, GL_FALSE, value_ptr(GetProjectionMatrix()));
	glUniformMatrix4fv(program->GetLocation("view"), 1, GL_FALSE, value_ptr(GetViewMatrix()));
	roomModel->Draw(program);
}

void TrackerHandler::Update(float deltaTime)
{
#if Debug
	yawAngle   += -pi<float>() * deltaTime * joyStickRightx;
	pitchAngle += -pi<float>() * deltaTime * joyStickRighty;
	
	pitchAngle = std::max(-pi<float>()/6, std::min(pitchAngle, pi<float>() / 6));
	
	vec3 f = rotate(vec3(0.0, 0.0, -1.0), yawAngle, vec3(0.0, 1.0, 0.0));
	vec3 s = rotate(vec3(1.0, 0.0, 0.0), yawAngle, vec3(0.0, 1.0, 0.0));
	vec3 direction = -1.0f * f * joyStickLefty + s * joyStickLeftx;
	position += 2.0f * direction * (float)deltaTime;
#else
#endif
}

vector<bool> TrackerHandler::CheckVisibility(vector<vec4> testPoints)
{
	vector<bool> visible;
    mat4 projection = GetProjectionMatrix();
    mat4 view = GetViewMatrix();
    for(auto point : testPoints) {
        vec4 transformedPoint = projection * view * point;
        transformedPoint = transformedPoint / transformedPoint.w;
        if(InFrustrum(transformedPoint)) {
            int row = (int)((transformedPoint.y + 1) * height);
            int column = (int)((transformedPoint.x + 1) * width);
            float depthThere = depthBuffer[4 * (row * 2 * width + column)] / 255.0f;
            visible.push_back(depthThere > transformedPoint.z);
        }
        else if(InFrustrum(transformedPoint * 0.8f))
        {
            visible.push_back(true);
        }
        else
        {
            visible.push_back(false);
        }
    }
    return visible;
}

mat4 TrackerHandler::GetProjectionMatrix()
{
	return perspectiveFov<float>(pi<float>()/3.0f, width, height, 0.1f, 15.0f);
}

mat4 TrackerHandler::GetViewMatrix()
{
#if Debug
	mat4 cameraMatrix = mat4();
	cameraMatrix = translate(cameraMatrix, position);
	cameraMatrix = rotate(cameraMatrix, yawAngle, vec3(0.0, 1.0, 0.0));
	cameraMatrix = rotate(cameraMatrix, pitchAngle, vec3(1.0, 0.0, 0.0));
	return inverse(cameraMatrix);
#else
#endif
}

void TrackerHandler::PanStarted(int x, int y)
{
#if Debug
	vec2 rightJoystickLocation = vec2(5.0 * width / 6.0, height / 2.0);
	vec2 leftJoystickLocation  = vec2(width / 6.0, height / 2.0);
	
	if(distance(vec2(x,y), rightJoystickLocation) < 100.0)
	{
		joystickState = JoystickState::RightJoystick;
	}
	if(distance(vec2(x,y), leftJoystickLocation) < 100.0)
	{
		joystickState = JoystickState::LeftJoystick;
	}
#endif
}

void TrackerHandler::PanMoved(int deltaX, int deltaY)
{
#if Debug
	float joystickX, joystickY;
	
	ToJoystickCoordinates(deltaX, deltaY, joystickX, joystickY);
	
	switch(joystickState)
	{
		case JoystickState::RightJoystick:
			joyStickRightx = joystickX;
			joyStickRighty = joystickY;
			break;
		case JoystickState::LeftJoystick:
			joyStickLeftx = joystickX;
			joyStickLefty = joystickY;
			break;
		default:
			break;
	}
#endif
}

void TrackerHandler::PanEnded()
{
#if Debug
	switch (joystickState)
	{
		case JoystickState::RightJoystick:
			joyStickRightx = joyStickRighty = 0.0f;
			break;
		
		case JoystickState::LeftJoystick:
			joyStickLeftx = joyStickLefty = 0.0f;
		default:
			break;
	}
	
	joystickState = JoystickState::None;
#endif
}

void TrackerHandler::FillDepthBuffer()
{
	
}

#if Debug
void TrackerHandler::ToJoystickCoordinates(int x, int y, float &joystickX, float &joystickY)
{
	joystickX = x / MAX_DISTANCE;
	joystickY = y / MAX_DISTANCE;
	
	float length = sqrt(joystickX * joystickX + joystickY * joystickY);
	
	if(length > 1.0)
	{
		joystickX /= length;
		joystickY /= length;
	}
}
#endif