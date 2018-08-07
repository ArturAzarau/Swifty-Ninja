//
//  GameScene.swift
//  Swifty Ninja
//
//  Created by Артур Азаров on 07.08.2018.
//  Copyright © 2018 Артур Азаров. All rights reserved.
//

import SpriteKit
import GameplayKit

final class GameScene: SKScene {
    
    // MARK: - Properties
    
    private var gameScore: SKLabelNode!
    
    // MARK: -
    
    private var score = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    // MARK: -
    
    private var livesImages = [SKSpriteNode]()
    
    // MARK: -
    
    private var lives = 3
    
    // MARK: -
    
    private var isSwooshSoundActive = false
    
    // MARK: -
    
    private var activeSliceBG: SKShapeNode!
    private var activeSliceFG: SKShapeNode!
    private var activeSlicePoints = [CGPoint]()
    
    // MARK: - View life cycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        createBackground()
        adjustGravity()
        adjustSpeed()
        createScore()
        createLives()
        createSlices()
    }
    
    // MARK: - Handling touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        if let touch = touches.first {
            let location = touch.location(in: self)
            activeSlicePoints.append(location)
            redrawActiveSlices()
            activeSliceBG.removeAllActions()
            activeSliceFG.removeAllActions()
            activeSliceBG.alpha = 1
            activeSliceFG.alpha = 1
        }
    }
    
    // MARK: -
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        
        redrawActiveSlices()
        
        if !isSwooshSoundActive {
            playSwooshSound()
        }
    }
    
    // MARK: -
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.25)
        activeSliceBG.run(fadeOutAction)
        activeSliceFG.run(fadeOutAction)
    }
    
    // MARK: -
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    // MARK: - Methods
    
    private func createBackground() {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
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
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score = 0"
        gameScore.fontSize = 48
        gameScore.horizontalAlignmentMode = .left
        addChild(gameScore)
        
        gameScore.position = CGPoint(x: 8, y: 8)
    }
    
    // MARK: -
    
    private func createLives() {
        for i in stride(from: 834, through: 974, by: 70) {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: i, y: 720)
            addChild(spriteNode)
            livesImages.append(spriteNode)
        }
    }
    
    // MARK: -
    
    private func createSlices() {
        let bgSlice = createBGSlice()
        let fgSlice = createFGSlice()
        
        addChild(bgSlice)
        addChild(fgSlice)
    }
    
    // MARK: -
    
    private func redrawActiveSlices() {
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        while activeSlicePoints.count > 12 {
            activeSlicePoints.remove(at: 0)
        }
        
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for i in 1..<activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }
        
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
    }
    
    // MARK: -
    
    private func playSwooshSound() {
        isSwooshSoundActive = true
        let randomNumber = RandomInt(min: 1, max: 3)
        let soundName = "swoosh\(randomNumber).caf"
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        run(swooshSound) { [unowned self] in
            self.isSwooshSoundActive = false
        }
    }
    
    // MARK: - Helpers
    
    private func createBGSlice() -> SKShapeNode {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        activeSliceBG.lineCap = .round
        
        return activeSliceBG
    }
    
    // MARK: -
    
    private func createFGSlice() -> SKShapeNode {
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        activeSliceFG.strokeColor = UIColor.white
        activeSliceFG.lineWidth = 5
        activeSliceFG.lineCap = .round
        return activeSliceFG
    }
    
}
