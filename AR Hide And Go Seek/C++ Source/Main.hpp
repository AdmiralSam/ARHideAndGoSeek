//
//  Main.hpp
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/30/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//

#pragma once

void Initialize(float width, float height);
void Dispose();

void Draw();
void Update(float deltaTime);

void PanStarted(int x, int y);
void PanMoved(int deltaX, int deltaY);
void PanEnded();