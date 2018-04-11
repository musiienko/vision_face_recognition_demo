//
//  FaceShapeLayer.swift
//  VisionFaceRecognitionDemo
//
//  Created by Maksym Musiienko on 4/11/18.
//  Copyright © 2018 Inoxoft. All rights reserved.
//

import UIKit

class FaceShapeLayer: CAShapeLayer {

    convenience init(strokeColor: UIColor?, path: UIBezierPath?) {
        self.init()
        self.strokeColor = strokeColor?.cgColor
        self.path = path?.cgPath
        lineWidth = 2
        fillColor = nil
    }

    static var `default`: FaceShapeLayer {
        let layer = FaceShapeLayer(strokeColor: nil, path: nil)
        layer.setAffineTransform(CGAffineTransform(scaleX: -1, y: -1))
        return layer
    }


    func addBox(with path: UIBezierPath) {
        addSublayer(FaceShapeLayer(strokeColor: .yellow, path: path))
    }

    func addLine(with path: UIBezierPath) {
        addSublayer(FaceShapeLayer(strokeColor: .green, path: path))
    }
}

extension CALayer {

    func removeAllSublayers(exceptFirst count: Int = 0) {
        sublayers?.dropFirst(count).forEach { $0.removeFromSuperlayer() }
    }
}
