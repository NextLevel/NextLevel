//
//  NextLevel+CMSampleBuffer.swift
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
        var status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &itemCount)
        if status != 0 {
            return nil
        }

        var timingInfo = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(value: 0, timescale: 0), presentationTimeStamp: CMTimeMake(value: 0, timescale: 0), decodeTimeStamp: CMTimeMake(value: 0, timescale: 0)), count: itemCount)
        status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: itemCount, arrayToFill: &timingInfo, entriesNeededOut: &itemCount)
        if status != 0 {
            return nil
        }

        if let dur = duration {
            for i in 0 ..< itemCount {
                timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset)
                timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset)
                timingInfo[i].duration = dur
            }
        } else {
            for i in 0 ..< itemCount {
                timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset)
                timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset)
            }
        }

        var sampleBufferOffset: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleTimingEntryCount: itemCount, sampleTimingArray: &timingInfo, sampleBufferOut: &sampleBufferOffset)

        if let output = sampleBufferOffset {
            return output
        } else {
            return nil
        }
    }

}
