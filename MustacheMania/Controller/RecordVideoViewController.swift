//
//  RecordVideoViewController.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit
import AVFoundation
import RealityKit

class RecordVideoViewController: UIViewController {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var durationViewContainer: UIView!
    @IBOutlet weak var durationImageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var switchCameraMenuButton: UIBarButtonItem!
    @IBOutlet weak var arView: ARView!
    
    private var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureMovieFileOutput()
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureDevice: AVCaptureDevice?
    private var isUsingFrontCamera = true
    
    private var coreDataService = CoreDataService()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set CoreDataService delegate.
        coreDataService.delegate = self
        
        // Setup recording duration views
        durationViewContainer.layer.cornerRadius = durationViewContainer.frame.height / 2
        durationViewContainer.alpha = 0
    }
    
    func checkUserPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Request permissions and handle the response
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                guard isGranted else {
                    self?.showAlertDialog()
                    return
                }
                DispatchQueue.main.async {
                    self?.setupCamera()
                }

            }
        case .restricted:
            print("Camera Permissions Restricted")
            break
        case .denied:
            showAlertDialog()
            break
            // User has previously granted permissions.
        case .authorized:
            setupCamera()
        @unknown default:
            break
        }
    }
    
    func showAlertDialog() {
        DispatchQueue.main.async {
            let message = "MustacheMania does not have permission to use the camera. Please allow in the application settings."
            let alertController = UIAlertController(title: "Missing Permissions", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            alertController.addAction(UIAlertAction(title: "Settings",
                                                    style: .default,
                                                    handler: { _ in
                                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                  options: [:],
                                                                                  completionHandler: nil)
            }))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }

    
    func setupCamera() {
        // Create the capture session.
        let captureSession = AVCaptureSession()
        
        // Find the default video device.
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        
        
        captureDevice = videoDevice

        do {
            // Wrap the video device in a capture device input.
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            // If the input can be added, add it to the session.
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            captureSession.sessionPreset = .high
//            // Set the preview layers session.
//            videoPreviewLayer.session = captureSession
//            videoPreviewLayer.videoGravity = .resizeAspectFill
            // Start session.
            captureSession.startRunning()
            setupARView()
            // Set session as global variable.
            self.captureSession = captureSession
            
        } catch {
            // Configuration failed. Handle error.
            print("Error configuring camera = \(error.localizedDescription)")
        }
    }
    
    func setupARView() {
         let anchor = AnchorEntity(plane: .horizontal, minimumBounds:[0.2, 0.2])
         arView.scene.addAnchor(anchor)
        var mustaches: [Entity] = []
        for _ in 1...4 {
            let box = MeshResource.generateBox(width: 0.04, height: 0.002, depth: 0.04)
            let metalMaterial = SimpleMaterial(color: .gray, isMetallic: true)
            let model = ModelEntity(mesh: box, materials: [metalMaterial])
            
            model.generateCollisionShapes(recursive: true)
            mustaches.append(model)
        }
        
        for (index, mustache) in mustaches.enumerated() {
            let x = Float(index % 2)
            let z = Float(index / 2)
            mustache.position = [x * 0.1, 0 , z * 0.1]
            anchor.addChild(mustache)
        }
     }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if videoOutput.isRecording { videoOutput.stopRecording() }
        else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

            let fileUrl = paths[0].appendingPathComponent("output.mov")

            try? FileManager.default.removeItem(at: fileUrl)

            videoOutput.startRecording(to: fileUrl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        }
        
            let buttonImage = self.videoOutput.isRecording ? UIImage(systemName: "record.circle") : UIImage(systemName: "stop")
            self.recordButton.setImage(buttonImage, for: .normal)
            self.durationViewContainer.alpha = self.videoOutput.isRecording ? 0 : 1
            self.switchCameraMenuButton.isEnabled = self.videoOutput.isRecording
    }
    
    @IBAction func changeCameraButtonPressed(_ sender: UIBarButtonItem) {
        print("Switch Camera Pressed")
    }
    
}

// MARK: - CoreDataServiceDelegate
extension RecordVideoViewController: CoreDataServiceDelegate {

}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension RecordVideoViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Finished Recording")
    }
}
