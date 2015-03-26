//
//  NextLevel.swift
//  NextLevel
//
//  Copyright (c) 2015 NextLevel (http://nextlevel.engineering/)
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

import Foundation
import AVFoundation
import MobileCoreServices

// types

public enum AuthorizationStatus: Int {
    case AuthorizationStatusNotDetermined = 0
    case AuthorizationStatusAuthorized
    case AuthorizationStatusAudioDenied
}

public enum CameraDevice: Int {
    case Back = 0
    case Front
}

public enum CameraMode: Int {
    case Photo = 0
    case Video
}

// errors

public let NextLevelErrorDomain = "NextLevelErrorDomain"

public enum NextLevelErrors: Int, Printable {
    case Unknown = -1
    
    public var description: String {
        get {
            switch self {
                case Unknown:
                    return "Unknown"
            }
        }
    }
}

// delegate

public protocol NextLevelDelegate {
}

public class NextLevel: NSObject {
    
    public class var sharedNextLevel: NextLevel {
        struct Singleton {
            static let instance: NextLevel = NextLevel()
        }
        return Singleton.instance
    }
    

    
}
