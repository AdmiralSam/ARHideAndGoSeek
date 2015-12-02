//
//  TrackerHandler.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 12/1/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "TrackerHandler.hpp"
#include "glm/gtx/rotate_vector.hpp"

using namespace std;
using namespace glm;

TrackerHandler::TrackerHandler(TextureManager* manager, int w, int h)
{
	roomModel = new BasicMesh("classroom.obj", manager);
	position  = vec3(0.0, 0.0, 14.0);
	yawAngle = pitchAngle = 0.0;
	
	width = w;
	height = h;
}

TrackerHandler::~TrackerHandler()
{
	free(roomModel);
	free(depthBuffer);
}

void TrackerHandler::Draw(ShaderProgram* program)
{
	roomModel->Draw(program);
}

void TrackerHandler::Update(float deltaTime)
{
	yawAngle   += -pi<float>() * deltaTime * joyStickRightx;
	pitchAngle += -pi<float>() * deltaTime * joyStickRighty;
	
	pitchAngle = std::max(-pi<float>()/8, std::min(pitchAngle, pi<float>() / 8));
	
	vec3 f = rotate(vec3(0.0, 0.0, -1.0), yawAngle, vec3(0.0, 1.0, 0.0));
	vec3 s = rotate(vec3(1.0, 0.0, 0.0), yawAngle, vec3(0.0, 1.0, 0.0));
	vec3 direction = -1.0f * f * joyStickLefty + s * joyStickLeftx;
	position += 5.0f * direction * (float)deltaTime;
	
}

vector<vector<bool> > TrackerHandler::CheckVisibility(vector<vector<vec3> > testPoints)
{
	vector<vector<bool>> v;
	
	return v;
}

mat4 TrackerHandler::GetProjectionMatrix()
{
	return perspectiveFov<float>(pi<float>()/3.0f, width, height, 0.1f, 100.0f);
}

mat4 TrackerHandler::GetViewMatrix()
{
	mat4 cameraMatrix = mat4();
	cameraMatrix = translate(cameraMatrix, position);
	cameraMatrix = rotate(cameraMatrix, yawAngle, vec3(0.0, 1.0, 0.0));
	cameraMatrix = rotate(cameraMatrix, pitchAngle, vec3(1.0, 0.0, 0.0));
	return inverse(cameraMatrix);
}

void TrackerHandler::PanStarted(int x, int y)
{
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
}

void TrackerHandler::PanMoved(int deltaX, int deltaY)
{
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
}

void TrackerHandler::PanEnded()
{
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
}

void TrackerHandler::FillDepthBuffer()
{
	
}

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




























