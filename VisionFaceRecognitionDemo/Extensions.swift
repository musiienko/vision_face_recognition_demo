//
//  Extensions.swift
//  VisionFaceRecognitionDemo
//
//  Created by Maksym Musiienko on 4/11/18.
//  Copyright © 2018 Inoxoft. All rights reserved.
//

import CoreGraphics

extension CGRect {

    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}

extension CGPoint {

    func scaled(with rect: CGRect) -> CGPoint {
        let x = self.x * rect.width + rect.origin.x
        let y = self.y * rect.height + rect.origin.y
        return CGPoint(x: x, y: y)
    }
}
