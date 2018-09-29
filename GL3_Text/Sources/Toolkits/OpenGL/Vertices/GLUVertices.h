/*
     File: GLUVertices.h
 Abstract: 
 OpenGL vertices representation private types.
 
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

#ifndef _GL_UTILITIES_VERTICES_H_
#define _GL_UTILITIES_VERTICES_H_

// STL container types
#import <vector>

// OpenGL Mac OS X
#import <OpenGL/OpenGL.h>

// SIMD Math OS X
#import <simd/simd.h>

#ifdef __cplusplus

namespace GLU
{
    // Vertex 2D class
    struct Vertex2D
    {
        vector_float2 m_Positions;
        vector_float2 m_Texcoords;
        vector_float4 m_Colors;
    }; // GLVertex2D
    
    typedef struct GLVertex2D GLVertex2D;
    
    // Vertex 3D class with positions, texture coordinates,
    // and colors
    struct Vertex3D_1
    {
        vector_float3 m_Positions;
        vector_float3 m_Texcoords;
        vector_float4 m_Colors;
    }; // GLVertex3D_1
    
    typedef struct GLVertex3D_1 GLVertex3D_1;
    
    // Vertex 3D class with positions, normals, texture coordinates,
    // and colors
    struct Vertex3D_2
    {
        vector_float3 m_Positions;
        vector_float3 m_Normals;
        vector_float3 m_Texcoords;
        vector_float4 m_Colors;
    }; // GLVertex3D
    
    typedef struct GLVertex3D_2 GLVertex3D_2;
    
    // Vertex 3D class with positions, texture coordinates, colors,
    // and with/without normals
    union Vertex3D
    {
        Vertex3D_1  m_v3D_1;
        Vertex3D_2  m_v3D_2;
    }; // GLVertex3D
    
    typedef union Vertex3D Vertex3D;
    
    // 2D or 3D vertex representation
    class Vertex
    {
    public:
        // 2D vertex constructor
        Vertex(vector_float2 const & rPositions,
               vector_float2 const & rTexcoords,
               vector_float4 const & rColors)
        {
            m_Vertex2D.m_Positions = rPositions;
            m_Vertex2D.m_Texcoords = rTexcoords;
            m_Vertex2D.m_Colors    = rColors;
        } // constructor
        
        // 3D vertex constructor without normals
        Vertex(vector_float3 const & rPositions,
               vector_float3 const & rTexcoords,
               vector_float4 const & rColors)
        {
            m_Vertex3D.m_v3D_1.m_Positions = rPositions;
            m_Vertex3D.m_v3D_1.m_Texcoords = rTexcoords;
            m_Vertex3D.m_v3D_1.m_Colors    = rColors;
        } // constructor
        
        // 3D vertex constructor with normals
        Vertex(vector_float3 const & rPositions,
               vector_float3 const & rNormals,
               vector_float3 const & rTexcoords,
               vector_float4 const & rColors)
        {
            m_Vertex3D.m_v3D_2.m_Positions = rPositions;
            m_Vertex3D.m_v3D_2.m_Normals   = rNormals;
            m_Vertex3D.m_v3D_2.m_Texcoords = rTexcoords;
            m_Vertex3D.m_v3D_2.m_Colors    = rColors;
        } // constructor
        
        union
        {
            Vertex2D m_Vertex2D;
            Vertex3D m_Vertex3D;
        }; // anonymous union
    }; // Vertex
    
    // Interleaved array, with either 2D or 3D vertices
    struct Array
    {
        GLuint mnDim;
        GLuint mnCount[4];
        
        std::vector<Vertex>  m_Vertices;
    }; // Array
    
    typedef struct Array Array;
} // GLU

#endif

#endif