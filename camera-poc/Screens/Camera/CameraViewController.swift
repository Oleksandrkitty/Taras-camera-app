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
    @IBOutlet private weak var pickerView: UIView!
    @IBOutlet private weak var pickerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var controlsView: UIView!
    
    @IBOutlet private weak var isoValueLabel: UILabel!
    @IBOutlet private weak var exposureValueLabel: UILabel!
    @IBOutlet private weak var whiteBalanceValueLabel: UILabel!
    @IBOutlet private weak var usvValueLabel: UILabel!
    @IBOutlet private weak var lightLabel: UILabel!
    @IBOutlet private weak var singleShootSwitch: UISwitch!
    @IBOutlet private weak var darkModeSwitch: UISwitch!
    @IBOutlet private weak var panelSwitch: UISwitch!
    @IBOutlet private weak var lightView: UIView!
    @IBOutlet private weak var lightPickerContainerView: UIView! {
        didSet {
            lightPickerContainerView.isHidden = true
            lightPickerContainerView.clipsToBounds = true
            lightPickerContainerView.layer.cornerRadius = 10.0
        }
    }
    @IBOutlet private weak var deviceFamilyLabel: UILabel!
    
    @IBOutlet private weak var singleLabel: UILabel!
    @IBOutlet private weak var darkModeLabel: UILabel!
    @IBOutlet private weak var panelLabel: UILabel!
    @IBOutlet private weak var contolsStackView: UIStackView!
    @IBOutlet private weak var frameView: UIView!
    @IBOutlet private weak var captureFormatView: UIView!
    @IBOutlet private weak var captureFormatSegmentControl: UISegmentedControl!
    
    @IBOutlet private weak var lightPickerContainerViewBottomConstraint: NSLayoutConstraint! {
        didSet {
            lightPickerContainerViewBottomConstraint.constant = -300
        }
    }
    @IBOutlet private weak var flashWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var flashHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var luminosityLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var apertureLabel: UILabel!
    @IBOutlet private weak var lockISOSwitch: UISwitch!
    @IBOutlet private weak var lockExposureSwitch: UISwitch!
    @IBOutlet private weak var lockApertureSwitch: UISwitch!
    
    @IBAction private func cameraButtonPressed(_ button: UIButton) {
        viewModel.capture()
    }
    
    @IBAction private func isoButtonPressed(_ button: UIButton) {
        viewModel.selectISO()
    }
    
    @IBAction private func exposureButtonPressed(_ button: UIButton) {
        viewModel.selectExposure()
    }
    
    @IBAction private func apertureButtonPressed(_ button: UIButton) {
        viewModel.selectAperture()
    }
    
    @IBAction private func lockISOValueChanged(_ sender: UISwitch) {
        viewModel.hideSliders()
        viewModel.lightMeter.isoLock = !sender.isOn
    }
    
    @IBAction private func lockExposureValueChanged(_ sender: UISwitch) {
        viewModel.hideSliders()
        viewModel.lightMeter.speedLock = !sender.isOn
    }
    
    @IBAction private func lockApertureValueChanged(_ sender: UISwitch) {
        viewModel.hideSliders()
        viewModel.lightMeter.apertureLock = !sender.isOn
    }
    
    @IBAction private func whiteBalanceButtonPressed(_ button: UIButton) {
        viewModel.selectWhiteBalance()
    }
    
    @IBAction private func usvButtonPressed(_ button: UIButton) {
        viewModel.selectUSV()
    }
    
    @IBAction private func resetButtonPressed(_ button: UIButton) {
        viewModel.reset()
    }
    
    @IBAction private func signleShootValueChanged(_ sender: UISwitch) {
        viewModel.setSingleShootEnabled(sender.isOn)
    }
    
    @IBAction private func darkModeValueChanged(_ sender: UISwitch) {
        viewModel.setDarkModeEnabled(sender.isOn)
    }
    
    @IBAction private func panelValueChanged(_ sender: UISwitch) {
        changeElementsVisibility()
    }
    
    @IBAction private func lightButtonPressed(_ button: UIButton) {
        viewModel.changeLight()
    }
    
    @IBAction private func deviceFamilyButtonPressed(_ button: UIButton) {
        viewModel.presentFamilyDevicePicker()
    }
    
    @IBAction private func calibrateButtonPressed(_ button: UIButton) {
        viewModel.calibrateCamera()
    }
    
    @IBAction private func captureFormatChanged(_ segment: UISegmentedControl) {
        viewModel.changeCaptureFormat(segment.selectedSegmentIndex == 0 ? .tiff : .raw)
    }
    
    private lazy var ovalOverlayView = OvalOverlayView(frame: containerView.bounds)
    
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
    
    private lazy var wbSlider: WhiteBalanceSliderView = {
        let slider = WhiteBalanceSliderView(frame: .zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.delegate = self
        return slider
    }()
    
    private lazy var listPickerView: ListPickerView = {
        let view = ListPickerView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
            viewModel.isSliderEnabled.bind { [unowned self] isEnabled in
                self.slider.isHidden = !isEnabled
                self.pickerViewHeightConstraint.constant = isEnabled ? 50.0 : 0
            }
            viewModel.isUSVPickerEnabled.bind { [unowned self] isEnabled in
                self.usvPicker.isHidden = !isEnabled
                self.pickerViewHeightConstraint.constant = isEnabled ? 50.0 : 0
            }
            viewModel.isWhiteBalanceSliderEnabled.bind { [unowned self] isEnabled in
                self.wbSlider.isHidden = !isEnabled
                self.pickerViewHeightConstraint.constant = isEnabled ? 100.0 : 0
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
            viewModel.tintMinValue.bind { [unowned self] value in
                self.wbSlider.set(minTint: value)
            }
            viewModel.tintMaxValue.bind { [unowned self] value in
                self.wbSlider.set(maxTint: value)
            }
            viewModel.tintValue.bind { [unowned self] value in
                self.wbSlider.set(tint: value)
            }
            viewModel.tintLabel.bind { [unowned self] value in
                self.wbSlider.tint = value
            }
            viewModel.temperatureMinValue.bind { [unowned self] value in
                self.wbSlider.set(minTemperature: value)
            }
            viewModel.temperatureMaxValue.bind { [unowned self] value in
                self.wbSlider.set(maxTemperature: value)
            }
            viewModel.temperatureValue.bind { [unowned self] value in
                self.wbSlider.set(temperature: value)
            }
            viewModel.temperatureLabel.bind { [unowned self] value in
                self.wbSlider.temperature = value
            }
            viewModel.isoValue.bind { [unowned self] value in
                self.isoValueLabel.text = value
            }
            viewModel.exposureValue.bind { [unowned self] value in
                self.exposureValueLabel.text = value
            }
            viewModel.apertureValue.bind { [unowned self] value in
                self.apertureLabel.text = value
            }
            viewModel.wbValue.bind { [unowned self] value in
                self.whiteBalanceValueLabel.text = value
            }
            viewModel.usvValue.bind { [unowned self] value in
                self.usvValueLabel.text = value
            }
            viewModel.isCaptureEnabled.bind { [unowned self] isEnabled in
                self.captureButton.isUserInteractionEnabled = isEnabled
            }
            viewModel.usvPercents.bind { [unowned self] value in
                DispatchQueue.main.async {
                    self.captureButton.setTitle(value, for: .normal)
                    self.lightLabel.text = value
                }
            }
            viewModel.isSingleShootEnabled.bind { [unowned self] isEnabled in
                self.singleShootSwitch.isOn = isEnabled
                UIView.animate(withDuration: 0.3) {
                    self.lightView.isHidden = !isEnabled
                }
            }
            viewModel.isDarkModeEnabled.bind { [unowned self] isEnabled in
                self.darkModeSwitch.isOn = isEnabled
            }
            viewModel.frameSize.bind { [unowned self] size in
                self.deviceFamilyLabel.text = size.stringValue
                switch size {
                case .none:
                    self.flashWidthConstraint.constant = UIScreen.main.bounds.width
                    self.flashHeightConstraint.constant = UIScreen.main.bounds.height
                case .iPhoneSeven:
                    self.flashWidthConstraint.constant = iPhoneSevenSizeInInches.width * (UIScreen.pointsPerInch ?? 0)
                    self.flashHeightConstraint.constant = iPhoneSevenSizeInInches.height * (UIScreen.pointsPerInch ?? 0)
                    print("width \(self.flashWidthConstraint.constant)")
                    print("height \(self.flashHeightConstraint.constant)")
                }
                self.view.layoutIfNeeded()
                //display example flashing
                self.flashView.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.flashView.isHidden = true
                }
            }
            viewModel.distance.bind { [unowned self] distance in
                self.distanceLabel.text = "\(distance)cm"
            }
            viewModel.luminosity.bind { [unowned self] luminosity in
                self.luminosityLabel.text = "\(luminosity)"
            }
        }
    }
    
    private var isInitialized: Bool = false
    
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
        
        pickerView.addSubview(wbSlider)
        wbSlider.leftAnchor.constraint(equalTo: pickerView.leftAnchor, constant: 0).isActive = true
        wbSlider.rightAnchor.constraint(equalTo: pickerView.rightAnchor, constant: 0).isActive = true
        wbSlider.topAnchor.constraint(equalTo: pickerView.topAnchor, constant: 0).isActive = true
        wbSlider.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 0).isActive = true
        
        usvPicker.isHidden = true
        slider.isHidden = true
        wbSlider.isHidden = true
        pickerViewHeightConstraint.constant = 0
        captureButton.setTitle(viewModel.usvPercents.value, for: .normal)
        singleShootSwitch.isOn = viewModel.isSingleShootEnabled.value
        darkModeSwitch.isOn = viewModel.isDarkModeEnabled.value
        lightView.isHidden = !viewModel.isSingleShootEnabled.value
        lockISOSwitch.isOn = !viewModel.lightMeter.isoLock
        lockExposureSwitch.isOn = !viewModel.lightMeter.speedLock
        lockApertureSwitch.isOn = !viewModel.lightMeter.apertureLock
        
        lightPickerContainerView.addSubview(listPickerView)
        listPickerView.leftAnchor.constraint(equalTo: lightPickerContainerView.leftAnchor, constant: 0).isActive = true
        listPickerView.rightAnchor.constraint(equalTo: lightPickerContainerView.rightAnchor, constant: 0).isActive = true
        listPickerView.topAnchor.constraint(equalTo: lightPickerContainerView.topAnchor, constant: 0).isActive = true
        listPickerView.bottomAnchor.constraint(equalTo: lightPickerContainerView.bottomAnchor, constant: 0).isActive = true
        
        deviceFamilyLabel.text = viewModel.frameSize.value.stringValue
        switch viewModel.frameSize.value {
        case .none:
            flashWidthConstraint.constant = UIScreen.main.bounds.width
            flashHeightConstraint.constant = UIScreen.main.bounds.height
        case .iPhoneSeven:
            self.flashWidthConstraint.constant = iPhoneSevenSizeInInches.width * (UIScreen.pointsPerInch ?? 0)
            self.flashHeightConstraint.constant = iPhoneSevenSizeInInches.height * (UIScreen.pointsPerInch ?? 0)
        }
        let segmentIndex = viewModel.captureFormat == .tiff ? 0 : 1
        captureFormatSegmentControl.selectedSegmentIndex = segmentIndex
        changeElementsVisibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isInitialized {
            viewModel.continueCamera()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isInitialized {
            containerView.videoPreviewLayer.frame = containerView.frame
            viewModel.requestCameraAccess(containerView.videoPreviewLayer)
            containerView.addSubview(ovalOverlayView)
            isInitialized = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.pauseCamera()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func presentLightPicker(values: [Float]) {
        lightPickerContainerView.isHidden = false
        lightPickerContainerViewBottomConstraint.constant = 0
        listPickerView.values = values.map { "\(Int($0))%" }
        listPickerView.canceled = { [unowned self] in
            self.hidePicker()
        }
        listPickerView.completed = { [unowned self] index in
            self.hidePicker()
            self.viewModel.change(brightness: values[index])
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func presentFamilyDevicePicker() {
        lightPickerContainerView.isHidden = false
        lightPickerContainerViewBottomConstraint.constant = 0
        let values: [FrameSize] = [.none, .iPhoneSeven]
        let index = FramingService.size().rawValue
        listPickerView.values = values.map { $0.stringValue }
        listPickerView.canceled = { [unowned self] in
            self.hidePicker()
        }
        listPickerView.completed = { [unowned self] index in
            self.hidePicker()
            self.viewModel.change(size: values[index])
        }
        listPickerView.select(index)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func hidePicker() {
        lightPickerContainerViewBottomConstraint.constant = -300
        self.lightPickerContainerView.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func changeElementsVisibility() {
        contolsStackView.isHidden = !panelSwitch.isOn
        frameView.isHidden = !panelSwitch.isOn
        singleLabel.isHidden = !panelSwitch.isOn
        darkModeLabel.isHidden = !panelSwitch.isOn
        singleShootSwitch.isHidden = !panelSwitch.isOn
        darkModeSwitch.isHidden = !panelSwitch.isOn
        frameView.isHidden = !panelSwitch.isOn
        captureFormatView.isHidden = !viewModel.isCaptureFormatSelectionEnabled
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
    func sliderDidChangeValue(_ value: Float) {
        viewModel.update(value: value)
    }
    
    func sliderChangedValue(_ value: Float) {
        viewModel.change(value: value)
    }
}

extension CameraViewController: WhiteBalanceSliderViewDelegate {
    func tintValueDidChanged(_ value: Float) {
        viewModel.change(tint: value)
    }
    
    func temperatureValueDidChanged(_ value: Float) {
        viewModel.change(temperature: value)
    }
}
