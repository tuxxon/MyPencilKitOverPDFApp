[![Swift](https://img.shields.io/badge/Swift-5.7_5.8-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.7_5.8-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_16-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-iOS_16-yellowgreen?style=flat-square)

Refer to: https://github.com/GuillaumeRossit/MyPencilKitOverPDFApp

# MyPencilKitOverPDFApp
Demonstrates use of PDFPageOverlayViewProvider to use PencikKit over PDFKit as shown in wwdc2022-10089.

<https://developer.apple.com/videos/play/wwdc2022/10089/>

## Current Issue

The current issue is:
1. When "Draw Box Off" is enabled, the drawing works correctly.  
2. However, when "Draw Box On" is enabled:
    - Drawing should be disabled  ===> Ok
    - The `handleDrag()` should be triggered when drawing with one finger or with the pencil, but currently, it only works when using two fingers or a combination of one finger + pencil.
3. This issue started occurring after upgrading from iOS 17.6 to iOS 18.0.