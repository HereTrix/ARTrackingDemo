//
//  RecordingViewController.swift
//  ARTrackingDemo
//
//  Created by HereTrix on 6/2/20.
//

import UIKit
import SceneKit
import ARKit
import MBProgressHUD

private let showPreviewSegueIdentifier = "showPreview"

class RecordingViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var previewButton: UIButton!
    @IBOutlet var warningLabel: UILabel!
    
    private var renderer: RenderService!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGestures()
        
        renderer = RenderService(with: sceneView)
        
        // Configure effect
        let scene = SCNScene(named: "art.scnassets/Phoenix.scn")!
        renderer.addEffect(node: scene.rootNode)
        
        warningLabel.isHidden = renderer.isFaceTrackingSupported
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
        configureButtons()
        
        renderer.startRendering()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        renderer.stopRendering()
    }

    // MARK: - Configuration
    private func configureButtons() {
        let recordingTitle = renderer.isRecording ? "Stop record" : "Start record"
        recordButton.setTitle(recordingTitle, for: .normal)
        previewButton.isEnabled = !renderer.isRecording && renderer.hasPreview
    }
    
    // MARK: - Gesture Recognizers
    private func setupGestures() {
        if renderer.isFaceTrackingSupported {
            return
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(gesture:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @IBAction func toggleRecording() {
        if !renderer.isRecording {
            renderer.startRecording()
            configureButtons()
        } else {
            MBProgressHUD.showAdded(to: view, animated: true)
            renderer.stopRecording {
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.configureButtons()
                }
            }
        }
    }
    
    @IBAction func preview() {
        performSegue(withIdentifier: showPreviewSegueIdentifier, sender: nil)
    }
    
    @objc private func didTap(gesture: UITapGestureRecognizer) {
        
        if gesture.state == .recognized {
            let point = gesture.location(in: gesture.view)
            renderer.addAnchor(at: point)
        }
    }
}
