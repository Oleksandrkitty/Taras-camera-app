//
//  CaptureFormat.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.06.2022.
//

import Foundation

enum CaptureFormat {
    case raw
    case tiff
    case dng
    
    var fileExtension: String {
        switch self {
        case .raw: return "dng"
        case .tiff: return "tiff"
        case .dng: return "dng"
        }
    }
}
