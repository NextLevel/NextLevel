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
    
    public func avcaptureDictionary() -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            return nil
        }
    }
}

// MARK: - VideoConfiguration

public class NextLevelVideoConfiguration: NextLevelConfiguration {

    public var bitRate: UInt64                      // AVEncoderBitRateKey
    
    public var dimensions: CGSize                   // AVVideoWidthKey, AVVideoHeightKey
    
    public var affineTransform: CGAffineTransform?
    
    public var codec: String                        // AVVideoCodecKey
    
    public var scalingMode: String?                 // AVVideoScalingModeKey
    
    public var maxFrameRate: CMTimeScale            // AVVideoMaxKeyFrameIntervalKey
    
    public var timeScale: CGFloat
    
    public var maximumCaptureDuration: CMTime
    
    // MARK: - class func
    
    public class func videoConfiguration(fromSampleBuffer sampleBuffer: CMSampleBuffer) -> NextLevelVideoConfiguration {
        // TODO
        return NextLevelVideoConfiguration()
    }
    
    // MARK: - object lifecycle
    
    override init() {
        self.bitRate = 2000000
        self.dimensions = CGSize(width: 0, height: 0)
        self.affineTransform = CGAffineTransform.identity
        self.codec = AVVideoCodecH264
        self.scalingMode = AVVideoScalingModeResizeAspectFill
        self.maxFrameRate = 0
        self.timeScale = 0
        self.maximumCaptureDuration = kCMTimeInvalid
        super.init()
    }
    
    // MARK: - func
    
    override public func avcaptureDictionary() -> [String : Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String: Any] = [AVEncoderBitRateKey:self.bitRate]
            config[AVVideoWidthKey] = self.dimensions.width
            config[AVVideoHeightKey] = self.dimensions.height
            config[AVVideoCodecKey] = self.codec

            if let scalingMode = self.scalingMode {
                config[AVVideoScalingModeKey] = scalingMode
            }
            
            let compressionDict = [AVVideoMaxKeyFrameIntervalKey:self.maxFrameRate]
            config[AVVideoCompressionPropertiesKey] = compressionDict
            
            return config
        }
    }
}

// MARK: - AudioConfiguration

public class NextLevelAudioConfiguration: NextLevelConfiguration {
    
    public var bitRate: UInt64          // AVEncoderBitRateKey
    
    public var sampleRate: Float64?     // AVSampleRateKey
    
    public var channelsCount: Int?      // AVNumberOfChannelsKey
    
    public var format: AudioFormatID    // AVFormatIDKey

    // MARK: - class func
    
    public class func audioConfiguration(fromSampleBuffer sampleBuffer: CMSampleBuffer) -> NextLevelAudioConfiguration {
        // TODO
        return NextLevelAudioConfiguration()
    }
    
    // MARK: - object lifecycle
    
    override init() {
        self.bitRate = 128000
        self.sampleRate = 44100
        self.channelsCount = 2
        self.format = kAudioFormatMPEG4AAC
        super.init()
    }

    // MARK: funcs
    
    override public func avcaptureDictionary() -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            var config: [String: Any] = [AVEncoderBitRateKey:self.bitRate]
            
            if let sampleRate = self.sampleRate {
                config[AVSampleRateKey] = sampleRate
            }
            
            if let channels = self.channelsCount {
                config[AVNumberOfChannelsKey] = channels
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
        
    override public func avcaptureDictionary() -> [String: Any]? {
        if let options = self.options {
            return options
        } else {
            let config: [String: Any] = [AVVideoCodecKey: self.codec]
            return config
        }
    }
    
}

