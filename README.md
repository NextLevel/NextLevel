<p><img src="https://raw.github.com/NextLevel/NextLevel/master/NextLevel%402x.png" style="max-width:100%;"></p>

*** in the works… almost fully tested and featured!
*** check back soon or ask how to help!

NextLevel is a media capture library for iOS written in [Swift](https://developer.apple.com/swift/).

[![Build Status](https://travis-ci.org/NextLevel/NextLevel.svg?branch=master)](https://travis-ci.org/NextLevel/NextLevel) 

## Features

- [x] simple and extensible API
- [ ] “[Vine](http://vine.co)-like” video clip recording
- [x] slow motion capture on supported hardware ([iPhone](https://www.apple.com/iphone/compare/), [iPad](https://www.apple.com/ipad/compare/))
- [x] video zoom
- [x] customizable user interface and gestural interactions
- [x] white balance, focus, and exposure adjustment support
- [x] flash/torch support
- [x] mirroring support
- [x] photo capture
- [x] dual camera system support
- [x] [Swift 3](https://developer.apple.com/swift/)

## Quick Start

```ruby

# CocoaPods

pod "NextLevel", "~> 0.0.1"

# Carthage

github "nextlevel/NextLevel" ~> 0.0.1

# Swift PM

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/nextlevel/NextLevel", majorVersion: 0)
    ]
)

```

Alternatively, drop the NextLevel [source files](https://github.com/NextLevel/NextLevel/tree/master/Sources) or project file into your Xcode project.

## Community

NextLevel is a community – contributions and discussions are welcome!

- Feature idea? Open an [issue](https://github.com/nextlevel/NextLevel/issues).
- Found a bug? Open an [issue](https://github.com/nextlevel/NextLevel/issues).
- Need help? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/nextlevel) with the tag ’nextlevel’.
- Questions? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/nextlevel) with the tag 'nextlevel'.
- Want to contribute? Submit a pull request.

### Stickers

If this project was helpful, check out the [standardized](https://terinjokes.github.io/StickerConstructorSpec/) sticker on [Sticker Mule](https://www.stickermule.com/en/marketplace/15145-next-level).

### Complementary Projects

Need a video player?
- [Player (Swift)](https://github.com/piemonte/player)
- [PBJVideoPlayer (obj-c)](https://github.com/piemonte/PBJVideoPlayer)

Need an image processing library?
- [GPUImage2](https://github.com/BradLarson/GPUImage2)

Need an obj-c media capture library?
- [SCRecorder](https://github.com/rFlex/SCRecorder)
- [PBJVision](https://github.com/piemonte/PBJVision)

Need a transcoding library?
- [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter)
- [SDAVAssetExportSession](https://github.com/rs/SDAVAssetExportSession)

## Overview

### Record Video Clips
Import the library.

```swift
import NextLevel
```

Setup the camera preview.

```swift
let screenBounds = UIScreen.main.bounds
self.previewView = UIView(frame: screenBounds)
if let previewView = self.previewView {
       previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
       previewView.backgroundColor = UIColor.black
       previewView.layer.addSublayer(NextLevel.sharedInstance.previewLayer)
       self.view.addSubview(previewView)
}
```

Start, configure, and clean-up the `NextLevel` controller.

```swift
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // modify .videoConfiguration, .photoConfiguration, . audioConfiguration properties, if necessary
        NextLevel.sharedInstance.start()
        // …
    }
```

```swift
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)        
        NextLevel.sharedInstance.stop()
        // …
    }
```

Video Pause/Record

```swift
// pause
NextLevel.sharedInstance.pause(nil)

// record
NextLevel.sharedInstance.record()

// finalize
NextLevel.sharedInstance.completeSession()
```

Handle the output and export the recorded session.

```swift
// TODO
```

### Configure video quality and compression

```swift
// TODO
```

### Configure automatic video duration limit

To enable automatic end of capture, you can specify a maximum duration on the `.videoConfiguration` property.

```swift
NextLevel.sharedInstance.videoConfiguration.maximumCaptureDuration = CMTimeMakeWithSeconds(5, 600)
```

## About

Next Level is just a little weekend project that is still going.

The software provides foundational components for advanced media recording, camera interface customization, and gestural interaction customization on iOS. The same capture capabilities can also be found in apps such as [Snapchat](http://snapchat.com), [Instagram](http://instagram.com), [Vine](http://vine.co), [Peach](http://peach.cool), and others.

If it can provide a good foundation for quick integration, allowing everyone to focus on the functionality that makes the matters most – such as image processing, computer vision apps such as 3D photography or object mapping, augmented reality, depth of field, or even new cinematographic techniques.

## Resources

* [iOS Device Camera Summary](https://developer.apple.com/library/prerelease/content/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Cameras/Cameras.html)
* [AV Foundation Programming Guide](https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html)
* [AV Foundation Framework Reference](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVFoundationFramework/)
* [Swift Evolution](https://github.com/apple/swift-evolution)
* [objc.io Camera and Photos](http://www.objc.io/issue-21/)
* [objc.io Video](http://www.objc.io/issue-23/)
* [Player](https://github.com/piemonte/player), a simple iOS video player in Swift
* [PBJVideoPlayer](https://github.com/piemonte/PBJVideoPlayer), a simple iOS video player in obj-c
* [SCRecorder](https://github.com/rFlex/SCRecorder), obj-C iOS camera engine with Vine-like tap to record, filters, slow motion, segments editing
* [PBJVision](https://github.com/piemonte/PBJVision), obj-c iOS camera engine, features touch-to-record video, slow motion video, and photo capture
* [GPUImage2](https://github.com/BradLarson/GPUImage2), image processing library in Swift
* [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter), media export and transcoding library

## License

NextLevel is available under the MIT license, see the [LICENSE](https://github.com/NextLevel/NextLevel/blob/master/LICENSE) file for more information.
