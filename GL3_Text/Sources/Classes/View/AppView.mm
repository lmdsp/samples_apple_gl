/*
     File: AppView.mm
 Abstract: 
 Applications's OpenGL view.
 
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#pragma mark -
#pragma mark Headers

// OpenGL Core Profile
#import <OpenGL/gl.h>

// Application view code
#import "AppView.h"

#pragma mark -
#pragma mark Enumerated Types

// Text types
enum GLTextType
{
	kGLUTextPrespective = 0,
	kGLUTextNonPrespective
};

// Key types
enum GLKeyDown
{
	GLKeyDownFullscreen         = 27,	// ASCII ESC - Fullscreen
	GLKeyDownTextNonPerspective = 110,	// ASCII 'n' - Non-perspective text
	GLKeyDownTextPerspective    = 112	// ASCII 'p' - Perspective text
};

#pragma mark -

// Private interfaces
@interface AppView(Private)

- (NSPoint) mousePoint:(NSEvent *)pEvent;

- (void) terminate:(NSNotification *)notification;

- (void) initOpenGL;
- (void) queryOpenGL;

@end

#pragma mark -

@implementation AppView
{
@private
    BOOL          mbFullscreen;
    GLU::TextRef  mpText[2];
    NSPoint       m_MousePt;
    GLuint        mnSelector;
} // AppView

// Draw texts in a scene
- (void) scene
{
    // No need to flush the buffer here.  The base class render method
    // takes care of this.
    GLU::TextDisplay(mpText[mnSelector]);
} // scene

// When application is terminating cleanup the objects
- (void) terminate:(NSNotification *)notification
{
	[self  cleanup];
} // terminate

// Designated initializer
- (id) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
    
    if(self)
    {
        // App starts in a window mode
        mbFullscreen = NO;
        
        // It's important to clean up our rendering objects before we terminate -- Cocoa will
        // not specifically release everything on application termination, so we explicitly
        // call our cleanup (private object destructor) routines.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminate:)
                                                     name:@"NSApplicationWillTerminateNotification"
                                                   object:NSApp];
    } // if

    return self;
} // initWithFrame

// Tear-down objects
- (void) cleanup
{
	GLU::TextDelete(mpText[kGLUTextPrespective]);
	GLU::TextDelete(mpText[kGLUTextNonPrespective]);
	
    [super cleanup];
} // cleanup

// Dealloc or destructor
- (void) dealloc
{
    [self cleanup];
    
	[super dealloc];
} // dealloc

- (BOOL) isOpaque
{
    return YES;
} // isOpaque

- (BOOL) acceptsFirstResponder
{
    return YES;
} // acceptsFirstResponder

- (void) initOpenGL
{
	// Text-view bounds
	NSRect  bounds = [self bounds];
	
	// Gradient color matrix for perspective text
	const GLfloat gradientColors1[16] =
	{
		1.0f, 0.0f, 1.0f,  1.0f,	// make this vertex purple
		1.0f, 0.0f, 0.0f, 0.75f,	// make this vertex red
		1.0f, 1.0f, 0.0f,  0.5f,	// make this vertex yellow
		0.0f, 0.0f, 1.0f, 0.25f		// make this vertex blue
	};
	
	// Non-perspective text
	mpText[kGLUTextPrespective] = GLU::TextCreatePerspective(CFSTR("The Quick Brown Fox\nJumps Over\nThe Lazy Dog!!"),
														 CFSTR("Palatino"),
														 1024.0f,
														 kCTCenterTextAlignment,
														 bounds,
														 gradientColors1);
	
	// Non-perspective text position
	NSPoint position = NSMakePoint(32.0f, 32.0f);
	
	// Gradient color matrix for non-perspective text
	const GLfloat gradientColors2[16] =
	{
		1.0f, 0.0f,  0.0f, 0.25f,	// make this vertex red
		0.0f, 1.0f,  0.0f,  0.5f,	// make this vertex green
		0.0f, 0.0f,  1.0f, 0.75f,	// make this vertex blue
		1.0f, 1.0f,  0.0f,  1.0f,	// make this vertex yellow
	};
	
	// Perspective text
	mpText[kGLUTextNonPrespective] = GLU::TextCreateNonPerspective(CFSTR("The Quick Brown Fox\nJumps Over\nThe Lazy Dog!!"),
															   CFSTR("Courier"),
															   128.0f,
															   kCTLeftTextAlignment,
															   bounds,
															   position,
															   gradientColors2);
	
    // Set the swap interval
	GLint nSyncVR = GL_TRUE;
    
	[[self openGLContext] setValues:&nSyncVR
					   forParameter:NSOpenGLCPSwapInterval];
} // initOpenGL

// Determine OpenGL features, and write the results to the log
- (void) queryOpenGL
{
    NSLog(@">> Vendor   = %@",[self vendor]);
    NSLog(@">> Version  = %@",[self version]);
    NSLog(@">> Renderer = %@",[self renderer]);
    
    NSLog(@">> Extensions: Apple = %@",[self apple]);
    NSLog(@">> Extensions: ARB   = %@",[self arb]);
    NSLog(@">> Extensions: EXT   = %@",[self ext]);
} // queryOpenGL

// Initialize OpenGL
- (void) prepareOpenGL
{
	[super prepareOpenGL];
	
	[self initOpenGL];
    [self queryOpenGL];
} // prepareOpenGL

// When the view is resized
- (void) reshape
{
    [super reshape];
    
	// Get the text-view bounds
    NSRect bounds = [self bounds];
    
	// Get the bound's width and height
    GLsizei nWidth  = GLsizei(bounds.size.width);
    GLsizei nHeight = GLsizei(bounds.size.height);
	
    // Set the viewport to be the entire window
    glViewport(0, 0, nWidth, nHeight);

	// Update the linear transformation matrices
    GLU::TexSetPrespective(bounds, mpText[kGLUTextPrespective]);
    GLU::TextSetOrthographic(bounds, mpText[kGLUTextNonPrespective]);
} // reshape

// Switch to fullscreen
- (IBAction) toggleFullscreen:(id)sender
{
	mbFullscreen = !mbFullscreen;
	
    [self setFullscreen:mbFullscreen];
} // toggleFullscreen

// When a key is pressed
- (void) keyDown:(NSEvent *)pEvent
{
    if([[pEvent characters] length])
	{
        unichar nKey = [[pEvent characters] characterAtIndex:0];
		
		// [Esc] exits full-screen mode
		switch(nKey)
		{
			case GLKeyDownFullscreen:
                [self toggleFullscreen:self];
				break;
				
			case GLKeyDownTextNonPerspective:
				mnSelector = kGLUTextNonPrespective;
				break;
				
			case GLKeyDownTextPerspective:
			default:
				mnSelector = kGLUTextPrespective;
				break;
		} // switch
        
		[self setNeedsDisplay:YES];
	} // if
} // keyDown

// The mouse location in a window
- (NSPoint) mousePoint:(NSEvent *)pEvent
{
    NSPoint point = [pEvent locationInWindow];
    
    return [self convertPoint:point
					 fromView:nil];
} // mousePoint

// Left mouse button is pressed
- (void) mouseDown:(NSEvent *)pEvent
{
    if(pEvent)
    {
        m_MousePt = [self mousePoint:pEvent];
    } // if
} // mouseDown

// Right mouse button is pressed
- (void) rightMouseDown:(NSEvent *)pEvent
{
    if(pEvent)
    {
        m_MousePt = [self mousePoint:pEvent];
    } // if
} // rightMouseDown

// With the left mouse button down, mouse is dragged
- (void) mouseDragged:(NSEvent *)pEvent
{
    if(pEvent)
    {
        if([pEvent modifierFlags] & NSRightMouseDown)
        {
            [self rightMouseDragged:pEvent];
        } // if
        else
        {
            m_MousePt = [self mousePoint:pEvent];
            
            [self setNeedsDisplay:YES];
        } // else
    } // if
} // mouseDragged

// With the right mouse button down, mouse is dragged
- (void) rightMouseDragged:(NSEvent *)pEvent
{
    if(pEvent)
    {
		NSRect  bounds  = [self bounds];
        NSPoint mousePt = [self mousePoint:pEvent];
        GLfloat deltaY  = GLfloat(m_MousePt.y - mousePt.y);
        
		GLU::TextSetZoom(deltaY, mpText[kGLUTextPrespective]);
		GLU::TexSetPrespective(bounds, mpText[kGLUTextPrespective]);
        
        m_MousePt = mousePt;
        
        [self setNeedsDisplay:YES];
    } // if
} // rightMouseDragged

@end
