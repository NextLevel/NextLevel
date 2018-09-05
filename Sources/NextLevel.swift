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

/// Operation modes for NextLevel.
/// Note: video, audio, and videoWithoutAudio options support multi clip recording.
/// Movie is strictly for single clip recording.
public enum NextLevelCaptureMode: Int, CustomStringConvertible {
    case video = 0
    case photo
    case audio
    case videoWithoutAudio
    case movie
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
            case .movie:
                return "Movie"
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
public typealias NextLevelWhiteBalanceMode = AVCaptureDevice.WhiteBalanceMode

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
    internal var _movieFileOutput: AVCaptureMovieFileOutput?
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
    internal var _observers = [NSKeyValueObservation]()
    
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
        case .movie:
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

// MARK: - private session configuration support

extension NextLevel {
    
    // re-entrant configuration lock, thanks to SCRecorder
    internal func beginConfiguration() {
        guard let session = self._captureSession else {
            return
        }

        self._sessionConfigurationCount += 1
        if self._sessionConfigurationCount == 1 {
            session.beginConfiguration()
        }
    }
    
    internal func commitConfiguration() {
        guard let session = self._captureSession else {
            return
        }
        
        self._sessionConfigurationCount -= 1
        if self._sessionConfigurationCount == 0 {
            session.commitConfiguration()
        }
    }
    
    internal func configureSessionDevices() {
        guard let _ = self._captureSession else {
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
        case .movie:
            // TODO
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
        guard let session = self._captureSession else {
            return
        }

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
        case .movie:
            // TODO
            break
        case .arKit:
            // no AV inputs to setup
            break
        }
        
        self.commitConfiguration()
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
    
    private func addMovieOutput() -> Bool {
        
        if self._movieFileOutput == nil {
            self._movieFileOutput = AVCaptureMovieFileOutput()
        }
        
        // TODO configuration
        
        if let session = self._captureSession, let movieOutput = self._movieFileOutput {
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
                return true
            }
        }
        print("NextLevel, couldn't add movie output to session")
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
        self._movieFileOutput = nil
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
        case .movie:
            if let movieOutput = self._movieFileOutput, session.outputs.contains(movieOutput) {
                session.removeOutput(movieOutput)
                self._movieFileOutput = nil
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

// MARK: - preview

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
}

// MARK: - capture device switching

extension NextLevel {
    
    /// Triggers a camera device position change.
    public func flipCaptureDevicePosition() {
        self.devicePosition = self.devicePosition == .back ? .front : .back
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
            self.deviceDelegate?.nextLevel(self, didChangeDeviceOrientation: currentOrientation)
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

// MARK: - mirroring

extension NextLevel {
    
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
            guard let _ = self._captureSession,
                let videoOutput = self._videoOutput
                else {
                    return
            }
            
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

// MARK: - flash and torch

extension NextLevel {
    
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
            return self.photoConfiguration.flashMode
        }
        set {
            guard let device = self._currentDevice, device.hasFlash
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
                guard let device = self._currentDevice,
                    device.hasTorch,
                    device.torchMode != newValue
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

// MARK: - focus, exposure, white balance

extension NextLevel {
    
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
            if let device = self._currentDevice {
                return device.isFocusModeSupported(.locked)
            }
            return false
        }
    }
    
    /// Checks if focus adjustment is in progress.
    public var isAdjustingFocus: Bool {
        get {
            if let device = self._currentDevice {
                return device.isAdjustingFocus
            }
            return false
        }
    }
    
    /// The focus mode of the device.
    public var focusMode: NextLevelFocusMode {
        get {
            if let device = self._currentDevice {
                return device.focusMode
            }
            return .locked
        }
        set {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                guard let device = self._currentDevice,
                    device.isFocusModeSupported(newValue),
                    device.focusMode != newValue
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
    
    /// The lens position of the device.
    public var lensPosition: Float {
        get {
            if let device = self._currentDevice {
                return device.lensPosition
            }
            return 1.0
        }
        set {
            guard let device = self._currentDevice,
                device.focusMode == .locked,
                device.isFocusModeSupported(.locked)
                else {
                    return
            }
            
            let newLensPosition = newValue.clamped(to: 0...1)
            
            do {
                try device.lockForConfiguration()
                
                device.setFocusModeLocked(lensPosition: newLensPosition, completionHandler: nil)
                
                device.unlockForConfiguration()
            }
            catch {
                print("NextLevel, lens position failed to lock device for configuration")
            }
        }
    }
    
    /// Focuses, exposures, and adjusts white balanace at the point of interest.
    ///
    /// - Parameter adjustedPoint: The point of interest.
    public func focusExposeAndAdjustWhiteBalance(atAdjustedPoint adjustedPoint: CGPoint) {
        guard let device = self._currentDevice,
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
    
    /// Changes focus at adjusted point of interest.
    ///
    /// - Parameter adjustedPoint: The point of interest for focus
    public func focusAtAdjustedPointOfInterest(adjustedPoint: CGPoint) {
        guard let device = self._currentDevice,
                !device.isAdjustingFocus,
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
            if let device = self._currentDevice {
                return device.exposureMode
            }
            return .locked
        }
        set {
            guard let device = self._currentDevice,
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
    
    /// Changes exposure at adjusted point of interest.
    ///
    /// - Parameter adjustedPoint: The point of interest for exposure.
    public func exposeAtAdjustedPointOfInterest(adjustedPoint: CGPoint) {
        guard let device = self._currentDevice,
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
    
    /// Adjusts exposure duration to a custom value in seconds.
    ///
    /// - Parameter duration: The exposure duration in seconds.
    /// - Parameter durationPower: Larger power values will increase the sensitivity at shorter durations.
    /// - Parameter minDurationRangeLimit: Minimum limitation for duration.
    public func expose(withDuration duration: Double, durationPower: Double = 5, minDurationRangeLimit: Double = (1.0 / 1000.0)) {
        guard let device = self._currentDevice,
            !device.isAdjustingExposure
        else {
                return
        }
        
        let newDuration = duration.clamped(to: 0...1)
        
        let minDurationSeconds: Double = Swift.max(CMTimeGetSeconds(device.activeFormat.minExposureDuration), minDurationRangeLimit)
        let maxDurationSeconds: Double = CMTimeGetSeconds(device.activeFormat.maxExposureDuration)

        let p: Double = pow(newDuration, durationPower)
        let newDurationSeconds: Double = (p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds)
        
        do {
            try device.lockForConfiguration()
            
            device.setExposureModeCustom(duration: CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 ), iso: AVCaptureDevice.currentISO, completionHandler: nil)
            
            device.unlockForConfiguration()
        } catch {
            print("NextLevel, setExposureModeCustom failed to lock device for configuration")
        }
    }
    
    /// Adjusts exposure to a specific custom ISO value.
    ///
    /// - Parameter iso: The exposure ISO value.
    public func expose(withISO iso: Float) {
        guard let device = self._currentDevice,
                !device.isAdjustingExposure
        else {
            return
        }
 
        let newISO = iso.clamped(to: device.activeFormat.minISO...device.activeFormat.maxISO)
        
        do {
            try device.lockForConfiguration()
            
            device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: newISO, completionHandler: nil)
            
            device.unlockForConfiguration()
        } catch {
            print("NextLevel, setExposureModeCustom failed to lock device for configuration")
        }
    }
    
    /// Adjusts exposure to the specified target bias.
    ///
    /// - Parameter targetBias: The exposure target bias.
    public func expose(withTargetBias targetBias: Float) {
        guard let device = self._currentDevice,
                !device.isAdjustingExposure
        else {
            return
        }
        
        let newTargetBias = targetBias.clamped(to: device.minExposureTargetBias...device.maxExposureTargetBias)
        
        do {
            try device.lockForConfiguration()
            
            device.setExposureTargetBias(newTargetBias, completionHandler: nil)
            
            device.unlockForConfiguration()
        } catch {
            print("NextLevel, setExposureTargetBias failed to lock device for configuration")
        }
    }
    
    // white balance
    
    /// Checks if white balance lock is supported.
    public var isWhiteBalanceLockSupported: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isWhiteBalanceModeSupported(.locked)
            }
            return false
        }
    }
    
    /// Checks if an white balance adjustment is progress.
    public var isAdjustingWhiteBalance: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isAdjustingWhiteBalance
            }
            return false
        }
    }
    
    /// The white balance mode of the device.
    public var whiteBalanceMode: NextLevelWhiteBalanceMode {
        get {
            if let device = self._currentDevice {
                return device.whiteBalanceMode
            }
            return .locked
        }
        set {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                guard let device = self._currentDevice,
                    device.isWhiteBalanceModeSupported(newValue),
                    device.whiteBalanceMode != newValue
                else {
                    return
                }
                
                do {
                    try device.lockForConfiguration()
                    device.whiteBalanceMode = newValue
                    device.unlockForConfiguration()
                } catch {
                    print("NextLevel, whiteBalanceMode failed to lock device for configuration")
                }
            }
        }
    }
    
    // TODO: chromaticity support?
    
    public var whiteBalanceTemperature: Float {
        get {
            if let device = self._currentDevice {
                return device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains).temperature
            }
            return 8000
        }
        set {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                guard let device = self._currentDevice,
                    device.isWhiteBalanceModeSupported(.locked),
                    device.whiteBalanceMode == .locked
                    else {
                        return
                }
                
                let newTemperature = newValue.clamped(to: 3000...8000)
                let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: newTemperature, tint: device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains).tint)
                
                do {
                    try device.lockForConfiguration()
                    device.deviceWhiteBalanceGains(for: temperatureAndTint)
                    device.unlockForConfiguration()
                } catch {
                    print("NextLevel, deviceWhiteBalanceGains failed to lock device for configuration")
                }
            }
        }
    }
    
    public var whiteBalanceTint: Float {
        get {
            if let device = self._currentDevice {
                return device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains).tint
            }
            return 150
        }
        set {
            self.executeClosureAsyncOnSessionQueueIfNecessary {
                guard let device = self._currentDevice,
                    device.isWhiteBalanceModeSupported(.locked),
                    device.whiteBalanceMode == .locked
                    else {
                        return
                }
                
                let newTint = newValue.clamped(to: -150...150)
                let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains).temperature, tint: newTint)
                
                do {
                    try device.lockForConfiguration()
                    device.deviceWhiteBalanceGains(for: temperatureAndTint)
                    device.unlockForConfiguration()
                } catch {
                    print("NextLevel, deviceWhiteBalanceGains failed to lock device for configuration")
                }
            }
        }
    }
    
    /// Adjusts white balance gains to custom values.
    ///
    /// - Parameter whiteBalanceGains: Gains values for adjustment.
    public func adjustWhiteBalanceGains(_ whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains) {
        guard let device = self._currentDevice else {
                return
        }
        
        let newWhiteBalanceGains = whiteBalanceGains.normalize(device)
        
        do {
            try device.lockForConfiguration()
            
            device.setWhiteBalanceModeLocked(with: newWhiteBalanceGains, completionHandler: nil)
            
            device.unlockForConfiguration()
        } catch {
            print("NextLevel, setWhiteBalanceModeLocked failed to lock device for configuration")
        }
    }
    
    // private functions
    
    internal func adjustFocusExposureAndWhiteBalance() {
        guard let device = self._currentDevice,
            !device.isAdjustingFocus,
            !device.isAdjustingExposure
        else {
            return
        }
        
        if self.focusMode != .locked {
            self.deviceDelegate?.nextLevelWillStartFocus(self)
            self.focusAtAdjustedPointOfInterest(adjustedPoint: CGPoint(x: 0.5, y: 0.5))
        }
    }
    
    internal func adjustWhiteBalanceForExposureMode(exposureMode: AVCaptureDevice.ExposureMode) {
        guard let device = self._currentDevice else {
            return
        }
        
        let whiteBalanceMode = self.whiteBalanceModeBestForExposureMode(exposureMode: exposureMode)
        if device.isWhiteBalanceModeSupported(whiteBalanceMode) {
            device.whiteBalanceMode = whiteBalanceMode
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
        guard let device = self._currentDevice,
                !device.isAdjustingFocus
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
    
    internal func exposureStarted() {
        DispatchQueue.main.async {
            self.deviceDelegate?.nextLevelWillChangeExposure(self)
        }
    }
    
    internal func exposureEnded() {
        guard let device = self._currentDevice,
            !device.isAdjustingFocus,
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
}

// MARK: - frame rate support

extension NextLevel {
    
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
            guard let device = self._currentDevice else {
                return
            }
            
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

// MARK: - video capture

extension NextLevel {
    
    /// Checks if video capture is supported by the hardware.
    public var isVideoCaptureSupported: Bool {
        get {
            var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                             AVCaptureDevice.DeviceType.builtInTelephotoCamera]
            if #available(iOS 11.0, *) {
                deviceTypes.append(.builtInDualCamera)
                if #available(iOS 11.1, *) {
                    deviceTypes.append(.builtInTrueDepthCamera)
                }
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
            return self.isVideoCaptureSupported && (FileManager.availableStorageSpaceInBytes() > NextLevelRequiredMinimumStorageSpaceInBytes)
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
            DispatchQueue.main.async {
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
                photoOutput.isHighResolutionCaptureEnabled = self.photoConfiguration.isHighResolutionEnabled
                
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
        if session.isVideoSetup == false {
            if let settings = self.videoConfiguration.avcaptureSettingsDictionary(sampleBuffer: sampleBuffer),
                let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                if !session.setupVideo(withSettings: settings, configuration: self.videoConfiguration, formatDescription: formatDescription) {
                    print("NextLevel, could not setup video session")
                }
            }
            DispatchQueue.main.async {
                self.videoDelegate?.nextLevel(self, didSetupVideoInSession: session)
            }
        }
        
        if self._recording && (session.isAudioSetup || self.captureMode == .videoWithoutAudio) && session.currentClipHasStarted {
            self.beginRecordingNewClipIfNecessary()
            
            let minTimeBetweenFrames = 0.004
            let sleepDuration = minTimeBetweenFrames - (CACurrentMediaTime() - self._lastVideoFrameTimeInterval)
            if sleepDuration > 0 {
                Thread.sleep(forTimeInterval: sleepDuration)
            }
            
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
            
            guard let device = self._currentDevice else {
                return
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
                    DispatchQueue.main.async {
                        self.videoDelegate?.nextLevel(self, didAppendVideoSampleBuffer: sampleBuffer, inSession: session)
                    }
                    self.checkSessionDuration()
                } else {
                    DispatchQueue.main.async {
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
            
        }
    }
    
    // Beta: handleVideoOutput(pixelBuffer:timestamp:session:) needs to be tested
    internal func handleVideoOutput(pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, session: NextLevelSession) {
        if session.isVideoSetup == false {
            if let settings = self.videoConfiguration.avcaptureSettingsDictionary(pixelBuffer: pixelBuffer) {
                if !session.setupVideo(withSettings: settings, configuration: self.videoConfiguration) {
                    print("NextLevel, could not setup video session")
                }
            }
            DispatchQueue.main.async {
                self.videoDelegate?.nextLevel(self, didSetupVideoInSession: session)
            }
        }

        if self._recording && (session.isAudioSetup || self.captureMode == .videoWithoutAudio) && session.currentClipHasStarted {
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
                if success {
                    DispatchQueue.main.async {
                        self.videoDelegate?.nextLevel(self, didAppendVideoPixelBuffer: pixelBuffer, timestamp: timestamp, inSession: session)
                    }
                    self.checkSessionDuration()
                } else {
                    DispatchQueue.main.async {
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
        if session.isAudioSetup == false {
            if let settings = self.audioConfiguration.avcaptureSettingsDictionary(sampleBuffer: sampleBuffer),
                let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                if !session.setupAudio(withSettings: settings, configuration: self.audioConfiguration, formatDescription: formatDescription) {
                    print("NextLevel, could not setup audio session")
                }
            }
            
            DispatchQueue.main.async {
                self.videoDelegate?.nextLevel(self, didSetupAudioInSession: session)
            }
        }
        
        if self._recording && session.isVideoSetup && session.currentClipHasStarted && session.currentClipHasVideo {
            self.beginRecordingNewClipIfNecessary()
            
            session.appendAudio(withSampleBuffer: sampleBuffer, completionHandler: { (success: Bool) -> Void in
                if success {
                    DispatchQueue.main.async {
                        self.videoDelegate?.nextLevel(self, didAppendAudioSampleBuffer: sampleBuffer, inSession: session)
                    }
                    self.checkSessionDuration()
                } else {
                    DispatchQueue.main.async {
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
                            DispatchQueue.main.async {
                                self.videoDelegate?.nextLevel(self, didCompleteClip: clip, inSession: session)
                            }
                        } else if let _ = error {
                            // TODO report error
                        }
                        DispatchQueue.main.async {
                            self.videoDelegate?.nextLevel(self, didCompleteSession: session)
                        }
                    })
                }
            }
        }
    }
}

// MARK: - rendering support
    
extension NextLevel {

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
        } else if let videoOutput = self._videoOutput,
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

// MARK: - AVCaptureFileOutputDelegate

extension NextLevel: AVCaptureFileOutputRecordingDelegate {
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    }

    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    }
    
}

// MARK: - AVCapturePhotoCaptureDelegate

extension NextLevel: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async {
            self.photoDelegate?.nextLevel(self, willCapturePhotoWithConfiguration: self.photoConfiguration)
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async {
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
            
            DispatchQueue.main.async {
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
            
            DispatchQueue.main.async {
                self.photoDelegate?.nextLevel(self, didProcessRawPhotoCaptureWith: photoDict, photoConfiguration: self.photoConfiguration)
            }
        }
    }
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        DispatchQueue.main.async {
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

// MARK: - KVO observers

extension NextLevel {
    
    internal func addKeyValueObservers(_ currentDevice: AVCaptureDevice) {
        
        self._observers.append(currentDevice.observe(\.isAdjustingFocus, options: [.new]) { [weak self] (object, change) in
            if object.isAdjustingFocus {
                self?.focusStarted()
            } else {
                self?.focusEnded()
            }
        })

        self._observers.append(currentDevice.observe(\.isAdjustingExposure, options: [.new]) { [weak self] (object, change) in
            if object.isAdjustingExposure {
                self?.exposureStarted()
            } else {
                self?.exposureEnded()
            }
        })

        self._observers.append(currentDevice.observe(\.isAdjustingWhiteBalance, options: [.new]) { [weak self] (object, change) in
            if object.isAdjustingWhiteBalance {
                self?.whiteBalanceStarted()
            } else {
                self?.whiteBalanceEnded()
            }
        })

        self._observers.append(currentDevice.observe(\.isFlashAvailable, options: [.new]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }

            DispatchQueue.main.async {
                strongSelf.flashDelegate?.nextLevelFlashAndTorchAvailabilityChanged(strongSelf)
            }
        })
        
        self._observers.append(currentDevice.observe(\.isTorchAvailable, options: [.new]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.flashDelegate?.nextLevelFlashAndTorchAvailabilityChanged(strongSelf)
            }
        })
        
        self._observers.append(currentDevice.observe(\.isFlashActive, options: [.new]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }
            
            // adjust white balance mode depending on the flash
            let whiteBalanceMode = strongSelf.whiteBalanceModeBestForExposureMode(exposureMode: object.exposureMode)
            let currentWhiteBalanceMode = object.whiteBalanceMode
            
            if whiteBalanceMode != currentWhiteBalanceMode {
                do {
                    try object.lockForConfiguration()
                    
                    strongSelf.adjustWhiteBalanceForExposureMode(exposureMode: object.exposureMode)
                    
                    object.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, failed to lock device for white balance exposure configuration")
                }
            }
            
            DispatchQueue.main.async {
                strongSelf.flashDelegate?.nextLevelFlashActiveChanged(strongSelf)
            }
        })
        
        self._observers.append(currentDevice.observe(\.isTorchActive, options: [.new]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.flashDelegate?.nextLevelTorchActiveChanged(strongSelf)
            }
        })

        self._observers.append(currentDevice.observe(\.lensPosition, options: [.new]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }
            
            if object.focusMode != .locked {
                DispatchQueue.main.async {
                    strongSelf.deviceDelegate?.nextLevel(strongSelf, didChangeLensPosition: object.lensPosition)
                }
            }
        })
        
        self._observers.append(currentDevice.observe(\.exposureDuration, options: [.new]) { [weak self] (object, change) in
            
            // TODO: add delegate callback
        })
        
        self._observers.append(currentDevice.observe(\.iso, options: [.new]) { [weak self] (object, change) in
            // TODO: add delegate callback
        })
        
        self._observers.append(currentDevice.observe(\.exposureTargetBias, options: [.new]) { [weak self] (object, change) in
            // TODO: add delegate callback
        })
        
        self._observers.append(currentDevice.observe(\.exposureTargetOffset, options: [.new]) { [weak self] (object, change) in
            // TODO: add delegate callback
        })
        
        self._observers.append(currentDevice.observe(\.deviceWhiteBalanceGains, options: [.new]) { [weak self] (object, change) in
            if object.exposureMode != .locked {
                // TODO: add delegate callback
            }
        })
        
        self._observers.append(currentDevice.observe(\.videoZoomFactor, options: [.new]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.videoDelegate?.nextLevel(strongSelf, didUpdateVideoZoomFactor: strongSelf.videoZoomFactor)
            }
        })
    }
    
    internal func removeKeyValueObservers(_ currentDevice: AVCaptureDevice) {
        for observer in self._observers {
            observer.invalidate()
        }
        self._observers.removeAll()
    }

}
