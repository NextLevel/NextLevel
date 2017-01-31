//
//  NextLevel+Metadata.swift
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
import CoreMedia
import ImageIO

extension CMSampleBuffer {
    
    /// Extracts the metadata dictionary from a `CMSampleBuffer`.
    ///  (ie EXIF: Aperture, Brightness, Exposure, FocalLength, etc)
    ///
    /// - Parameter sampleBuffer: sample buffer to be processed
    /// - Returns: metadata dictionary from the provided sample buffer
    public func metadata() -> [String : Any]? {
        
        if let cfmetadata = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, self, kCMAttachmentMode_ShouldPropagate) {
            if let metadata = cfmetadata as? [String : Any] {
                return metadata
            }
        }
        return nil
        
    }
    
    /// Appends the provided metadata dictionary key/value pairs.
    ///
    /// - Parameter metadataAdditions: Metadata key/value pairs to be appended.
    public func append(metadataAdditions: [String: Any]) {
        
        // append tiff metadata to buffer for proagation
        if let tiffDict: CFDictionary = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, kCGImagePropertyTIFFDictionary, kCMAttachmentMode_ShouldPropagate) {
            let tiffNSDict = tiffDict as NSDictionary
            var metaDict: [String: Any] = [:]
            for (key, value) in metadataAdditions {
                metaDict.updateValue(value as AnyObject, forKey: key)
            }
            for (key, value) in tiffNSDict {
                if let keyString = key as? String {
                    metaDict.updateValue(value as AnyObject, forKey: keyString)
                }
            }
            CMSetAttachment(self, kCGImagePropertyTIFFDictionary, metaDict as CFTypeRef?, kCMAttachmentMode_ShouldPropagate)
        } else {
            CMSetAttachment(self, kCGImagePropertyTIFFDictionary, metadataAdditions as CFTypeRef?, kCMAttachmentMode_ShouldPropagate)
        }
    }
    
}

fileprivate let NextLevelMetadataTitle = "NextLevel"
fileprivate let NextLevelMetadataArtist = "http://nextlevel.engineering/"

extension NextLevel {
    
    internal class func tiffMetadata() -> [String: Any] {
        return [ kCGImagePropertyTIFFSoftware as String : NextLevelMetadataTitle,
                 kCGImagePropertyTIFFArtist as String : NextLevelMetadataArtist,
                 kCGImagePropertyTIFFDateTime as String : Date().iso8601() ]
    }
    
    internal class func assetWriterMetadata() -> [AVMutableMetadataItem] {
        let currentDevice = UIDevice.current
        
        let modelItem = AVMutableMetadataItem()
        modelItem.keySpace = AVMetadataKeySpaceCommon
        modelItem.key = AVMetadataCommonKeyModel as (NSCopying & NSObjectProtocol)
        modelItem.value = currentDevice.localizedModel as (NSCopying & NSObjectProtocol)
        
        let softwareItem = AVMutableMetadataItem()
        softwareItem.keySpace = AVMetadataKeySpaceCommon
        softwareItem.key = AVMetadataCommonKeySoftware as (NSCopying & NSObjectProtocol)
        softwareItem.value = NextLevelMetadataTitle as (NSCopying & NSObjectProtocol)
        
        let artistItem = AVMutableMetadataItem()
        artistItem.keySpace = AVMetadataKeySpaceCommon
        artistItem.key = AVMetadataCommonKeyArtist as (NSCopying & NSObjectProtocol)
        artistItem.value = NextLevelMetadataArtist as (NSCopying & NSObjectProtocol)
        
        let creationDateItem = AVMutableMetadataItem()
        creationDateItem.keySpace = AVMetadataKeySpaceCommon
        creationDateItem.key = AVMetadataCommonKeyCreationDate as (NSCopying & NSObjectProtocol)
        creationDateItem.value = Date().iso8601() as (NSCopying & NSObjectProtocol)
        
        return [modelItem, softwareItem, artistItem, creationDateItem]
    }

}

// MARK: - Date extensions

extension Date {
    
    static let dateFormatter: DateFormatter = iso8601DateFormatter()
    fileprivate static func iso8601DateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }

    // http://nshipster.com/nsformatter/
    // http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
    fileprivate func iso8601() -> String {
        return Date.iso8601DateFormatter().string(from: self)
    }
    
}

// MARK: - Data extensions

extension Data {

    /// Outputs a `Data` object with the desired metadata dictionary
    ///
    /// - Parameter metadata: metadata dictionary to be added
    /// - Returns: JPEG formatted image data
    public func jpegData(withMetadataDictionary metadata: [String: Any]) -> Data? {
        var imageDataWithMetadata: Data? = nil
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
