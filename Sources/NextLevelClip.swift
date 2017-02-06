//
//  NextLevelClip.swift
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

// NextLevelClip dictionary representation keys

public let NextLevelClipFilenameKey = "NextLevelClipFilenameKey"
public let NextLevelClipInfoDictKey = "NextLevelClipInfoDictKey"

/// NextLevelClip, an object for managing a single media clip
public class NextLevelClip: NSObject {

    /// URL of the clip
    public var url: URL? {
        didSet {
            self._asset = nil
        }
    }
    
    /// True, if the clip's file exists
    public var fileExists: Bool {
        get {
            if let url = self.url {
                return FileManager.default.fileExists(atPath: url.path)
            }
            return false
        }
    }
    
    /// `AVAsset` of the clip
    public var asset: AVAsset? {
        get {
            if let url = self.url {
                if self._asset == nil {
                    self._asset = AVAsset(url: url)
                }
            }
            return self._asset
        }
    }
    
    /// Duration of the clip, otherwise invalid.
    public var duration: CMTime {
        get {
            if let asset = self.asset {
                return asset.duration
            }
            return kCMTimeZero
        }
    }
    
    /// If it doesn't already exist, generates a thumbnail image of the clip.
    public var thumbnailImage: UIImage? {
        get {
            guard
                self._thumbnailImage == nil
            else {
                return self._thumbnailImage
            }
            
            if let asset = self.asset {
                let imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                do {
                    let cgimage: CGImage = try imageGenerator.copyCGImage(at: kCMTimeZero, actualTime: nil)
                    let uiimage: UIImage = UIImage(cgImage: cgimage)
                    self._thumbnailImage = uiimage
                } catch {
                    print("NextLevel, unable to generate lastFrameImage for \(self.url)")
                    self._thumbnailImage = nil
                }
            }
            return self._thumbnailImage
        }
    }
    
    /// If it doesn't already exist, generates an image for the last frame of the clip.
    public var lastFrameImage: UIImage? {
        get {
            guard
                self._lastFrameImage == nil
            else {
                return self._lastFrameImage
            }
            
            if let asset = self.asset {
                let imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
            
                do {
                    let cgimage: CGImage = try imageGenerator.copyCGImage(at: self.duration, actualTime: nil)
                    let uiimage: UIImage = UIImage(cgImage: cgimage)
                    self._lastFrameImage = uiimage
                } catch {
                    print("NextLevel, unable to generate lastFrameImage for \(self.url)")
                    self._lastFrameImage = nil
                }
            }
            return self._lastFrameImage
        }
    }
    
    /// Frame rate at which the asset was recorded.
    public var frameRate: Float {
        get {
            if let asset = self.asset {
                let tracks: [AVAssetTrack] = asset.tracks(withMediaType: AVMediaTypeVideo)
                if tracks.count > 0 {
                    if let videoTrack = tracks.first {
                        return videoTrack.nominalFrameRate
                    }
                }
            }
            return 0
        }
    }
    
    /// Dictionary containing metadata about the clip.
    public var infoDict: [String: Any]? {
        get {
            return self._infoDict
        }
    }
    
    /// Dictionary containing data for re-initialization of the clip.
    public var representationDict: [String:Any]? {
        get {
            if let infoDict = self.infoDict, let url = self.url {
                return [NextLevelClipFilenameKey:url.lastPathComponent,
                        NextLevelClipInfoDictKey:infoDict]
            } else if let url = self.url {
                return [NextLevelClipFilenameKey:url.lastPathComponent]
            } else {
                return nil
            }
        }
    }
    
    // MARK: - class functions
    
    /// Class method initializer for a clip URL
    ///
    /// - Parameters:
    ///   - filename: Filename for the media asset
    ///   - directoryPath: Directory path for the media asset
    /// - Returns: Returns a URL for the designated clip, otherwise nil
    public class func clipURL(withFilename filename: String, directoryPath: String) -> URL? {
        var clipURL: URL = URL(fileURLWithPath: directoryPath)
        clipURL.appendPathComponent(filename)
        return clipURL
    }
    
    /// Class method initializer for a NextLevelClip
    ///
    /// - Parameters:
    ///   - url: URL of the media asset
    ///   - infoDict: Dictionary containing metadata about the clip
    /// - Returns: Returns a NextLevelClip
    public class func clip(withUrl url: URL?, infoDict: [String: Any]?) -> NextLevelClip {
        return NextLevelClip(url: url, infoDict: infoDict)
    }
    
    // MARK: - private instance vars
    
    internal var _asset: AVAsset?
    internal var _infoDict: [String : Any]?
    internal weak var _thumbnailImage: UIImage?
    internal weak var _lastFrameImage: UIImage?
    
    // MARK: - object lifecycle
    
    override init() {
        super.init()
    }
    
    /// Initialize a clip from a URL and dictionary.
    ///
    /// - Parameters:
    ///   - url: URL and filename of the specified media asset
    ///   - infoDict: Dictionary with NextLevelClip metadata information
    convenience init(url: URL?, infoDict: [String : Any]?) {
        self.init()
        self.url = url
        self._infoDict = infoDict
    }
    
    /// Initialize a clip from a dictionary representation and directory name
    ///
    /// - Parameters:
    ///   - directoryPath: Directory where the media asset is located
    ///   - representationDict: Dictionary containing defining metadata about the clip
    convenience init(directoryPath: String, representationDict: [String : Any]?) {
        if let clipDict = representationDict,
           let filename = clipDict[NextLevelClipFilenameKey] as? String,
           let url: URL = NextLevelClip.clipURL(withFilename: filename, directoryPath: directoryPath) {
            let infoDict = clipDict[NextLevelClipInfoDictKey] as? [String : Any]
            self.init(url: url, infoDict: infoDict)
        } else {
            self.init()
        }
    }
    
    deinit {
    }
    
    // MARK: - functions
    
    /// Removes the associated file representation on disk.
    public func removeFile()  {
        do {
            if let url = self.url {
                try FileManager.default.removeItem(at: url)
                self.url = nil
            }
        } catch {
            print("NextLevel, error deleting a clip's file \(self.url)")
        }
    }
    
}
