//
//  WhiteBalanceSliderView.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 07.06.2021.
//

import UIKit

protocol WhiteBalanceSliderViewDelegate: AnyObject {
    func tintValueDidChanged(_ value: Float)
    func temperatureValueDidChanged(_ value: Float)
}

class WhiteBalanceSliderView: UIView {
    private lazy var tintSlider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.addTarget(self, action: #selector(tintValueDidChanged), for: .valueChanged)
        slider.tintColor = .yellow
        slider.tintColor = UIColor(red: 254 / 255, green: 212 / 255, blue: 22 / 255, alpha: 1.0)
        return slider
    }()
    
    private lazy var temperatureSlider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.addTarget(self, action: #selector(temperatureValueDidChanged), for: .valueChanged)
        slider.tintColor = .blue
        slider.tintColor = UIColor(red: 254 / 255, green: 212 / 255, blue: 22 / 255, alpha: 1.0)
        return slider
    }()
    
    weak var delegate: WhiteBalanceSliderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func set(minTint: Float) {
        tintSlider.minimumValue = minTint
    }
    
    func set(maxTint: Float) {
        tintSlider.maximumValue = maxTint
    }
    
    func set(tint: Float) {
        tintSlider.value = tint
    }
    
    func set(minTemperature: Float) {
        temperatureSlider.minimumValue = minTemperature
    }
    
    func set(maxTemperature: Float) {
        temperatureSlider.maximumValue = maxTemperature
    }
    
    func set(temperature: Float) {
        temperatureSlider.value = temperature
    }
    
    @objc private func tintValueDidChanged() {
        delegate?.tintValueDidChanged(tintSlider.value)
    }
    
    @objc private func temperatureValueDidChanged() {
        delegate?.temperatureValueDidChanged(temperatureSlider.value)
    }
    
    private func setup() {
        let container = UIStackView(frame: .zero)
        container.axis = .vertical
        container.distribution = .fillEqually
        container.spacing = 0.0
        
        let tintLabel = UILabel(frame: .zero)
        tintLabel.text = "Tint"
        tintLabel.textColor = .white
        tintLabel.font = UIFont.systemFont(ofSize: 10)
        let temperatureLabel = UILabel(frame: .zero)
        temperatureLabel.text = "Temperature"
        temperatureLabel.font = UIFont.systemFont(ofSize: 10)
        temperatureLabel.textColor = .white
        
        let tintVStack = UIStackView(arrangedSubviews: [tintLabel, tintSlider])
        tintVStack.spacing = 0.0
        tintVStack.axis = .vertical
        let temperaturVStack = UIStackView(arrangedSubviews: [temperatureLabel, temperatureSlider])
        temperaturVStack.spacing = 0.0
        temperaturVStack.axis = .vertical
        container.addArrangedSubview(tintVStack)
        container.addArrangedSubview(temperaturVStack)
        
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        container.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        container.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }
}
