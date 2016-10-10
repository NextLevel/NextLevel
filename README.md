<p><img src="https://raw.github.com/NextLevel/NextLevel/master/NextLevel%402x.png" alt="Next Level" style="max-width:100%;"></p>

Next Level is a media capture camera library for iOS written in [Swift](https://developer.apple.com/swift/).

Currently initial **beta**, several features are being tested and have bugs – these are being addressed.

[![Build Status](https://travis-ci.org/NextLevel/NextLevel.svg?branch=master)](https://travis-ci.org/NextLevel/NextLevel) [![Pod Version](https://img.shields.io/cocoapods/v/NextLevel.svg?style=flat)](http://cocoadocs.org/docsets/NextLevel/)

## Features

- [x] simple and extensible API
- [x] camera user interface and gestural interaction customization
- [x] “[Vine](http://vine.co)-like” video clip recording
- [x] slow motion capture on supported hardware ([iPhone](https://www.apple.com/iphone/compare/), [iPad](https://www.apple.com/ipad/compare/))
- [x] video zoom
- [x] white balance, focus, and exposure adjustment
- [x] flash/torch support
- [x] mirroring support
- [x] photo capture
- [x] dual camera, wide angle, telephoto device switching
- [x] [Swift 3](https://developer.apple.com/swift/)

## Quick Start

```ruby

# CocoaPods

pod "NextLevel", "~> 0.0.1-beta.5"

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end

# Carthage

github "nextlevel/NextLevel" ~> 0.0.1-beta.5

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

### Sticker

If you found this project to be helpful, check out the [Next Level sticker](https://www.stickermule.com/en/marketplace/15145-next-level).

For a [$10 credit](https://www.stickermule.com/unlock?ref_id=1012370701), use this sign up [link](https://www.stickermule.com/unlock?ref_id=1012370701).

If other projects have interest in providing something similar, this conforms to the [sticker standard](https://terinjokes.github.io/StickerConstructorSpec/) which is also used by several node projects. 

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
    NextLevel.sharedInstance.previewLayer.frame = previewView.bounds
    previewView.layer.addSublayer(NextLevel.sharedInstance.previewLayer)
    self.view.addSubview(previewView)
}
```

Configure the capture session.
```swift
override func viewDidLoad() {
    NextLevel.sharedInstance.delegate = self
    
    // modify .videoConfiguration, .audioConfiguration, .photoConfiguration properties
    // Compression, resolution, and maximum recording time options are available
    NextLevel.sharedInstance.videoConfiguration.maxRecordDuration = CMTimeMakeWithSeconds(5, 600)
    NextLevel.sharedInstance.audioConfiguration.bitRate = 44000
 }
```

Start/stop the session when appropriate. These methods create a new "session" instance for 'NextLevel.sharedInstance.session' when called.

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)     
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

Video record/pause.

```swift
// record
NextLevel.sharedInstance.record()

// pause
NextLevel.sharedInstance.pause()
```

Editing and finalizing the recorded session.
```swift

if let session = NextLevel.sharedInstance.session {

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

## About

Next Level is just a little weekend project that kept going.

The software provides foundational components for advanced media recording, camera interface customization, and gestural interaction customization on iOS. The same capabilities can also be found in apps such as [Snapchat](http://snapchat.com), [Instagram](http://instagram.com), [Vine](http://vine.co), [Peach](http://peach.cool), and others.

It's goal is to provide a good foundation for quick integration – allowing everyone to focus on the functionality that builds on this, such as image processing, computer vision methods including 3D photography, augmented reality, depth of field, or even new technology aided cinematographic techniques.

### Related Projects

- [Player (Swift)](https://github.com/piemonte/player), video player in Swift
- [PBJVideoPlayer (obj-c)](https://github.com/piemonte/PBJVideoPlayer), video player in obj-c
- [GPUImage2](https://github.com/BradLarson/GPUImage2), image processing library
- [SCRecorder](https://github.com/rFlex/SCRecorder), obj-c capture library
- [PBJVision](https://github.com/piemonte/PBJVision), obj-c capture library
- [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter), media transcoding in Swift
- [SDAVAssetExportSession](https://github.com/rs/SDAVAssetExportSession), media transcoding in obj-c

## Resources

* [iOS Device Camera Summary](https://developer.apple.com/library/prerelease/content/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Cameras/Cameras.html)
* [AV Foundation Programming Guide](https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html)
* [AV Foundation Framework Reference](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVFoundationFramework/)
* [Swift Evolution](https://github.com/apple/swift-evolution)
* [objc.io Camera and Photos](http://www.objc.io/issue-21/)
* [objc.io Video](http://www.objc.io/issue-23/)

## License

NextLevel is available under the MIT license, see the [LICENSE](https://github.com/NextLevel/NextLevel/blob/master/LICENSE) file for more information.
