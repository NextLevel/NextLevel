//
//  NextLevel.swift
//  NextLevel
//
//  Copyright (c) 2015-present NextLevel (http://nextlevel.engineering/)
//
//  Simon Corsin and Patrick Piemonte
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

import Foundation
import AVFoundation
import MobileCoreServices

// MARK: - types

public enum AuthorizationStatus: Int, CustomStringConvertible {
    case NotDetermined = 0
    case Authorized
    case AudioNotAuthorized
    
    public var description: String {
        get {
            switch self {
            case NotDetermined:
                return "Not Determined"
            case Authorized:
                return "Authorized"
            case AudioNotAuthorized:
                return "Audio Not Authorized"
            }
        }
    }
}

public enum CameraDevice: Int, CustomStringConvertible {
    case Back = 0
    case Front
    
    public var description: String {
        get {
            switch self {
            case Back:
                return "Back"
            case Front:
                return "Front"
            }
        }
    }
}

public enum CameraMode: Int, CustomStringConvertible {
    case Photo = 0
    case Video
    
    public var description: String {
        get {
            switch self {
            case Photo:
                return "Photo"
            case Video:
                return "Video"
            }
        }
    }
}

// MARK: - errors

public let NextLevelErrorDomain = "NextLevelErrorDomain"

public enum NextLevelErrors: Int, CustomStringConvertible {
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

// MARK: - delegate

public protocol NextLevelDelegate: NSObjectProtocol {

    // permission
    func nextLevel(nextLevel: NextLevel, didChangeAuthorizationStatus status: AuthorizationStatus)
    
    // session
    
    // device, mode, format
    
    // focus, exposure
    
    // preview
    
    // photo
    
    // video
    
}

public class NextLevel: NSObject {
    
    // MARK: - singleton

    static let sharedPosition: NextLevel = NextLevel()

    // MARK: - object lifecycle
    
    override init() {
    
        super.init()
    }
    
}
