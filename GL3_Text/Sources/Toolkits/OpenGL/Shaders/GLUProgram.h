/*
     File: GLUProgram.h
 Abstract: 
 GLSL shader utility toolkit.
 
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

// MacOS X

#ifndef _GL_UTILITIES_PROGRAM_H_
#define _GL_UTILITIES_PROGRAM_H_

// Mac OS X frameworks
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

// OpenGL container types
#import "GLUContainers.h"

#ifdef __cplusplus

namespace GLU
{
    // In a large scale system architecture, instead of exposing the data
    // structure, one would hide all the instance variables and instead
    // expose a single opaque data reference.  In this case our opaque data
    // reference is represented by a pointer to Query structure.  The
    // details of this data structure are hidden and only exposed in the
    // implementation file.  All subsequent methods then work with this
    // opaque data reference.
    typedef struct Program  *ProgramRef;
    
    // Compile vertex and fragment shaders
    ProgramRef ProgramCreate(const bool& bUseAsPath,
                             const String& rVertex,
                             const String& rFragment);
    
    // Compile vertex and fragment shaders, with/without optional
    // geometry shader
    ProgramRef ProgramCreate(const bool& bUseAsPath,
                             const String& rVertex,
                             const String& rFragment,
                             const String& rGeometry);
    
    // Compile vertex and fragment shaders
    ProgramRef ProgramCreate(const bool& bUseAsPath,
                             CFStringRef pVertex,
                             CFStringRef pFragment);
    
    // Compile vertex and fragment shaders, with/without optional
    // geometry shader
    ProgramRef ProgramCreate(const bool& bUseAsPath,
                             CFStringRef pVertex,
                             CFStringRef pFragment,
                             CFStringRef pGeometry);
    
    // Make a deep copy of the program object
    ProgramRef ProgramCreateCopy(ProgramRef pProgramSrc);
    
    // Delete all the program object and shaders
    void ProgramDelete(ProgramRef pProgram);
    
    // Add attribute locations using key-value vector pairs
    bool ProgramAddAttributes(const UInts    &rKeys,
                              const Strings  &rValues,
                              ProgramRef pProgram);
    
    // Add attribute locations using key-value array pairs
    bool ProgramAddAttributes(CFArrayRef pKeys,
                              CFArrayRef pValues,
                              ProgramRef pProgram);
    
    // Add attribute locations using a dictionary
    bool ProgramAddAttributes(CFDictionaryRef pLocations,
                              ProgramRef pProgram);
    
    // Add fragment locations using key-value vector pairs
    bool ProgramAddFragments(const UInts& rKeys,
                             const Strings& rValues,
                             ProgramRef pProgram);
    
    // Add fragment locations using key-value array pairs
    bool ProgramAddFragments(CFArrayRef pKeys,
                             CFArrayRef pValues,
                             ProgramRef pProgram);
    
    // Add fragment locations using a dictionary
    bool ProgramAddFragments(CFDictionaryRef pLocations,
                             ProgramRef pProgram);
    
    // Add geometry shader inputs
    bool ProgramAddInputs(const GLenum& nInputType,
                          const GLenum& nOutputType,
                          const GLuint& nVerticesOut,
                          ProgramRef pProgram);

    // Create a program object from shaders (that may include an
    // optional geometry shader)
    bool ProgramFinalize(ProgramRef pProgram);
    
    // Get the id associated with the program object
    GLuint ProgramGetHandle(ProgramRef pProgram);

    // Bind the program object
    bool ProgramBind(ProgramRef pProgram);
} // GLU

#endif

#endif
