//
//  ViewController.swift
//  BattleShips
//
//  Created by Aleksei Sobolevskii on 2020-12-03.
//

import ARKit

class ViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var statusLabel: UILabel!
    
    // MARK: - Private properties
    
    private var audioPlayer: AVAudioPlayer?
    
    private var cameraVectors: (SCNVector3, SCNVector3) {
        guard let frame = sceneView.session.currentFrame else {
            return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.1))
        }
        let transform = SCNMatrix4(frame.camera.transform)
        // The reflection of camera
        let direction = SCNVector3(-1 * transform.m31,
                                   -1 * transform.m32,
                                   -1 * transform.m33)
        let position = SCNVector3(transform.m41,
                                  transform.m42,
                                  transform.m43)
        return (direction, position)
    }
    
    private var score: UInt16 = 0 {
        didSet {
            updateStatusLabel()
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startSession()
        spawnEnemyShip()
        
        // Needs to be set after SceneView is present
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopSession()
    }
    
    // MARK: - Private
    
    private func setupScene() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        setupGestures()
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }

    private func startSession() {
        let config = ARWorldTrackingConfiguration()
        sceneView.session.run(config)
    }

    private func stopSession() {
        sceneView.session.pause()
    }
    
    private func spawnTorpedo() {
        playSound(Sound.launch)
        
        let (direction, position) = cameraVectors
        let torpedo = Torpedo()
        let lookAtDirection = SCNVector3(0, 1000, -1)
        torpedo.position = position
        torpedo.look(at: lookAtDirection)
        torpedo.physicsBody?.applyForce(direction, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(torpedo)
    }
    
    private func spawnEnemyShip() {
        guard
            let shipNode = SCNScene(named: "art.scnassets/enemy_ship.usdz")?.rootNode
                .childNode(withName: "enemy_ship", recursively: false)
        else {
            return
        }
        
        let position = SCNVector3(range(min: -1.0, max: 1.0),
                                  range(min: -0.5, max: 0.5),
                                  range(min: -2.0, max: -1.5))
        shipNode.position = position
        
        let shopGeometry = SCNBox(width: CGFloat(shipNode.size.x),
                                  height: CGFloat(shipNode.size.y),
                                  length: CGFloat(shipNode.size.z),
                                  chamferRadius: 0)
        let physicsShape = SCNPhysicsShape(geometry: shopGeometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.isAffectedByGravity = false
        physicsBody.categoryBitMask = CollisionCategory.alienShip.rawValue
        shipNode.physicsBody = physicsBody
        
        sceneView.scene.rootNode.addChildNode(shipNode)
    }
    
    private func torpedoHitAlientShip() {
        score += 1
        
        spawnEnemyShip()
    }
    
    private func playSound(_ sound: Sound) {
        DispatchQueue.main.async {
            guard
                let url = Bundle.main.url(forResource: "art.scnassets/Sounds/\(sound.rawValue)", withExtension: "mp3"),
                let audioPlayer = try? AVAudioPlayer(contentsOf: url)
            else {
                return
            }
            
            audioPlayer.play()
            self.audioPlayer = audioPlayer
        }
    }
    
    private func updateStatusLabel() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Score: \(self.score)"
        }
    }
    
    // MARK: - Actions
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        spawnTorpedo()
    }
}


// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    }
    
}


// MARK: - SCNPhysicsContactDelegate

extension ViewController: SCNPhysicsContactDelegate {
    private func isContact(_ contact: SCNPhysicsContact,
                           between categoryA: CollisionCategory,
                           and categoryB: CollisionCategory) -> Bool {
        return (contact.nodeA.physicsBody?.categoryBitMask == categoryA.rawValue &&
                    contact.nodeB.physicsBody?.categoryBitMask == categoryB.rawValue) ||
            (contact.nodeB.physicsBody?.categoryBitMask == categoryA.rawValue &&
                contact.nodeA.physicsBody?.categoryBitMask == categoryB.rawValue)
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if isContact(contact, between: .torpedo, and: .alienShip) {
            torpedoHitAlientShip()
            
            contact.nodeA.removeFromParentNode()
            contact.nodeB.removeFromParentNode()
        }
    }
}










func range(min: Float, max: Float) -> Float {
    Float.random(in: min...max)
}

enum Sound: String {
    case launch     = "TorpedoLaunch"
    case collision  = "TorpedoCollision"
    case explode    = "TorpedoExplode"
}

extension BinaryInteger {
    var degToRad: CGFloat { CGFloat(self) * .pi / 180 }
}

extension FloatingPoint {
    var degToRad: Self { self * .pi / 180 }
    var radToDeg: Self { self * 180 / .pi }
}

extension simd_float3 {
    var radToDeg: simd_float3 {
        return simd_float3(x.radToDeg, y.radToDeg, z.radToDeg)
    }
}

extension SCNVector3 {
    static func * (_ lhs: SCNVector3, _ rhs: Int) -> SCNVector3 {
        return SCNVector3(lhs.x * Float(rhs), lhs.y * Float(rhs), lhs.z * Float(rhs))
    }
}

extension SCNNode {
    var size: SCNVector3 {
        let xSize = boundingBox.max.x - boundingBox.min.x
        let ySize = boundingBox.max.y - boundingBox.min.y
        let zSize = boundingBox.max.z - boundingBox.min.z
        return SCNVector3(xSize, ySize, zSize)
    }
}

private struct Constants {
    static let sphereRadius: CGFloat = 5
}
