/*
     File: GLUView.mm
 Abstract: 
 Applications's OpenGL base view.
 
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

// OpenGL core profile (3.2) features
#import "GLUQuery.h"

// Application view code
#import "GLUView.h"

#pragma mark -

// Private interfaces
@interface GLUView(Private)

- (void) render;

@end

#pragma mark -

@implementation GLUView
{
@private
    NSDictionary  *mpOptions;
    NSTimer       *mpTimer;
    GLU::QueryRef  mpQuery;
} // GLUView

// Draw the scene here
- (void) scene
{
    // Nothing to draw in the base class
} // scene

// Render the content
- (void) render
{
    [[self openGLContext] makeCurrentContext];
    {
        [self scene];
    }
    [[self openGLContext] flushBuffer];
} // render

// Tear-down objects
- (void) cleanup
{
    if(mpQuery != nullptr)
    {
        GLU::QueryDelete(mpQuery);
    } // if
    
    if(mpTimer)
    {
        [mpTimer invalidate];
        [mpTimer release];
    } // if
    
    if(mpOptions)
    {
        [mpOptions release];
    } // if
} // cleanup

// Dealloc or destructor
- (void) dealloc
{
    [self cleanup];
    
    [super dealloc];
} // dealloc

// Designated initializer
- (id) initWithFrame:(NSRect)frameRect
{
    NSOpenGLPixelFormatAttribute attribs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };
    
    NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
    
    self = [super initWithFrame:frameRect
                    pixelFormat:format];
    
    if(self)
    {
        // timer for the runloop
        mpTimer = [[NSTimer timerWithTimeInterval:1.0/60.0
                                           target:self
                                         selector:@selector(render)
                                         userInfo:self
                                          repeats:true] retain];
        
        if(mpTimer)
        {
            // Add timer to the runloop with common perferences
            [[NSRunLoop currentRunLoop] addTimer:mpTimer
                                         forMode:NSRunLoopCommonModes];
        } // if
        
        // Fullscreen dictionary options
        mpOptions  = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                  forKey:NSFullScreenModeSetting] retain];
        
        // Need a valid OpenGL context before initializing
        mpQuery = nullptr;
    } // if
    
    // Pixel format is not needed beyond this point
    if(format)
    {
        [format release];
    } // if
    
    // If not a valid context then exit the application
    if(![self openGLContext])
    {
        // Tear-down objects
        [self cleanup];
        
        // Error message
        NSLog(@">> ERROR: OpenGL view base - Not a valid OpenGL context. Exiting!");
        
        // Exit the app with status of -1
        exit(-1);
    } // if
    
    return self;
} // initWithFrame

// Initialize OpenGL
- (void) prepareOpenGL
{
    [super prepareOpenGL];
    
    // Query OpenGL for a feature set
    mpQuery = GLU::QueryCreate();
} // prepareOpenGL

- (void)lockFocus
{
    // BUG Not called on Mojave
    [super lockFocus];
}

- (BOOL) isOpaque
{
    return YES;
} // isOpaque

- (BOOL) acceptsFirstResponder
{
    return YES;
} // acceptsFirstResponder

- (BOOL) becomeFirstResponder
{
    return  YES;
} // becomeFirstResponder

- (BOOL) resignFirstResponder
{
    return YES;
} // resignFirstResponder

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
} // applicationShouldTerminateAfterLastWindowClosed

- (void) renewGState
{
    [super renewGState];
    
    [[self window] disableScreenUpdatesUntilFlush];
} // renewGState

// Enter and exit fullscreen mode
- (void) setFullscreen:(const BOOL)theMode
{
    if(theMode)
    {
        [self enterFullScreenMode:[NSScreen mainScreen]
                      withOptions:mpOptions];
    } // if
    else
    {
        [self exitFullScreenModeWithOptions:mpOptions];
        
        [[self window] makeFirstResponder:self];
    } // else
} // setFullscreen

// OpenGL vendor
- (NSString *) vendor
{
    return [NSString stringWithUTF8String:GLU::QueryStringGetVendor(mpQuery).c_str()];
} // vendor

// OpenGL version
- (NSString *) version
{
    return [NSString stringWithUTF8String:GLU::QueryStringGetVersion(mpQuery).c_str()];
} // version

// OpenGL renderer
- (NSString *) renderer
{
    return [NSString stringWithUTF8String:GLU::QueryStringGetRenderer(mpQuery).c_str()];
} // renderer

// OpenGL Apple features
- (NSArray *) apple
{
    return (NSArray *)GLU::QueryArrayGetApple(mpQuery);
} // apple

// OpenGL ARB features
- (NSArray *) arb
{
    return (NSArray *)GLU::QueryArrayGetARB(mpQuery);
} // arb

// OpenGL EXT features
- (NSArray *) ext
{
    return (NSArray *)GLU::QueryArrayGetEXT(mpQuery);
} // ext

@end
