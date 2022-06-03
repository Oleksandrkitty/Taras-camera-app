//
//  CaptureParams.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.06.2022.
//

import Foundation
import UIKit

struct CaptureParams {
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        return dateFormatter
    }()
    
    let title: String
    let iso: Float
    let exposure: Float
    let aperture: Float
    let tint: Float
    let temperature: Float
    let brightness: Float
    let distance: Int
    
    func makeFileName() -> String {
        let values: [String] = [
            UIDevice.modelName,
            self.dateFormatter.string(from: Date()),
            "ISO: \("A_\(Int(iso))")",
            "Exp: \(speedToString(exposure, divider: "%"))",
            "F:\(apertureToString(aperture))",
            "Tint: \(Int(tint))",
            "Temperature: \(Int(temperature))",
            "Frame: \(title)",
            "Light: \(Int(brightness * 100))%",
            "Distance: \(distance)cm"
        ]
        return values.joined(separator: "_")
    }
}

func speedToString(_ speed: Float, divider: String = "/") -> String {
    if speed >= 1.0 {
        return String(Int(speed)) + "\""
    }
    return "1\(divider)" + String(Int(round(1 / speed)))
}

func apertureToString(_ aperture: Float) -> String {
    return String(format: "F%.1f", aperture)
}
