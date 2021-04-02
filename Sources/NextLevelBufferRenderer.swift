//
//  NextLevelBufferRenderer.swift
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
import Foundation
import CoreImage
import Metal
#if USE_ARKIT
import ARKit
import SceneKit
#endif

/// NextLevelBufferRenderer, provides the ability to render/record SceneKit frames
public class NextLevelBufferRenderer {

    // MARK: - properties

    /// Specifies if the renderer should automatically light up scenes that have no light source.
    public var autoenablesDefaultLighting: Bool = true {
        didSet {
            #if USE_ARKIT
            self._renderer?.autoenablesDefaultLighting = self.autoenablesDefaultLighting
            #endif
        }
    }

    /// Rendering context based on the ARSCNView metal device
    public var ciContext: CIContext? {
        get {
            self._ciContext
        }
    }

    /// Pixel buffer pool for sharing
    public var pixelBufferPool: CVPixelBufferPool? {
        get {
            self._pixelBufferPool
        }
    }

    /// Rendered video buffer output (using to write video file)
    public var videoBufferOutput: CVPixelBuffer? {
        get {
            self._videoBufferOutput
        }
    }

    // MARK: - ivars

    fileprivate var _device: MTLDevice?
    fileprivate var _library: MTLLibrary?
    fileprivate var _commandQueue: MTLCommandQueue?
    fileprivate var _renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()

    fileprivate var _texture: MTLTexture?

    fileprivate var _bufferWidth: Int = 0
    fileprivate var _bufferHeight: Int = 0
    fileprivate var _bufferFormatType: OSType = OSType(kCVPixelFormatType_32BGRA)
    fileprivate var _presentationFrame: CGRect = .zero

    fileprivate var _ciContext: CIContext?
    fileprivate var _pixelBufferPool: CVPixelBufferPool?
    fileprivate var _videoBufferOutput: CVPixelBuffer?

    #if USE_ARKIT
    fileprivate weak var _arView: ARSCNView?
    fileprivate var _renderer: SCNRenderer?

    public convenience init(view: ARSCNView) {
        self.init()

        self._arView = view
        self._presentationFrame = view.bounds

        #if !( targetEnvironment(simulator) )
        self._device = view.device
        self._renderer = SCNRenderer(device: view.device, options: nil)
        self._renderer?.scene = view.scene
        self._renderer?.autoenablesDefaultLighting = self.autoenablesDefaultLighting
        #endif

        self._commandQueue = view.device?.makeCommandQueue()
    }
    #endif

    deinit {
        self._device = nil
        self._library = nil
        self._commandQueue = nil
        self._texture = nil

        #if USE_ARKIT
        self._renderer?.scene = nil
        self._renderer = nil
        self._arView = nil
        #endif

        self._ciContext = nil
        self._pixelBufferPool = nil
        self._videoBufferOutput = nil
    }

}

// MARK: - setup

extension NextLevelBufferRenderer {

    fileprivate func setupContextIfNecessary() {
        guard self._ciContext == nil else {
            return
        }

        guard let device = self._device else {
            return
        }

        self._ciContext = CIContext.createDefaultCIContext(device)
    }

    fileprivate func setupPixelBufferPoolIfNecessary(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let formatType = CVPixelBufferGetPixelFormatType(pixelBuffer)

        // (width != self._bufferWidth) || (height != self._bufferHeight) || (formatType != self._bufferFormatType) ||
        let bufferChanged: Bool = self._pixelBufferPool == nil
        if !bufferChanged {
            return
        }

        var renderWidth = width
        var renderHeight = height

        switch orientation {
        case .up:
            fallthrough
        case .upMirrored:
            fallthrough
        case .down:
            fallthrough
        case .downMirrored:
            renderWidth = height
            renderHeight = width
            break
        default:
            break
        }

        let poolAttributes: [String: AnyObject] = [String(kCVPixelBufferPoolMinimumBufferCountKey): NSNumber(integerLiteral: 1)]
        let pixelBufferAttributes: [String: AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(integerLiteral: Int(formatType)),
                                                           String(kCVPixelBufferWidthKey): NSNumber(value: renderWidth),
                                                           String(kCVPixelBufferHeightKey): NSNumber(value: renderHeight),
                                                           String(kCVPixelBufferMetalCompatibilityKey): NSNumber(booleanLiteral: true),
                                                           String(kCVPixelBufferIOSurfacePropertiesKey): [:] as AnyObject ]

        var pixelBufferPool: CVPixelBufferPool?
        if CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as CFDictionary, pixelBufferAttributes as CFDictionary, &pixelBufferPool) == kCVReturnSuccess {
            self._bufferWidth = renderWidth
            self._bufferHeight = renderHeight
            self._bufferFormatType = formatType
            self._pixelBufferPool = pixelBufferPool
        }
    }

}

// MARK: - rendering

extension NextLevelBufferRenderer {

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
            textureDescriptor.storageMode = .private
            textureDescriptor.textureType = .type2D
            textureDescriptor.sampleCount = 1
            self._texture = device.makeTexture(descriptor: textureDescriptor)
        }

        if let commandBuffer = self._commandQueue?.makeCommandBuffer(),
            let texture = self._texture {
            self._renderPassDescriptor.colorAttachments[0].texture = texture
            self._renderPassDescriptor.colorAttachments[0].loadAction = .clear
            self._renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
            self._renderPassDescriptor.colorAttachments[0].storeAction = .store

            let presentationAspectRatio = self._presentationFrame.size.width > self._presentationFrame.size.height ?
                self._presentationFrame.size.width / self._presentationFrame.size.height :
                self._presentationFrame.size.height / self._presentationFrame.size.width

            let textureAspectRatio = texture.width > texture.height ?
                CGFloat(texture.width) / CGFloat(texture.height) :
                CGFloat(texture.height) / CGFloat(texture.width)

            var viewport = CGRect(x: 0, y: 0, width: texture.width, height: texture.height)
            if presentationAspectRatio != textureAspectRatio {
                // aspectFill
                // print("texture \(texture.width) \(texture.height) \(self._presentationFrame.size.width) \(self._presentationFrame.size.height)")
                let scaleFactorWidth = CGFloat(CGFloat(texture.width) / self._presentationFrame.size.width)
                viewport = CGRect(x: 0, y: Int(CGFloat(texture.height - Int(self._presentationFrame.size.height * scaleFactorWidth)) * 0.5),
                                  width: texture.width, height: Int(self._presentationFrame.size.height * scaleFactorWidth) )
            }

            self._renderer?.scene = scene
            self._renderer?.pointOfView = pointOfView
            self._renderer?.render(atTime: time, viewport: viewport, commandBuffer: commandBuffer, passDescriptor: self._renderPassDescriptor)

            commandBuffer.commit()
        }

        let orientation: CGImagePropertyOrientation = .downMirrored

        self.setupPixelBufferPoolIfNecessary(pixelBuffer, orientation: orientation)

        if let pixelBufferPool = self._pixelBufferPool,
            let texture = self._texture {
            if let pixelBufferOutput = self._ciContext?.createPixelBuffer(fromMTLTexture: texture, withOrientation: orientation, pixelBufferPool: pixelBufferPool) {
                self._videoBufferOutput = pixelBufferOutput
            }
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    }

    #endif

}
