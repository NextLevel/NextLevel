//
//  NextLevelGIFCreator.swift
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
import AVFoundation
import ImageIO
import MobileCoreServices

private let NextLevelGIFCreatorQueueIdentifier = "engineering.NextLevel.GIF"

public class NextLevelGIFCreator {

    // MARK: - properties

    /// Output directory where the GIF is created, default is tmp
    public var outputDirectory: String

    // MARK: - ivars

    fileprivate var _outputFilePath: URL?
    fileprivate var _fileExtension: String = "gif"

    fileprivate var _queue: DispatchQueue = DispatchQueue(label: NextLevelGIFCreatorQueueIdentifier, attributes: .concurrent)

    // MARK: - object lifecycle

    public init() {
        self.outputDirectory = NSTemporaryDirectory()
    }

    // MARK: - internal

    fileprivate func createOutputFilePath() -> URL? {
        let filename = "\(Date().iso8601())-NL.\(self._fileExtension)"

        var gifURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        gifURL.appendPathComponent(filename)
        return gifURL
    }

    // MARK: - factory

    /// Creates an animated GIF from a sequence of images.
    ///
    /// - Parameters:
    ///   - images: Frames for creating the sequence
    ///   - delay: Time between each frame
    ///   - loopCount: Number of loops built into the sequence, default is 0
    ///   - completionHandler: Completion handler called when the operation finishes with success or failure
    public func create(gifWithImages images: [UIImage], delay: Float, loopCount: Int = 0, completionHandler: ((_ completed: Bool, _ gifPath: URL?) -> Void)? = nil) {
        guard let outputFilePath = self.createOutputFilePath() else {
            DispatchQueue.main.async {
                completionHandler?(false, nil)
            }
            return
        }

        self._outputFilePath = outputFilePath
        self._queue.async {
            guard let destination = CGImageDestinationCreateWithURL(outputFilePath as CFURL, kUTTypeGIF, images.count, nil) else {
                DispatchQueue.main.async {
                    completionHandler?(false, nil)
                }
                return
            }

            let gifProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: loopCount]] as CFDictionary
            let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: delay]] as CFDictionary

            CGImageDestinationSetProperties(destination, gifProperties)
            for image in images {
                if let cgImage = image.cgImage {
                    CGImageDestinationAddImage(destination, cgImage, frameProperties)
                }
            }

            if CGImageDestinationFinalize(destination) {
                DispatchQueue.main.async {
                    completionHandler?(true, self._outputFilePath)
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler?(false, nil)
                }
            }
        }
    }

}
