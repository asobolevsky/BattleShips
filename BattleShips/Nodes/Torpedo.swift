//
//  Torpedo.swift
//  CollisionShips
//
//  Created by Aleksei Sobolevskii on 2020-11-27.
//

import SceneKit

class Torpedo: SCNNode {
    
    override init() {
        super.init()
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.darkGray
        material.emission.contents = UIColor.lightGray
        material.emission.intensity = 1.2
        material.lightingModel = .physicallyBased
        material.metalness.intensity = 2
        let geometry = SCNCapsule(capRadius: 0.02, height: 0.15)
        geometry.firstMaterial = material
        self.geometry = geometry
        
        let physicsShape = SCNPhysicsShape(geometry: geometry)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.isAffectedByGravity = false
        physicsBody.categoryBitMask = CollisionCategory.torpedo.rawValue
        physicsBody.contactTestBitMask = CollisionCategory.alienShip.rawValue
        self.physicsBody = physicsBody
        
        self.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
