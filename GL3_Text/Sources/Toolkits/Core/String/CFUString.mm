/*
     File: CFUString.mm
 Abstract: 
 Utility toolkit for converting CF strings to STL strings or c-strings.
 
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

// STL streams
#import <string>

// OpenGL string utilities
#import "CFString.h"

#pragma mark -
#pragma mark Public - Utilities

// Create a c-string from a CF string opaque reference
GLchar *CF::StringCreateBufferCopy(CFStringRef pString)
{
    GLchar *pBuffer = nullptr;
    
    if(pString != nullptr)
    {
        size_t nLength = CFStringGetLength(pString);
        
        if(nLength)
        {
			static const size_t kSizeUniChar = sizeof(UniChar);
			
            // Even though we're requesting a c-string, the
            // buffer length must be equal to the length of
            // a UniChar buffer.
            
            size_t nSize = nLength * kSizeUniChar;
            
            try
            {
                pBuffer = new char[nSize];
                
                CFStringGetCString(pString,
                                   pBuffer,
                                   nSize,
                                   kCFStringEncodingUTF8);
            } // try
            catch(std::bad_alloc& ba)
            {
                NSLog(@">> ERROR: CF String Create Buffer Copy - Failed allocating a buffer for copy: \"%s\"", ba.what());
            } // catch
        } // if
        else
        {
            NSLog(@">> ERROR: CF String Create Buffer Copy - CF String reference is zero length!");
        } // else
    } // if
    
	return(pBuffer);
} // CFStringCreateBufferCopy

// Create a STL string from a CF string opaque reference
std::string CF::StringCreateCStringCopy(CFStringRef pString)
{
    std::string buffer = "";
    
    char *pBuffer = CF::StringCreateBufferCopy(pString);
    
    if(pBuffer != nullptr)
    {
        buffer = pBuffer;
        
        delete [] pBuffer;
    } // if
    else
    {
        NSLog(@">> ERROR: CF String Create String Copy - Failed allocating a buffer for string reference conversion!");
    } // else
    
	return(buffer);
} // CFStringCreateStringCopy
