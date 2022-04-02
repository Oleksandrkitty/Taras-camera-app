//
//  DistanceMeasure.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.04.2022.
//

import UIKit
import Vision
import AVFoundation

class DistanceMeasure {
    private let box: AVCaptureVideoPreviewLayer
    
    init(box: AVCaptureVideoPreviewLayer) {
        self.box = box
    }
    
    func eyesDistance(in image: CVPixelBuffer) async -> Float {
        let faces = await detectFace(in: image)
        let distances = faces.compactMap { (face: VNFaceObservation) -> Float in
            let boundingBox = box.layerRectConverted(
                fromMetadataOutputRect: face.boundingBox
            )
            if let landmarks = face.landmarks,
               let leftEye = landmarks.leftEye,
               let rightEye = landmarks.rightEye {
                let leftDrawing = drawEye(leftEye, boundingBox: boundingBox)
                let rightDrawing = drawEye(rightEye, boundingBox: boundingBox)
                if let rightMidX = rightDrawing.path?.boundingBox.midX,
                   let leftMidX = leftDrawing.path?.boundingBox.midX {
                    return Float(rightMidX - leftMidX)
                }
            }
            return 0.0
        }
        return distances.first ?? 0.0
    }
    
    private func detectFace(in image: CVPixelBuffer) async -> [VNFaceObservation] {
        return await withCheckedContinuation { continuation in
            let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
                if let results = request.results as? [VNFaceObservation] {
                    continuation.resume(returning: results)
                } else {
                    continuation.resume(returning: [])
                }
            })
            let imageRequestHandler = VNImageRequestHandler(
                cvPixelBuffer: image,
                orientation: .leftMirrored,
                options: [:]
            )
            try? imageRequestHandler.perform([faceDetectionRequest])
        }
    }
    
    private func drawEye(_ eye: VNFaceLandmarkRegion2D, boundingBox: CGRect) -> CAShapeLayer {
        let eyePath = CGMutablePath()
        let eyePathPoints = eye.normalizedPoints.map { eyePoint in
            CGPoint(
                x: eyePoint.y * boundingBox.height + boundingBox.origin.x,
                y: eyePoint.x * boundingBox.width + boundingBox.origin.y
            )
        }
        eyePath.addLines(between: eyePathPoints)
        eyePath.closeSubpath()
        let eyeDrawing = CAShapeLayer()
        eyeDrawing.path = eyePath
        eyeDrawing.fillColor = UIColor.clear.cgColor
        eyeDrawing.strokeColor = UIColor.green.cgColor
        
        return eyeDrawing
    }
}

