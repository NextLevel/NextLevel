//
//  NextLevel+Additions.swift
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

import Foundation
import AVFoundation

extension NextLevel {
    
    /// Creates an offset `CMSampleBuffer` for the given time offset and duration.
    ///
    /// - Parameters:
    ///   - sampleBuffer: Input sample buffer to copy and offset.
    ///   - timeOffset: Time offset for the output sample buffer.
    ///   - duration: Optional duration for the output sample buffer.
    /// - Returns: Sample buffer with the desired time offset and duration, otherwise nil.
    public class func sampleBufferOffset(withSampleBuffer sampleBuffer: CMSampleBuffer, timeOffset: CMTime, duration: CMTime?) -> CMSampleBuffer? {
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
    
    /// Returns the available user designated storage space in bytes.
    ///
    /// - Returns: Number of available bytes in storage.
    public class func availableStorageSpaceInBytes() -> UInt64 {
        do {
            if let lastPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last {
                let attributes = try FileManager.default.attributesOfFileSystem(forPath: lastPath)
                if let freeSize = attributes[FileAttributeKey.systemFreeSize] as? UInt64 {
                    return freeSize
                }
            }
        } catch {
            print("could not determine user attributes of file system")
            return 0
        }
        return 0
    }

}
