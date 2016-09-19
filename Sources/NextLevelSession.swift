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
            return self.videoInput != nil
        }
    }
    
    public var isAudioReady: Bool {
        get {
            return self.audioInput != nil
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

    public var currentClipHasAudio: Bool {
        get {
            return self.sessionCurrentClipHasAudio
        }
    }
    
    public var currentClipHasVideo: Bool {
        get {
            return self.sessionCurrentClipHasVideo
        }
    }

    public var currentClipReady: Bool = false
    public var currentClipStarted: Bool = false
    
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
    
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?

    private var videoConfiguration: NextLevelVideoConfiguration?
    private var audioConfiguration: NextLevelAudioConfiguration?
    
    internal var sessionQueue: DispatchQueue
    internal var sessionQueueKey: DispatchSpecificKey<NSObject>
    
    private var sessionCurrentClipDuration: CMTime
    private var sessionCurrentClipHasAudio: Bool
    private var sessionCurrentClipHasVideo: Bool

    // TODO
    
    private var clipReady: Bool
    private var timeOffset: CMTime
    private var lastAudioTimestamp: CMTime
    private var lastVideoTimestamp: CMTime
    private var sessionCurrentClipStartTimestamp: CMTime
    
    //
    
    private let NextLevelSessionIdentifier = "engineering.NextLevel.session"
    private let NextLevelSessionSpecificKey = DispatchSpecificKey<NSObject>()
    
    // MARK: - object lifecycle
    
    convenience init(queue: DispatchQueue, queueKey: DispatchSpecificKey<NSObject>) {
        self.init()
        self.sessionQueue = queue
        self.sessionQueueKey = queueKey
    }
    
    override init() {
        self.sessionIdentifier = NSUUID().uuidString
        self.sessionClips = []
        self.sessionDate = Date()
        self.sessionDuration = kCMTimeZero
        
        self.sessionQueue = DispatchQueue(label: NextLevelSessionIdentifier)
        self.sessionQueue.setSpecific(key: NextLevelSessionSpecificKey, value: self.sessionQueue)
        self.sessionQueueKey = NextLevelSessionSpecificKey

        self.sessionCurrentClipDuration = kCMTimeZero
        self.sessionCurrentClipHasAudio = false
        self.sessionCurrentClipHasVideo = false
        
        //
        
        self.clipReady = false
        
        self.timeOffset = kCMTimeInvalid
        self.lastAudioTimestamp = kCMTimeInvalid
        self.lastVideoTimestamp = kCMTimeInvalid
        
        self.sessionCurrentClipStartTimestamp = kCMTimeInvalid
        
        super.init()
    }
    
    deinit {
        self.writer = nil
        self.videoInput = nil
        self.audioInput = nil
        self.pixelBufferAdapter = nil
        
        self.videoConfiguration = nil
        self.audioConfiguration = nil
        
    }
    
    // MARK: - functions
    
    // setup
    
    public func setupVideo(withSettings settings: [String : Any]?, configuration: NextLevelVideoConfiguration, formatDescription: CMFormatDescription) -> Bool {
        self.videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: settings, sourceFormatHint: formatDescription)
        if let videoInput = self.videoInput {
            videoInput.expectsMediaDataInRealTime = true
            videoInput.transform = configuration.transform
            self.videoConfiguration = configuration
            
            let videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            
            let pixelBufferAttri: [String : Any] = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
                                                    String(kCVPixelBufferWidthKey): Float(videoDimensions.width),
                                                    String(kCVPixelBufferHeightKey): Float(videoDimensions.height)]
            self.pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: pixelBufferAttri)
        }
        return self.videoInput != nil
    }
    
    public func setupAudio(withSettings settings: [String : Any]?, configuration: NextLevelAudioConfiguration, formatDescription: CMFormatDescription) -> Bool {
        self.audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: settings, sourceFormatHint: formatDescription)
        if let audioInput = self.audioInput {
            audioInput.expectsMediaDataInRealTime = true
            self.audioConfiguration = configuration
        }
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
        self.executeClosureSyncOnSessionQueueIfNecessary {
            if self.writer == nil {
                self.setupWriter()
                self.sessionCurrentClipDuration = kCMTimeZero
                self.sessionCurrentClipHasAudio = false
                self.sessionCurrentClipHasVideo = false
            } else {
                print("NextLevel, clip has already been created.")
            }
        }
    }
    
    public func endClip(completionHandler: (_ sessionClip: NextLevelSessionClip?) -> Void) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            
        }
    }
    
    // editing
    
    public func add(clip: NextLevelSessionClip) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self.sessionClips.append(clip)
            self.sessionDuration = self.sessionDuration + clip.duration
        }
    }
    
    public func add(clip: NextLevelSessionClip, at idx: Int) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self.sessionClips.insert(clip, at: idx)
            self.sessionDuration = self.sessionDuration + clip.duration
        }
    }
    
    public func remove(clip: NextLevelSessionClip) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            if let idx = self.sessionClips.index(of: clip) {
                self.sessionClips.remove(at: idx)
                self.sessionDuration = self.sessionDuration - clip.duration
            }
        }
    }
    
    public func remove(clipAt idx: Int, removeFile: Bool) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            if self.sessionClips.indices.contains(idx) {
                let clip = self.sessionClips.remove(at: idx)
                if removeFile {
                    clip.removeFile()
                }
                self.sessionDuration = self.sessionDuration - clip.duration
            }
        }
    }
    
    public func removeAllClips() {
        self.removeAllClips(removeFiles: true)
    }
    
    public func removeAllClips(removeFiles: Bool) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            while self.sessionClips.count > 0 {
                if removeFiles {
                    if let clipToRemove = self.sessionClips.first {
                        clipToRemove.removeFile()
                    }
                    self.sessionClips.removeFirst()
                }
            }
            self.sessionDuration = kCMTimeZero
        }
    }

    public func removeLastClip() {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            if self.clips.count > 0 {
                if let clipToRemove = self.clips.last {
                    self.remove(clip: clipToRemove)
                    self.sessionDuration = self.sessionDuration - clipToRemove.duration
                }
            }
        }
    }
    
    // finalize
    
    public func mergeClips(usingPreset preset: String, completionHandler: (_: URL, _: Error)-> Void) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            let fileType = self.fileType()
            
            
        }
    }
    
    // MARK: - private
    
    private func setupWriter() {
        let fileType = self.fileType()
        
//        self.writer = AVAssetWriter(url: URL, fileType: fileType)
//        if let writer = self.writer {
//            writer.metadata =
//        }
        
    }
    
    private func fileType() -> String {
        return AVFileTypeAppleM4A
    }

}

// MARK: - queues

extension NextLevelSession {
    
    internal func executeClosureAsyncOnMainQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }
    
    internal func executeClosureAsyncOnSessionQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: self.sessionQueueKey) == self.sessionQueue {
            closure()
        } else {
            self.sessionQueue.async(execute: closure)
        }
    }
    
    internal func executeClosureSyncOnSessionQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: self.sessionQueueKey) == self.sessionQueue {
            closure()
        } else {
            self.sessionQueue.sync(execute: closure)
        }
    }
}
