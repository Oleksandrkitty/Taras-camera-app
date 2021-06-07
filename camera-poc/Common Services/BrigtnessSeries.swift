//
//  BrigtnessSeries.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 07.06.2021.
//

import Foundation
import UIKit

struct BrigtnessSeries {
    let min: CGFloat
    let max: CGFloat
    let step: CGFloat
}

let Low = BrigtnessSeries(min: 10, max: 40, step: 0.05)
let Medium = BrigtnessSeries(min: 45, max: 70, step: 0.05)
let High = BrigtnessSeries(min: 75, max: 100, step: 0.05)
