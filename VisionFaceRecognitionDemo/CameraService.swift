//
//  CameraService.swift
//  VisionFaceRecognitionDemo
//
//  Created by Maksym Musiienko on 4/11/18.
//  Copyright © 2018 Inoxoft. All rights reserved.
//

import UIKit
import AVFoundation

enum Result<T, E: Error> {
    case success(T)
    case failure(E)
}

typealias Handler<T> = (T) -> Void

protocol CameraServiceDelegate: class {

    func cameraService(_ cameraService: CameraService, didOutput sampleBuffer: CMSampleBuffer)
}

class CameraService: NSObject {

    enum Error: Swift.Error {
        case failedToCreateConnection
        case failedToCreateImage
    }

    private let session: AVCaptureSession
    private let device: AVCaptureDevice
    private let output: AVCaptureVideoDataOutput
    private let queue: DispatchQueue
    private let previewLayer: AVCaptureVideoPreviewLayer
    private weak var delegate: CameraServiceDelegate?

    init?(in view: UIView, delegate: CameraServiceDelegate) {
        guard
            let captureDevice = AVCaptureDevice
                .DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
                .devices
                .first
        else {
            return nil
        }

        do {
            session = AVCaptureSession()
            device = captureDevice
            let input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print(error)
            return nil
        }

        queue = DispatchQueue(label: "camera-service.queue")
        output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        output.alwaysDiscardsLateVideoFrames = true

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspect
        view.layer.insertSublayer(previewLayer, at: 0)
        self.delegate = delegate
        super.init()
        output.setSampleBufferDelegate(self, queue: queue)
        start()
    }

    func start() {
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraService(self, didOutput: sampleBuffer)
    }
}

extension CameraService {

    static var authorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestAccess(completion: @escaping Handler<AVAuthorizationStatus>) {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async { completion(authorizationStatus) }
        }
    }
}
