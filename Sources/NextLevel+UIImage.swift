//
//  NextLevel+UIImage.swift
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

extension UIImage {

    //  via by BrikerMan on 2017/12/23.

    /// EZSE: Returns cropped image from CGRect
    public func nx_croppedImage(to ratio: CGFloat) -> UIImage {
        let height = self.size.width * ratio
        let y = (self.size.height - height) / 2

        let bound = CGRect(x: 0, y: y, width: self.size.width, height: height)
        let scaledBounds: CGRect = CGRect(x: bound.origin.x * self.scale,
                                          y: bound.origin.y * self.scale,
                                          width: bound.width * self.scale,
                                          height: bound.height * self.scale)
        let imageRef = self.cgImage?.cropping(to: scaledBounds)

        let croppedImage: UIImage = UIImage(cgImage: imageRef!, scale: self.scale, orientation: UIImage.Orientation.up)
        return croppedImage
    }

}
