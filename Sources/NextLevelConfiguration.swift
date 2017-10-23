//
//  NextLevelConfiguration.swift
//  NextLevel (http://nextlevel.engineering/)
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
import ARKit

// MARK: - MediaTypeConfiguration

/// NextLevelConfiguration, media capture configuration object
public class NextLevelConfiguration: NSObject {

    /// AVFoundation configuration preset, see AVCaptureSession.h
    public var preset: AVCaptureSession.Preset
    
    /// Setting an options dictionary overrides all other properties set on a configuration object but allows full customization
    public var options: [String: Any]?
    
    // MARK: - object lifecycle
    
    override init() {
        self.preset = AVCaptureSession.Preset.high
        self.options = nil
        super.init()
    }
    
    // MARK: - func
    
    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Configuration dictionary for AVFoundation
    public func avcaptureSettingsDictionary(sampleBuffer: CMSampleBuffer? = nil, pixelBuffer: CVPixelBuffer? = nil) -> [String: Any]? {
        return self.options
    }
}

// MARK: - VideoConfiguration

let NextLevelVideoConfigurationDefaultBitRate: Int = 2000000

/// NextLevelVideoConfiguration, video capture configuration object
public class NextLevelVideoConfiguration: NextLevelConfiguration {

    /// Output aspect ratio, specifies dimensions for video output automatically
    public enum OutputAspectRatio: Int, CustomStringConvertible {
        case active      // active preset or specified dimensions (default)
        case standard    // 4:3
        case square      // 1:1
        case widescreen  // 16:9
        
        public var description: String {
            get {
                switch self {
                case .active:
                    return "Active"
                case .standard:
                    return "Standard"
                case .square:
                    return "Square"
                case .widescreen:
                    return "Widescreen"
                }
            }
        }
    }
    
    /// Average video bit rate (bits per second), AV dictionary key AVVideoAverageBitRateKey
    public var bitRate: Int = NextLevelVideoConfigurationDefaultBitRate

    /// Dimensions for video output, AV dictionary keys AVVideoWidthKey, AVVideoHeightKey
    public var dimensions: CGSize?

    /// Output aspect ratio automatically sizes output dimensions, `active` indicates NextLevelVideoConfiguration.preset or NextLevelVideoConfiguration.dimensions
    public var aspectRatio: OutputAspectRatio = .active

    /// Video output transform for display
    public var transform: CGAffineTransform = .identity

    /// Codec used to encode video, AV dictionary key AVVideoCodecKey
    public var codec: String

    /// Profile level for the configuration, AV dictionary key AVVideoProfileLevelKey (H.264 codec only)
    public var profileLevel: String?

    /// Video scaling mode, AV dictionary key AVVideoScalingModeKey
    public var scalingMode: String?

    /// Maximum interval between key frames, 1 meaning key frames only, AV dictionary key AVVideoMaxKeyFrameIntervalKey
    public var maxKeyFrameInterval: Int?

    /// Video time scale, value/timescale = seconds
    public var timescale: Float64?

    /// Maximum recording duration, when set, session finishes automatically
    public var maximumCaptureDuration: CMTime?
        
    // MARK: - object lifecycle
    
    override init() {
        if #available(iOS 11.0, *) {
            self.codec = AVVideoCodecType.h264.rawValue
        } else {
            self.codec = AVVideoCodecH264
        }
        self.scalingMode = AVVideoScalingModeResizeAspectFill
        super.init()
    }
    
    // MARK: - func
    
    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Video configuration dictionary for AVFoundation
    override public func avcaptureSettingsDictionary(sampleBuffer: CMSampleBuffer? = nil, pixelBuffer: CVPixelBuffer? = nil) -> [String : Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String : Any] = [:]
            
            if let dimensions = self.dimensions {
                config[AVVideoWidthKey] = NSNumber(integerLiteral: Int(dimensions.width))
                config[AVVideoHeightKey] = NSNumber(integerLiteral: Int(dimensions.height))
            } else if let sampleBuffer = sampleBuffer,
                let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
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
            
            config = updateConfigSizeValues(withConfig: config)
            
            config[AVVideoCodecKey] = self.codec
            
            if let scalingMode = self.scalingMode {
                config[AVVideoScalingModeKey] = scalingMode
            }
            
            var compressionDict: [String : Any] = [:]
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
    }
    
    /**
     With MPEG-2 and MPEG-4 (and other DCT based codecs), compression is applied to a grid of 16x16 pixel macroblocks.
     With MPEG-4 Part 10 (AVC/H.264), multiple of 4 and 8 also works, but 16 is most efficient.
     So, to prevent appearing on broken(green) pixels, the sizes of captured video must be divided by 4, 8, or 16.
     */
    private func updateConfigSizeValues(withConfig config: [String : Any], makeDividableBy dividableBy: Int? = 16) -> [String : Any] {
        var config = config
        
        if let divValue = dividableBy {
            if let width = config[AVVideoWidthKey] as? Int {
                let newWidth = width - (width % divValue)
                config[AVVideoWidthKey] = NSNumber(integerLiteral: newWidth)
            }
            if let height = config[AVVideoHeightKey] as? Int {
                let newHeight = height - (height % divValue)
                config[AVVideoHeightKey] = NSNumber(integerLiteral: newHeight)
            }
        }
        
        return config
    }
    
}

// MARK: - AudioConfiguration

let NextLevelAudioConfigurationDefaultBitRate: Int = 128000
let NextLevelAudioConfigurationDefaultSampleRate: Float64 = 44100
let NextLevelAudioConfigurationDefaultChannelsCount: Int = 2

/// NextLevelAudioConfiguration, audio capture configuration object
public class NextLevelAudioConfiguration: NextLevelConfiguration {

    /// Audio bit rate, AV dictionary key AVEncoderBitRateKey
    public var bitRate: Int = NextLevelAudioConfigurationDefaultBitRate

    /// Sample rate in hertz, AV dictionary key AVSampleRateKey
    public var sampleRate: Float64?

    /// Number of channels, AV dictionary key AVNumberOfChannelsKey
    public var channelsCount: Int?

    /// Audio data format identifier, AV dictionary key AVFormatIDKey
    /// https://developer.apple.com/reference/coreaudio/1613060-core_audio_data_types
    public var format: AudioFormatID = kAudioFormatMPEG4AAC

    // MARK: - object lifecycle
    
    override init() {
        super.init()
    }

    // MARK: - funcs

    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Audio configuration dictionary for AVFoundation
    override public func avcaptureSettingsDictionary(sampleBuffer: CMSampleBuffer? = nil, pixelBuffer: CVPixelBuffer? = nil) -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String : Any] = [AVEncoderBitRateKey : NSNumber(integerLiteral: self.bitRate)]
            
            if let sampleBuffer = sampleBuffer {
                if let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                    if let _ = self.sampleRate, let _ = self.channelsCount {
                        // loading user provided settings after buffer use
                    } else if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                        self.sampleRate = streamBasicDescription.pointee.mSampleRate
                        self.channelsCount = Int(streamBasicDescription.pointee.mChannelsPerFrame)
                    }
                    
                    var layoutSize: Int = 0
                    if let currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &layoutSize) {
                        let currentChannelLayoutData = layoutSize > 0 ? Data(bytes: currentChannelLayout, count:layoutSize) : Data()
                        config[AVChannelLayoutKey] = currentChannelLayoutData
                    }
                }
            }
            
            if let sampleRate = self.sampleRate {
                config[AVSampleRateKey] = sampleRate == 0 ? NSNumber(value: NextLevelAudioConfigurationDefaultSampleRate) : NSNumber(value: sampleRate)
            } else {
                config[AVSampleRateKey] = NSNumber(value: NextLevelAudioConfigurationDefaultSampleRate)
            }
                
            if let channels = self.channelsCount {
                config[AVNumberOfChannelsKey] = channels == 0 ? NSNumber(integerLiteral: NextLevelAudioConfigurationDefaultChannelsCount) : NSNumber(integerLiteral: channels)
            } else {
                config[AVNumberOfChannelsKey] = NSNumber(integerLiteral: NextLevelAudioConfigurationDefaultChannelsCount)
            }
            
            config[AVFormatIDKey] = NSNumber(value: self.format as UInt32)
            
            return config
        }
    }
}

// MARK: - PhotoConfiguration

/// NextLevelPhotoConfiguration, photo capture configuration object
public class NextLevelPhotoConfiguration : NextLevelConfiguration {

    /// Codec used to encode photo, AV dictionary key AVVideoCodecKey
    public var codec: String

    /// True indicates that NextLevel should generate a thumbnail for the photo
    public var generateThumbnail: Bool = false

    // MARK: - ivars
    
    // change flashMode with NextLevel.flashMode
    internal var flashMode: AVCaptureDevice.FlashMode = .off

    // MARK: - object lifecycle
    
    override init() {
        if #available(iOS 11.0, *) {
            self.codec = AVVideoCodecType.jpeg.rawValue
        } else {
            self.codec = AVVideoCodecJPEG
        }
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

@available(iOS 11.0, *)
/// NextLevelARConfiguration, augmented reality configuration object
public class NextLevelARConfiguration : NextLevelConfiguration {
    
    /// ARKit configuration
    public var config: ARConfiguration?
    
    /// ARKit session, note: the delegate queue will be overriden
    public var session: ARSession?
    
    /// Session run options
    public var runOptions: ARSession.RunOptions?
    
}

