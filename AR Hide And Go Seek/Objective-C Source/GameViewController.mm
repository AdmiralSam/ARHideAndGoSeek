//
//  GameViewController.m
//  AR Hide And Go Seek
//
//  Created by Samuel Dong on 11/18/15.
//  Copyright © 2015 SamuelNatalyRussell. All rights reserved.
//
//  With code from the Unbounded Tracker API example program from Occipital

#import "GameViewController.h"
#import "OpenGLES/ES3/gl.h"
#import "Main.hpp"

#import "StructureSensorS.h"
@interface GameViewController () 
{
	@private
	StructureSensorS *sharedSensorInstance;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (void)onPanEvent:(UIPanGestureRecognizer*) recognizer;
- (void)onTapEvent:(UITapGestureRecognizer*) recognizer;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanEvent:)];
	panGesture.minimumNumberOfTouches = 1;
	panGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapEvent:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
	
	sharedSensorInstance = [StructureSensorS sharedSensorInstance];
	[sharedSensorInstance initializeSensor:self withContext:self.context];
    
    [self setupGL];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    Initialize(self.view.bounds.size.width, self.view.bounds.size.height);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    Dispose();
}

- (void)update
{
    Update([self timeSinceLastUpdate]);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    Draw();
}

- (void)onPanEvent:(UIPanGestureRecognizer *)recognizer
{
    CGPoint startingPoint = [recognizer locationInView:self.view];
    CGPoint translation = [recognizer translationInView:self.view];
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            PanStarted(startingPoint.x, startingPoint.y);
            break;
        
        case UIGestureRecognizerStateChanged:
            PanMoved(translation.x, translation.y);
            break;
            
        case UIGestureRecognizerStateEnded:
            PanEnded();
            break;
            
        default:
            break;
    }
}

- (void)onTapEvent:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint point = [recognizer locationInView:self.view];
        Tapped(point.x, point.y);
    }
}

@end







