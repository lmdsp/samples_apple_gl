/*
     File: GLUQuery.mm
 Abstract: 
 Utility toolkit for constructing a query of OpenGL Core profile features.
 
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

// STL containers
#import <sstream>

// Mac OS X OpenGL frameworks
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

// OpenGL string utilities
#import "GLUString.h"

// Query Header
#import "GLUQuery.h"

#pragma mark -
#pragma mark Private - Data Structures

namespace GLU
{
    // Search string for feature family
    static const GLchar *kQueryStringApple = "GL_APPLE";
    static const GLchar *kQueryStringARB   = "GL_ARB";
    static const GLchar *kQueryStringEXT   = "GL_EXT";
    
    // String feature family length
    static const size_t kQuerySzStringApple = 8;
    static const size_t kQuerySzStringARB   = 6;
    static const size_t kQuerySzStringEXT   = 6;
    
    // More (private) OpenGL container types
    typedef std::stringstream                             SStream;
    typedef std::unordered_map<String, String>            ExtDB;
    typedef std::unordered_map<String, String>::iterator  ExtDBitr;
    
    // Renderer, version, and vendor data structures
    struct QueryString
    {
        String m_Renderer;
        String m_Version;
        String m_Vendor;
    };
    
    typedef struct QueryString   QueryString;
    
    // Apple, ARB, and EXT features and their strings
    struct QueryFeatures
    {
        Features m_Apple;
        Features m_ARB;
        Features m_EXT;
        
        CFMutableArrayRef mpApple;
        CFMutableArrayRef mpARB;
        CFMutableArrayRef mpEXT;
    };
    
    typedef struct QueryFeatures   QueryFeatures;
    
    // Apple, ARB, and EXT features as an associative array
    struct QueryDB
    {
        ExtDB     m_Exts;
        ExtDBitr  m_ExtsEnd;
    };
    
    typedef struct QueryDB  QueryDB;
    
    // OpenGL query strings, extensions (or features), including
    // a dictionary representation
    struct Query
    {
        QueryString    m_String;
        QueryFeatures  m_Features;
        QueryDB        m_DB;
    };
    
    typedef struct Query Query;
} // GLU

#pragma mark -
#pragma mark Private - Utilities - Strings

// OpenGL features as a string, where each feature is separated
// using a seperator string
static GLU::String GLUQueryCreateStringFeatures(const GLU::String &rSeperator,
                                                const GLU::Features &rFeatures)
{
    GLU::String string;
    
    GLuint iMax = rFeatures.size();
    
    if(iMax)
    {
        GLuint i;
        
        GLU::SStream oss;
        
        GLU::String seperator = !rSeperator.empty() ? rSeperator : " ";
        
        iMax--;
        
        for(i = 0; i < iMax; ++i)
        {
            oss << rFeatures[i] << seperator;
        } // for
        
        oss << rFeatures[iMax];
        
        string = oss.str();
    } // if
    
    return string;
} // GLUQueryCreateStringFeatures

// OpenGL Apple features as a string, where each feature is separated
// using a seperator string
static GLU::String GLUQueryCreateStringApple(const GLU::String &rSeperator,
                                             const GLU::QueryRef pQuery)
{
    return GLUQueryCreateStringFeatures(rSeperator, pQuery->m_Features.m_Apple);
} // GLUQueryCreateStringApple

// OpenGL ARB features as a string, where each feature is separated
// using a seperator string
static GLU::String GLUQueryCreateStringARB(const GLU::String &rSeperator,
                                           const GLU::QueryRef pQuery)
{
    return GLUQueryCreateStringFeatures(rSeperator, pQuery->m_Features.m_ARB);
} // GLUQueryCreateStringARB

// OpenGL EXT features as a string, where each feature is separated
// using a seperator string
static GLU::String GLUQueryCreateStringEXT(const GLU::String &rSeperator,
                                           const GLU::QueryRef pQuery)
{
    return GLUQueryCreateStringFeatures(rSeperator, pQuery->m_Features.m_EXT);
} // GLUQueryCreateStringEXT

#pragma mark -
#pragma mark Private - Utilities - Arrays

// Found Apple feature
static bool GLUQueryStringIsApple(const GLchar * const pExtension)
{
    return(strncmp(pExtension, GLU::kQueryStringApple, GLU::kQuerySzStringApple) == 0);
} // GLUQueryStringIsApple

// Found ARB feature
static bool GLUQueryStringIsARB(const GLchar * const pExtension)
{
    return(strncmp(pExtension, GLU::kQueryStringARB, GLU::kQuerySzStringARB) == 0);
} // GLUQueryStringIsARB

// Found EXT feature
static bool GLUQueryStringIsEXT(const GLchar * const pExtension)
{
    return(strncmp(pExtension, GLU::kQueryStringEXT, GLU::kQuerySzStringEXT) == 0);
} // GLUQueryStringIsEXT

// Add Apple feature
static void GLUQueryAddFeatureApple(const GLchar * const pFeature,
                                    GLU::QueryRef pQuery)
{
    GLU::String feature(pFeature);
    
    pQuery->m_Features.m_Apple.push_back(feature);
    
    pQuery->m_DB.m_Exts[feature] = GLU::kQueryStringApple;
} // GLUQueryAddFeatureApple

// Add ARB feature
static void GLUQueryAddFeatureARB(const GLchar * const pFeature,
                                  GLU::QueryRef pQuery)
{
    GLU::String feature(pFeature);
    
    pQuery->m_Features.m_ARB.push_back(feature);
    
    pQuery->m_DB.m_Exts[feature] = GLU::kQueryStringARB;
} // GLUQueryAddFeatureARB

// Add EXT feature
static void GLUQueryAddFeatureEXT(const GLchar * const pFeature,
                                  GLU::QueryRef pQuery)
{
    GLU::String feature(pFeature);
    
    pQuery->m_Features.m_EXT.push_back(feature);
    
    pQuery->m_DB.m_Exts[feature] = GLU::kQueryStringEXT;
} // GLUQueryAddFeatureEXT

// Query OpenGL and get a string representation of extension (or feature).
static void GLUQueryAppendFeature(const GLuint &rExtIdx,
                                  GLU::QueryRef pQuery)
{
    const GLchar *pFeature = (const GLchar *)glGetStringi(GL_EXTENSIONS, rExtIdx);
    
    if(pFeature != nullptr)
    {
        if(GLUQueryStringIsApple(pFeature))
        {
            GLUQueryAddFeatureApple(pFeature, pQuery);
        } // if
        else if(GLUQueryStringIsARB(pFeature))
        {
            GLUQueryAddFeatureARB(pFeature, pQuery);
        } // else if
        else if(GLUQueryStringIsEXT(pFeature))
        {
            GLUQueryAddFeatureEXT(pFeature, pQuery);
        } // else if
    } // if
} // GLUQueryAppendFeature

#pragma mark -
#pragma mark Private - Utilities - Destructors

// Clear all strings
static void GLUQueryClearStrings(GLU::QueryRef pQuery)
{
    pQuery->m_String.m_Renderer.clear();
    pQuery->m_String.m_Vendor.clear();
    pQuery->m_String.m_Version.clear();
} // GLUQueryClearStrings

// Clear all features
static void GLUQueryClearFeatures(GLU::QueryRef pQuery)
{
    pQuery->m_Features.m_Apple.clear();
    pQuery->m_Features.m_ARB.clear();
    pQuery->m_Features.m_EXT.clear();
} // GLUQueryClearFeatures

// Release all arrays
static void GLUQueryReleaseArrays(GLU::QueryRef pQuery)
{
    if(pQuery->m_Features.mpApple != nullptr)
    {
        CFRelease(pQuery->m_Features.mpApple);
    } // if
    
    if(pQuery->m_Features.mpARB != nullptr)
    {
        CFRelease(pQuery->m_Features.mpARB);
    } // if
    
    if(pQuery->m_Features.mpEXT != nullptr)
    {
        CFRelease(pQuery->m_Features.mpEXT);
    } // if
} // GLUQueryReleaseArrays

// Clear extensions' map
static void GLUQueryClearDB(GLU::QueryRef pQuery)
{
    pQuery->m_DB.m_Exts.clear();
} // GLUQueryClearDB

#pragma mark -
#pragma mark Private - Utilities - Constructors

// Create a vector of extensions (or features)
static void GLUQueryCreateFeatures(GLU::QueryRef pQuery)
{
    GLuint  nExtIdx = 0;
    GLint   nExtCnt = 0;
    
    glGetIntegerv(GL_NUM_EXTENSIONS, &nExtCnt);
    
    for(nExtIdx = 0; nExtIdx < nExtCnt; ++nExtIdx)
    {
        GLUQueryAppendFeature(nExtIdx, pQuery);
    } // for
    
    pQuery->m_DB.m_ExtsEnd = pQuery->m_DB.m_Exts.end();
    
    pQuery->m_Features.mpApple = nullptr;
    pQuery->m_Features.mpARB   = nullptr;
    pQuery->m_Features.mpEXT   = nullptr;
} // GLUQueryCreateFeatures

// Create vendor, version, and renderer strings
static void GLUQueryCreateStrings(GLU::QueryRef pQuery)
{
    pQuery->m_String.m_Renderer = GLU::StringCreateWithParam(GL_VERSION);
    pQuery->m_String.m_Vendor   = GLU::StringCreateWithParam(GL_VENDOR);
    pQuery->m_String.m_Version  = GLU::StringCreateWithParam(GL_RENDERER);
} // GLUQueryCreateStrings

#pragma mark -
#pragma mark Private - Utilities - Features

// Convert STL vector to CF mutable array
static CFMutableArrayRef GLUQueryFeaturesCreateCopy(const GLU::Features &rFeature)
{
    CFMutableArrayRef pFeatures = nullptr;
    
    GLuint iMax = rFeature.size();
    
    if(iMax)
    {
        pFeatures = CFArrayCreateMutable(kCFAllocatorDefault,
                                         0,
                                         &kCFTypeArrayCallBacks);
        
        if(pFeatures != nullptr)
        {
            CFStringRef pFeature = NULL;
            
            GLuint i;
            
            for(i = 0; i < iMax; ++i)
            {
                pFeature = CFStringCreateWithCString(kCFAllocatorDefault,
                                                     rFeature[i].c_str(),
                                                     kCFStringEncodingASCII);
                
                if(pFeature != nullptr)
                {
                    CFArrayAppendValue(pFeatures, pFeature);
                    
                    CFRelease(pFeature);
                } // if
            } // for
        } // if
    } // if
    
    return pFeatures;
} // GLUQueryFeaturesCreateCopy

#pragma mark -
#pragma mark Public - Constructor

// Create an OpenGL query opaque data reference
GLU::QueryRef GLU::QueryCreate()
{
    GLU::QueryRef pQuery = NULL;
    
    try
    {
        pQuery = new GLU::Query;
        
        GLUQueryCreateFeatures(pQuery);
        GLUQueryCreateStrings(pQuery);
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: Failed allocating memory for OpenGL query object backing store: \"%s\"", ba.what());
    } // catch
    
    return(pQuery);
} // GLUQueryCreate

#pragma mark -
#pragma mark Public - Destructor

// Delete an OpenGL query opaque data reference
void GLU::QueryDelete(GLU::QueryRef pQuery)
{
    if(pQuery != nullptr)
    {
        GLUQueryClearFeatures(pQuery);
        GLUQueryClearStrings(pQuery);
        GLUQueryClearDB(pQuery);
        
        GLUQueryReleaseArrays(pQuery);
        
        delete pQuery;
    } // if
} // GLQueryDelete

#pragma mark -
#pragma mark Public - Accessors - Features

// OpenGL Apple features
const GLU::Features GLU::QueryFeaturesGetApple(const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? pQuery->m_Features.m_Apple : GLU::Features(1);
} // GLU::QueryFeaturesGetApple

// OpenGL ARB features
const GLU::Features GLU::QueryFeaturesGetARB(const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? pQuery->m_Features.m_ARB : GLU::Features(1);
} // GLU::QueryFeaturesGetARB

// OpenGL EXT features
const GLU::Features GLU::QueryFeaturesGetEXT(const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? pQuery->m_Features.m_EXT : GLU::Features(1);
} // GLU::QueryFeaturesGetEXT

#pragma mark -
#pragma mark Public - Accessors - Strings

// OpnGL vendor
const GLU::String GLU::QueryStringGetVendor(const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? pQuery->m_String.m_Vendor : "";
} // GLU::QueryStringGetVendor

// OpenGL version
const GLU::String GLU::QueryStringGetVersion(const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? pQuery->m_String.m_Version : "";
} // GLU::QueryStringGetVersion

// OpenGL renderer
const GLU::String GLU::QueryStringGetRenderer(const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? pQuery->m_String.m_Renderer : "";
} // GLU::QueryStringGetRenderer

// OpenGL Apple features as a string, where each feature
// is separated using a seperator string
const GLU::String GLU::QueryStringGetApple(const GLU::String &rSeperator,
                                           const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? GLUQueryCreateStringApple(rSeperator, pQuery) : "";
} // GLU::QueryStringGetApple

// OpenGL Apple features as a string, where each feature
// is separated using a seperator string
const GLU::String GLU::QueryStringGetARB(const GLU::String &rSeperator,
                                         const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? GLUQueryCreateStringARB(rSeperator, pQuery) : "";
} // GLU::QueryStringGetARB

// OpenGL Apple features as a string, where each feature
// is separated using a seperator string
const GLU::String GLU::QueryStringGetEXT(const GLU::String &rSeperator,
                                         const GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? GLUQueryCreateStringEXT(rSeperator, pQuery) : "";
} // GLU::QueryStringGetEXT

#pragma mark -
#pragma mark Public - Utilities - Arrays

// Apple feature set as an CF array
CFArrayRef GLU::QueryArrayGetApple(GLU::QueryRef pQuery)
{
    if(pQuery->m_Features.mpApple == nullptr)
    {
        pQuery->m_Features.mpApple = GLUQueryFeaturesCreateCopy(pQuery->m_Features.m_Apple);
    } // if
    
    return pQuery->m_Features.mpApple;
} // GLQueryArrayGetApple

// ARB feature set as an CF array
CFArrayRef GLU::QueryArrayGetARB(GLU::QueryRef pQuery)
{
    if(pQuery->m_Features.mpARB == nullptr)
    {
        pQuery->m_Features.mpARB = GLUQueryFeaturesCreateCopy(pQuery->m_Features.m_ARB);
    } // if
    
    return pQuery->m_Features.mpARB;
} // GLQueryArrayGetARB

// EXT feature set as an CF array
CFArrayRef GLU::QueryArrayGetEXT(GLU::QueryRef pQuery)
{
    if(pQuery->m_Features.mpEXT == nullptr)
    {
        pQuery->m_Features.mpEXT = GLUQueryFeaturesCreateCopy(pQuery->m_Features.m_EXT);
    } // if
    
    return pQuery->m_Features.mpEXT;
} // GLQueryArrayGetEXT

#pragma mark -
#pragma mark Public - Utilities - Features

// Is the feature available
const bool GLU::QueryFeatureIsAvailable(const GLU::Feature &rFeature,
                                        GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? pQuery->m_DB.m_Exts.find(rFeature) != pQuery->m_DB.m_ExtsEnd : false;
} // GLQueryFeatureIsAvailable

// If the feature is found, the returned string will be GL_APPLE, GL_ARB, or GL_EXT
const GLU::String GLU::QueryFeatureGetType(const GLU::Feature &rFeature,
                                           GLU::QueryRef pQuery)
{
    return (pQuery != nullptr) ? pQuery->m_DB.m_Exts[rFeature] : "";
} // GLQueryFeatureGetType
