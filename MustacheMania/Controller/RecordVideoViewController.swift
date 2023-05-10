//
//  RecordVideoViewController.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit
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
    private let recordingQueue = DispatchQueue(label: "recordingThread")
    private var timer: Timer?
    private var toggleDurationImage = true
    private var counter: Double = 0.0 {
        didSet {
            DispatchQueue.main.async {
                // Update the duration labels text.
                self.durationLabel.text = self.manager.getTimestampFromSeconds(secondsDouble: self.counter)
                // Flash the duration image while recording.
                self.durationImageView.alpha = self.toggleDurationImage ? 1 : 0
                self.toggleDurationImage.toggle()
            }
        }
    }
    
    private var mustacheNumber = 1 {
        // Restrict the mustache number from 1 to 5 to match the assets file names.
        didSet { if mustacheNumber > 5 { mustacheNumber =  1 } }
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
        // Manually request audio permissions.
        recorder?.requestMicPermission = .manual
        // Setup recording duration views.
        durationViewContainer.layer.cornerRadius = durationViewContainer.frame.height / 2
        durationViewContainer.alpha = 0
        // Add corner radius to mustache button.
        mustacheButton.layer.cornerRadius = 20
        addTapGestureToSceneView()
        // Add notification observer to listen for when the app enters the background.
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkUserVideoPermissions()
        checkUserAudioPermissions()
        // Create the session configuration.
        let configuration = ARWorldTrackingConfiguration()
        recorder?.prepare(configuration)
        // Run the view's session.
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If currently recording stop before navigating away.
        stopVideoRecording()
        recorder?.rest()
        // Pause the view's session.
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
    
    // Stop recording when app enters background.
    @objc func didEnterBackground() { stopVideoRecording() }
    
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
    
    func checkUserVideoPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Request permissions and handle the response.
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                guard isGranted else {
                    self?.showAlertDialog()
                    self?.setupCamera(hasPermissions: false)
                    return
                }
                self?.setupCamera(hasPermissions: true)
            }
        case .restricted:
            print("Camera Permissions Restricted")
            setupCamera(hasPermissions: false)
            break
            // User has previously denied permissions.
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
    
    func checkUserAudioPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            // Request permissions and handle the response.
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { isGranted in
                self.recorder?.enableAudio = isGranted
            }
        case .restricted:
            recorder?.enableAudio = false
            break
            // User has previously denied permissions.
        case .denied:
            recorder?.enableAudio = false
            break
        case .authorized:
            // User has previously granted permissions.
            recorder?.enableAudio = true
            break
        @unknown default:
            recorder?.enableAudio = false
            break
        }
    }
    
    func showAlertDialog() {
        DispatchQueue.main.async {
            let message = "MustacheMania does not have permission to use the camera. Please allow in the application settings."
            let alertController = UIAlertController(title: "Missing Permissions", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                // Open the applications settings menu.
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
                // Get the text from the users text field.
                guard let textField = alertController.textFields?.first else { return }
                self.exportVideo(tag: textField.text ?? "", tempUrl)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    func setupCamera(hasPermissions: Bool) {
        DispatchQueue.main.async {
            // Disable buttons if permissions have been denied.
            self.recordButton.isEnabled = hasPermissions
            self.mustacheButton.isEnabled = hasPermissions
            // Set the labels text based on the permissions state.
            self.clickScreenLabel.text = hasPermissions ? "Click screen to set mustache!" : "Camera Permissions Required"
        }
    }
    
    func stopVideoRecording() {
        // Stop recording and invalidate timer.
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        // Set the record buttons image back to the default.
        self.recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
        // Hide the duration counter.
        self.durationViewContainer.alpha = 0
    }
    
    @IBAction func mustacheButtonPressed(_ sender: UIButton) {
        // Increment mustache number and update image.
        mustacheNumber += 1
        // Set the buttons image to the next mustache.
        mustacheButton.setImage(UIImage(named: "mustache\(mustacheNumber)"), for: .normal)
        // If the current mustache is not nil update the image.
        if let _ = currentMustache { currentMustache?.geometry = createGeometry() }
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        // If the recorder is recording stop it and revert buttons and timer back to the default state.
        if recorder?.status == .recording { stopVideoRecording() }
        else {
            // If camera is not recording start the recorder and timer.
            recordingQueue.async { self.recorder?.record() }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeCounterChanged), userInfo: nil, repeats: true)
            counter = 0.0
            // Change record button image.
            self.recordButton.setImage(UIImage(systemName: "stop"), for: .normal)
            // Make recording duration counter visible.
            self.durationViewContainer.alpha = 1
        }
    }
    // Update timer counter seconds.
    @objc func timeCounterChanged() { self.counter += 1 }
    
    func exportVideo(tag: String, _ tempUrl: URL) {
        // Create new file name.
        let fileName = "\(Date().timeIntervalSince1970).mp4"
        // Get the document directory path.
        let destinationPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let path = destinationPath else { return }
        // Append the new file name to document directory.
        let url = path.appendingPathComponent(fileName)
        do {
            // Convert the temporary recording url to data.
            let data = try Data(contentsOf: tempUrl)
            // Write video data to document directory.
            try data.write(to: url)
            // Get the videos duration.
            let duration = AVURLAsset(url: url).duration.seconds
            // Convert the duration double to a timestamp string.
            let timestamp = manager.getTimestampFromSeconds(secondsDouble: duration)
            // Create the recorded video item and save it to the database.
            self.coreDataService.createVideo(tag: tag, duration: timestamp, fileName: fileName)
            // Notify observer about change to the database.
            NotificationCenter.default.post(name: Notification.Name("Update"), object: nil)
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - ARSCNViewDelegate
extension RecordVideoViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Remove existing node before adding new one.
        currentMustache?.removeFromParentNode()
        // Set the current mustache to the newly created node.
        currentMustache = createMustacheNode()
        guard let _ = currentMustache else { return }
        DispatchQueue.main.async { node.addChildNode(self.currentMustache!) }
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
