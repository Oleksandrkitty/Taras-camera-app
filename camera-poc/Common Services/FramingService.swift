//
//  FramingService.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 18.06.2021.
//

import Foundation

enum FrameSize: Int {
    case none = 0
    case iPhoneSeven = 1
    
    var stringValue: String {
        switch self {
            case .none: return "None"
            case .iPhoneSeven: return "iPhone 7"
        }
    }
}

struct FramingService {
    private struct Key {
        static let frameSize = "FrameSizeKey"
    }
    
    private static let userDefautls = UserDefaults.standard
    
    static func set(size: FrameSize) {
        userDefautls.set(size.rawValue, forKey: Key.frameSize)
    }
    
    static func size() -> FrameSize {
        let rawValue = userDefautls.integer(forKey: Key.frameSize)
        return FrameSize(rawValue: rawValue) ?? .none
    }
}
