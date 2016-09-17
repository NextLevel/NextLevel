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

public class NextLevelConfiguration: NSObject {

    public var preset: String

    // setting the options dictionary overrides all other properties
    public var options: [String: Any]?
    
    // object lifecycle
    
    override init() {
        self.preset = AVCaptureSessionPresetMedium
        self.options = nil
        super.init()
    }
    
    // MARK: func
    
    public func avcaptureSettingsDictionary(withSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            return nil
        }
    }
}

// MARK: - VideoConfiguration

let NextLevelVideoConfigurationDefaultBitRate: Int = 2000000

public class NextLevelVideoConfiguration: NextLevelConfiguration {

    public var bitRate: Int                         // AVVideoAverageBitRateKey
    
    public var dimensions: CGSize?                  // AVVideoWidthKey, AVVideoHeightKey
    
    public var transform: CGAffineTransform
    
    public var codec: String                        // AVVideoCodecKey
    
    public var profileLevel: String?                // AVVideoProfileLevelKey (H.264 codec only)
    
    public var scalingMode: String?                 // AVVideoScalingModeKey
    
    public var maxFrameRate: CMTimeScale?           // AVVideoMaxKeyFrameIntervalKey
    
    public var timeScale: CGFloat?
    
    public var maximumCaptureDuration: CMTime?
    
    // TODO provide video sizing presets, ie. Square/Widescreen/etc
    
    // MARK: - object lifecycle
    
    override init() {
        self.bitRate = NextLevelVideoConfigurationDefaultBitRate
        self.transform = CGAffineTransform.identity
        self.codec = AVVideoCodecH264
        self.scalingMode = AVVideoScalingModeResizeAspectFill
        super.init()
    }
    
    // MARK: - func
    
    override public func avcaptureSettingsDictionary(withSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String : Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String : Any] = [:]
            
            if let dimensions = self.dimensions {
                config[AVVideoWidthKey] = Float(dimensions.width)
                config[AVVideoHeightKey] = Float(dimensions.height)
            } else if let buffer = sampleBuffer {
                if let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(buffer) {
                    let videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
                    config[AVVideoWidthKey] = Float(videoDimensions.width)
                    config[AVVideoHeightKey] = Float(videoDimensions.height)
                }
            }

            config[AVVideoCodecKey] = self.codec
            
            if let scalingMode = self.scalingMode {
                config[AVVideoScalingModeKey] = scalingMode
            }
            
            var compressionDict: [String : Any] = [:]
            compressionDict[AVVideoAverageBitRateKey] = self.bitRate
            compressionDict[AVVideoAllowFrameReorderingKey] = false
            compressionDict[AVVideoExpectedSourceFrameRateKey] = Int(30)
            if let profileLevel = self.profileLevel {
                compressionDict[AVVideoProfileLevelKey] = profileLevel
            }
            if let maxFrameRate = self.maxFrameRate {
                compressionDict[AVVideoMaxKeyFrameIntervalKey] = maxFrameRate
            }
            config[AVVideoCompressionPropertiesKey] = compressionDict

            return config
        }
    }
}

// MARK: - AudioConfiguration

let NextLevelAudioConfigurationDefaultBitRate: UInt64 = 128000
let NextLevelAudioConfigurationDefaultSampleRate: Float64 = 44100
let NextLevelAudioConfigurationDefaultChannelsCount: UInt32 = 2

public class NextLevelAudioConfiguration: NextLevelConfiguration {
    
    public var bitRate: UInt64          // AVEncoderBitRateKey
    
    public var sampleRate: Float64?     // AVSampleRateKey
    
    public var channelsCount: UInt32?   // AVNumberOfChannelsKey
    
    public var format: AudioFormatID    // AVFormatIDKey

    // MARK: - object lifecycle
    
    override init() {
        self.bitRate = NextLevelAudioConfigurationDefaultBitRate
        self.format = kAudioFormatMPEG4AAC
        super.init()
    }

    // MARK: funcs
    
    override public func avcaptureSettingsDictionary(withSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String : Any] = [AVEncoderBitRateKey:self.bitRate]
            
            if let buffer = sampleBuffer {
                if let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(buffer) {
                    if let _ = self.sampleRate, let _ = self.channelsCount {
                        // loading user provided settings after buffer use
                    } else if let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                        self.sampleRate = streamBasicDescription.pointee.mSampleRate
                        self.channelsCount = streamBasicDescription.pointee.mChannelsPerFrame
                    }
                    
                    var layoutSize: Int = 0
                    if let currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &layoutSize) {
                        let currentChannelLayoutData = layoutSize > 0 ? Data(bytes: currentChannelLayout, count:layoutSize) : Data()
                        config[AVChannelLayoutKey] = currentChannelLayoutData
                    }
                }
            }
            
            if let sampleRate = self.sampleRate {
                config[AVSampleRateKey] = sampleRate == 0 ? NextLevelAudioConfigurationDefaultSampleRate : sampleRate
            } else {
                config[AVSampleRateKey] = NextLevelAudioConfigurationDefaultSampleRate
            }
                
            if let channels = self.channelsCount {
                config[AVNumberOfChannelsKey] = channels == 0 ? NextLevelAudioConfigurationDefaultChannelsCount : channelsCount
            } else {
                config[AVNumberOfChannelsKey] = NextLevelAudioConfigurationDefaultChannelsCount
            }
            
            config[AVFormatIDKey] = self.format

            return config
        }
    }
}

// MARK: - PhotoConfiguration

public class NextLevelPhotoConfiguration : NextLevelConfiguration {
    
    public var codec: String        // AVVideoCodecKey
    
    // MARK: - object lifecycle
    
    override init() {
        self.codec = AVVideoCodecJPEG
        super.init()
    }
    
    // MARK: funcs
        
    public func avcaptureDictionary() -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            let config: [String: Any] = [AVVideoCodecKey: self.codec]
            return config
        }
    }
    
}

