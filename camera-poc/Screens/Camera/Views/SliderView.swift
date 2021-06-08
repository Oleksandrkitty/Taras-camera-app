//
//  SliderView.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 07.06.2021.
//

import UIKit

protocol SliderViewDelegate: AnyObject {
    func sliderDidChangedValue(_ value: Float)
}

class SliderView: UIView {
    private lazy var slider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.addTarget(self, action: #selector(sliderDidChangedValue(_:)), for: .valueChanged)
        slider.tintColor = UIColor(red: 254 / 255, green: 212 / 255, blue: 22 / 255, alpha: 1.0)
        return slider
    }()
    
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
    
    @objc private func sliderDidChangedValue(_ slider: UISlider) {
        delegate?.sliderDidChangedValue(slider.value)
    }
}
