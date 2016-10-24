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
    
    public var outputDirectory: String
    
    // see AVMediaFormat.h for file type and extension
    
    public var fileType: String
    
    public var fileExtension: String
    
    // state

    public var identifier: String {
        get {
            return self._identifier
        }
    }
    
    public var date: Date {
        get {
            return self._date
        }
    }
    
    public var url: URL? {
        get {
            let filename = "\(self.identifier)-NL-merged.\(self.fileExtension)"
            if let url = NextLevelClip.clipURL(withFilename: filename, directory: self.outputDirectory) {
                return url
            } else {
                return nil
            }
        }
    }

    public var isVideoReady: Bool {
        get {
            return self._videoInput != nil
        }
    }
    
    public var isAudioReady: Bool {
        get {
            return self._audioInput != nil
        }
    }

    public var clips: [NextLevelClip] {
        get {
            return self._clips
        }
    }
    
    public var duration: CMTime {
        get {
            return self._duration
        }
    }

    public var isClipReady: Bool {
        get {
            return self._writer != nil
        }
    }
    
    public var clipStarted: Bool {
        get {
            return self._clipStarted
        }
    }

    public var currentClipDuration: CMTime {
        get {
            return self._currentClipDuration
        }
    }

    public var currentClipHasVideo: Bool {
        get {
            return self._currentClipHasVideo
        }
    }

    public var currentClipHasAudio: Bool {
        get {
            return self._currentClipHasAudio
        }
    }
    
    public var asset: AVAsset? {
        get {
            var asset: AVAsset? = nil
            self.executeClosureSyncOnSessionQueueIfNecessary {
                if self._clips.count == 1 {
                    asset = self._clips.first?.asset
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
            return self._pixelBufferAdapter?.pixelBufferPool
        }
    }
    
    // MARK: - private instance vars
    
    internal var _identifier: String
    internal var _date: Date
    
    internal var _duration: CMTime
    internal var _clips: [NextLevelClip]
    internal var _clipFilenameCount: Int

    internal var _writer: AVAssetWriter?
    internal var _videoInput: AVAssetWriterInput?
    internal var _audioInput: AVAssetWriterInput?
    internal var _pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?

    internal var _videoConfiguration: NextLevelVideoConfiguration?
    internal var _audioConfiguration: NextLevelAudioConfiguration?
    
    internal var _audioQueue: DispatchQueue
    internal var _sessionQueue: DispatchQueue
    internal var _sessionQueueKey: DispatchSpecificKey<NSObject>
    
    internal var _currentClipDuration: CMTime
    internal var _currentClipHasAudio: Bool
    internal var _currentClipHasVideo: Bool

    internal var _clipStarted: Bool
    internal var _timeOffset: CMTime
    internal var _startTimestamp: CMTime
    internal var _lastAudioTimestamp: CMTime
    internal var _lastVideoTimestamp: CMTime
    
    private let NextLevelSessionAudioQueueIdentifier = "engineering.NextLevel.session.audioQueue"
    private let NextLevelSessionQueueIdentifier = "engineering.NextLevel.sessionQueue"
    private let NextLevelSessionSpecificKey = DispatchSpecificKey<NSObject>()
    
    // MARK: - object lifecycle
    
    convenience init(queue: DispatchQueue, queueKey: DispatchSpecificKey<NSObject>) {
        self.init()
        self._sessionQueue = queue
        self._sessionQueueKey = queueKey
    }
    
    override init() {
        self._identifier = NSUUID().uuidString
        self._date = Date()
        self.outputDirectory = NSTemporaryDirectory()
        self.fileType = AVFileTypeMPEG4
        self.fileExtension = "mp4"
        
        self._clips = []
        self._clipFilenameCount = 0
        self._duration = kCMTimeZero
     
        self._audioQueue = DispatchQueue(label: NextLevelSessionAudioQueueIdentifier)

        // should always use init(queue:queueKey:), but this may be good for the future
        self._sessionQueue = DispatchQueue(label: NextLevelSessionQueueIdentifier)
        self._sessionQueue.setSpecific(key: NextLevelSessionSpecificKey, value: self._sessionQueue)
        self._sessionQueueKey = NextLevelSessionSpecificKey

        self._currentClipDuration = kCMTimeZero
        self._currentClipHasAudio = false
        self._currentClipHasVideo = false
        
        self._clipStarted = false
        self._timeOffset = kCMTimeInvalid
        self._startTimestamp = kCMTimeInvalid
        self._lastAudioTimestamp = kCMTimeInvalid
        self._lastVideoTimestamp = kCMTimeInvalid
        
        super.init()
    }
    
    deinit {
        self._writer = nil
        self._videoInput = nil
        self._audioInput = nil
        self._pixelBufferAdapter = nil
        
        self._videoConfiguration = nil
        self._audioConfiguration = nil    
    }
    
    // MARK: - functions
    
    // setup
    
    public func setupVideo(withSettings settings: [String : Any]?, configuration: NextLevelVideoConfiguration, formatDescription: CMFormatDescription) -> Bool {
        self._videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: settings, sourceFormatHint: formatDescription)
        if let videoInput = self._videoInput {
            videoInput.expectsMediaDataInRealTime = true
            videoInput.transform = configuration.transform
            self._videoConfiguration = configuration
            
            let videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            
            let pixelBufferAttri: [String : Any] = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
                                                    String(kCVPixelBufferWidthKey): Float(videoDimensions.width),
                                                    String(kCVPixelBufferHeightKey): Float(videoDimensions.height)]
            self._pixelBufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: pixelBufferAttri)
        }
        return self._videoInput != nil
    }
    
    public func setupAudio(withSettings settings: [String : Any]?, configuration: NextLevelAudioConfiguration, formatDescription: CMFormatDescription) -> Bool {
        self._audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: settings, sourceFormatHint: formatDescription)
        if let audioInput = self._audioInput {
            audioInput.expectsMediaDataInRealTime = true
            self._audioConfiguration = configuration
        }
        return self._audioInput != nil
    }
    
    internal func setupWriter() {
        if let url = self.nextFileURL() {
            do {
                self._writer = try AVAssetWriter(url: url, fileType: self.fileType)
                if let writer = self._writer {
                    writer.shouldOptimizeForNetworkUse = true
                    writer.metadata = NextLevel.assetWriterMetadata()
                    
                    if let videoInput = self._videoInput {
                        if writer.canAdd(videoInput) {
                            writer.add(videoInput)
                        } else {
                            print("NextLevel, could not add video input to session")
                        }
                    }
                    
                    if let audioInput = self._audioInput {
                        if writer.canAdd(audioInput) {
                            writer.add(audioInput)
                        } else {
                            print("NextLevel, could not add audio input to session")
                        }
                    }
                    
                    if writer.startWriting() {
                        self._clipStarted = true
                        self._timeOffset = kCMTimeZero
                        self._startTimestamp = kCMTimeInvalid
                    } else {
                        print("NextLevel, writer encountered an error \(writer.error)")
                        self._writer = nil
                    }
                }
            } catch {
                print("NextLevel could not create asset writer")
            }
        }
    }
    
    internal func destroyWriter() {
        self._writer = nil
        self._clipStarted = false
        self._timeOffset = kCMTimeZero
        self._startTimestamp = kCMTimeInvalid
        self._currentClipDuration = kCMTimeZero
        self._currentClipHasVideo = false
        self._currentClipHasAudio = false
    }
}

// MARK: - recording/editing

extension NextLevelSession {
    
    // recording
    
    public typealias NextLevelSessionAppendSampleBufferCompletionHandler = (_: Bool) -> Void
    
    public func appendVideo(withSampleBuffer sampleBuffer: CMSampleBuffer, imageBuffer: CVPixelBuffer?, minFrameDuration: CMTime, completionHandler: NextLevelSessionAppendSampleBufferCompletionHandler) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        self.startSessionIfNecessary(timestamp: timestamp)
        
        var frameDuration = minFrameDuration
        let offsetBufferTimestamp = timestamp - self._timeOffset
        
        if let videoConfig = self._videoConfiguration, let timeScale = videoConfig.timeScale {
            if timeScale != 1.0 {
                let scaledDuration = CMTimeMultiplyByFloat64(duration, timeScale)
                if self._currentClipDuration.value > 0 {
                    self._timeOffset = self._timeOffset + (duration - scaledDuration)
                }
                frameDuration = scaledDuration
            }
        }
        
        if let videoInput = self._videoInput, let pixelBufferAdapter = self._pixelBufferAdapter {
            if videoInput.isReadyForMoreMediaData {
                
                var bufferToProcess: CVPixelBuffer? = nil
                if let pixelImageBuffer = imageBuffer {
                    bufferToProcess = pixelImageBuffer
                } else {
                    bufferToProcess = CMSampleBufferGetImageBuffer(sampleBuffer)
                }
                
                if let outputBuffer = bufferToProcess {
                    if pixelBufferAdapter.append(outputBuffer, withPresentationTime: offsetBufferTimestamp) {
                        self._currentClipDuration = (offsetBufferTimestamp + frameDuration) - self._startTimestamp
                        self._lastVideoTimestamp = timestamp
                        self._currentClipHasVideo = true
                        completionHandler(true)
                        return
                    }
                }
                
            }
        }

        print("NextLevel, session failed to append video frame to clip")
        completionHandler(false)
    }
    
    public func appendAudio(withSampleBuffer sampleBuffer: CMSampleBuffer, completionHandler: @escaping NextLevelSessionAppendSampleBufferCompletionHandler) {
        self.startSessionIfNecessary(timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        if let adjustedBuffer = NextLevel.sampleBufferOffset(withSampleBuffer: sampleBuffer, timeOffset: self._timeOffset, duration: duration) {
            let presentationTimestamp = CMSampleBufferGetPresentationTimeStamp(adjustedBuffer)
            let lastTimestamp = presentationTimestamp + duration
            
            self._audioQueue.async {
                if let audioInput = self._audioInput {
                    if audioInput.isReadyForMoreMediaData && audioInput.append(adjustedBuffer) {
                        self._lastAudioTimestamp = lastTimestamp
                        
                        if !self.currentClipHasVideo {
                            self._currentClipDuration = lastTimestamp - self._startTimestamp
                        }
                        
                        self._currentClipHasAudio = true
                        
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
            self._videoInput = nil
            self._audioInput = nil
            self._pixelBufferAdapter = nil
            
            self._videoConfiguration = nil
            self._audioConfiguration = nil
            
            self._clipFilenameCount = 0
        }
    }
    
    private func startSessionIfNecessary(timestamp: CMTime) {
        if !self._startTimestamp.isValid {
            self._startTimestamp = timestamp
            if let writer = self._writer {
                writer.startSession(atSourceTime: timestamp)
            }
        }
    }
    
    // create
    
    public typealias NextLevelSessionEndClipCompletionHandler = (_: NextLevelClip?, _: Error?) -> Void
    
    public func beginClip() {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            if self._writer == nil {
                self.setupWriter()
                self._currentClipDuration = kCMTimeZero
                self._currentClipHasAudio = false
                self._currentClipHasVideo = false
            } else {
                print("NextLevel, clip has already been created.")
            }
        }
    }
    
    public func endClip(completionHandler: NextLevelSessionEndClipCompletionHandler?) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self._audioQueue.sync {
                if self.clipStarted {
                    self._clipStarted = false
                    
                    if let writer = self._writer {
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
                            writer.endSession(atSourceTime: (self._currentClipDuration + self._startTimestamp))
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
                        handler(nil, NextLevelError.notReadyToRecord)
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
            self._clips.append(clip)
            self._duration = self._duration + clip.duration
        }
    }
    
    public func add(clip: NextLevelClip, at idx: Int) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self._clips.insert(clip, at: idx)
            self._duration = self._duration + clip.duration
        }
    }
    
    public func remove(clip: NextLevelClip) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            if let idx = self._clips.index(of: clip) {
                self._clips.remove(at: idx)
                self._duration = self._duration - clip.duration
            }
        }
    }
    
    public func remove(clipAt idx: Int, removeFile: Bool) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            if self._clips.indices.contains(idx) {
                let clip = self._clips.remove(at: idx)
                if removeFile {
                    clip.removeFile()
                }
                self._duration = self._duration - clip.duration
            }
        }
    }
    
    public func removeAllClips() {
        self.removeAllClips(removeFiles: true)
    }
    
    public func removeAllClips(removeFiles: Bool) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            while self._clips.count > 0 {
                if removeFiles {
                    if let clipToRemove = self._clips.first {
                        clipToRemove.removeFile()
                    }
                    self._clips.removeFirst()
                }
            }
            self._duration = kCMTimeZero
        }
    }

    public func removeLastClip() {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            if self.clips.count > 0 {
                if let clipToRemove = self.clips.last {
                    self.remove(clip: clipToRemove)
                    self._duration = self._duration - clipToRemove.duration
                }
            }
        }
    }
    
    public typealias NextLevelSessionMergeClipsCompletionHandler = (_: URL?, _: Error?) -> Void
    
    public func mergeClips(usingPreset preset: String, completionHandler: @escaping NextLevelSessionMergeClipsCompletionHandler) {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            let filename = "\(self.identifier)-NL-merged.\(self.fileExtension)"

            let outputURL: URL? = NextLevelClip.clipURL(withFilename: filename, directory: self.outputDirectory)
            var asset: AVAsset? = nil
            
            if self._clips.count > 0 {
                asset = self.asset

                if let exportAsset = asset, let exportURL = outputURL {
                    self.removeFile(fileUrl: exportURL)
                    
                    if let exportSession = AVAssetExportSession(asset: exportAsset, presetName: preset) {
                        exportSession.shouldOptimizeForNetworkUse = true
                        exportSession.outputURL = exportURL
                        exportSession.outputFileType = self.fileType
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
            
            for clip: NextLevelClip in self._clips {
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
    
    internal func nextFileURL() -> URL? {
        let filename = "\(self.identifier)-NL-clip.\(self._clipFilenameCount).\(self.fileExtension)"
        if let url = NextLevelClip.clipURL(withFilename: filename, directory: self.outputDirectory) {
            self.removeFile(fileUrl: url)
            self._clipFilenameCount += 1
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
        if DispatchQueue.getSpecific(key: self._sessionQueueKey) == self._sessionQueue {
            closure()
        } else {
            self._sessionQueue.sync(execute: closure)
        }
    }
    
}
