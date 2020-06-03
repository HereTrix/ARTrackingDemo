//
//  RenderService.swift
//  ARTrackingDemo
//
//  Created by HereTrix on 6/2/20.
//

import ARKit
import RealityKit

class RenderService: NSObject {
    
    fileprivate var arView: ARSCNView
    
    var hasPreview: Bool {
        return VideoRecorder.hasRecordedVideo
    }
    
    var isFaceTrackingSupported: Bool { ARFaceTrackingConfiguration.isSupported }
    
    private(set) var isRecording = false
    
    // AR configuration
    private var effectNode: SCNNode? {
        willSet {
            effectNode?.removeFromParentNode()
        }
        
        didSet {
            for faceNode in anchorNodes {
                addEffect(to: faceNode, position: .init(x: 0, y: 0, z: 0))
            }
        }
    }
    
    fileprivate var anchorNodes: Set<SCNNode> = []
    
    private lazy var configuration: ARConfiguration = {
        var configuration: ARConfiguration
        if ARFaceTrackingConfiguration.isSupported {
            configuration = ARFaceTrackingConfiguration()
            print("Face tracking supported")
        } else {
            let worldConfiguration = ARWorldTrackingConfiguration()
            configuration = worldConfiguration
        }
        return configuration
    }()
    
    // Recording stuff
    fileprivate var videoSize: CGSize!
    fileprivate var recorder: VideoRecorder?
    private var renderEngine: SCNRenderer!
    private var loop: CADisplayLink?
    fileprivate let renderingQueue = DispatchQueue(label: "com.test.ARTrackingDemo.renderingQueue", attributes: .concurrent)
    
    init(with sceneView: ARSCNView) {
        self.arView = sceneView
        
        if let mtlDevice = MTLCreateSystemDefaultDevice() {
            renderEngine = SCNRenderer(device: mtlDevice, options: nil)
            renderEngine.scene = arView.scene
        } else {
            debugPrint("Metal is not supported")
        }
        
        super.init()
        // Set the view's delegate
        sceneView.delegate = self

#if DEBUG
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
#endif
    }
    
    deinit {
        loop?.remove(from: .main, forMode: .common)
    }
    
    // MARK: - Rendering
    func startRendering() {
        
        arView.session.run(configuration, options: .removeExistingAnchors)
    }
    
    func stopRendering() {
        anchorNodes.removeAll()
        arView.session.pause()
    }
    
    
    // MARK: - Recording
    func addEffect(node: SCNNode) {
        effectNode = node
    }
    
    fileprivate func addEffect(to node: SCNNode, position: SCNVector3) {
        if let effect = effectNode?.clone()  {
            
            effect.position = position
            
            node.addChildNode(effect)
        }
    }
    
    func addAnchor(at point: CGPoint) {
        
        if let hit = arView.hitTest(point, types: [.featurePoint]).last {
            
            arView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
        }
    }
    
    func startRecording() {
        
        guard !isRecording else {
            return
        }
        
        let width = Int(arView.bounds.width)
        let height = Int(arView.bounds.height)
        videoSize = CGSize(width: width,
                           height: height)
        
        VideoRecorder.clearTemp()
        recorder = VideoRecorder(width: width,
                                 height: height)
        
        recorder?.errorCallback = { error in
            debugPrint(error)
        }
        
        if recorder == nil {
            return
        }
        
        isRecording = true
        
        loop = CADisplayLink(target: self,
                                selector: #selector(renderFrame))
        loop?.preferredFramesPerSecond = 60
        loop?.add(to: .main, forMode: .common)
    }
    
    func stopRecording(_ finished: @escaping () -> Void) {
        
        recorder?.end {
            self.isRecording = false
            self.loop?.remove(from: .main, forMode: .common)
            finished()
        }
    }
}

// MARK: - ARSCNViewDelegate
extension RenderService: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        if let _ = anchor as? ARFaceAnchor {
            return faceNode()
        }
        
        return worldNode()
    }
    
    private func faceNode() -> SCNNode? {
        guard let device = arView.device else {
            return nil
        }
        
        let faceGeometry = ARSCNFaceGeometry(device: device, fillMesh: false)
        
        guard let geometry = faceGeometry else {
            return nil
        }
        
        let faceNode = SCNNode()
        
        // Adjust effect position
        let y = geometry.boundingBox.max.y + 0.05
        let z = geometry.boundingBox.min.z - 0.05
        
        let position = SCNVector3(0, y, z)
        
        addEffect(to: faceNode, position: position)
        
        anchorNodes.insert(faceNode)
        
        return faceNode
    }
    
    private func worldNode() -> SCNNode {
        let node = SCNNode()
        let position = SCNVector3(0, 0, 0)
        addEffect(to: node, position: position)
        anchorNodes.insert(node)
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        anchorNodes.remove(node)
    }
}

// MARK: - Rendering
extension RenderService {
    @objc
    func renderFrame() {
        guard isRecording else {
            return
        }
        
        renderingQueue.sync {
            let mediaTime = CACurrentMediaTime()
            
            let snapshot = renderEngine.snapshot(atTime: mediaTime,
                                                 with: videoSize,
                                                 antialiasingMode: .none)
            if let bufer = snapshot.buffer {
                let time = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000000)
                recorder?.write(buffer: bufer, with: time)
            } else {
                debugPrint("Buffer capture failed")
            }
        }
    }
}
