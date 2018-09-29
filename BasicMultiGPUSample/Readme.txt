BasicMultiGPUSample

===================================================================================
DESCRIPTION:

This sample demonstrates what an OpenGL application should do to detect possible 
renderer changes. When running on a multi-GPU system, in order to render the OpenGL 
content correctly on all hardware, your application needs to be able to detect 
renderer changes. Whenever the virtual screen changes, the capabilities of the video 
card you are currently rendering to can change, so you must re-query those capabilities
(such as max texture size) and adjust your drawing paths as necessary to support 
the newly active GPU.

This sample demonstrates how to detect and respond to renderer changes in both 
an NSOpenGLView subclass and an NSView subclass. It also demonstrates how to enable 
the usage of offline renderers (renderers that are not connected to a display).

===================================================================================
PACKAGING LIST:

MyNSOpenGLView.h/.m
This is an NSOpenGLView subclass. Demonstrates how to detect and respond to 
renderer changes if you are using an NSOpenGLView subclass.

MyOpenGLView.h/.m
This is an NSView subclass. Demonstrates how to detect and respond to renderer 
changes if you are not using NSOpenGLView.

BoingRenderer.h/.m
This class handles the rendering of a Boing ball using Core Profile. This class 
does not contain code relevant to multi-GPU support.

===================================================================================
BUILD REQUIREMENTS:

OS X v10.9 or later

===================================================================================
RUNTIME REQUIREMENTS:

OS X v10.8 or later

===================================================================================
Copyright (C) 2013~2014 Apple Inc. All rights reserved.