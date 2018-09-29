/*
     File: MyOpenGLView.m
 Abstract: An NSView subclass (not an NSOpenGLView).
  Version: 1.3
 
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

#import "MyOpenGLView.h"
#import "BoingRenderer.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@interface MyOpenGLView()
{
    IBOutlet NSTextField *rendererNameField;
    IBOutlet NSTextField *videoRAMField;
    
    NSOpenGLPixelFormat *pixelFormat;
    NSOpenGLContext *openGLContext;
    
    GLint virtualScreen;
    BOOL enableMultisample;
    CVDisplayLinkRef displayLink;
    BoingRenderer *renderer;
}

@end

@implementation MyOpenGLView

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	// There is no autorelease pool when this method is called
	// because it will be called from a background thread
	// It's important to create one or you will leak objects
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self drawView];
	
	[pool release];
	return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(MyOpenGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (NSOpenGLContext*)openGLContext
{
    return openGLContext;
}

- (NSOpenGLPixelFormat*)pixelFormat
{
    return pixelFormat;
}

- (void)lockFocus
{
    // BUG Not called on Mojave
    [super lockFocus];
    
    if ([[self openGLContext] view] != self)
    {
        // Unlike NSOpenGLView, NSView does not export a -prepareOpenGL method to override.
        // We need to call it explicitly.
        [self prepareOpenGL];
        
        [[self openGLContext] setView:self];
    }
}

- (id)initWithFrame:(NSRect)frame
{
    // Any Macintosh system configuration that includes more GPUs than displays will have both online and offline GPUs.
    // Online GPUs are those that are connected to a display while offline GPUs are those that have no such output
    // hardware attached. In these configurations you may wish to take advantage of the offline hardware, or to be able
    // to start rendering on this hardware should a display be connected at a future date without having to reconfigure
    // and reupload all of your OpenGL content.
    //
    // To enable the usage of offline renderers, add NSOpenGLPFAAllowOfflineRenderers when using NSOpenGL or
    // kCGLPFAAllowOfflineRenderers when using CGL to the attribute list that you use to create your pixel format.
	NSOpenGLPixelFormatAttribute attribs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAAllowOfflineRenderers, // lets OpenGL know this context is offline renderer aware
		NSOpenGLPFAMultisample, 1,
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples, 4,
		NSOpenGLPFAColorSize, 32,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, // Core Profile is the future
		0
	};
    
	NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	if(!pf)
	{
		NSLog(@"Failed to create pixel format.");
        [self release];
        return nil;
	}
	
	self = [super initWithFrame:frame];
	if (self)
	{
        pixelFormat = [pf retain];
        openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
        
        enableMultisample = YES;
    }
    
    [pf release];
	
	return self;
}

- (void)initGL
{
	[[self openGLContext] makeCurrentContext];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint one = 1;
	[[self openGLContext] setValues:&one forParameter:NSOpenGLCPSwapInterval];
	
	if(enableMultisample)
		glEnable(GL_MULTISAMPLE);
}

-(void)setupDisplayLink
{
    // Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	// Activate the display link
	CVDisplayLinkStart(displayLink);
}

- (void)prepareOpenGL
{
    // Make the OpenGL context current and do some one-time initialization.
    [self initGL];

    // Create the CVDisplayLink for driving the rendering loop
    [self setupDisplayLink];
    
    // This is an NSView subclass, not an NSOpenGLView.
    // We need to register the following notifications to be able to detect renderer changes.
    
    // Add an observer to NSViewGlobalFrameDidChangeNotification, which is posted
    // whenever an NSView that has an attached NSSurface changes size or changes screens
    // (thus potentially changing graphics hardware drivers).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(surfaceNeedsUpdate:)
                                                 name:NSViewGlobalFrameDidChangeNotification
                                               object:self];
    
    // Also register for changes to the display configuation using Quartz Display Services
    CGDisplayRegisterReconfigurationCallback(MyDisplayReconfigurationCallBack, self);
}

- (void)update
{
    // Call -[NSOpenGLContext update] to let it handle screen selection after resize/move.
	[[self openGLContext] update];
    
    // A virtual screen change is detected
	if(virtualScreen != [[self openGLContext] currentVirtualScreen])
    {
        // Find the current renderer and update the UI.
		[self gpuChanged];
        
        // Add your additional handling here
        // Adapt to any changes in capabilities
        // (such as max texture size, extensions and hardware capabilities such as the amount of VRAM).
    }
}

- (void)surfaceNeedsUpdate:(NSNotification *)notification
{
    [self update];
}

// When displays are reconfigured this callback will be called. You can take this opportunity to do further
// processing or pass the notification on to an object for further handling.
void MyDisplayReconfigurationCallBack(CGDirectDisplayID display,
                                      CGDisplayChangeSummaryFlags flags,
                                      void *userInfo)
{
    if (flags & kCGDisplaySetModeFlag)
    {
        // In this example we've passed 'self' for the userInfo pointer,
        // so we can cast it to an appropriate object type and forward the message onwards.
        [((MyOpenGLView *)userInfo) update];
        
        // Display has been reconfigured.
        // Adapt to any changes in capabilities
        // (such as max texture size, extensions and hardware capabilities such as the amount of VRAM).
    }
}

- (void)gpuChanged
{
	virtualScreen = [[self openGLContext] currentVirtualScreen];
	
	// Since this may be called from outside the display loop, make sure
	// our context is current so the GL calls all work properly.
	[[self openGLContext] makeCurrentContext];
	
	// Update UI elements with current renderer name, etc.
	[rendererNameField setStringValue:[NSString stringWithCString:(const char *)
									   glGetString(GL_RENDERER) encoding:NSASCIIStringEncoding]];
	
	// Use the current virtual screen index to interrogate the pixel format
	// for its display mask and renderer id.
	GLint displayMask;
	GLint rendererID;
	[pixelFormat getValues:&displayMask forAttribute:NSOpenGLPFAScreenMask forVirtualScreen:virtualScreen];
	[pixelFormat getValues:&rendererID  forAttribute:NSOpenGLPFARendererID forVirtualScreen:virtualScreen];
	
	// The software renderer (for whatever reason) returns a display mask of all 0's rather than
	// all 1's, so we swap that out here so that CGLQueryRendererInfo will at least find the software
	// renderer.
	if(displayMask == 0)
		displayMask = 0xffffffff;
	
	// Get renderer info for all renderers that match the display mask.
	GLint i, nrend = 0;
	CGLRendererInfoObj rend;
	
	CGLQueryRendererInfo((GLuint)displayMask, &rend, &nrend);
	
	GLint videoMemory = 0;
	for(i = 0; i < nrend; i++)
	{
		GLint thisRenderer;
		
		CGLDescribeRenderer(rend, i, kCGLRPRendererID, &thisRenderer);
		
		// See if this is the one we want
		if(thisRenderer == rendererID)
			CGLDescribeRenderer(rend, i, kCGLRPVideoMemoryMegabytes, &videoMemory);
	}
	
	CGLDestroyRendererInfo(rend);
	
	// Update UI
	[videoRAMField setStringValue:[NSString stringWithFormat:@"%d MB", videoMemory]];
}

- (void)drawView
{
    [[self openGLContext] makeCurrentContext];
    
    // We draw on a secondary thread through the display link
	// Add a mutex around to avoid the threads from accessing the context simultaneously
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
	glViewport(0,0,[self bounds].size.width,[self bounds].size.height);
    
	glClearColor(0.675f,0.675f,0.675f,1.0f);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    if (!renderer) //first time drawing
    {
        // Create a BoingRenderer object which handles the rendering of a Boing ball.
        renderer = [[BoingRenderer alloc] init];
        
        // Delegate to the BoingRenderer object to create an Orthographic projection camera
        [renderer makeOrthographicForWidth:self.bounds.size.width height:self.bounds.size.height];
        
        // Update the text fields with the initial renderer info
        [self gpuChanged];
    }
    
    // Let the BoingRenderer object update the physics stuff
    [renderer update];
    
    // Delegate to the BoingRenderer object for drawing the boling ball
    [renderer render];
    
	[[self openGLContext] flushBuffer];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)dealloc
{
    // Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been released
	CVDisplayLinkStop(displayLink);
    
	CVDisplayLinkRelease(displayLink);
    
    // Destroy the GL context AFTER display link has been released
    [renderer release];
    [pixelFormat release];
    [openGLContext release];
    
    // Remove the registrations
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSViewGlobalFrameDidChangeNotification
                                                  object:self];
    
    CGDisplayRemoveReconfigurationCallback(MyDisplayReconfigurationCallBack, self);
    
    [super dealloc];
}

- (BOOL)isOpaque
{
	return YES;
}

@end
