//
//  NextLevelProtocols.swift
//  NextLevel (http://github.com/NextLevel/)
//
//  Copyright (c) 2016-present patrick piemonte (http://patrickpiemonte.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import AVFoundation
import CoreVideo
#if USE_ARKIT
import ARKit
#endif

// MARK: - NextLevelDelegate Dictionary Keys

/// Delegate callback dictionary key for photo metadata
public let NextLevelPhotoMetadataKey = "NextLevelPhotoMetadataKey"

/// Delegate callback dictionary key for JPEG data
public let NextLevelPhotoJPEGKey = "NextLevelPhotoJPEGKey"

/// Delegate callback dictionary key for cropped JPEG data
public let NextLevelPhotoCroppedJPEGKey = "NextLevelPhotoCroppedJPEGKey"

/// Delegate callback dictionary key for raw image data
public let NextLevelPhotoRawImageKey = "NextLevelPhotoRawImageKey"

/// Delegate callback dictionary key for a photo thumbnail
public let NextLevelPhotoThumbnailKey = "NextLevelPhotoThumbnailKey"

/// Delegate callback dictionary key for file data, configure using NextLevelPhotoConfiguration.outputFileDataFormat
public let NextLevelPhotoFileDataKey = "NextLevelPhotoFileDataKey"

// MARK: - NextLevelDelegate

/// NextLevel delegate, provides updates for authorization, configuration changes, session state, preview state, and mode changes.
public protocol NextLevelDelegate: AnyObject {

    // configuration
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration)

    // session
    func nextLevelSessionWillStart(_ nextLevel: NextLevel)
    func nextLevelSessionDidStart(_ nextLevel: NextLevel)
    func nextLevelSessionDidStop(_ nextLevel: NextLevel)

    // session interruption
    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel)
    func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel)

    // mode
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel)
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel)

}

/// Preview delegate, provides update for
public protocol NextLevelPreviewDelegate: AnyObject {

    // preview
    func nextLevelWillStartPreview(_ nextLevel: NextLevel)
    func nextLevelDidStopPreview(_ nextLevel: NextLevel)

}

/// Device delegate, provides updates on device position, orientation, clean aperture, focus, exposure, and white balances changes.
public protocol NextLevelDeviceDelegate: AnyObject {

    // position, orientation
    func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel)
    func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel)
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation)

    // format
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceFormat deviceFormat: AVCaptureDevice.Format)

    // aperture, lens
    func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect)
    func nextLevel(_ nextLevel: NextLevel, didChangeLensPosition lensPosition: Float)

    // focus, exposure, white balance
    func nextLevelWillStartFocus(_ nextLevel: NextLevel)
    func nextLevelDidStopFocus(_  nextLevel: NextLevel)

    func nextLevelWillChangeExposure(_ nextLevel: NextLevel)
    func nextLevelDidChangeExposure(_ nextLevel: NextLevel)

    func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel)
    func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel)

}

// MARK: - NextLevelFlashAndTorchDelegate

/// Flash and torch delegate, provides updates on active flash and torch related changes.
public protocol NextLevelFlashAndTorchDelegate: AnyObject {

    func nextLevelDidChangeFlashMode(_ nextLevel: NextLevel)
    func nextLevelDidChangeTorchMode(_ nextLevel: NextLevel)

    func nextLevelFlashActiveChanged(_ nextLevel: NextLevel)
    func nextLevelTorchActiveChanged(_ nextLevel: NextLevel)

    func nextLevelFlashAndTorchAvailabilityChanged(_ nextLevel: NextLevel)

}

// MARK: - NextLevelVideoDelegate

/// Video delegate, provides updates on video related recording and capture functionality.
/// All methods are called on the main queue with the exception of nextLevel:renderToCustomContextWithSampleBuffer:onQueue.
public protocol NextLevelVideoDelegate: AnyObject {

    // video zoom
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float)

    // video processing
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue)
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue)

    // ARKit video processing
    func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, timestamp: TimeInterval, onQueue queue: DispatchQueue)

    // video recording session
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession)

    // clip start/stop
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession)

    // clip file I/O
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)

    func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession)

    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)

    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession)

    // video frame photo
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String: Any]?)

}

// MARK: - NextLevelPhotoDelegate

/// Photo delegate, provides updates on photo related capture functionality.
public protocol NextLevelPhotoDelegate: AnyObject {
    func nextLevel(_ nextLevel: NextLevel, output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, photoConfiguration: NextLevelPhotoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings, photoConfiguration: NextLevelPhotoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings, photoConfiguration: NextLevelPhotoConfiguration)

    func nextLevel(_ nextLevel: NextLevel, didFinishProcessingPhoto photo: AVCapturePhoto, photoDict: [String: Any], photoConfiguration: NextLevelPhotoConfiguration)

    func nextLevelDidCompletePhotoCapture(_ nextLevel: NextLevel)
}

// MARK: - NextLevelDepthDataDelegate

#if USE_TRUE_DEPTH
/// Depth data delegate, provides depth data updates
public protocol NextLevelDepthDataDelegate: AnyObject {
    func depthDataOutput(_ nextLevel: NextLevel, didOutput depthData: AVDepthData, timestamp: CMTime)
    func depthDataOutput(_ nextLevel: NextLevel, didDrop depthData: AVDepthData, timestamp: CMTime, reason: AVCaptureOutput.DataDroppedReason)
}
#endif

// MARK: - NextLevelPortraitEffectsMatteDelegate

/// Portrait Effects Matte delegate, provides portrait effects matte updates
public protocol NextLevelPortraitEffectsMatteDelegate: AnyObject {
    func portraitEffectsMatteOutput(_ nextLevel: NextLevel, didOutput portraitEffectsMatte: AVPortraitEffectsMatte)
}

// MARK: - NextLevelMetadataOutputObjectsDelegate

/// Metadata Output delegate, provides objects like faces and barcodes
public protocol NextLevelMetadataOutputObjectsDelegate: AnyObject {
    func metadataOutputObjects(_ nextLevel: NextLevel, didOutput metadataObjects: [AVMetadataObject])
}
