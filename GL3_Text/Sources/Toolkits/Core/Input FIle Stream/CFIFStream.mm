/*
     File: CFIFStream.mm
 Abstract: 
 A toolkit for managing input file streams (such as vertex, fragment, or geometry shader ascii text files).
 
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

// STL containers
#import <iostream>
#import <fstream>

// String copy utilities
#import "CFString.h"

// OpenGL input file stream
#import "CFIFStream.h"

#pragma mark -
#pragma mark Private - Data Structures

namespace CF
{
    // Input file stream structure
    struct IFStream
    {
        bool    mbIsValid;
        Buffer  mpBuffer;
        size_t  mnLength;
        
        std::string    m_Pathname;
        std::ifstream  m_Stream;
    };
    
    typedef struct IFStream IFStream;
} // CF

#pragma mark -
#pragma mark Private - Utilities - Destructors

static void CFIFStreamDeleteBuffer(CF::IFStreamRef pIFStream)
{
    if(pIFStream->mpBuffer != nullptr)
    {
        delete [] pIFStream->mpBuffer;
    } // if
} // IFStreamDeleteBuffer

static void CFIFStreamCloseStream(CF::IFStreamRef pIFStream)
{
    if(pIFStream->m_Stream.is_open())
    {
        pIFStream->m_Stream.close();
    } // if
} // CFIFStreamCloseStream

static void CFIFStreamClearPathname(CF::IFStreamRef pIFStream)
{
    pIFStream->m_Pathname.clear();
} // CFIFStreamClearPathname

static void CFIFStreamDelete(CF::IFStreamRef pIFStream)
{
    CFIFStreamDeleteBuffer(pIFStream);
    CFIFStreamCloseStream(pIFStream);
    CFIFStreamClearPathname(pIFStream);
    
    delete pIFStream;
} // CFIFStreamDelete

#pragma mark -
#pragma mark Private - Utilities - Constructors

static bool CFIFStreamRead(CF::IFStreamRef pIFStream)
{
    pIFStream->mnLength = pIFStream->m_Stream.tellg();
    
    bool bSuccess = bool(pIFStream->mnLength);
    
    if(bSuccess)
    {
        try
        {
            pIFStream->mpBuffer = new GLchar[pIFStream->mnLength];
            
            pIFStream->m_Stream.seekg(0, std::ios::beg);
            
            pIFStream->m_Stream.read(pIFStream->mpBuffer, pIFStream->mnLength);
            pIFStream->m_Stream.close();
        } // try
        catch(std::bad_alloc& ba)
        {
            NSLog(@">> ERROR: Core Foundation File - Failed allocating buffer memory: \"%s\"", ba.what());
            
            bSuccess = false;
        } // catch
    } // if
    else
    {
        NSLog(@">> ERROR: Core Foundation File - File has size 0!");
    } // else
    
    return bSuccess;
} // CFIFStreamRead

static void CFIFStreamAcquire(CF::IFStreamRef pIFStream)
{
    pIFStream->m_Stream.open(pIFStream->m_Pathname.c_str(),
                             std::ios::in|std::ios::binary|std::ios::ate);
    
    pIFStream->mbIsValid = pIFStream->m_Stream.is_open();
    
    if(pIFStream->mbIsValid)
    {
        pIFStream->mbIsValid = CFIFStreamRead(pIFStream);
    } // if
    else
    {
        NSLog(@">> ERROR: Core Foundation File - Failed opening the file \"%s\"!", pIFStream->m_Pathname.c_str());
    } // else
    
    if(!pIFStream->mbIsValid)
    {
        CFIFStreamCloseStream(pIFStream);
    } // if
} // CFIFStreamAcquire

static CF::IFStreamRef CFIFStreamCreate(const std::string& rPathname)
{
    CF::IFStreamRef pIFStream = nullptr;
    
    if(!rPathname.empty())
    {
        try
        {
            pIFStream = new CF::IFStream;
            
            pIFStream->m_Pathname = rPathname;
            pIFStream->mpBuffer   = nullptr;
            pIFStream->mnLength   = 0;
            
            CFIFStreamAcquire(pIFStream);
        } // try
        catch(std::bad_alloc& ba)
        {
            NSLog(@">> ERROR: ERROR: Core Foundation File - Failed creating a backing store: \"%s\"", ba.what());
        } // catch
    } // if
    
    return pIFStream;
} // CFIFStreamCreate

static CF::IFStreamRef CFIFStreamCreate(CFStringRef pPathname)
{
    const std::string pathname = CF::StringCreateCStringCopy(pPathname);
    
    return CFIFStreamCreate(pathname);
} // CFIFStreamCreate

#pragma mark -
#pragma mark Public - Constructors

// Create a file object from a stl string pathname
CF::IFStreamRef CF::IFStreamCreate(const std::string &rPathname)
{
    return CFIFStreamCreate(rPathname);
} // CFIFStreamCreate

CF::IFStreamRef CF::IFStreamCreate(CFStringRef pPathname)
{
    return CFIFStreamCreate(pPathname);
} // CFIFStreamCreate

#pragma mark -
#pragma mark Public - Copy Constructor

// Deep copy constructor
CF::IFStreamRef CF::IFStreamCreateCopy(const CF::IFStreamRef pIFStreamSrc)
{
    CF::IFStreamRef pIFStreamDst = nullptr;
    
    if(pIFStreamSrc != nullptr)
    {
        pIFStreamDst = CFIFStreamCreate(pIFStreamSrc->m_Pathname);
    } // if
    
    return pIFStreamDst;
} // IFStreamCreateCopy

#pragma mark -
#pragma mark Public - Destructor

void CF::IFStreamDelete(CF::IFStreamRef pIFStream)
{
    if(pIFStream != nullptr)
    {
        CFIFStreamDelete(pIFStream);
    } // if
} // IFStreamDelete

#pragma mark -
#pragma mark Public - Query

bool CF::IFStreamIsValid(const CF::IFStreamRef pIFStream)
{
    return (pIFStream != nullptr) ? pIFStream->mbIsValid : false;
} // IFStreamIsValid

#pragma mark -
#pragma mark Public - Accessors

const std::string CF::IFStreamGetPathname(const CF::IFStreamRef pIFStream)
{
    return (pIFStream != nullptr) ? pIFStream->m_Pathname : "";
} // IFStreamGetPathname

const CF::Buffer CF::IFStreamGetBuffer(const CF::IFStreamRef pIFStream)
{
    return (pIFStream != nullptr) ? pIFStream->mpBuffer : nullptr;
} // IFStreamGetBuffer

const size_t CF::IFStreamGetLength(const CF::IFStreamRef pIFStream)
{
    return (pIFStream != nullptr) ? pIFStream->mnLength : 0;
} // IFStreamGetBuffer

