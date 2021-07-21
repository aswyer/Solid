//
//  Modl.swift
//  Solid
//
//  Created by Andrew Sawyer on 6/19/21.
//

import Foundation
import SceneKit
import RealityKit
import SpriteKit
import ModelIO
import SwiftUI
import CoreImage.CIFilterBuiltins


class ViewportModel: NSObject, ObservableObject, SCNSceneRendererDelegate {
    lazy var sceneView = SCNView()
    private var scene = SCNScene()

    private var capture: Capture?
    var captureNode: SCNNode?
    
    let camera = SCNCamera()
    
    private var floorNode: SCNNode?
    
    private var previewQuality: PhotogrammetrySession.Request.Detail?
    
    var isBackgroundVisible = UserDefaults.standard.bool(forKey: "isBackgroundVisible") {
        didSet {
            floorNode?.isHidden = isBackgroundVisible
        }
    }

    private var backgroundColor: CGColor {
        return CGColor(gray: 0.05, alpha: 1)
    }
   
    //TODO: cache of nodes?

    override init() {
        
        super.init()
        
        //CAMERA SETUP
        camera.zNear = Defaults.zMin
        camera.wantsDepthOfField = UserDefaults.standard.bool(forKey: "wantsDOF")
        camera.fStop = 1
        
        camera.wantsHDR = true
        camera.wantsExposureAdaptation = true
        
        
        camera.exposureAdaptationDarkeningSpeedFactor = 10
        camera.exposureAdaptationBrighteningSpeedFactor = 10
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        
        //SCENE VIEW SETUP
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        
        //ENVIRONMENT SETUP
        setupSceneEnvironment()
        let lightingEnvironmentValue = UserDefaults.standard.integer(forKey: "lightingEnvironment")
        if let lightingEnvironment = LightingEnvironment(rawValue: lightingEnvironmentValue) {
            setupLightingEnvironment(for: lightingEnvironment)
        }
    }
    
    func update(withNewCapture newCapture: Capture, quality: PhotogrammetrySession.Request.Detail) {
        //ensure that capture isn't same OR the processedFiles aren't the same
        guard
            newCapture != capture ||
            quality != previewQuality
        else {
            return
        }
        
        //update local variables
        capture = newCapture
        previewQuality = quality
        guard let capture = capture, let previewQuality = previewQuality else { return }

        //get url and check that file exists
        let url = Storage.url(for: capture, with: previewQuality)
        guard Storage.fileExists(at: url) else {
            debugPrint("capture file NOT found")
            self.captureNode?.removeFromParentNode()
            
            return
        }
        //debugPrint("capture file found")
        
        //create capture node
        let newNode = SCNReferenceNode(url: url)
        newNode?.load()
        let gZeroNode = newNode?.childNode(withName: "g0", recursively: true)
        gZeroNode?.geometry?.firstMaterial?.lightingModel = .physicallyBased
        
        guard let newNode = newNode else {
            return
        }
        
        sceneView.prepare([newNode]) { completed in
            //remove current capture node
            self.captureNode?.removeFromParentNode()
            
            //add new capture to scene
            self.captureNode = newNode
            if let captureNode = self.captureNode {
                self.scene.rootNode.addChildNode(captureNode)
            }
        }
    }
 
    
    private func setupSceneEnvironment() {
        //reflections
        scene.wantsScreenSpaceReflection = true
        
        //fog
        scene.fogColor = backgroundColor
        scene.fogDensityExponent = 1
        scene.fogStartDistance = 5
        scene.fogEndDistance = 33
        
        
        //floor geometry
        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = 0
        
        //floor node
        floorNode = SCNNode(geometry: floorGeometry)
        floorNode?.position = SCNVector3(0, -0.5, 0)
        floorNode?.opacity = 0.2
        
        //floor material
        let floorMaterial = floorGeometry.firstMaterial
        floorMaterial?.lightingModel = .constant
        
        floorMaterial?.diffuse.contents = NSImage(named: "grid")
        floorMaterial?.diffuse.wrapT = .mirror
        floorMaterial?.diffuse.wrapS = .mirror
        floorMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(50, 50, 1)
        
        //add floor
        if let floorNode = floorNode {
            scene.rootNode.addChildNode(floorNode)
        }
    }
    
    func setupLightingEnvironment(for style: LightingEnvironment) {
        let imageName = "environment_\(style.rawValue)"
        scene.lightingEnvironment.contents = imageName
        
        //sky
        if isBackgroundVisible {
            scene.background.contents = imageName
        } else {
            scene.background.contents = backgroundColor
        }
    }
    
    
    func resetFrame() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        
        sceneView.pointOfView?.position = SCNVector3(x: 0, y: 0, z: 2)
        sceneView.pointOfView?.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
        sceneView.pointOfView?.look(at: SCNVector3(x: 0, y: 0, z: 0)) //captureNode.worldPosition
        
        SCNTransaction.commit()
    }
    
}
