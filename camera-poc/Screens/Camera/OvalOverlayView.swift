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
    private var color: UIColor = UIColor.white.withAlphaComponent(0.0)

    var frameColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }

    init(frame: CGRect, topSpace: CGFloat, backgroundColor: UIColor) {
        super.init(frame: frame)
        self.color = backgroundColor
        setup(topSpace: topSpace)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup(topSpace: CGFloat = 80.0) {
        backgroundColor = UIColor.clear
        overlayFrame = CGRect(x: (frame.width - width) / 2,
                              y: topSpace,
                              width: width,
                              height: height)
    }

    override func draw(_ rect: CGRect) {
        let overlayPath = UIBezierPath(rect: bounds)
        let ovalPath = UIBezierPath(ovalIn: overlayFrame)
        overlayPath.append(ovalPath)
        overlayPath.usesEvenOddFillRule = true

        let ovalLayer = CAShapeLayer()
        ovalLayer.path = ovalPath.cgPath
        ovalLayer.fillColor = UIColor.clear.cgColor
        ovalLayer.strokeColor = frameColor.cgColor
        ovalLayer.lineWidth = 5.0
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = overlayPath.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.fillColor = color.cgColor
        
        layer.addSublayer(fillLayer)
        layer.addSublayer(ovalLayer)
    }
}
