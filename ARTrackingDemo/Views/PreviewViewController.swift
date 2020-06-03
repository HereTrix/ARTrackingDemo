//
//  PreviewViewController.swift
//  ARTrackingDemo
//
//  Created by HereTrix on 6/2/20.
//

import UIKit
import AVKit
import Photos
import MBProgressHUD

private let playerSegueIdentifier = "playerSegue"

class PreviewViewController: UIViewController {
    
    private let player = AVPlayer(url: VideoRecorder.recordFileURL)
    private var playerController: AVPlayerViewController!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerController.player = player
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    // MARK: - Actions
    @IBAction func saveToLibrary() {
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.save()
                } else {
                    DispatchQueue.main.async {
                        UIAlertController.show(message: "Please, enable access to photo library", from: self)
                    }
                }
            }
        case .authorized:
            save()
        default:
            UIAlertController.show(message: "Please, enable access to photo library", from: self)
        }
    }
    
    private func save() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: VideoRecorder.recordFileURL)
        }) { (saved, error) in
            
            DispatchQueue.main.async {
                let message = saved ? "Video saved successfully!" : "Video saving failed"
                UIAlertController.show(message: message, from: self)
                
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == playerSegueIdentifier {
            playerController = segue.destination as? AVPlayerViewController
        }
    }
}
