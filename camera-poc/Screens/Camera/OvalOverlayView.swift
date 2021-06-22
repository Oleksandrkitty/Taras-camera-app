//
//  OvalOverlayView.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 11.06.2021.
//

import UIKit

class OvalOverlayView: UIView {
    private var overlayFrame: CGRect!
    private let width: CGFloat = 185
    private let height: CGFloat = 265

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        overlayFrame = CGRect(x: (frame.width - width) / 2,
                              y: 80,
                              width: width,
                              height: height)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ rect: CGRect) {
        let overlayPath = UIBezierPath(rect: bounds)
        let ovalPath = UIBezierPath(ovalIn: overlayFrame)
        overlayPath.append(ovalPath)
        overlayPath.usesEvenOddFillRule = true

        let ovalLayer = CAShapeLayer()
        ovalLayer.path = ovalPath.cgPath
        ovalLayer.fillColor = UIColor.clear.cgColor
        ovalLayer.strokeColor = UIColor.white.cgColor
        ovalLayer.lineWidth = 5.0
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = overlayPath.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.fillColor = UIColor.white.withAlphaComponent(0.0).cgColor
        
        layer.addSublayer(fillLayer)
        layer.addSublayer(ovalLayer)
    }

}
