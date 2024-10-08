//
//  SliderView.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 07.06.2021.
//

import UIKit

protocol SliderViewDelegate: AnyObject {
    func sliderDidChangeValue(_ value: Float)
    func sliderChangedValue(_ value: Float)
}

class SliderView: UIView {
    private lazy var slider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.addTarget(self, action: #selector(sliderDidChangeValue(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderChangedValue(_:)), for: [.touchUpInside, .touchUpOutside])
        slider.tintColor = UIColor.turbo
        return slider
    }()
    
    var isContinuous: Bool = true {
        didSet {
            slider.isContinuous = isContinuous
        }
    }
    weak var delegate: SliderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func set(minValue: Float) {
        slider.minimumValue = minValue
    }
    
    func set(maxValue: Float) {
        slider.maximumValue = maxValue
    }
    
    func set(value: Float) {
        slider.value = value
    }
    
    private func setup() {
        addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        slider.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        slider.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }
    
    @objc private func sliderDidChangeValue(_ slider: UISlider) {
        delegate?.sliderDidChangeValue(slider.value)
    }
    
    @objc private func sliderChangedValue(_ slider: UISlider) {
        delegate?.sliderChangedValue(slider.value)
    }
}
