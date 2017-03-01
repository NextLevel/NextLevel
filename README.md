<p><img src="https://raw.github.com/NextLevel/NextLevel/master/NextLevel%402x.png" alt="Next Level" style="max-width:100%;"></p>

Next Level is a media capture camera library for iOS written in [Swift](https://developer.apple.com/swift/).

[![Build Status](https://travis-ci.org/NextLevel/NextLevel.svg?branch=master)](https://travis-ci.org/NextLevel/NextLevel) [![Pod Version](https://img.shields.io/cocoapods/v/NextLevel.svg?style=flat)](http://cocoadocs.org/docsets/NextLevel/) [![Swift Version](https://img.shields.io/badge/language-swift%203.0-brightgreen.svg)](https://developer.apple.com/swift) [![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/NextLevel/NextLevel/blob/master/LICENSE)

|  | Features |
|:---------:|:---------------------------------------------------------------|
| &#127916; | “[Vine](http://vine.co)-like” video clip recording and editing |
| &#128444; | photo capture (raw, jpeg, and from a video frame) |
| &#128070; | customizable gestural interaction and user interface |
| &#128247; | dual camera, wide angle, and telephoto device support |
| &#128034; | adjustable frame rate on supported hardware (ie fast/slow motion capture) |
| &#128269; | video zoom |
| &#9878; | white balance, focus, and exposure adjustment |
| &#128294; | flash and torch support |
| &#128111; | mirroring support |
| &#9728; | low light boost |
| &#128374; | smooth auto-focus |
| &#9881; | configurable encoding and compression settings |
| &#128736; | simple media capture and editing API |
| &#127744; | extensible API for image processing and CV |
| &#128038; | [Swift 3](https://developer.apple.com/swift/) |

## Quick Start

```ruby

# CocoaPods
swift_version = "3.0"
pod "NextLevel", "~> 0.3.5"

# Carthage
github "nextlevel/NextLevel" ~> 0.3.5

# Swift PM
let package = Package(
    dependencies: [
        .Package(url: "https://github.com/nextlevel/NextLevel", majorVersion: 0)
    ]
)

```

Alternatively, drop the NextLevel [source files](https://github.com/NextLevel/NextLevel/tree/master/Sources) or project file into your Xcode project.

## Overview

Before starting, ensure that permission keys have been added to your app's `Info.plist`.

```xml
<key>NSCameraUsageDescription</key>
    <string>Allowing access to the camera lets you take photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
    <string>Allowing access to the microphone lets you record audio.</string>
```

### Recording Video Clips

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
    NextLevel.shared.previewLayer.frame = previewView.bounds
    previewView.layer.addSublayer(NextLevel.shared.previewLayer)
    self.view.addSubview(previewView)
}
```

Configure the capture session.

```swift
override func viewDidLoad() {
    NextLevel.shared.delegate = self
    NextLevel.shared.deviceDelegate = self
    NextLevel.shared.videoDelegate = self
    NextLevel.shared.photoDelegate = self
    
    // modify .videoConfiguration, .audioConfiguration, .photoConfiguration properties
    // Compression, resolution, and maximum recording time options are available
    NextLevel.shared.videoConfiguration.maxRecordDuration = CMTimeMakeWithSeconds(5, 600)
    NextLevel.shared.audioConfiguration.bitRate = 44000
 }
```

Start/stop the session when appropriate. These methods create a new "session" instance for 'NextLevel.shared.session' when called.

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)     
    NextLevel.shared.start()
    // …
}
```

```swift
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)        
    NextLevel.shared.stop()
    // …
}
```

Video record/pause.

```swift
// record
NextLevel.shared.record()

// pause
NextLevel.shared.pause()
```

### Editing Recorded Clips

Editing and finalizing the recorded session.
```swift

if let session = NextLevel.shared.session {

    //..

    // undo
    session.removeLastClip()

    // various editing operations can be done using the NextLevelSession methods

    // export
    session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality, completionHandler: { (url: URL?, error: Error?) in
        if let _ = url {
            //
        } else if let _ = error {
            //
        }
     })

    //..

}
```
Videos can also be processed using the [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter), a media transcoding library in Swift.

## Custom Buffer Rendering

‘NextLevel’ was designed for sample buffer analysis and custom modification in real-time along side a rich set of camera features. 

Just to note, modifications performed on a buffer and provided back to NextLevel may potentially effect frame rate.

Enable custom rendering.

```swift
NextLevel.shared.isVideoCustomContextRenderingEnabled = true
```

Optional hook that allows reading `sampleBuffer` for analysis.

```swift
extension CameraViewController: NextLevelVideoDelegate {
    
    // ...

    // video frame processing
    public func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        // Use the sampleBuffer parameter in your system for continual analysis
    }
```

Another optional hook for reading buffers for modification, `imageBuffer`. This is also the recommended place to provide the buffer back to NextLevel for recording.

```swift
extension CameraViewController: NextLevelVideoDelegate {

    // ...

    // enabled by isCustomContextVideoRenderingEnabled
    public func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
		    // provide the frame back to NextLevel for recording
        if let frame = self._availableFrameBuffer {
            nextLevel.videoCustomContextImageBuffer = frame
        }
    }
```

NextLevel will check this property when writing buffers to a destination file. This works for both video and photos with `capturePhotoFromVideo`.

```swift
nextLevel.videoCustomContextImageBuffer = modifiedFrame
```

## Documentation

You can find [the docs here](https://nextlevel.github.io/NextLevel). Documentation is generated with [jazzy](https://github.com/realm/jazzy) and hosted on [GitHub-Pages](https://pages.github.com).

## About

Next Level was a little weekend project that turned into something more useful. The software provides foundational components for advanced media recording, camera interface customization, and gestural interaction customization for iOS. The same capabilities can also be found in apps such as [Snapchat](http://snapchat.com), [Instagram](http://instagram.com), and [Vine](http://vine.co).

The goal is to continue to provide a good foundation for quick integration (taking you to the next level) – allowing everyone to focus on the app functionality that matters most. My hope is the app functionality that matters most whether is be realtime image processing, computer vision methods, augmented reality, or even new cinematographic recording techniques benefit from how this library is structured.

### Related Projects

- [Player (Swift)](https://github.com/piemonte/player), video player in Swift
- [PBJVideoPlayer (obj-c)](https://github.com/piemonte/PBJVideoPlayer), video player in obj-c
- [GPUImage2](https://github.com/BradLarson/GPUImage2), image processing library
- [SCRecorder](https://github.com/rFlex/SCRecorder), obj-c capture library
- [PBJVision](https://github.com/piemonte/PBJVision), obj-c capture library
- [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter), media transcoding in Swift

## Community

NextLevel is a community – contributions and discussions are welcome!

### Project

- Feature idea? Open an [issue](https://github.com/nextlevel/NextLevel/issues).
- Found a bug? Open an [issue](https://github.com/nextlevel/NextLevel/issues).
- Need help? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/nextlevel) with the tag ’nextlevel’.
- Questions? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/nextlevel) with the tag 'nextlevel'.
- Want to contribute? Submit a pull request.

### Stickers

If you found this project to be helpful, check out the [Next Level stickers](https://www.stickermule.com/en/user/1070732101/stickers).

You can use this sign up [link](https://www.stickermule.com/unlock?ref_id=1012370701) for a $10 [credit](https://www.stickermule.com/unlock?ref_id=1012370701).

If other projects have interest in providing a similar hex sticker, it conforms to the [sticker standard](https://terinjokes.github.io/StickerConstructorSpec/) used by several node projects. 

## Resources

* [iOS Device Camera Summary](https://developer.apple.com/library/prerelease/content/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Cameras/Cameras.html)
* [AV Foundation Programming Guide](https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html)
* [AV Foundation Framework Reference](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVFoundationFramework/)
* [Swift Evolution](https://github.com/apple/swift-evolution)
* [objc.io Camera and Photos](http://www.objc.io/issue-21/)
* [objc.io Video](http://www.objc.io/issue-23/)
* [objc.io Core Image and Video](https://www.objc.io/issues/23-video/core-image-video/)
* [Cameras, ecommerce and machine learning](http://ben-evans.com/benedictevans/2016/11/20/ku6omictaredoge4cao9cytspbz4jt)
* [Again, iPhone is the default camera](http://om.co/2016/12/07/again-iphone-is-the-default-camera/)

## License

NextLevel is available under the MIT license, see the [LICENSE](https://github.com/NextLevel/NextLevel/blob/master/LICENSE) file for more information.
