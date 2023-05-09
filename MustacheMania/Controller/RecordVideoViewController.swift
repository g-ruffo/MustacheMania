//
//  RecordVideoViewController.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit
import SpriteKit
import ARKit
import ARVideoKit

class RecordVideoViewController: UIViewController {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var durationViewContainer: UIView!
    @IBOutlet weak var durationImageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var clickScreenLabel: UILabel!

    private var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureMovieFileOutput()
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureDevice: AVCaptureDevice?
    private var recorder: RecordAR?
    private var timer: Timer?
    private var toggleDurationImage = true
    private var counter: Double = 0.0 {
        didSet {
            DispatchQueue.main.async { 
                self.durationLabel.text = self.manager.getTimestampFromSeconds(secondsDouble: self.counter)
                self.durationImageView.alpha = self.toggleDurationImage ? 1 : 0
                self.toggleDurationImage.toggle()
            }
        }
    }
    
    private var currentMustache: SCNNode? {
        didSet {
            DispatchQueue.main.async {
                if let _ = self.currentMustache {
                    self.clickScreenLabel.alpha = 0 }
                else { self.clickScreenLabel.alpha = 1 }
            }
        }
    }

    private var coreDataService = CoreDataService()
    private let manager = RecordVideoManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set CoreDataService delegate.
        coreDataService.delegate = self
        sceneView.delegate = self
        recorder = RecordAR(ARSceneKit: sceneView)
        recorder?.delegate = self

        // Setup recording duration views
        durationViewContainer.layer.cornerRadius = durationViewContainer.frame.height / 2
        durationViewContainer.alpha = 0
        addTapGestureToSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        recorder?.prepare(configuration)
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recorder?.rest()
        currentMustache?.removeFromParentNode()
        currentMustache = nil
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapGesture(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func didReceiveTapGesture(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        guard let hitTestResult = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane]).first
            else { return }
        let anchor = ARAnchor(transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchor)
    }
    
    func generateSphereNode() -> SCNNode {
        let planeGeometry = SCNPlane(width: 0.1, height: 0.2)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "mustache1")
        planeGeometry.materials = [material]

        let node = SCNNode()
        node.geometry = planeGeometry
        return node
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
    
    func showSaveDialog(tempUrl: URL) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Add Tag to Video", message: nil, preferredStyle: .alert)
            alertController.addTextField { field in
                field.placeholder = "Enter Tag"
                field.returnKeyType = .done
                
            }

            alertController.addAction(UIAlertAction(title: "Save", style: .cancel, handler: { _ in
                guard let textField = alertController.textFields?.first else { return }
                self.exportVideo(tag: textField.text ?? "", tempUrl)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

            self.present(alertController, animated: true, completion: nil)
        }
    }

    
    func setupCamera() {

    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if recorder?.status == .recording {
            recorder?.stop()
            timer?.invalidate()
            timer = nil
            self.recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
            self.durationViewContainer.alpha = 0
        } else {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeCounterChanged), userInfo: nil, repeats: true)
            recorder?.record()
            counter = 0.0
            self.recordButton.setImage(UIImage(systemName: "stop"), for: .normal)
            self.durationViewContainer.alpha = 1

        }
    }
    
    @objc func timeCounterChanged() -> Void {
                self.counter += 1
    }
    
    func exportVideo(tag: String, _ tempUrl: URL) {
        let fileName = "\(Date().timeIntervalSince1970).mp4"
        let destinationPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let path = destinationPath else { return }
        let url = path.appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: tempUrl)
            try data.write(to: url)
            let duration = AVURLAsset(url: url).duration.seconds
            let timestamp = manager.getTimestampFromSeconds(secondsDouble: duration)
            self.coreDataService.createUpdateVideo(tag: tag, duration: timestamp, fileName: fileName)
            NotificationCenter.default.post(name: Notification.Name("Update"), object: nil)
             } catch {
                 print(error.localizedDescription)
             }
    }
    
}

// MARK: - CoreDataServiceDelegate
extension RecordVideoViewController: CoreDataServiceDelegate {

}

// MARK: - ARSCNViewDelegate
extension RecordVideoViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard !(anchor is ARPlaneAnchor) else { return }
        currentMustache?.removeFromParentNode()
        currentMustache = generateSphereNode()
        DispatchQueue.main.async {
            node.addChildNode(self.currentMustache!)
        }
    }
}

// MARK: - RecordARDelegate
extension RecordVideoViewController: RecordARDelegate {
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError {
            showSaveDialog(tempUrl: path)
        }
    }
    
    func recorder(didFailRecording error: Error?, and status: String) {
    }
    
    func recorder(willEnterBackground status: ARVideoKit.RecordARStatus) {
        
    }
}
