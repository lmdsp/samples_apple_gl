/*
     File: GLUTexture.mm
 Abstract: 
 Utility toolkit for generating an OpenGL textures from strings.
 
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

// OpenGL utilities header
#import "GLUTexture.h"

#pragma mark -
#pragma mark Private - Utilities - CF

// Create an attributed string from a CF string, font, justification, and font size
static CFMutableAttributedStringRef CFMutableAttributedStringCreate(CFStringRef pString,
                                                                    CFStringRef pFontNameSrc,
                                                                    CGColorRef pComponents,
                                                                    const CGFloat& rFontSize,
                                                                    const CTTextAlignment nAlignment,
                                                                    CFRange *pRange)
{
    CFMutableAttributedStringRef pAttrString = nullptr;
    
    if(pString != nullptr)
    {
        // Paragraph style setting structure
        const GLuint nCntStyle = 2;
        
        // For single spacing between the lines
        const CGFloat nLineHeightMultiple = 1.0f;
        
        // Paragraph settings with alignment and style
        CTParagraphStyleSetting settings[nCntStyle] =
        {
            {
                kCTParagraphStyleSpecifierAlignment,
                sizeof(CTTextAlignment),
                &nAlignment
            },
            {
                kCTParagraphStyleSpecifierLineHeightMultiple,
                sizeof(CGFloat),
                &nLineHeightMultiple
            }
        };
        
        // Create a paragraph style
        CTParagraphStyleRef pStyle = CTParagraphStyleCreate(settings, nCntStyle);
        
        if(pStyle != nullptr)
        {
            // If the font name is nullptr default to Helvetica
            CFStringRef pFontNameDst = (pFontNameSrc) ? pFontNameSrc : CFSTR("Helvetica");
            
            // Prepare font
            CTFontRef pFont = CTFontCreateWithName(pFontNameDst, rFontSize, nullptr);
            
            if(pFont != nullptr)
            {
                // Set attributed string properties
                const GLuint nCntDict = 3;
                
                CFStringRef keys[nCntDict] =
                {
                    kCTParagraphStyleAttributeName,
                    kCTFontAttributeName,
                    kCTForegroundColorAttributeName
                };
                
                CFTypeRef values[nCntDict] =
                {
                    pStyle,
                    pFont,
                    pComponents
                };
                
                // Create a dictionary of attributes for our string
                CFDictionaryRef pAttributes = CFDictionaryCreate(nullptr,
                                                                 (const void **)&keys,
                                                                 (const void **)&values,
                                                                 nCntDict,
                                                                 &kCFTypeDictionaryKeyCallBacks,
                                                                 &kCFTypeDictionaryValueCallBacks);
                
                if(pAttributes != nullptr)
                {
                    // Creating a mutable attributed string
                    pAttrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
                    
                    if(pAttrString != nullptr)
                    {
                        // Set a mutable attributed string with the input string
                        CFAttributedStringReplaceString(pAttrString, CFRangeMake(0, 0), pString);
                        
                        // Compute the mutable attributed string range
                        *pRange = CFRangeMake(0, CFAttributedStringGetLength(pAttrString));
                        
                        // Set the attributes
                        CFAttributedStringSetAttributes(pAttrString, *pRange, pAttributes, NO);
                    } // if
                    
                    CFRelease(pAttributes);
                } // if
                
                CFRelease(pFont);
            } // if
            
            CFRelease(pStyle);
        } // if
    } // if
    
    return pAttrString;
} // CFMutableAttributedStringCreate

#pragma mark -
#pragma mark Private - Utilities - CG

// Create a bitmap context from a string, font, justification, and font size
static CGContextRef CGContextCreateFromAttributedString(CFAttributedStringRef pAttrString,
                                                        const CFRange& rRange,
                                                        CGColorSpaceRef pColorspace,
                                                        NSSize& rSize)
{
    CGContextRef pContext = nullptr;
    
    if(pAttrString != nullptr)
    {
        // Acquire a frame setter
        CTFramesetterRef pFrameSetter = CTFramesetterCreateWithAttributedString(pAttrString);
        
        if(pFrameSetter != nullptr)
        {
            // Create a path for layout
            CGMutablePathRef pPath = CGPathCreateMutable();
            
            if(pPath != nullptr)
            {
                CFRange range;
                CGSize  constraint = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
                
                // Get the CoreText suggested size from our framesetter
                rSize = CTFramesetterSuggestFrameSizeWithConstraints(pFrameSetter,
                                                                     rRange,
                                                                     nullptr,
                                                                     constraint,
                                                                     &range);
                
                // Set path bounds
                CGRect bounds = CGRectMake(0.0f,
                                           0.0f,
                                           rSize.width,
                                           rSize.height);
                
                // Bound the path
                CGPathAddRect(pPath, nullptr, bounds);
                
                // Layout the attributed string in a frame
                CTFrameRef pFrame = CTFramesetterCreateFrame(pFrameSetter, range, pPath, nullptr);
                
                if(pFrame != nullptr)
                {
                    // Compute bounds for the bitmap context
                    size_t width  = size_t(rSize.width);
                    size_t height = size_t(rSize.height);
                    size_t stride = sizeof(GLuint) * width;
                    
                    // No explicit backing-store allocation here.  We'll let the
                    // context allocate the storage for us.
                    pContext = CGBitmapContextCreate(nullptr,
                                                     width,
                                                     height,
                                                     8,
                                                     stride,
                                                     pColorspace,
                                                     kCGImageAlphaPremultipliedLast);
                    
                    if(pContext != nullptr)
                    {
                        // Use this for vertical reflection
                        CGContextTranslateCTM(pContext, 0.0, height);
                        CGContextScaleCTM(pContext, 1.0, -1.0);
                        
                        // Draw the frame into a bitmap context
                        CTFrameDraw(pFrame, pContext);
                        
                        // Flush the context
                        CGContextFlush(pContext);
                    } // if
                    
                    // Release the frame
                    CFRelease(pFrame);
                } // if
                
                CFRelease(pPath);
            } // if
            
            CFRelease(pFrameSetter);
        } // if
    } // if
    
    return pContext;
} // CGContextCreateFromString

// Create a bitmap context from a core foundation string, font,
// justification, and font size
static CGContextRef CGContextCreateFromString(CFStringRef pString,
                                              CFStringRef pFontName,
                                              const CGFloat& rFontSize,
                                              const CTTextAlignment& rAlignment,
                                              const CGFloat * const pComponents,
                                              NSSize &rSize)
{
    CGContextRef pContext = nullptr;
    
    if(pString != nullptr)
    {
        // Get a generic linear RGB color space
        CGColorSpaceRef pColorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
        
        if(pColorspace != nullptr)
        {
            // Create a white color reference
            CGColorRef pColor = CGColorCreate(pColorspace, pComponents);
            
            if(pColor != nullptr)
            {
                // Creating a mutable attributed string
                CFRange range;
                
                CFMutableAttributedStringRef pAttrString = CFMutableAttributedStringCreate(pString,
                                                                                           pFontName,
                                                                                           pColor,
                                                                                           rFontSize,
                                                                                           rAlignment,
                                                                                           &range);
                
                if(pAttrString != nullptr)
                {
                    // Create a context from our attributed string
                    pContext = CGContextCreateFromAttributedString(pAttrString,
                                                                   range,
                                                                   pColorspace,
                                                                   rSize);
                    
                    CFRelease(pAttrString);
                } // if
                
                CFRelease(pColor);
            } // if
            
            CFRelease(pColorspace);
        } // if
    } // if
    
    return pContext;
} // CGContextCreateFromString

// Create a bitmap context from a c-string, font, justification, and font size
static CGContextRef CGContextCreateFromString(const GLchar * const pString,
                                              const GLchar * const pFontName,
                                              const CGFloat& rFontSize,
                                              const CTTextAlignment& rAlignment,
                                              const CGFloat * const pComponents,
                                              NSSize& rSize)
{
    CGContextRef pContext = nullptr;
    
    if(pString != nullptr)
    {
        CFStringRef pCFString = CFStringCreateWithCString(kCFAllocatorDefault,
                                                          pString,
                                                          kCFStringEncodingASCII);
        
        if(pCFString != nullptr)
        {
            const GLchar *pFontString = (pFontName) ? pFontName : "Helvetica";
            
            CFStringRef pFontCFString = CFStringCreateWithCString(kCFAllocatorDefault,
                                                                  pFontString,
                                                                  kCFStringEncodingASCII);
            
            if(pFontCFString != nullptr)
            {
                pContext = CGContextCreateFromString(pCFString,
                                                     pFontCFString,
                                                     rFontSize,
                                                     rAlignment,
                                                     pComponents,
                                                     rSize);
                
                CFRelease(pFontCFString);
            } // if
            
            CFRelease(pCFString);
        } // if
    } // if
    
    return pContext;
} // CGContextCreateFromString

#pragma mark -
#pragma mark Private - Utilities - OpenGL - Textures

// Create a 2D texture
static GLuint GLUTexture2DCreate(const GLuint& rWidth,
                                 const GLuint& rHeight,
                                 const GLvoid * const pPixels)
{
    GLuint nTID = 0;
    
    // Greate a texture
    glGenTextures(1, &nTID);
    
    if(nTID)
    {
        // Bind a texture with ID
        glBindTexture(GL_TEXTURE_2D, nTID);
        
        // Set texture properties (including linear mipmap)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // Initialize the texture
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_RGBA,
                     rWidth,
                     rHeight,
                     0,
                     GL_RGBA,
                     GL_UNSIGNED_INT_8_8_8_8_REV,
                     pPixels);
        
        // Generate mipmaps
        glGenerateMipmap(GL_TEXTURE_2D);
        
        // Discard
        glBindTexture(GL_TEXTURE_2D, 0);
    } // if
    
    return nTID;
} // GLUTexture2DCreate

// Create a texture from a bitmap context
static GLuint GLUTexture2DCreateFromContext(CGContextRef pContext)
{
    GLuint nTID = 0;
    
    if(pContext != nullptr)
    {
        GLuint nWidth  = GLuint(CGBitmapContextGetWidth(pContext));
        GLuint nHeight = GLuint(CGBitmapContextGetHeight(pContext));
        
        const GLvoid *pPixels = CGBitmapContextGetData(pContext);
        
        nTID = GLUTexture2DCreate(nWidth, nHeight, pPixels);
        
        // Was there a GL error?
        GLenum nErr = glGetError();
        
        if(nErr != GL_NO_ERROR)
        {
            NSLog(@">> OpenGL Error: %04x caught at %s:%u", nErr, __FILE__, __LINE__);
            
            glDeleteTextures(1, &nTID);
            
            nTID = 0;
        } // if
    } // if
    
    return nTID;
} // GLUTexture2DCreateFromContext

#pragma mark -
#pragma mark Public - Constructors

// Generate a texture from a core foundation attributed string
GLuint GLU::Texture2DCreateFromString(CFAttributedStringRef pAttrString,
                                      const CFRange& rRange,
                                      NSSize& rSize)
{
    GLuint nTID = 0;
    
    if(pAttrString != nullptr)
    {
        // Get a generic linear RGB color space
        CGColorSpaceRef pColorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
        
        if(pColorspace != nullptr)
        {
            CGContextRef pCtx = CGContextCreateFromAttributedString(pAttrString,
                                                                    rRange,
                                                                    pColorspace,
                                                                    rSize);
            
            if(pCtx != nullptr)
            {
                nTID = GLUTexture2DCreateFromContext(pCtx);
                
                CGContextRelease(pCtx);
            } // if
            
            CFRelease(pColorspace);
        } // if
    } // if
    
    return nTID;
} // GLUTexture2DCreateFromString

// Generate a texture from a core foundation string, using a font, at a size,
// with alignment and color
GLuint GLU::Texture2DCreateFromString(CFStringRef pString,
                                      CFStringRef pFontName,
                                      const CGFloat& rFontSize,
                                      const CTTextAlignment& rAlignment,
                                      const CGFloat * const pColor,
                                      NSSize &rSize)
{
    GLuint nTID = 0;
    
    CGContextRef pCtx = CGContextCreateFromString(pString,
                                                  pFontName,
                                                  rFontSize,
                                                  rAlignment,
                                                  pColor,
                                                  rSize);
    
    if(pCtx != nullptr)
    {
        nTID = GLUTexture2DCreateFromContext(pCtx);
        
        CGContextRelease(pCtx);
    } // if
    
    return nTID;
} // GLUTexture2DCreateFromString

// Generate a texture from a cstring, using a font, at a size,
// with alignment and color
GLuint GLU::Texture2DCreateFromString(const GLchar * const pString,
                                      const GLchar * const pFontName,
                                      const CGFloat& rFontSize,
                                      const CTTextAlignment& rAlignment,
                                      const CGFloat * const pColor,
                                      NSSize& rSize)
{
    GLuint nTID = 0;
    
    CGContextRef pCtx = CGContextCreateFromString(pString,
                                                  pFontName,
                                                  rFontSize,
                                                  rAlignment,
                                                  pColor,
                                                  rSize);
    
    if(pCtx != nullptr)
    {
        nTID = GLUTexture2DCreateFromContext(pCtx);
        
        CGContextRelease(pCtx);
    } // if
    
    return nTID;
} // GLUTexture2DCreateFromString

// Generate a texture from a stl string, using a font, at a size,
// with an alignment and a color
GLuint GLU::Texture2DCreateFromString(const GLU::String& rString,
                                      const GLU::String& rFontName,
                                      const CGFloat& rFontSize,
                                      const CTTextAlignment& rAlignment,
                                      const CGFloat * const pColor,
                                      NSSize& rSize)
{
    return GLU::Texture2DCreateFromString(rString.c_str(),
                                          rFontName.c_str(),
                                          rFontSize,
                                          rAlignment,
                                          pColor,
                                          rSize);
} // GLUTexture2DCreateFromString