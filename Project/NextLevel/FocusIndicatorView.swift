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
import Foundation

public class FocusIndicatorView: UIView {
    
    // MARK: - ivars
    
    internal var _focusRingView: UIImageView?
    
    // MARK: - object lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.contentMode = .scaleToFill
        self._focusRingView = UIImageView(image: UIImage(named: "focus_indicator"))
        if let focusRingView = self._focusRingView {
            focusRingView.alpha = 0
            self.addSubview(focusRingView)
        }
        self.frame = self._focusRingView?.frame ?? frame
        
        self.prepareAnimation()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self._focusRingView?.layer.removeAllAnimations()
    }
}

// MARK: - animation

extension FocusIndicatorView {

    internal func prepareAnimation() {
        // prepare animation
        self._focusRingView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        self._focusRingView?.alpha = 0
    }
    
    public func startAnimation() {
        self._focusRingView?.layer.removeAllAnimations()
        
        // animate
        UIView.animate(withDuration: 0.2) { 
            self._focusRingView?.alpha = 1
        }
        UIView.animate(withDuration: 0.5) { 
            self._focusRingView?.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        }
    }
    
    public func stopAnimation() {
        self._focusRingView?.layer.removeAllAnimations()
 
        UIView.animate(withDuration: 0.2) {
            self._focusRingView?.alpha = 0
        }
        UIView.animate(withDuration: 0.2, animations: { 
            self._focusRingView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (completed) in
            if completed {
                self.removeFromSuperview()
            }
        }
    }
    
}
