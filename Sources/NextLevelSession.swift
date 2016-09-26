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

// MARK: - NextLevelSession

public class NextLevelSession: NSObject {
    
    // config
    
    public var url: URL? {
        get {
            let fileType = self.fileType()
            let fileExtension = self.fileExtension(fileType: fileType)
            let filename = "\(self.identifier)-NL-merged.\(fileExtension)"
            if let url = NextLevelClip.clipURL(withFilename: filename, directory: self.sessionDirectory) {
                return url
            } else {
                return nil
            }
        }
    }
    
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

    public var clips: [NextLevelClip] {
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

    public var currentClipDuration: CMTime {
        get {
            return self.sessionCurrentClipDuration
        }
    }

    public var currentClipHasVideo: Bool {
        get {
            return self.sessionCurrentClipHasVideo
        }
    }

    public var currentClipHasAudio: Bool {
        get {
            return self.sessionCurrentClipHasAudio
        }
    }
    
    public var lastVideoFrame: CMSampleBuffer? {
        get {
            return self.sessionLastVideoFrame
        }
    }
    
    public var lastAudioFrame: CMSampleBuffer? {
        get {
            return self.sessionLastAudioFrame
        }
    }
    
    public var asset: AVAsset? {
        get {
            var asset: AVAsset? = nil
            self.executeClosureSyncOnSessionQueueIfNecessary {
                if self.sessionClips.count == 1 {
                    asset = self.sessionClips.first?.asset
                } else {
                    let composition: AVMutableComposition = AVMutableComposition()
                    self.appendClips(toComposition: composition)
                    asset = composition
                }
            }
            return asset
        }
    }
    
    public var pixelBufferPool: CVPixelBufferPool? {
        get {
            if let pixelBufferAdapter = self.pixelBufferAdapter, let pool = pixelBufferAdapter.pixelBufferPool {
                return pool
            }
            return nil
        }
    }
    
    // MARK: - private instance vars
    
    internal var sessionIdentifier: String
    internal var sessionDirectory: String
    internal var sessionDate: Date
    internal var sessionDuration: CMTime

    internal var sessionClips: [NextLevelClip]
    internal var sessionClipFilenameCount: Int

    internal var writer: AVAssetWriter?
    internal var videoInput: AVAssetWriterInput?
    internal var audioInput: AVAssetWriterInput?
    internal var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?

    internal var videoConfiguration: NextLevelVideoConfiguration?
    internal var audioConfiguration: NextLevelAudioConfiguration?
    
    internal var audioQueue: DispatchQueue
    internal var sessionQueue: DispatchQueue
    internal var sessionQueueKey: DispatchSpecificKey<NSObject>
    
    internal var sessionCurrentClipDuration: CMTime
    internal var sessionCurrentClipHasAudio: Bool
    internal var sessionCurrentClipHasVideo: Bool

    internal var clipReady: Bool
    internal var timeOffset: CMTime
    internal var startTimestamp: CMTime
    internal var lastAudioTimestamp: CMTime
    internal var lastVideoTimestamp: CMTime
    
    internal var sessionLastVideoFrame: CMSampleBuffer?
    internal var sessionLastAudioFrame: CMSampleBuffer?
    
    private let NextLevelSessionAudioQueueIdentifier = "engineering.NextLevel.session.audioQueue"
    private let NextLevelSessionQueueIdentifier = "engineering.NextLevel.sessionQueue"
    private let NextLevelSessionSpecificKey = DispatchSpecificKey<NSObject>()
    
    // MARK: - object lifecycle
    
    convenience init(queue: DispatchQueue, queueKey: DispatchSpecificKey<NSObject>) {
        self.init()
        self.sessionQueue = queue
        self.sessionQueueKey = queueKey
    }
    
    override init() {
        self.sessionIdentifier = NSUUID().uuidString
        self.sessionDirectory = NSTemporaryDirectory()
        self.sessionClips = []
        self.sessionClipFilenameCount = 0
        self.sessionDate = Date()
        self.sessionDuration = kCMTimeZero
     
        self.audioQueue = DispatchQueue(label: NextLevelSessionAudioQueueIdentifier)

        // should always use init(queue:queueKey:), but this may be good for the future
        self.sessionQueue = DispatchQueue(label: NextLevelSessionQueueIdentifier)
        self.sessionQueue.setSpecific(key: NextLevelSessionSpecificKey, value: self.sessionQueue)
        self.sessionQueueKey = NextLevelSessionSpecificKey

        self.sessionCurrentClipDuration = kCMTimeZero
        self.sessionCurrentClipHasAudio = false
        self.sessionCurrentClipHasVideo = false
        
        self.clipReady = false
        self.timeOffset = kCMTimeInvalid
        self.startTimestamp = kCMTimeInvalid
        self.lastAudioTimestamp = kCMTimeInvalid
        self.lastVideoTimestamp = kCMTimeInvalid
        
        super.init()
    }
    
    deinit {
        self.writer = nil
        self.videoInput = nil
        self.audioInput = nil
        self.pixelBufferAdapter = nil
        
        self.videoConfiguration = nil
        self.audioConfiguration = nil
    
        self.sessionLastVideoFrame = nil
        self.sessionLastAudioFrame = nil
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
    
    internal func setupWriter() {
        if let url = self.nextFileURL() {
            do {
                self.writer = try AVAssetWriter(url: url, fileType: self.fileType())
                if let writer = self.writer {
                    writer.shouldOptimizeForNetworkUse = true
                    writer.metadata = NextLevel.assetWriterMetadata()
                    
                    if let videoInput = self.videoInput {
                        if writer.canAdd(videoInput) {
                            writer.add(videoInput)
                        } else {
                            print("NextLevel, could not add video input to session")
                        }
                    }
                    
                    if let audioInput = self.audioInput {
                        if writer.canAdd(audioInput) {
                            writer.add(audioInput)
                        } else {
                            print("NextLevel, could not add audio input to session")
                        }
                    }
                    
                    if writer.startWriting() {
                        self.clipReady = true
                        self.timeOffset = kCMTimeZero
                        self.startTimestamp = kCMTimeInvalid
                    } else {
                        print("NextLevel, writer encountered an error \(writer.error)")
                        self.writer = nil
                    }
                }
            } catch {
                print("NextLevel could not create asset writer")
            }
        }
    }
    
    internal func destroyWriter() {
        self.writer = nil
        self.clipReady = false
        self.timeOffset = kCMTimeZero
        self.startTimestamp = kCMTimeInvalid
        self.sessionCurrentClipDuration = kCMTimeZero
        self.sessionCurrentClipHasVideo = false
        self.sessionCurrentClipHasAudio = false
    }
}

// MARK: - recording/editing

extension NextLevelSession {
    
    // recording
    
    public typealias NextLevelSessionAppendSampleBufferCompletionHandler = (_: Bool) -> Void
    
    public func appendVideo(withSampleBuffer sampleBuffer: CMSampleBuffer, minFrameDuration: CMTime, completionHandler: NextLevelSessionAppendSampleBufferCompletionHandler) {
        self.sessionLastVideoFrame = sampleBuffer
        
        if let pixelBufferImage = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.startSessionIfNecessary(timestamp: timestamp)
            
            var frameDuration = minFrameDuration
            let offsetBufferTimestamp = timestamp - self.timeOffset
            
            if let videoConfig = self.videoConfiguration, let timeScale = videoConfig.timeScale {
                if timeScale != 1.0 {
                    let scaledDuration = CMTimeMultiplyByFloat64(duration, timeScale)
                    if self.sessionCurrentClipDuration.value > 0 {
                        self.timeOffset = self.timeOffset + (duration - scaledDuration)
                    }
                    frameDuration = scaledDuration
                }
            }
            
            if let videoInput = self.videoInput, let pixelBufferAdapter = self.pixelBufferAdapter {
                if videoInput.isReadyForMoreMediaData && pixelBufferAdapter.append(pixelBufferImage, withPresentationTime: offsetBufferTimestamp) {
                    self.sessionCurrentClipDuration = (offsetBufferTimestamp + frameDuration) - self.startTimestamp
                    self.lastVideoTimestamp = timestamp
                    self.sessionCurrentClipHasVideo = true
                    completionHandler(true)
                    return
                }
            }
        }
        print("NextLevel, session failed to append video frame to clip")
        completionHandler(false)
    }
    
    public func appendAudio(withSampleBuffer sampleBuffer: CMSampleBuffer, completionHandler: @escaping NextLevelSessionAppendSampleBufferCompletionHandler) {
        self.startSessionIfNecessary(timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        if let adjustedBuffer = NextLevel.sampleBufferOffset(withSampleBuffer: sampleBuffer, timeOffset: self.timeOffset, duration: duration) {
            let presentationTimestamp = CMSampleBufferGetPresentationTimeStamp(adjustedBuffer)
            let lastTimestamp = presentationTimestamp + duration
            
            self.audioQueue.async {
                if let audioInput = self.audioInput {
                    if audioInput.isReadyForMoreMediaData && audioInput.append(adjustedBuffer) {
                        self.lastAudioTimestamp = lastTimestamp
                        
                        if !self.currentClipHasVideo {
                            self.sessionCurrentClipDuration = lastTimestamp - self.startTimestamp
                        }
                        
                        self.sessionCurrentClipHasAudio = true
                        
                        completionHandler(true)
                        return
                    }
                }
                completionHandler(false)
            }
        }
    }
    
    public func reset() {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self.endClip(completionHandler: nil)
            self.videoInput = nil
            self.audioInput = nil
            self.pixelBufferAdapter = nil
            
            self.videoConfiguration = nil
            self.audioConfiguration = nil
            
            self.sessionLastVideoFrame = nil
            self.sessionLastAudioFrame = nil
            
            self.sessionClipFilenameCount = 0
        }
    }
    
    private func startSessionIfNecessary(timestamp: CMTime) {
        if !self.startTimestamp.isValid {
            self.startTimestamp = timestamp
            if let writer = self.writer {
                writer.startSession(atSourceTime: timestamp)
            }
        }
    }
    
    // create
    
    public typealias NextLevelSessionEndClipCompletionHandler = (_: NextLevelClip?, _: Error?) -> Void
    
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
    
    public func endClip(completionHandler: NextLevelSessionEndClipCompletionHandler?) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self.audioQueue.sync {
                if self.isClipReady {
                    self.clipReady = false
                    
                    if let writer = self.writer {
                        if !self.currentClipHasAudio && !self.currentClipHasVideo {
                            writer.cancelWriting()
                            
                            self.removeFile(fileUrl: writer.outputURL)
                            self.destroyWriter()
                            
                            if let handler = completionHandler {
                                self.executeClosureAsyncOnMainQueueIfNecessary {
                                    handler(nil, nil)
                                }
                            }
                            
                        } else {
                            writer.endSession(atSourceTime: (self.sessionCurrentClipDuration + self.startTimestamp))
                            writer.finishWriting(completionHandler: {
                                // TODO support info dictionaries
                                self.appendClip(withClipURL: writer.outputURL, infoDict: nil, error: writer.error, completionHandler: completionHandler)
                            })
                            return
                        }
                    }
                }
                
                if let handler = completionHandler {
                    self.executeClosureAsyncOnMainQueueIfNecessary {
                        handler(nil, NextLevelError.notReady)
                    }
                }
            }
        }
    }
    
    private func appendClip(withClipURL url: URL, infoDict: [String : Any]?, error: Error?, completionHandler: NextLevelSessionEndClipCompletionHandler?) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            let clip = NextLevelClip(url: url, infoDict: infoDict)
            self.add(clip: clip)
            
            self.destroyWriter()
            
            self.executeClosureAsyncOnMainQueueIfNecessary {
                if let handler = completionHandler {
                    handler(clip, error)
                }
            }
        }
    }
    
    // edit
    
    public func add(clip: NextLevelClip) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self.sessionClips.append(clip)
            self.sessionDuration = self.sessionDuration + clip.duration
        }
    }
    
    public func add(clip: NextLevelClip, at idx: Int) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self.sessionClips.insert(clip, at: idx)
            self.sessionDuration = self.sessionDuration + clip.duration
        }
    }
    
    public func remove(clip: NextLevelClip) {
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
    
    public typealias NextLevelSessionMergeClipsCompletionHandler = (_: URL?, _: Error?) -> Void
    
    public func mergeClips(usingPreset preset: String, completionHandler: @escaping NextLevelSessionMergeClipsCompletionHandler) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            let fileType = self.fileType()
            let fileExtension = self.fileExtension(fileType: fileType)
            let filename = "\(self.identifier)-NL-merged.\(fileExtension)"

            let outputURL: URL? = NextLevelClip.clipURL(withFilename: filename, directory: self.sessionDirectory)
            var asset: AVAsset? = nil
            
            if self.sessionClips.count > 0 {
                asset = self.asset

                if let exportAsset = asset, let exportURL = outputURL {
                    self.removeFile(fileUrl: exportURL)
                    
                    if let exportSession = AVAssetExportSession(asset: exportAsset, presetName: preset) {
                        exportSession.shouldOptimizeForNetworkUse = true
                        exportSession.outputURL = exportURL
                        exportSession.outputFileType = fileType
                        exportSession.exportAsynchronously {
                            self.executeClosureAsyncOnMainQueueIfNecessary {
                                completionHandler(exportURL, exportSession.error)
                            }
                        }
                        return
                    }
                }
            }
            
            self.executeClosureAsyncOnMainQueueIfNecessary {
                completionHandler(nil, NextLevelError.unknown)
            }
        }
    }
}

// MARK: - compositions

extension NextLevelSession {

    internal func appendClips(toComposition composition: AVMutableComposition) {
        self.appendClips(toComposition: composition, audioMix: nil)
    }
    
    internal func appendClips(toComposition composition: AVMutableComposition, audioMix: AVMutableAudioMix?) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            var videoTrack: AVMutableCompositionTrack? = nil
            var audioTrack: AVMutableCompositionTrack? = nil
            
            var currentTime = composition.duration
            
            for clip: NextLevelClip in self.sessionClips {
                if let asset = clip.asset {
                    let videoAssetTracks = asset.tracks(withMediaType: AVMediaTypeVideo)
                    let audioAssetTracks = asset.tracks(withMediaType: AVMediaTypeAudio)
                 
                    var maxRange = kCMTimeInvalid
                    
                    var videoTime = currentTime
                    for videoAssetTrack in videoAssetTracks {
                        if videoTrack == nil {
                            let videoTracks = composition.tracks(withMediaType: AVMediaTypeVideo)
                            if videoTracks.count > 0 {
                                videoTrack = videoTracks.first
                            } else {
                                videoTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                                videoTrack?.preferredTransform = videoAssetTrack.preferredTransform
                            }
                        }
                        
                        if let foundTrack = videoTrack {
                            videoTime = self.appendTrack(track: videoAssetTrack, toCompositionTrack: foundTrack, withStartTime: videoTime, range: maxRange)
                            maxRange = videoTime
                        }
                    }
                    
                    var audioTime = currentTime
                    for audioAssetTrack in audioAssetTracks {
                        if audioTrack == nil {
                            let audioTracks = composition.tracks(withMediaType: AVMediaTypeAudio)
                            
                            if audioTracks.count > 0 {
                                audioTrack = audioTracks.first
                            } else {
                                audioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                            }
                            
                        }
                        if let foundTrack = audioTrack {
                            audioTime = self.appendTrack(track: audioAssetTrack, toCompositionTrack: foundTrack, withStartTime: audioTime, range: maxRange)
                        }
                    }
                    
                    currentTime = composition.duration
                }
            }
        }
    }
    
    private func appendTrack(track: AVAssetTrack, toCompositionTrack compositionTrack: AVMutableCompositionTrack, withStartTime time: CMTime, range: CMTime) -> CMTime {
        var timeRange = track.timeRange
        let startTime = time + timeRange.start
        
        if range.isValid {
            let currentRange = startTime + timeRange.duration
            
            if currentRange > range {
                timeRange = CMTimeRange(start: timeRange.start, duration: (timeRange.duration - (currentRange - range)))
            }
        }
        
        if timeRange.duration > kCMTimeZero {
            do {
                try compositionTrack.insertTimeRange(timeRange, of: track, at: startTime)
            } catch {
                print("NextLevel, failed to insert composition track")
            }
            return (startTime + timeRange.duration)
        }
        
        return startTime
    }
    
}

// MARK: - file management

extension NextLevelSession {
    
    internal func fileType() -> String {
        return AVFileTypeAppleM4A
    }
    
    internal func fileExtension(fileType: String) -> String {
        return "m4a"
    }
    
    internal func nextFileURL() -> URL? {
        let fileType = self.fileType()
        let fileExtension = self.fileExtension(fileType: fileType)
        let filename = "\(self.identifier)-NL-clip.\(self.sessionClipFilenameCount).\(fileExtension)"
        if let url = NextLevelClip.clipURL(withFilename: filename, directory: self.sessionDirectory) {
            self.removeFile(fileUrl: url)
            self.sessionClipFilenameCount += 1
            return url
        } else {
            return nil
        }
    }
    
    internal func removeFile(fileUrl: URL) {
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            do {
                try FileManager.default.removeItem(atPath: fileUrl.path)
            } catch {
                print("NextLevel, could not remove file at path")
            }
        }
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
    
    internal func executeClosureSyncOnSessionQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: self.sessionQueueKey) == self.sessionQueue {
            closure()
        } else {
            self.sessionQueue.sync(execute: closure)
        }
    }
    
}
