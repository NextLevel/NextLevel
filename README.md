<p><img src="https://raw.github.com/NextLevel/NextLevel/master/NextLevel%402x.png" alt="Next Level" style="max-width:100%;"></p>

`NextLevel` is a [Swift](https://developer.apple.com/swift/) camera system designed for easy integration, customized media capture, and image streaming in iOS. Integration can optionally leverage `AVFoundation` or `ARKit`.

[![Build Status](https://travis-ci.org/NextLevel/NextLevel.svg?branch=master)](https://travis-ci.org/NextLevel/NextLevel) [![Pod Version](https://img.shields.io/cocoapods/v/NextLevel.svg?style=flat)](http://cocoadocs.org/docsets/NextLevel/) [![Swift Version](https://img.shields.io/badge/language-swift%205.0-brightgreen.svg)](https://developer.apple.com/swift) [![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/NextLevel/NextLevel/blob/master/LICENSE)

|  | Features |
|:---------:|:---------------------------------------------------------------|
| &#127916; | “[Vine](http://vine.co)-like” video clip recording and editing |
| &#128444; | photo capture (raw, jpeg, and video frame) |
| &#128070; | customizable gestural interaction and interface |
| &#128160; | [ARKit integration](https://developer.apple.com/arkit/) (beta) |
| &#128247; | dual, wide angle, telephoto, & true depth support |
| &#128034; | adjustable frame rate on supported hardware (ie fast/slow motion capture) |
| &#127906; | depth data capture support & portrait effects matte support |
| &#128269; | video zoom |
| &#9878; | white balance, focus, and exposure adjustment |
| &#128294; | flash and torch support |
| &#128111; | mirroring support |
| &#9728; | low light boost |
| &#128374; | smooth auto-focus |
| &#9881; | configurable encoding and compression settings |
| &#128736; | simple media capture and editing API |
| &#127744; | extensible API for image processing and CV |
| &#128008; | animated GIF creator |
| &#128526; | face recognition; qr- and bar-codes recognition |
| &#128038; | [Swift 5](https://developer.apple.com/swift/) |

Need a different version of Swift?
* `5.0` - Target your Podfile to the latest release or master
* `4.2` - Target your Podfile to the `swift4.2` branch

## Quick Start

```ruby

# CocoaPods
pod "NextLevel", "~> 0.16.3"

# Carthage
github "nextlevel/NextLevel" ~> 0.16.3

# Swift PM
let package = Package(
    dependencies: [
        .Package(url: "https://github.com/nextlevel/NextLevel", majorVersion: 0)
    ]
)

```

Alternatively, drop the NextLevel [source files](https://github.com/NextLevel/NextLevel/tree/master/Sources) or project file into your Xcode project.

## Important Configuration Note for ARKit and True Depth

ARKit and the True Depth Camera software features are enabled with the inclusion of the Swift compiler flag `USE_ARKIT` and `USE_TRUE_DEPTH` respectively.

Apple will [reject](https://github.com/NextLevel/NextLevel/issues/106) apps that link against ARKit or the True Depth Camera API and do not use them.

If you use Cocoapods, you can include `-D USE_ARKIT` or `-D USE_TRUE_DEPTH` with the following `Podfile` addition or by adding it to your Xcode build settings.

```ruby
  installer.pods_project.targets.each do |target|
    # setup NextLevel for ARKit use
    if target.name == 'NextLevel'
      target.build_configurations.each do |config|
        config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-DUSE_ARKIT']
      end
    end
  end
```

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
    NextLevel.shared.videoConfiguration.maximumCaptureDuration = CMTimeMakeWithSeconds(5, 600)
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

## About

NextLevel was initally a weekend project that has now grown into a open community of camera platform enthusists. The software provides foundational components for managing media recording, camera interface customization, gestural interaction customization, and image streaming on iOS. The same capabilities can also be found in apps such as [Snapchat](http://snapchat.com), [Instagram](http://instagram.com), and [Vine](http://vine.co).

The goal is to continue to provide a good foundation for quick integration (enabling projects to be taken to the next level) – allowing focus to placed on functionality that matters most whether it's realtime image processing, computer vision methods, augmented reality, or [computational photography](https://om.co/2018/07/23/even-leica-loves-computational-photography/).

## ARKit

NextLevel provides components for capturing ARKit video and photo. This enables a variety of new camera features while leveraging the existing recording capabilities and media management of NextLevel.

If you are trying to capture frames from SceneKit for ARKit recording, check out the [examples](https://github.com/NextLevel/examples) project.

## Documentation

You can find [the docs here](https://nextlevel.github.io/NextLevel). Documentation is generated with [jazzy](https://github.com/realm/jazzy) and hosted on [GitHub-Pages](https://pages.github.com).

### Stickers

If you found this project to be helpful, check out the [Next Level stickers](https://www.stickermule.com/en/user/1070732101/stickers).

### Project

NextLevel is a community – contributions and discussions are welcome!

- Feature idea? Open an [issue](https://github.com/nextlevel/NextLevel/issues).
- Found a bug? Open an [issue](https://github.com/nextlevel/NextLevel/issues).
- Need help? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/nextlevel) with the tag ’nextlevel’.
- Questions? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/nextlevel) with the tag 'nextlevel'.
- Want to contribute? Submit a pull request.

### Related Projects

- [Player (Swift)](https://github.com/piemonte/player), video player in Swift
- [PBJVideoPlayer (obj-c)](https://github.com/piemonte/PBJVideoPlayer), video player in obj-c
- [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter), media transcoding in Swift
- [GPUImage3](https://github.com/BradLarson/GPUImage3), image processing library
- [SCRecorder](https://github.com/rFlex/SCRecorder), obj-c capture library
- [PBJVision](https://github.com/piemonte/PBJVision), obj-c capture library

## Resources

* [iOS Device Camera Summary](https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Cameras/Cameras.html)
* [AV Foundation Programming Guide](https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html)
* [AV Foundation Framework Reference](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVFoundationFramework/)
* [ARKit Framework Reference](https://developer.apple.com/documentation/arkit)
* [Swift Evolution](https://github.com/apple/swift-evolution)
* [objc.io Camera and Photos](http://www.objc.io/issue-21/)
* [objc.io Video](http://www.objc.io/issue-23/)
* [objc.io Core Image and Video](https://www.objc.io/issues/23-video/core-image-video/)
* [Cameras, ecommerce and machine learning](http://ben-evans.com/benedictevans/2016/11/20/ku6omictaredoge4cao9cytspbz4jt)
* [Again, iPhone is the default camera](http://om.co/2016/12/07/again-iphone-is-the-default-camera/)

## License

NextLevel is available under the MIT license, see the [LICENSE](https://github.com/NextLevel/NextLevel/blob/master/LICENSE) file for more information.
