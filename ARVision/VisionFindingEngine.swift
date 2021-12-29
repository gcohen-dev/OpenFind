//
//  VisionFindingEngine.swift
//  ARVision
//
//  Created by Zheng on 11/25/21.
//  Copyright © 2021 Andrew. All rights reserved.
//

import UIKit
import Vision

class VisionFindingEngine {
    var startTime: Date?
    
    func fastFind(_ text: [String], in pixelBuffer: CVPixelBuffer, completion: @escaping (([VNRecognizedTextObservation]) -> Void)) {
        let request = VNRecognizeTextRequest { request, _ in
            let observations = self.textFound(request: request)
            completion(observations)
        }
        request.customWords = text
        request.recognitionLevel = .fast
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        startTime = Date()
        do {
            try imageRequestHandler.perform([request])
        } catch {}
    }
}

extension VisionFindingEngine {
    func textFound(request: VNRequest) -> [VNRecognizedTextObservation] {
        guard
            let results = request.results
        else {
            startTime = nil
            return []
        }
        
        let observations = results.compactMap { $0 as? VNRecognizedTextObservation }
        
//        for observation in observations {
//            observation.topCandidates(1)
//        }
        
        startTime = nil
        return observations
    }
}
