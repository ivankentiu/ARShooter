//
//  ViewController.swift
//  ARShooter
//
//  Created by Ivan Ken Tiu on 01/10/2017.
//  Copyright © 2017 FinalShift Inc. All rights reserved.
//

import UIKit
import ARKit

enum BitMaskCategory: Int {
    case bullet = 2
    case target = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 50
    var target: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        // delegate the physics contact
        self.sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else { return }
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let cameraPosition = orientation + location
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        bullet.position = cameraPosition
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
        body.isAffectedByGravity = false
        bullet.physicsBody = body
        bullet.physicsBody?.applyForce(SCNVector3(orientation.x * power, orientation.y * power, orientation.z * power), asImpulse: true)
        // Category and Contact
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        self.sceneView.scene.rootNode.addChildNode(bullet)
        
        // remove bullet after 2 secs
        bullet.runAction(
            SCNAction.sequence([SCNAction.wait(duration: 2.0), SCNAction.removeFromParentNode()])
        )
    }

    @IBAction func addTargets(_ sender: Any) {
        self.addEgg(x: 5, y: 0, z: -40)
        self.addEgg(x: 0, y: 0, z: -40)
        self.addEgg(x: -5, y: 0, z: -40)
        
    }
    
    func addEgg(x: Float, y: Float, z: Float) {
        let eggScene = SCNScene(named: "Media.scnassets/egg.scn")
        let eggNode = (eggScene?.rootNode.childNode(withName: "egg", recursively: false))!
        eggNode.position = SCNVector3(x, y, z)
        eggNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: eggNode, options: nil))
        // category and contact
        eggNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        eggNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        
        self.sceneView.scene.rootNode.addChildNode(eggNode)
    }
    
    // Beginning of Hit
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        // whether nodeA or nodeB is the egg
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            self.target = nodeA
        } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            self.target = nodeB
        }
        // Particle System (Confetti)
        let confetti = SCNParticleSystem(named: "Media.scnassets/Confetti.scnp", inDirectory: nil)
        confetti?.loops = false
        confetti?.particleLifeSpan = 4
        confetti?.emitterShape = target?.geometry // Confetti flying in the bounderies of the egg
        let confettiNode = SCNNode()
        confettiNode.addParticleSystem(confetti!)
        confettiNode.position = contact.contactPoint // position to contact point
        self.sceneView.scene.rootNode.addChildNode(confettiNode)
        target?.removeFromParentNode()
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

