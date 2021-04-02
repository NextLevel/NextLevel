//
//  NextLevelConfiguration.swift
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

import UIKit
import Foundation
import AVFoundation
#if USE_ARKIT
import ARKit
#endif

// MARK: - MediaTypeConfiguration

/// NextLevelConfiguration, media capture configuration object
public class NextLevelConfiguration {

    // MARK: - types

    /// Aspect ratio, specifies dimensions for video output
    ///
    /// - active: active preset or specified dimensions (default)
    /// - square: 1:1 square
    /// - standard: 3:4
    /// - standardLandscape: 4:3, landscape
    /// - widescreen: 9:16 HD
    /// - widescreenLandscape: 16:9 HD landscape
    /// - instagram: 4:5 Instagram
    /// - instagramLandscape: 5:4 Instagram landscape
    /// - instagramStories: 9:16 Instagram stories
    /// - cinematic: 2.35:1 cinematic
    /// - custom: custom aspect ratio
    public enum AspectRatio: CustomStringConvertible {
        case active
        case square
        case standard
        case standardLandscape
        case widescreen
        case widescreenLandscape
        case twitter
        case youtube
        case instagram
        case instagramLandscape
        case instagramStories
        case cinematic
        case custom(w: Int, h: Int)

        public var dimensions: CGSize? {
            get {
                switch self {
                case .active:
                    return nil
                case .square:
                    return CGSize(width: 1, height: 1)
                case .standard:
                    return CGSize(width: 3, height: 4)
                case .standardLandscape:
                    return CGSize(width: 4, height: 3)
                case .widescreen:
                    return CGSize(width: 9, height: 16)
                case .twitter, .youtube:
                    fallthrough
                case .widescreenLandscape:
                    return CGSize(width: 16, height: 9)
                case .instagram:
                    return CGSize(width: 4, height: 5)
                case .instagramLandscape:
                    return CGSize(width: 5, height: 4)
                case .instagramStories:
                    return CGSize(width: 9, height: 16)
                case .cinematic:
                    return CGSize(width: 2.35, height: 1)
                case .custom(let w, let h):
                    return CGSize(width: w, height: h)
                }
            }
        }

        public var ratio: CGFloat? {
            get {
                switch self {
                case .active:
                    return nil
                case .square:
                    return 1
                case .custom(let w, let h):
                    return CGFloat(h) / CGFloat(w)
                default:
                    if let w = self.dimensions?.width,
                       let h = self.dimensions?.height {
                        return h / w
                    } else {
                        return nil
                    }
                }
            }
        }

        public var description: String {
            get {
                switch self {
                case .active:
                    return "Active"
                case .square:
                    return "1:1 Square"
                case .standard:
                    return "3:4 Standard"
                case .standardLandscape:
                    return "4:3 Standard Landscape"
                case .widescreen:
                    return "9:16 Widescreen HD"
                case .widescreenLandscape:
                    return "16:9 Widescreen Landscape HD"
                case .twitter:
                    return "16:9 Twitter Widescreen Landscape HD"
                case .youtube:
                    return "16:9 YouTube Widescreen Landscape HD"
                case .instagram:
                    return "4:5 Instagram"
                case .instagramLandscape:
                    return "5:4 Instagram Landscape"
                case .instagramStories:
                    return "9:16 Instagram Stories"
                case .cinematic:
                    return "2.35:1 Cinematic"
                case .custom(let w, let h):
                    return "\(w):\(h) Custom"
                }
            }
        }
    }

    // MARK: - properties

    /// AVFoundation configuration preset, see AVCaptureSession.h
    public var preset: AVCaptureSession.Preset

    /// Setting an options dictionary overrides all other properties set on a configuration object but allows full customization
    public var options: [String: Any]?

    // MARK: - object lifecycle

    public init() {
        self.preset = AVCaptureSession.Preset.high
        self.options = nil
    }

    // MARK: - func

    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Configuration dictionary for AVFoundation
    public func avcaptureSettingsDictionary(sampleBuffer: CMSampleBuffer? = nil, pixelBuffer: CVPixelBuffer? = nil) -> [String: Any]? {
        self.options
    }
}

// MARK: - VideoConfiguration

/// NextLevelVideoConfiguration, video capture configuration object
public class NextLevelVideoConfiguration: NextLevelConfiguration {

    // MARK: - types

    public static let VideoBitRateDefault: Int = 2000000

    // MARK: - properties

    /// Average video bit rate (bits per second), AV dictionary key AVVideoAverageBitRateKey
    public var bitRate: Int = NextLevelVideoConfiguration.VideoBitRateDefault

    /// Dimensions for video output, AV dictionary keys AVVideoWidthKey, AVVideoHeightKey
    public var dimensions: CGSize?

    /// Output aspect ratio automatically sizes output dimensions, `active` indicates NextLevelVideoConfiguration.preset or NextLevelVideoConfiguration.dimensions
    public var aspectRatio: AspectRatio = .active

    /// Video output transform for display
    public var transform: CGAffineTransform = .identity

    /// Codec used to encode video, AV dictionary key AVVideoCodecKey
    public var codec: AVVideoCodecType = AVVideoCodecType.h264

    /// Profile level for the configuration, AV dictionary key AVVideoProfileLevelKey (H.264 codec only)
    public var profileLevel: String?

    /// Video scaling mode, AV dictionary key AVVideoScalingModeKey
    /// (AVVideoScalingModeResizeAspectFill, AVVideoScalingModeResizeAspect, AVVideoScalingModeResize, AVVideoScalingModeFit)
    public var scalingMode: String = AVVideoScalingModeResizeAspectFill

    /// Maximum interval between key frames, 1 meaning key frames only, AV dictionary key AVVideoMaxKeyFrameIntervalKey
    public var maxKeyFrameInterval: Int?

    /// Video time scale, value/timescale = seconds
    public var timescale: Float64?

    /// Maximum recording duration, when set, session finishes automatically
    public var maximumCaptureDuration: CMTime?

    // MARK: - object lifecycle

    override public init() {
        super.init()
    }

    // MARK: - func

    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Video configuration dictionary for AVFoundation
    override public func avcaptureSettingsDictionary(sampleBuffer: CMSampleBuffer? = nil, pixelBuffer: CVPixelBuffer? = nil) -> [String: Any]? {

        // if the client specified custom options, use those instead
        if let options = self.options {
            return options
        }

        var config: [String: Any] = [:]

        if let dimensions = self.dimensions {
            config[AVVideoWidthKey] = NSNumber(integerLiteral: Int(dimensions.width))
            config[AVVideoHeightKey] = NSNumber(integerLiteral: Int(dimensions.height))
        } else if let sampleBuffer = sampleBuffer,
                  let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {

            // TODO: this is incorrect and needs to be fixed
            let videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            switch self.aspectRatio {
            case .standard:
                config[AVVideoWidthKey] = NSNumber(integerLiteral: Int(videoDimensions.width))
                config[AVVideoHeightKey] = NSNumber(integerLiteral: Int(videoDimensions.width * 3 / 4))
                break
            case .widescreen:
                config[AVVideoWidthKey] = NSNumber(integerLiteral: Int(videoDimensions.width))
                config[AVVideoHeightKey] = NSNumber(integerLiteral: Int(videoDimensions.width * 9 / 16))
                break
            case .square:
                let min = Swift.min(videoDimensions.width, videoDimensions.height)
                config[AVVideoWidthKey] = NSNumber(integerLiteral: Int(min))
                config[AVVideoHeightKey] = NSNumber(integerLiteral: Int(min))
                break
            case .custom(let w, let h):
                config[AVVideoWidthKey] = NSNumber(integerLiteral: Int(videoDimensions.width))
                config[AVVideoHeightKey] = NSNumber(integerLiteral: Int(videoDimensions.width * Int32(h) / Int32(w)))
                break
            case .active:
                fallthrough
            default:
                config[AVVideoWidthKey] = NSNumber(integerLiteral: Int(videoDimensions.width))
                config[AVVideoHeightKey] = NSNumber(integerLiteral: Int(videoDimensions.height))
                break
            }

        } else if let pixelBuffer = pixelBuffer {
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            config[AVVideoWidthKey] = NSNumber(integerLiteral: Int(width))
            config[AVVideoHeightKey] = NSNumber(integerLiteral: Int(height))
        }

        config = self.update(config: config)

        config[AVVideoCodecKey] = self.codec
        config[AVVideoScalingModeKey] = self.scalingMode

        var compressionDict: [String: Any] = [:]
        compressionDict[AVVideoAverageBitRateKey] = NSNumber(integerLiteral: self.bitRate)
        compressionDict[AVVideoAllowFrameReorderingKey] = NSNumber(booleanLiteral: false)
        compressionDict[AVVideoExpectedSourceFrameRateKey] = NSNumber(integerLiteral: 30)
        if let profileLevel = self.profileLevel {
            compressionDict[AVVideoProfileLevelKey] = profileLevel
        }
        if let maxKeyFrameInterval = self.maxKeyFrameInterval {
            compressionDict[AVVideoMaxKeyFrameIntervalKey] = NSNumber(integerLiteral: maxKeyFrameInterval)
        }

        config[AVVideoCompressionPropertiesKey] = (compressionDict as NSDictionary)
        return config
    }

    /// Update configuration with size values.
    ///     With MPEG-2 and MPEG-4 (and other DCT based codecs), compression is applied to a grid of 16x16 pixel macroblocks.
    ///     With MPEG-4 Part 10 (AVC/H.264), multiple of 4 and 8 also works, but 16 is most efficient.
    ///     So, to prevent appearing on broken(green) pixels, the sizes of captured video must be divided by 4, 8, or 16.
    ///
    /// - Parameters:
    ///   - config: Input configuration dictionary
    ///   - divisibleBy: Divisor
    /// - Returns: Configuration with appropriately divided sizes
    private func update(config: [String: Any], withSizeValuesDivisibleBy divisibleBy: Int = 16) -> [String: Any] {
        var config = config

        if let width = config[AVVideoWidthKey] as? Int {
            let newWidth = width - (width % divisibleBy)
            config[AVVideoWidthKey] = NSNumber(integerLiteral: newWidth)
        }
        if let height = config[AVVideoHeightKey] as? Int {
            let newHeight = height - (height % divisibleBy)
            config[AVVideoHeightKey] = NSNumber(integerLiteral: newHeight)
        }

        return config
    }

}

// MARK: - AudioConfiguration

/// NextLevelAudioConfiguration, audio capture configuration object
public class NextLevelAudioConfiguration: NextLevelConfiguration {

    // MARK: - types

    public static let AudioBitRateDefault: Int = 96000
    public static let AudioSampleRateDefault: Float64 = 44100
    public static let AudioChannelsCountDefault: Int = 2

    // MARK: - properties

    /// Audio bit rate, AV dictionary key AVEncoderBitRateKey
    public var bitRate: Int = NextLevelAudioConfiguration.AudioBitRateDefault

    /// Sample rate in hertz, AV dictionary key AVSampleRateKey
    public var sampleRate: Float64?

    /// Number of channels, AV dictionary key AVNumberOfChannelsKey
    public var channelsCount: Int?

    /// Audio data format identifier, AV dictionary key AVFormatIDKey
    /// https://developer.apple.com/reference/coreaudio/1613060-core_audio_data_types
    public var format: AudioFormatID = kAudioFormatMPEG4AAC

    // MARK: - object lifecycle

    override public init() {
        super.init()
    }

    // MARK: - funcs

    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Audio configuration dictionary for AVFoundation
    override public func avcaptureSettingsDictionary(sampleBuffer: CMSampleBuffer? = nil, pixelBuffer: CVPixelBuffer? = nil) -> [String: Any]? {
        // if the client specified custom options, use those instead
        if let options = self.options {
            return options
        }

        var config: [String: Any] = [AVEncoderBitRateKey: NSNumber(integerLiteral: self.bitRate)]

        if let sampleBuffer = sampleBuffer, let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
            if let _ = self.sampleRate, let _ = self.channelsCount {
                // loading user provided settings after buffer use
            } else if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                self.sampleRate = streamBasicDescription.pointee.mSampleRate
                self.channelsCount = Int(streamBasicDescription.pointee.mChannelsPerFrame)
            }

            var layoutSize: Int = 0
            if let currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, sizeOut: &layoutSize) {
                let currentChannelLayoutData = layoutSize > 0 ? Data(bytes: currentChannelLayout, count: layoutSize) : Data()
                config[AVChannelLayoutKey] = currentChannelLayoutData
            }
        }

        if let sampleRate = self.sampleRate {
            config[AVSampleRateKey] = sampleRate == 0 ? NSNumber(value: NextLevelAudioConfiguration.AudioSampleRateDefault) : NSNumber(value: sampleRate)
        } else {
            config[AVSampleRateKey] = NSNumber(value: NextLevelAudioConfiguration.AudioSampleRateDefault)
        }

        if let channels = self.channelsCount {
            config[AVNumberOfChannelsKey] = channels == 0 ? NSNumber(integerLiteral: NextLevelAudioConfiguration.AudioChannelsCountDefault) : NSNumber(integerLiteral: channels)
        } else {
            config[AVNumberOfChannelsKey] = NSNumber(integerLiteral: NextLevelAudioConfiguration.AudioChannelsCountDefault)
        }

        config[AVFormatIDKey] = NSNumber(value: self.format as UInt32)

        return config
    }
}

// MARK: - PhotoConfiguration

/// NextLevelPhotoConfiguration, photo capture configuration object
public class NextLevelPhotoConfiguration: NextLevelConfiguration {

    /// Codec used to encode photo, AV dictionary key AVVideoCodecKey
    public var codec: AVVideoCodecType = AVVideoCodecType.hevc

    /// When true, NextLevel should generate a thumbnail for the photo
    public var generateThumbnail: Bool = false

    /// Enabled high resolution capture
    public var isHighResolutionEnabled: Bool = false

    /// Enabled depth data capture with photo
    #if USE_TRUE_DEPTH
    public var isDepthDataEnabled: Bool = false
    #endif

    /// Enables portrait effects matte output for the photo
    public var isPortraitEffectsMatteEnabled: Bool = false

    public var isRawCaptureEnabled: Bool = false

    // MARK: - ivars

    // change flashMode with NextLevel.flashMode
    internal var flashMode: AVCaptureDevice.FlashMode = .off

    // MARK: - object lifecycle

    override init() {
        super.init()
    }

    // MARK: - funcs

    /// Provides an AVFoundation friendly dictionary dictionary for configuration output.
    ///
    /// - Returns: Configuration dictionary for AVFoundation
    public func avcaptureDictionary() -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String: Any] = [AVVideoCodecKey: self.codec]
            if self.generateThumbnail {
                let settings = AVCapturePhotoSettings()
                // iOS 11 GM fix
                // https://forums.developer.apple.com/thread/86810
                if settings.__availablePreviewPhotoPixelFormatTypes.count > 0 {
                    if let formatType = settings.__availablePreviewPhotoPixelFormatTypes.first {
                        config[kCVPixelBufferPixelFormatTypeKey as String] = formatType
                    }
                }
            }
            return config
        }
    }
}

// MARK: - ARConfiguration

/// NextLevelARConfiguration, augmented reality configuration object
public class NextLevelARConfiguration: NextLevelConfiguration {

    #if USE_ARKIT
    /// ARKit configuration
    public var config: ARConfiguration?

    /// ARKit session, note: the delegate queue will be overriden
    public var session: ARSession?

    /// Session run options
    public var runOptions: ARSession.RunOptions?
    #endif

}
