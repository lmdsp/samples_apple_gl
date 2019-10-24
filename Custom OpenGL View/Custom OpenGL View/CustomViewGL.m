//
//  CustomViewGL.m
//  Custom OpenGL View
//
//  Created by Lorcan Mc Donagh on 30/09/2018.
//  Copyright © 2018 Lorcan Mc Donagh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CustomViewGL.h"

@implementation CustomOpenGLView
{
@private
    NSOpenGLContext*     _openGLContext;
    NSOpenGLPixelFormat* _pixelFormat;
}

+ (NSOpenGLPixelFormat*)defaultPixelFormat
{
    return nil;
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat*)format
{
    self = [super initWithFrame:frameRect];
    if (self != nil) {
        _pixelFormat   = [format retain];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_surfaceNeedsUpdate:)
                                                     name:NSViewGlobalFrameDidChangeNotification
                                                   object:self];
    }
    
    return self;
}

- (void)setOpenGLContext:(NSOpenGLContext*)context
{
    _openGLContext = context;
}

- (NSOpenGLContext*)openGLContext
{
    return _openGLContext;
}

- (void)clearGLContext
{
    
}

- (void)prepareOpenGL
{
    
}

- (void)update
{
    
}

- (void) _surfaceNeedsUpdate:(NSNotification*)notification
{
    [self update];
}

- (void)setPixelFormat:(NSOpenGLPixelFormat*)pixelFormat
{
    
}

- (NSOpenGLPixelFormat*)pixelFormat
{
    return _pixelFormat;
}

- (void)lockFocus
{
    NSOpenGLContext* context = [self openGLContext];
    
    [super lockFocus];
    if ([context view] != self) {
        [context setView:self];
    }
    [context makeCurrentContext];
}

-(void) drawRect
{
    [_openGLContext makeCurrentContext];
    //Perform drawing here
    [_openGLContext flushBuffer];
}

-(void) viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    if ([self window] == nil)
        [_openGLContext clearDrawable];
}

@end
