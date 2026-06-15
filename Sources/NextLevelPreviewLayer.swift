import Foundation
import AVFoundation
import UIKit
#if targetEnvironment(simulator)
import SimulatorCameraClient
#endif

/// Cross-platform preview layer used by NextLevel.
///
/// - On device: wraps AVCaptureVideoPreviewLayer.
/// - On simulator: uses AVSampleBufferDisplayLayer + SimulatorCameraPreviewModel
///   so previewLayer behaves like a normal preview for callers.
public final class NextLevelPreviewLayer: CALayer {
    
    public override init(layer: Any) {
        super.init(layer: layer)
    }

    // MARK: Public API used by NextLevel (kept minimal)

    /// Matches AVCaptureVideoPreviewLayer.videoGravity
    public var videoGravity: AVLayerVideoGravity {
        get {
            #if targetEnvironment(simulator)
            return displayLayer.videoGravity
            #else
            return devicePreview?.videoGravity ?? .resizeAspect
            #endif
        }
        set {
            #if targetEnvironment(simulator)
            displayLayer.videoGravity = newValue
            #else
            devicePreview?.videoGravity = newValue
            #endif
            setNeedsLayout()
        }
    }

    /// Matches AVCaptureVideoPreviewLayer.session (setter attaches on device)
    public var session: AVCaptureSession? {
        get {
            #if !targetEnvironment(simulator)
            return devicePreview?.session
            #else
            return nil
            #endif
        }
        set {
            #if !targetEnvironment(simulator)
            devicePreview?.session = newValue
            #else
            // no-op on simulator
            #endif
        }
    }

    /// Matches AVCaptureVideoPreviewLayer.connection
    public var connection: AVCaptureConnection? {
        #if !targetEnvironment(simulator)
        return devicePreview?.connection
        #else
        return nil
        #endif
    }

    /// Transforms metadata object coordinates into preview coordinates.
    /// On simulator returns the original object (no transform) if device API unavailable.
    public func transformedMetadataObject(for metadataObject: AVMetadataObject) -> AVMetadataObject? {
        #if !targetEnvironment(simulator)
        return devicePreview?.transformedMetadataObject(for: metadataObject)
        #else
        // Simulator preview is an AVSampleBufferDisplayLayer — no AVFoundation transform available.
        // Return the metadata object as-is so callers receive a non-nil object.
        return metadataObject
        #endif
    }

    // MARK: - Device backing (real device)
    #if !targetEnvironment(simulator)
    private lazy var devicePreview: AVCaptureVideoPreviewLayer? = {
        let p = AVCaptureVideoPreviewLayer()
        p.videoGravity = .resizeAspectFill
        return p
    }()
    #endif

    // MARK: - Simulator backing
    #if targetEnvironment(simulator)
    private let displayLayer: AVSampleBufferDisplayLayer = {
        let l = AVSampleBufferDisplayLayer()
        l.videoGravity = .resizeAspectFill
        l.needsDisplayOnBoundsChange = true
        return l
    }()

    /// Model that manages subscription and enqueues frames to displayLayer.
    public private(set) lazy var previewModel: Any? = {
        if #available(iOS 13, *) {
            return SimulatorCameraPreviewModel()
        } else {
            return nil
        }
    }()
    #endif

    // MARK: - Init / layout

    public override init() {
        super.init()
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        #if targetEnvironment(simulator)
        self.addSublayer(displayLayer)
        if #available(iOS 13.0, *) {
            (previewModel as? SimulatorCameraPreviewModel)?.setDisplayLayer(displayLayer)
        }
        #else
        if let p = devicePreview {
            self.addSublayer(p)
        }
        #endif
    }

    deinit {
        #if targetEnvironment(simulator)
        if #available(iOS 13.0, *) {
            (previewModel as? SimulatorCameraPreviewModel)?.setDisplayLayer(nil)
        }
        #endif
    }

    public override func layoutSublayers() {
        super.layoutSublayers()
        #if targetEnvironment(simulator)
        displayLayer.frame = bounds
        #else
        devicePreview?.frame = bounds
        #endif
    }

    // Convenience: expose some mirroring helpers that NextLevel might expect via connection
    public var isVideoMirroringSupported: Bool {
        #if !targetEnvironment(simulator)
        return connection?.isVideoMirroringSupported ?? false
        #else
        return false
        #endif
    }

    public var isVideoMirrored: Bool {
        get {
            #if !targetEnvironment(simulator)
            return connection?.isVideoMirrored ?? false
            #else
            return false
            #endif
        }
        set {
            #if !targetEnvironment(simulator)
            if let conn = connection, conn.isVideoMirroringSupported {
                conn.isVideoMirrored = newValue
            }
            #endif
        }
    }

    public var automaticallyAdjustsVideoMirroring: Bool {
        get {
            #if !targetEnvironment(simulator)
            return connection?.automaticallyAdjustsVideoMirroring ?? false
            #else
            return false
            #endif
        }
        set {
            #if !targetEnvironment(simulator)
            if let conn = connection, conn.isVideoMirroringSupported {
                conn.automaticallyAdjustsVideoMirroring = newValue
            }
            #endif
        }
    }
}
