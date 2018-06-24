//
//  NextLevel.swift
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
import CoreImage
import CoreVideo
import ImageIO
import Metal
#if USE_ARKIT
import ARKit
#endif

// MARK: - types

public enum NextLevelAuthorizationStatus: Int, CustomStringConvertible {
    case notDetermined = 0
    case notAuthorized
    case authorized
    
    public var description: String {
        get {
            switch self {
            case .notDetermined:
                return "Not Determined"
            case .notAuthorized:
                return "Not Authorized"
            case .authorized:
                return "Authorized"
            }
        }
    }
}

public enum NextLevelDeviceType: Int, CustomStringConvertible {
    case microphone = 0
    case wideAngleCamera
    case telephotoCamera
    case duoCamera
    case trueDepthCamera
    
    public var avfoundationType: AVCaptureDevice.DeviceType {
        switch self {
        case .microphone:
            return AVCaptureDevice.DeviceType.builtInMicrophone
        case .telephotoCamera:
            return AVCaptureDevice.DeviceType.builtInTelephotoCamera
        case .wideAngleCamera:
            return AVCaptureDevice.DeviceType.builtInWideAngleCamera
        case .duoCamera:
            if #available(iOS 11.0, *) {
                return AVCaptureDevice.DeviceType.builtInDualCamera
            } else {
                return AVCaptureDevice.DeviceType.builtInDuoCamera
            }
        case .trueDepthCamera:
            if #available(iOS 11.1, *) {
                return AVCaptureDevice.DeviceType.builtInTrueDepthCamera
            } else {
                return AVCaptureDevice.DeviceType(rawValue: "Unavailable")
            }
        }
    }
    
    public var description: String {
        get {
            switch self {
            case .microphone:
                return "Microphone"
            case .wideAngleCamera:
                return "Wide Angle Camera"
            case .telephotoCamera:
                return "Telephoto Camera"
            case .duoCamera:
                return "Duo Camera"
            case .trueDepthCamera:
                return "True Depth Camera"
            }
        }
    }
}

public enum NextLevelCaptureMode: Int, CustomStringConvertible {
    case video = 0
    case photo
    case audio
    case videoWithoutAudio
    case arKit
    
    public var description: String {
        get {
            switch self {
            case .video:
                return "Video"
            case .videoWithoutAudio:
                return "Video without audio"
            case .photo:
                return "Photo"
            case .audio:
                return "Audio"
            case .arKit:
                return "ARKit"
            }
        }
    }
}

public typealias NextLevelDeviceOrientation = AVCaptureVideoOrientation
public typealias NextLevelDevicePosition = AVCaptureDevice.Position

public typealias NextLevelFocusMode = AVCaptureDevice.FocusMode
public typealias NextLevelExposureMode = AVCaptureDevice.ExposureMode
public typealias NextLevelFlashMode = AVCaptureDevice.FlashMode
public typealias NextLevelTorchMode = AVCaptureDevice.TorchMode

public typealias NextLevelVideoStabilizationMode = AVCaptureVideoStabilizationMode

public enum NextLevelMirroringMode: Int, CustomStringConvertible {
    case off = 0
    case on
    case auto
    
    public var description: String {
        get {
            switch self {
            case .off:
                return "Off"
            case .on:
                return "On"
            case .auto:
                return "Auto"
            }
        }
    }
}

// MARK: - error types

/// Error domain for all Next Level errors.
public let NextLevelErrorDomain = "NextLevelErrorDomain"

/// Error types.
public enum NextLevelError: Error, CustomStringConvertible {
    case unknown
    case started
    case deviceNotAvailable
    case authorization
    case fileExists
    case nothingRecorded
    case notReadyToRecord
    
    public var description: String {
        get {
            switch self {
            case .unknown:
                return "Unknown"
            case .started:
                return "NextLevel already started"
            case .fileExists:
                return "File exists"
            case .authorization:
                return "Authorization has not been requested"
            case .deviceNotAvailable:
                return "Device Not Available"
            case .nothingRecorded:
                return "Nothing recorded"
            case .notReadyToRecord:
                return "NextLevel is not ready to record"
            }
        }
    }
}

// MARK: - NextLevelDelegate Dictionary Keys

/// Delegate callback dictionary key for photo metadata
public let NextLevelPhotoMetadataKey = "NextLevelPhotoMetadataKey"

/// Delegate callback dictionary key for JPEG data
public let NextLevelPhotoJPEGKey = "NextLevelPhotoJPEGKey"

/// Delegate callback dictionary key for cropped JPEG data
public let NextLevelPhotoCroppedJPEGKey = "NextLevelPhotoCroppedJPEGKey"

/// Delegate callback dictionary key for raw image data
public let NextLevelPhotoRawImageKey = "NextLevelPhotoRawImageKey"

/// Delegate callback dictionary key for a photo thumbnail
public let NextLevelPhotoThumbnailKey = "NextLevelPhotoThumbnailKey"

// MARK: - NextLevelDelegate

/// NextLevel delegate, provides updates for authorization, configuration changes, session state, preview state, and mode changes.
public protocol NextLevelDelegate: NSObjectProtocol {
    
    // permission
    func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: AVMediaType)
    
    // configuration
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration)
    
    // session
    func nextLevelSessionWillStart(_ nextLevel: NextLevel)
    func nextLevelSessionDidStart(_ nextLevel: NextLevel)
    func nextLevelSessionDidStop(_ nextLevel: NextLevel)
    
    // session interruption
    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel)
    func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel)
    
    // mode
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel)
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel)
}

/// Preview delegate, provides update for
public protocol NextLevelPreviewDelegate: NSObjectProtocol {

    // preview
    func nextLevelWillStartPreview(_ nextLevel: NextLevel)
    func nextLevelDidStopPreview(_ nextLevel: NextLevel)

}

/// Device delegate, provides updates on device position, orientation, clean aperture, focus, exposure, and white balances changes.
public protocol NextLevelDeviceDelegate: NSObjectProtocol {
    
    // position, orientation
    func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel)
    func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel)
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation)
    
    // format
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceFormat deviceFormat: AVCaptureDevice.Format)
    
    // aperture
    func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect)
    
    // focus, exposure, white balance
    func nextLevelWillStartFocus(_ nextLevel: NextLevel)
    func nextLevelDidStopFocus(_  nextLevel: NextLevel)
    
    func nextLevelWillChangeExposure(_ nextLevel: NextLevel)
    func nextLevelDidChangeExposure(_ nextLevel: NextLevel)
    
    func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel)
    func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel)
    
}

// MARK: - NextLevelFlashAndTorchDelegate

/// Flash and torch delegate, provides updates on active flash and torch related changes.
public protocol NextLevelFlashAndTorchDelegate: NSObjectProtocol {
    
    func nextLevelDidChangeFlashMode(_ nextLevel: NextLevel)
    func nextLevelDidChangeTorchMode(_ nextLevel: NextLevel)
    
    func nextLevelFlashActiveChanged(_ nextLevel: NextLevel)
    func nextLevelTorchActiveChanged(_ nextLevel: NextLevel)
    
    func nextLevelFlashAndTorchAvailabilityChanged(_ nextLevel: NextLevel)
    
}

// MARK: - NextLevelVideoDelegate

/// Video delegate, provides updates on video related recording and capture functionality.
/// All methods are called on the main queue with the exception of nextLevel:renderToCustomContextWithSampleBuffer:onQueue.
public protocol NextLevelVideoDelegate: NSObjectProtocol {
    
    // video zoom
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float)
    
    // video processing
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue)
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue)

    // ARKit video processing
    @available(iOS 11.0, *)
    func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, onQueue queue: DispatchQueue)

    // video recording session
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession)
    
    // clip start/stop
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession)
    
    // clip file I/O
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)

    func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession)
    
    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)

    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession)
    
    // video frame photo
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?)
    
}

// MARK: - NextLevelPhotoDelegate

/// Photo delegate, provides updates on photo related capture functionality.
public protocol NextLevelPhotoDelegate: NSObjectProtocol {
    
    func nextLevel(_ nextLevel: NextLevel, willCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, didCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration)
    
    func nextLevel(_ nextLevel: NextLevel, didProcessPhotoCaptureWith photoDict: [String: Any]?, photoConfiguration: NextLevelPhotoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, didProcessRawPhotoCaptureWith photoDict: [String: Any]?, photoConfiguration: NextLevelPhotoConfiguration)
    
    func nextLevelDidCompletePhotoCapture(_ nextLevel: NextLevel)
    
}

// MARK: - NextLevelDepthDataDelegate

/// Depth data delegate, provides depth data updates
public protocol NextLevelDepthDataDelegate: NSObjectProtocol {

    @available(iOS 11.0, *)
    func depthDataOutput(_ nextLevel: NextLevel, didOutput depthData: AVDepthData, timestamp: CMTime)

    @available(iOS 11.0, *)
    func depthDataOutput(_ nextLevel: NextLevel, didDrop depthData: AVDepthData, timestamp: CMTime, reason: AVCaptureOutput.DataDroppedReason)

}

// MARK: - constants

private let NextLevelCaptureSessionQueueIdentifier = "engineering.NextLevel.CaptureSession"
private let NextLevelCaptureSessionQueueSpecificKey = DispatchSpecificKey<()>()
private let NextLevelDepthDataQueueIdentifier = "engineering.NextLevel.DepthData"
private let NextLevelRequiredMinimumStorageSpaceInBytes: UInt64 = 49999872 // ~47 MB

// MARK: - NextLevel state

/// ⬆️ NextLevel, Rad Media Capture in Swift (http://nextlevel.engineering)
public class NextLevel: NSObject {
    
    // delegates
    
    public weak var delegate: NextLevelDelegate?
    public weak var previewDelegate: NextLevelPreviewDelegate?
    public weak var deviceDelegate: NextLevelDeviceDelegate?
    public weak var flashDelegate: NextLevelFlashAndTorchDelegate?
    public weak var videoDelegate: NextLevelVideoDelegate?
    public weak var photoDelegate: NextLevelPhotoDelegate?
    public weak var depthDataDelegate: NextLevelDepthDataDelegate?
    
    // preview
    
    /// Live camera preview, add as a sublayer to the UIView's primary layer.
    public var previewLayer: AVCaptureVideoPreviewLayer
    
    // capture configuration
    
    /// Configuration for video
    public var videoConfiguration: NextLevelVideoConfiguration
    
    /// Configuration for audio
    public var audioConfiguration: NextLevelAudioConfiguration
    
    /// Configuration for photos
    public var photoConfiguration: NextLevelPhotoConfiguration
    
    @available(iOS 11.0, *)
    /// Configuration property for augmented reality
    public var arConfiguration: NextLevelARConfiguration? {
        get {
            return self._arConfiguration as? NextLevelARConfiguration
        }
    }
    
    // audio configuration
    
    /// Indicates whether the capture session automatically changes settings in the app’s shared audio session. By default, is `true`.
    public var automaticallyConfiguresApplicationAudioSession: Bool = true
    
    // camera configuration
    
    /// Checks if a camera device is available for a position.
    ///
    /// - Parameter devicePosition: Camera device position to query.
    /// - Returns: `true` if the camera device exists, otherwise false.
    public func isCameraDeviceAvailable(withDevicePosition devicePosition: NextLevelDevicePosition) -> Bool {
        return UIImagePickerController .isCameraDeviceAvailable(devicePosition.uikitType)
    }
    
    /// The current capture mode of the device.
    public var captureMode: NextLevelCaptureMode = .video {
        didSet {
            guard
                self.captureMode != oldValue
                else {
                    return
            }
            
            self.delegate?.nextLevelCaptureModeWillChange(self)
            
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                self.configureSession()
                self.configureSessionDevices()
                self.updateVideoOrientation()

#if USE_ARKIT
                if self.captureMode == .arKit {
                    self.setupContextIfNecessary()
                }
#endif
                self.delegate?.nextLevelCaptureModeDidChange(self)
            }
        }
    }
    
    /// The current device position.
    public var devicePosition: NextLevelDevicePosition = .back {
        didSet {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                self.configureSessionDevices()
                self.updateVideoOrientation()
            }
        }
    }
    
    /// When `true` actives device orientation updates
    public var automaticallyUpdatesDeviceOrientation: Bool = false
    
    /// The current orientation of the device.
    public var deviceOrientation: NextLevelDeviceOrientation = .portrait {
        didSet {
            self.automaticallyUpdatesDeviceOrientation = false
            self.updateVideoOrientation()
        }
    }
    
    // stabilization
    
    /// When `true`, enables photo capture stabilization.
    public var photoStabilizationEnabled: Bool = false
    
    /// Video stabilization mode
    public var videoStabilizationMode: NextLevelVideoStabilizationMode = .auto {
        didSet {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                self.beginConfiguration()
                self.updateVideoOutputSettings()
                self.commitConfiguration()
            }
        }
    }
    
    // depth data
    
    /// When `true`, enables streaming depth data capture (use PhotoConfiguration for photos)
    public var depthDataCaptureEnabled: Bool = false
    
    // state
    
    /// Checks if the system is recording.
    public var isRecording: Bool {
        get {
            return self._recording
        }
    }
    
    /// Checks if the current capture session is running
    public var isRunning: Bool {
        get {
            if #available(iOS 11.0, *) {
                if self.captureMode == .arKit {
                    return self._arRunning
                }
            }
            if let session = self._captureSession {
                return session.isRunning
            }
            return false
        }
    }
    
    /// The current recording session, a powerful means for modifying and editing previously recorded clips.
    /// The session provides features such as 'undo'.
    public var session: NextLevelSession? {
        get {
            return self._recordingSession
        }
    }
    
    // MARK: - private instance vars
    
    internal var _sessionQueue: DispatchQueue
    internal var _sessionConfigurationCount: Int = 0
    
    internal var _recording: Bool = false
    internal var _recordingSession: NextLevelSession?
    internal var _lastVideoFrameTimeInterval: TimeInterval = 0
    
    internal var _videoCustomContextRenderingEnabled: Bool = false
    internal var _sessionVideoCustomContextImageBuffer: CVPixelBuffer?
    internal var _ciContext: CIContext?
    
    internal var _pixelBufferPool: CVPixelBufferPool?
    internal var _bufferWidth: Int = 0
    internal var _bufferHeight: Int = 0
    internal var _bufferFormatType: OSType = OSType(kCVPixelFormatType_32BGRA)
    
    // AVFoundation
    
    internal var _captureSession: AVCaptureSession?
    
    internal var _videoInput: AVCaptureDeviceInput?
    internal var _audioInput: AVCaptureDeviceInput?
    
    internal var _videoOutput: AVCaptureVideoDataOutput?
    internal var _audioOutput: AVCaptureAudioDataOutput?
    internal var _photoOutput: AVCapturePhotoOutput?
    
    internal var _depthDataOutput: Any?
    @available(iOS 11.0, *)
    internal var depthDataOutput: AVCaptureDepthDataOutput? {
        get {
            return self._depthDataOutput as? AVCaptureDepthDataOutput
        }
        set {
            self._depthDataOutput = newValue
        }
    }
    
    internal var _currentDevice: AVCaptureDevice?
    internal var _requestedDevice: AVCaptureDevice?
    
    internal var _lastVideoFrame: CMSampleBuffer?
    internal var _lastAudioFrame: CMSampleBuffer?
    
    // ARKit
    
    internal var _arRunning: Bool = false
    internal var _arConfiguration: NextLevelConfiguration?
    
    internal var _lastARFrame: CVPixelBuffer?
    
    // MARK: - singleton
    
    /// Method for providing a NextLevel singleton. This isn't required for use.
    public static let shared = NextLevel()
    
    // MARK: - object lifecycle
    
    public override init() {
        self.previewLayer = AVCaptureVideoPreviewLayer()
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self._sessionQueue = DispatchQueue(label: NextLevelCaptureSessionQueueIdentifier, qos: .userInteractive, target: DispatchQueue.global())
        self._sessionQueue.setSpecific(key: NextLevelCaptureSessionQueueSpecificKey, value: ())
        
        self.videoConfiguration = NextLevelVideoConfiguration()
        self.audioConfiguration = NextLevelAudioConfiguration()
        self.photoConfiguration = NextLevelPhotoConfiguration()
        if #available(iOS 11.0, *) {
            self._arConfiguration = NextLevelARConfiguration()
        }
        
        super.init()
        
        self.addApplicationObservers()
        self.addSessionObservers()
        self.addDeviceObservers()
    }
    
    deinit {
        self.delegate = nil
        self.previewDelegate = nil
        self.deviceDelegate = nil
        self.flashDelegate = nil
        self.videoDelegate = nil
        self.photoDelegate = nil
        self.depthDataDelegate = nil
        
        self.removeApplicationObservers()
        self.removeSessionObservers()
        self.removeDeviceObservers()
        
        if let session = self._captureSession {
            self.beginConfiguration()
            self.removeInputs(session: session)
            self.removeOutputs(session: session)
            self.commitConfiguration()
        }
        
        self.previewLayer.session = nil
        
        self._currentDevice = nil
        self._ciContext = nil
        
        self._recordingSession = nil
        self._captureSession = nil
    }
}

// MARK: - authorization

extension NextLevel {
    
    /// Checks the current authorization status for the desired media type.
    ///
    /// - Parameter mediaType: Specified media type (i.e. AVMediaTypeVideo, AVMediaTypeAudio, etc.)
    /// - Returns: Authorization status for the desired media type.
    public func authorizationStatus(forMediaType mediaType: AVMediaType) -> NextLevelAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)
        var nextLevelStatus: NextLevelAuthorizationStatus = .notDetermined
        switch status {
        case .denied, .restricted:
            nextLevelStatus = .notAuthorized
            break
        case .authorized:
            nextLevelStatus = .authorized
            break
        case .notDetermined:
            break
        }
        return nextLevelStatus
    }
    
    /// Requests authorization permission.
    ///
    /// - Parameter mediaType: Specified media type (i.e. AVMediaTypeVideo, AVMediaTypeAudio, etc.)
    public func requestAuthorization(forMediaType mediaType: AVMediaType) {
        AVCaptureDevice.requestAccess(for: mediaType) { (granted: Bool) in
            let status: NextLevelAuthorizationStatus = (granted == true) ? .authorized : .notAuthorized
            DispatchQueue.main.async {
                self.delegate?.nextLevel(self, didUpdateAuthorizationStatus: status, forMediaType: mediaType)
            }
        }
    }
    
    internal func authorizationStatusForCurrentCameraMode() -> NextLevelAuthorizationStatus {
        switch self.captureMode {
        case .audio:
            return self.authorizationStatus(forMediaType: AVMediaType.audio)
        case .videoWithoutAudio:
            return self.authorizationStatus(forMediaType: AVMediaType.video)
        case .arKit:
            fallthrough
        case .video:
            let audioStatus = self.authorizationStatus(forMediaType: AVMediaType.audio)
            let videoStatus = self.authorizationStatus(forMediaType: AVMediaType.video)
            return (audioStatus == .authorized && videoStatus == .authorized) ? .authorized : .notAuthorized
        case .photo:
            return self.authorizationStatus(forMediaType: AVMediaType.video)
        }
    }
}

// MARK: - session start/stop

extension NextLevel {
    
    /// Starts the current recording session.
    ///
    /// - Throws: 'NextLevelError.authorization' when permissions are not authorized, 'NextLevelError.started' when the session has already started.
    public func start() throws {
        guard self._captureSession == nil
        else {
            throw NextLevelError.started
        }
        
        guard self.authorizationStatusForCurrentCameraMode() == .authorized
        else {
            throw NextLevelError.authorization
        }
        
        if self.captureMode == .arKit {
            if #available(iOS 11.0, *) {
                setupARSession()
            }
        } else {
            setupAVSession()
        }
    }
    
    /// Stops the current recording session.
    public func stop() {
        if let session = self._captureSession {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                if session.isRunning == true {
                    session.stopRunning()
                }
                
                self.beginConfiguration()
                self.removeInputs(session: session)
                self.removeOutputs(session: session)
                self.commitConfiguration()
                
                self._recordingSession = nil
                self._captureSession = nil
                self._currentDevice = nil
            }
        }
        
#if USE_ARKIT
        if self.captureMode == .arKit {
            if #available(iOS 11.0, *) {
                self.executeClosureAsyncOnSessionQueueIfNecessary {
                    if self._arRunning == true {
                        self.arConfiguration?.session?.pause()
                        self._arRunning = false
                        
                        self._recordingSession = nil
                    }
                }
            }
        }
#endif
    }
    
    internal func setupAVSession() {
        // Note: use nextLevelSessionDidStart to ensure a device and session are available for configuration or format changes
        self.executeClosureAsyncOnSessionQueueIfNecessary {
            // setup AV capture sesssion
            self._captureSession = AVCaptureSession()
            self._sessionConfigurationCount = 0
            
            // setup NL recording session
            self._recordingSession = NextLevelSession(queue: self._sessionQueue, queueKey: NextLevelCaptureSessionQueueSpecificKey)
            
            if let session = self._captureSession {
                session.automaticallyConfiguresApplicationAudioSession = self.automaticallyConfiguresApplicationAudioSession
                
                self.beginConfiguration()
                self.previewLayer.session = session
                
                self.configureSession()
                self.configureSessionDevices()
                self.updateVideoOrientation()
                
                self.commitConfiguration()
                
                if session.isRunning == false {
                    self.delegate?.nextLevelSessionWillStart(self)
                    session.startRunning()
                    self.previewDelegate?.nextLevelWillStartPreview(self)
                    
                    // nextLevelSessionDidStart is called from AVFoundation
                }
            }
        }
    }
    
    @available(iOS 11.0, *)
    internal func setupARSession() {
#if USE_ARKIT
        self.executeClosureAsyncOnSessionQueueIfNecessary {
            if let config = self.arConfiguration?.config,
                let options = self.arConfiguration?.runOptions {
                self._captureSession = AVCaptureSession() // AV session is needed for device management and configuration
                self._sessionConfigurationCount = 0

                // setup NL recording session
                self._recordingSession = NextLevelSession(queue: self._sessionQueue, queueKey: NextLevelCaptureSessionQueueSpecificKey)
                self.arConfiguration?.session?.delegateQueue = self._sessionQueue
                
                if let session = self._captureSession {
                    session.automaticallyConfiguresApplicationAudioSession = self.automaticallyConfiguresApplicationAudioSession
                    
                    self.beginConfiguration()
                    self.configureSession()
                    self.configureSessionDevices()
                    self.updateVideoOrientation()
                    self.commitConfiguration()
                }
                
                if self._arRunning == false {
                    self.delegate?.nextLevelSessionWillStart(self)
                    self.arConfiguration?.session?.run(config, options: options)
                    self._arRunning = true
                    
                    DispatchQueue.main.async {
                        self.delegate?.nextLevelSessionDidStart(self)
                    }
                }
            }
        }
#endif
    }
    
}

// MARK: - NextLevel private session configuration support

extension NextLevel {
    
    // re-entrant configuration lock, thanks to SCRecorder
    internal func beginConfiguration() {
        if let session = self._captureSession {
            self._sessionConfigurationCount += 1
            if self._sessionConfigurationCount == 1 {
                session.beginConfiguration()
            }
        }
    }
    
    internal func commitConfiguration() {
        if let session = self._captureSession {
            self._sessionConfigurationCount -= 1
            if self._sessionConfigurationCount == 0 {
                session.commitConfiguration()
            }
        }
    }
    
    internal func configureSessionDevices() {
        guard self._captureSession != nil else {
            return
        }
        
        self.beginConfiguration()
        
        var shouldConfigureVideo = false
        var shouldConfigureAudio = false
        switch self.captureMode {
        case .photo:
            shouldConfigureVideo = true
            break
        case .audio:
            shouldConfigureAudio = true
            break
        case .video:
            shouldConfigureVideo = true
            shouldConfigureAudio = true
            break
        case .videoWithoutAudio:
            shouldConfigureVideo = true
            break
        case .arKit:
            shouldConfigureVideo = true
            break
        }
        
        if shouldConfigureVideo == true {
            var captureDevice: AVCaptureDevice? = nil
            
            if let requestedDevice = self._requestedDevice {
                captureDevice = requestedDevice
            } else if let videoDevice = AVCaptureDevice.primaryVideoDevice(forPosition: self.devicePosition) {
                captureDevice = videoDevice
            }
            
            if let captureDevice = captureDevice {
                if captureDevice != self._currentDevice {
                    self.configureDevice(captureDevice: captureDevice, mediaType: AVMediaType.video)
                    
                    let changingPosition = (captureDevice.position != self._currentDevice?.position)
                    if changingPosition {
                        DispatchQueue.main.async {
                            self.deviceDelegate?.nextLevelDevicePositionWillChange(self)
                        }
                    }
                    
                    self.willChangeValue(forKey: "currentDevice")
                    self._currentDevice = captureDevice
                    self.didChangeValue(forKey: "currentDevice")
                    self._requestedDevice = nil
                    
                    if changingPosition {
                        DispatchQueue.main.async {
                            self.deviceDelegate?.nextLevelDevicePositionDidChange(self)
                        }
                    }
                }
            }
        }
        
        if shouldConfigureAudio {
            if let audioDevice = AVCaptureDevice.audioDevice() {
                self.configureDevice(captureDevice: audioDevice, mediaType: AVMediaType.audio)
            }
        }
        
        self.commitConfiguration()
        
        if shouldConfigureVideo {
            DispatchQueue.main.async {
                self.delegate?.nextLevel(self, didUpdateVideoConfiguration: self.videoConfiguration)
            }
        }
        
        if shouldConfigureAudio {
            DispatchQueue.main.async {
                self.delegate?.nextLevel(self, didUpdateAudioConfiguration: self.audioConfiguration)
            }
        }
    }
    
    internal func configureSession() {
        if let session = self._captureSession {
            self.beginConfiguration()
            
            // setup preset and mode
            
            self.removeUnusedOutputsForCurrentCameraMode(session: session)
            
            switch self.captureMode {
            case .video:
                fallthrough
            case .videoWithoutAudio:
                if session.sessionPreset != self.videoConfiguration.preset {
                    if session.canSetSessionPreset(self.videoConfiguration.preset) {
                        session.sessionPreset = self.videoConfiguration.preset
                    } else {
                        print("NextLevel, could not set preset on session")
                    }
                }
                
                if self.captureMode == .video {
                    let _ = self.addAudioOuput()
                }
                let _ = self.addVideoOutput()
                if self.depthDataCaptureEnabled {
                    let _ = self.addDepthDataOutput()
                }
                break
            case .photo:
                if session.sessionPreset != self.photoConfiguration.preset {
                    if session.canSetSessionPreset(self.photoConfiguration.preset) {
                        session.sessionPreset = self.photoConfiguration.preset
                    } else {
                        print("NextLevel, could not set preset on session")
                    }
                }
                
                let _ = self.addPhotoOutput()
                if self.depthDataCaptureEnabled {
                    let _ = self.addDepthDataOutput()
                }
                break
            case .audio:
                let _ = self.addAudioOuput()
                break
            case .arKit:
                // no AV inputs to setup
                break
            }
            
            self.commitConfiguration()
        }
    }
    
    // inputs
    
    private func configureDevice(captureDevice: AVCaptureDevice, mediaType: AVMediaType) {
        
        if let session = self._captureSession,
            let currentDeviceInput = AVCaptureDeviceInput.deviceInput(withMediaType: mediaType, captureSession: session) {
            if currentDeviceInput.device == captureDevice {
                return
            }
        }
        
        if mediaType == AVMediaType.video {
            do {
                try captureDevice.lockForConfiguration()
                
                if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                    captureDevice.focusMode = .continuousAutoFocus
                    if captureDevice.isSmoothAutoFocusSupported {
                        captureDevice.isSmoothAutoFocusEnabled = true
                    }
                }
                
                if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                    captureDevice.exposureMode = .continuousAutoExposure
                }
                
                if captureDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    captureDevice.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                
                captureDevice.isSubjectAreaChangeMonitoringEnabled = true
                
                if captureDevice.isLowLightBoostSupported {
                    captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                captureDevice.unlockForConfiguration()
            }
            catch {
                print("NextLevel, low light failed to lock device for configuration")
            }
        }
        
        if let session = self._captureSession {
            if let currentDeviceInput = AVCaptureDeviceInput.deviceInput(withMediaType: mediaType, captureSession: session) {
                session.removeInput(currentDeviceInput)
                if currentDeviceInput.device.hasMediaType(AVMediaType.video) {
                    self.removeKeyValueObservers(currentDeviceInput.device)
                }
            }
            
            let _ = self.addInput(session: session, device: captureDevice)
        }
    }
    
    private func addInput(session: AVCaptureSession, device: AVCaptureDevice) -> Bool {
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                
                if input.device.hasMediaType(AVMediaType.video) {
                    self.addKeyValueObservers(input.device)
                    self.updateVideoOutputSettings()
                    self._videoInput = input
                } else {
                    self._audioInput = input
                }
                
                return true
            }
        } catch  {
            print("NextLevel, failure adding input device")
        }
        return false
    }
    
    internal func removeInputs(session: AVCaptureSession) {
        if let inputs = session.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                session.removeInput(input)
                if input.device.hasMediaType(AVMediaType.video) {
                    self.removeKeyValueObservers(input.device)
                }
            }
            self._videoInput = nil
            self._audioInput = nil
        }
    }
    
    // outputs, only call within configuration lock
    
    private func addVideoOutput() -> Bool {
        
        if self._videoOutput == nil {
            self._videoOutput = AVCaptureVideoDataOutput()
            self._videoOutput?.alwaysDiscardsLateVideoFrames = false
            
            var videoSettings = [String(kCVPixelBufferPixelFormatTypeKey):Int(kCVPixelFormatType_32BGRA)]
            if let formatTypes = self._videoOutput?.availableVideoPixelFormatTypes {
                var supportsFullRange = false
                var supportsVideoRange = false
                for format in formatTypes {
                    if format == Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
                        supportsFullRange = true
                    }
                    if format == Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
                        supportsVideoRange = true
                    }
                }
                if supportsFullRange {
                    videoSettings[String(kCVPixelBufferPixelFormatTypeKey)] = Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                } else if supportsVideoRange {
                    videoSettings[String(kCVPixelBufferPixelFormatTypeKey)] = Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                }
            }
            self._videoOutput?.videoSettings = videoSettings
        }
        
        if let session = self._captureSession, let videoOutput = self._videoOutput {
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                videoOutput.setSampleBufferDelegate(self, queue: self._sessionQueue)
                return true
            }
        }
        print("NextLevel, couldn't add video output to session")
        return false
        
    }
    
    private func addAudioOuput() -> Bool {
        
        if self._audioOutput == nil {
            self._audioOutput = AVCaptureAudioDataOutput()
        }
        
        if let session = self._captureSession, let audioOutput = self._audioOutput {
            if session.canAddOutput(audioOutput) {
                session.addOutput(audioOutput)
                audioOutput.setSampleBufferDelegate(self, queue: self._sessionQueue)
                return true
            }
        }
        print("NextLevel, couldn't add audio output to session")
        return false
        
    }
    
    private func addPhotoOutput() -> Bool {
        
        if self._photoOutput == nil {
            self._photoOutput = AVCapturePhotoOutput()
        }
        
        if let session = self._captureSession, let photoOutput = self._photoOutput {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                return true
            }
        }
        print("NextLevel, couldn't add photo output to session")
        return false
        
    }
    
    private func addDepthDataOutput() -> Bool {
        guard depthDataCaptureEnabled else {
            return false
        }
        
        if #available(iOS 11.0, *) {
            // setup depth streaming
            if self.depthDataOutput == nil {
                self.depthDataOutput = AVCaptureDepthDataOutput()
                if let depthDataOutput = self.depthDataOutput {
                    let depthDataQueue = DispatchQueue(label: NextLevelDepthDataQueueIdentifier)
                    depthDataOutput.setDelegate(self, callbackQueue: depthDataQueue)
                }
                
                if let session = self._captureSession, let depthDataOutput = self.depthDataOutput {
                    if session.canAddOutput(depthDataOutput) {
                        session.addOutput(depthDataOutput)
                        return true
                    }
                }
            }
        }
        print("NextLevel, couldn't add depth data output to session")
        return false
    }
    
    internal func removeOutputs(session: AVCaptureSession) {
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        self._videoOutput = nil
        self._audioInput = nil
        self._photoOutput = nil
        self._depthDataOutput = nil
    }
    
    internal func removeUnusedOutputsForCurrentCameraMode(session: AVCaptureSession) {
        switch self.captureMode {
        case .video:
            if let photoOutput = self._photoOutput, session.outputs.contains(photoOutput) {
                session.removeOutput(photoOutput)
                self._photoOutput = nil
            }
            break
        case .videoWithoutAudio:
            if let photoOutput = self._photoOutput, session.outputs.contains(photoOutput) {
                session.removeOutput(photoOutput)
                self._photoOutput = nil
            }
            if let audioOutput = self._audioOutput, session.outputs.contains(audioOutput) {
                session.removeOutput(audioOutput)
                self._audioOutput = nil
            }
            break
        case .photo:
            if let videoOutput = self._videoOutput, session.outputs.contains(videoOutput) {
                session.removeOutput(videoOutput)
                self._videoOutput = nil
            }
            if let audioOutput = self._audioOutput, session.outputs.contains(audioOutput) {
                session.removeOutput(audioOutput)
                self._audioOutput = nil
            }
            break
        case .audio:
            if let videoOutput = self._videoOutput, session.outputs.contains(videoOutput) {
                session.removeOutput(videoOutput)
                self._videoOutput = nil
            }
            if let photoOutput = self._photoOutput, session.outputs.contains(photoOutput) {
                session.removeOutput(photoOutput)
                self._photoOutput = nil
            }
            break
        case .arKit:
            if let videoOutput = self._videoOutput, session.outputs.contains(videoOutput) {
                session.removeOutput(videoOutput)
                self._videoOutput = nil
            }
            if let audioOutput = self._audioOutput, session.outputs.contains(audioOutput) {
                session.removeOutput(audioOutput)
                self._audioOutput = nil
            }
            if let photoOutput = self._photoOutput, session.outputs.contains(photoOutput) {
                session.removeOutput(photoOutput)
                self._photoOutput = nil
            }
            break
        }
        
    }
    
}

// MARK: - capture mode and device settings (flash, torch, focus, exposure, white balance, and frame rate)

extension NextLevel {
    
    // preview
    
    /// Freezes the live camera preview layer.
    public func freezePreview() {
        if let previewConnection = self.previewLayer.connection {
            previewConnection.isEnabled = false
        }
    }
    
    /// Un-freezes the live camera preview layer.
    public func unfreezePreview() {
        if let previewConnection = self.previewLayer.connection {
            previewConnection.isEnabled = true
        }
    }
    
    // flash and torch
    
    /// Checks if a flash is available.
    public var isFlashAvailable: Bool {
        if let device: AVCaptureDevice = self._currentDevice {
            return device.hasFlash && device.isFlashAvailable
        }
        return false
    }
    
    /// The flash mode of the device.
    public var flashMode: NextLevelFlashMode {
        get {
            return self.photoConfiguration.flashMode.flashModeNextLevelType()
        }
        set {
            if let device: AVCaptureDevice = self._currentDevice {
                guard device.hasFlash
                    else {
                        return
                }
                
                if let output = self._photoOutput {
                    if self.photoConfiguration.flashMode != newValue {
                        // iOS 11 GM fix
                        // https://forums.developer.apple.com/thread/86810
                        let modes = output.__supportedFlashModes
                        if modes.contains(NSNumber(value: newValue.rawValue)) {
                            self.photoConfiguration.flashMode = newValue
                        }
                    }
                }
            }
        }
    }
    
    /// Checks if a torch is available.
    public var isTorchAvailable: Bool {
        get {
            if let device = self._currentDevice {
                return device.hasTorch
            }
            return false
        }
    }
    
    /// Torch mode of the device.
    public var torchMode: NextLevelTorchMode {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.torchMode
            }
            return .off
        }
        set {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                if let device = self._currentDevice {
                    guard
                        device.torchMode != newValue,
                        device.hasTorch
                        else {
                            return
                    }
                    
                    do {
                        try device.lockForConfiguration()
                        if device.isTorchModeSupported(newValue) {
                            device.torchMode = newValue
                        }
                        device.unlockForConfiguration()
                    } catch {
                        print("NextLevel, torchMode failed to lock device for configuration")
                    }
                }
            }
        }
    }
    
    // focus, exposure, and white balance
    // note: focus and exposure modes change when adjusting on point
    
    /// Checks if focusing at a point of interest is supported.
    public var isFocusPointOfInterestSupported: Bool {
        get {
            if let device = self._currentDevice {
                return device.isFocusPointOfInterestSupported
            }
            return false
        }
    }
    
    /// Checks if focus lock is supported.
    public var isFocusLockSupported: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isFocusModeSupported(.locked)
            }
            return false
        }
    }
    
    /// Checks if focus adjustment is in progress.
    public var isAdjustingFocus: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isAdjustingFocus
            }
            return false
        }
    }
    
    /// The focus mode of the device.
    public var focusMode: NextLevelFocusMode {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.focusMode
            }
            return .locked
        }
        set {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                if let device: AVCaptureDevice = self._currentDevice {
                    guard
                        device.focusMode != newValue,
                        device.isFocusModeSupported(newValue)
                        else {
                            return
                    }
                    
                    do {
                        try device.lockForConfiguration()
                        device.focusMode = newValue
                        device.unlockForConfiguration()
                    } catch {
                        print("NextLevel, focusMode failed to lock device for configuration")
                    }
                }
            }
        }
    }
    
    /// Focuses, exposures, and adjusts white balanace at the point of interest.
    ///
    /// - Parameter adjustedPoint: The point of interest.
    public func focusExposeAndAdjustWhiteBalance(atAdjustedPoint adjustedPoint: CGPoint) {
        if let device: AVCaptureDevice = self._currentDevice {
            guard
                !device.isAdjustingFocus,
                !device.isAdjustingExposure
                else {
                    return
            }
            do {
                try device.lockForConfiguration()
                
                let focusMode: AVCaptureDevice.FocusMode = .autoFocus
                let exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure
                let whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode = .continuousAutoWhiteBalance
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = adjustedPoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = adjustedPoint
                    device.exposureMode = exposureMode
                }
                
                if device.isWhiteBalanceModeSupported(whiteBalanceMode) {
                    device.whiteBalanceMode = whiteBalanceMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = false
                
                device.unlockForConfiguration()
            }
            catch {
                print("NextLevel, focusExposeAndAdjustWhiteBalance failed to lock device for configuration")
            }
        }
    }
    
    /// Changes focus at adjusted point of interest.
    ///
    /// - Parameter adjustedPoint: The point of interest for focus
    public func focusAtAdjustedPointOfInterest(adjustedPoint: CGPoint) {
        if let device: AVCaptureDevice = self._currentDevice {
            guard !device.isAdjustingFocus,
                  !device.isAdjustingExposure
            else {
                return
            }
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    let focusMode = device.focusMode
                    device.focusPointOfInterest = adjustedPoint
                    device.focusMode = focusMode
                }
                
                device.unlockForConfiguration()
            }
            catch {
                print("NextLevel, focusAtAdjustedPointOfInterest failed to lock device for configuration")
            }
        }
    }
    
    // exposure
    
    /// Checks if exposure lock is supported.
    public var isExposureLockSupported: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isExposureModeSupported(.locked)
            }
            return false
        }
    }
    
    /// Checks if an exposure adjustment is progress.
    public var isAdjustingExposure: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isAdjustingExposure
            }
            return false
        }
    }
    
    /// The exposure mode of the device.
    public var exposureMode: NextLevelExposureMode {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.exposureMode
            }
            return .locked
        }
        set {
            if let device: AVCaptureDevice = self._currentDevice {
                guard
                    device.exposureMode != newValue,
                    device.isExposureModeSupported(newValue)
                    else {
                        return
                }
                
                do {
                    try device.lockForConfiguration()
                    
                    device.exposureMode = newValue
                    self.adjustWhiteBalanceForExposureMode(exposureMode: newValue)
                    
                    device.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, exposureMode failed to lock device for configuration")
                }
            }
        }
    }
    
    /// Changes exposure at adjusted point of interest.
    ///
    /// - Parameter adjustedPoint: The point of interest for exposure.
    public func exposeAtAdjustedPointOfInterest(adjustedPoint: CGPoint) {
        if let device: AVCaptureDevice = self._currentDevice {
            guard
                !device.isAdjustingExposure
                else {
                    return
            }
            
            do {
                try device.lockForConfiguration()
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
                    let exposureMode = device.exposureMode
                    device.exposurePointOfInterest = adjustedPoint
                    device.exposureMode = exposureMode
                }
                
                device.unlockForConfiguration()
            }
            catch {
                print("NextLevel, exposeAtAdjustedPointOfInterest failed to lock device for configuration")
            }
        }
    }
    
    /// Calculates focal length and principle point camera intrinsic parameters for OpenCV.
    /// (see Hartley's Mutiple View Geometry, Chapter 6)
    ///
    /// - Parameters:
    ///   - focalLengthX: focal length along the x-axis
    ///   - focalLengthY: focal length along the y-axis
    ///   - principlePointX: principle point x-coordinate
    ///   - principlePointY: principle point y-coordinate
    /// - Returns: `true` when the focal length and principle point parameters are successfully calculated.
    public func focalLengthAndPrinciplePoint(focalLengthX: inout Float, focalLengthY: inout Float, principlePointX: inout Float, principlePointY: inout Float) -> Bool {
        if let device: AVCaptureDevice = self._currentDevice {
            let dimensions = CMVideoFormatDescriptionGetPresentationDimensions(device.activeFormat.formatDescription, true, true)
        
            principlePointX = Float(dimensions.width) * 0.5
            principlePointY = Float(dimensions.height) * 0.5
            
            let horizontalFieldOfView = device.activeFormat.videoFieldOfView
            let verticalFieldOfView = (horizontalFieldOfView / principlePointX) * principlePointY
            
            focalLengthX = fabs( Float(dimensions.width) / (2.0 * tan(horizontalFieldOfView / 180.0 * .pi / 2 )) )
            focalLengthY = fabs( Float(dimensions.height) / (2.0 * tan(verticalFieldOfView / 180.0 * .pi / 2 )) )
            return true
        }
        return false
    }
    
    // private functions
    
    internal func adjustFocusExposureAndWhiteBalance() {
        if let device: AVCaptureDevice = self._currentDevice {
            guard !device.isAdjustingFocus, !device.isAdjustingExposure
            else {
                return
            }
            if self.focusMode != .locked {
                self.deviceDelegate?.nextLevelWillStartFocus(self)
                self.focusAtAdjustedPointOfInterest(adjustedPoint: CGPoint(x: 0.5, y: 0.5))
            }
        }
    }
    
    internal func adjustWhiteBalanceForExposureMode(exposureMode: AVCaptureDevice.ExposureMode) {
        if let device = self._currentDevice {
            let whiteBalanceMode = self.whiteBalanceModeBestForExposureMode(exposureMode: exposureMode)
            if device.isWhiteBalanceModeSupported(whiteBalanceMode) {
                device.whiteBalanceMode = whiteBalanceMode
            }
        }
    }
    
    internal func whiteBalanceModeBestForExposureMode(exposureMode: AVCaptureDevice.ExposureMode) -> AVCaptureDevice.WhiteBalanceMode {
        var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode = .continuousAutoWhiteBalance
        if let device = self._currentDevice {
            switch exposureMode {
            case .autoExpose:
                if device.isWhiteBalanceModeSupported(.autoWhiteBalance) {
                    whiteBalanceMode = .autoWhiteBalance
                }
                break
            case .locked:
                if device.isWhiteBalanceModeSupported(.locked) {
                    let flashActive: Bool = (self.photoConfiguration.flashMode == .on) || (self.photoConfiguration.flashMode == .auto)
                    whiteBalanceMode = flashActive == true ? .continuousAutoWhiteBalance : .locked
                }
                break
            default:
                break
            }
        }
        return whiteBalanceMode
    }
    
    internal func focusStarted() {
        DispatchQueue.main.async {
            self.deviceDelegate?.nextLevelWillStartFocus(self)
        }
    }
    
    internal func focusEnded() {
        if let device = self._currentDevice {
            guard !device.isAdjustingFocus
            else {
                return
            }
            
            let isAutoFocusEnabled: Bool = (device.focusMode == .autoFocus ||
                device.focusMode == .continuousAutoFocus)
            if isAutoFocusEnabled {
                do {
                    try device.lockForConfiguration()
                    
                    device.isSubjectAreaChangeMonitoringEnabled = true
                    
                    device.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, focus ending failed to lock device for configuration")
                }
            }
            
            DispatchQueue.main.async {
                self.deviceDelegate?.nextLevelDidStopFocus(self)
            }
            
        }
    }
    
    internal func exposureStarted() {
        DispatchQueue.main.async {
            self.deviceDelegate?.nextLevelWillChangeExposure(self)
        }
    }
    
    internal func exposureEnded() {
        if let device = self._currentDevice {
            guard
                !device.isAdjustingFocus ||
                    !device.isAdjustingExposure
                else {
                    return
            }
            
            let isContinuousAutoExposureEnabled: Bool = (device.exposureMode == .continuousAutoExposure)
            if isContinuousAutoExposureEnabled {
                do {
                    try device.lockForConfiguration()
                    
                    device.isSubjectAreaChangeMonitoringEnabled = true
                    
                    device.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, focus ending failed to lock device for configuration")
                }
            }
            
            DispatchQueue.main.async {
                self.deviceDelegate?.nextLevelDidChangeExposure(self)
            }
        }
    }
    
    internal func whiteBalanceStarted() {
        DispatchQueue.main.async {
            self.deviceDelegate?.nextLevelWillChangeWhiteBalance(self)
        }
    }
    
    internal func whiteBalanceEnded() {
        DispatchQueue.main.async {
            self.deviceDelegate?.nextLevelDidChangeWhiteBalance(self)
        }
    }
    
    internal func flashActiveChanged() {
        // adjust white balance mode depending on the flash
        if let device = self._currentDevice {
            let exposureMode = device.exposureMode
            let whiteBalanceMode = self.whiteBalanceModeBestForExposureMode(exposureMode: exposureMode)
            let currentWhiteBalanceMode = device.whiteBalanceMode
            
            if whiteBalanceMode != currentWhiteBalanceMode {
                do {
                    try device.lockForConfiguration()
                    
                    self.adjustWhiteBalanceForExposureMode(exposureMode: exposureMode)
                    
                    device.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, failed to lock device for white balance configuration")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.flashDelegate?.nextLevelFlashActiveChanged(self)
        }
    }
    
    internal func torchActiveChanged() {
        DispatchQueue.main.async {
            self.flashDelegate?.nextLevelTorchActiveChanged(self)
        }
    }
    
    internal func flashAndTorchAvailabilityChanged() {
        DispatchQueue.main.async {
            self.flashDelegate?.nextLevelFlashAndTorchAvailabilityChanged(self)
        }
    }
    
    // mirroring
    
    /// Changes the current capture device's mirroring mode.
    public var mirroringMode: NextLevelMirroringMode {
        get {
            if let pc = self.previewLayer.connection {
                if pc.isVideoMirroringSupported {
                    if !pc.automaticallyAdjustsVideoMirroring {
                        return pc.isVideoMirrored ? .on : .off
                    } else {
                        return .auto
                    }
                }
            }
            return .off
        }
        set {
            if let _ = self._captureSession,
                let videoOutput = self._videoOutput {
                
                switch newValue {
                case .off:
                    if let vc = videoOutput.connection(with: AVMediaType.video) {
                        if vc.isVideoMirroringSupported {
                            vc.isVideoMirrored = false
                        }
                    }
                    if let pc = self.previewLayer.connection {
                        if pc.isVideoMirroringSupported {
                            pc.automaticallyAdjustsVideoMirroring = false
                            pc.isVideoMirrored = false
                        }
                    }
                    break
                case .on:
                    if let vc = videoOutput.connection(with: AVMediaType.video) {
                        if vc.isVideoMirroringSupported {
                            vc.isVideoMirrored = true
                        }
                    }
                    if let pc = self.previewLayer.connection {
                        if pc.isVideoMirroringSupported {
                            pc.automaticallyAdjustsVideoMirroring = false
                            pc.isVideoMirrored = true
                        }
                    }
                    break
                case .auto:
                    if let vc = videoOutput.connection(with: AVMediaType.video), let device = self._currentDevice {
                        if vc.isVideoMirroringSupported {
                            vc.isVideoMirrored = (device.position == .front)
                        }
                    }
                    if let pc = self.previewLayer.connection {
                        if pc.isVideoMirroringSupported {
                            pc.automaticallyAdjustsVideoMirroring = true
                        }
                    }
                    break
                }
            }
        }
    }
    
    // frame rate
    
    /// Changes the current device frame rate.
    public var frameRate: CMTimeScale {
        get {
            var frameRate: CMTimeScale = 0
            if let session = self._captureSession,
                let inputs = session.inputs as? [AVCaptureDeviceInput] {
                for input in inputs {
                    if input.device.hasMediaType(AVMediaType.video) {
                        frameRate = input.device.activeVideoMaxFrameDuration.timescale
                        break
                    }
                }
            }
            return frameRate
        }
        set {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                if let device: AVCaptureDevice = self._currentDevice {
                    guard device.activeFormat.isSupported(withFrameRate: newValue)
                        else {
                            print("unsupported frame rate for current device format config, \(newValue) fps")
                            return
                    }
                    
                    let fps: CMTime = CMTimeMake(1, newValue)
                    do {
                        try device.lockForConfiguration()
                        
                        device.activeVideoMaxFrameDuration = fps
                        device.activeVideoMinFrameDuration = fps
                        
                        device.unlockForConfiguration()
                    } catch {
                        print("NextLevel, frame rate failed to lock device for configuration")
                    }
                }
            }
        }
    }
    
    // device format
    
    /// Changes the current device frame rate within the desired dimensions.
    ///
    /// - Parameters:
    ///   - frameRate: Desired frame rate.
    ///   - dimensions: Desired video dimensions.
    public func updateDeviceFormat(withFrameRate frameRate: CMTimeScale, dimensions: CMVideoDimensions) {
        self.executeClosureAsyncOnSessionQueueIfNecessary {
            if let device: AVCaptureDevice = self._currentDevice {
                
                var updatedFormat: AVCaptureDevice.Format? = nil
                for currentFormat in device.formats {
                    if currentFormat.isSupported(withFrameRate: frameRate, dimensions: dimensions) {
                        if updatedFormat == nil {
                            updatedFormat = currentFormat
                        } else if let updated = updatedFormat {
                            let currentDimensions = CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription)
                            let updatedDimensions = CMVideoFormatDescriptionGetDimensions(updated.formatDescription)
                            
                            if currentDimensions.width < updatedDimensions.width && currentDimensions.height < updatedDimensions.height {
                                updatedFormat = currentFormat
                            } else if currentDimensions.width == updatedDimensions.width && currentDimensions.height == updatedDimensions.height {
                                
                                let currentFrameRate = AVCaptureDevice.Format.maxFrameRate(forFormat: currentFormat, minFrameRate: frameRate)
                                let updatedFrameRate = AVCaptureDevice.Format.maxFrameRate(forFormat: updated, minFrameRate: frameRate)
                                
                                if updatedFrameRate > currentFrameRate {
                                    updatedFormat = currentFormat
                                }
                            }
                            
                        }
                    }
                }
                
                if let format = updatedFormat {
                    do {
                        try device.lockForConfiguration()
                        device.activeFormat = format
                        if device.activeFormat.isSupported(withFrameRate: frameRate) {
                            let fps: CMTime = CMTimeMake(1, frameRate)
                            device.activeVideoMaxFrameDuration = fps
                            device.activeVideoMinFrameDuration = fps
                        }
                        device.unlockForConfiguration()
                        
                        DispatchQueue.main.async {
                            self.deviceDelegate?.nextLevel(self, didChangeDeviceFormat: format)
                        }
                    } catch {
                        print("NextLevel, active device format failed to lock device for configuration")
                    }
                } else {
                    print("Nextlevel, could not find a current device format matching the requirements")
                }
                
            }
        }
    }
}

// MARK: - capture device switching

extension NextLevel {
    
    /// Triggers a camera device position change.
    public func flipCaptureDevicePosition() {
        if self.devicePosition == .back {
            self.devicePosition = .front
        } else {
            self.devicePosition = .back
        }
    }
    
    /// Changes capture device if the desired device is available.
    public func changeCaptureDeviceIfAvailable(captureDevice: NextLevelDeviceType) throws {
        let deviceForUse = AVCaptureDevice.captureDevice(withType: captureDevice.avfoundationType, forPosition: .back)
        if deviceForUse == nil {
            throw NextLevelError.deviceNotAvailable
        } else {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                self._requestedDevice = deviceForUse
                self.configureSessionDevices()
                self.updateVideoOrientation()
            }
        }
    }
    
    internal func updateVideoOrientation() {
        if let session = self._recordingSession {
            if session.currentClipHasAudio == false && session.currentClipHasVideo == false {
                session.reset()
            }
        }
        
        var didChangeOrientation = false
        let currentOrientation = AVCaptureVideoOrientation.avorientationFromUIDeviceOrientation(UIDevice.current.orientation)
        
        if let previewConnection = self.previewLayer.connection {
            if previewConnection.isVideoOrientationSupported && previewConnection.videoOrientation != currentOrientation {
                previewConnection.videoOrientation = currentOrientation
                didChangeOrientation = true
            }
        }
        
        if let videoOutput = self._videoOutput, let videoConnection = videoOutput.connection(with: AVMediaType.video) {
            if videoConnection.isVideoOrientationSupported && videoConnection.videoOrientation != currentOrientation {
                videoConnection.videoOrientation = currentOrientation
                didChangeOrientation = true
            }
        }
        
        if let photoOutput = self._photoOutput, let photoConnection = photoOutput.connection(with: AVMediaType.video) {
            if photoConnection.isVideoOrientationSupported && photoConnection.videoOrientation != currentOrientation {
                photoConnection.videoOrientation = currentOrientation
                didChangeOrientation = true
            }
        }
        
        if didChangeOrientation == true {
            self.deviceDelegate?.nextLevel(self, didChangeDeviceOrientation: currentOrientation.deviceOrientationNextLevelType())
        }
    }
    
    internal func updateVideoOutputSettings() {
        if let videoOutput = self._videoOutput {
            if let videoConnection = videoOutput.connection(with: AVMediaType.video) {
                if videoConnection.isVideoStabilizationSupported {
                    videoConnection.preferredVideoStabilizationMode = self.videoStabilizationMode
                }
            }
        }
    }
}

// MARK: - video capture

extension NextLevel {
    
    /// Checks if video capture is supported by the hardware.
    public var supportsVideoCapture: Bool {
        get {
            var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInTelephotoCamera]
            if #available(iOS 11.0, *) {
                deviceTypes.append(.builtInDualCamera)
            } else {
                deviceTypes.append(.builtInDuoCamera)
            }
            
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: .unspecified)
            return discoverySession.devices.count > 0
        }
    }
    
    /// Checks if video capture is available, based on available storage and supported hardware functionality.
    public var canCaptureVideo: Bool {
        get {
            return self.supportsVideoCapture && (FileManager.availableStorageSpaceInBytes() > NextLevelRequiredMinimumStorageSpaceInBytes)
        }
    }
    
    // zoom
    
    /// Updates video capture zoom factor.
    public var videoZoomFactor: Float {
        get {
            if let device = self._currentDevice {
                return Float(device.videoZoomFactor)
            }
            return 1.0 // prefer 1.0 instead of using an optional
        }
        set {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                if let device = self._currentDevice {
                    do {
                        try device.lockForConfiguration()
                        
                        let zoom: Float = max(1, min(newValue, Float(device.activeFormat.videoMaxZoomFactor)))
                        device.videoZoomFactor = CGFloat(zoom)
                        
                        device.unlockForConfiguration()
                    } catch {
                        print("NextLevel, zoomFactor failed to lock device for configuration")
                    }
                }
            }
        }
    }
    
    internal func videoZoomFactorChanged() {
        DispatchQueue.main.async {
            self.videoDelegate?.nextLevel(self, didUpdateVideoZoomFactor: self.videoZoomFactor)
        }
    }
    
    /// Triggers a photo capture from the last video frame.
    public func capturePhotoFromVideo() {
        
        self.executeClosureAsyncOnSessionQueueIfNecessary {
            guard self._recordingSession != nil
            else {
                return
            }
            
            var buffer: CVPixelBuffer? = nil
            if let videoFrame = self._lastVideoFrame,
                let imageBuffer = CMSampleBufferGetImageBuffer(videoFrame) {
                buffer = imageBuffer
            } else if let arFrame = self._lastARFrame {
                buffer = arFrame
            }

            if self.isVideoCustomContextRenderingEnabled {
                if let buffer = buffer {
                    if CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess {
                        // only called from captureQueue, populates self._sessionVideoCustomContextImageBuffer
                        self.videoDelegate?.nextLevel(self, renderToCustomContextWithImageBuffer: buffer, onQueue: self._sessionQueue)
                        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
                    }
                }
            }
            
            // create a render context
            
            self.setupContextIfNecessary()
            
            var photoDict: [String: Any]? = nil
            let ratio = self.videoConfiguration.aspectRatio.ratio
            if let customFrame = self._sessionVideoCustomContextImageBuffer {
                
                // TODO append exif metadata
                
                // add JPEG, thumbnail
                
                if let context = self._ciContext,
                    let photo = context.uiimage(withPixelBuffer: customFrame) {
                    let croppedPhoto = ratio != nil ? photo.nx_croppedImage(to: ratio!) : photo
                    if let imageData = UIImageJPEGRepresentation(photo, 1),
                        let croppedImageData = UIImageJPEGRepresentation(croppedPhoto, 1){
                        if photoDict == nil {
                            photoDict = [:]
                        }
                        photoDict?[NextLevelPhotoJPEGKey] = imageData
                        photoDict?[NextLevelPhotoCroppedJPEGKey] = croppedImageData
                    }
                }
            } else if let videoFrame = self._lastVideoFrame {
                
                // append exif metadata
                videoFrame.append(metadataAdditions: NextLevel.tiffMetadata())
                if let metadata = videoFrame.metadata() {
                    if photoDict == nil {
                        photoDict = [:]
                    }
                    photoDict?[NextLevelPhotoMetadataKey] = metadata
                }
                
                // add JPEG, thumbnail
                if let context = self._ciContext,
                    let photo = context.uiimage(withSampleBuffer: videoFrame) {
                    let croppedPhoto = ratio != nil ? photo.nx_croppedImage(to: ratio!) : photo
                    if let imageData = UIImageJPEGRepresentation(photo, 1),
                    let croppedImageData = UIImageJPEGRepresentation(croppedPhoto, 1){
                        if photoDict == nil {
                            photoDict = [:]
                        }
                        photoDict?[NextLevelPhotoJPEGKey] = imageData
                        photoDict?[NextLevelPhotoCroppedJPEGKey] = croppedImageData
                    }
                }
                
            } else if let arFrame = self._lastARFrame {
                
                // TODO append exif metadata
                
                // add JPEG, thumbnail
                if let context = self._ciContext,
                    let photo = context.uiimage(withPixelBuffer: arFrame),
                    let imageData = UIImageJPEGRepresentation(photo, 1) {
                    
                    if photoDict == nil {
                        photoDict = [:]
                    }
                    photoDict?[NextLevelPhotoJPEGKey] = imageData
                }
            }
            
            // TODO, if photoDict?[NextLevelPhotoJPEGKey]
            // add explicit thumbnail
            //let thumbnailData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: previewBuffer, previewPhotoSampleBuffer: nil)
            //if let tData = thumbnailData {
            //    photoDict[NextLevelPhotoThumbnailKey] = tData
            //}
            DispatchQueue.main.sync {
                self.videoDelegate?.nextLevel(self, didCompletePhotoCaptureFromVideoFrame: photoDict)
            }
            
        }
        
    }
    
    // custom video rendering
    
    /// Enables delegate callbacks for rendering into a custom context.
    /// videoDelegate, func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue)
    public var isVideoCustomContextRenderingEnabled: Bool {
        get {
            return self._videoCustomContextRenderingEnabled
        }
        set {
            self.executeClosureSyncOnSessionQueueIfNecessary {
                self._videoCustomContextRenderingEnabled = newValue
                self._sessionVideoCustomContextImageBuffer = nil
            }
        }
    }
    
    /// Settings this property passes a modified buffer into the session for writing.
    /// The property is only observed when 'isVideoCustomContextRenderingEnabled' is enabled. Setting it to nil avoids modification for a frame.
    public var videoCustomContextImageBuffer: CVPixelBuffer? {
        get {
            return self._sessionVideoCustomContextImageBuffer
        }
        set {
            self.executeClosureSyncOnSessionQueueIfNecessary {
                self._sessionVideoCustomContextImageBuffer = newValue
            }
        }
    }
    
    /// Initiates video recording, managed as a clip within the 'NextLevelSession'
    public func record() {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self._recording = true
            if let _ = self._recordingSession {
                self.beginRecordingNewClipIfNecessary()
            }
        }
    }
        
    /// Pauses video recording, preparing 'NextLevel' to start a new clip with 'record()' with completion handler.
    ///
    /// - Parameter completionHandler: Completion handler for when pause completes
    public func pause(withCompletionHandler completionHandler: (() -> Void)? = nil) {
        self._recording = false
        
        self.executeClosureAsyncOnSessionQueueIfNecessary {
            if let session = self._recordingSession {
                if session.currentClipHasStarted {
                    session.endClip(completionHandler: { (sessionClip: NextLevelClip?, error: Error?) in
                        if let sessionClip = sessionClip {
                            DispatchQueue.main.async {
                                self.videoDelegate?.nextLevel(self, didCompleteClip: sessionClip, inSession: session)
                            }
                            if let completionHandler = completionHandler {
                                DispatchQueue.main.async(execute: completionHandler)
                            }
                        } else if let _ = error {
                            // TODO, report error
                            if let completionHandler = completionHandler {
                                DispatchQueue.main.async(execute: completionHandler)
                            }
                        }
                    })
                } else if let completionHandler = completionHandler {
                    DispatchQueue.main.async(execute: completionHandler)
                }
            } else if let completionHandler = completionHandler {
                DispatchQueue.main.async(execute: completionHandler)
            }
        }
    }
    
    internal func beginRecordingNewClipIfNecessary() {
        if let session = self._recordingSession,
            session.isReady == false {
            session.beginClip()
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.videoDelegate?.nextLevel(self, didStartClipInSession: session)
            }
        }
    }
    
}

// MARK: - photo capture

extension NextLevel {
    
    /// Checks if a photo capture operation can be performed, based on available storage space and supported hardware functionality.
    public var canCapturePhoto: Bool {
        get {
            let canCapturePhoto: Bool = (self._captureSession?.isRunning == true)
            return canCapturePhoto && FileManager.availableStorageSpaceInBytes() > NextLevelRequiredMinimumStorageSpaceInBytes
        }
    }
    
    /// Triggers a photo capture.
    public func capturePhoto() {
        if let photoOutput = self._photoOutput,
           let _ = photoOutput.connection(with: AVMediaType.video) {
            if let formatDictionary = self.photoConfiguration.avcaptureDictionary() {
                
                let photoSettings = AVCapturePhotoSettings(format: formatDictionary)
                photoSettings.isHighResolutionPhotoEnabled = self.photoConfiguration.isHighResolutionEnabled
                
                if #available(iOS 11.0, *) {
                    if photoOutput.isDepthDataDeliverySupported {
                        photoOutput.isDepthDataDeliveryEnabled = self.photoConfiguration.isDepthDataEnabled
                        photoSettings.embedsDepthDataInPhoto = self.photoConfiguration.isDepthDataEnabled
                    }
                }
                
                if self.isFlashAvailable {
                    photoSettings.flashMode = self.photoConfiguration.flashMode
                }
                
                photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
        }
    }
    
}

// MARK: - NextLevelSession and sample buffer processing

extension NextLevel {
    
    // sample buffer processing
    
    internal func handleVideoOutput(sampleBuffer: CMSampleBuffer, session: NextLevelSession) {
        if session.isVideoReady == false {
            if let settings = self.videoConfiguration.avcaptureSettingsDictionary(sampleBuffer: sampleBuffer),
                let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                if !session.setupVideo(withSettings: settings, configuration: self.videoConfiguration, formatDescription: formatDescription) {
                    print("NextLevel, could not setup video session")
                }
            }
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.videoDelegate?.nextLevel(self, didSetupVideoInSession: session)
            }
        }
        
        if self._recording && (session.isAudioReady || self.captureMode == .videoWithoutAudio) && session.currentClipHasStarted {
            self.beginRecordingNewClipIfNecessary()
            
            let minTimeBetweenFrames = 0.004
            let sleepDuration = minTimeBetweenFrames - (CACurrentMediaTime() - self._lastVideoFrameTimeInterval)
            if sleepDuration > 0 {
                Thread.sleep(forTimeInterval: sleepDuration)
            }
            
            if let device = self._currentDevice {
                
                // check with the client to setup/maintain external render contexts
                let imageBuffer = self.isVideoCustomContextRenderingEnabled == true ? CMSampleBufferGetImageBuffer(sampleBuffer) : nil
                if let imageBuffer = imageBuffer {
                    if CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess {
                        // only called from captureQueue
                        self.videoDelegate?.nextLevel(self, renderToCustomContextWithImageBuffer: imageBuffer, onQueue: self._sessionQueue)
                    } else {
                        self._sessionVideoCustomContextImageBuffer = nil
                    }
                }
                
                // when clients modify a frame using their rendering context, the resulting CVPixelBuffer is then passed in here with the original sampleBuffer for recording
                session.appendVideo(withSampleBuffer: sampleBuffer, customImageBuffer: self._sessionVideoCustomContextImageBuffer, minFrameDuration: device.activeVideoMinFrameDuration, completionHandler: { (success: Bool) -> Void in
                    // cleanup client rendering context
                    if self.isVideoCustomContextRenderingEnabled {
                        if let imageBuffer = imageBuffer {
                            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
                        }
                    }
                    
                    // process frame
                    self._lastVideoFrameTimeInterval = CACurrentMediaTime()
                    if success == true {
                        self.executeClosureAsyncOnMainQueueIfNecessary {
                            self.videoDelegate?.nextLevel(self, didAppendVideoSampleBuffer: sampleBuffer, inSession: session)
                        }
                        self.checkSessionDuration()
                    } else {
                        self.executeClosureAsyncOnMainQueueIfNecessary {
                            self.videoDelegate?.nextLevel(self, didSkipVideoSampleBuffer: sampleBuffer, inSession: session)
                        }
                    }
                })
                
                
                if session.currentClipHasVideo == false && (session.currentClipHasAudio == false || self.captureMode == .videoWithoutAudio) {
                    if let audioBuffer = self._lastAudioFrame {
                        let lastAudioEndTime = CMTimeAdd(CMSampleBufferGetPresentationTimeStamp(audioBuffer), CMSampleBufferGetDuration(audioBuffer))
                        let videoStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        
                        if lastAudioEndTime > videoStartTime {
                            self.handleAudioOutput(sampleBuffer: audioBuffer, session: session)
                        }
                    }
                }
            } // self._currentDevice
        }
    }
    
    // Beta: handleVideoOutput(pixelBuffer:timestamp:session:) needs to be tested
    internal func handleVideoOutput(pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, session: NextLevelSession) {
        if session.isVideoReady == false {
            if let settings = self.videoConfiguration.avcaptureSettingsDictionary(pixelBuffer: pixelBuffer) {
                if !session.setupVideo(withSettings: settings, configuration: self.videoConfiguration) {
                    print("NextLevel, could not setup video session")
                }
            }
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.videoDelegate?.nextLevel(self, didSetupVideoInSession: session)
            }
        }

        if self._recording && (session.isAudioReady || self.captureMode == .videoWithoutAudio) && session.currentClipHasStarted {
            self.beginRecordingNewClipIfNecessary()

            let minTimeBetweenFrames = 0.004
            let sleepDuration = minTimeBetweenFrames - (CACurrentMediaTime() - self._lastVideoFrameTimeInterval)
            if sleepDuration > 0 {
                Thread.sleep(forTimeInterval: sleepDuration)
            }

            // check with the client to setup/maintain external render contexts
            let imageBuffer = self.isVideoCustomContextRenderingEnabled == true ? pixelBuffer : nil
            if let imageBuffer = imageBuffer {
                if CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess {
                    // only called from captureQueue
                    self.videoDelegate?.nextLevel(self, renderToCustomContextWithImageBuffer: imageBuffer, onQueue: self._sessionQueue)
                } else {
                    self._sessionVideoCustomContextImageBuffer = nil
                }
            }

            // when clients modify a frame using their rendering context, the resulting CVPixelBuffer is then passed in here with the original sampleBuffer for recording
            session.appendVideo(withPixelBuffer: pixelBuffer, customImageBuffer: self._sessionVideoCustomContextImageBuffer, timestamp: timestamp, minFrameDuration: CMTime(seconds: 1, preferredTimescale: 600), completionHandler: { (success: Bool) -> Void in
                // cleanup client rendering context
                if self.isVideoCustomContextRenderingEnabled {
                    if let imageBuffer = imageBuffer {
                        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
                    }
                }

                // process frame
                self._lastVideoFrameTimeInterval = CACurrentMediaTime()
                if success == true {
                    self.executeClosureAsyncOnMainQueueIfNecessary {
                        self.videoDelegate?.nextLevel(self, didAppendVideoPixelBuffer: pixelBuffer, timestamp: timestamp, inSession: session)
                    }
                    self.checkSessionDuration()
                } else {
                    self.executeClosureAsyncOnMainQueueIfNecessary {
                        self.videoDelegate?.nextLevel(self, didSkipVideoPixelBuffer: pixelBuffer, timestamp: timestamp, inSession: session)
                    }
                }
            })

            if session.currentClipHasVideo == false && (session.currentClipHasAudio == false || self.captureMode == .videoWithoutAudio) {
                if let audioBuffer = self._lastAudioFrame {
                    let lastAudioEndTime = CMTimeAdd(CMSampleBufferGetPresentationTimeStamp(audioBuffer), CMSampleBufferGetDuration(audioBuffer))
                    let videoStartTime = CMTime(seconds: timestamp, preferredTimescale: 600)

                    if lastAudioEndTime > videoStartTime {
                        self.handleAudioOutput(sampleBuffer: audioBuffer, session: session)
                    }
                }
            }
        }
    }
    
    internal func handleAudioOutput(sampleBuffer: CMSampleBuffer, session: NextLevelSession) {
        if session.isAudioReady == false {
            if let settings = self.audioConfiguration.avcaptureSettingsDictionary(sampleBuffer: sampleBuffer),
                let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                if !session.setupAudio(withSettings: settings, configuration: self.audioConfiguration, formatDescription: formatDescription) {
                    print("NextLevel, could not setup audio session")
                }
            }
            
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.videoDelegate?.nextLevel(self, didSetupAudioInSession: session)
            }
        }
        
        if self._recording && session.isVideoReady && session.currentClipHasStarted && session.currentClipHasVideo {
            self.beginRecordingNewClipIfNecessary()
            
            session.appendAudio(withSampleBuffer: sampleBuffer, completionHandler: { (success: Bool) -> Void in
                if success {
                    self.executeClosureAsyncOnMainQueueIfNecessary {
                        self.videoDelegate?.nextLevel(self, didAppendAudioSampleBuffer: sampleBuffer, inSession: session)
                    }
                    self.checkSessionDuration()
                } else {
                    self.executeClosureAsyncOnMainQueueIfNecessary {
                        self.videoDelegate?.nextLevel(self, didSkipAudioSampleBuffer: sampleBuffer, inSession: session)
                    }
                }
            })
        }
    }
    
    private func checkSessionDuration() {
        if let session = self._recordingSession,
            let maximumCaptureDuration = self.videoConfiguration.maximumCaptureDuration {
            if maximumCaptureDuration.isValid && session.totalDuration >= maximumCaptureDuration {
                self._recording = false
                
                // already on session queue, adding to next cycle
                self.executeClosureAsyncOnSessionQueueIfNecessary {
                    session.endClip(completionHandler: { (sessionClip: NextLevelClip?, error: Error?) in
                        if let clip = sessionClip {
                            self.executeClosureAsyncOnMainQueueIfNecessary {
                                self.videoDelegate?.nextLevel(self, didCompleteClip: clip, inSession: session)
                            }
                        } else if let _ = error {
                            // TODO report error
                        }
                        self.executeClosureAsyncOnMainQueueIfNecessary {
                            self.videoDelegate?.nextLevel(self, didCompleteSession: session)
                        }
                    })
                }
            }
        }
    }
    
    private func setupContextIfNecessary() {
        if self._ciContext == nil {
            let options : [String : AnyObject] = [kCIContextWorkingColorSpace : CGColorSpaceCreateDeviceRGB(),
                                                  kCIContextUseSoftwareRenderer : NSNumber(booleanLiteral: false)]
            if let device = MTLCreateSystemDefaultDevice() {
                self._ciContext = CIContext(mtlDevice: device, options: options)
            } else if let eaglContext = EAGLContext(api: .openGLES2) {
                self._ciContext = CIContext(eaglContext: eaglContext, options: options)
            }
        }
    }
    
    private func setupPixelBufferPoolIfNecessary(_ pixelBuffer: CVPixelBuffer) {
        let formatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        guard self._pixelBufferPool == nil ||
              width != self._bufferWidth ||
              height != self._bufferHeight ||
              formatType != self._bufferFormatType
        else {
            return
        }
        
        self._bufferWidth = width
        self._bufferHeight = height
        self._bufferFormatType = formatType
        
        let pixelBufferPoolMinimumCount = 3
        let poolAttributes: [String:AnyObject] = [String(kCVPixelBufferPoolMinimumBufferCountKey): NSNumber(integerLiteral: pixelBufferPoolMinimumCount)]
        
        // TODO: doesn't properly support orientation, should reference videoConfiguration settings
        let pixelBufferAttributes: [String:AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(integerLiteral: Int(self._bufferFormatType)),
                                                         String(kCVPixelBufferWidthKey) : NSNumber(value: self._bufferHeight), // flip
                                                         String(kCVPixelBufferHeightKey) : NSNumber(value: self._bufferWidth), // flip
                                                         String(kCVPixelBufferMetalCompatibilityKey) : NSNumber(booleanLiteral: true),
                                                         String(kCVPixelBufferIOSurfacePropertiesKey) : [:] as AnyObject ]
        
        var pixelBufferPool: CVPixelBufferPool? = nil
        if CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as CFDictionary, pixelBufferAttributes as CFDictionary, &pixelBufferPool) == kCVReturnSuccess {
            self._pixelBufferPool = pixelBufferPool
        }
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate

extension NextLevel: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.captureMode == .videoWithoutAudio && captureOutput == self._videoOutput {
            self.videoDelegate?.nextLevel(self, willProcessRawVideoSampleBuffer: sampleBuffer, onQueue: self._sessionQueue)
            self._lastVideoFrame = sampleBuffer
            if let session = self._recordingSession {
                self.handleVideoOutput(sampleBuffer: sampleBuffer, session: session)
            }
            
        }
        else if let videoOutput = self._videoOutput,
            let audioOutput = self._audioOutput {
            switch captureOutput {
            case videoOutput:
                self.videoDelegate?.nextLevel(self, willProcessRawVideoSampleBuffer: sampleBuffer, onQueue: self._sessionQueue)
                self._lastVideoFrame = sampleBuffer
                if let session = self._recordingSession {
                    self.handleVideoOutput(sampleBuffer: sampleBuffer, session: session)
                }
                break
            case audioOutput:
                self._lastAudioFrame = sampleBuffer
                if let session = self._recordingSession {
                    self.handleAudioOutput(sampleBuffer: sampleBuffer, session: session)
                }
                break
            default:
                break
            }
        }
    }
    
}

// MARK: - AVCapturePhotoCaptureDelegate

extension NextLevel: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.photoDelegate?.nextLevel(self, willCapturePhotoWithConfiguration: self.photoConfiguration)
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.photoDelegate?.nextLevel(self, didCapturePhotoWithConfiguration: self.photoConfiguration)
        }
    }
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let sampleBuffer = photoSampleBuffer {
            
            // output dictionary
            var photoDict: [String: Any] = [:]
            
            // append tiff metadata
            sampleBuffer.append(metadataAdditions: NextLevel.tiffMetadata())
            
            // add exif metadata
            if let metadata = sampleBuffer.metadata() {
                photoDict[NextLevelPhotoMetadataKey] = metadata
            }
            
            // add JPEG, thumbnail
            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            if let data = imageData {
                photoDict[NextLevelPhotoJPEGKey] = data
            }
            
            // add explicit thumbnail
            //let thumbnailData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: previewBuffer, previewPhotoSampleBuffer: nil)
            //if let tData = thumbnailData {
            //    photoDict[NextLevelPhotoThumbnailKey] = tData
            //}
            
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.photoDelegate?.nextLevel(self, didProcessPhotoCaptureWith: photoDict, photoConfiguration: self.photoConfiguration)
            }
        }
    }
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let sampleBuffer = rawSampleBuffer {
            
            // output dictionary
            var photoDict: [String: Any] = [:]
            
            // append tiff metadata
            sampleBuffer.append(metadataAdditions: NextLevel.tiffMetadata())
            
            // add exif metadata
            if let metadata = sampleBuffer.metadata() {
                photoDict[NextLevelPhotoMetadataKey] = metadata
            }
            
            // add Raw + thumbnail
            let imageData = AVCapturePhotoOutput.dngPhotoDataRepresentation(forRawSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            if let data = imageData {
                photoDict[NextLevelPhotoRawImageKey] = data
            }
            
            // add explicit thumbnail
            // TODO based on configuration pixel buffer
            //let thumbnailData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: previewBuffer, previewPhotoSampleBuffer: nil)
            //if let tData = thumbnailData {
            //    photoDict[NextLevelPhotoThumbnailKey] = tData
            //}
            
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.photoDelegate?.nextLevel(self, didProcessRawPhotoCaptureWith: photoDict, photoConfiguration: self.photoConfiguration)
            }
        }
    }
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.photoDelegate?.nextLevelDidCompletePhotoCapture(self)
        }
    }
    
}

// MARK: - AVCaptureDepthDataOutputDelegate

@available(iOS 11.0, *)
extension NextLevel: AVCaptureDepthDataOutputDelegate {
    
    public func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            self.depthDataDelegate?.depthDataOutput(self, didOutput: depthData, timestamp: timestamp)
        }
    }
    
    public func depthDataOutput(_ output: AVCaptureDepthDataOutput, didDrop depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection, reason: AVCaptureOutput.DataDroppedReason) {
            self.depthDataDelegate?.depthDataOutput(self, didDrop: depthData, timestamp: timestamp, reason: reason)
    }
    
}

#if USE_ARKIT
// MARK: - ARSession

@available(iOS 11.0, *)
extension NextLevel {
   
    public func arSession(_ session: ARSession, didUpdate frame: ARFrame) {
        var pixelBuffer = frame.capturedImage
        let timestamp = frame.timestamp

        // TODO: support orientation changes, maybe use snapshot API instead
        self.setupPixelBufferPoolIfNecessary(pixelBuffer)
        if let pixelBufferPool = self._pixelBufferPool,
            let adjustedPixelBuffer = self._ciContext?.createPixelBuffer(fromPixelBuffer: pixelBuffer, withOrientation: .right, pixelBufferPool: pixelBufferPool) {
            pixelBuffer = adjustedPixelBuffer
        
            self.videoDelegate?.nextLevel(self, willProcessFrame: frame, pixelBuffer: pixelBuffer, timestamp: timestamp, onQueue: self._sessionQueue)
            self._lastARFrame = pixelBuffer
            
            if let session = self._recordingSession {
                self.handleVideoOutput(pixelBuffer: pixelBuffer, timestamp: timestamp, session: session)
            }
        }
    }
    
    public func arSession(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        self._lastAudioFrame = audioSampleBuffer
        if let session = self._recordingSession {
            self.handleAudioOutput(sampleBuffer: audioSampleBuffer, session: session)
        }
    }
    
}
#endif

// MARK: - queues

extension NextLevel {
    
    internal func executeClosureAsyncOnMainQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        DispatchQueue.main.async(execute: closure)
    }
    
    internal func executeClosureAsyncOnSessionQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        self._sessionQueue.async(execute: closure)
    }
    
    internal func executeClosureSyncOnSessionQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: NextLevelCaptureSessionQueueSpecificKey) != nil {
            closure()
        } else {
            self._sessionQueue.sync(execute: closure)
        }
    }
}

// MARK: - NSNotifications

extension NextLevel {
    
    // application
    
    internal func addApplicationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleApplicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleApplicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    internal func removeApplicationObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    @objc internal func handleApplicationWillEnterForeground(_ notification: Notification) {
        //self.sessionQueue.async {}
    }
    
    @objc internal func handleApplicationDidEnterBackground(_ notification: Notification) {
        self.executeClosureAsyncOnSessionQueueIfNecessary {
            if self.isRecording {
                self.pause()
            }
        }
    }
    
    // session
    
    internal func addSessionObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleSessionDidStartRunning(_:)), name: .AVCaptureSessionDidStartRunning, object: self._captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleSessionDidStopRunning(_:)), name: .AVCaptureSessionDidStopRunning, object: self._captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleSessionRuntimeError(_:)), name: .AVCaptureSessionRuntimeError, object: self._captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleSessionWasInterrupted(_:)), name: .AVCaptureSessionWasInterrupted, object: self._captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleSessionInterruptionEnded(_:)), name: .AVCaptureSessionInterruptionEnded, object: self._captureSession)
    }
    
    internal func removeSessionObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionDidStartRunning, object: self._captureSession)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionDidStopRunning, object: self._captureSession)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionRuntimeError, object: self._captureSession)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionWasInterrupted, object: self._captureSession)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionInterruptionEnded, object: self._captureSession)
    }
    
    @objc internal func handleSessionDidStartRunning(_ notification: Notification) {
        //self.performRecoveryCheckIfNecessary()
        // TODO
        DispatchQueue.main.async {
            self.delegate?.nextLevelSessionDidStart(self)
        }
    }
    
    @objc internal func handleSessionDidStopRunning(_ notification: Notification) {
        DispatchQueue.main.async {
            self.delegate?.nextLevelSessionDidStop(self)
        }
    }
    
    @objc internal func handleSessionRuntimeError(_ notification: Notification) {
        self.executeClosureAsyncOnSessionQueueIfNecessary {
            if let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError {
                switch error.code {
                case .deviceIsNotAvailableInBackground:
                    print("NextLevel, error, media services are not available in the background")
                    break
                case .mediaServicesWereReset:
                    fallthrough
                default:
                    // TODO reset capture
                    break
                }
            }
        }
    }
    
    @objc public func handleSessionWasInterrupted(_ notification: Notification) {
        DispatchQueue.main.async {
            if self._recording {
                self.delegate?.nextLevelSessionDidStop(self)
            }
            
            DispatchQueue.main.async {
                self.delegate?.nextLevelSessionWasInterrupted(self)
            }
        }
    }
    
    @objc public func handleSessionInterruptionEnded(_ notification: Notification) {
        DispatchQueue.main.async {
            self.delegate?.nextLevelSessionInterruptionEnded(self)
        }
    }
    
    // device
    
    internal func addDeviceObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.deviceSubjectAreaDidChange(_:)), name: .AVCaptureDeviceSubjectAreaDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.deviceInputPortFormatDescriptionDidChange(_:)), name: .AVCaptureInputPortFormatDescriptionDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.deviceOrientationDidChange(_:)), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    internal func removeDeviceObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureInputPortFormatDescriptionDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    @objc internal func deviceSubjectAreaDidChange(_ notification: NSNotification) {
        self.adjustFocusExposureAndWhiteBalance()
    }
    
    @objc internal func deviceInputPortFormatDescriptionDidChange(_ notification: Notification) {
        if let session = self._captureSession {
            let inputs: [AVCaptureInput] = session.inputs
            if let input = inputs.first,
                let port = input.ports.first,
                let formatDescription: CMFormatDescription = port.formatDescription {
                let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription, true)
                self.deviceDelegate?.nextLevel(self, didChangeCleanAperture: cleanAperture)
            }
        }
    }
    
    @objc internal func deviceOrientationDidChange(_ notification: NSNotification) {
        if self.automaticallyUpdatesDeviceOrientation {
            self._sessionQueue.sync {
                self.updateVideoOrientation()
            }
        }
    }
}

// MARK: - KVO and KVO constants

private var NextLevelFocusObserverContext = "NextLevelFocusObserverContext"
private var NextLevelExposureObserverContext = "NextLevelExposureObserverContext"
private var NextLevelWhiteBalanceObserverContext = "NextLevelWhiteBalanceObserverContext"

private var NextLevelFlashAvailabilityObserverContext = "NextLevelFlashAvailabilityObserverContext"
private var NextLevelTorchAvailabilityObserverContext = "NextLevelTorchAvailabilityObserverContext"
private var NextLevelFlashActiveObserverContext = "NextLevelFlashActiveObserverContext"
private var NextLevelTorchActiveObserverContext = "NextLevelTorchActiveObserverContext"

private var NextLevelVideoZoomFactorObserverContext = "NextLevelVideoZoomFactorObserverContext"

extension NextLevel {
    
    internal func addKeyValueObservers(_ currentDevice: AVCaptureDevice) {
        currentDevice.addObserver(self, forKeyPath: "adjustingFocus", options: [.new], context: &NextLevelFocusObserverContext)
        currentDevice.addObserver(self, forKeyPath: "adjustingExposure", options: [.new], context: &NextLevelExposureObserverContext)
        currentDevice.addObserver(self, forKeyPath: "adjustingWhiteBalance", options: [.new], context: &NextLevelWhiteBalanceObserverContext)
        currentDevice.addObserver(self, forKeyPath: "flashAvailable", options: [.new], context: &NextLevelFlashAvailabilityObserverContext)
        currentDevice.addObserver(self, forKeyPath: "torchAvailable", options: [.new], context: &NextLevelTorchAvailabilityObserverContext)
        currentDevice.addObserver(self, forKeyPath: "flashActive", options: [.new], context: &NextLevelFlashActiveObserverContext)
        currentDevice.addObserver(self, forKeyPath: "torchActive", options: [.new], context: &NextLevelTorchActiveObserverContext)
        currentDevice.addObserver(self, forKeyPath: "videoZoomFactor", options: [.new], context: &NextLevelVideoZoomFactorObserverContext)
    }
    
    internal func removeKeyValueObservers(_ currentDevice: AVCaptureDevice) {
        currentDevice.removeObserver(self, forKeyPath: "adjustingFocus")
        currentDevice.removeObserver(self, forKeyPath: "adjustingExposure")
        currentDevice.removeObserver(self, forKeyPath: "adjustingWhiteBalance")
        currentDevice.removeObserver(self, forKeyPath: "flashAvailable")
        currentDevice.removeObserver(self, forKeyPath: "torchAvailable")
        currentDevice.removeObserver(self, forKeyPath: "flashActive")
        currentDevice.removeObserver(self, forKeyPath: "torchActive")
        currentDevice.removeObserver(self, forKeyPath: "videoZoomFactor")
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &NextLevelFocusObserverContext {
            
            if let isFocusing = (change?[.newKey] as? Bool) {
                if isFocusing {
                    self.focusStarted()
                } else {
                    self.focusEnded()
                }
            }
            
        } else if context == &NextLevelExposureObserverContext {
            
            if let isChangingExposure = (change?[.newKey] as? Bool) {
                if isChangingExposure {
                    self.exposureStarted()
                } else {
                    self.exposureEnded()
                }
            }
            
        } else if context == &NextLevelWhiteBalanceObserverContext {
            
            if let isChangingWhiteBalance = (change?[.newKey] as? Bool) {
                if isChangingWhiteBalance {
                    self.whiteBalanceStarted()
                } else {
                    self.whiteBalanceEnded()
                }
            }
            
        } else if context == &NextLevelFlashAvailabilityObserverContext ||
            context == &NextLevelTorchAvailabilityObserverContext {
            
            self.flashAndTorchAvailabilityChanged()
            
        } else if context == &NextLevelFlashActiveObserverContext {
            
            self.flashActiveChanged()
            
        } else if context == &NextLevelTorchActiveObserverContext {
            
            self.torchActiveChanged()
            
        } else if context == &NextLevelVideoZoomFactorObserverContext {
            
            self.videoZoomFactorChanged()
            
        }
    }
    
}
