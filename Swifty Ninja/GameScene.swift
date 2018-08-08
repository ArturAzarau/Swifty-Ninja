//
//  GameScene.swift
//  Swifty Ninja
//
//  Created by Артур Азаров on 07.08.2018.
//  Copyright © 2018 Артур Азаров. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

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
    
    // MARK: -
    
    private enum ForceBomb {
        case never, always, random
    }
    
    // MARK: - Creating enemies
    
    private enum SequenceType: Int {
        case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
    }
    
    private var popupTime = 0.9
    private var sequence: [SequenceType]!
    private var sequencePosition = 0
    private var chainDelay = 3.0
    private var nextSequenceQueued = true
    
    
    // MARK: -
    
    private var activeEnemies = [SKSpriteNode]()
    
    // MARK: -
    
    private var bombSoundEffect: AVAudioPlayer!
    
    
    // MARK: - View life cycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        createBackground()
        adjustGravity()
        adjustSpeed()
        createScore()
        createLives()
        createSlices()
        positionEnemies()
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
    
    // MARK: -
    
    private func createEnemy(forceBomb: ForceBomb = .random) {
        var enemy = SKSpriteNode()
        
        // 0 means bomb, other mean pinguin
        var enemyType = RandomInt(min: 0, max: 6)
        
        if forceBomb == .never {
            enemyType = 1
        } else if forceBomb == .always {
            enemyType = 0
        }
        
        if enemyType == 0 {
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)
            
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
            
            let path = Bundle.main.path(forResource: "sliceBombFuse.caf", ofType: nil)!
            let url = URL(fileURLWithPath: path)
            let sound = try! AVAudioPlayer(contentsOf: url)
            bombSoundEffect = sound
            sound.play()
            
            let emitter = SKEmitterNode(fileNamed: "sliceFuse")!
            emitter.position = CGPoint(x: 76, y: 64)
            enemy.addChild(emitter)
            
        } else {
            enemy = SKSpriteNode(imageNamed: "penguin")
            run(SKAction.playSoundFileNamed("lauch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }
        
        // Positioning
        let randomPosition = CGPoint(x: RandomInt(min: 64, max: 960), y: -128)
        enemy.position = position
        
        let randomAngularVelocity = CGFloat(RandomInt(min: -6, max: 6)) / 2.0
        var randomXVelocity = 0
        
        if randomPosition.x < 256 {
            randomXVelocity = RandomInt(min: 8, max: 15)
        } else if randomPosition.x < 512 {
            randomXVelocity = RandomInt(min: 3, max: 5)
        } else if randomPosition.x < 768 {
            randomXVelocity = -RandomInt(min: 3, max: 5)
        } else {
            randomXVelocity = -RandomInt(min: 8, max: 15)
        }
        
        let randomYVelocity = RandomInt(min: 24, max: 32)
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody?.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        enemy.physicsBody?.angularVelocity = randomAngularVelocity
        enemy.physicsBody?.collisionBitMask = 0
        
        addChild(enemy)
        activeEnemies.append(enemy)
        
    }
    
    // MARK: -
    
    override func update(_ currentTime: TimeInterval) {
        if activeEnemies.filter({$0.name == "bombContainer"}).count == 0 {
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
        }
        
        if activeEnemies.count > 0 {
            activeEnemies.filter({$0.position.y < -140}).forEach {
                $0.removeFromParent()
                if let index = activeEnemies.index(of: $0) {
                    activeEnemies.remove(at: index)
                }
            }
        } else {
            if !nextSequenceQueued {
                DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) { [unowned self] in
                    self.tossEnemies()
                }
                nextSequenceQueued = true
            }
        }
    }
    
    // MARK: -
    
    private func tossEnemies() {
        popupTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        let sequenceType = sequence[sequencePosition]
        
        switch sequenceType {
        case .oneNoBomb:
            createEnemy(forceBomb: .never)
            
        case .one:
            createEnemy()
            
        case .twoWithOneBomb:
            createEnemy(forceBomb: .never)
            createEnemy(forceBomb: .always)
            
        case .two:
            for _ in 0..<2 { createEnemy() }
            
        case .three:
            for _ in 0..<3 { createEnemy() }
            
        case .four:
            for _ in 0..<4 { createEnemy() }
            
        case .chain:
            createEnemy()
            for i in 1...4 { DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * Double(i))) { [unowned self] in self.createEnemy() } }
            
        case .fastChain:
            createEnemy()
            for i in 1...4 { DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * Double(i))) { [unowned self] in self.createEnemy() } }
        }
        
        sequencePosition += 1
        nextSequenceQueued = false
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
    
    // MARK: -
    private func positionEnemies() {
        sequence = [.oneNoBomb, .oneNoBomb, .twoWithOneBomb, .twoWithOneBomb, .three, .one, .chain]
        
        for _ in 0 ... 1000 {
            let nextSequence = SequenceType(rawValue: RandomInt(min: 2, max: 7))!
            sequence.append(nextSequence)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [unowned self] in
            self.tossEnemies()
        }
    }
}
