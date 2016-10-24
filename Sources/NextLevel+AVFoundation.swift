//
//  NextLevel+AVFoundation.swift
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

extension AVCaptureDeviceInput {
    
    public class func deviceInput(withMediaType mediaType: String, captureSession: AVCaptureSession) -> AVCaptureDeviceInput? {
        let inputs = captureSession.inputs as! [AVCaptureDeviceInput]
        for deviceInput in inputs {
            if deviceInput.device.hasMediaType(mediaType) {
                return deviceInput
            }
        }
        return nil
    }
    
}

extension AVCaptureConnection {
    
    public class func connection(withMediaType mediaType:String, fromConnections connections: [AVCaptureConnection]) -> AVCaptureConnection? {
        for connection: AVCaptureConnection in connections {
            if let inputPorts = connection.inputPorts as? [AVCaptureInputPort] {
                for port: AVCaptureInputPort in inputPorts {
                    if port.mediaType == mediaType {
                        return connection
                    }
                }
            }
        }
        return nil
    }
    
}

extension AVCaptureDevice {

    // MARK: device lookup

    public class func captureDevice(withType deviceType: AVCaptureDeviceType, forPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDeviceType] = [deviceType]
        if let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaTypeVideo, position: position) {
            return discoverySession.devices.first
        }
        return nil
    }
    
    public class func wideAngleVideoDevice(forPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDeviceType] = [.builtInWideAngleCamera]
        if let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaTypeVideo, position: position) {
            return discoverySession.devices.first
        }
        return nil
    }
    
    public class func telephotoVideoDevice(forPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDeviceType] = [.builtInTelephotoCamera]
        if let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaTypeVideo, position: position) {
            return discoverySession.devices.first
        }
        return nil
    }
    
    public class func primaryVideoDevice(forPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDeviceType] = [.builtInDuoCamera, .builtInWideAngleCamera]
        if let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaTypeVideo, position: position) {
            // prioritize duo camera systems before wide angle
            for device in discoverySession.devices {
                if (device.deviceType == .builtInDuoCamera) {
                    return device
                }
            }
            return discoverySession.devices.first
        }
        return nil
    }
    
    public class func videoDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    }
    
    public class func audioDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    }
    
    // MARK: device format
    
    public class func isCaptureDeviceFormat(inRange format: AVCaptureDeviceFormat, frameRate: CMTimeScale) -> Bool {
        return AVCaptureDevice.isCaptureDeviceFormat(inRange: format, frameRate: frameRate, dimensions: CMVideoDimensions(width: 0, height: 0))
    }
    
    public class func isCaptureDeviceFormat(inRange format: AVCaptureDeviceFormat, frameRate: CMTimeScale, dimensions: CMVideoDimensions) -> Bool {
        let formatDimensions: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        
        if (formatDimensions.width >= dimensions.width && formatDimensions.height >= dimensions.height) {
            let videoSupportedFrameRateRanges: [AVFrameRateRange] = format.videoSupportedFrameRateRanges as! [AVFrameRateRange]
            for frameRateRange in videoSupportedFrameRateRanges {
                if frameRateRange.minFrameDuration.timescale >= frameRate && frameRateRange.maxFrameDuration.timescale <= frameRate {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: NextLevel types
    
    internal func torchModeNextLevelType() -> NextLevelTorchMode {
        var mode = NextLevelTorchMode.off
        switch self.torchMode {
        case .auto:
            mode = .auto
            break
        case .off:
            mode = .off
            break
        case .on:
            mode = .on
            break
        }
        return mode
    }
    
    internal func focusModeNextLevelType() -> NextLevelFocusMode {
        var mode = NextLevelFocusMode.locked
        switch self.focusMode {
        case .autoFocus:
            mode = .autoFocus
            break
        case .continuousAutoFocus:
            mode = .continuousAutoFocus
            break
        case .locked:
            mode = .locked
            break
        }
        return mode
    }
    
    internal func exposureModeNextLevelType() -> NextLevelExposureMode {
        var nextLevelMode = NextLevelExposureMode.locked
        switch self.exposureMode {
        case .autoExpose:
            nextLevelMode = .autoExpose
            break
        case .continuousAutoExposure:
            nextLevelMode = .continuousAutoExposure
            break
        case .locked:
            nextLevelMode = .locked
            break
        case .custom:
            nextLevelMode = .custom
            break
        }
        return nextLevelMode
    }
    
}

extension AVCaptureVideoOrientation {
    
    internal static func avorientationFromUIDeviceOrientation(_ orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        var avorientation: AVCaptureVideoOrientation = .portrait
        switch orientation {
        case .portrait:
            break
        case .landscapeLeft:
            avorientation = .landscapeRight
            break
        case .landscapeRight:
            avorientation = .landscapeLeft
            break
        case .portraitUpsideDown:
            avorientation = .portraitUpsideDown
            break
        default:
            break
        }
        return avorientation
    }
    
    internal func deviceOrientationNextLevelType() -> NextLevelDeviceOrientation {
        var nlorientation = NextLevelDeviceOrientation.portrait
        switch self {
        case .portrait:
            break
        case .landscapeLeft:
            nlorientation = .landscapeRight
            break
        case .landscapeRight:
            nlorientation = .landscapeLeft
            break
        case .portraitUpsideDown:
            nlorientation = .portraitUpsideDown
            break
        }
        return nlorientation
    }
    
}

extension AVCaptureFlashMode {
    
    internal func flashModeNextLevelType() -> NextLevelFlashMode {
        var mode = NextLevelFlashMode.off
        switch self {
        case .auto:
            mode = .auto
            break
        case .off:
            mode = .off
            break
        case .on:
            mode = .on
            break
        }
        return mode
    }
    
}
