//
//  CustomViewGL.h
//  Custom OpenGL View
//
//  Created by Lorcan Mc Donagh on 30/09/2018.
//  Copyright © 2018 Lorcan Mc Donagh. All rights reserved.
//

#ifndef CustomViewGL_h
#define CustomViewGL_h

#import <Cocoa/Cocoa.h>

@class NSOpenGLContext, NSOpenGLPixelFormat;

// [Drawing OpenGL Content to a Custom View](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_drawing/opengl_drawing.html#//apple_ref/doc/uid/TP40001987-CH404-SW3)
@interface CustomOpenGLView : NSView

+ (NSOpenGLPixelFormat*)defaultPixelFormat;
- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat*)format;
- (void)setOpenGLContext:(NSOpenGLContext*)context;
- (NSOpenGLContext*)openGLContext;
- (void)clearGLContext;
- (void)prepareOpenGL;
- (void)update;
- (void)setPixelFormat:(NSOpenGLPixelFormat*)pixelFormat;
- (NSOpenGLPixelFormat*)pixelFormat;

@end

#endif /* CustomViewGL_h */
