//
//  Main.mm
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/30/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#include "Main.hpp"
#include "OpenGLES/ES3/gl.h"

void Initialize(float width, float height)
{
    glViewport(0, 0, width, height);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
}

void Dispose()
{
    
}

void Draw()
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void Update(float deltaTime)
{
    
}