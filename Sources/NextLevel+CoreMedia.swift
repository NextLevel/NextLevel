//
//  NextLevel+CoreVideo.swift
//  NextLevel
//
//  Created by Patrick Piemonte on 9/18/17.
//  Copyright © 2017 NextLevel. All rights reserved.
//

import CoreMedia
import Foundation

extension CMSampleBuffer {
    
    /// Creates an offset `CMSampleBuffer` for the given time offset and duration.
    ///
    /// - Parameters:
    ///   - sampleBuffer: Input sample buffer to copy and offset.
    ///   - timeOffset: Time offset for the output sample buffer.
    ///   - duration: Optional duration for the output sample buffer.
    /// - Returns: Sample buffer with the desired time offset and duration, otherwise nil.
    public class func createSampleBuffer(fromSampleBuffer sampleBuffer: CMSampleBuffer, withTimeOffset timeOffset: CMTime, duration: CMTime?) -> CMSampleBuffer? {
        var itemCount: CMItemCount = 0
        var status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &itemCount)
        if status != 0 {
            return nil
        }
        
        var timingInfo = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(0, 0), presentationTimeStamp: CMTimeMake(0, 0), decodeTimeStamp: CMTimeMake(0, 0)), count: itemCount)
        status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, itemCount, &timingInfo, &itemCount);
        if status != 0 {
            return nil
        }
        
        if let dur = duration {
            for i in 0 ..< itemCount {
                timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset);
                timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset);
                timingInfo[i].duration = dur
            }
        } else {
            for i in 0 ..< itemCount {
                timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset);
                timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset);
            }
        }
        
        var sampleBufferOffset: CMSampleBuffer? = nil
        CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, itemCount, &timingInfo, &sampleBufferOffset);
        
        if let output = sampleBufferOffset {
            return output
        } else {
            return nil
        }
    }
    
}
