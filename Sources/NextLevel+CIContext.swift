//
//  NextLevel+CoreImage.swift
//  NextLevel (http://github.com/NextLevel/)
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
import CoreImage
import CoreMedia
import Foundation

extension CIContext {

    /// Factory for creating a CIContext using the available graphics API.
    ///
    /// - Parameter mtlDevice: Processor for computing
    /// - Returns: Default configuration rendering context, otherwise nil.
    public class func createDefaultCIContext(_ mtlDevice: MTLDevice? = nil) -> CIContext? {
        let options: [CIContextOption: Any] = [.outputColorSpace: CGColorSpaceCreateDeviceRGB(),
                                                 .outputPremultiplied: true,
                                                 .useSoftwareRenderer: NSNumber(booleanLiteral: false)]
        if let device = mtlDevice {
            return CIContext(mtlDevice: device, options: options)
        } else if let device = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: device, options: options)
        } else {
            return nil
        }
    }

    /// Creates a UIImage from the given sample buffer input
    ///
    /// - Parameter sampleBuffer: sample buffer input
    /// - Returns: UIImage from the sample buffer, otherwise nil
    public func uiimage(withSampleBuffer sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let ciimage = CIImage(cvPixelBuffer: pixelBuffer)
        var sampleBufferImage: UIImage?
        if let cgimage = self.createCGImage(ciimage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))) {
            sampleBufferImage = UIImage(cgImage: cgimage)
        }
        return sampleBufferImage
    }

    /// Creates a UIImage from the given pixel buffer input
    ///
    /// - Parameter pixelBuffer: Pixel buffer input
    /// - Returns: UIImage from the pixel buffer, otherwise nil
    public func uiimage(withPixelBuffer pixelBuffer: CVPixelBuffer) -> UIImage? {
        var pixelBufferImage: UIImage?
        guard CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly) == kCVReturnSuccess else {
            return nil
        }

        let ciimage = CIImage(cvPixelBuffer: pixelBuffer)
        if let cgimage = self.createCGImage(ciimage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))) {
            pixelBufferImage = UIImage(cgImage: cgimage)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)

        return pixelBufferImage
    }

    /// Orient a pixel buffer using an exif orientation value.
    ///
    /// - Parameters:
    ///   - pixelBuffer: Pixel buffer input
    ///   - orientation: CGImage orientation for the new pixel buffer
    ///   - pixelBufferPool: Pixel buffer pool at which to allocate the new buffer
    /// - Returns: Oriented pixel buffer, otherwise nil
    public func createPixelBuffer(fromPixelBuffer pixelBuffer: CVPixelBuffer, withOrientation orientation: CGImagePropertyOrientation, pixelBufferPool: CVPixelBufferPool) -> CVPixelBuffer? {
        var updatedPixelBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &updatedPixelBuffer) == kCVReturnSuccess else {
            return nil
        }

        if let updatedPixelBuffer = updatedPixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
            let orientedImage = ciImage.oriented(orientation)
            self.render(orientedImage, to: updatedPixelBuffer)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
            return updatedPixelBuffer
        }
        return nil
    }

    /// Create a pixel buffer from a MTLTexture and orientation value.
    ///
    /// - Parameters:
    ///   - mtlTexture: Input texture to render
    ///   - orientation: CGImage orientation for the new pixel buffer
    ///   - pixelBufferPool: Pixel buffer pool at which to allocate the new buffer
    /// - Returns: Oriented pixel buffer, otherwise nil
    public func createPixelBuffer(fromMTLTexture mtlTexture: MTLTexture, withOrientation orientation: CGImagePropertyOrientation, pixelBufferPool: CVPixelBufferPool) -> CVPixelBuffer? {
        var updatedPixelBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &updatedPixelBuffer) == kCVReturnSuccess else {
            return nil
        }

        if let updatedPixelBuffer = updatedPixelBuffer {
            // update orientation to match Metal's origin
            let ciImage = CIImage(mtlTexture: mtlTexture, options: nil)
            if let orientedImage = ciImage?.oriented(orientation) {
                CVPixelBufferLockBaseAddress(updatedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                self.render(orientedImage, to: updatedPixelBuffer)
                CVPixelBufferUnlockBaseAddress(updatedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                return updatedPixelBuffer
            }
        }
        return nil
    }
}
