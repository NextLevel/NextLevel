//
//  NextLevel+Foundation.swift
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

// MARK: - Comparable

extension Comparable {

    public func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }

}

// MARK: - Data

extension Data {

    /// Outputs a `Data` object with the desired metadata dictionary
    ///
    /// - Parameter metadata: metadata dictionary to be added
    /// - Returns: JPEG formatted image data
    public func jpegData(withMetadataDictionary metadata: [String: Any]) -> Data? {
        var imageDataWithMetadata: Data?
        if let source = CGImageSourceCreateWithData(self as CFData, nil),
            let sourceType = CGImageSourceGetType(source) {
            let mutableData = NSMutableData()
            if let destination = CGImageDestinationCreateWithData(mutableData, sourceType, 1, nil) {
                CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary?)
                let success = CGImageDestinationFinalize(destination)
                if success == true {
                    imageDataWithMetadata = mutableData as Data
                } else {
                    print("could not finalize image with metadata")
                }
            }
        }
        return imageDataWithMetadata
    }

}

// MARK: - Date

extension Date {

    static let dateFormatter: DateFormatter = iso8601DateFormatter()
    fileprivate static func iso8601DateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }

    // http://nshipster.com/nsformatter/
    // http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
    public func iso8601() -> String {
        Date.iso8601DateFormatter().string(from: self)
    }

}

// MARK: - FileManager

extension FileManager {

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
