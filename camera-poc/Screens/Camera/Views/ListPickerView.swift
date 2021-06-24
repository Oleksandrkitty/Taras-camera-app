//
//  ListPickerView.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 14.06.2021.
//

import UIKit

class ListPickerView: UIView {
    private lazy var cancelButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Cancel", for: .normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = 5.0
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    private lazy var completeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.turbo
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Done", for: .normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = 5.0
        button.addTarget(self, action: #selector(complete), for: .touchUpInside)
        return button
    }()
    
    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    var canceled: (() -> ())?
    var completed: ((Int) -> ())?
    
    var values: [String] = [] {
        didSet {
            pickerView.reloadAllComponents()
            pickerView.selectRow(0, inComponent: 0, animated: false)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func select(_ row: Int) {
        pickerView.selectRow(row, inComponent: 0, animated: true)
    }
    
    @objc private func cancel() {
        canceled?()
    }
    
    @objc private func complete() {
        let row = pickerView.selectedRow(inComponent: 0)
        completed?(row)
    }
    
    private func setup() {
        let bottomView = UIStackView(frame: .zero)
        bottomView.axis = .horizontal
        bottomView.distribution = .fillEqually
        bottomView.spacing = 8.0
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        bottomView.addArrangedSubview(cancelButton)
        bottomView.addArrangedSubview(completeButton)
        
        addSubview(pickerView)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        pickerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        pickerView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        
        addSubview(bottomView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        bottomView.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 8).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24).isActive = true
    }
}

extension ListPickerView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return values[row]
    }
}
