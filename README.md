<p><img src="https://raw.github.com/NextLevel/NextLevel/master/NextLevel%402x.png" alt="Next Level" style="max-width:100%;"></p>

## NextLevel 📷

`NextLevel` is a Swift camera system designed for easy integration, customized media capture, and image streaming in iOS.

[![Swift Version](https://img.shields.io/badge/language-swift%206.0-brightgreen.svg)](https://developer.apple.com/swift) [![Platform](https://img.shields.io/badge/platform-iOS%2016.0%2B-blue.svg)](https://developer.apple.com/ios/) [![SPM Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/) [![Pod Version](https://img.shields.io/cocoapods/v/NextLevel.svg?style=flat)](http://cocoadocs.org/docsets/NextLevel/) [![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/NextLevel/NextLevel/blob/master/LICENSE)

|  | Features |
|:---------:|:---------------------------------------------------------------|
| &#127916; | "[Vine](http://vine.co)-like" video clip recording and editing |
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
| &#128038; | [Swift 6](https://developer.apple.com/swift/) |
| &#9889; | async/await and modern concurrency support |
| &#128214; | structured logging with OSLog |

The library provides powerful camera controls and features for capturing photos and videos, including multi-clip "Vine-like" recording, custom buffer processing, ARKit integration, and extensive device control – all with a simple, intuitive API.

### ✨ What's New in Swift 6

- **🚀 Modern Async/Await API** - Native Swift concurrency support with `async/await` and `AsyncStream` events
- **🔒 Swift 6 Strict Concurrency** - Full thread-safety with Sendable conformance and actor isolation
- **🛡️ Critical Bug Fixes** - Fixed AudioChannelLayout crash (#286, #271), photo capture crash (#280), audio interruption handling (#281), and video timing issues (#278)
- **📝 Enhanced Error Messages** - Contextual error descriptions with LocalizedError and recovery suggestions
- **⚡ Better Performance** - Proper state management and memory handling for long recordings
- **📐 Multi-Clip Recording Improvements** - Fixed timestamp offset bugs for seamless clip merging
- **🎯 Configurable Network Optimization** - Control shouldOptimizeForNetworkUse for faster local recording (#257)
- **📱 iOS 16+ AsyncStream Events** - Modern reactive event system for camera state changes
- **🔙 Backwards Compatible** - Legacy delegate-based API still works

### Requirements

- **iOS 16.0+** for modern concurrency features and Task.sleep(for:) API
- **Swift 6.0**
- **Xcode 16.0+**

### Related Projects

- Looking for a video exporter? Check out [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter).
- Looking for a video player? Check out [Player](https://github.com/piemonte/player)

## Quick Start

### Swift Package Manager (Recommended)

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/NextLevel/NextLevel", from: "0.19.1")
]
```

Or add it directly in Xcode: **File → Add Package Dependencies...**

### CocoaPods

```ruby
pod "NextLevel", "~> 0.19.1"
```

### Manual Integration

Alternatively, drop the [source files](https://github.com/NextLevel/NextLevel/tree/master/Sources) into your Xcode project.

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

## Examples

### Permissions

Before starting, ensure that permission keys have been added to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
    <string>Allowing access to the camera lets you take photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
    <string>Allowing access to the microphone lets you record audio.</string>
```

### Basic Video Recording

Import the library:

```swift
import NextLevel
```

Setup the camera preview:

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

Configure the capture session:

```swift
override func viewDidLoad() {
    super.viewDidLoad()

    // Set delegates
    NextLevel.shared.delegate = self
    NextLevel.shared.deviceDelegate = self
    NextLevel.shared.videoDelegate = self
    NextLevel.shared.photoDelegate = self

    // Configure video settings
    NextLevel.shared.videoConfiguration.bitRate = 6_000_000  // 6 Mbps
    NextLevel.shared.videoConfiguration.preset = .hd1920x1080
    NextLevel.shared.videoConfiguration.maximumCaptureDuration = CMTime(seconds: 10, preferredTimescale: 600)

    // Configure audio settings
    NextLevel.shared.audioConfiguration.bitRate = 128_000  // 128 kbps
}
```

Start/stop the session:

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NextLevel.shared.start()
}

override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NextLevel.shared.stop()
}
```

Record and pause:

```swift
// Start recording
NextLevel.shared.record()

// Pause recording (creates a clip)
NextLevel.shared.pause()

// Resume recording (starts a new clip)
NextLevel.shared.record()
```

### Modern Async/Await API (iOS 15+)

The modern API provides clean async/await support for session operations:

```swift
// Merge clips with async/await
do {
    if let session = NextLevel.shared.session {
        let url = try await session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality)
        print("Video saved to: \(url)")

        // Save to photo library
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
} catch {
    print("Merge failed: \(error.localizedDescription)")
}
```

### AsyncStream Events (iOS 15+)

Subscribe to camera events using AsyncStream for reactive programming:

```swift
Task {
    for await event in NextLevel.shared.sessionEvents {
        switch event {
        case .didStart:
            print("Camera session started")
        case .didStop:
            print("Camera session stopped")
        case .sessionDidStart:
            print("Recording session started")
        case .sessionDidStop:
            print("Recording session stopped")
        case .wasInterrupted:
            print("Session interrupted (e.g., phone call)")
        case .interruptionEnded:
            print("Interruption ended")
        }
    }
}
```

### Multi-Clip Recording ("Vine-like")

NextLevel makes it easy to record multiple clips and merge them into a single video:

```swift
// Record first clip
NextLevel.shared.record()
// ... wait ...
NextLevel.shared.pause()  // Creates first clip

// Record second clip
NextLevel.shared.record()
// ... wait ...
NextLevel.shared.pause()  // Creates second clip

// Access all clips
if let session = NextLevel.shared.session {
    print("Total clips: \(session.clips.count)")
    print("Total duration: \(session.totalDuration.seconds)s")

    // Remove last clip (undo)
    session.removeLastClip()

    // Remove specific clip
    if let firstClip = session.clips.first {
        session.remove(clip: firstClip)
    }

    // Remove all clips
    session.removeAllClips()

    // Merge all clips into single video
    session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality) { url, error in
        if let outputURL = url {
            print("Merged video: \(outputURL)")
        } else if let error = error {
            print("Merge failed: \(error.localizedDescription)")
        }
    }
}
```

### Photo Capture

Capture high-quality photos with extensive configuration options:

```swift
// Configure photo settings
NextLevel.shared.photoConfiguration.codec = .hevc  // HEVC for better compression
NextLevel.shared.photoConfiguration.isHighResolutionEnabled = true
NextLevel.shared.photoConfiguration.flashMode = .auto

// Set photo resolution/aspect ratio
// By default photos use .high preset (16:9)
// Available presets:
NextLevel.shared.photoConfiguration.preset = .photo          // 4:3 aspect ratio (default camera)
// NextLevel.shared.photoConfiguration.preset = .high        // 16:9 aspect ratio
// NextLevel.shared.photoConfiguration.preset = .hd1280x720  // 720p
// NextLevel.shared.photoConfiguration.preset = .hd1920x1080 // 1080p
// NextLevel.shared.photoConfiguration.preset = .hd4K3840x2160 // 4K

// Capture photo
NextLevel.shared.capturePhoto()

// Handle result in delegate
extension CameraViewController: NextLevelPhotoDelegate {
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame: Bool) {
        print("Photo capture completed")
    }

    func nextLevel(_ nextLevel: NextLevel, didFinishProcessingPhoto photo: AVCapturePhoto, photoDict: [String: Any], photoConfiguration: NextLevelPhotoConfiguration) {
        // Get JPEG data
        if let jpegData = photoDict[NextLevelPhotoJPEGKey] as? Data {
            // Save photo
            if let image = UIImage(data: jpegData) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }

        // Get HEVC data (if configured)
        if let hevcData = photoDict[NextLevelPhotoHEVCKey] as? Data {
            // Process HEVC photo
        }
    }
}
```

**Photo Configuration Options:**
- **Codec**: `.jpeg`, `.hevc` - Choose compression format
- **Preset**: `.photo` (4:3), `.high` (16:9), `.hd1920x1080`, `.hd4K3840x2160` - Controls resolution and aspect ratio
- **High Resolution**: Enable `isHighResolutionEnabled` for maximum quality
- **Flash Mode**: `.on`, `.off`, `.auto`
- **Portrait Effects Matte**: Enable `isPortraitEffectsMatteEnabled` for depth effects
- **Quality Prioritization**: `.speed`, `.balanced`, `.quality` - Balance between capture speed and quality

### Camera Control

NextLevel provides comprehensive camera control:

```swift
// Focus
try? NextLevel.shared.focusAtAdjustedPoint(CGPoint(x: 0.5, y: 0.5))
NextLevel.shared.focusMode = .continuousAutoFocus

// Exposure
try? NextLevel.shared.exposeAtAdjustedPoint(CGPoint(x: 0.5, y: 0.5))
NextLevel.shared.exposureMode = .continuousAutoExposure

// Zoom
NextLevel.shared.videoZoomFactor = 2.0

// Flash
NextLevel.shared.flashMode = .on

// Torch
NextLevel.shared.torchMode = .on

// Device position (front/back camera)
NextLevel.shared.devicePosition = .front

// Orientation
NextLevel.shared.deviceOrientation = .portrait

// Frame rate
NextLevel.shared.frameRate = 60  // 60 fps for slow motion

// Mirroring
NextLevel.shared.isMirroringEnabled = true

// Stabilization
NextLevel.shared.videoStabilizationMode = .cinematic
```

### Bluetooth Audio Support

To use Bluetooth headsets or external microphones, configure the audio session before starting NextLevel:

```swift
override func viewDidLoad() {
    super.viewDidLoad()

    // Disable automatic audio session configuration
    NextLevel.shared.automaticallyConfiguresApplicationAudioSession = false

    // Configure audio session for Bluetooth support
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .videoRecording,
            options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
        )
        try audioSession.setActive(true)
    } catch {
        print("Failed to configure audio session: \(error)")
    }

    // Now configure NextLevel
    NextLevel.shared.delegate = self
    NextLevel.shared.videoDelegate = self
    // ... rest of configuration
}
```

**Audio Session Options:**
- `.allowBluetooth` - Enable Bluetooth HFP (hands-free profile) for voice
- `.allowBluetoothA2DP` - Enable Bluetooth A2DP for high-quality audio
- `.defaultToSpeaker` - Use speaker when no Bluetooth device is connected
- `.mixWithOthers` - Allow mixing with other audio (e.g., music apps)

**Note:** Choose the options that match your app's requirements. For example, video recording typically uses `.videoRecording` mode with `.allowBluetoothA2DP` for better audio quality.

### Legacy Delegate-Based API

For compatibility with older iOS versions or existing codebases:

```swift
extension CameraViewController: NextLevelDelegate {
    func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        print("Session will start")
    }

    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        print("Session started")
    }

    func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        print("Session stopped")
    }

    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
        print("Session interrupted")
    }

    func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
        print("Interruption ended")
    }
}

extension CameraViewController: NextLevelVideoDelegate {
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
        print("Video configuration updated")
    }

    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
        print("Zoom: \(videoZoomFactor)x")
    }
}
```

Videos can also be processed using [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter), a powerful media transcoding library in Swift.

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

## Migration Guide

### Migrating to Swift 6 (v0.19.0)

The 0.19.0 release introduces Swift 6 with modern async/await APIs while maintaining full backward compatibility. Here's how to migrate:

#### Breaking Changes

- **Minimum iOS 15.0** (was iOS 14.0)
- **Swift 6.0 required** (was Swift 5.x)
- **Xcode 16.0+ required**

#### Non-Breaking Changes

All existing delegate-based APIs continue to work. You can adopt new features incrementally:

**Before (0.x):**
```swift
// Legacy completion handler
session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality) { url, error in
    if let url = url {
        print("Merged: \(url)")
    } else if let error = error {
        print("Error: \(error)")
    }
}
```

**After (0.19.0):**
```swift
// Modern async/await
do {
    let url = try await session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality)
    print("Merged: \(url)")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

#### Adopting AsyncStream Events (Optional)

**Before:**
```swift
extension CameraViewController: NextLevelDelegate {
    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        print("Session started")
    }

    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
        print("Session interrupted")
    }
}
```

**After (iOS 15+):**
```swift
Task {
    for await event in NextLevel.shared.sessionEvents {
        switch event {
        case .didStart:
            print("Session started")
        case .wasInterrupted:
            print("Session interrupted")
        default:
            break
        }
    }
}
```

#### Bug Fixes You Get Automatically

When you update to 0.19.0, these critical bugs are automatically fixed:

1. **AudioChannelLayout crash** (#286, #271) - No longer crashes when audio channel layout doesn't match channel count
2. **Photo capture crash** (#280) - Fixed when `generateThumbnail = true`
3. **Missing audio after interruption** (#281) - Audio now properly resumes after phone calls
4. **Video time skips** (#278) - Fixed timestamp offset accumulation bug
5. **Network optimization** (#257) - Now configurable via `shouldOptimizeForNetworkUse`

**No code changes required** - just update your dependency version!

#### Updated Error Handling

Errors now provide more context:

```swift
do {
    try NextLevel.shared.focusAtAdjustedPoint(point)
} catch let error as LocalizedError {
    print(error.localizedDescription)     // User-friendly message
    print(error.recoverySuggestion ?? "")  // How to fix it
}
```

### Migrating from Older Versions

**Need Swift 5?** Target the `swift5` branch:
```ruby
pod "NextLevel", :git => 'https://github.com/NextLevel/NextLevel.git', :branch => 'swift5'
```

**Need Swift 4.2?** Target the `swift4.2` branch:
```ruby
pod "NextLevel", :git => 'https://github.com/NextLevel/NextLevel.git', :branch => 'swift4.2'
```

## Troubleshooting

### AudioChannelLayout Crash (Fixed in 0.19.0)

**Problem:** App crashes with "AudioChannelLayout channel count does not match AVNumberOfChannelsKey channel count"

**Solution:** Update to NextLevel 0.19.0 or later. This issue has been fixed.

**Root Cause:** Audio channel layout validation now ensures the layout matches the declared channel count before configuring AVAssetWriterInput.

### Photo Capture Crash with generateThumbnail (Fixed in 0.19.0)

**Problem:** Setting `generateThumbnail = true` causes app crash

**Solution:** Update to NextLevel 0.19.0 or later. The issue has been fixed.

**Root Cause:** `kCVPixelBufferPixelFormatTypeKey` and `AVVideoCodecKey` are mutually exclusive in AVFoundation. The fix ensures only the appropriate key is set based on thumbnail configuration.

### Missing Audio After Phone Call (Fixed in 0.19.0)

**Problem:** Video recordings have no audio after receiving a phone call or other interruption

**Solution:** Update to NextLevel 0.19.0 or later. The library now properly pauses and resumes recording during interruptions.

**Root Cause:** Audio session interruptions weren't properly handled, causing audio track initialization to fail after resuming.

### Video Has Time Skips or Jumps (Fixed in 0.19.0)

**Problem:** Video playback shows unexpected time skips or jumps between clips

**Solution:** Update to NextLevel 0.19.0 or later. The timestamp offset calculation has been fixed.

**Root Cause:** Cumulative timestamp offset was being incorrectly accumulated every frame instead of only adjusting clip boundaries.

### Camera Session Won't Start

**Problem:** Camera preview is black or session doesn't start

**Solutions:**
1. Check permissions in Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>Allowing access to the camera lets you take photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Allowing access to the microphone lets you record audio.</string>
```

2. Verify you're calling `start()` on the main thread:
```swift
DispatchQueue.main.async {
    NextLevel.shared.start()
}
```

3. Check authorization status:
```swift
let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
if authStatus == .authorized {
    NextLevel.shared.start()
} else {
    AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
            DispatchQueue.main.async {
                NextLevel.shared.start()
            }
        }
    }
}
```

### Recording Stops Unexpectedly

**Problem:** Recording stops on its own without calling `pause()`

**Possible Causes:**
1. **Maximum duration reached** - Check `videoConfiguration.maximumCaptureDuration`
2. **Disk space full** - Monitor available storage
3. **Memory pressure** - Lower resolution or bitrate for long recordings
4. **Interruption** - Phone call, Siri, or other system interruption

**Solutions:**
```swift
// Increase max duration
NextLevel.shared.videoConfiguration.maximumCaptureDuration = CMTime.positiveInfinity

// Monitor session state
extension YourViewController: NextLevelDelegate {
    func nextLevelCaptureDurationDidChange(_ nextLevel: NextLevel) {
        if let session = nextLevel.session {
            print("Duration: \(session.totalDuration.seconds)s")
        }
    }
}
```

### Low Frame Rate or Choppy Video

**Solutions:**
1. Lower the resolution:
```swift
NextLevel.shared.videoConfiguration.preset = .hd1280x720  // Instead of 1920x1080
```

2. Reduce bitrate:
```swift
NextLevel.shared.videoConfiguration.bitRate = 3_000_000  // 3 Mbps instead of 6 Mbps
```

3. Disable custom buffer processing if not needed:
```swift
NextLevel.shared.isVideoCustomContextRenderingEnabled = false
```

4. Test on a physical device (simulators have different performance characteristics)

### Memory Issues During Long Recordings

**Solutions:**
1. Use HEVC codec for better compression:
```swift
NextLevel.shared.videoConfiguration.codec = .hevc
```

2. Enable network optimization for faster writing (default):
```swift
if let session = NextLevel.shared.session {
    session.shouldOptimizeForNetworkUse = true
}
```

3. Remove clips you no longer need:
```swift
session.removeLastClip()
session.removeAllClips(removeFiles: true)  // Also delete files from disk
```

### ARKit Integration Issues

**Problem:** App rejected by App Store for linking ARKit without using it

**Solution:** Only include ARKit compiler flags when you're actually using ARKit features:

```ruby
# In Podfile - only add if using ARKit
installer.pods_project.targets.each do |target|
    if target.name == 'NextLevel'
        target.build_configurations.each do |config|
            config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-DUSE_ARKIT']
        end
    end
end
```

Don't add `-DUSE_ARKIT` or `-DUSE_TRUE_DEPTH` flags unless you're actually using those features.

### Build Errors After Upgrading to Swift 6

**Problem:** Concurrency warnings or errors after upgrading

**Solutions:**
1. Clean build folder: **Product → Clean Build Folder**
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Update all dependencies to Swift 6 compatible versions
4. Enable strict concurrency checking in your project if needed

### Getting Help

- **Issues**: Open an [issue](https://github.com/NextLevel/NextLevel/issues) with device model, iOS version, and NextLevel version
- **Questions**: Use [Stack Overflow](http://stackoverflow.com/questions/tagged/nextlevel) with the tag `nextlevel`
- **Discussions**: Check [GitHub Discussions](https://github.com/NextLevel/NextLevel/discussions) for community help

## About

NextLevel was initally a weekend project that has now grown into a open community of camera platform enthusists. The software provides foundational components for managing media recording, camera interface customization, gestural interaction customization, and image streaming on iOS. The same capabilities can also be found in apps such as [Snapchat](http://snapchat.com), [Instagram](http://instagram.com), and [Vine](http://vine.co).

The goal is to continue to provide a good foundation for quick integration (enabling projects to be taken to the next level) – allowing focus to placed on functionality that matters most whether it's realtime image processing, computer vision methods, augmented reality, or [computational photography](https://om.co/2018/07/23/even-leica-loves-computational-photography/).

## ARKit

NextLevel provides components for capturing ARKit video and photo. This enables a variety of new camera features while leveraging the existing recording capabilities and media management of NextLevel.

If you are trying to capture frames from SceneKit for ARKit recording, check out the [examples](https://github.com/NextLevel/examples) project.

## Documentation

You can find [the docs here](https://nextlevel.github.io/NextLevel). Documentation is generated with [jazzy](https://github.com/realm/jazzy) and hosted on [GitHub-Pages](https://pages.github.com).

## Community

NextLevel is a community – contributions and discussions are welcome!

- Found a bug? Open an [issue](https://github.com/NextLevel/NextLevel/issues).
- Feature idea? Open an [issue](https://github.com/NextLevel/NextLevel/issues).
- Want to contribute? Submit a [pull request](https://github.com/NextLevel/NextLevel/pulls).

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
