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

// MARK: - MediaTypeConfiguration

/// NextLevelConfiguration, media capture configuration object
public class NextLevelConfiguration: NSObject {

    /// AVFoundation configuration preset.
    public var preset: String
    
    /// Setting an options dictionary overrides all other properties set on a configuration object but allows full customization
    public var options: [String: Any]?
    
    // MARK: - object lifecycle
    
    override init() {
        self.preset = AVCaptureSessionPresetHigh
        self.options = nil
        super.init()
    }
    
    // MARK: - func
    
    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Configuration dictionary for AVFoundation
    public func avcaptureSettingsDictionary(withSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String: Any]? {
        return self.options
    }
}

// MARK: - VideoConfiguration

let NextLevelVideoConfigurationDefaultBitRate: Int = 2000000

/// NextLevelVideoConfiguration, video capture configuration object
public class NextLevelVideoConfiguration: NextLevelConfiguration {

    /// Average video bit rate (bits per second), AV dictionary key AVVideoAverageBitRateKey
    public var bitRate: Int

    /// Dimensions for video output, AV dictionary keys AVVideoWidthKey, AVVideoHeightKey
    public var dimensions: CGSize?

    /// Video output transform for display
    public var transform: CGAffineTransform

    /// Codec used to encode video, AV dictionary key AVVideoCodecKey
    public var codec: String

    /// Profile level for the configuration, AV dictionary key AVVideoProfileLevelKey (H.264 codec only)
    public var profileLevel: String?

    /// Video scaling mode, AV dictionary key AVVideoScalingModeKey
    public var scalingMode: String?

    /// Maximum interval between frame keys, AV dictionary key AVVideoMaxKeyFrameIntervalKey
    public var maxFrameRate: CMTimeScale?

    /// Video time scale, value/timescale = seconds
    public var timescale: Float64?

    /// Maximum recording duration, when set, session finishes automatically
    public var maximumCaptureDuration: CMTime?
        
    // MARK: - object lifecycle
    
    override init() {
        self.bitRate = NextLevelVideoConfigurationDefaultBitRate
        self.transform = CGAffineTransform.identity
        self.codec = AVVideoCodecH264
        self.scalingMode = AVVideoScalingModeResizeAspectFill
        super.init()
    }
    
    // MARK: - func
    
    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Video configuration dictionary for AVFoundation
    override public func avcaptureSettingsDictionary(withSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String : Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String : Any] = [:]
            
            if let dimensions = self.dimensions {
                config[AVVideoWidthKey] = NSNumber(value: Float(dimensions.width))
                config[AVVideoHeightKey] = NSNumber(value: Float(dimensions.height))
            } else if let buffer = sampleBuffer {
                if let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(buffer) {
                    let videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
                    config[AVVideoWidthKey] = NSNumber(value: Float(videoDimensions.width))
                    config[AVVideoHeightKey] = NSNumber(value: Float(videoDimensions.height))
                }
            }

            config[AVVideoCodecKey] = self.codec
            
            if let scalingMode = self.scalingMode {
                config[AVVideoScalingModeKey] = scalingMode
            }
            
            var compressionDict: [String : Any] = [:]
            compressionDict[AVVideoAverageBitRateKey] = NSNumber(value: self.bitRate)
            compressionDict[AVVideoAllowFrameReorderingKey] = NSNumber(value: false)
            compressionDict[AVVideoExpectedSourceFrameRateKey] = NSNumber(value: Int(30))
            if let profileLevel = self.profileLevel {
                compressionDict[AVVideoProfileLevelKey] = (profileLevel as NSString)
            }
            if let maxFrameRate = self.maxFrameRate {
                compressionDict[AVVideoMaxKeyFrameIntervalKey] = NSNumber(value: maxFrameRate)
            }
            config[AVVideoCompressionPropertiesKey] = (compressionDict as NSDictionary)
            return config
        }
    }
}

// MARK: - AudioConfiguration

let NextLevelAudioConfigurationDefaultBitRate: Int = 128000
let NextLevelAudioConfigurationDefaultSampleRate: Float64 = 44100
let NextLevelAudioConfigurationDefaultChannelsCount: Int = 2

/// NextLevelAudioConfiguration, audio capture configuration object
public class NextLevelAudioConfiguration: NextLevelConfiguration {

    /// Audio bit rate, AV dictionary key AVEncoderBitRateKey
    public var bitRate: Int

    /// Sample rate in hertz, AV dictionary key AVSampleRateKey
    public var sampleRate: Float64?

    /// Number of channels, AV dictionary key AVNumberOfChannelsKey
    public var channelsCount: Int?

    /// Audio data format identifier, AV dictionary key AVFormatIDKey
    /// https://developer.apple.com/reference/coreaudio/1613060-core_audio_data_types
    public var format: AudioFormatID

    // MARK: - object lifecycle
    
    override init() {
        self.bitRate = NextLevelAudioConfigurationDefaultBitRate
        self.format = kAudioFormatMPEG4AAC
        super.init()
    }

    // MARK: - funcs

    /// Provides an AVFoundation friendly dictionary for configuring output.
    ///
    /// - Parameter sampleBuffer: Sample buffer for extracting configuration information
    /// - Returns: Audio configuration dictionary for AVFoundation
    override public func avcaptureSettingsDictionary(withSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String : Any] = [AVEncoderBitRateKey : NSNumber(value: self.bitRate)]
            
            if let buffer = sampleBuffer {
                if let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(buffer) {
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
                config[AVNumberOfChannelsKey] = channels == 0 ? NSNumber(value: NextLevelAudioConfigurationDefaultChannelsCount) : NSNumber(value: channels)
            } else {
                config[AVNumberOfChannelsKey] = NSNumber(value: NextLevelAudioConfigurationDefaultChannelsCount)
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
    public var generateThumbnail: Bool
    
    // MARK: - object lifecycle
    
    override init() {
        self.codec = AVVideoCodecJPEG
        self.generateThumbnail = false
        self.flashMode = .off
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
            if generateThumbnail == true {
                let settings = AVCapturePhotoSettings()
                if settings.availablePreviewPhotoPixelFormatTypes.count > 0 {
                    config[kCVPixelBufferPixelFormatTypeKey as String] = settings.availablePreviewPhotoPixelFormatTypes[0]
                }
            }
            return config
        }
    }
    
    // change flashMode with NextLevel.flashMode
    internal var flashMode: AVCaptureFlashMode
}

