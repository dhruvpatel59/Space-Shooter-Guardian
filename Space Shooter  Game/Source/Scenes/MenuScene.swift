//
//  MenuScene.swift
//  Space Shooter  Game
//
//  Created by Antigravity on 10/04/26.
//

import SpriteKit

class MenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        createStarfield()
        setupUI()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        titleLabel.text = "SPACE SHOOTER"
        // Scale font size based on screen width
        titleLabel.fontSize = min(frame.width / 8, 35)
        titleLabel.fontColor = .cyan
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.7)
        addChild(titleLabel)
        
        // Add glow to title
        let titleGlow = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        titleGlow.text = titleLabel.text
        titleGlow.fontSize = titleLabel.fontSize
        titleGlow.fontColor = .cyan
        titleGlow.alpha = 0.3
        titleGlow.position = .zero
        titleGlow.zPosition = -1
        titleLabel.addChild(titleGlow)
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ])
        titleLabel.run(SKAction.repeatForever(pulse))
        
        // Start Button
        let startButton = SKShapeNode(rectOf: CGSize(width: 220, height: 60), cornerRadius: 30)
        startButton.fillColor = .cyan
        startButton.strokeColor = .white
        startButton.lineWidth = 2
        startButton.position = CGPoint(x: frame.midX, y: frame.midY)
        startButton.name = "startButton"
        addChild(startButton)
        
        let startLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        startLabel.text = "LAUNCH MISSION"
        startLabel.fontSize = min(frame.width / 20, 20)
        startLabel.fontColor = .black
        startLabel.verticalAlignmentMode = .center
        startLabel.name = "startButton"
        startButton.addChild(startLabel)
        
        // High Score
        if let currentUser = AuthManager.shared.currentUser {
            let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            highScoreLabel.text = "PILOT BEST: \(currentUser.highScore)"
            highScoreLabel.fontSize = 18
            highScoreLabel.fontColor = .white
            highScoreLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.35)
            addChild(highScoreLabel)
            
            let pilotLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            pilotLabel.text = "ACTIVE PILOT: \(currentUser.email.prefix(upTo: currentUser.email.firstIndex(of: "@") ?? currentUser.email.endIndex))"
            pilotLabel.fontSize = 14
            pilotLabel.fontColor = .gray
            pilotLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.3)
            addChild(pilotLabel)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)
        
        for node in nodesAtPoint {
            if node.name == "startButton" {
                startGame()
                return
            }
        }
    }
    
    private func startGame() {
        let transition = SKTransition.crossFade(withDuration: 1.0)
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        
        if let skView = self.view {
            // Robust delegate discovery: Traverse the responder chain to find the host GameViewController
            var responder: UIResponder? = skView
            while let currentResponder = responder {
                if let delegate = currentResponder as? GameSceneDelegate {
                    gameScene.gameDelegate = delegate
                    break
                }
                responder = currentResponder.next
            }
            
            skView.presentScene(gameScene, transition: transition)
        }
    }
    
    private func createStarfield() {
        for _ in 0..<100 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.3...0.8)
            
            let xPos = CGFloat.random(in: 0...frame.width)
            let yPos = CGFloat.random(in: 0...frame.height)
            star.position = CGPoint(x: xPos, y: yPos)
            star.zPosition = -1
            addChild(star)
            
            let duration = Double.random(in: 20...60)
            let moveDown = SKAction.moveBy(x: 0, y: -(frame.height + 20), duration: duration)
            let resetPos = SKAction.moveBy(x: 0, y: frame.height + 20, duration: 0)
            star.run(SKAction.repeatForever(SKAction.sequence([moveDown, resetPos])))
        }
    }
}
