//
//  ObjectPool.swift
//  Space Shooter  Game
//
//  Created by Antigravity on 10/04/26.
//

import SpriteKit

/// A generic object pool to manage SpriteKit nodes for better performance.
class ObjectPool<T: SKNode> {
    private var pool: [T] = []
    private let maxObjects: Int
    private let creator: () -> T
    
    init(maxObjects: Int, creator: @escaping () -> T) {
        self.maxObjects = maxObjects
        self.creator = creator
        
        // Pre-fill the pool
        for _ in 0..<maxObjects {
            let object = creator()
            object.isHidden = true
            pool.append(object)
        }
    }
    
    /// Returns the first available hidden object from the pool.
    func get() -> T? {
        return pool.first(where: { $0.isHidden })
    }
    
    /// Adds all pooled objects to a parent scene or node.
    func addToParent(_ parent: SKNode) {
        for object in pool {
            if object.parent == nil {
                parent.addChild(object)
            }
        }
    }
    
    /// Resets the entire pool by hiding all objects and removing actions.
    func reset() {
        for object in pool {
            object.isHidden = true
            object.removeAllActions()
        }
    }
    
    /// Iterator for all objects in the pool.
    var allObjects: [T] {
        return pool
    }
}
