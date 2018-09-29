/*
 File: lighting.fsh
 Abstract: A vertex shader for adding basic directional lighting. It 
 essentially implements the standard OpenGL ES 1.0 fixed-function 
 directional lighting model.
 Version: 1.0
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#version 150

in vec4 inVertex, inColor;
in vec3 inNormal;

out vec4 color;

uniform mat4 MVP, ModelView;
uniform mat3 ModelViewIT;
uniform vec3 lightDir;
uniform vec4 ambient, diffuse, specular;
uniform float shininess;

void main()
{
	// transform position to clip space
	gl_Position = MVP * inVertex;
    
	// transform position to eye space
	vec3 eyePosition = vec3(ModelView * inVertex);
    
	// transform normal to eye space (normalization skipped here: inNormal already normalized, matrix not scaled)
	vec3 eyeNormal = ModelViewIT * inNormal;
    
	// directional light ambient and diffuse contribution (lightDir alreay normalized)
	float NdotL = max(dot(eyeNormal, lightDir), 0.0);
	vec4 lightColor = ambient + diffuse * NdotL;
    
	if (NdotL > 0.0)
	{
		// half angle
		vec3 H = normalize(lightDir - normalize(eyePosition));
        
		// specular contribution
		float NdotH = max(dot(eyeNormal, H), 0.0);
		lightColor += specular * pow(NdotH, shininess);
	}
    
	// apply directional light color and saturate result
    // to match fixed function behavior
	color = min(inColor * lightColor, 1.0);
}
