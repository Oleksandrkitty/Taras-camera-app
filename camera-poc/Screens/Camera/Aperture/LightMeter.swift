//
//  LightMeter.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 16.04.2022.
//

import Foundation
import AVFoundation
import Combine

class LightMeter: ObservableObject {
    private let camera: CameraSDK
    private lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(callback))
        displayLink.preferredFramesPerSecond = 6
        return displayLink
    }()
    
    private(set) var exposureValue = ExposureValue(rawValue: 0) {
        didSet {
            if oldValue != exposureValue {
                update()
            }
        }
    }
    
    private var updating: Bool = false
    
    @Published var exposureStops = ExposureStops(stops: .full)
    
    @Published var aperture: Float = UserDefaults().float(forKey: "aperture") {
        didSet {
            if oldValue != aperture && apertureLock && !updating {
                UserDefaults().setValue(aperture, forKey: "aperture")
            }
            update()
        }
    }
    @Published var apertureLock = UserDefaults().bool(forKey: "apertureLock") {
        didSet {
            if oldValue != apertureLock {
                UserDefaults().setValue(apertureLock, forKey: "apertureLock")
                UserDefaults().setValue(aperture, forKey: "aperture")
            }
            update()
        }
    }
    
    @Published var speed: Float = UserDefaults().float(forKey: "speed") {
        didSet {
            if oldValue != speed && speedLock && !updating {
                UserDefaults().setValue(speed, forKey: "speed")
            }
            update()
        }
    }
    @Published var speedLock = UserDefaults().bool(forKey: "speedLock") {
        didSet {
            if oldValue != speedLock {
                UserDefaults().setValue(speedLock, forKey: "speedLock")
                UserDefaults().setValue(speed, forKey: "speed")
            }
            update()
        }
    }
    
    @Published var iso: Float = UserDefaults().float(forKey: "iso") {
        didSet {
            if oldValue != iso && isoLock && !updating {
                UserDefaults().setValue(iso, forKey: "iso")
            }
            update()
        }
    }
    @Published var isoLock = UserDefaults().bool(forKey: "isoLock") {
        didSet {
            if oldValue != isoLock {
                UserDefaults().setValue(isoLock, forKey: "isoLock")
                UserDefaults().setValue(iso, forKey: "iso")
            }
            update()
        }
    }
    
    init(camera: CameraSDK) {
        self.camera = camera
    }
    
    func startUpdating() {
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func callback(displayLink: CADisplayLink) {
        exposureValue = ExposureValue(aperture: camera.aperture, speed: camera.speed, iso: camera.iso)
    }
    
    private func update() {
        guard !updating else { return }
        updating = true
        
        if isoLock && speedLock && apertureLock {
            //preview mode
            let lockEV = ExposureValue(aperture: aperture, speed: speed, iso: iso)
            let iso = lockEV.iso(withAperture: camera.aperture, speed: speed)
            camera.setCustomExposure(speed: speed, iso: iso)
        } else {
            camera.clearCustomExposure()
            
            if isoLock {
                if speedLock {
                    //s mode
                    aperture = exposureStops.aperture(from: exposureValue.aperture(withSpeed: speed, iso: iso))
                } else if apertureLock {
                    //a mode
                    speed = exposureStops.speed(from: exposureValue.speed(withAperture: aperture, iso: iso))
                } else {
                    //p mode
                    aperture = exposureStops.aperture(from: camera.aperture)
                    speed = exposureStops.speed(from: exposureValue.speed(withAperture: aperture, iso: iso))
                }
            } else if speedLock {
                if !apertureLock {
                    //s mode & iso auto
                    aperture = exposureStops.aperture(from: camera.aperture)
                }
                //iso auto
                iso = exposureStops.iso(from: exposureValue.iso(withAperture: aperture, speed: speed))
            } else if apertureLock {
                //a mode & iso auto
                speed = exposureStops.speed(from: camera.speed)
                iso = exposureStops.iso(from: exposureValue.iso(withAperture: aperture, speed: speed))
            } else {
                //all auto
                aperture = exposureStops.aperture(from: camera.aperture)
                speed = exposureStops.speed(from: camera.speed)
                iso = exposureStops.iso(from: exposureValue.iso(withAperture: aperture, speed: speed))
            }
        }
        updating = false
    }
}
