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
    
    public var clipsDuration: CMTime {
        get {
            // TODO
            return kCMTimeInvalid
        }
    }

    public var currentClipDuration: CMTime {
        get {
            return self.sessionCurrentClipDuration
        }
    }
    
    public var isActive: Bool {
        get {
            return self.active
        }
    }
    
    public var isClipReady: Bool {
        get {
            return self.ready
        }
    }
    
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
    
    private var active: Bool
    private var ready: Bool
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    
    private var timeOffset: CMTime
    private var lastAudioTimestamp: CMTime
    
    private var lastVideoTimestamp: CMTime
    
    private var sessionCurrentClipDuration: CMTime
    private var sessionCurrentClipStartTimestamp: CMTime
    
    private var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    
    // MARK: - class functions
    
    class func session() -> NextLevelSession {
        return NextLevelSession()
    }
    
    class func session(with dictRepresentation: [String: Any]) -> NextLevelSession {
        let session = NextLevelSession()
        return session
    }
    
    // MARK: - object lifecycle
    
    override init() {
        self.sessionIdentifier = NSUUID().uuidString
        self.sessionClips = []
        self.sessionDate = Date()
        self.sessionDuration = kCMTimeZero
        self.active = false
        self.ready = false
        
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
    
    // recording
    
    public func beginClip() {
        
    }
    
    public func endClip(withInfoDict infoDict: [String:Any], completionHandler: (_: NextLevelSessionClip, _: Error)-> Void) {
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
    
    public func cancelSession(withCompletionHandler completionHandler: ()-> Void) {
    }
    
    // finalize
    
    public func mergeClips(usingPreset preset: String, completionHandler: (_: URL, _: Error)-> Void) {
        
    }
    
    // MARK: - private
    
    private func setupWriter() {
    }

}
