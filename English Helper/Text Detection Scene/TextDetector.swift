//
//  TextDetector.swift
//  English Helper
//
//  Created by Матвей Анисович on 24.09.2020.
//  Copyright © 2020 Матвей Анисович. All rights reserved.
//

import UIKit
import Vision

@available(iOS 13.0, *)
class TextDetector: NSObject {
    ///A class that detects texts
    func detectTexts(on image: UIImage, with recognitionLevel:VNRequestTextRecognitionLevel, customImageSize: CGSize?) -> [TextDetection] {
        var detections:[TextDetection] = []
        
        let requestHandler = VNImageRequestHandler(data: image.pngData()!, orientation: .right, options: [:])
        let textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            for observation in observations {
                detections.append(TextDetection(observation: observation, imageSize: customImageSize ?? image.size))
            }
        }
        textRecognitionRequest.recognitionLevel = recognitionLevel
        textRecognitionRequest.recognitionLanguages = ["en-UK"]
        textRecognitionRequest.usesLanguageCorrection = true
        try? requestHandler.perform([textRecognitionRequest])
        
        return detections
        
        
    }
}

@available(iOS 13.0, *)
class TextDetection: NSObject,NSCopying {
    ///A class that describes text detection
    var textObservation: VNRecognizedTextObservation!
    private var topCandidate:[VNRecognizedText]!
    var text:String = ""
    var imageSize:CGSize!
    
    var topLeft:CGPoint!
    var bottomLeft:CGPoint!
    var bottomRight:CGPoint!
    var topRight:CGPoint!
    var observationPath:UIBezierPath!
    var isSelected = false
    
    init(observation:VNRecognizedTextObservation, imageSize:CGSize) {
        self.imageSize = imageSize
        textObservation = observation
        topCandidate  = textObservation.topCandidates(1)
        if let recognizedText: VNRecognizedText = topCandidate.first {
            text = recognizedText.string
        }
        let transform = CGAffineTransform.identity
            .scaledBy(x: 1, y: -1)
            .translatedBy(x: 0, y: -imageSize.height * 1)
            .scaledBy(x: imageSize.width * 1, y: imageSize.height * 1)
        
        topLeft = observation.topLeft.applying(transform)
        bottomRight = observation.bottomRight.applying(transform)
        topRight = observation.topRight.applying(transform)
        bottomLeft = observation.bottomLeft.applying(transform)
        
        observationPath = UIBezierPath()
        observationPath.move(to: topLeft)
        observationPath.addLine(to: topRight)
        observationPath.addLine(to: bottomRight)
        observationPath.addLine(to: bottomLeft)
        observationPath.addLine(to: topLeft)
    }
    override var description:String {
        return "\(text)"
    }
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TextDetection(observation: textObservation, imageSize: imageSize)
        return copy
    }
}

