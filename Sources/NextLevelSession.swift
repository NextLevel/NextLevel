//
//  NextLevelSession.swift
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

// MARK: - types

public enum NextLevelDirectoryType: Int, CustomStringConvertible {
    case temporary = 0
    case cache
    case document
    case custom
    
    public var description: String {
        get {
            switch self {
            case .temporary:
                return "Temporary"
            case .cache:
                return "Cache"
            case .document:
                return "Document"
            case .custom:
                return "Custom"
            }
        }
    }
}

// MARK: - NextLevelSession

public class NextLevelSession: NSObject {
    
    // config
    
//    public var directory: NextLevelDirectoryType {
//        get {
//        }
//        set {
//        }
//    }
    
//    public var fileType: String {
//        get {
//        }
//        set {
//        }
//    }
    
//    public var url: URL {
//    }

    // state
    
    public var identifier: String {
        get {
            return self.sessionIdentifier
        }
    }
    
    public var date: Date {
        get {
            return self.sessionDate
        }
    }
    
    public var isVideoReady: Bool {
        get {
            return self.videoReady
        }
    }
    
    public var isAudioReady: Bool {
        get {
            return self.audioReady
        }
    }

    public var clips: [NextLevelSessionClip] {
        get {
            return self.sessionClips
        }
    }
    
    public var duration: CMTime {
        get {
            return self.sessionDuration
        }

    }

    public var isClipReady: Bool {
        get {
            return self.clipReady
        }
    }

    public var clipDuration: CMTime {
        get {
            return self.sessionCurrentClipDuration
        }
    }

    public var currentClipReady: Bool = false // TODO
    public var currentClipStarted: Bool = false
    public var currentClipHasAudio: Bool = false
    public var currentClipHasVideo: Bool = false
    
    public var lastVideoFrame: CMSampleBuffer?
    public var lastAudioFrame: CMSampleBuffer?
        
    public var fullSessionAsset: AVAsset? {
        get {
            // TODO
            return nil
        }
    }
    
    // MARK: - private instance vars
    
    private var sessionIdentifier: String
    private var sessionClips: [NextLevelSessionClip]
    private var sessionDate: Date
    private var sessionDuration: CMTime
    
    private var videoReady: Bool
    private var audioReady: Bool
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    
    private var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    
    private var clipReady: Bool

    private var timeOffset: CMTime
    private var lastAudioTimestamp: CMTime
    private var lastVideoTimestamp: CMTime
    
    private var sessionCurrentClipDuration: CMTime
    private var sessionCurrentClipStartTimestamp: CMTime
    
    // MARK: - class functions
    
    class func session() -> NextLevelSession {
        return NextLevelSession()
    }
    
    // MARK: - object lifecycle
    
    override init() {
        self.sessionIdentifier = NSUUID().uuidString
        self.sessionClips = []
        self.sessionDate = Date()
        self.sessionDuration = kCMTimeZero
        
        self.videoReady = false
        self.audioReady = false

        //

        self.clipReady = false
        
        self.timeOffset = kCMTimeInvalid
        self.lastAudioTimestamp = kCMTimeInvalid
        self.lastVideoTimestamp = kCMTimeInvalid
        
        self.sessionCurrentClipDuration = kCMTimeZero
        self.sessionCurrentClipStartTimestamp = kCMTimeInvalid

        super.init()
    }
    
    deinit {
    }
    
    // MARK: - functions
    
    // setup
    
    public func setupVideo(withSettings settings: [String:Any], transform: CGAffineTransform, formatDescription: CMFormatDescription) -> Bool {
        return self.videoInput != nil
    }
    
    public func setupAudio(withSettings settings: [String:Any], formatDescription: CMFormatDescription) -> Bool {
        return self.audioInput != nil
    }
    
    // recording
    
    typealias NextLevelSessionCompletionHandler = (Bool)-> Void
    
    public func appendVideo(withSampleBuffer sampleBuffer: CMSampleBuffer, duration: CMTime, completionHandler: NextLevelSessionCompletionHandler) {

    }
    
    public func appendAudio(withSampleBuffer sampleBuffer: CMSampleBuffer, completionHandler: NextLevelSessionCompletionHandler) {
        
    }
    
    public func reset() {
        
    }
    
    // clip creation
    
    public func beginClip() {
        
    }
    
    public func endClip(completionHandler: (_ sessionClip: NextLevelSessionClip?) -> Void) {
        
    }
    
    // editing
    
    public func add(clip: NextLevelSessionClip) {
    }
    
    public func add(clip: NextLevelSessionClip, at idx: Int) {
    }
    
    public func remove(clip: NextLevelSessionClip) {
    }
    
    public func remove(clipAt idx: Int, deleteFile: Bool) {
    }
    
    public func removeAllClips() {
        self.removeAllClips(deleteFiles: true)
    }
    
    public func removeAllClips(deleteFiles: Bool) {
        
    }

    public func removeLastClip() {
    }
    
    // finalize
    
    public func mergeClips(usingPreset preset: String, completionHandler: (_: URL, _: Error)-> Void) {
        
    }
    
    // MARK: - private
    
    private func setupWriter() {
    }

}
