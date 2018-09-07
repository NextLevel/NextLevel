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
    
    /// Returns the capture device input for the desired media type and capture session, otherwise nil.
    ///
    /// - Parameters:
    ///   - mediaType: Specified media type. (i.e. AVMediaTypeVideo, AVMediaTypeAudio, etc.)
    ///   - captureSession: Capture session for which to query
    /// - Returns: Desired capture device input for the associated media type, otherwise nil
    public class func deviceInput(withMediaType mediaType: AVMediaType, captureSession: AVCaptureSession) -> AVCaptureDeviceInput? {
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for deviceInput in inputs {
                if deviceInput.device.hasMediaType(mediaType) {
                    return deviceInput
                }
            }
        }
        return nil
    }
    
}

extension AVCaptureConnection {
    
    /// Returns the capture connection for the desired media type, otherwise nil.
    ///
    /// - Parameters:
    ///   - mediaType: Specified media type. (i.e. AVMediaTypeVideo, AVMediaTypeAudio, etc.)
    ///   - connections: Array of `AVCaptureConnection` objects to search
    /// - Returns: Capture connection for the desired media type, otherwise nil
    public class func connection(withMediaType mediaType: AVMediaType, fromConnections connections: [AVCaptureConnection]) -> AVCaptureConnection? {
        for connection: AVCaptureConnection in connections {
            for port: AVCaptureInput.Port in connection.inputPorts {
                if port.mediaType == mediaType {
                    return connection
                }
            }
        }
        return nil
    }
    
}

extension AVCaptureDevice {

    // MARK: device lookup

    /// Returns the capture device for the desired device type and position.
    /// #protip, NextLevelDevicePosition.avfoundationType can provide the AVFoundation type.
    ///
    /// - Parameters:
    ///   - deviceType: Specified capture device type, (i.e. builtInMicrophone, builtInWideAngleCamera, etc.)
    ///   - position: Desired position of device
    /// - Returns: Capture device for the specified type and position, otherwise nil
    public class func captureDevice(withType deviceType: AVCaptureDevice.DeviceType, forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [deviceType]
        if let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position).devices.first {
            return discoverySession
        }
        return nil
    }
    
    /// Returns the default wide angle video device for the desired position, otherwise nil.
    ///
    /// - Parameter position: Desired position of the device
    /// - Returns: Wide angle video capture device, otherwise nil
    public class func wideAngleVideoDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
        if let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position).devices.first {
            return discoverySession
        }
        return nil
    }
    
    /// Returns the default telephoto video device for the desired position, otherwise nil.
    ///
    /// - Parameter position: Desired position of the device
    /// - Returns: Telephoto video capture device, otherwise nil
    public class func telephotoVideoDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInTelephotoCamera]
        if let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position).devices.first {
            return discoverySession
        }
        return nil
    }
    
    /// Returns the primary duo camera video device, if available, else the default wide angel camera, otherwise nil.
    ///
    /// - Parameter position: Desired position of the device
    /// - Returns: Primary video capture device found, otherwise nil
    public class func primaryVideoDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
        if #available(iOS 11.0, *) {
            deviceTypes.append(.builtInDualCamera)
        } else {
            deviceTypes.append(.builtInDuoCamera)
        }
        
        // prioritize duo camera systems before wide angle
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
        for device in discoverySession.devices {
            if #available(iOS 11.0, *) {
                if (device.deviceType == AVCaptureDevice.DeviceType.builtInDualCamera) {
                    return device
                }
            } else {
                if (device.deviceType == AVCaptureDevice.DeviceType.builtInDuoCamera) {
                    return device
                }
            }
        }
        return discoverySession.devices.first
    }
    
    /// Returns the default video capture device, otherwise nil.
    ///
    /// - Returns: Default video capture device, otherwise nil
    public class func videoDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.default(for: AVMediaType.video)
    }
    
    /// Returns the default audio capture device, otherwise nil.
    ///
    /// - Returns: default audio capture device, otherwise nil
    public class func audioDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.default(for: AVMediaType.audio)
    }
    
}

extension AVCaptureDevice.Format {
    
    /// Returns the maximum capable framerate for the desired capture format and minimum, otherwise zero.
    ///
    /// - Parameters:
    ///   - format: Capture format to evaluate for a specific framerate.
    ///   - minFrameRate: Lower bound time scale or minimum desired framerate.
    /// - Returns: Maximum capable framerate within the desired format and minimum constraints.
    public class func maxFrameRate(forFormat format: AVCaptureDevice.Format, minFrameRate: CMTimeScale) -> CMTimeScale {
        var lowestTimeScale: CMTimeScale = 0
        for range in format.videoSupportedFrameRateRanges {
            if range.minFrameDuration.timescale >= minFrameRate && (lowestTimeScale == 0 || range.minFrameDuration.timescale < lowestTimeScale) {
                lowestTimeScale = range.minFrameDuration.timescale
            }
        }
        return lowestTimeScale
    }
    
    /// Checks if the specified capture device format supports a desired framerate and dimensions.
    ///
    /// - Parameters:
    ///   - frameRate: Desired frame rate
    ///   - dimensions: Desired video dimensions
    /// - Returns: `true` if the capture device format supports the given criteria, otherwise false
    public func isSupported(withFrameRate frameRate: CMTimeScale, dimensions: CMVideoDimensions = CMVideoDimensions(width: 0, height: 0)) -> Bool {
        let formatDimensions = CMVideoFormatDescriptionGetDimensions(self.formatDescription)
        if (formatDimensions.width >= dimensions.width && formatDimensions.height >= dimensions.height) {
            for frameRateRange in self.videoSupportedFrameRateRanges {
                if frameRateRange.minFrameDuration.timescale >= frameRate && frameRateRange.maxFrameDuration.timescale <= frameRate {
                    return true
                }
            }
        }
        return false
    }
    
}

extension AVCaptureVideoOrientation {
    
    /// UIKit orientation equivalent type
    public var uikitType: UIDeviceOrientation {
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
    
}

extension AVCaptureDevice.Position {
    
    /// UIKit device equivalent type
    public var uikitType: UIImagePickerController.CameraDevice {
        switch self {
        case .unspecified:
            fallthrough
        case .back:
            return .rear
        case .front:
            return .front
        }
    }
}

extension AVCaptureDevice.WhiteBalanceGains {
    
    /// Normalize gain values for a capture device.
    ///
    /// - Parameter captureDevice: Device used for adjustment.
    /// - Returns: Normalized gains.
    public func normalize(_ captureDevice: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        var newGains = self

        newGains.redGain = Swift.min(captureDevice.maxWhiteBalanceGain, Swift.max(1.0, newGains.redGain))
        newGains.greenGain = Swift.min(captureDevice.maxWhiteBalanceGain, Swift.max(1.0, newGains.greenGain))
        newGains.blueGain = Swift.min(captureDevice.maxWhiteBalanceGain, Swift.max(1.0, newGains.blueGain))
        
        return newGains
    }
    
}
