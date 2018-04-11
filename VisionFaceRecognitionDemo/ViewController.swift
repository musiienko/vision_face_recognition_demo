//
//  ViewController.swift
//  VisionFaceRecognitionDemo
//
//  Created by Maksym Musiienko on 4/11/18.
//  Copyright © 2018 Inoxoft. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import DelaunaySwift

class ViewController: UIViewController {

    enum ViewType: String {
        case face, triangle
    }

    @IBOutlet private weak var fpsLabel: UILabel!
    @IBOutlet private weak var typeButton: UIButton!

    private let requestHandler = VNSequenceRequestHandler()
    private let faceBoxLayer = FaceShapeLayer.default

    private lazy var cameraService = CameraService(in: view, delegate: self)!
    private lazy var landmarksRequest: VNDetectFaceLandmarksRequest = {
        return VNDetectFaceLandmarksRequest { [weak self] (request, error) in
            DispatchQueue.main.async { self?.handle(request: request, error: error) }
        }
    }()

    private var fps = 0

    private var type = ViewType.face

    private var faceRect: CGRect = .zero {
        didSet {
            guard faceRect != .zero else { return }
            drawFacesBox()
        }
    }

    private var landmarks: VNFaceLandmarks2D! {
        didSet {
            guard faceRect != .zero else { return }
            switch type {
            case .face:
                drawFaceLandmarks()
            case .triangle:
                drawTriangles()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.addSublayer(faceBoxLayer)
        cameraService.start()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateFPS()
        }
        configureButton()
    }

    private func configureButton() {
        typeButton.setTitle(type.rawValue.capitalized, for: .normal)
    }

    @IBAction private func switchType() {
        switch type {
        case .face: type = .triangle
        case .triangle: type = .face
        }
        configureButton()
    }

    private func updateFPS() {
        fpsLabel.text = "\(fps) FPS"
        fps = 0
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        faceBoxLayer.frame = view.bounds
    }

    private func handle(request: VNRequest, error: Error?) {
        if let error = error {
            print(error)
            return
        }

        guard let observation = request.results?.first as? VNFaceObservation else {
            faceRect = .zero
            landmarks = nil
            return
        }

        faceRect = observation.boundingBox.scaled(to: view.bounds.size)
        landmarks = observation.landmarks
    }
}

extension ViewController {

    private func drawFacesBox() {
        faceBoxLayer.removeAllSublayers()
        faceBoxLayer.addBox(with: UIBezierPath(rect: faceRect))
    }

    private func drawTriangles() {
        faceBoxLayer.removeAllSublayers(exceptFirst: 1) // leaving box
        guard
            let points = self.landmarks.allPoints?.normalizedPoints.map ({ $0.scaled(with: faceRect) }),
            !points.isEmpty
        else {
            return
        }

        let vertexs = points.map { Vertex(x: Double($0.x), y: Double($0.y)) }.dropLast()
        let triangles = Delaunay().triangulate(Array(vertexs))
        let paths = triangles.map { $0.toPath() }
        paths.forEach { faceBoxLayer.addLine(with: $0) }
    }

    private func drawFaceLandmarks() {
        faceBoxLayer.removeAllSublayers(exceptFirst: 1)
        guard let landmarks = self.landmarks else {
            return
        }

        if let face = landmarks.faceContour { draw(region: face) }

        // eyes
        if let leftEye = landmarks.leftEye { draw(region: leftEye, isClosed: true) }
        if let rightEye = landmarks.rightEye { draw(region: rightEye, isClosed: true) }

        // eye pupils
//        if let leftPupil = landmarks.leftPupil { draw(region: leftPupil, isClosed: true) }
//        if let rightPupil = landmarks.rightPupil { draw(region: rightPupil, isClosed: true) }

        // eyebrows
        if let leftEyebrow = landmarks.leftEyebrow { draw(region: leftEyebrow) }
        if let rightEyebrow = landmarks.rightEyebrow { draw(region: rightEyebrow) }

        // nose
        if let nose = landmarks.nose { draw(region: nose) }
//        if let noseCrest = landmarks.noseCrest { draw(region: noseCrest) }
//        if let medianLine = landmarks.medianLine { draw(region: medianLine)}

        // lips
        if let outerLips = landmarks.outerLips { draw(region: outerLips, isClosed: true) }
//        if let innerLips = landmarks.innerLips { draw(region: innerLips, isClosed: true) }
    }

    private func draw(region: VNFaceLandmarkRegion2D, isClosed: Bool = false) {
        let points = region.normalizedPoints.map { $0.scaled(with: faceRect) }
        guard !points.isEmpty else { return }
        let path = UIBezierPath()
        path.move(to: points.first!)
        points.dropFirst().forEach(path.addLine)

        if isClosed {
            path.close()
        }
        faceBoxLayer.addLine(with: path)
    }
}

extension ViewController: CameraServiceDelegate {

    func cameraService(_ cameraService: CameraService, didOutput sampleBuffer: CMSampleBuffer) {
        fps += 1
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)

        let image = CIImage(cvImageBuffer: pixelBuffer, options: attachments as? [String: Any]).oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue))

        do {
            try requestHandler.perform([landmarksRequest], on: image)
        } catch {
            print(error)
        }
    }
}
