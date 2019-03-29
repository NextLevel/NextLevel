//
//  NextLevelBufferRenderer.swift
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
import Metal
#if USE_ARKIT
import ARKit
import SceneKit
#endif

/// NextLevelBufferRenderer, provides the ability to render/record SceneKit frames
@available(iOS 11.0, *)
public class NextLevelBufferRenderer {
    
    // MARK: - properties
    
    /// Rendered video buffer output (using to write video file)
    public var videoBufferOutput: CVPixelBuffer? {
        get {
            return self._videoBufferOutput
        }
    }
    
    // MARK: - ivars
    
    internal var _device: MTLDevice?
    internal var _library: MTLLibrary?
    internal var _commandQueue: MTLCommandQueue?
    internal var _renderPassDescriptor: MTLRenderPassDescriptor?
    
    internal var _texture: MTLTexture?
    
    internal var _bufferWidth: Int = 0
    internal var _bufferHeight: Int = 0
    internal var _bufferFormatType: OSType = OSType(kCVPixelFormatType_32BGRA)
    internal var _presentationFrame: CGRect = .zero
    
    internal var _ciContext: CIContext?
    internal var _pixelBufferPool: CVPixelBufferPool?
    internal var _videoBufferOutput: CVPixelBuffer?
    
    #if USE_ARKIT
    internal weak var _arView: ARSCNView?
    internal var _renderSemaphore: DispatchSemaphore = DispatchSemaphore(value: 3)
    internal var _renderer: SCNRenderer?
    
    // MARK: - object lifecycle
    
    public convenience init(view: ARSCNView) {
        self.init()
        
        #if !( targetEnvironment(simulator) )
        self._device = view.device
        self._renderer = SCNRenderer(device: view.device, options: nil)
        self._renderer?.scene = view.scene
        #endif
        
        self._arView = view
        self._presentationFrame = view.bounds
    }
    #endif
    
    deinit {
        self._device = nil
        self._library = nil
        self._commandQueue = nil
        self._renderPassDescriptor = nil
        self._texture = nil
        
        self._ciContext = nil
        self._pixelBufferPool = nil
        self._videoBufferOutput = nil
        
        #if USE_ARKIT
        self._renderer?.scene = nil
        self._renderer = nil
        self._arView = nil
        #endif
    }
    
}

// MARK: - setup

@available(iOS 11.0, *)
extension NextLevelBufferRenderer {
    
    internal func setupContextIfNecessary() {
        guard self._ciContext == nil else {
            return
        }
        
        guard let device = self._device else {
            return
        }
        
        // setup a context for buffer conversion
        let options : [CIContextOption : Any] = [.outputColorSpace : CGColorSpaceCreateDeviceRGB(),
                                                 .outputPremultiplied : true,
                                                 .useSoftwareRenderer : NSNumber(booleanLiteral: false)]
        self._ciContext = CIContext(mtlDevice: device, options: options)
        
        // setup pixel buffer rendering
        #if USE_ARKIT
        self._renderer = SCNRenderer(device: device, options: nil)
        self._commandQueue = device.makeCommandQueue()
        self._renderPassDescriptor = MTLRenderPassDescriptor()
        #endif
    }
    
    internal func setupPixelBufferPoolIfNecessary(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        let formatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        guard self._pixelBufferPool == nil else {
            return
        }
        
        // check dimension/orientation/format changed
        if width == self._bufferWidth && height == self._bufferHeight && formatType == self._bufferFormatType {
            return
        }
        
        switch orientation {
        case .up:
            fallthrough
        case .upMirrored:
            fallthrough
        case .down:
            fallthrough
        case .downMirrored:
            self._bufferWidth = height
            self._bufferHeight = width
            break
        default:
            break
        }
        self._bufferFormatType = formatType
        
        let poolAttributes: [String : AnyObject] = [String(kCVPixelBufferPoolMinimumBufferCountKey): NSNumber(integerLiteral: 1)]
        let pixelBufferAttributes: [String : AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(integerLiteral: Int(self._bufferFormatType)),
                                                           String(kCVPixelBufferWidthKey) : NSNumber(value: self._bufferWidth),
                                                           String(kCVPixelBufferHeightKey) : NSNumber(value: self._bufferHeight),
                                                           String(kCVPixelBufferMetalCompatibilityKey) : NSNumber(booleanLiteral: true),
                                                           String(kCVPixelBufferIOSurfacePropertiesKey) : [:] as AnyObject ]
        
        var pixelBufferPool: CVPixelBufferPool? = nil
        if CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as CFDictionary, pixelBufferAttributes as CFDictionary, &pixelBufferPool) == kCVReturnSuccess {
            self._pixelBufferPool = pixelBufferPool
        }
    }
    
}

// MARK: - rendering

@available(iOS 11.0, *)
extension NextLevelBufferRenderer {

    private func createPixelBufferOutput(withPixelBuffer pixelBuffer: CVPixelBuffer,
                                         orientation: CGImagePropertyOrientation,
                                         pixelBufferPool: CVPixelBufferPool,
                                         texture: MTLTexture) -> CVPixelBuffer? {
        // allocate a pixel buffer and render into it
        var updatedPixelBuffer: CVPixelBuffer? = nil
        if CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &updatedPixelBuffer) == kCVReturnSuccess {
            if let updatedPixelBuffer = updatedPixelBuffer {
                // update orientation to match Metal's origin
                let ciImage = CIImage(mtlTexture: texture, options: nil)
                if let orientedImage = ciImage?.oriented(orientation) {
                    CVPixelBufferLockBaseAddress(updatedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                    self._ciContext?.render(orientedImage, to: updatedPixelBuffer)
                    CVPixelBufferUnlockBaseAddress(updatedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                    return updatedPixelBuffer
                }
            }
        }
        return nil
    }
    
    #if USE_ARKIT
    
    /// SCNSceneRendererDelegate hook for rendering
    ///
    /// - Parameters:
    ///   - renderer: SCNSceneRendererDelegate renderer
    ///   - scene: SCNSceneRendererDelegate scene
    ///   - time: SCNSceneRendererDelegate time
    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let arView = self._arView,
            let pixelBuffer = arView.session.currentFrame?.capturedImage,
            let pointOfView = arView.pointOfView,
            let device = self._device else {
                return
        }
        
        self.setupContextIfNecessary()
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        // setup the offscreen texture now that the size was determined
        if self._texture == nil && self._bufferWidth > 0 && self._bufferHeight > 0 {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                             width: self._bufferWidth,
                                                                             height: self._bufferHeight,
                                                                             mipmapped: false)
            textureDescriptor.usage = [.shaderRead, .renderTarget]
            self._texture = device.makeTexture(descriptor: textureDescriptor)
        }
        
        if let commandBuffer = self._commandQueue?.makeCommandBuffer(),
            let renderPassDescriptor = self._renderPassDescriptor,
            let texture = self._texture {
            
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0);
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            var viewport = CGRect(x: 0, y: 0, width: texture.width, height: texture.height)
            
            let presentationAspectRatio = self._presentationFrame.size.width > self._presentationFrame.size.height ?
                self._presentationFrame.size.width / self._presentationFrame.size.height :
                self._presentationFrame.size.height / self._presentationFrame.size.width
            
            let textureAspectRatio = texture.width > texture.height ?
                CGFloat(texture.width) / CGFloat(texture.height) :
                CGFloat(texture.height) / CGFloat(texture.width)
            
            if presentationAspectRatio != textureAspectRatio {
                // aspectFill
                // print("texture \(texture.width) \(texture.height) \(self._presentationFrame.size.width) \(self._presentationFrame.size.height)")
                let scaleFactorWidth = CGFloat(CGFloat(texture.width) / self._presentationFrame.size.width)
                viewport = CGRect(x: 0, y: Int(CGFloat(texture.height - Int(self._presentationFrame.size.height * scaleFactorWidth)) * 0.5),
                                  width: texture.width, height: Int(self._presentationFrame.size.height * scaleFactorWidth) )
            }
            
            self._renderer?.scene = scene
            self._renderer?.pointOfView = pointOfView
            self._renderer?.render(atTime: renderer.sceneTime, viewport: viewport, commandBuffer: commandBuffer, passDescriptor: renderPassDescriptor)
            
            commandBuffer.commit()
        }
        
        let orientation: CGImagePropertyOrientation = .downMirrored
        self.setupPixelBufferPoolIfNecessary(pixelBuffer, orientation: orientation)
        if let pixelBufferPool = self._pixelBufferPool, let texture = self._texture {
            if let pixelBufferOutput = self.createPixelBufferOutput(withPixelBuffer: pixelBuffer,
                                                                    orientation: orientation,
                                                                    pixelBufferPool: pixelBufferPool,
                                                                    texture: texture) {
                self._videoBufferOutput = pixelBufferOutput
            }
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    }
    
    #endif
    
}
