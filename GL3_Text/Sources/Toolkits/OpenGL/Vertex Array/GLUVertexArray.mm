/*
     File: GLUVertexArray.mm
 Abstract: 
 Utility toolkit for vao management and generation.
 
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

// STL container types
#import <string>
#import <unordered_map>

// OpenGL core profile
#import <OpenGL/gl3.h>

// OpenGL vertices private type
#import "GLUVertices.h"

// OpenGL VAO header
#import "GLUVertexArray.h"

#pragma mark -
#pragma mark Private - Data Structures

namespace GLU
{
    // Name associated with an attribute or a binding point
    typedef std::string  Name;
    
    // Interleaved array
    struct VertexArray
    {
        GLuint mnVAO;
        GLuint mnBID;
        GLuint mnPID;
        GLuint mnCount;
        
        std::unordered_map<Name, GLuint>  m_Attributes;
    }; // GLUVertexArray
    
    typedef struct VertexArray  VertexArray;
} // GLU

#pragma mark -
#pragma mark Private - Utilities - Buffers

// Get a pointer into a buffer at an offset
static const GLchar *GLUBufferGetOffset(const GLsizeiptr nOffset)
{
    return((const GLchar *)nullptr + nOffset);
} // GLUBufferGetOffset

// Create a buffer
static GLuint GLUBufferCreate(const GLenum& rTarget,
                              const GLenum& rUsage,
                              const GLsizeiptr& rSize,
                              const GLfloat * const pArray)
{
    GLuint nBID = 0;
    
    glGenBuffers(1, &nBID);
    
    if(nBID)
    {
        glBindBuffer(rTarget, nBID);
        glBufferData(rTarget, rSize, pArray, rUsage);
        glBindBuffer(rTarget, 0);
    } // if
    
    return nBID;
} // GLUBufferCreate

#pragma mark -
#pragma mark Private - Utilities - Arrays

// Enable a generic vertex attribute
static BOOL GLUVertexAttributeArrayEnable(const GLint& rSize,
                                          const GLchar * const pName,
                                          const GLsizei& rStride,
                                          const GLvoid *pOffset,
                                          GLU::VertexArrayRef pVertexArray)
{
    BOOL bSuccess = pName != nullptr;
    
    if(bSuccess)
    {
        glUseProgram(pVertexArray->mnPID);
        
        const GLint nAttribLoc = glGetAttribLocation(pVertexArray->mnPID, pName);
        
        pVertexArray->m_Attributes[pName] = nAttribLoc;
        
        glVertexAttribPointer(nAttribLoc, rSize, GL_FLOAT, GL_FALSE, rStride, pOffset);
        glEnableVertexAttribArray(nAttribLoc);
    } // if
    
    return bSuccess;
} // GLUVertexAttributeArrayEnable

// Create an array buffer
static GLuint GLUArrayBufferCreate(const GLuint& rCount,
                                   const GLuint& rSPP,
                                   const GLfloat * const pArray)
{
    GLsizeiptr nSize = rSPP * rCount;
    
    return GLUBufferCreate(GL_ARRAY_BUFFER, GL_STATIC_DRAW, nSize, pArray);
} // GLUArrayBufferCreate

// Bind an array buffer
static void GLUArrayBufferBind(const GLuint nBID)
{
    glBindBuffer(GL_ARRAY_BUFFER,nBID);
} // GLUArrayBufferCreate

#pragma mark -
#pragma mark Private - Utilities - Vertices

// Get a float array from a STL vector representing a 2D object
static const GLfloat * GLUArrayGetPointer(const GLU::ArrayRef pArray)
{
    return((const GLfloat *)&pArray->m_Vertices[0]);
} // GLUArrayGetPointer

#pragma mark -
#pragma mark Private - Utilities - Vertex Array

// Create a buffer for vertices of a triangle fan
static void GLUVertexArrayEnable(const GLchar * const pPosition,
                                 const GLchar * const pTexCoord,
                                 const GLchar * const pColor,
                                 const GLU::ArrayRef pArray,
                                 GLU::VertexArrayRef pVertexArray)
{
    GLsizei nStride = sizeof(GLU::Vertex);
    
    pVertexArray->mnBID = GLUArrayBufferCreate(pVertexArray->mnCount, nStride, GLUArrayGetPointer(pArray));
    
    GLsizeiptr nOffsetTexCoord = sizeof(vector_float2);
    GLsizeiptr nOffsetColor    = 2 * nOffsetTexCoord;
    
    GLUArrayBufferBind(pVertexArray->mnBID);
    
    if(pPosition != nullptr)
    {
        GLUVertexAttributeArrayEnable(2, pPosition, nStride, GLUBufferGetOffset(0), pVertexArray);
    } // if
    
    if(pTexCoord != nullptr)
    {
        GLUVertexAttributeArrayEnable(2, pTexCoord, nStride, GLUBufferGetOffset(nOffsetTexCoord), pVertexArray);
    } // if
    
    if(pColor != nullptr)
    {
        GLUVertexAttributeArrayEnable(4, pColor, nStride, GLUBufferGetOffset(nOffsetColor), pVertexArray);
    } // if
} // GLUVertexArrayEnable

// Create a buffer for vertices of a triangle fan
static void GLUVertexArrayEnable(const GLchar * const pPosition,
                                 const GLchar * const pNormal,
                                 const GLchar * const pTexCoord,
                                 const GLchar * const pColor,
                                 const GLU::ArrayRef pArray,
                                 GLU::VertexArrayRef pVertexArray)
{
    GLsizei nStride = sizeof(GLU::Vertex);
    
    pVertexArray->mnBID = GLUArrayBufferCreate(pVertexArray->mnCount, nStride, GLUArrayGetPointer(pArray));
    
    GLsizeiptr nOffsetNormals  = sizeof(vector_float3);
    GLsizeiptr nOffsetTexCoord = 2 * nOffsetNormals;
    GLsizeiptr nOffsetColor    = 3 * nOffsetNormals;
    
    GLUArrayBufferBind(pVertexArray->mnBID);
    
    if(pPosition != nullptr)
    {
        GLUVertexAttributeArrayEnable(3, pPosition, nStride, GLUBufferGetOffset(0), pVertexArray);
    } // if
    
    if(pNormal != nullptr)
    {
        GLUVertexAttributeArrayEnable(3, pNormal, nStride, GLUBufferGetOffset(nOffsetNormals), pVertexArray);
    } // if
    
    if(pTexCoord != nullptr)
    {
        GLUVertexAttributeArrayEnable(3, pTexCoord, nStride, GLUBufferGetOffset(nOffsetTexCoord), pVertexArray);
    } // if
    
    if(pColor != nullptr)
    {
        GLUVertexAttributeArrayEnable(4, pColor, nStride, GLUBufferGetOffset(nOffsetColor), pVertexArray);
    } // if
} // GLUVertexArrayEnable

// Get the cached attribute location
static GLuint GLUVertexArrayGetAttribute(const GLU::Name &rName,
                                         GLU::VertexArrayRef pVertexArray)
{
    return pVertexArray->m_Attributes[rName];
} // GLUVertexArrayGetLocation

#pragma mark -
#pragma mark Public - Constructors

// Create a vao, representing a 2D object, using vertices, colors,
// and texture coordinates
GLU::VertexArrayRef GLU::VertexArrayCreate(const GLuint& rProgramID,
                                           const GLuint& rCount,
                                           const GLchar * const pPosition,
                                           const GLchar * const pTexCoord,
                                           const GLchar * const pColor,
                                           const GLU::ArrayRef pArray)
{
    GLU::VertexArrayRef pVertexArray = nullptr;
    
    if(rProgramID && pArray)
    {
        try
        {
            pVertexArray = new GLU::VertexArray;
            
            pVertexArray->mnPID   = rProgramID;
            pVertexArray->mnCount = rCount;
            
            glGenVertexArrays(1, &pVertexArray->mnVAO);
            
            if(pVertexArray->mnVAO)
            {
                glBindVertexArray(pVertexArray->mnVAO);
                
                GLUVertexArrayEnable(pPosition,
                                     pTexCoord,
                                     pColor,
                                     pArray,
                                     pVertexArray);
            } // if
        } // try
        catch(std::bad_alloc& ba)
        {
            NSLog(@">> ERROR: Failed allocating memory for CF mutable dictionary backing store: \"%s\"", ba.what());
        } // catch
    } // if
    
    return pVertexArray;
} // GLUVertexArrayCreate

// Create a vao, representing a 3D object, using vertices, normals,
// colors, and texture coordinates
GLU::VertexArrayRef GLU::VertexArrayCreate(const GLuint& rProgramID,
                                           const GLuint& rCount,
                                           const GLchar * const pPosition,
                                           const GLchar * const pNormal,
                                           const GLchar * const pTexCoord,
                                           const GLchar * const pColor,
                                           const GLU::ArrayRef pArray)
{
    GLU::VertexArrayRef pVertexArray = nullptr;
    
    if(rProgramID && pArray)
    {
        try
        {
            pVertexArray = new GLU::VertexArray;
            
            pVertexArray->mnPID   = rProgramID;
            pVertexArray->mnCount = rCount;
            
            glGenVertexArrays(1, &pVertexArray->mnVAO);
            
            if(pVertexArray->mnVAO)
            {
                glBindVertexArray(pVertexArray->mnVAO);
                
                GLUVertexArrayEnable(pPosition,
                                     pNormal,
                                     pTexCoord,
                                     pColor,
                                     pArray,
                                     pVertexArray);
            } // if
        } // try
        catch(std::bad_alloc& ba)
        {
            NSLog(@">> ERROR: Failed allocating memory for vertex array backing store: \"%s\"", ba.what());
            
            return;
        } // catch
    } // if
    
    return pVertexArray;
} // GLUVertexArrayCreate

#pragma mark -
#pragma mark Public - Destructor

// Delete the VAO opaque data reference
void GLU::VertexArrayDelete(GLU::VertexArrayRef pVertexArray)
{
    if(pVertexArray != nullptr)
    {
        pVertexArray->m_Attributes.clear();
        
        glDeleteBuffers(1, &pVertexArray->mnBID);
        glDeleteVertexArrays(1, &pVertexArray->mnVAO);
        
        delete pVertexArray;
    } // if
} // GLUVertexArrayDelete

#pragma mark -
#pragma mark Public - Accessors

// Get VBO id
const GLuint GLU::VertexArrayGetBuffer(const GLU::VertexArrayRef pVertexArray)
{
    return pVertexArray->mnBID;
} // GLUVertexArrayGetBuffer

// Get VAO id
const GLuint GLU::VertexArrayGetVAO(const GLU::VertexArrayRef pVertexArray)
{
    return pVertexArray->mnVAO;
} // GLUVertexArrayGetVAO

// Get the named attribute location
const GLuint GLU::VertexArrayGetLocation(const GLchar * const pName,
                                         const GLU::VertexArrayRef pVertexArray)
{
    return GLUVertexArrayGetAttribute(pName, pVertexArray);
} // GLUVertexArrayGetLocation

// Create VAO representing a quad
GLU::VertexArrayRef GLU::VertexArrayCreateQuad(const GLuint& rProgramID,
                                               const GLchar  * const pVertex,
                                               const GLchar  * const pColor,
                                               const GLfloat * const pColors,
                                               const GLchar  * const pTexCoords)
{
    GLU::VertexArrayRef pVertexArray = nullptr;
    
    GLU::ArrayRef pVertices = GLU::ArrayCreateQuad(nullptr, nullptr, pColors);
    
    if(pVertices != nullptr)
    {
        pVertexArray = GLU::VertexArrayCreate(rProgramID,
                                              4,
                                              pVertex,
                                              pTexCoords,
                                              pColor,
                                              pVertices);
        
        GLU::ArrayDelete(pVertices);
    } // if
    
    return pVertexArray;
} // GLUVertexArrayCreateQuad

// Create VAO representing a quad
GLU::VertexArrayRef GLU::VertexArrayCreateQuad(const GLuint& rProgramID,
                                               const GLchar  * const pColor,
                                               const GLfloat * const pColors,
                                               const GLchar  * const pTexCoords)
{
    GLU::VertexArrayRef pVertexArray = nullptr;
    
    GLU::ArrayRef pVertices = GLU::ArrayCreateQuad(nullptr, nullptr, pColors);
    
    if(pVertices != nullptr)
    {
        pVertexArray = GLU::VertexArrayCreate(rProgramID,
                                              4,
                                              nullptr,
                                              pTexCoords,
                                              pColor,
                                              pVertices);
        
        GLU::ArrayDelete(pVertices);
    } // if
    
    return pVertexArray;
} // GLUVertexArrayCreateQuad
