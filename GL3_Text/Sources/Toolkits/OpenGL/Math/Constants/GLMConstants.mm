/*
     File: GLMConstants.mm
 Abstract: 
 OpenGL numeric constants.
 
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

#import <cmath>

#import "GLMConstants.h"

GLfloat GLM::kPi_f       = GLfloat(M_PI);
GLfloat GLM::kTwoPi_f    = 2.0f * GLM::kPi_f;
GLfloat GLM::kHalfPi_f   = 0.5f * GLM::kPi_f;
GLfloat GLM::kPiDiv4_f   = 0.25f * GLM::kPi_f;
GLfloat GLM::kPiDiv6_f   = GLM::kPi_f / 6.0f;
GLfloat GLM::k3PiDiv4_f  = (3.0f * GLM::kPi_f) / 4.0f;
GLfloat GLM::k4PiDiv3_f  = (4.0f * GLM::kPi_f) / 3.0f;
GLfloat GLM::k180DivPi_f = 180.0f / GLM::kPi_f;
GLfloat GLM::kPiDiv180_f = GLM::kPi_f / 180.0f;
GLfloat GLM::k360DivPi_f = 360.0f / GLM::kPi_f;
GLfloat GLM::kPiDiv360_f = GLM::kPi_f / 360.0f;
GLfloat GLM::kRadians_f  = GLM::kPi_f / 180.0f;

GLdouble GLM::kPi_d       = GLdouble(M_PI);
GLdouble GLM::kTwoPi_d    = 2.0f * GLM::kPi_d;
GLdouble GLM::kHalfPi_d   = 0.5f * GLM::kPi_d;
GLdouble GLM::kPiDiv4_d   = 0.25f * GLM::kPi_d;
GLdouble GLM::kPiDiv6_d   = GLM::kPi_d / 6.0f;
GLdouble GLM::k3PiDiv4_d  = (3.0f * GLM::kPi_d) / 4.0f;
GLdouble GLM::k4PiDiv3_d  = (4.0f * GLM::kPi_d) / 3.0f;
GLdouble GLM::k180DivPi_d = 180.0f / GLM::kPi_d;
GLdouble GLM::kPiDiv180_d = GLM::kPi_d / 180.0f;
GLdouble GLM::k360DivPi_d = 360.0f / GLM::kPi_d;
GLdouble GLM::kPiDiv360_d = GLM::kPi_d / 360.0f;
GLdouble GLM::kRadians_d  = GLM::kPi_d / 180.0;
