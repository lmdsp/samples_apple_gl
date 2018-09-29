/*
     File: GLUText.mm
 Abstract: 
 Utility toolkit for generating an OpenGL text from a string reference.
 
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

// OpenGL core profile
#import <OpenGL/gl3.h>

// Constants
#import "GLMConstants.h"

// OpenGL math utilities
#import "GLMTransforms.h"

// OpenGL utilities header
#import "GLUProgram.h"
#import "GLUTexture.h"
#import "GLUVertexArray.h"

// OpenGL text header
#import "GLUText.h"

#pragma mark -
#pragma mark Private - Data Structures

namespace GLU
{
    struct TextUniforms
    {
        GLuint	mnSampler2D;	// Sampler 2D for a texture
        GLuint  mnMVP;			// Model-view-Projection uniform
    }; // TextUniforms
    
    typedef struct TextUniforms  TextUniforms;
    
    union TextTransform
    {
        vector_float4 m_Ortho2D;	// Orthographic 2D vector transform
        
        struct
        {
            GLfloat          mnZoom;		// Zooming within a viewport
            GLfloat          mnFovy;		// Field-of-view within a viewport
            matrix_float4x4  m_ModelView;	// Model-view transformation matrix for perspective correct text
        };
    }; // TextTransform
    
    typedef union TextTransform  TextTransform;
    
    struct TextProgram
    {
        GLuint        mnPID;		// Program object ID
        GLuint        mnVAO;		// VAO id
        TextUniforms  m_UID;		// Uniform IDs
        ProgramRef    mpProgram;    // Program object encapsulating shaders
    }; // Program
    
    typedef struct TextProgram  TextProgram;
    
    struct Text
    {
        GLuint			mnTID;          // Texture ID
        GLenum          mnFactor[2];    // Blend function source factor
        NSPoint         m_Position;		// Text position
        NSSize          m_Size;			// Bounding rectangle limits
        NSRect          m_Bounds;		// Text view bounds
        TextTransform   m_Transform;	// Transformations
        TextProgram     m_Program;		// Program Object
        VertexArrayRef  mpVertices;     // VAO encapsulation
    }; // Text
    
    typedef struct Text  Text;
    
    static const simd::float3 kDefaultEye    = {0.0f, 0.0f, 2.0f};
    static const simd::float3 kDefaultCenter = {0.0f, 0.0f, 0.0f};
    static const simd::float3 kDefaultUp     = {0.0f, 1.0f, 0.0f};
    
    // Default model-view look at perspective linear transformation
    static const simd::float4x4 kDefaultModelView = GLM::lookAt(GLU::kDefaultEye, GLU::kDefaultCenter, GLU::kDefaultUp);
} // GLU

#pragma mark -
#pragma mark Private - Utilities - Texture

// Generate texture from context's bitmap
static bool GLUTextCreateTexture2D(const GLchar * const pString,
                                   const GLchar * const pFontName,
                                   const CGFloat& rFontSize,
                                   const CTTextAlignment& rAlignment,
                                   GLU::TextRef pText)
{
    CGFloat color[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    
    pText->mnTID = GLU::Texture2DCreateFromString(pString,
                                                  pFontName,
                                                  rFontSize,
                                                  rAlignment,
                                                  color,
                                                  pText->m_Size);
    
    return bool(pText->mnTID);
} // GLUTextCreateTexture2D

// Generate texture from context's bitmap
static bool GLUTextCreateTexture2D(const GLU::String& rString,
                                   const GLU::String& rFontName,
                                   const CGFloat& rFontSize,
                                   const CTTextAlignment& rAlignment,
                                   GLU::TextRef pText)
{
    CGFloat color[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    
    pText->mnTID = GLU::Texture2DCreateFromString(rString,
                                                  rFontName,
                                                  rFontSize,
                                                  rAlignment,
                                                  color,
                                                  pText->m_Size);
    
    return bool(pText->mnTID);
} // GLUTextCreateTexture2D

// Generate texture from context's bitmap
static bool GLUTextCreateTexture2D(CFStringRef pString,
                                   CFStringRef pFontName,
                                   const CGFloat& rFontSize,
                                   const CTTextAlignment& rAlignment,
                                   GLU::TextRef pText)
{
    CGFloat color[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    
    pText->mnTID = GLU::Texture2DCreateFromString(pString,
                                                  pFontName,
                                                  rFontSize,
                                                  rAlignment,
                                                  color,
                                                  pText->m_Size);
    
    return bool(pText->mnTID);
} // GLUTextCreateTexture2D

// Generate texture from context's bitmap
static bool GLUTextCreateTexture2D(CFAttributedStringRef pAttrString,
                                   GLU::TextRef pText)
{
    CFRange range = CFRangeMake(0, CFAttributedStringGetLength(pAttrString));
    
    pText->mnTID = GLU::Texture2DCreateFromString(pAttrString,
                                                  range,
                                                  pText->m_Size);
    
    return bool(pText->mnTID);
} // GLUTextCreateTexture2D

#pragma mark -
#pragma mark Private - Utilities - Quad

// Create a quad for perspective text
static void GLUTextQuadCreatePerspective(const GLchar * const pVertex,
                                         const GLchar * const pColor,
                                         const GLfloat * const pColors,
                                         const GLchar * const pTexCoords,
                                         GLU::TextRef pText)
{
    pText->mpVertices = GLU::VertexArrayCreateQuad(pText->m_Program.mnPID,
                                                   pVertex,
                                                   pColor,
                                                   pColors,
                                                   pTexCoords);
    
    if(pText->mpVertices != nullptr)
    {
        pText->m_Program.mnVAO = GLU::VertexArrayGetVAO(pText->mpVertices);
    } // if
} // GLUTextQuadCreatePerspective

// Create a quad for non-perspective text
static void GLUTextQuadCreateNonPerspective(const GLchar * const pColor,
                                            const GLfloat * const pColors,
                                            const GLchar * const pTexCoords,
                                            GLU::TextRef pText)
{
    pText->mpVertices = GLU::VertexArrayCreateQuad(pText->m_Program.mnPID,
                                                   pColor,
                                                   pColors,
                                                   pTexCoords);
    
    if(pText->mpVertices != nullptr)
    {
        pText->m_Program.mnVAO = GLU::VertexArrayGetVAO(pText->mpVertices);
    } // if
} // GLUTextQuadCreateNonPerspective

#pragma mark -
#pragma mark Private - Utilities - Bounds

// Set the text view bounds
static bool GLUTextSetBounds(const NSRect &rBounds,
                             GLU::TextRef pText)
{
    pText->m_Bounds = rBounds;
    
    return !NSEqualRects(rBounds, pText->m_Bounds);
} // GLUTextSetBounds

#pragma mark -
#pragma mark Private - Utilities - Transformations

// Calculate the orthographic 2D linear transformation
static vector_float4 GLUTextTransformCreateOrtho2D(const NSRect& rBounds,
                                                   GLU::TextRef pText)
{
    // Set the text-view bounds
    GLUTextSetBounds(rBounds, pText);
    
    // Compute the orthographic 2D linear transformation
    GLfloat x = 2.0f / pText->m_Bounds.size.width;
    GLfloat y = 2.0f / pText->m_Bounds.size.height;
    
    vector_float4 v;
    
    v.x = pText->m_Size.width  * x;
    v.y = pText->m_Size.height * y;
    v.z = pText->m_Position.x  * x - 1.0f;
    v.w = pText->m_Position.y  * y - 1.0f;
    
    return v;
} // GLUTextTransformCreateOrtho2D

// Compute a linear transformation with a frustum
static matrix_float4x4 GLUTextTransformCreateMVP(const NSRect& rBounds,
                                                 GLU::TextRef pText)
{
    // Set the text-view bounds
    GLUTextSetBounds(rBounds, pText);
    
    // For computing the mvp linear transformation
    GLfloat nAspect =  GLfloat(pText->m_Bounds.size.width / pText->m_Bounds.size.height);
    GLfloat nRight  =  pText->m_Transform.mnZoom;
    GLfloat nLeft   = -nRight;
    GLfloat nTop    =  pText->m_Transform.mnZoom;
    GLfloat nBottom = -nTop;
    
    if(nAspect < 1.0f)
    {
        // window taller than wide
        nBottom /= nAspect;
        nTop    /= nAspect;
    } // if
    else
    {
        nLeft  *= nAspect;
        nRight *= nAspect;
    } // else
    
    // compute the projection linear transformation
    simd::float4x4 projection = GLM::frustum(nLeft, nRight, nBottom, nTop, 1.0f, 100.0f);
    
    // Create a MVP linear transformation using a frustum
    return pText->m_Transform.m_ModelView * projection;
} // GLUTextTransformCreateMVP

// Compute the model-view-projection linear transformation
static matrix_float4x4 GLUTextTransformCreateMVP(const NSRect& rBounds,
                                                 const vector_float3& rTranslate,
                                                 const vector_float4& rRotate,
                                                 GLU::TextRef pText)
{
    // Set the text-view bounds
    GLUTextSetBounds(rBounds, pText);
    
    // Compute the aspect ratio
    GLfloat nAspect = GLfloat(pText->m_Bounds.size.width  / pText->m_Bounds.size.height);
    GLfloat nFactor = 1.0f / nAspect;
    
    // Scale
    simd::float3 scale = 0.0f;
    
    scale.x = nFactor * pText->m_Size.width / pText->m_Size.height;
    scale.y = nFactor;
    scale.z = nFactor;
    
    // Compute the model-view linear transformation
    simd::float4x4 modelView = GLM::scale(scale) * GLU::kDefaultModelView;
    
    modelView = GLM::rotate(rRotate) * modelView;
    modelView = GLM::translate(rTranslate) * modelView;
    
    // Set the model-view matrix
    pText->m_Transform.m_ModelView = modelView;
    
    // Compute the prespective projection transformation
    simd::float4x4 perspective = GLM::perspective(pText->m_Transform.mnFovy, nAspect, 1.0f, 100.0f);
    
    // Compute a linear transformation with a prespective projection
    return pText->m_Transform.m_ModelView * perspective;
} // GLUTextTransformCreateMVP

#pragma mark -
#pragma mark Private - Utilities - Uniforms

// Enable the uniform assocated with a model-view-projection linear transformation
static void GLUTextUniformEnableMVP(const GLchar * pName,
                                    const NSRect& rBounds,
                                    const vector_float3& rTranslate,
                                    const vector_float4& rRotate,
                                    GLU::TextRef pText)
{
    // Compute the model-view-projection linear transformation
    matrix_float4x4 mvp = GLUTextTransformCreateMVP(rBounds, rTranslate, rRotate, pText);
    
    // Enable the program object
    glUseProgram(pText->m_Program.mnPID);
    
    // Cache the uniform location
    pText->m_Program.m_UID.mnMVP = glGetUniformLocation(pText->m_Program.mnPID, pName);
    
    // Update the mvp linear transformation
    GLM::uniform(pText->m_Program.m_UID.mnMVP, false, mvp);
} // GLUTextUniformEnableMVP

// Enable the uniform assocated with a orthographic 2D transformation
static void GLUTextUniformEnableOrtho2D(const GLchar * const pName,
                                        const NSRect& rBounds,
                                        GLU::TextRef pText)
{
    // Calculate the orthographic 2D linear transformation
    pText->m_Transform.m_Ortho2D = GLUTextTransformCreateOrtho2D(rBounds, pText);
    
    // Enable the program object
    glUseProgram(pText->m_Program.mnPID);
    
    // Cache the uniform location
    pText->m_Program.m_UID.mnMVP = glGetUniformLocation(pText->m_Program.mnPID, pName);
    
    // Set the orthographic 2D linear transformation
    glUniform4f(pText->m_Program.m_UID.mnMVP,
                pText->m_Transform.m_Ortho2D.x,
                pText->m_Transform.m_Ortho2D.y,
                pText->m_Transform.m_Ortho2D.z,
                pText->m_Transform.m_Ortho2D.w);
} // GLUTextUniformEnableOrtho2D

// Enable the sampler 2D uniform assocated with a texture
static void GLUTextUniformEnableSampler2D(const GLchar * const pName,
                                          GLU::TextRef pText)
{
    // Use the program object
    glUseProgram(pText->m_Program.mnPID);
    
    // Cache the sampler 2D uniform location
    pText->m_Program.m_UID.mnSampler2D = glGetUniformLocation(pText->m_Program.mnPID, pName);
    
    // 0 for GL_TEXTURE0
    glUniform1i(pText->m_Program.m_UID.mnSampler2D, 0);
} // GLUTextUniformEnableSampler2D

#pragma mark -
#pragma mark Private - Utilities - Defaults

static void GLUTextSetDefaults(GLU::TextRef pText)
{
    // Clear the sturcture
    std::memset(pText, 0x0, sizeof(GLU::Text));
    
    // Blend function source factor
    pText->mnFactor[0] = GL_SRC_ALPHA;
    
    // Blend function destination factor
    pText->mnFactor[1] = GL_ONE;
} // GLUTextSetDefaults

#pragma mark -
#pragma mark Private - Utilities - Acquire

static bool GLUTextAcquirePerspectiveProgram(GLU::TextRef pText)
{
    // Default vertex and fragment shaders
    const GLchar *kShaders[2] =
    {
        // Vertex shader
        "#version 150\n"
        "uniform mat4 mvp;\n"
        "in vec2 position;\n"
        "in vec2 texCoords;\n"
        "in vec4 colors;\n"
        "out block\n"
        "{\n"
        "    vec2 texCoords;\n"
        "    vec4 colors;\n"
        "} outData;\n"
        "void main()\n"
        "{\n"
        "   outData.colors    = colors;\n"
        "	outData.texCoords = texCoords;\n"
        "	gl_Position = mvp * vec4(position,0.0,1.0);\n"
        "}\n",
        
        // Fragment shader
        "#version 150\n"
        "uniform sampler2D tex;\n"
        "in block\n"
        "{\n"
        "	vec4 colors;\n"
        "	vec2 texCoords;\n"
        "} inData;\n"
        "out vec4 fragColor;\n"
        "void main()\n"
        "{\n"
        "   vec4 tex2D = texture(tex, inData.texCoords);\n"
        "	fragColor = tex2D * inData.colors;\n"
        "}\n"
    };
    
    // Create a program object from shaders, attributes and fragment data
    pText->m_Program.mpProgram = GLU::ProgramCreate(false, kShaders[0], kShaders[1]);
    
    bool bSuccess = pText->m_Program.mpProgram != nullptr;
    
    if(bSuccess)
    {
        // Create attributes associative array
        GLU::UInts   vAttribKeys = {0, 1, 2};
        GLU::Strings vAttribVals = {"position", "texCoords", "colors"};
        
        GLU::ProgramAddAttributes(vAttribKeys, vAttribVals, pText->m_Program.mpProgram);
        
        // Create fragment data associative array
        GLU::UInts   vColorKeys = { 0 };
        GLU::Strings vColorVals = { "fragColor" };
        
        GLU::ProgramAddFragments(vColorKeys, vColorVals, pText->m_Program.mpProgram);
        
        // Compile and link the shaders
        bSuccess = GLU::ProgramFinalize(pText->m_Program.mpProgram);
        
        // Get the program object ID
        pText->m_Program.mnPID = GLU::ProgramGetHandle(pText->m_Program.mpProgram);
    } // if
    
    return bSuccess;
} // GLUTextAcquirePerspectiveProgram

// Acquire a program object, shaders, vao, and buffers for a perspective text
static bool GLUTextAcquirePerspective(const NSRect& rBounds,
                                      const GLfloat * const pColors,
                                      GLU::TextRef pText)
{
    bool bSuccess = GLUTextAcquirePerspectiveProgram(pText);
    
    if(bSuccess)
    {
        // Initial zoom value
        pText->m_Transform.mnZoom = 0.5f;
        
        // Initial field-of-view 45 degreess
        pText->m_Transform.mnFovy = GLM::kPiDiv4_f;
        
        // Rotation parameters are { x, y, z, θ }
        const vector_float4 rotate = {0.0f, 0.0f, 1.0f, 0.0f};
        
        // Translation in the rectangular Cartesian coordinatines
        const vector_float3 translate = {0.0f, 0.0f, 0.5f};
        
        // Enable th model-view-projection matrix
        GLUTextUniformEnableMVP("mvp", rBounds, translate, rotate, pText);
        
        // Enable the sampler 2D
        GLUTextUniformEnableSampler2D("tex", pText);
        
        // Create a triangle fan
        GLUTextQuadCreatePerspective("position", "colors", pColors, "texCoords", pText);
    } // if
    
    return bSuccess;
} // GLUTextAcquirePerspective

static bool GLUTextAcquireNonPerspectiveProgram(GLU::TextRef pText)
{
    // create HUD vertex and fragment shader sources
    const GLchar *kShaders[2] =
    {
        // Vertex Shader
        "#version 150\n"
        "uniform vec4 ortho;\n"
        "in vec4 colors;\n"
        "in vec2 positions;\n"
        "out block\n"
        "{\n"
        "    vec4 colors;\n"
        "    vec2 texCoords;\n"
        "} outData;\n"
        "void main()\n"
        "{\n"
        "   outData.colors    = colors;\n"
        "	outData.texCoords = positions;\n"
        "	gl_Position = vec4(positions * ortho.xy + ortho.zw, 0.0, 1.0);\n"
        "}\n",
        
        // Fragment Shader
        "#version 150\n"
        "uniform sampler2D tex;\n"
        "in block\n"
        "{\n"
        "	vec4 colors;\n"
        "	vec2 texCoords;\n"
        "} inData;\n"
        "out vec4 fragColor;\n"
        "void main()\n"
        "{\n"
        "   vec4 tex2D = texture(tex, inData.texCoords);\n"
        "	fragColor = tex2D * inData.colors;\n"
        "}\n"
    };
    
    // Create a program object from shaders, attributes and fragment data
    pText->m_Program.mpProgram = GLU::ProgramCreate(false, kShaders[0], kShaders[1]);
    
    bool bSuccess = pText->m_Program.mpProgram != nullptr;
    
    if(bSuccess)
    {
        // Create attributes associative array
        GLU::UInts   vAttribKeys = { 3, 4 };
        GLU::Strings vAttribVals = { "positions", "colors" };
        
        GLU::ProgramAddAttributes(vAttribKeys, vAttribVals, pText->m_Program.mpProgram);
        
        // Create fragment data associative array
        GLU::UInts   vColorKeys = { 0 };
        GLU::Strings vColorVals = { "fragColor" };
        
        GLU::ProgramAddFragments(vColorKeys, vColorVals, pText->m_Program.mpProgram);
        
        // Compile and link the shaders
        bSuccess = GLU::ProgramFinalize(pText->m_Program.mpProgram);
        
        // Get the program object ID
        pText->m_Program.mnPID = GLU::ProgramGetHandle(pText->m_Program.mpProgram);
    } // if
    
    return bSuccess;
} // GLUTextAcquireNonPerspectiveProgram

// Acquire a program object, shaders, vao, and buffers for a nonperspective text
static bool GLUTextAcquireNonPerspective(const NSRect& rBounds,
                                         const NSPoint& rPosition,
                                         const GLfloat * const pColors,
                                         GLU::TextRef pText)
{
    bool bSuccess = GLUTextAcquireNonPerspectiveProgram(pText);
    
    if(bSuccess)
    {
        // Set text position within a view
        pText->m_Position = rPosition;
        
        // Enable the uniforms
        GLUTextUniformEnableOrtho2D("ortho", rBounds, pText);
        
        // Enable sampler 2D
        GLUTextUniformEnableSampler2D("tex", pText);
        
        // Create a triangle fan
        GLUTextQuadCreateNonPerspective("colors", pColors, "positions", pText);
    } // if
    
    return bSuccess;
} // GLUTextAcquireNonPerspective

#pragma mark -
#pragma mark Private - Utilities - Blending

static bool GLUTextCheckBlending(const GLenum& nFactor)
{
    bool bSuccess = false;
    
    switch(nFactor)
    {
        case GL_ZERO:
        case GL_ONE:
        case GL_SRC_COLOR:
        case GL_ONE_MINUS_SRC_COLOR:
        case GL_SRC_ALPHA:
        case GL_ONE_MINUS_SRC_ALPHA:
        case GL_DST_ALPHA:
        case GL_ONE_MINUS_DST_ALPHA:
        case GL_DST_COLOR:
        case GL_ONE_MINUS_DST_COLOR:
        case GL_SRC_ALPHA_SATURATE:
            bSuccess = true;
            break;
            
        default:
            break;
    } // switch
    
    return bSuccess;
} // GLUTextCheckBlending

#pragma mark -
#pragma mark Public - Utilities - Accessors

// Specify how the red, green, blue, and alpha source and
// destination blending factors are computed
void GLU::TextSetBlending(const GLenum& rSrc,
                          const GLenum& rDst,
                          GLU::TextRef pText)
{
    if(pText != nullptr)
    {
        // Check the source and destination blending factors
        GLenum nSFactor = GLUTextCheckBlending(rSrc) ? rSrc : GL_SRC_ALPHA;
        GLenum nDFactor = GLUTextCheckBlending(rDst) ? rDst : GL_ONE;
        
        // Blend function source factor
        pText->mnFactor[0] = nSFactor;
        
        // Blend function destination factor
        pText->mnFactor[1] = nDFactor;
    } // if
} // GLTextSetBlending

// Set field-of-view for prespective correct text
void GLU::TextSetFieldOfView(const GLfloat& rFovy,
                             GLU::TextRef pText)
{
    if(pText != nullptr)
    {
        pText->m_Transform.mnFovy = rFovy * GLM::kRadians_f;
    } // if
} // GLTextSetFieldOfView

// Set the text zoom for perspective projection
void GLU::TextSetZoom(const GLfloat& rDeltaY,
                      GLU::TextRef pText)
{
    if(pText != nullptr)
    {
        pText->m_Transform.mnZoom += 0.01f * rDeltaY;
        
        if(pText->m_Transform.mnZoom < 0.05f)
        {
            pText->m_Transform.mnZoom = 0.05f;
        } // if
        else if(pText->m_Transform.mnZoom > 2.0f)
        {
            pText->m_Transform.mnZoom = 2.0f;
        } // else if
    } // if
} // GLTextSetZoom

// Set the uniform assocated with a model-view-projection linear transformation
void GLU::TextSetMVP(const NSRect& rBounds,
                     const vector_float3& rTranslate,
                     const vector_float4& rRotate,
                     GLU::TextRef pText)
{
    if(pText != nullptr)
    {
        // Compute the model-view-projection linear transformation
        matrix_float4x4 mvp = GLUTextTransformCreateMVP(rBounds, rTranslate, rRotate, pText);
        
        // Enable the program object
        glUseProgram(pText->m_Program.mnPID);
        
        // Update the mvp linear transformation
        GLM::uniform(pText->m_Program.m_UID.mnMVP, false, mvp);
    } // if
} // GLTextSetUniformMVP

// Set the uniform assocated with a frustum linear transformation
void GLU::TexSetPrespective(const NSRect& rBounds,
                            GLU::TextRef pText)
{
    if(pText != nullptr)
    {
        // Compute the mvp linear transformation
        matrix_float4x4 mvp = GLUTextTransformCreateMVP(rBounds, pText);
        
        // Update the projection matrix
        glUseProgram(pText->m_Program.mnPID);
        
        // Set the mvp linear transformation unifrom
        GLM::uniform(pText->m_Program.m_UID.mnMVP, false, mvp);
    } // if
} // GLTexSetPrespective

// Set the uniform assocated with a orthographic 2D transformation
void GLU::TextSetOrthographic(const NSRect& rBounds,
                              GLU::TextRef pText)
{
    if(pText != nullptr)
    {
        // Calculate the orthographic 2D linear transformation
        pText->m_Transform.m_Ortho2D = GLUTextTransformCreateOrtho2D(rBounds, pText);
        
        // Enable the program object
        glUseProgram(pText->m_Program.mnPID);
        
        // Set the orthographic 2D linear transformation
        glUniform4f(pText->m_Program.m_UID.mnMVP,
                    pText->m_Transform.m_Ortho2D.x,
                    pText->m_Transform.m_Ortho2D.y,
                    pText->m_Transform.m_Ortho2D.z,
                    pText->m_Transform.m_Ortho2D.w);
    } // if
} // GLTextSetOrthographic

#pragma mark -
#pragma mark Public - Utilities - Rendering

// Render a text into an OpenGL view
void GLU::TextDisplay(const GLU::TextRef pText)
{
    if(pText != nullptr)
    {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glDisable(GL_DEPTH_TEST);
        glEnable(GL_BLEND);
        {
            // Specify pixel arithmetic.
            glBlendFunc(pText->mnFactor[0], pText->mnFactor[1]);
            
            // Select both front and back-facing polygon rasterization
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            
            glUseProgram(pText->m_Program.mnPID);
            glBindVertexArray(pText->m_Program.mnVAO);
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, pText->mnTID);
            
            glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        }
        glDisable(GL_BLEND);
    } // if
} // GLTextDisplay

#pragma mark -
#pragma mark Public - Constructors

// Create a perspective correct OpenGL text object
GLU::TextRef GLU::TextCreatePerspective(const GLU::String &rString,
                                        const GLU::String &rFontName,
                                        const CGFloat& rFontSize,
                                        const CTTextAlignment& rAlignment,
                                        const NSRect& rBounds,
                                        const GLfloat * const pColors)
{
    GLU::TextRef pText = NULL;
    
    try
    {
        // Instantiate a text object
        pText = new GLU::Text;
        
        // Clear the sturcture
        GLUTextSetDefaults(pText);
        
        if(!GLUTextCreateTexture2D(rString, rFontName, rFontSize, rAlignment, pText))
        {
            throw @"Failed creating a texture 2d for a c-string";
        }
        
        if(!GLUTextAcquirePerspective(rBounds, pColors, pText))
        {
            glDeleteTextures(1, &pText->mnTID);
            
            throw @"Failed acquiring a 2d perspective text";
        }
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: Failed allocating memory for CF mutable dictionary backing store: \"%s\"", ba.what());
        
        return;
    } // catch
    catch(NSString *pString)
    {
        delete pText;
        
        NSLog(@">> ERROR: %@", pString);
    } // catch
    
    return pText;
} // GLUTextCreatePerspective

// Create a non-perspective OpenGL text object
GLU::TextRef GLU::TextCreateNonPerspective(const GLU::String& rString,
                                           const GLU::String& rFontName,
                                           const CGFloat& rFontSize,
                                           const CTTextAlignment& rAlignment,
                                           const NSRect& rBounds,
                                           const NSPoint& rPosition,
                                           const GLfloat * const pColors)
{
    GLU::TextRef pText = NULL;
    
    try
    {
        // Instantiate a text object
        pText = new GLU::Text;
        
        // Clear the sturcture
        GLUTextSetDefaults(pText);
        
        if(!GLUTextCreateTexture2D(rString, rFontName, rFontSize, rAlignment, pText))
        {
            throw @"Failed creating a texture 2d for a c-string";
        }
        
        if(!GLUTextAcquireNonPerspective(rBounds, rPosition, pColors, pText))
        {
            glDeleteTextures(1, &pText->mnTID);
            
            throw @"Failed acquiring a 2d non-perspective text";
        }
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: Failed allocating memory for CF mutable dictionary backing store: \"%s\"", ba.what());
        
        return;
    } // catch
    catch(NSString *pString)
    {
        delete pText;
        
        NSLog(@">> ERROR: %@", pString);
    } // catch
} // GLUTextCreateNonPerspective

// Create program object, shaders, vao, and buffers for a perspective text
GLU::TextRef GLU::TextCreatePerspective(CFStringRef pString,
                                        CFStringRef pFontName,
                                        const CGFloat& rFontSize,
                                        const CTTextAlignment& rAlignment,
                                        const NSRect& rBounds,
                                        const GLfloat * const pColors)
{
    GLU::TextRef pText = NULL;
    
    try
    {
        // Instantiate a text object
        pText = new GLU::Text;
        
        // Clear the sturcture
        GLUTextSetDefaults(pText);
        
        if(!GLUTextCreateTexture2D(pString, pFontName, rFontSize, rAlignment, pText))
        {
            throw @"Failed creating a texture 2d for a c-string";
        }
        
        if(!GLUTextAcquirePerspective(rBounds, pColors, pText))
        {
            glDeleteTextures(1, &pText->mnTID);
            
            throw @"Failed acquiring a 2d perspective text";
        }
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: Failed allocating memory for CF mutable dictionary backing store: \"%s\"", ba.what());
        
        return;
    } // catch
    catch(NSString *pString)
    {
        delete pText;
        
        NSLog(@">> ERROR: %@", pString);
    } // catch
    
    return pText;
} // GLUTextCreatePerspective

// Create a program object, shaders, vao, and buffers for a nonperspective text
GLU::TextRef GLU::TextCreateNonPerspective(CFStringRef pString,
                                           CFStringRef pFontName,
                                           const CGFloat& rFontSize,
                                           const CTTextAlignment& rAlignment,
                                           const NSRect& rBounds,
                                           const NSPoint& rPosition,
                                           const GLfloat * const pColors)
{
    GLU::TextRef pText = NULL;
    
    try
    {
        // Instantiate a text object
        pText = new GLU::Text;
        
        // Clear the sturcture
        GLUTextSetDefaults(pText);
        
        if(!GLUTextCreateTexture2D(pString, pFontName, rFontSize, rAlignment, pText))
        {
            throw @"Failed creating a texture 2d for a c-string";
        }
        
        if(!GLUTextAcquireNonPerspective(rBounds, rPosition, pColors, pText))
        {
            glDeleteTextures(1, &pText->mnTID);
            
            throw @"Failed acquiring a 2d non-perspective text";
        }
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: Failed allocating memory for CF mutable dictionary backing store: \"%s\"", ba.what());
        
        return;
    } // catch
    catch(NSString *pString)
    {
        delete pText;
        
        NSLog(@">> ERROR: %@", pString);
    } // catch
    
    return pText;
} // GLUTextCreateNonPerspective

// Create a perspective correct OpenGL text object
GLU::TextRef GLU::TextCreatePerspective(CFAttributedStringRef pAttrString,
                                        const NSRect& rBounds,
                                        const GLfloat * const pColors)
{
    GLU::TextRef pText = NULL;
    
    try
    {
        // Instantiate a text object
        pText = new GLU::Text;
        
        // Clear the sturcture
        GLUTextSetDefaults(pText);
        
        if(!GLUTextCreateTexture2D(pAttrString, pText))
        {
            throw @"Failed creating a texture 2d for a c-string";
        }
        
        if(!GLUTextAcquirePerspective(rBounds, pColors, pText))
        {
            glDeleteTextures(1, &pText->mnTID);
            
            throw @"Failed acquiring a 2d perspective text";
        }
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: Failed allocating memory for CF mutable dictionary backing store: \"%s\"", ba.what());
        
        return;
    } // catch
    catch(NSString *pString)
    {
        delete pText;
        
        NSLog(@">> ERROR: %@", pString);
    } // catch
    
    return pText;
} // GLUTextCreatePerspective

// Create a non-perspective OpenGL text object
GLU::TextRef GLU::TextCreateNonPerspective(CFAttributedStringRef pAttrString,
                                           const NSRect& rBounds,
                                           const NSPoint& rPosition,
                                           const GLfloat * const pColors)
{
    GLU::TextRef pText = NULL;
    
    try
    {
        // Instantiate a text object
        pText = new GLU::Text;
        
        // Clear the sturcture
        GLUTextSetDefaults(pText);
        
        if(!GLUTextCreateTexture2D(pAttrString, pText))
        {
            throw @"Failed creating a texture 2d for a c-string";
        }
        
        if(!GLUTextAcquireNonPerspective(rBounds, rPosition, pColors, pText))
        {
            glDeleteTextures(1, &pText->mnTID);
            
            throw @"Failed acquiring a 2d perspective text";
        }
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: Failed allocating memory for CF mutable dictionary backing store: \"%s\"", ba.what());
        
        return;
    } // catch
    catch(NSString *pString)
    {
        delete pText;
        
        NSLog(@">> ERROR: %@", pString);
    } // catch
    
    return pText;
} // GLUTextCreateNonPerspective

#pragma mark -
#pragma mark Public - Destructor

// Delete program object, shaders, vao, and buffers
void GLU::TextDelete(GLU::TextRef pText)
{
    if(pText != nullptr)
    {
        glDeleteTextures(1, &pText->mnTID);
        
        GLU::VertexArrayDelete(pText->mpVertices);
        GLU::ProgramDelete(pText->m_Program.mpProgram);
        
        delete pText;
    } // if
} // GLUTextDelete
