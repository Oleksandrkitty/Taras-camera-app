//
//  CameraViewController.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

class CameraViewController: UIViewController {
    @IBOutlet private weak var containerView: CameraPreviewView!
    @IBOutlet private weak var captureButton: UIButton!
    @IBOutlet private weak var flashView: UIView!
    @IBOutlet private weak var seriesLabel: UILabel!
    @IBOutlet private weak var pickerView: UIView!
    @IBOutlet private weak var pickerViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction private func cancelButtonPressed(_ button: UIButton) {
       //TODO: dismiss screen here
    }
    
    @IBAction private func cameraButtonPressed(_ button: UIButton) {
        viewModel.capture()
    }
    
    @IBAction private func isoButtonPressed(_ button: UIButton) {
        viewModel.selectISO()
    }
    
    @IBAction private func exposureButtonPressed(_ button: UIButton) {
        viewModel.selectExposure()
    }
    
    @IBAction private func shutterSpeedButtonPressed(_ button: UIButton) {
        viewModel.selectShutterSpeed()
    }
    
    @IBAction private func whiteBalanceButtonPressed(_ button: UIButton) {
        viewModel.selectWhiteBalance()
    }
    
    @IBAction private func usvButtonPressed(_ button: UIButton) {
        viewModel.selectUSV()
    }
    
    private lazy var usvPicker: UIView = {
        let picker = USVPickerView(frame: .zero)
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = self
        return picker
    }()
    
    private lazy var slider: SliderView = {
        let slider = SliderView(frame: .zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.delegate = self
        return slider
    }()
    
    var viewModel: CameraVM! {
        didSet {
            viewModel.isFlashEnabled.bind { [unowned self] isEnabled in
                if isEnabled {
                    self.flashView.isHidden = false
                } else {
                    UIView.animate(withDuration: 0.1) {
                        self.flashView.isHidden = true
                    }
                }
            }
            viewModel.seriesString.bind { [unowned self] string in
                self.seriesLabel.text = string
            }
            viewModel.isSliderEnabled.bind { [unowned self] isEnabled in
                self.slider.isHidden = !isEnabled
            }
            viewModel.isUSVPickerEnabled.bind { [unowned self] isEnabled in
                self.usvPicker.isHidden = !isEnabled
            }
            viewModel.sliderMinValue.bind { [unowned self] value in
                self.slider.set(minValue: value)
            }
            viewModel.sliderMaxValue.bind { [unowned self] value in
                self.slider.set(maxValue: value)
            }
            viewModel.sliderCurrentValue.bind { [unowned self] value in
                self.slider.set(value: value)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.addSubview(usvPicker)
        usvPicker.leftAnchor.constraint(equalTo: pickerView.leftAnchor, constant: 0).isActive = true
        usvPicker.rightAnchor.constraint(equalTo: pickerView.rightAnchor, constant: 0).isActive = true
        usvPicker.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 0).isActive = true
        usvPicker.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 0).isActive = true
        
        pickerView.addSubview(slider)
        slider.leftAnchor.constraint(equalTo: pickerView.leftAnchor, constant: 0).isActive = true
        slider.rightAnchor.constraint(equalTo: pickerView.rightAnchor, constant: 0).isActive = true
        slider.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 0).isActive = true
        slider.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 0).isActive = true
        
        usvPicker.isHidden = true
        slider.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        containerView.videoPreviewLayer.session = viewModel.captureSession
        containerView.videoPreviewLayer.videoGravity = .resizeAspectFill
        viewModel.requestCameraAccess()
    }
}

extension CameraViewController: USVPickerViewDelegate {
    func pickerDidSelectLowLight() {
        viewModel.change(series: Low)
    }
    
    func pickerDidSelectMediumLight() {
        viewModel.change(series: Medium)
    }
    
    func pickerDidSelectHighLight() {
        viewModel.change(series: High)
    }
}

extension CameraViewController: SliderViewDelegate {
    func sliderDidChangedValue(_ value: Float) {
        viewModel.change(value: value)
    }
}
