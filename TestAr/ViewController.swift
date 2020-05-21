//
//  ViewController.swift
//  TestAr
//
//  Created by Alexey on 5/18/20.
//  Copyright © 2020 Alexey. All rights reserved.
//

import ARKit
import SceneKit
import UIKit
import ReplayKit

class ViewController: UIViewController, RPPreviewViewControllerDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var recordButton: UIButton!
    
    var faceNode: SCNNode!
    let recorder = RPScreenRecorder.shared()
    private var isFirstRecording = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !ARFaceTrackingConfiguration.isSupported {
            let alertController = UIAlertController(title: "Alert", message: "Unsupported Device", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Close app", style: .default, handler: { (_) in
                exit(0)
            }))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        sceneView.delegate = self
        sceneView.session.delegate = self
        if self.isFirstRecording {
            //Workaround because Replay kit can't ask permissions once
            self.startRecording()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }
    
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func rotate(rotation: Float, object: SCNNode, duration: Float){
        let rotation = SCNAction.rotateBy(x:0,y:CGFloat(rotation),z:0, duration: TimeInterval(duration))
        object.runAction(SCNAction.repeatForever(rotation))
    }
    
    func createRing(ringSize: Float) -> SCNNode {
        let ring = SCNTorus(ringRadius: CGFloat(ringSize), pipeRadius: 0.002)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear // Change color for check object way
        ring.materials = [material]
        let ringNode = SCNNode(geometry: ring)
        return ringNode
    }
    
    @IBAction func startRecordAction(_ sender: Any) {
        self.startRecording()
    }
    
    @IBAction func finishRecordAction(_ sender: Any) {
        self.stopRecording()
    }
    
    func startRecording() {
        guard recorder.isAvailable else {
            return
        }
        recorder.startRecording{ (error) in
            guard error == nil else {
                return
            }
            if self.isFirstRecording {
                self.stopRecordingWithoutSave()
                self.isFirstRecording = false
            }
        }
    }
    
    func stopRecording() {
        recorder.stopRecording { [unowned self] (preview, error) in
            guard preview != nil else {
                return
            }
            preview?.previewControllerDelegate = self
            self.present(preview!, animated: true, completion: nil)
        }
    }
    
    func stopRecordingWithoutSave() {
        recorder.stopRecording { (preview, error) in
            guard preview != nil else {
                return
            }
        }
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARFaceAnchor else { return }
        
        let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)!
        faceGeometry.firstMaterial!.colorBufferWriteMask = []
        faceGeometry.firstMaterial?.isDoubleSided = true
        faceNode = SCNNode(geometry: faceGeometry)
        faceNode.renderingOrder = 0
        let radius = faceNode.boundingSphere.radius + faceNode.boundingSphere.radius/2 //Create radius more than head sphere radius
        
        let objRing = createRing(ringSize: radius) // Create ring with head radius. Move this ring around X.
        objRing.position = faceNode.boundingSphere.center
        let obj = SCNReferenceNode(named: "overlayModel")// Create obj
        obj.position = SCNVector3(x: radius ,y: 0, z: 0)
        rotate(rotation: 1, object: objRing, duration: 1)
        
        
        objRing.addChildNode(obj)
        faceNode.addChildNode(objRing)
        // Add object to ring
        node.addChildNode(faceNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceGeometry = faceNode.geometry as? ARSCNFaceGeometry,
            let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)
    }
}

extension ViewController : ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
              guard error is ARError else { return }
              
              let errorWithInfo = error as NSError
              let messages = [
                  errorWithInfo.localizedDescription,
                  errorWithInfo.localizedFailureReason,
                  errorWithInfo.localizedRecoverySuggestion
              ]
              let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
              
              DispatchQueue.main.async {
                  self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
              }
          }
          
          func displayErrorMessage(title: String, message: String) {
              // Present an alert informing about the error that has occurred.
              let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
              let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                  alertController.dismiss(animated: true, completion: nil)
                  self.resetTracking()
              }
              alertController.addAction(restartAction)
              present(alertController, animated: true, completion: nil)
          }
}

