//
//  Extensions.swift
//  VisionFaceRecognitionDemo
//
//  Created by Maksym Musiienko on 4/11/18.
//  Copyright © 2018 Inoxoft. All rights reserved.
//

import DelaunaySwift

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

extension Triangle {
    func toPath() -> UIBezierPath {

        let path = UIBezierPath()
        let point1 = vertex1.pointValue()
        let point2 = vertex2.pointValue()
        let point3 = vertex3.pointValue()

        path.move(to: point1)
        path.addLine(to: point2)
        path.addLine(to: point3)
        path.addLine(to: point1)

        path.close()

        return path
    }
}

extension Vertex {
    func pointValue() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
}
