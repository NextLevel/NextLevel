//
//  MixedRealityViewController.swift
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

import UIKit
import AVFoundation
import Photos
import ARKit
//import NextLevel

@available(iOS 11.0, *)
class MixedRealityViewController: UIViewController {

    // MARK: - UIViewController
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - properties
    
    internal var arConfig: ARWorldTrackingConfiguration?
    internal var arView: ARSCNView?
    internal var arSession: ARSession?
    
    internal var gestureView: UIView?
    internal var focusView: FocusIndicatorView?
    internal var controlDockView: UIView?
    
    internal var recordButton: UIImageView?
    internal var flipButton: UIButton?
    internal var flashButton: UIButton?
    internal var saveButton: UIButton?
    
    internal var longPressGestureRecognizer: UILongPressGestureRecognizer?
    internal var photoTapGestureRecognizer: UITapGestureRecognizer?
    internal var tapGestureRecognizer: UITapGestureRecognizer?
    internal var flipDoubleTapGestureRecognizer: UITapGestureRecognizer?
    
    internal var _panStartPoint: CGPoint = .zero
    internal var _panStartZoom: CGFloat = 0.0
    
    // MARK: - object lifecycle
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
    }
    
    // MARK: - view lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let screenBounds = UIScreen.main.bounds
        
        // preview
        self.arView = ARSCNView(frame: screenBounds)
        if let arView = self.arView {
            arView.delegate = self
            
            // setup the session delegate (your controller manages this instead of NextLevel)
            self.arSession = arView.session
            self.arSession?.delegate = self
            
            arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            arView.backgroundColor = UIColor.black
            arView.scene = SCNScene()
            arView.isPlaying = true
            arView.loops = true
            
            arView.debugOptions = ARSCNDebugOptions.showFeaturePoints
            
            NextLevel.shared.previewLayer.frame = arView.frame
            self.view.addSubview(arView)
        }
        
        //self.focusView = FocusIndicatorView(frame: .zero)
        
        // buttons
        self.recordButton = UIImageView(image: UIImage(named: "record_button"))
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGestureRecognizer(_:)))
        if let recordButton = self.recordButton,
            let longPressGestureRecognizer = self.longPressGestureRecognizer {
            recordButton.isUserInteractionEnabled = true
            recordButton.sizeToFit()
            
            longPressGestureRecognizer.delegate = self
            longPressGestureRecognizer.minimumPressDuration = 0.05
            longPressGestureRecognizer.allowableMovement = 10.0
            recordButton.addGestureRecognizer(longPressGestureRecognizer)
        }
        
        self.flipButton = UIButton(type: .custom)
        if let flipButton = self.flipButton {
            flipButton.setImage(UIImage(named: "flip_button"), for: .normal)
            flipButton.sizeToFit()
            flipButton.addTarget(self, action: #selector(handleFlipButton(_:)), for: .touchUpInside)
        }
        
        self.saveButton = UIButton(type: .custom)
        if let saveButton = self.saveButton {
            saveButton.setImage(UIImage(named: "save_button"), for: .normal)
            saveButton.sizeToFit()
            saveButton.addTarget(self, action: #selector(handleSaveButton(_:)), for: .touchUpInside)
        }
        
        // capture control "dock"
        let controlDockHeight = screenBounds.height * 0.2
        self.controlDockView = UIView(frame: CGRect(x: 0, y: screenBounds.height - controlDockHeight, width: screenBounds.width, height: controlDockHeight))
        if let controlDockView = self.controlDockView {
            controlDockView.backgroundColor = UIColor.clear
            controlDockView.autoresizingMask = [.flexibleTopMargin]
            self.view.addSubview(controlDockView)
            
            if let recordButton = self.recordButton {
                recordButton.center = CGPoint(x: controlDockView.bounds.midX, y: controlDockView.bounds.midY)
                controlDockView.addSubview(recordButton)
            }
            
            if let flipButton = self.flipButton, let recordButton = self.recordButton {
                flipButton.center = CGPoint(x: recordButton.center.x + controlDockView.bounds.width * 0.25 + flipButton.bounds.width * 0.5, y: recordButton.center.y)
                //controlDockView.addSubview(flipButton)
            }
            
            if let saveButton = self.saveButton, let recordButton = self.recordButton {
                saveButton.center = CGPoint(x: controlDockView.bounds.width * 0.25 - saveButton.bounds.width * 0.5, y: recordButton.center.y)
                controlDockView.addSubview(saveButton)
            }
        }
        
        // gestures
        self.gestureView = UIView(frame: screenBounds)
        if let gestureView = self.gestureView, let controlDockView = self.controlDockView {
            gestureView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            gestureView.frame.size.height -= controlDockView.frame.height
            gestureView.backgroundColor = .clear
            self.view.addSubview(gestureView)
            
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
            if let tapGestureRecognizer = self.tapGestureRecognizer {
                tapGestureRecognizer.delegate = self
                tapGestureRecognizer.numberOfTapsRequired = 1
                gestureView.addGestureRecognizer(tapGestureRecognizer)
            }
        }
        
        self.arConfig = ARWorldTrackingConfiguration()
        self.arConfig?.providesAudioData = true
        self.arConfig?.planeDetection = .horizontal
        
        // Configure NextLevel by modifying the configuration ivars
        let nextLevel = NextLevel.shared
        nextLevel.delegate = self
        nextLevel.deviceDelegate = self
        nextLevel.videoDelegate = self
        
        nextLevel.captureMode = .arKit
        nextLevel.videoStabilizationMode = .off
        
        // video configuration
        nextLevel.videoConfiguration.bitRate = 2000000
        nextLevel.videoConfiguration.scalingMode = AVVideoScalingModeResizeAspectFill
        nextLevel.videoConfiguration.profileLevel = AVVideoProfileLevelH264HighAutoLevel

        // audio configuration
        nextLevel.audioConfiguration.bitRate = 96000
        
        // ar configuration
        nextLevel.arConfiguration?.config = self.arConfig
        nextLevel.arConfiguration?.session = self.arSession
        nextLevel.arConfiguration?.runOptions = [.resetTracking, .removeExistingAnchors]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if NextLevel.shared.isRunning == false {
            let nextLevel = NextLevel.shared
            if nextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
                nextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
                do {
                    try nextLevel.start()
                } catch {
                    print("NextLevel, failed to start camera session")
                }
            } else {
                nextLevel.requestAuthorization(forMediaType: AVMediaType.video)
                nextLevel.requestAuthorization(forMediaType: AVMediaType.audio)
            }
        } else {
            // handleCameraDidStart
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if NextLevel.shared.isRunning {
            NextLevel.shared.stop()
            NextLevel.shared.videoZoomFactor = 1.0
        }
    }
    
}

// MARK: - library

@available(iOS 11.0, *)
extension MixedRealityViewController {
    
    internal func albumAssetCollection(withTitle title: String) -> PHAssetCollection? {
        let predicate = NSPredicate(format: "localizedTitle = %@", title)
        let options = PHFetchOptions()
        options.predicate = predicate
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        if result.count > 0 {
            return result.firstObject
        }
        return nil
    }
    
    internal func saveVideo(withURL url: URL) {
        PHPhotoLibrary.shared().performChanges({
            let albumAssetCollection = self.albumAssetCollection(withTitle: NextLevelAlbumTitle)
            if albumAssetCollection == nil {
                let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: NextLevelAlbumTitle)
                let _ = changeRequest.placeholderForCreatedAssetCollection
            }}, completionHandler: { (success1: Bool, error1: Error?) in
                if let albumAssetCollection = self.albumAssetCollection(withTitle: NextLevelAlbumTitle) {
                    PHPhotoLibrary.shared().performChanges({
                        if let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) {
                            let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                            let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                            assetCollectionChangeRequest?.addAssets(enumeration)
                        }
                    }, completionHandler: { (success2: Bool, error2: Error?) in
                        if success2 == true {
                            // prompt that the video has been saved
                            let alertController = UIAlertController(title: "Video Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            // prompt that the video has been saved
                            let alertController = UIAlertController(title: "Oops!", message: "Something failed!", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                    })
                }
        })
    }
    
}

// MARK: - capture

@available(iOS 11.0, *)
extension MixedRealityViewController {
    
    internal func startCapture() {
        self.photoTapGestureRecognizer?.isEnabled = false
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            self.recordButton?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { (completed: Bool) in
        }
        NextLevel.shared.record()
    }
    
    internal func pauseCapture() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            self.recordButton?.transform = .identity
        }) { (completed: Bool) in
        }
        NextLevel.shared.pause()
    }
    
    internal func endCapture() {
        self.photoTapGestureRecognizer?.isEnabled = true
        
        if let session = NextLevel.shared.session {
            
            if session.clips.count > 1 {
                NextLevel.shared.session?.mergeClips(usingPreset: AVAssetExportPresetHighestQuality, completionHandler: { (url: URL?, error: Error?) in
                    if let videoUrl = url {
                        self.saveVideo(withURL: videoUrl)
                    } else if let _ = error {
                        print("failed to merge clips at the end of capture \(String(describing: error))")
                    }
                })
            } else {
                if let videoUrl = NextLevel.shared.session?.lastClipUrl {
                    self.saveVideo(withURL: videoUrl)
                } else {
                    // prompt that the video has been saved
                    let alertController = UIAlertController(title: "Oops!", message: "Something failed!", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK: - UIButton handlers

@available(iOS 11.0, *)
extension MixedRealityViewController {
    
    @objc internal func handleFlipButton(_ button: UIButton) {
//        NextLevel.shared.flipCaptureDevicePosition()
    }

    @objc internal func handleSaveButton(_ button: UIButton) {
        self.endCapture()
    }
    
}

// MARK: - UIGestureRecognizerDelegate

@available(iOS 11.0, *)
extension MixedRealityViewController: UIGestureRecognizerDelegate {
    
    @objc internal func handleLongPressGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.startCapture()
            self._panStartPoint = gestureRecognizer.location(in: self.view)
            self._panStartZoom = CGFloat(NextLevel.shared.videoZoomFactor)
            break
        case .changed:
            let newPoint = gestureRecognizer.location(in: self.view)
            let scale = (self._panStartPoint.y / newPoint.y)
            let newZoom = (scale * self._panStartZoom)
            NextLevel.shared.videoZoomFactor = Float(newZoom)
            break
        case .ended:
            fallthrough
        case .cancelled:
            fallthrough
        case .failed:
            self.pauseCapture()
            fallthrough
        default:
            break
        }
    }
    
    @objc internal func handlePhotoTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // play system camera shutter sound
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil)
        NextLevel.shared.capturePhotoFromVideo()
    }
    
}

// MARK: - gesture handlers

@available(iOS 11.0, *)
extension MixedRealityViewController {
    
    @objc internal func handleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
    }
    
}

// MARK: - ARSCNViewDelegate

@available(iOS 11.0, *)
extension MixedRealityViewController: ARSCNViewDelegate {
}

// MARK: - ARSessionDelegate

@available(iOS 11.0, *)
extension MixedRealityViewController: ARSessionDelegate {
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
    }
    
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    }

    public func sessionWasInterrupted(_ session: ARSession) {
        // hook in to NextLevel (allows your controller to be the delegate without multicasting)
        NextLevel.shared.handleSessionWasInterrupted(Notification(name: Notification.Name("NextLevel")))
        
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        // hook in to NextLevel (allows your controller to be the delegate without multicasting)
        NextLevel.shared.handleSessionInterruptionEnded(Notification(name: Notification.Name("NextLevel")))
        
    }

    public func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        // hook in to NextLevel (allows your controller to be the delegate without multicasting)
        NextLevel.shared.arSession(session, didOutputAudioSampleBuffer:audioSampleBuffer)
        
    }

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // hook in to NextLevel (allows your controller to be the delegate without multicasting)
        NextLevel.shared.arSession(session, didUpdate: frame)
        
    }
    
}

// MARK: - NextLevelDelegate

@available(iOS 11.0, *)
extension MixedRealityViewController: NextLevelDelegate {
    
    // permission
    func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: AVMediaType) {
        print("NextLevel, authorization updated for media \(mediaType) status \(status)")
        if nextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
            nextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
            do {
                try nextLevel.start()
            } catch {
                print("NextLevel, failed to start camera session")
            }
        } else if status == .notAuthorized {
            // gracefully handle when audio/video is not authorized
            print("NextLevel doesn't have authorization for audio or video")
        }
    }
    
    // configuration
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
    }
    
    // session
    func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        print("nextLevelSessionWillStart")
    }
    
    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        print("nextLevelSessionDidStart")
    }
    
    func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        print("nextLevelSessionDidStop")
    }
    
    // interruption
    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
    }
    
    func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
    }
    
    // mode
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    }
    
}

@available(iOS 11.0, *)
extension MixedRealityViewController: NextLevelDeviceDelegate {
    
    // position, orientation
    func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation) {
    }
    
    // format
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceFormat deviceFormat: AVCaptureDevice.Format) {
    }
    
    // aperture
    func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect) {
    }
    
    // focus, exposure, white balance
    func nextLevelWillStartFocus(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidStopFocus(_  nextLevel: NextLevel) {
//        if let focusView = self.focusView {
//            if focusView.superview != nil {
//                focusView.stopAnimation()
//            }
//        }
    }
    
    func nextLevelWillChangeExposure(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidChangeExposure(_ nextLevel: NextLevel) {
//        if let focusView = self.focusView {
//            if focusView.superview != nil {
//                focusView.stopAnimation()
//            }
//        }
    }
    
    func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel) {
    }
    
}

// MARK: - NextLevelVideoDelegate

@available(iOS 11.0, *)
extension MixedRealityViewController: NextLevelVideoDelegate {

    // video zoom
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    }
    
    // video frame processing
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue) {
    }
    
    // enabled by isCustomContextVideoRenderingEnabled
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
    }

    func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, onQueue queue: DispatchQueue) {
    }

    // video recording session
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
        print("setup video")
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
        print("setup audio")
    }
    
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        // called when a configuration time limit is specified
        self.endCapture()
    }
    
    // video frame photo
    
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
        
        if let dictionary = photoDict,
            let photoData = dictionary[NextLevelPhotoJPEGKey] {
            
            PHPhotoLibrary.shared().performChanges({
                
                let albumAssetCollection = self.albumAssetCollection(withTitle: NextLevelAlbumTitle)
                if albumAssetCollection == nil {
                    let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: NextLevelAlbumTitle)
                    let _ = changeRequest.placeholderForCreatedAssetCollection
                }
                
            }, completionHandler: { (success1: Bool, error1: Error?) in
                
                if success1 == true {
                    if let albumAssetCollection = self.albumAssetCollection(withTitle: NextLevelAlbumTitle) {
                        PHPhotoLibrary.shared().performChanges({
                            if let data = photoData as? Data,
                                let photoImage = UIImage(data: data) {
                                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photoImage)
                                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                                let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                                assetCollectionChangeRequest?.addAssets(enumeration)
                            }
                        }, completionHandler: { (success2: Bool, error2: Error?) in
                            if success2 == true {
                                let alertController = UIAlertController(title: "Photo Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alertController.addAction(okAction)
                                self.present(alertController, animated: true, completion: nil)
                            }
                        })
                    }
                } else if let _ = error1 {
                    print("failure capturing photo from video frame \(String(describing: error1))")
                }
                
            })
            
        }
        
    }
    
}
