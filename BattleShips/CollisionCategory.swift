//
//  CollisionCategory.swift
//  CollisionShips
//
//  Created by Aleksei Sobolevskii on 2020-11-27.
//

import Foundation

struct CollisionCategory: OptionSet {
    var rawValue: Int
    
    static let torpedo      = CollisionCategory(rawValue: 1 << 0)
    static let alienShip    = CollisionCategory(rawValue: 1 << 1)
    
    static let outerSphere  = CollisionCategory(rawValue: 1 << 2)
    
}
