//
//  UIImage+Luminosity.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 19.04.2022.
//

import UIKit

extension UIImage {
    var luminosity: Double {
        get {
            return self.cgImage?.brightness ?? 0
        }
    }
}

extension CGImage {
    var brightness: Double {
        get {
            let imageData = self.dataProvider?.data
            let ptr = CFDataGetBytePtr(imageData)
            let pixels = self.width * self.height
            let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
            var result: Double = 0
            for y in 0..<self.height {
                for x in 0..<self.width {
                    let offset = (y * self.bytesPerRow) + (x * bytesPerPixel)
                    let r = ptr![offset]
                    let g = ptr![offset + 1]
                    let b = ptr![offset + 2]
                    result += (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                }
            }
            let bright = result / Double (pixels)
            return bright
        }
    }
}
