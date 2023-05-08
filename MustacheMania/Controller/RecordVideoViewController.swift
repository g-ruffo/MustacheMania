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
    
    private var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureMovieFileOutput()
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var captureDevice: AVCaptureDevice?
    private var isUsingFrontCamera = true
    private var recorder:RecordAR?
    private var currentMustache: SCNNode?

    private var coreDataService = CoreDataService()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set CoreDataService delegate.
        coreDataService.delegate = self
        sceneView.delegate = self
        recorder = RecordAR(ARSceneKit: sceneView)

        // Setup recording duration views
        durationViewContainer.layer.cornerRadius = durationViewContainer.frame.height / 2
        durationViewContainer.alpha = 0
        addTapGestureToSceneView()
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
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func generateSphereNode() -> SCNNode {
        let planeGeometry = SCNPlane(width: 0.1, height: 0.2)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "mustache3")
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

    
    func setupCamera() {

    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if recorder?.status == .recording {
            recorder?.stop()
            let url = getDocumentsDirectory().appendingPathComponent("\(Date()).mp4")
  
            self.recordButton.setImage(UIImage(systemName: "stop"), for: .normal)
            self.durationViewContainer.alpha = 0
        } else {
            recorder?.record()
            self.recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
            self.durationViewContainer.alpha = 1

        }
    }
    
    func exportVideo(url: URL) {
        recorder?.export(video: url) { exported , _ in
            if exported {
                
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
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
