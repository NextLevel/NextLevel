//
//  CameraViewController.swift
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
//import NextLevel

class CameraViewController: UIViewController {

    // MARK: - UIViewController

    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - properties
    
    internal var previewView: UIView?
    internal var gestureView: UIView?
    internal var controlDockView: UIView?

    internal var recordButton: UIButton?
    internal var flipButton: UIButton?
    internal var flashButton: UIButton?
    internal var saveButton: UIButton?

    internal var focusTapGestureRecognizer: UITapGestureRecognizer?
    internal var zoomPanGestureRecognizer: UIPanGestureRecognizer?
    internal var flipDoubleTapGestureRecognizer: UITapGestureRecognizer?
    
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
        self.previewView = UIView(frame: screenBounds)
        if let previewView = self.previewView {
            previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            previewView.backgroundColor = UIColor.black
            NextLevel.sharedInstance.previewLayer.frame = previewView.bounds
            previewView.layer.addSublayer(NextLevel.sharedInstance.previewLayer)
            self.view.addSubview(previewView)
        }
        
        // buttons
        self.recordButton = UIButton(type: .custom)
        if let recordButton = self.recordButton {
            recordButton.setImage(UIImage(named: "record_button"), for: .normal)
            recordButton.sizeToFit()
            recordButton.addTarget(self, action: #selector(handleRecordButton(_:)), for: .touchUpInside)
        }
        
        self.flipButton = UIButton(type: .custom)
        if let flipButton = self.flipButton {
            flipButton.setImage(UIImage(named: "flip_button"), for: .normal)
            flipButton.sizeToFit()
            flipButton.addTarget(self, action: #selector(handleFlipButton(_:)), for: .touchUpInside)
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
                controlDockView.addSubview(flipButton)
            }
        }
        
        // gestures
        self.gestureView = UIView(frame: screenBounds)
        if let gestureView = self.gestureView, let controlDockView = self.controlDockView {
            gestureView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            gestureView.frame.size.height -= controlDockView.frame.height
            gestureView.backgroundColor = .clear
            self.view.addSubview(gestureView)

            self.focusTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleFocusTapGestureRecognizer(_:)))
            if let focusTapGestureRecognizer = self.focusTapGestureRecognizer {
                focusTapGestureRecognizer.delegate = self
                focusTapGestureRecognizer.numberOfTapsRequired = 1
                gestureView.addGestureRecognizer(focusTapGestureRecognizer)
            }
        }
        
        // Configure NextLevel by modifying the configuration ivars
        //NextLevel.sharedInstance.videoConfiguration
        //NextLevel.sharedInstance.audioConfiguration
        
        // setup a new recording session
        NextLevel.sharedInstance.session = NextLevelSession.session()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            try NextLevel.sharedInstance.start()
        } catch {
            print("NextLevel, failed to start camera session")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NextLevel.sharedInstance.stop()
    }
    
}

// MARK: - UIButton

extension CameraViewController {

    internal func handleFlipButton(_ button: UIButton) {
        NextLevel.sharedInstance.flipCaptureDevicePosition()
    }
    
    internal func handleFlashModeButton(_ button: UIButton) {
        
    }
    
    internal func handleRecordButton(_ button: UIButton) {
        
    }
    
    internal func handleDoneButton(_ button: UIButton) {
        
    }
    
}

// MARK: - UIGestureRecognizerDelegate

extension CameraViewController: UIGestureRecognizerDelegate {

    internal func handleLongPressGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        
    }
    
    internal func handleFocusTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: self.previewView)

        // TODO: create focus view and animate
        
        let previewLayer = NextLevel.sharedInstance.previewLayer
        let adjustedPoint = previewLayer.captureDevicePointOfInterest(for: tapPoint)
        NextLevel.sharedInstance.focusExposeAndAdjustWhiteBalance(atAdjustedPoint: adjustedPoint)
    }
    
}

// MARK: - NextLevelDelegate

extension CameraViewController: NextLevelDelegate {

    // permission
    func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: String!) {
        
    }
    
    // configuration
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
        
    }
    
    // session
    func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        
    }
    
    // device, mode, orientation
    func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation) {
    }
    
    // aperture
    func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect) {
    }
    
    // focus, exposure, white balance
    func nextLevelWillStartFocus(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidStopFocus(_  nextLevel: NextLevel) {
    }
    
    func nextLevelWillChangeExposure(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidChangeExposure(_ nextLevel: NextLevel) {
    }
    
    func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel) {
    }
    
    // torch, flash
    func nextLevelDidChangeFlashMode(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidChangeTorchMode(_ nextLevel: NextLevel) {
    }
    
    func nextLevelFlashActiveChanged(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelTorchActiveChanged(_ nextLevel: NextLevel) {
        
    }
    
    func nextLevelFlashAndTorchAvailabilityChanged(_ nextLevel: NextLevel) {
        
    }
    
    // zoom
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    }
    
    // preview
    func nextLevelWillStartPreview(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidStopPreview(_ nextLevel: NextLevel) {
    }
    
    // video
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelSessionClip, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        
    }
    
    // video frame photo

    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
        
    }
    
    // photo
    func nextLevel(_ nextLevel: NextLevel, willCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didProcessPhotoCaptureWith photoDictionary: [String : Any]?, photoConfiguration: NextLevelPhotoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didProcessRawPhotoCaptureWith photoDictionary: [String : Any]?, photoConfiguration: NextLevelPhotoConfiguration) {
    }

    func nextLevelDidCompletePhotoCapture(_ nextLevel: NextLevel) {
    }
}
