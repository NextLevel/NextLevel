//
//  NextLevelConfiguration.swift
//  NextLevel
//
//  Copyright (c) 2015 NextLevel (http://nextlevel.engineering/)
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

import UIKit
import Foundation
import AVFoundation

// MARK: - MediaTypeConfiguration

public protocol MediaTypeConfigurationDelegate {
    
    func mediaTypeConfigurationEnabledDidChange(mediaTypeConfiguration: MediaTypeConfiguration, enabled: Bool)
    
}

class MediaTypeConfiguration {
    
    /**
    Whether this media type is enabled or not.
    */
    var enabled: Bool = true {
        didSet {
            if oldValue != self.enabled {
                if let delegate = self.delegate {
                    delegate.mediaTypeConfigurationEnabledDidChange(self, enabled: self.enabled)
                }
            }
        }
    }
        
    var options: [NSObject: AnyObject]?
    
    var delegate: MediaTypeConfigurationDelegate?
   
}

// MARK: - AudioConfiguration

class AudioConfiguration: MediaTypeConfiguration {
    
    /**
    Set the bitrate of the audio
    */
    var bitrate = 128000
    
    /**
    Defines a preset to use. If set, most properties will be
    ignored to use values that reflect this preset.
    */
    var preset : QualityPreset? = nil
    
    /**
    Set the sample rate of the audio
    If not set, the original sample rate will be used.
    */
    var sampleRate: Int? = nil
    
    /**
    Set the number of channels
    If not set, the original channels number will be used.
    */
    var channelsCount: Int? = nil
    
    /**
    Must be like kAudioFormat* (example kAudioFormatMPEGLayer3)
    */
    var format = kAudioFormatMPEG4AAC
    
    /**
    The audioMix to apply.
    
    Only used in Exporter.
    */
    var audioMix: AVAudioMix? = nil
}

extension AudioConfiguration {
    
    func createAssetWriterOptionsUsingSampleBuffer(samplebuffer: CMSampleBufferRef?) -> [NSObject: AnyObject] {
        if let options = self.options {
            return options
        }
        
        var sampleRate = self.sampleRate
        var channels = self.channelsCount
        var bitrate = self.bitrate
        
        if let preset = self.preset {
            switch preset {
            case .Highest:
                bitrate = 320000
            case .Medium:
                bitrate = 128000
            case .Low:
                bitrate = 64000
                channels = 1
            }
        }
        
        if let samplebuffer = samplebuffer {
            let formatDescription = CMSampleBufferGetFormatDescription(samplebuffer)
            let streamBaiscDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
            
            if sampleRate == nil {
                sampleRate = Int(streamBaiscDescription.memory.mSampleRate)
            }
            
            if channels == nil {
                channels = Int(streamBaiscDescription.memory.mChannelsPerFrame)
            }
        }
        
        if sampleRate == nil {
            sampleRate = 44100
        }
        
        if channels == nil {
            channels = 2
        }
        
        return [
            AVFormatIDKey : self.format,
            AVEncoderBitRateKey : bitrate,
            AVNumberOfChannelsKey : channels!,
            AVSampleRateKey : sampleRate!
        ]
    }

}

// MARK: - PhotoConfiguration

class PhotoConfiguration : MediaTypeConfiguration {
    
}

extension PhotoConfiguration {
    
    func createOutputSettings() -> [NSObject: AnyObject] {
        if let options = self.options {
            return options
        }
        
        return [
            AVVideoCodecKey : AVVideoCodecJPEG
        ]
    }
    
}

// MARK: - VideoConfiguration

class VideoConfiguration : MediaTypeConfiguration {
    
    /**
    Set the bitrate of the video
    */
    var bitrate = 2000000
    
    /**
    Defines a preset to use. If set, most properties will be
    ignored to use values that reflect this preset.
    */
    var preset : QualityPreset? = nil
    
    /**
    Change the size of the video
    If not set, the input video size received from the camera will be used
    Default is nil
    */
    var size: CGSize? = nil
    
    /**
    Change the affine transform for the video
    If options has been changed, this property will be ignored
    */
    var affineTransform: CGAffineTransform? = nil
    
    /**
    Set the codec used for the video
    Default is AVVideoCodecH264
    */
    var codec = AVVideoCodecH264
    
    /**
    Set the video scaling mode
    */
    var scalingMode = AVVideoScalingModeResizeAspectFill
    
    /**
    The maximum framerate that this SCRecordSession should handle
    If the camera appends too much frames, they will be dropped.
    If not set, it will use the current framerate from the camera.
    */
    var maxFrameRate: Int? = nil
    
    /**
    The time scale of the video
    A value more than 1 will make the buffers last longer, it creates
    a slow motion effect. A value less than 1 will make the buffers be
    shorter, it creates a timelapse effect.
    
    Only used in Recorder.
    */
    var timeScale: Float = 1
    
    /**
    If true and videoSize is CGSizeZero, the videoSize
    used will equal to the minimum width or height found,
    thus making the video square.
    */
    var sizeAsSquare = false
    
    /**
    If true, each frame will be encoded as a keyframe
    This is needed if you want to merge the recordSegments using
    the passthrough preset. This will seriously impact the video
    size. You can set this to NO and change the recordSegmentsMergePreset if you want
    a better quality/size ratio, but the merge will be slower.
    Default is NO
    */
    var shouldKeepOnlyKeyFrames = false
    
    /**
    If not nil, each appended frame will be processed by this SCFilter.
    While it seems convenient, this removes the possibility to change the
    filter after the segment has been added.
    Setting a new filter will cause the SCRecordSession to stop the
    current record segment if the previous filter was NIL and the
    new filter is NOT NIL or vice versa. If you want to have a smooth
    transition between filters in the same record segment, make sure to set
    an empty SCFilterGroup instead of setting this property to nil.
    */
    var filter: Filter? = nil
    
    /**
    The video composition to use.
    
    Only used in Exporter.
    */
    var composition: AVVideoComposition? = nil
    
    /**
    The watermark to use. If the composition is not set, this watermark
    image will be applied on the exported video.
    
    Only used in Exporter.
    */
    var watermarkImage: UIImage? = nil
    
    /**
    The watermark image location and size in the input video frame coordinates.
    
    Only used in Exporter.
    */
    var watermarkFrame = CGSizeZero
    
    /**
    Set a specific key to the video profile
    */
    var profileLevel: String? = nil
    
    /**
    The watermark anchor location.
    
    Default is top left
    
    Only used in Exporter.
    */
    var watermarkAnchorLocation = WatermarkAnchorLocation.TopLeft
    
}

extension VideoConfiguration {
    
    func createAssetWriterOptionsWithVideoSize(videoSize: CGSize) -> [NSObject: AnyObject] {
        if let options = self.options {
            return options;
        }
        
        var outputSize = self.size;
        var bitrate = self.bitrate;
    
        if let preset = self.preset {
            switch preset {
            case .Highest:
                bitrate = 6000000
                outputSize = self.makeVideoSize(videoSize, requestedWidth: 1920)
            case .Medium:
                bitrate = 1000000
                outputSize = self.makeVideoSize(videoSize, requestedWidth: 1280)
            case .Low:
                bitrate = 500000
                outputSize = self.makeVideoSize(videoSize, requestedWidth: 640)
            }
        }
        
        if outputSize == nil {
            outputSize = videoSize
        }
        
        if self.sizeAsSquare {
            if videoSize.width > videoSize.height {
                outputSize!.width = videoSize.height;
            } else {
                outputSize!.height = videoSize.width;
            }
        }
        
        var compressionSettings: [NSObject: AnyObject] = [AVVideoAverageBitRateKey : bitrate]

        if self.shouldKeepOnlyKeyFrames {
            compressionSettings[AVVideoMaxKeyFrameIntervalKey] = 1
        }
        
        if let profileLevel = self.profileLevel {
            compressionSettings[AVVideoProfileLevelKey] = profileLevel
        }
        
        compressionSettings[AVVideoAllowFrameReorderingKey] = false
        
        return [
            AVVideoCodecKey : self.codec,
            AVVideoScalingModeKey : self.scalingMode,
            AVVideoWidthKey : outputSize!.width,
            AVVideoHeightKey : outputSize!.height,
            AVVideoCompressionPropertiesKey : compressionSettings
        ]
    }
    
    func createAssetWriterOptionsUsingSampleBuffer(samplebuffer: CMSampleBufferRef) -> [NSObject: AnyObject] {
        let imageBuffer = CMSampleBufferGetImageBuffer(samplebuffer)
        let width = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        
        return self.createAssetWriterOptionsWithVideoSize(CGSizeMake(width, height))
    }
    
    func makeVideoSize(videoSize: CGSize, requestedWidth: CGFloat) -> CGSize {
        let ratio = videoSize.width / requestedWidth;
        
        if (ratio <= 1) {
            return videoSize;
        }
        
        return CGSizeMake(videoSize.width / ratio, videoSize.height / ratio);
    }

}
