/*
     File: GLUProgram.mm
 Abstract: n/a
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

// String copy utilities
#import "CFString.h"

// OpenGL string utilities
#import "GLUString.h"

// OpenGL file stream utilities
#import "CFIFStream.h"

// OpenGL utilities header
#import "GLUProgram.h"

#pragma mark -
#pragma mark Private - Data Structures

namespace GLU
{
    // GLSL program description
    struct Program
    {
        GLuint     mnPID;
        Inputs     m_Inputs;
        Locations  m_Fragments;
        Locations  m_Attributes;
        Objects    m_Shaders;
        Sources    m_Sources;
    }; // Program
    
    typedef struct Program  Program;
} // GLU

#pragma mark -
#pragma mark Private - Utilities - Destructor

static void GLUProgramClearInputs(GLU::ProgramRef pProgram)
{
    if(!pProgram->m_Inputs.empty())
    {
        pProgram->m_Inputs.clear();
    } // if
} // GLUProgramClearInputs

// Delete locations
static void GLUProgramClearLocations(GLU::ProgramRef pProgram)
{
    if(!pProgram->m_Fragments.empty())
    {
        pProgram->m_Fragments.clear();
    } // if
    
    if(!pProgram->m_Attributes.empty())
    {
        pProgram->m_Attributes.clear();
    } // if
} // GLUProgramClearLocations

// Delete inputs
static void GLUProgramClearSources(GLU::ProgramRef pProgram)
{
    if(!pProgram->m_Sources.empty())
    {
        pProgram->m_Sources.clear();
    } // if
} // GLUProgramClearSources

// Delete all the shaders
static void GLUProgramDeleteShaders(GLU::ProgramRef pProgram)
{
    if(!pProgram->m_Shaders.empty())
    {
        for(auto& shader:pProgram->m_Shaders)
        {
            glDeleteShader(shader);
        } // if
        
        pProgram->m_Shaders.clear();
    } // if
} // GLUProgramDeleteShaders

// Delete program object
static void GLUProgramDeleteProgObj(GLU::ProgramRef pProgram)
{
    if(!pProgram->mnPID)
    {
        glDeleteProgram(pProgram->mnPID);
    } // if
} // GLUProgramDeleteProgObj

// Delete all the program object and shaders
static void GLUProgramDelete(GLU::ProgramRef pProgram)
{
    GLUProgramClearInputs(pProgram);
    GLUProgramClearLocations(pProgram);
    GLUProgramClearSources(pProgram);
    
    GLUProgramDeleteShaders(pProgram);
    GLUProgramDeleteProgObj(pProgram);
    
    delete pProgram;
} // GLUProgramDelete

#pragma mark -
#pragma mark Private - Utilities - Locations

// Function pointer definition for location binding
typedef void (*GLUProgramBindLocationFuncPtr)(GLuint nPID, GLuint nIndex, const GLchar *pName);

// Bind locations using an OpenGL function
static bool GLUProgramBindLocations(const GLuint nPID,
                                    GLU::Locations  &rLocations,
                                    GLUProgramBindLocationFuncPtr GLUBindLocation)
{
    bool bSuccess = !rLocations.empty();
    
    if(bSuccess)
    {
        // Vertex shader inputs
        for(auto& location: rLocations)
        {
            GLUBindLocation(nPID, location.first, location.second.c_str());
        } // for
    } // if
    
    return bSuccess;
} // GLUProgramBindLocations

// Create an associative array (a.k.a. map) from key-value pairs
static GLU::Locations GLUProgramLocationsCreate(const GLU::UInts   &rKeys,
                                                const GLU::Strings &rValues)
{
    GLU::Locations locs;
    
    if(!rKeys.empty())
    {
        GLuint i = 0;
        
        // Insert the key-value pair into an associative array
        for(auto& key:rKeys)
        {
            locs[key] = rValues[i];
            
            ++i;
        } // for
    } // if
    
    return locs;
} // GLUProgramLocationsCreate

// Create an associative array (a.k.a. map) from key-value pairs
static GLU::Locations GLUProgramLocationsCreate(CFArrayRef pKeys,
                                                CFArrayRef pValues)
{
    GLU::Locations locs;
    
    if(pKeys && pValues)
    {
        GLuint iMax = CFArrayGetCount(pKeys);
        GLuint jMax = CFArrayGetCount(pValues);
        
        if(iMax > jMax)
        {
            iMax = jMax;
        } // if
        
        if(iMax)
        {
            GLuint i;
            
            CFStringRef pValue = NULL;
            CFNumberRef pKey   = NULL;
            
            GLuint key = 0;
            
            bool bSuccess = false;
            
            // Insert the key-value pair into an associative array
            for(i = 0; i < iMax; ++i)
            {
                pKey = CFNumberRef(CFArrayGetValueAtIndex(pKeys, i));
                
                if(pKey != nullptr)
                {
                    pValue = CFStringRef(CFArrayGetValueAtIndex(pValues, i));
                    
                    bSuccess = pValue != nullptr;
                    
                    bSuccess = bSuccess && CFNumberGetValue(pKey, kCFNumberSInt32Type, &key);
                    
                    if(bSuccess)
                    {
                        locs[GLuint(key)] = CF::StringCreateCStringCopy(pValue);
                    } // ikf
                } // if
            } // for
        } // if
    } // if
    
    return locs;
} // GLUProgramLocationsCreate

// Applier function for converting a CFDictionary to a STL map
static void GLUProgramLocationsApplyFunction(const void *pKey,
                                             const void *pValue,
                                             void *pContext)
{
    if(pKey && pValue)
    {
        GLuint key = 0;
        
        if(CFNumberGetValue(CFNumberRef(pKey), kCFNumberSInt32Type, &key))
        {
            GLU::String     value = CF::StringCreateCStringCopy(CFStringRef(pValue));
            GLU::Locations *pLocs = (GLU::Locations *)pContext;
            
            pLocs->insert(GLU::Location(GLuint(key),value));
        } // if
    } // if
} // GLUProgramLocationsApplyFunction

// Create an associative array (a.k.a. map) from key-value pairs
static GLU::Locations GLUProgramLocationsCreate(CFDictionaryRef pLocations)
{
    GLU::Locations locs;
    
    if(pLocations != nullptr)
    {
        GLuint nCount = CFDictionaryGetCount(pLocations);
        
        if(nCount)
        {
            CFDictionaryApplyFunction(pLocations,GLUProgramLocationsApplyFunction,&locs);
        } // if
    } // if
    
    return locs;
} // GLUProgramLocationsCreate

#pragma mark -
#pragma mark Private - Utilities - Inputs

// Acquire inputs for a geometry shader
static bool GLUProgramAddInputs(const GLenum& nInputType,
                                const GLenum& nOutputType,
                                const GLuint& nVerticesOut,
                                GLU::ProgramRef pProgram)
{
    pProgram->m_Inputs[GL_GEOMETRY_INPUT_TYPE]   = nInputType;
    pProgram->m_Inputs[GL_GEOMETRY_OUTPUT_TYPE]  = nOutputType;
    pProgram->m_Inputs[GL_GEOMETRY_VERTICES_OUT] = nVerticesOut;
    
    return pProgram->m_Inputs.size() == 3;
} // GLUProgramInputsAcquire

// Set geometry shader stage parameters
static void GLUProgramBindInputs(GLU::ProgramRef pProgram)
{
    if(!pProgram->m_Inputs.empty())
    {
        GLenum  nInputType  = pProgram->m_Inputs[GL_GEOMETRY_INPUT_TYPE];
        GLenum  nOutputType = pProgram->m_Inputs[GL_GEOMETRY_OUTPUT_TYPE];
        GLuint  nVertices   = pProgram->m_Inputs[GL_GEOMETRY_VERTICES_OUT];
        
        glProgramParameteri(pProgram->mnPID, GL_GEOMETRY_INPUT_TYPE, nInputType);
        glProgramParameteri(pProgram->mnPID, GL_GEOMETRY_OUTPUT_TYPE, nOutputType);
        glProgramParameteri(pProgram->mnPID, GL_GEOMETRY_VERTICES_OUT, nVertices);
    } // if
} // GLUProgramBindInputs

#pragma mark -
#pragma mark Private - Utilities - Shader Sources

// Compile vertex and fragment shaders, with/without optional
// geometry shader
static bool GLUProgramAcquireShaderSources(const GLU::Source& rVertex,
                                           const GLU::Source& rFragment,
                                           const GLU::Source& rGeometry,
                                           GLU::ProgramRef pProgram)
{
    bool bSuccess = !rVertex.empty() && !rFragment.empty();
    
    if(bSuccess)
    {
        pProgram->m_Sources[GL_VERTEX_SHADER]   = rVertex;
        pProgram->m_Sources[GL_FRAGMENT_SHADER] = rFragment;
        
        if(!rGeometry.empty())
        {
            pProgram->m_Sources[GL_GEOMETRY_SHADER] = rGeometry;
        } // if
    } // if
    
    return bSuccess;
} // GLUProgramAcquireShaderSources

// Compile vertex and fragment shaders
static bool GLUProgramAcquireShaderSources(const GLU::Source& rVertex,
                                           const GLU::Source& rFragment,
                                           GLU::ProgramRef pProgram)
{
    return GLUProgramAcquireShaderSources(rVertex, rFragment, "", pProgram);
} // GLUProgramAcquireShaderSources

// Compile vertex and fragment shaders, with/without optional
// geometry shader
static bool GLUProgramAcquireShaderSources(CFStringRef pVertex,
                                           CFStringRef pFragment,
                                           CFStringRef pGeometry,
                                           GLU::ProgramRef pProgram)
{
    GLchar *vertex   = CF::StringCreateBufferCopy(pVertex);
    GLchar *fragment = CF::StringCreateBufferCopy(pFragment);
    
    bool bSuccess = (vertex != nullptr) && (fragment != nullptr);
    
    if(bSuccess)
    {
        pProgram->m_Sources[GL_VERTEX_SHADER]   = vertex;
        pProgram->m_Sources[GL_FRAGMENT_SHADER] = fragment;
        
        GLchar *geometry = CF::StringCreateBufferCopy(pGeometry);
        
        if(geometry != nullptr)
        {
            pProgram->m_Sources[GL_GEOMETRY_SHADER] = geometry;
            
            free(geometry);
        } // if
    } // if
    
    if(vertex != nullptr)
    {
        free(vertex);
    } // if
    
    if(fragment != nullptr)
    {
        free(fragment);
    } // if
    
    return bSuccess;
} // GLUProgramAcquireShaderSources

// Compile vertex and fragment shaders
static bool GLUProgramAcquireShaderSources(CFStringRef pVertex,
                                           CFStringRef pFragment,
                                           GLU::ProgramRef pProgram)
{
    return GLUProgramAcquireShaderSources(pVertex, pFragment, nullptr, pProgram);
} // GLUProgramAcquireShaderSources

#pragma mark -
#pragma mark Private - Utilities - Shaders

// Compile a shader from source string
static void GLUProgramCompileShader(GLuint nShader,
                                    const GLU::Source &rShaderSource)
{
    GLint nInfoLogLength = 0;
    
    if(!rShaderSource.empty())
    {
        const GLchar *pShaderSource = rShaderSource.c_str();
        
        glShaderSource(nShader, 1, &pShaderSource, nullptr);
        glCompileShader(nShader);
        
        glGetShaderiv(nShader, GL_INFO_LOG_LENGTH, &nInfoLogLength);
        
        if(nInfoLogLength)
        {
            GLchar *pInfoLog = NULL;
            
            try
            {
                pInfoLog = new GLchar[nInfoLogLength];
                
                glGetShaderInfoLog(nShader,
                                   nInfoLogLength,
                                   &nInfoLogLength,
                                   pInfoLog);
                
                NSLog(@">> INFO: OpenGL Shader - Shader compile log:\n%s\n", pInfoLog);
                
                delete [] pInfoLog;
            } // try
            catch(std::bad_alloc& ba)
            {
                NSLog(@">> ERROR: Failed allocating memory for shader compilation info. log: \"%s\"", ba.what());
            } // catch
        } // if
    } // if
} // GLUProgramCompileShader

// Validate a compiled shader
static bool GLUProgramValidateShader(const GLuint nShader,
                                     const GLU::Source &rShaderSource)
{
    GLint nIsCompiled = 0;
    
    glGetShaderiv(nShader, GL_COMPILE_STATUS, &nIsCompiled);
    
    if(nIsCompiled == 0)
    {
        if(!rShaderSource.empty())
        {
            NSLog(@">> WARNING: OpenGL Shader - Failed to compile shader!\n%s\n", rShaderSource.c_str());
        } // if
        
        NSLog(@">> WARNING: OpenGL Shader - Deleted shader object with id = %d", nShader);
        
        glDeleteShader(nShader);
    } // if
    
    return nIsCompiled != 0;
} // GLUProgramValidateShader

// Create, and validate, a shader from a source string
static GLuint GLUProgramCreateShader(const GLenum nShaderType,
                                     GLU::ProgramRef pProgram)
{
    GLuint nShader = glCreateShader(nShaderType);
    
    if(nShader)
    {
        GLUProgramCompileShader(nShader, pProgram->m_Sources[nShaderType]);
        
        if(!GLUProgramValidateShader(nShader, pProgram->m_Sources[nShaderType]))
        {
            nShader = 0;
        } // if
    } // if
    
    return nShader;
} // GLUProgramCreateShader

// Compile vertex and fragment shaders, with/without optional geometry shader
static bool GLUProgramAcquireShaders(GLU::ProgramRef pProgram)
{
    bool bSuccess =
    (!pProgram->m_Sources[GL_VERTEX_SHADER].empty())
    &&  (!pProgram->m_Sources[GL_FRAGMENT_SHADER].empty());
    
    if(bSuccess)
    {
        // Compile the mandatory vertex and fragment shaders
        
        // Create a vertex shader
        GLuint shaderID = GLUProgramCreateShader(GL_VERTEX_SHADER, pProgram);
        
        bool bSuccess = bool(shaderID);
        
        if(bSuccess)
        {
            // Insert vertex shader id into the vector
            pProgram->m_Shaders.push_back(shaderID);
            
            // Create a fragment shader
            shaderID = GLUProgramCreateShader(GL_FRAGMENT_SHADER, pProgram);
            
            bSuccess = bool(shaderID);
            
            if(bSuccess)
            {
                // Insert fragment shader id into the vector
                pProgram->m_Shaders.push_back(shaderID);
                
                // If optional geometry shader stage is required
                if(pProgram->m_Sources.size() == 3)
                {
                    shaderID = GLUProgramCreateShader(GL_GEOMETRY_SHADER, pProgram);
                    
                    bSuccess = bool(shaderID);
                    
                    if(bSuccess)
                    {
                        // Insert optional geometry shader id into the vector
                        pProgram->m_Shaders.push_back(shaderID);
                    } // if
                } // if
            } // if
        } // if
        
        if(!bSuccess)
        {
            GLUProgramDeleteShaders(pProgram);
        } // if
    } // if
    
    return bSuccess;
} // GLUProgramAcquireShaders

#pragma mark -
#pragma mark Private - Utilities - Attaching

// Attach the (optional) geometry shader stage
static void GLUProgramAttachGeometryShader(GLU::ProgramRef pProgram)
{
    if(pProgram->m_Shaders.size() == 3)
    {
        glAttachShader(pProgram->mnPID, pProgram->m_Shaders[2]);
        
        GLUProgramBindInputs(pProgram);
    } // if
} // GLUProgramAttachGeometryShader

// Create a program object and attach shaders
static bool GLUProgramAttachShaders(GLU::ProgramRef pProgram)
{
    pProgram->mnPID = glCreateProgram();
    
    if(pProgram->mnPID)
    {
        // Attach the vertex shader
        glAttachShader(pProgram->mnPID, pProgram->m_Shaders[0]);
        
        // Attach the fragment shader
        glAttachShader(pProgram->mnPID, pProgram->m_Shaders[1]);
        
        // Attach the optional geometry shader
        GLUProgramAttachGeometryShader(pProgram);
    } // if
    
    return bool(pProgram->mnPID);
} // GLUProgramAttachShaders

#pragma mark -
#pragma mark Private - Utilities - Linker

// Get the program log
static void GLUProgramGetInfoLog(GLU::ProgramRef pProgram)
{
    GLint nInfoLogLength = 0;
    
    glGetProgramiv(pProgram->mnPID, GL_INFO_LOG_LENGTH, &nInfoLogLength);
    
    if(nInfoLogLength)
    {
        GLchar *pInfoLog = NULL;
        
        try
        {
            pInfoLog =  new GLchar[nInfoLogLength];
            
            glGetProgramInfoLog(pProgram->mnPID,
                                nInfoLogLength,
                                &nInfoLogLength,
                                pInfoLog);
            
            NSLog(@">> INFO: OpenGL Program - Link log:\n%s\n", pInfoLog);
            
            delete [] pInfoLog;
        } // try
        catch(std::bad_alloc& ba)
        {
            NSLog(@">> ERROR: OpenGL Program - Failed allocating memory for program link info. log: \"%s\"", ba.what());
        } // catch
    } // if
} // GLUProgramGetInfoLog

// Validate the program object
static bool GLUProgramValidate(GLU::ProgramRef pProgram)
{
    GLint nIsLinked = 0;
    
    glGetProgramiv(pProgram->mnPID, GL_LINK_STATUS, &nIsLinked);
    
    if(!nIsLinked)
    {
        NSLog(@">> WARNING: OpenGL Program - Deleted program object with id = %d", pProgram->mnPID);
        
        glDeleteProgram(pProgram->mnPID);
        
        pProgram->mnPID = 0;
    } // if
    
    return nIsLinked != 0;
} // GLUProgramValidate

// Bind generic vertex attribute locations
static bool GLUProgramBindAttributes(GLU::ProgramRef pProgram)
{
    return GLUProgramBindLocations(pProgram->mnPID,
                                   pProgram->m_Attributes,
                                   glBindAttribLocation);
} // GLUProgramBindAttributes

// Bind fragment data locations
static bool GLUProgramBindFragments(GLU::ProgramRef pProgram)
{
    return GLUProgramBindLocations(pProgram->mnPID,
                                   pProgram->m_Fragments,
                                   glBindFragDataLocation);
} // GLUProgramBindFragments

// Create a program object from shaders (that may include an optional geometry shader)
static bool GLUProgramLink(GLU::ProgramRef pProgram)
{
    // Create the program object
    bool bSuccess = GLUProgramAttachShaders(pProgram);
    
    if(bSuccess)
    {
        // Bind attribute locations
        GLUProgramBindAttributes(pProgram);
        
        // Bind fragment data locations
        GLUProgramBindFragments(pProgram);
        
        // Link to the program object
        glLinkProgram(pProgram->mnPID);
        
        // Get the program log
        GLUProgramGetInfoLog(pProgram);
        
        // Validate the program object
        bSuccess = GLUProgramValidate(pProgram);
    } // if
    
    return bSuccess;
} // GLUProgramLink

// Compile and link shaders to acquire a program object
static bool GLUProgramFinalize(GLU::ProgramRef pProgram)
{
    bool bSuccess = GLUProgramAcquireShaders(pProgram);
    
    if(bSuccess)
    {
        bSuccess = GLUProgramLink(pProgram);
    } // if
    
    return bSuccess;
} // GLUProgramFinalize

// Use a compiled and linked program object
static bool GLUProgramBind(GLU::ProgramRef pProgram)
{
    glUseProgram(pProgram->mnPID);
    
    return bool(pProgram->mnPID);
} // GLUProgramBind

#pragma mark -
#pragma mark Private - Utilities - Copy

static bool GLUProgramCopy(const GLU::ProgramRef pProgramSrc,
                           GLU::ProgramRef pProgramDst)
{
    // Copy shader sources
    pProgramDst->m_Sources = pProgramSrc->m_Sources;
    
    // Copy fragment locations
    pProgramDst->m_Fragments = pProgramSrc->m_Fragments;
    
    // Copy attribute locations
    pProgramDst->m_Attributes = pProgramSrc->m_Attributes;
    
    // Copy geometry shader inputs
    pProgramDst->m_Inputs = pProgramSrc->m_Inputs;
    
    bool bSuccess = GLUProgramFinalize(pProgramDst);
    
    // Compile link and acquire a program object
    if(!bSuccess)
    {
        GLUProgramClearInputs(pProgramDst);
        GLUProgramClearLocations(pProgramDst);
        GLUProgramClearSources(pProgramDst);
    } // if
    
    return bSuccess;
} // GLUProgramCopy

#pragma mark -
#pragma mark Private - Utilities - Constructors

// Compile vertex and fragment shaders, with/without optional
// geometry shader
static GLU::ProgramRef GLUProgramCreate(const GLU::String &rVertex,
                                        const GLU::String &rFragment,
                                        const GLU::String &rGeometry)
{
    GLU::ProgramRef pProgram = nullptr;
    
    try
    {
        pProgram = new GLU::Program;
        
        if(!GLUProgramAcquireShaderSources(rVertex, rFragment, rGeometry, pProgram))
        {
            throw @"OpenGL Program - Failed acquiring shader sources!";
        } // if
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: OpenGL Program - Failed creating program object backing-store: \"%s\"", ba.what());
    } // catch
    catch(NSString *pString)
    {
        GLUProgramDelete(pProgram);
        
        NSLog(@">> ERROR: %@", pString);
    } // catch
    
    return pProgram;
} // GLUProgramCreate

// Compile vertex and fragment shaders, with/without optional
// geometry shader
static GLU::ProgramRef GLUProgramCreate(CFStringRef pVertex,
                                        CFStringRef pFragment,
                                        CFStringRef pGeometry)
{
    GLU::ProgramRef pProgram = nullptr;
    
    try
    {
        pProgram = new GLU::Program;
        
        if(!GLUProgramAcquireShaderSources(pVertex, pFragment, pGeometry, pProgram))
        {
            throw @"OpenGL Program - Failed acquiring shader sources!";
        } // if
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: OpenGL Program - Failed creating program object backing-store: \"%s\"", ba.what());
    } // catch
    catch(NSString *pString)
    {
        GLUProgramDelete(pProgram);
        
        NSLog(@">> ERROR: %@", pString);
    } // catch
    
    return pProgram;
} // GLUProgramCreate

// Compile vertex and fragment shaders, with/without optional geometry shader
// geometry shader at a pathname
static GLU::ProgramRef GLUProgramCreateAtPath(const GLU::String &rVertex,
                                              const GLU::String &rFragment,
                                              const GLU::String &rGeometry)
{
    GLU::ProgramRef pProgram = nullptr;
    
    CF::IFStreamRef vertex   = CF::IFStreamCreate(rVertex);
    CF::IFStreamRef fragment = CF::IFStreamCreate(rFragment);
    
    if((vertex != nullptr) && (fragment != nullptr))
    {
        CF::IFStreamRef geometry = CF::IFStreamCreate(rGeometry);
        
        pProgram = GLU::ProgramCreate(CF::IFStreamGetBuffer(vertex),
                                      CF::IFStreamGetBuffer(fragment),
                                      CF::IFStreamGetBuffer(geometry));
        
        CF::IFStreamDelete(vertex);
        CF::IFStreamDelete(fragment);
        CF::IFStreamDelete(geometry);
    } // if
    
    return pProgram;
} // GLUProgramsCreateAtPath

// Compile vertex and fragment shaders, with/without optional geometry shader
// geometry shader at a pathname
static GLU::ProgramRef GLUProgramCreateAtPath(CFStringRef pVertex,
                                              CFStringRef pFragment,
                                              CFStringRef pGeometry)
{
    GLU::ProgramRef pProgram = nullptr;
    
    CF::IFStreamRef vertex   = CF::IFStreamCreate(pVertex);
    CF::IFStreamRef fragment = CF::IFStreamCreate(pFragment);
    
    if((vertex != nullptr) && (fragment != nullptr))
    {
        CF::IFStreamRef geometry = CF::IFStreamCreate(pGeometry);
        
        pProgram = GLU::ProgramCreate(CF::IFStreamGetBuffer(vertex),
                                      CF::IFStreamGetBuffer(fragment),
                                      CF::IFStreamGetBuffer(geometry));
        
        CF::IFStreamDelete(vertex);
        CF::IFStreamDelete(fragment);
        CF::IFStreamDelete(geometry);
    } // if
    
    return pProgram;
} // GLUProgramsCreateAtPath

#pragma mark -
#pragma mark Public - Utilities - Constructors

// Compile vertex and fragment shaders
GLU::ProgramRef GLU::ProgramCreate(const bool& bUseAsPath,
                                   const GLU::String& rVertex,
                                   const GLU::String& rFragment)
{
    return (bUseAsPath)
    ? GLUProgramCreateAtPath(rVertex, rFragment, "")
    : GLUProgramCreate(rVertex, rFragment, "");
} // ProgramCreate

// Compile vertex and fragment shaders, with/without optional
// geometry shader
GLU::ProgramRef GLU::ProgramCreate(const bool& bUseAsPath,
                                   const GLU::String& rVertex,
                                   const GLU::String& rFragment,
                                   const GLU::String& rGeometry)
{
    return (bUseAsPath)
    ? GLUProgramCreateAtPath(rVertex, rFragment, rGeometry)
    : GLUProgramCreate(rVertex, rFragment, rGeometry);
} // ProgramCreate

// Compile vertex and fragment shaders
GLU::ProgramRef GLU::ProgramCreate(const bool& bUseAsPath,
                                   CFStringRef pVertex,
                                   CFStringRef pFragment)
{
    return (bUseAsPath)
    ? GLUProgramCreateAtPath(pVertex, pFragment, nullptr)
    : GLUProgramCreate(pVertex, pFragment, nullptr);
} // ProgramCreate

// Compile vertex and fragment shaders, with/without optional
// geometry shader
GLU::ProgramRef GLU::ProgramCreate(const bool& bUseAsPath,
                                   CFStringRef pVertex,
                                   CFStringRef pFragment,
                                   CFStringRef pGeometry)
{
    return (bUseAsPath)
    ? GLUProgramCreateAtPath(pVertex, pFragment, pGeometry)
    : GLUProgramCreate(pVertex, pFragment, pGeometry);
} // ProgramCreate

#pragma mark -
#pragma mark Public - Utilities - Copy Constructor

// Make a deep copy of the program object
GLU::ProgramRef GLU::ProgramCreateCopy(GLU::ProgramRef pProgramSrc)
{
    GLU::ProgramRef pProgramDst = nullptr;
    
    if(pProgramSrc != nullptr)
    {
        try
        {
            pProgramDst = new GLU::Program;
            
            if(!GLUProgramCopy(pProgramSrc, pProgramDst))
            {
                throw @"OpenGL Program - Failed copying the source to destination program object!";
            } // if
        } // try
        catch(std::bad_alloc& ba)
        {
            NSLog(@">> ERROR: OpenGL Program - Failed creating program object copy backing-store: \"%s\"", ba.what());
        } // catch
        catch(NSString *pString)
        {
            GLUProgramDelete(pProgramDst);
            
            NSLog(@">> ERROR: %@", pString);
        } // catch
    } // if
    
    return pProgramDst;
} // ProgramCreateCopy

#pragma mark -
#pragma mark Public - Utilities - Attributes

// Delete all the program object and shaders
void GLU::ProgramDelete(GLU::ProgramRef pProgram)
{
    if(pProgram != nullptr)
    {
        GLUProgramDelete(pProgram);
    } // if
} // GLUProgramDelete

#pragma mark -
#pragma mark Public - Utilities - Attributes

bool GLU::ProgramAddAttributes(const GLU::UInts    &rKeys,
                               const GLU::Strings  &rValues,
                               GLU::ProgramRef pProgram)
{
    bool bSuccess = pProgram != nullptr;
    
    if(bSuccess)
    {
        pProgram->m_Attributes = GLUProgramLocationsCreate(rKeys, rValues);
        
        bSuccess = pProgram->m_Attributes.size() == rKeys.size();
    } // if
    
    return bSuccess;
} // GLUProgramAddAttributes

bool GLU::ProgramAddAttributes(CFArrayRef pKeys,
                               CFArrayRef pValues,
                               GLU::ProgramRef pProgram)
{
    bool bSuccess = pProgram != nullptr;
    
    if(bSuccess)
    {
        pProgram->m_Attributes = GLUProgramLocationsCreate(pKeys, pValues);
        
        bSuccess = pProgram->m_Attributes.size() == ((pKeys) ? CFArrayGetCount(pKeys) : 0);
    } // if
    
    return bSuccess;
} // GLUProgramAddAttributes

bool GLU::ProgramAddAttributes(CFDictionaryRef pLocations,
                               GLU::ProgramRef pProgram)
{
    bool bSuccess = pProgram != nullptr;
    
    if(bSuccess)
    {
        pProgram->m_Attributes = GLUProgramLocationsCreate(pLocations);
        
        bSuccess = pProgram->m_Attributes.size() == ((pLocations) ? CFDictionaryGetCount(pLocations) : 0);
    } // if
    
    return bSuccess;
} // GLUProgramAddAttributes

#pragma mark -
#pragma mark Public - Utilities - Fragments

bool GLU::ProgramAddFragments(const UInts& rKeys,
                              const Strings& rValues,
                              ProgramRef pProgram)
{
    bool bSuccess = pProgram != nullptr;
    
    if(bSuccess)
    {
        pProgram->m_Fragments = GLUProgramLocationsCreate(rKeys, rValues);
        
        bSuccess = pProgram->m_Fragments.size() == rKeys.size();
    } // if
    
    return bSuccess;
} // GLUProgramAddFragments

bool GLU::ProgramAddFragments(CFArrayRef pKeys,
                              CFArrayRef pValues,
                              GLU::ProgramRef pProgram)
{
    bool bSuccess = pProgram != nullptr;
    
    if(bSuccess)
    {
        pProgram->m_Fragments = GLUProgramLocationsCreate(pKeys, pValues);
        
        bSuccess = pProgram->m_Fragments.size() == ((pKeys) ? CFArrayGetCount(pKeys) : 0);
    } // if
    
    return bSuccess;
} // GLUProgramAddFragments

bool GLU::ProgramAddFragments(CFDictionaryRef pLocations,
                              GLU::ProgramRef pProgram)
{
    bool bSuccess = pProgram != nullptr;
    
    if(bSuccess)
    {
        pProgram->m_Fragments = GLUProgramLocationsCreate(pLocations);
        
        bSuccess = pProgram->m_Fragments.size() == ((pLocations) ? CFDictionaryGetCount(pLocations) : 0);
    } // if
    
    return bSuccess;
} // GLUProgramAddFragments

#pragma mark -
#pragma mark Public - Utilities - Inputs

// Add geometry shader inputs
bool GLU::ProgramAddInputs(const GLenum& nInputType,
                           const GLenum& nOutputType,
                           const GLuint& nVerticesOut,
                           GLU::ProgramRef pProgram)
{
    return (pProgram != nullptr) ? GLUProgramAddInputs(nInputType, nOutputType, nVerticesOut, pProgram) : false;
} // ProgramAddInputs

#pragma mark -
#pragma mark Public - Utilities - Shaders

// Get the id associated with the program object
GLuint GLU::ProgramGetHandle(GLU::ProgramRef pProgram)
{
    return (pProgram != nullptr) ? pProgram->mnPID : 0;
} // ProgramGetHandle

// Compile and link shaders to acquire a program object
bool GLU::ProgramFinalize(GLU::ProgramRef pProgram)
{
    return (pProgram != nullptr) ? GLUProgramFinalize(pProgram) : false;
} // GLUProgramFinalize

// Use a compiled and linked program object
bool GLU::ProgramBind(GLU::ProgramRef pProgram)
{
    return (pProgram != nullptr) ? GLUProgramBind(pProgram) : false;
} // GLUProgramBind
