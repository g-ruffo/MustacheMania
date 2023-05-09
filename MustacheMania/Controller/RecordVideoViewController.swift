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
    @IBOutlet weak var mustacheButton: UIButton!
    
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
    
    private var mustacheNumber = 1 {
        didSet {
            if mustacheNumber > 5 { mustacheNumber =  1 }
            
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
        // Set SceneView delegate.
        sceneView.delegate = self
        recorder = RecordAR(ARSceneKit: sceneView)
        // Set RecordAR delegate.
        recorder?.delegate = self
        recorder?.deleteCacheWhenExported = true
        recorder?.onlyRenderWhileRecording = true
        // Setup recording duration views
        durationViewContainer.layer.cornerRadius = durationViewContainer.frame.height / 2
        durationViewContainer.alpha = 0
        mustacheButton.layer.cornerRadius = 20
        
        addTapGestureToSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        recorder?.prepare(configuration)
        checkUserPermissions()
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
        guard let hitTestResult = sceneView.hitTest(location, types: [.featurePoint]).first
            else { return }
        let anchor = ARAnchor(transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchor)
    }
    
    func createMustacheNode() -> SCNNode {
        let node = SCNNode()
        node.geometry = createGeometry()
        return node
    }
    
    func createGeometry() -> SCNGeometry {
        let sphereGeometry = SCNSphere(radius: 0.2)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "mustache\(mustacheNumber)")
        sphereGeometry.materials = [material]
        return sphereGeometry
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
                self?.setupCamera(hasPermissions: true)
            }
        case .restricted:
            print("Camera Permissions Restricted")
            setupCamera(hasPermissions: false)
            break
        case .denied:
            showAlertDialog()
            setupCamera(hasPermissions: false)
            break
            // User has previously granted permissions.
        case .authorized:
            setupCamera(hasPermissions: true)
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

            alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                guard let textField = alertController.textFields?.first else { return }
                self.exportVideo(tag: textField.text ?? "", tempUrl)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            self.present(alertController, animated: true, completion: nil)
        }
    }

    
    func setupCamera(hasPermissions: Bool) {
        recordButton.isEnabled = hasPermissions
        mustacheButton.isEnabled = hasPermissions
        clickScreenLabel.text = hasPermissions ? "Click screen to set mustache!" : "Camera Permissions Required"
    }
    
    @IBAction func mustacheButtonPressed(_ sender: UIButton) {
        mustacheNumber += 1
        mustacheButton.setImage(UIImage(named: "mustache\(mustacheNumber)"), for: .normal)
        if let _ = currentMustache { currentMustache?.geometry = createGeometry() }
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
    
    @objc func timeCounterChanged() { self.counter += 1 }
    
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
            self.coreDataService.createVideo(tag: tag, duration: timestamp, fileName: fileName)
            NotificationCenter.default.post(name: Notification.Name("Update"), object: nil)
             } catch {
                 print(error.localizedDescription)
             }
    }
    
}

// MARK: - ARSCNViewDelegate
extension RecordVideoViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard !(anchor is ARPlaneAnchor) else { return }
        currentMustache?.removeFromParentNode()
        currentMustache = createMustacheNode()
        guard let _ = currentMustache else { return }
        DispatchQueue.main.async {
            node.addChildNode(self.currentMustache!)
        }
    }
}

// MARK: - RecordARDelegate
extension RecordVideoViewController: RecordARDelegate {
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError { showSaveDialog(tempUrl: path)  }
    }
    func recorder(didFailRecording error: Error?, and status: String) { }
    func recorder(willEnterBackground status: ARVideoKit.RecordARStatus) { }
}
