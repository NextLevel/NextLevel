//
//  NextLevel+Metadata.swift
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
    public func metadata() -> [String: Any]? {

        if let cfmetadata = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: self, attachmentMode: kCMAttachmentMode_ShouldPropagate) {
            if let metadata = cfmetadata as? [String: Any] {
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
        if let tiffDict: CFDictionary = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: kCGImagePropertyTIFFDictionary, attachmentMode: kCMAttachmentMode_ShouldPropagate) {
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
            CMSetAttachment(self, key: kCGImagePropertyTIFFDictionary, value: metaDict as CFTypeRef?, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        } else {
            CMSetAttachment(self, key: kCGImagePropertyTIFFDictionary, value: metadataAdditions as CFTypeRef?, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        }
    }

}

private let NextLevelMetadataTitle = "NextLevel"
private let NextLevelMetadataArtist = "http://github.com/NextLevel/"

extension NextLevel {

    internal class var tiffMetadata: [String: Any] {
        [ kCGImagePropertyTIFFSoftware as String: NextLevelMetadataTitle,
                 kCGImagePropertyTIFFArtist as String: NextLevelMetadataArtist,
                 kCGImagePropertyTIFFDateTime as String: Date().iso8601() ]
    }

    internal class var assetWriterMetadata: [AVMutableMetadataItem] {
        let currentDevice = UIDevice.current

        let modelItem = AVMutableMetadataItem()
        modelItem.keySpace = AVMetadataKeySpace.common
        modelItem.key = AVMetadataKey.commonKeyModel as (NSCopying & NSObjectProtocol)
        modelItem.value = currentDevice.localizedModel as (NSCopying & NSObjectProtocol)

        let softwareItem = AVMutableMetadataItem()
        softwareItem.keySpace = AVMetadataKeySpace.common
        softwareItem.key = AVMetadataKey.commonKeySoftware as (NSCopying & NSObjectProtocol)
        softwareItem.value = NextLevelMetadataTitle as (NSCopying & NSObjectProtocol)

        let artistItem = AVMutableMetadataItem()
        artistItem.keySpace = AVMetadataKeySpace.common
        artistItem.key = AVMetadataKey.commonKeyArtist as (NSCopying & NSObjectProtocol)
        artistItem.value = NextLevelMetadataArtist as (NSCopying & NSObjectProtocol)

        let creationDateItem = AVMutableMetadataItem()
        creationDateItem.keySpace = .common

        if #available(iOS 13.0, *) {
            creationDateItem.key = AVMetadataKey.commonKeyCreationDate as NSString
            creationDateItem.value = Date() as NSDate
        } else {
            creationDateItem.key = AVMetadataKey.commonKeyCreationDate as (NSCopying & NSObjectProtocol)
            creationDateItem.value = Date().iso8601() as (NSCopying & NSObjectProtocol)
        }

        return [modelItem, softwareItem, artistItem, creationDateItem]
    }

}
