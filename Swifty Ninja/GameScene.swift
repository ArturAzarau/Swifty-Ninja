//
//  GameScene.swift
//  Swifty Ninja
//
//  Created by Артур Азаров on 07.08.2018.
//  Copyright © 2018 Артур Азаров. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        createBackground()
        adjustGravity()
        adjustSpeed()
        createScore()
        createLives()
        createSlices()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    // MARK: - Methods
    
    private func createBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.zPosition = -1
        background.blendMode = .replace
        addChild(background)
    }
    
    // MARK: -
    
    private func adjustGravity() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
    }
    
    // MARK: -
    
    private func adjustSpeed() {
        physicsWorld.speed = 0.85
    }
    
    // MARK: -
    
    private func createScore() {
        
    }
    
    // MARK: -
    
    private func createLives() {
        
    }
    
    // MARK: -
    
    private func createSlices() {
        
    }
    
}
