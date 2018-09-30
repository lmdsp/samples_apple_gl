# macos Mojave + OpenGL blank screen debugging 

Archive of some official [Apple OpenGL sample code samples](https://developer.apple.com/library/archive/navigation/#section=Technologies&topic=OpenGL)

Updated for XCode 10 / macOS 10.14 SDK

- [BasicMultiGPUSample - Detecting OpenGL Renderer Changes](https://developer.apple.com/library/archive/samplecode/BasicMultiGPUSample/Introduction/Intro.html#//apple_ref/doc/uid/DTS40010094)
- [GL3 Text](https://developer.apple.com/library/archive/samplecode/GL3_Text/Introduction/Intro.html#//apple_ref/doc/uid/DTS40013069)

## Details

To isolate the cause of the problem I then:

- downloaded some official Apple OpenGL code samples
- updated the projects with no source code changes at all
- built them using XCode10 + macOS 10.14 SDK + 10.8 deployment target
- uploaded this to a [git repo](https://bitbucket.org/lorcan/samples_apple_gl).

Both samples run fine on 10.13 High Sierra, however BasicMultiGPUSample doesn't display any GL content on Mojave, whilst GL3Text does. 
Interestingly BasicMultiGPUSample uses both an `NSOpenGLView` and a custom `NSView` holding GL context.

So clearly Apple have changed/broken the runtime behavior of OpenGL on Mojave, as some of their own samples, supposedly following best practices, don't work anymore.

There is a hint in AppKit Release Notes for [macOS 10.14/Layer-Backed Views](https://developer.apple.com/documentation/appkit/appkit_release_notes_for_macos_10_14?language=objc):

> Windows in apps linked against the macOS 10.14 SDK are displayed using Core Animation when the app is running in macOS 10.14. 
> This doesn't mean that all views are layer-backed; rather, it means that all views are either layer-backed or draw into a shared layer with other layers.

I've tried setting `setWantsLayer: YES` on my custom `NSView` as described in [Changes to subview drawing? - display works again but with severe flicker](https://forums.developer.apple.com/thread/107655).

Unfortunately I wasn't able to pinpoint the root cause of the problem and even less find a proper fix or workaround.

Since broadly used projects apparently suffer from the same issue, a solution should hopefully be found rather sooner than later:

- [[macOS]GLFW can't draw any content automatically from beginning on macOS 10.14 #1334](https://github.com/glfw/glfw/issues/1334#issuecomment-425172189)
- [Stuttering movement and black screen on macOS 10.14 and Cocos2d-x 3.17 #19080](https://github.com/cocos2d/cocos2d-x/issues/19080)

Same problem with OpenGL + Mojave too, using a custom `NSView` holding an `NSOpenGLContext`. 
This is working fine in all previous macOS versions.
All GL content gets drawn to the backbuffer alright,
which was cross-verified using a `glReadPixels()` call before flushing and
with the help of [apitrace](http://apitrace.github.io/) and [Intel Graphics Performance Analyzers](https://software.intel.com/en-us/gpa/).

