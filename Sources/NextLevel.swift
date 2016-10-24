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

public enum NextLevelDevicePosition: Int, CustomStringConvertible {
    case back = 0
    case front
    
    var uikitType: UIImagePickerControllerCameraDevice {
        switch self {
        case .back:
            return .rear
        case .front:
            return .front
        }
    }
    
    var avfoundationType: AVCaptureDevicePosition {
        switch self {
        case .back:
            return .back
        case .front:
            return .front
        }
    }
    
    public var description: String {
        get {
            switch self {
            case .back:
                return "Back"
            case .front:
                return "Front"
            }
        }
    }
}

public enum NextLevelDeviceType: Int, CustomStringConvertible {
    case microphone = 0
    case wideAngleCamera
    case telephotoCamera
    case duoCamera
    
    var avfoundationType: AVCaptureDeviceType {
        switch self {
        case .microphone:
            return .builtInMicrophone
        case .telephotoCamera:
            return .builtInTelephotoCamera
        case .wideAngleCamera:
            return .builtInWideAngleCamera
        case .duoCamera:
            return .builtInDuoCamera
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
            }
        }
    }
}

public enum NextLevelCaptureMode: Int, CustomStringConvertible {
    case video = 0
    case photo
    case audio
    
    public var description: String {
        get {
            switch self {
            case .video:
                return "Video"
            case .photo:
                return "Photo"
            case .audio:
                return "Audio"
            }
        }
    }
}

public enum NextLevelDeviceOrientation: Int, CustomStringConvertible {
    case portrait
    case portraitUpsideDown
    case landscapeRight
    case landscapeLeft
    
    var uikitType: UIDeviceOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        }
    }
    
    var avfoundationType: AVCaptureVideoOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeRight:
            return .landscapeRight
        case .landscapeLeft:
            return .landscapeLeft
        }
    }
    
    public var description: String {
        get {
            switch self {
            case .portrait:
                return "Portrait"
            case .portraitUpsideDown:
                return "PortraitUpsideDown"
            case .landscapeRight:
                return "LandscapeRight"
            case .landscapeLeft:
                return "LandscapeLeft"
            }
        }
    }
}

public enum NextLevelFocusMode: Int, CustomStringConvertible {
    case locked
    case autoFocus
    case continuousAutoFocus
    
    var avfoundationType: AVCaptureFocusMode {
        switch self {
        case .locked:
            return .locked
        case .autoFocus:
            return .autoFocus
        case .continuousAutoFocus:
            return .continuousAutoFocus
        }
    }

    public var description: String {
        get {
            switch self {
            case .locked:
                return "Locked"
            case .autoFocus:
                return "AutoFocus"
            case .continuousAutoFocus:
                return "ContinuousAutoFocus"
            }
        }
    }
}

public enum NextLevelExposureMode: Int, CustomStringConvertible {
    case locked
    case autoExpose
    case continuousAutoExposure
    case custom
    
    var avfoundationType: AVCaptureExposureMode {
        switch self {
        case .locked:
            return .locked
        case .autoExpose:
            return .autoExpose
        case .continuousAutoExposure:
            return .continuousAutoExposure
        case .custom:
            return .custom
        }
    }
    
    public var description: String {
        get {
            switch self {
            case .locked:
                return "Locked"
            case .autoExpose:
                return "AutoExpose"
            case .continuousAutoExposure:
                return "ContinuousAutoExposure"
            case .custom:
                return "Custom"
            }
        }
    }
}

public enum NextLevelFlashMode: Int, CustomStringConvertible {
    case off
    case on
    case auto

    var avfoundationType: AVCaptureFlashMode {
        switch self {
        case .off:
            return .off
        case .on:
            return .on
        case .auto:
            return .auto
        }
    }
    
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

public enum NextLevelTorchMode: Int, CustomStringConvertible {
    case off
    case on
    case auto
    
    var avfoundationType: AVCaptureTorchMode {
        switch self {
        case .off:
            return .off
        case .on:
            return .on
        case .auto:
            return .auto
        }
    }
    
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

public enum NextLevelVideoStabilizationMode: Int, CustomStringConvertible {
    case off = 0
    case standard
    case cinematic
    case auto
    
    var avfoundationType: AVCaptureVideoStabilizationMode {
        switch self {
        case .off:
            return .off
        case .standard:
            return .standard
        case .cinematic:
            return .cinematic
        case .auto:
            return .auto
        }
    }
    
    public var description: String {
        get {
            switch self {
            case .off:
                return "Off"
            case .standard:
                return "Standard"
            case .cinematic:
                return "Cinematic"
            case .auto:
                return "Auto"
            }
        }
    }
}

// MARK: - error types

public let NextLevelErrorDomain = "NextLevelErrorDomain"

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

// video keys

// photography keys
public let NextLevelPhotoMetadataKey = "NextLevelPhotoMetadataKey"
public let NextLevelPhotoJPEGKey = "NextLevelPhotoJPEGKey"
public let NextLevelPhotoRawImageKey = "NextLevelPhotoRawImageKey"
public let NextLevelPhotoThumbnailKey = "NextLevelPhotoThumbnailKey"

// MARK: - NextLevelDelegate
// all methods are called on the MainQueue except nextLevel:renderToCustomContextWithSampleBuffer:onQueue
public protocol NextLevelDelegate: NSObjectProtocol {

    // permission
    func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: String)
    
    // configuration
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration)
    
    // session
    func nextLevelSessionWillStart(_ nextLevel: NextLevel)
    func nextLevelSessionDidStart(_ nextLevel: NextLevel)
    func nextLevelSessionDidStop(_ nextLevel: NextLevel)
    
    // device, mode, orientation
    func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel)
    func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel)

    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel)
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel)
    
    // orientation
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation)
    
    // aperture
    func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect)
    
    // focus, exposure, white balance
    func nextLevelWillStartFocus(_ nextLevel: NextLevel)
    func nextLevelDidStopFocus(_  nextLevel: NextLevel)
    
    func nextLevelWillChangeExposure(_ nextLevel: NextLevel)
    func nextLevelDidChangeExposure(_ nextLevel: NextLevel)

    func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel)
    func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel)

    // torch, flash
    func nextLevelDidChangeFlashMode(_ nextLevel: NextLevel)
    func nextLevelDidChangeTorchMode(_ nextLevel: NextLevel)

    func nextLevelFlashActiveChanged(_ nextLevel: NextLevel)
    func nextLevelTorchActiveChanged(_ nextLevel: NextLevel)
    
    func nextLevelFlashAndTorchAvailabilityChanged(_ nextLevel: NextLevel)
    
    // zoom
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float)
    
    // preview
    func nextLevelWillStartPreview(_ nextLevel: NextLevel)
    func nextLevelDidStopPreview(_ nextLevel: NextLevel)
    
    // video processing
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer)
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue)

    // video recording session
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession)
    
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession)
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession)
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession)
    
    // video frame photo
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?)
    
    // photo
    func nextLevel(_ nextLevel: NextLevel, willCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, didCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration)
    
    func nextLevel(_ nextLevel: NextLevel, didProcessPhotoCaptureWith photoDict: [String: Any]?, photoConfiguration: NextLevelPhotoConfiguration)
    func nextLevel(_ nextLevel: NextLevel, didProcessRawPhotoCaptureWith photoDict: [String: Any]?, photoConfiguration: NextLevelPhotoConfiguration)
    
    func nextLevelDidCompletePhotoCapture(_ nextLevel: NextLevel)
    
}

// MARK: - constants

private let NextLevelCaptureSessionIdentifier = "engineering.NextLevel.captureSession"
private let NextLevelCaptureSessionSpecificKey = DispatchSpecificKey<NSObject>()
private let NextLevelRequiredMinimumStorageSpaceInBytes: UInt64 = 49999872 // ~47 MB

// MARK: - NextLevel state

public class NextLevel: NSObject {
    
    public weak var delegate: NextLevelDelegate?
    
    // preview
    
    public var previewLayer: AVCaptureVideoPreviewLayer
    
    // capture configuration
    
    public var videoConfiguration: NextLevelVideoConfiguration
    public var audioConfiguration: NextLevelAudioConfiguration
    public var photoConfiguration: NextLevelPhotoConfiguration
    
    // audio configuration
    
    public var automaticallyConfiguresApplicationAudioSession: Bool
    
    // camera configuration

    public func isCameraDeviceAvailable(cameraDevice: NextLevelDevicePosition) -> Bool {
        return UIImagePickerController .isCameraDeviceAvailable(cameraDevice.uikitType)
    }

    public var cameraMode: NextLevelCaptureMode {
        didSet {
            self.configureSession()
            self.configureSessionDevices()
        }
    }
        
    public var devicePosition: NextLevelDevicePosition {
        didSet {
            self.configureSessionDevices()
        }
    }
    
    public var automaticallyUpdatesDeviceOrientation: Bool
    
    public var deviceOrientation: NextLevelDeviceOrientation {
        didSet {
            self.automaticallyUpdatesDeviceOrientation = false
            self.updateVideoOrientation()
        }
    }
    
    // stabilization
    
    public var photoStabilizationEnabled: Bool
    
    public var videoStabilizationMode: NextLevelVideoStabilizationMode {
        didSet {
            self.beginConfiguration()
            self.updateVideoOutputSettings()
            self.commitConfiguration()
        }
    }
    
    // custom video rendering
    
    // property enables callbacks for rendering into a custom context
    public var isVideoCustomContextRenderingEnabled: Bool {
        get {
            return self.videoCustomContextRenderingEnabled
        }
        set {
            self.executeClosureSyncOnSessionQueueIfNecessary {
                self.videoCustomContextRenderingEnabled = newValue
                self.sessionVideoCustomContextImageBuffer = nil
            }
        }
    }
    
    // if you want to record the modified frame from isVideoCustomContextRenderingEnabled, set this property
    // if you do not want to record the modified frame, keep or set it to nil
    public var videoCustomContextImageBuffer: CVPixelBuffer? {
        get {
            return self.sessionVideoCustomContextImageBuffer
        }
        set {
            self.executeClosureSyncOnSessionQueueIfNecessary {
                self.sessionVideoCustomContextImageBuffer = newValue
            }
        }
    }
    
    // state
    
    public var isRecording: Bool {
        get {
            return self._recording
        }
    }
    
    public var session: NextLevelSession? {
        get {
            return self._recordingSession
        }
    }
    
    // MARK: - private instance vars
    
    internal var _captureSession: AVCaptureSession?
    internal var _sessionQueue: DispatchQueue
    internal var _sessionConfigurationCount: Int

    internal var _videoInput: AVCaptureDeviceInput?
    internal var _audioInput: AVCaptureDeviceInput?
    
    internal var _videoOutput: AVCaptureVideoDataOutput?
    internal var _audioOutput: AVCaptureAudioDataOutput?
    internal var _photoOutput: AVCapturePhotoOutput?
    
    internal var _currentDevice: AVCaptureDevice?
    internal var _requestedDevice: AVCaptureDevice?

    internal var _lastVideoFrame: CMSampleBuffer?
    internal var _lastAudioFrame: CMSampleBuffer?

    internal var _recording: Bool
    internal var _recordingSession: NextLevelSession?
    internal var _lastVideoFrameTimeInterval: TimeInterval
    
    internal var videoCustomContextRenderingEnabled: Bool
    internal var sessionVideoCustomContextImageBuffer: CVPixelBuffer?
    internal var cicontext: CIContext?
    
    // MARK: - singleton
    
    public static let sharedInstance: NextLevel = NextLevel()
    
    // MARK: - object lifecycle
    
    override init() {
        self.previewLayer = AVCaptureVideoPreviewLayer()
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self._sessionQueue = DispatchQueue(label: NextLevelCaptureSessionIdentifier)
        self._sessionQueue.setSpecific(key: NextLevelCaptureSessionSpecificKey, value: self._sessionQueue)
        self._sessionConfigurationCount = 0
        
        self.videoConfiguration = NextLevelVideoConfiguration()
        self.audioConfiguration = NextLevelAudioConfiguration()
        self.photoConfiguration = NextLevelPhotoConfiguration()
        
        self.cameraMode = .video
        
        self.photoStabilizationEnabled = false
        self.videoStabilizationMode = .auto
        self.videoCustomContextRenderingEnabled = false
        
        self._recording = false
        self._lastVideoFrameTimeInterval = 0
        
        self.automaticallyConfiguresApplicationAudioSession = true
        self.automaticallyUpdatesDeviceOrientation = false
        
        self.devicePosition = .back
        self.deviceOrientation = .portrait

        super.init()
        
        self.addApplicationObservers()
        self.addSessionObservers()
        self.addDeviceObservers()
    }
    
    deinit {
        self.delegate = nil

        self.removeApplicationObservers()
        self.removeSessionObservers()
        self.removeDeviceObservers()
        
        if let session = self._captureSession {
            self.beginConfiguration()
            self.removeInputs(session: session)
            self.removeOutputsIfNecessary(session: session)
            self.commitConfiguration()
        }

        self.previewLayer.session = nil
            
        self._currentDevice = nil
        self.cicontext = nil
        
        self._recordingSession = nil
        self._captureSession = nil
    }
}

// MARK: - authorization

extension NextLevel {
    
    public func authorizationStatus(forMediaType mediaType: String) -> NextLevelAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: mediaType)
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
    
    public func requestAuthorization(forMediaType mediaType: String) {
        AVCaptureDevice.requestAccess(forMediaType: mediaType) { (granted: Bool) in
            let status: NextLevelAuthorizationStatus = (granted == true) ? .authorized : .notAuthorized
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.delegate?.nextLevel(self, didUpdateAuthorizationStatus: status, forMediaType: mediaType)
            }
        }
    }
    
    internal func authorizationStatusForCurrentCameraMode() -> NextLevelAuthorizationStatus {
        switch self.cameraMode {
        case .audio:
            return self.authorizationStatus(forMediaType: AVMediaTypeAudio)
        case .video:
            let audioStatus = self.authorizationStatus(forMediaType: AVMediaTypeAudio)
            let videoStatus = self.authorizationStatus(forMediaType: AVMediaTypeVideo)
            return (audioStatus == .authorized && videoStatus == .authorized) ? .authorized : .notAuthorized
        case .photo:
            return self.authorizationStatus(forMediaType: AVMediaTypeVideo)
        }
    }
}

// MARK: - encoding configuration

extension NextLevel {
    
    public func start() throws {
        guard
            self._captureSession == nil
        else {
            throw NextLevelError.started
        }
        
        guard
            self.authorizationStatusForCurrentCameraMode() == .authorized
        else {
            throw NextLevelError.authorization
        }
        
        self._sessionQueue.async {
            // setup AV capture sesssion
            self._captureSession = AVCaptureSession()
            self._sessionConfigurationCount = 0

            // setup NL recording session
            self._recordingSession = NextLevelSession(queue: self._sessionQueue, queueKey: NextLevelCaptureSessionSpecificKey)
            
            if let session = self._captureSession {
                session.automaticallyConfiguresApplicationAudioSession = self.automaticallyConfiguresApplicationAudioSession
                
                self.beginConfiguration()
                self.previewLayer.session = session
                
                self.configureSession()
                self.configureSessionDevices()
                
                self.updateVideoOrientation()
                self.commitConfiguration()
                
                if session.isRunning == false {
                    session.startRunning()
                }
            }
        }
    }
    
    public func stop() {
        if let session = self._captureSession {
            self._sessionQueue.async {
                if session.isRunning == true {
                    session.stopRunning()
                }

                self.beginConfiguration()
                self.removeInputs(session: session)
                self.removeOutputsIfNecessary(session: session)
                self.commitConfiguration()
                
                self._recordingSession = nil
                self._captureSession = nil
            
            }
        }
    }
    
    // private session functions
    
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
        if self._captureSession != nil {
        
            self.beginConfiguration()
            
            var shouldConfigureVideo = false
            var shouldConfigureAudio = false
            switch self.cameraMode {
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
            }
            
            if shouldConfigureVideo == true {
                var captureDevice: AVCaptureDevice? = nil
                
                if let requestedDevice = self._requestedDevice {
                    captureDevice = requestedDevice
                } else if let videoDevice = AVCaptureDevice.primaryVideoDevice(forPosition: self.devicePosition.avfoundationType) {
                    captureDevice = videoDevice
                }
                
                if let device = captureDevice {
                    if device != self._currentDevice {
                        self.configureDevice(captureDevice: device, mediaType: AVMediaTypeVideo)
                        
                        let changingPosition = device.position != self._currentDevice?.position
                        if changingPosition == true {
                            self.executeClosureAsyncOnMainQueueIfNecessary {
                                self.delegate?.nextLevelDevicePositionWillChange(self)
                            }
                        }
                        
                        self.willChangeValue(forKey: "currentDevice")
                        self._currentDevice = device
                        self.didChangeValue(forKey: "currentDevice")
                        self._requestedDevice = nil
                        
                        if changingPosition == true {
                            self.executeClosureAsyncOnMainQueueIfNecessary {
                                self.delegate?.nextLevelDevicePositionDidChange(self)
                            }
                        }
                    }
                }
            }

            if shouldConfigureAudio == true {
                if let audioDevice = AVCaptureDevice.audioDevice() {
                    self.configureDevice(captureDevice: audioDevice, mediaType: AVMediaTypeAudio)
                }
            }
            
            self.commitConfiguration()
            
            if shouldConfigureVideo == true {
                self.delegate?.nextLevel(self, didUpdateVideoConfiguration: self.videoConfiguration)
            }
            
            if shouldConfigureAudio == true {
                self.delegate?.nextLevel(self, didUpdateAudioConfiguration: self.audioConfiguration)
            }
        }
    }
    
    internal func configureSession() {
        if let session = self._captureSession {
            self.beginConfiguration()
        
            // setup preset and mode
            
            self.removeOutputsIfNecessary(session: session)
            
            switch self.cameraMode {
            case .video:
                if session.sessionPreset != self.videoConfiguration.preset {
                    if session.canSetSessionPreset(self.videoConfiguration.preset) {
                        session.sessionPreset = self.videoConfiguration.preset
                    } else {
                        print("NextLevel, could not set preset on session")
                    }
                }

                let _ = self.addAudioOuput()
                let _ = self.addVideoOutput()
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
                break
            case .audio:
                let _ = self.addAudioOuput()
                break
            }
            
            self.commitConfiguration()
        }
    }
    
    // inputs
    
    private func configureDevice(captureDevice: AVCaptureDevice, mediaType: String) {
        
        if let session = self._captureSession,
            let currentDeviceInput = AVCaptureDeviceInput.deviceInput(withMediaType: mediaType, captureSession: session) {
            if currentDeviceInput.device == captureDevice {
                return
            }
        }
        
        if mediaType == AVMediaTypeVideo {
            do {
                try captureDevice.lockForConfiguration()
                
                if captureDevice.isSmoothAutoFocusSupported {
                    captureDevice.isSmoothAutoFocusEnabled = true
                }
                
                captureDevice.isSubjectAreaChangeMonitoringEnabled = true
                
                if captureDevice.isLowLightBoostSupported {
                    captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                captureDevice.unlockForConfiguration()
            }
            catch {
                print("NextLevel, flashMode failed to lock device for configuration")
            }
        }
        
        if let session = self._captureSession {
            if let currentDeviceInput = AVCaptureDeviceInput.deviceInput(withMediaType: mediaType, captureSession: session) {
                session.removeInput(currentDeviceInput)
                if currentDeviceInput.device.hasMediaType(AVMediaTypeVideo) {
                    self.removeKeyValueObservers()
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
                
                if input.device.hasMediaType(AVMediaTypeVideo) {
                    self.addKeyValueObservers()
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
        for input in session.inputs as! [AVCaptureDeviceInput] {
            session.removeInput(input)
            if input.device.hasMediaType(AVMediaTypeVideo) {
                self.removeKeyValueObservers()
            }
        }
        self._videoInput = nil
        self._audioInput = nil
    }

    // outputs, only call within configuration lock
    
    private func addVideoOutput() -> Bool {
        
        if self._videoOutput == nil {
            self._videoOutput = AVCaptureVideoDataOutput()
            self._videoOutput?.alwaysDiscardsLateVideoFrames = false
            
            var videoSettings = [String(kCVPixelBufferPixelFormatTypeKey):Int(kCVPixelFormatType_32BGRA)]
            if let formatTypes = self._videoOutput?.availableVideoCVPixelFormatTypes as? [Int] {
                var supportsFullRange = false
                var supportsVideoRange = false
                for format: Int in formatTypes {
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
        print("NextLevel, couldn't add audio output to session")
        return false
        
    }
    
    internal func removeOutputsIfNecessary(session: AVCaptureSession) {
        
        switch self.cameraMode {
        case .video:
            break
        case .photo:
            if let audioOutput = self._audioOutput {
                if session.outputs.contains(where: { (audioOutput) -> Bool in
                    return true
                }) {
                    session.removeOutput(audioOutput)
                    self._audioOutput = nil
                }
            }
            break
        case .audio:
            if let videoOutput = self._videoOutput {
                if session.outputs.contains(where: { (videoOutput) -> Bool in
                    return true
                }) {
                    session.removeOutput(videoOutput)
                    self._videoOutput = nil
                }
            }
            break
        }
        
    }
    
}

// MARK: - current capture mode and device state

extension NextLevel {
    
    // preview
    
    public func freezePreview() {
        if let previewConnection = self.previewLayer.connection {
            previewConnection.isEnabled = false
        }
    }
    
    public func unfreezePreview() {
        if let previewConnection = self.previewLayer.connection {
            previewConnection.isEnabled = true
        }
    }
    
    // flash and torch
    
    public var isFlashAvailable: Bool {
        if let device: AVCaptureDevice = self._currentDevice {
            return device.hasFlash
        }
        return false
    }
    
    public var flashMode: NextLevelFlashMode {
        get {
            return self.photoConfiguration.flashMode.flashModeNextLevelType()
        }
        set {
            if let device: AVCaptureDevice = self._currentDevice {
                guard
                    device.hasFlash
                else {
                    return
                }
                
                do {
                    try device.lockForConfiguration()
                    
                    if let output = self._photoOutput {
                        if self.photoConfiguration.flashMode != newValue.avfoundationType {
                            let modes = output.supportedFlashModes
                            let numberMode: NSNumber = NSNumber(integerLiteral: Int(newValue.avfoundationType.rawValue))
                            if modes.contains(numberMode) {
                                self.photoConfiguration.flashMode = newValue.avfoundationType
                            }
                        }
                    }
                        
                    device.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, flashMode failed to lock device for configuration")
                }
            }
        }
    }
    
    public var isTorchAvailable: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.hasTorch
            }
            return false
        }
    }
    
    public var torchMode: NextLevelTorchMode {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.torchModeNextLevelType()
            }
            return .off
        }
        set {
            if let device: AVCaptureDevice = self._currentDevice {
                guard
                    device.torchMode != newValue.avfoundationType,
                    device.hasTorch
                else {
                    return
                }
                
                do {
                    try device.lockForConfiguration()
                    
                    if device.isTorchModeSupported(newValue.avfoundationType) {
                        device.torchMode = newValue.avfoundationType
                    }
                    
                    device.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, flashMode failed to lock device for configuration")
                }
            }
        }
    }
    
    // focus, exposure, and white balance
    // note: focus and exposure modes change when adjusting on point
    
    public var isFocusPointOfInterestSupported: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isFocusPointOfInterestSupported
            }
            return false
        }
    }
    
    public var isFocusLockSupported: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isFocusModeSupported(.locked)
            }
            return false
        }
    }
    
    public var isAdjustingFocus: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isAdjustingFocus
            }
            return false
        }
    }
    
    public var focusMode: NextLevelFocusMode {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.focusModeNextLevelType()
            }
            return .locked
        }
        set {
            if let device: AVCaptureDevice = self._currentDevice {
                guard
                    device.focusMode != newValue.avfoundationType,
                    device.isFocusModeSupported(newValue.avfoundationType)
                else {
                    return
                }
            
                do {
                    try device.lockForConfiguration()
                    
                    device.focusMode = newValue.avfoundationType
                    
                    device.unlockForConfiguration()
                } catch {
                    print("NextLevel, focusMode failed to lock device for configuration")
                }
            }
        }
    }
    
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
                
                let focusMode: AVCaptureFocusMode = .autoFocus // .continuousAutoFocus
                let exposureMode: AVCaptureExposureMode = .continuousAutoExposure
                let whiteBalanceMode: AVCaptureWhiteBalanceMode = .continuousAutoWhiteBalance
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = adjustedPoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = adjustedPoint
                    device.exposureMode = exposureMode
                }
                
                if device.isWhiteBalanceModeSupported(whiteBalanceMode) {
                    device.focusPointOfInterest = adjustedPoint
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
    
    public func focusAtAdjustedPointOfInterest(adjustedPoint: CGPoint) {
        if let device: AVCaptureDevice = self._currentDevice {
            guard
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
    }
    
    // exposure
    
    public var isExposureLockSupported: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isExposureModeSupported(.locked)
            }
            return false
        }
    }
    
    public var isAdjustingExposure: Bool {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.isAdjustingExposure
            }
            return false
        }
    }
    
    public var exposureMode: NextLevelExposureMode {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return device.exposureModeNextLevelType()
            }
            return .locked
        }
        set {
            if let device: AVCaptureDevice = self._currentDevice {
                guard
                    device.exposureMode != newValue.avfoundationType,
                    device.isExposureModeSupported(exposureMode.avfoundationType)
                else {
                    return
                }
                
                do {
                    try device.lockForConfiguration()
                    
                    device.exposureMode = exposureMode.avfoundationType
                    self.adjustWhiteBalanceForExposureMode(exposureMode: exposureMode.avfoundationType)
                    
                    device.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, exposeAtAdjustedPointOfInterest failed to lock device for configuration")
                }
            }
        }
    }
    
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
    
    // focal length and principle point camera intrinsic parameters for OpenCV
    // see Hartley's Mutiple View Geometry, Chapter 6
    public func focalLengthAndPrinciplePoint(focalLengthX: inout Float, focalLengthY: inout Float, principlePointX: inout Float, principlePointY: inout Float) -> Bool {
        if let device: AVCaptureDevice = self._currentDevice,
            let formatDescription = device.activeFormat.formatDescription {
            let dimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, true, true)
            
            principlePointX = Float(dimensions.width) * 0.5
            principlePointY = Float(dimensions.height) * 0.5
            
            let horizontalFieldOfView = device.activeFormat.videoFieldOfView
            let verticalFieldOfView = (horizontalFieldOfView / principlePointX) * principlePointY
            
            focalLengthX = fabs( Float(dimensions.width) / (2.0 * tan(horizontalFieldOfView / 180.0 * Float(M_PI) / 2 )) )
            focalLengthY = fabs( Float(dimensions.height) / (2.0 * tan(verticalFieldOfView / 180.0 * Float(M_PI) / 2 )) )
            

            return true
        }
        return false
    }
    
    // private functions
    
    internal func adjustFocusExposureAndWhiteBalance() {
        if let device: AVCaptureDevice = self._currentDevice {
            guard
                !device.isAdjustingFocus,
                !device.isAdjustingExposure
            else {
                    return
            }
            
            self.delegate?.nextLevelWillStartFocus(self)
            
            self.focusAtAdjustedPointOfInterest(adjustedPoint: CGPoint(x: 0.5, y: 0.5))
        }
    }
    
    internal func adjustWhiteBalanceForExposureMode(exposureMode: AVCaptureExposureMode) {
        if let device = self._currentDevice {
            let whiteBalanceMode = self.whiteBalanceModeBestForExposureMode(exposureMode: exposureMode)
            if device.isWhiteBalanceModeSupported(whiteBalanceMode) {
                device.whiteBalanceMode = whiteBalanceMode
            }
        }
    }
    
    internal func whiteBalanceModeBestForExposureMode(exposureMode: AVCaptureExposureMode) -> AVCaptureWhiteBalanceMode {
        var whiteBalanceMode: AVCaptureWhiteBalanceMode = .continuousAutoWhiteBalance
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
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelWillStartFocus(self)
        }
    }
    
    internal func focusEnded() {
        if let device = self._currentDevice {
            guard
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
            
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.delegate?.nextLevelDidStopFocus(self)
            }
            
        }
    }
    
    internal func exposureStarted() {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelWillChangeExposure(self)
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

            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.delegate?.nextLevelDidChangeExposure(self)
            }
        }
    }
    
    internal func whiteBalanceStarted() {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelWillChangeWhiteBalance(self)
        }
    }
    
    internal func whiteBalanceEnded() {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelDidChangeWhiteBalance(self)
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
        
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelFlashActiveChanged(self)
        }
    }
    
    internal func torchActiveChanged() {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelTorchActiveChanged(self)
        }
    }
    
    internal func flashAndTorchAvailabilityChanged() {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelFlashAndTorchAvailabilityChanged(self)
        }
    }
    
    // mirroring
    
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
                    if let vc = videoOutput.connection(withMediaType: AVMediaTypeVideo) {
                        if vc.isVideoMirroringSupported {
                            vc.isVideoMirrored = false
                        }
                    }
                    if let pc = self.previewLayer.connection {
                        if pc.isVideoMirroringSupported {
                            pc.isVideoMirrored = false
                            pc.automaticallyAdjustsVideoMirroring = false
                        }
                    }
                    break
                case .on:
                    if let vc = videoOutput.connection(withMediaType: AVMediaTypeVideo) {
                        if vc.isVideoMirroringSupported {
                            vc.isVideoMirrored = true
                        }
                    }
                    if let pc = self.previewLayer.connection {
                        if pc.isVideoMirroringSupported {
                            pc.isVideoMirrored = true
                            pc.automaticallyAdjustsVideoMirroring = false
                        }
                    }
                    break
                case .auto:
                    if let vc = videoOutput.connection(withMediaType: AVMediaTypeVideo), let device = self._currentDevice {
                        if vc.isVideoMirroringSupported {
                            vc.isVideoMirrored = (device.position == .front)
                        }
                    }
                    if let pc = self.previewLayer.connection {
                        if pc.isVideoMirroringSupported {
                            pc.isVideoMirrored = true
                            pc.automaticallyAdjustsVideoMirroring = true
                        }
                    }
                    break
                }
            }
        }
    }
    
    // zoom
    
    public var videoZoomFactor: Float {
        get {
            if let device: AVCaptureDevice = self._currentDevice {
                return Float(device.videoZoomFactor)
            }
            return 1.0 // prefer 1.0 instead of using an optional
        }
        set {
            if let device: AVCaptureDevice = self._currentDevice {
                do {
                    try device.lockForConfiguration()
                    
                    let zoom: Float = max(1, min(newValue, Float(device.activeFormat.videoMaxZoomFactor)))
                    device.videoZoomFactor = CGFloat(zoom)
                    
                    device.unlockForConfiguration()
                }
                catch {
                    print("NextLevel, zoomFactor failed to lock device for configuration")
                }
            }
        }
    }
    
    internal func videoZoomFactorChanged() {
        self.delegate?.nextLevel(self, didUpdateVideoZoomFactor: self.videoZoomFactor)
    }
    
    // frame rate
    
    public var frameRate: CMTimeScale {
        get {
            var frameRate: CMTimeScale = 0
            if let session = self._captureSession {
                for input in session.inputs as! [AVCaptureDeviceInput] {
                    if input.device.hasMediaType(AVMediaTypeVideo) {
                        frameRate = input.device.activeVideoMaxFrameDuration.timescale
                        break
                    }
                }
            }
            return frameRate
        }
        set {
            if let device: AVCaptureDevice = self._currentDevice {
                guard
                    AVCaptureDevice.isCaptureDeviceFormat(inRange: device.activeFormat, frameRate: newValue)
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
                    print("NextLevel, flashMode failed to lock device for configuration")
                }
                
            }
        }
    }
    
    // device switch
    
    public func flipCaptureDevicePosition() {
        if self.devicePosition == .back {
            self.devicePosition = .front
        } else {
            self.devicePosition = .back
        }
    }
    
    public func changeCaptureDeviceIfAvailable(captureDevice: NextLevelDeviceType) throws {
        let deviceForUse = AVCaptureDevice.captureDevice(withType: captureDevice.avfoundationType, forPosition: .back)
        if deviceForUse == nil {
            throw NextLevelError.deviceNotAvailable
        } else {
            self._requestedDevice = deviceForUse
            self.configureSessionDevices()
        }
    }
    
    internal func updateVideoOrientation() {
        if let session = self._recordingSession {
            if session.currentClipHasAudio == false && session.currentClipHasVideo == false {
                session.reset()
            }
        }
        
        let currentOrientation = AVCaptureVideoOrientation.avorientationFromUIDeviceOrientation(UIDevice.current.orientation)
    
        if let previewConnection = self.previewLayer.connection {
            if previewConnection.isVideoOrientationSupported {
                previewConnection.videoOrientation = currentOrientation
            }
        }
            
        if let videoOutput = self._videoOutput, let videoConnection = videoOutput.connection(withMediaType: AVMediaTypeVideo) {
            if videoConnection.isVideoOrientationSupported {
                videoConnection.videoOrientation = currentOrientation
            }
        }
        
        if let photoOutput = self._photoOutput, let photoConnection = photoOutput.connection(withMediaType: AVMediaTypeVideo) {
            if photoConnection.isVideoOrientationSupported {
                photoConnection.videoOrientation = currentOrientation
            }
        }
        
        self.delegate?.nextLevel(self, didChangeDeviceOrientation: currentOrientation.deviceOrientationNextLevelType())
    }
    
    internal func updateVideoOutputSettings() {
        if let videoOutput = self._videoOutput {
            if let videoConnection = videoOutput.connection(withMediaType: AVMediaTypeVideo) {
                if videoConnection.isVideoStabilizationSupported {
                    videoConnection.preferredVideoStabilizationMode = .standard
                }
            }
        }
    }
}

// MARK: - video capture

extension NextLevel {
    
    // properties
    
    // use pause/resume if a session is in progress, end finalizes that recording session
    
    public var supportsVideoCapture: Bool {
        get {
            let deviceTypes: [AVCaptureDeviceType] = [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInDuoCamera]
            if let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaTypeVideo, position: .unspecified) {
                return discoverySession.devices.count > 0
            } else {
                return false
            }
        }
    }

    public var canCaptureVideo: Bool {
        get {
            return self.supportsVideoCapture && (NextLevel.availableStorageSpaceInBytes() > NextLevelRequiredMinimumStorageSpaceInBytes)
        }
    }
    
    // functions
    
    public func capturePhotoFromVideo() {
        
        self._sessionQueue.async {
            
            var photoDict: [String: Any]? = nil
            
            if let _ = self._recordingSession,
                let videoFrame = self._lastVideoFrame {
            
                let tiffMetadataAdditions = NextLevel.tiffMetadata()
                
                // append tiff metadata to buffer for proagation
                if let tiffDict: CFDictionary = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, kCGImagePropertyTIFFDictionary, kCMAttachmentMode_ShouldPropagate) {
                    let tiffNSDict = tiffDict as NSDictionary
                    var metaDict: [String: Any] = [:]
                    for (key, value) in tiffMetadataAdditions {
                        metaDict.updateValue(value as AnyObject, forKey: key)
                    }
                    for (key, value) in tiffNSDict {
                        let keyString = key as! String
                        metaDict.updateValue(value as AnyObject, forKey: keyString)
                    }
                    CMSetAttachment(videoFrame, kCGImagePropertyTIFFDictionary, metaDict as CFTypeRef?, kCMAttachmentMode_ShouldPropagate)
                } else {
                    CMSetAttachment(videoFrame, kCGImagePropertyTIFFDictionary, tiffMetadataAdditions as CFTypeRef?, kCMAttachmentMode_ShouldPropagate)
                }
                
                // add exif metadata
                if let metadata = NextLevel.metadataFromSampleBuffer(sampleBuffer: videoFrame) {
                    if photoDict == nil {
                        photoDict = [:]
                    }
                    photoDict?[NextLevelPhotoMetadataKey] = metadata
                }
                
                if let photo = self.uiimageFromSampleBuffer(sampleBuffer: videoFrame) {
                    
                    // add JPEG, thumbnail
                    let imageData = UIImageJPEGRepresentation(photo, 0)
                    if let data = imageData {
                        if photoDict == nil {
                            photoDict = [:]
                        }
                        photoDict?[NextLevelPhotoJPEGKey] = data
                    }
                    
                    // add explicit thumbnail
                    //let thumbnailData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: previewBuffer, previewPhotoSampleBuffer: nil)
                    //if let tData = thumbnailData {
                    //    photoDict[NextLevelPhotoThumbnailKey] = tData
                    //}
                }
            }

            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.delegate?.nextLevel(self, didCompletePhotoCaptureFromVideoFrame: photoDict)
            }

        }
        
    }
    
    public func record() {
        self.executeClosureSyncOnSessionQueueIfNecessary {
            self._recording = true
            if let _ = self._recordingSession {
                self.beginRecordingNewClipIfNecessary()
            }
        }
    }
    
    public func pause() {
        self.pause(withCompletionHandler: nil)
    }
    
    public func pause(withCompletionHandler completionHandler: (() -> Void)?) {
        self._recording = false
        
        self.executeClosureAsyncOnSessionQueueIfNecessary {
            if let session = self._recordingSession {
                if session.clipStarted {
                    
                    session.endClip(completionHandler: { (sessionClip: NextLevelClip?, error: Error?) in
                        if let clip = sessionClip {
                            self.delegate?.nextLevel(self, didCompleteClip: clip, inSession: session)
                            if let handler = completionHandler {
                                handler()
                            }
                        } else if let _ = error {
                            // TODO, report error
                            if let handler = completionHandler {
                                handler()
                            }
                        }
                    })
                    
                } else {
                    if let handler = completionHandler {
                        self.executeClosureAsyncOnMainQueueIfNecessary(withClosure: handler)
                    }
                }
            } else {
                if let handler = completionHandler {
                    self.executeClosureAsyncOnMainQueueIfNecessary(withClosure: handler)
                }
            }
        }
    }
    
    // private
    
    internal func beginRecordingNewClipIfNecessary() {
        if let session = self._recordingSession {
            if session.isClipReady == false {
                session.beginClip()
                self.executeClosureAsyncOnMainQueueIfNecessary {
                    self.delegate?.nextLevel(self, didStartClipInSession: session)
                }
            }
        }
    }
    
}

// MARK: - photo capture

extension NextLevel {
    
    public var canCapturePhoto: Bool {
        get {
            let canCapturePhoto: Bool = (self._captureSession?.isRunning == true)
            return canCapturePhoto && NextLevel.availableStorageSpaceInBytes() > NextLevelRequiredMinimumStorageSpaceInBytes
        }
    }
    
    public func capturePhoto() {
        if let photoOutput = self._photoOutput, let _ = photoOutput.connection(withMediaType: AVMediaTypeVideo) {
            if let formatDictionary = self.photoConfiguration.avcaptureDictionary() {
                let photoSettings = AVCapturePhotoSettings(format: formatDictionary)
                photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
        }
    }
    
}

// MARK: - NextLevelSession and sample buffer processing

extension NextLevel {
    
    // sample buffer processing
    
    internal func uiimageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        var sampleBufferImage: UIImage? = nil
        
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            
            // TODO better expose this or a sharegroup for custom context rendering support
            if self.cicontext == nil {
                self.cicontext = CIContext(eaglContext: EAGLContext(api: .openGLES2))
            }
            
            if let context = self.cicontext {
                let ciimage = CIImage(cvPixelBuffer: pixelBuffer)
                if let cgimage = context.createCGImage(ciimage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))) {
                    sampleBufferImage = UIImage(cgImage: cgimage)
                }
            }
            
        }
        
        return sampleBufferImage
    }
    
    internal func handleVideoOutput(sampleBuffer: CMSampleBuffer, session: NextLevelSession) {
        if let session = self._recordingSession {
        
            if session.isVideoReady == false {
                if let settings = self.videoConfiguration.avcaptureSettingsDictionary(withSampleBuffer: sampleBuffer),
                        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                    if !session.setupVideo(withSettings: settings, configuration: self.videoConfiguration, formatDescription: formatDescription) {
                        print("NextLevel, could not setup video session")
                    }
                }
                
                self.executeClosureAsyncOnMainQueueIfNecessary {
                    self.delegate?.nextLevel(self, didSetupVideoInSession: session)
                }
            }
            
            if self._recording && session.isAudioReady && session.clipStarted {
                self.beginRecordingNewClipIfNecessary()
                    
                let minTimeBetweenFrames = 0.004
                let sleepDuration = minTimeBetweenFrames - (CACurrentMediaTime() - self._lastVideoFrameTimeInterval)
                if sleepDuration > 0 {
                    Thread.sleep(forTimeInterval: sleepDuration)
                }
                
                if let device = self._currentDevice {
                    
                    // check with the client to setup/maintain external render contexts
                    let imageBuffer = self.isVideoCustomContextRenderingEnabled == true ? CMSampleBufferGetImageBuffer(sampleBuffer) : nil

                    if let bufferRef = imageBuffer {
                        if CVPixelBufferLockBaseAddress(bufferRef, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0))) == kCVReturnSuccess {
                            // only called from captureQueue
                            self.delegate?.nextLevel(self, renderToCustomContextWithImageBuffer: bufferRef, onQueue: self._sessionQueue)
                        } else {
                            self.sessionVideoCustomContextImageBuffer = nil
                        }
                    }
                    
                    let minFrameDuration = device.activeVideoMinFrameDuration
                    session.appendVideo(withSampleBuffer: sampleBuffer, imageBuffer: self.sessionVideoCustomContextImageBuffer, minFrameDuration: minFrameDuration, completionHandler: { (success: Bool) -> Void in
                        // cleanup client rendering context
                        if self.isVideoCustomContextRenderingEnabled {
                            if let bufferRef = imageBuffer {
                                CVPixelBufferUnlockBaseAddress(bufferRef, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            }
                        }
                        
                        // process frame
                        self._lastVideoFrameTimeInterval = CACurrentMediaTime()
                        if success == true {
                            self.executeClosureAsyncOnMainQueueIfNecessary {
                                self.delegate?.nextLevel(self, didAppendVideoSampleBuffer: sampleBuffer, inSession: session)
                            }
                            self.checkSessionDuration()
                        } else {
                            self.executeClosureAsyncOnMainQueueIfNecessary {
                                self.delegate?.nextLevel(self, didSkipVideoSampleBuffer: sampleBuffer, inSession: session)
                            }
                        }
                    })

                    if session.currentClipHasVideo == false && session.currentClipHasAudio == false {
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

        } // self.recordingSession
    }
    
    internal func handleAudioOutput(sampleBuffer: CMSampleBuffer, session: NextLevelSession) {
        if let session = self._recordingSession {
            
            if session.isAudioReady == false {
                if let settings = self.audioConfiguration.avcaptureSettingsDictionary(withSampleBuffer: sampleBuffer),
                        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                    if !session.setupAudio(withSettings: settings, configuration: self.audioConfiguration, formatDescription: formatDescription) {
                        print("NextLevel, could not setup audio session")
                    }
                }
                
                self.executeClosureAsyncOnMainQueueIfNecessary {
                    self.delegate?.nextLevel(self, didSetupAudioInSession: session)
                }
            }
            
            if self._recording && session.isVideoReady && session.clipStarted && session.currentClipHasVideo {
                self.beginRecordingNewClipIfNecessary()
                
                session.appendAudio(withSampleBuffer: sampleBuffer, completionHandler: { (success: Bool) -> Void in
                    if success {
                        self.executeClosureAsyncOnMainQueueIfNecessary {
                            self.delegate?.nextLevel(self, didAppendAudioSampleBuffer: sampleBuffer, inSession: session)
                        }
                        self.checkSessionDuration()
                    } else {
                        self.executeClosureAsyncOnMainQueueIfNecessary {
                            self.delegate?.nextLevel(self, didSkipAudioSampleBuffer: sampleBuffer, inSession: session)
                        }
                    }
                })
            }
        }
    }
    
    private func checkSessionDuration() {
        if let session = self._recordingSession,
            let maxRecordingDuration = self.videoConfiguration.maximumCaptureDuration {
            let currentDuration = session.duration
            if maxRecordingDuration.isValid && currentDuration >= maxRecordingDuration {
                self._recording = false
                
                // already on session queue, adding to next cycle
                self.executeClosureAsyncOnSessionQueueIfNecessary {
                    session.endClip(completionHandler: { (sessionClip: NextLevelClip?, error: Error?) in
                        if let clip = sessionClip {
                            self.delegate?.nextLevel(self, didCompleteClip: clip, inSession: session)
                        } else if let _ = error {
                            // TODO report error
                        }
                        self.delegate?.nextLevel(self, didCompleteSession: session)
                    })
                }
            }
        }
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate

extension NextLevel: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if let videoOutput = self._videoOutput,
            let audioOutput = self._audioOutput {
            switch captureOutput {
            case videoOutput:
                self.executeClosureAsyncOnMainQueueIfNecessary {
                    self.delegate?.nextLevel(self, willProcessRawVideoSampleBuffer: sampleBuffer)
                }
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
    
    public func capture(_ captureOutput: AVCapturePhotoOutput, willCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevel(self, willCapturePhotoWithConfiguration: self.photoConfiguration)
        }
    }
    
    public func capture(_ captureOutput: AVCapturePhotoOutput, didCapturePhotoForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevel(self, didCapturePhotoWithConfiguration: self.photoConfiguration)
        }
    }
    
    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer {
            
            // output dictionary
            var photoDict: [String: Any] = [:]

            let tiffMetadataAdditions = NextLevel.tiffMetadata()

            // append tiff metadata to buffer for proagation
            if let tiffDict: CFDictionary = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, kCGImagePropertyTIFFDictionary, kCMAttachmentMode_ShouldPropagate) {
                let tiffNSDict = tiffDict as NSDictionary
                var metaDict: [String: Any] = [:]
                for (key, value) in tiffMetadataAdditions {
                    metaDict.updateValue(value as AnyObject, forKey: key)
                }
                for (key, value) in tiffNSDict {
                    let keyString = key as! String
                    metaDict.updateValue(value as AnyObject, forKey: keyString)
                }
                CMSetAttachment(sampleBuffer, kCGImagePropertyTIFFDictionary, metaDict as CFTypeRef?, kCMAttachmentMode_ShouldPropagate)
            } else {
                CMSetAttachment(sampleBuffer, kCGImagePropertyTIFFDictionary, tiffMetadataAdditions as CFTypeRef?, kCMAttachmentMode_ShouldPropagate)
            }
            
            // add exif metadata
            if let metadata = NextLevel.metadataFromSampleBuffer(sampleBuffer: sampleBuffer) {
                photoDict[NextLevelPhotoMetadataKey] = metadata
            }
            
            // add JPEG, thumbnail
            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer)
            if let data = imageData {
                photoDict[NextLevelPhotoJPEGKey] = data
            }

            // add explicit thumbnail
            //let thumbnailData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: previewBuffer, previewPhotoSampleBuffer: nil)
            //if let tData = thumbnailData {
            //    photoDict[NextLevelPhotoThumbnailKey] = tData
            //}
            
            self.executeClosureAsyncOnMainQueueIfNecessary {
                self.delegate?.nextLevel(self, didProcessPhotoCaptureWith: photoDict, photoConfiguration: self.photoConfiguration)
            }
        }
    }
    
    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingRawPhotoSampleBuffer rawSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let sampleBuffer = rawSampleBuffer, let previewBuffer = previewPhotoSampleBuffer {
            
            // output dictionary
            var photoDict: [String: Any] = [:]
            
            let tiffMetadataAdditions = NextLevel.tiffMetadata()
            
            // append tiff metadata to buffer for proagation
            if let tiffDict: CFDictionary = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, kCGImagePropertyTIFFDictionary, kCMAttachmentMode_ShouldPropagate) {
                let tiffNSDict = tiffDict as NSDictionary
                var metaDict: [String: Any] = [:]
                for (key, value) in tiffMetadataAdditions {
                    metaDict.updateValue(value as AnyObject, forKey: key)
                }
                for (key, value) in tiffNSDict {
                    let keyString = key as! String
                    metaDict.updateValue(value as AnyObject, forKey: keyString)
                }
                CMSetAttachment(sampleBuffer, kCGImagePropertyTIFFDictionary, metaDict as CFTypeRef?, kCMAttachmentMode_ShouldPropagate)
            } else {
                CMSetAttachment(sampleBuffer, kCGImagePropertyTIFFDictionary, tiffMetadataAdditions as CFTypeRef?, kCMAttachmentMode_ShouldPropagate)
            }
            
            // add exif metadata
            if let metadata = NextLevel.metadataFromSampleBuffer(sampleBuffer: sampleBuffer) {
                photoDict[NextLevelPhotoMetadataKey] = metadata
            }
            
            // add Raw + thumbnail
            let imageData = AVCapturePhotoOutput.dngPhotoDataRepresentation(forRawSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer)
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
                self.delegate?.nextLevel(self, didProcessPhotoCaptureWith: photoDict, photoConfiguration: self.photoConfiguration)
            }
        }
    }
    
    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelDidCompletePhotoCapture(self)
        }
    }
    
}

// MARK: - queues

extension NextLevel {
    
    internal func executeClosureAsyncOnMainQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }

    internal func executeClosureAsyncOnSessionQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: NextLevelCaptureSessionSpecificKey) == self._sessionQueue {
            closure()
        } else {
            self._sessionQueue.async(execute: closure)
        }
    }
    
    internal func executeClosureSyncOnSessionQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: NextLevelCaptureSessionSpecificKey) == self._sessionQueue {
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
    
    internal func handleApplicationWillEnterForeground(_ notification: Notification) {
        //self.sessionQueue.async {}
    }
    
    internal func handleApplicationDidEnterBackground(_ notification: Notification) {
        self._sessionQueue.async {
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
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleSessionInterruption(_:)), name: .AVCaptureSessionWasInterrupted, object: self._captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(NextLevel.handleSessionInterruptionEnded(_:)), name: .AVCaptureSessionInterruptionEnded, object: self._captureSession)
    }
    
    internal func removeSessionObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionDidStartRunning, object: self._captureSession)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionDidStopRunning, object: self._captureSession)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionRuntimeError, object: self._captureSession)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionWasInterrupted, object: self._captureSession)
        NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionInterruptionEnded, object: self._captureSession)
    }
    
    internal func handleSessionDidStartRunning(_ notification: Notification) {
        //self.performRecoveryCheckIfNecessary()
        // TODO
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelSessionDidStart(self)
        }
    }
        
    internal func handleSessionDidStopRunning(_ notification: Notification) {
        self.executeClosureAsyncOnMainQueueIfNecessary {
            self.delegate?.nextLevelSessionDidStop(self)
        }
    }
    
    internal func handleSessionRuntimeError(_ notification: Notification) {
        //handleSessionRuntimeError
        // TODO
    }
    
    internal func handleSessionInterruption(_ notification: Notification) {
        // TODO
    }
    
    internal func handleSessionInterruptionEnded(_ notification: Notification) {
        // TODO
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
    
    internal func deviceSubjectAreaDidChange(_ notification: NSNotification) {
        self.adjustFocusExposureAndWhiteBalance()
    }
    
    internal func deviceInputPortFormatDescriptionDidChange(_ notification: Notification) {
        if let session = self._captureSession {
            let inputPorts = session.inputs
            if let input = inputPorts?.first as? AVCaptureInputPort {
                if let formatDescription: CMFormatDescription = input.formatDescription {
                    let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription, true)
                    self.delegate?.nextLevel(self, didChangeCleanAperture: cleanAperture)
                }
            }
        }
    }

    internal func deviceOrientationDidChange(_ notification: NSNotification) {
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
    
    internal func addKeyValueObservers() {
        self.addObserver(self, forKeyPath: "currentDevice.adjustingFocus", options: [.new], context: &NextLevelFocusObserverContext)
        self.addObserver(self, forKeyPath: "currentDevice.adjustingExposure", options: [.new], context: &NextLevelExposureObserverContext)
        self.addObserver(self, forKeyPath: "currentDevice.adjustingWhiteBalance", options: [.new], context: &NextLevelWhiteBalanceObserverContext)
        self.addObserver(self, forKeyPath: "currentDevice.flashAvailable", options: [.new], context: &NextLevelFlashAvailabilityObserverContext)
        self.addObserver(self, forKeyPath: "currentDevice.torchAvailable", options: [.new], context: &NextLevelTorchAvailabilityObserverContext)
        self.addObserver(self, forKeyPath: "currentDevice.flashActive", options: [.new], context: &NextLevelFlashActiveObserverContext)
        self.addObserver(self, forKeyPath: "currentDevice.torchActive", options: [.new], context: &NextLevelTorchActiveObserverContext)
        self.addObserver(self, forKeyPath: "currentDevice.videoZoomFactor", options: [.new], context: &NextLevelVideoZoomFactorObserverContext)
    }
    
    internal func removeKeyValueObservers() {
        self.removeObserver(self, forKeyPath: "currentDevice.adjustingFocus")
        self.removeObserver(self, forKeyPath: "currentDevice.adjustingExposure")
        self.removeObserver(self, forKeyPath: "currentDevice.adjustingWhiteBalance")
        self.removeObserver(self, forKeyPath: "currentDevice.flashAvailable")
        self.removeObserver(self, forKeyPath: "currentDevice.torchAvailable")
        self.removeObserver(self, forKeyPath: "currentDevice.flashActive")
        self.removeObserver(self, forKeyPath: "currentDevice.torchActive")
        self.removeObserver(self, forKeyPath: "currentDevice.videoZoomFactor")
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &NextLevelFocusObserverContext {
            
            let isFocusing = (change?[.newKey] as! Bool)
            if isFocusing {
                self.focusStarted()
            } else {
                self.focusEnded()
            }
            
        } else if context == &NextLevelExposureObserverContext {
            
            let isChangingExposure = (change?[.newKey] as! Bool)
            if isChangingExposure {
                self.exposureStarted()
            } else {
                self.exposureEnded()
            }
            
        } else if context == &NextLevelWhiteBalanceObserverContext {
            
            let isChangingWhiteBalance = (change?[.newKey] as! Bool)
            if isChangingWhiteBalance {
                self.whiteBalanceStarted()
            } else {
                self.whiteBalanceEnded()
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
