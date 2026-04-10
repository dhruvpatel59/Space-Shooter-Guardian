//
//  GameScene.swift
//  Space Shooter  Game
//
//  Created by Dhruv Patel on 09/02/25.
//f

import SpriteKit
import GameplayKit

/**
 * GameScene.swift
 * The core engine for the Space Shooter gameplay experience.
 * Manages physics, entity lifecycles via pooling, and combat state.
 */

protocol GameSceneDelegate: AnyObject {
    func didRequestLogout()
}

enum PowerupType: String {
    case shield, tripleShot
}

struct GameConfig {
    static let fireRate: TimeInterval = 0.3
    static let enemySpawnRateInitial: TimeInterval = 2.0
    static let enemySpawnRateMin: TimeInterval = 0.5
    static let enemySpeedInitial: CGFloat = 100
    static let comboGracePeriod: TimeInterval = 2.0
    static let powerupDuration: TimeInterval = 8.0
    
    struct Physics {
        static let laser: UInt32      = 0x1 << 0
        static let enemy: UInt32      = 0x1 << 1
        static let ship: UInt32       = 0x1 << 2
        static let powerup: UInt32    = 0x1 << 3
        static let enemyLaser: UInt32 = 0x1 << 4
        static let boss: UInt32       = 0x1 << 5
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    weak var gameDelegate: GameSceneDelegate?
    
    // Nodes
    private var spaceship: SKNode!
    private let cameraNode = SKCameraNode()
    private var shieldNode: SKShapeNode?
    
    // Labels
    private var scoreLabel: SKLabelNode!
    private var livesLabel: SKLabelNode?
    private var highScoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    
    // State
    private var score: Int = 0 { didSet { scoreLabel?.text = "Score: \(score)" } }
    private var lives: Int = 3 { didSet { livesLabel?.text = "Lives: \(lives)" } }
    private var highScore: Int = 0 { didSet { highScoreLabel?.text = "Best: \(highScore)" } }
    private var level: Int = 1 { 
        didSet { 
            levelLabel?.text = "Level \(level)"
            enemySpawnRate = max(GameConfig.enemySpawnRateMin, GameConfig.enemySpawnRateInitial - (Double(level) * 0.1))
        } 
    }
    
    private var isGameOver = false
    private var touchLocation: CGPoint?
    private var lastFireTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var deltaTime: TimeInterval = 0
    
    // Gameplay Spawning
    private var lastEnemySpawnTime: TimeInterval = 0
    private var enemySpawnRate = GameConfig.enemySpawnRateInitial
    private var enemySpeed = GameConfig.enemySpeedInitial
    
    // Combat State
    private var hasShield = false
    private var hasTripleShot = false
    private var tripleShotEndTime: TimeInterval = 0
    private var comboCount = 0
    private var lastHitTime: TimeInterval = 0
    
    // Boss State
    private var isBossActive = false
    private var bossNode: SKNode?
    private var bossHealth = 0
    private var bossMaxHealth = 10
    private var bossHealthBar: SKShapeNode?
    private var lastBossLevel = 0
    
    // Pools
    private var laserPool: ObjectPool<SKShapeNode>!
    private var enemyPool: ObjectPool<SKNode>!
    private var enemyLaserPool: ObjectPool<SKShapeNode>!
    
    // Haptics
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    
    override func didMove(to view: SKView) {
        setupUI() // Initialize labels first
        setupWorld() // Then load state which might update labels
        setupHaptics()
        setupParallax()
        setupSpaceship()
        setupPools()
    }
    
    private func setupWorld() {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        self.camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = CGPoint(x: frame.midX, y: frame.midY)
        
        if let currentUser = AuthManager.shared.currentUser {
            highScore = currentUser.highScore
        }
    }
    
    private func setupHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
    }
    
    private func setupParallax() {
        createStarfield()
    }
    
    private func setupSpaceship() {
        spaceship = createSpaceshipNode()
        addChild(spaceship)
        setupShipPhysics()
    }
    
    private func setupPools() {
        laserPool = ObjectPool(maxObjects: 20) { [weak self] in self?.createLaserNode() ?? SKShapeNode() }
        laserPool.addToParent(self)
        
        enemyPool = ObjectPool(maxObjects: 8) { [weak self] in self?.createEnemyNode() ?? SKNode() }
        enemyPool.addToParent(self)
        
        enemyLaserPool = ObjectPool(maxObjects: 15) { [weak self] in self?.createEnemyLaserNode() ?? SKShapeNode() }
        enemyLaserPool.addToParent(self)
    }
    
    private func createSpaceshipNode() -> SKNode {
        let ship = SKNode()
        ship.position = CGPoint(x: frame.midX, y: frame.height * 0.2)
        
        let body = SKShapeNode(path: spaceshipPath())
        body.fillColor = .white
        body.strokeColor = .cyan
        body.lineWidth = 2
        body.name = "spaceship"
        body.addGlow(radius: 10, color: .cyan)
        ship.addChild(body)
        
        // Add cockpit
        let cockpit = SKShapeNode(circleOfRadius: 6)
        cockpit.fillColor = .cyan
        cockpit.strokeColor = .white
        cockpit.alpha = 0.4
        cockpit.position = CGPoint(x: 0, y: 10)
        ship.addChild(cockpit)
        
        // Engine glows and flames
        setupEngines(for: ship)
        
        return ship
    }
    
    private func setupEngines(for ship: SKNode) {
        let enginePositions = [CGPoint(x: -10, y: -28), CGPoint(x: 10, y: -28)]
        let pulseAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.5),
            SKAction.scale(to: 0.8, duration: 0.5)
        ]))
        
        for pos in enginePositions {
            let glow = SKShapeNode(circleOfRadius: 4)
            glow.fillColor = .cyan
            glow.strokeColor = .clear
            glow.position = pos
            glow.run(pulseAction)
            ship.addChild(glow)
            
            let flames = createEngineFlame()
            flames.position = CGPoint(x: pos.x, y: pos.y - 4)
            ship.addChild(flames)
        }
    }
    
    private func spaceshipPath() -> CGPath {
        let path = CGMutablePath()
        
        // Simpler, upward-pointing spaceship
        path.move(to: CGPoint(x: 0, y: 30))       // Top point
        path.addLine(to: CGPoint(x: 20, y: -20))  // Right bottom
        path.addLine(to: CGPoint(x: 10, y: -15))  // Right engine indent
        path.addLine(to: CGPoint(x: -10, y: -15)) // Left engine indent
        path.addLine(to: CGPoint(x: -20, y: -20)) // Left bottom
        path.closeSubpath()
        
        return path
    }
    
    private func createEngineFlame() -> SKEmitterNode {
        let flames = SKEmitterNode()
        // Create a circle shape for particles
        let circle = SKShapeNode(circleOfRadius: 1)
        circle.fillColor = .cyan
        circle.strokeColor = .clear
        
        // Convert shape to texture
        let texture = SKView().texture(from: circle)
        flames.particleTexture = texture
        flames.particleBirthRate = 60
        flames.particleLifetime = 0.2
        flames.particleSpeed = 20
        flames.particleSpeedRange = 10
        flames.particleAlpha = 0.5
        flames.particleAlphaRange = 0.25
        flames.particleScale = 0.1
        flames.particleScaleRange = 0.05
        flames.particleColorBlendFactor = 1.0
        flames.particleColor = .cyan
        flames.yAcceleration = -100
        return flames
    }
    
    // Add these new touch handling methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if node.name == "logoutButton" {
                gameDelegate?.didRequestLogout()
                return
            }
        }
        
        if isGameOver {
            restartGame()
            return
        }
        touchLocation = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        updateEnvironment(currentTime)
        if !isGameOver {
            updateShipPosition()
            updateEnemySpawning(currentTime)
            checkPowerupExpiration(currentTime)
            checkComboExpiration(currentTime)
        }
    }
    
    private func updateEnvironment(_ currentTime: TimeInterval) {
        // Parallax or other background updates could go here
    }
    
    private func checkPowerupExpiration(_ currentTime: TimeInterval) {
        if hasTripleShot && currentTime > tripleShotEndTime {
            hasTripleShot = false
        }
    }
    
    private func checkComboExpiration(_ currentTime: TimeInterval) {
        if comboCount > 0 && currentTime - lastHitTime > GameConfig.comboGracePeriod {
            comboCount = 0
            // Optionally hide combo UI here
        }
    }
    
    private func updateShipPosition() {
        guard let location = touchLocation else { return }
        
        let dx = location.x - spaceship.position.x
        let dy = location.y - spaceship.position.y
        let distance = sqrt(dx*dx + dy*dy)
        
        if distance > 5 {
            let speed: CGFloat = 8.0
            let newX = spaceship.position.x + (dx/distance) * speed
            let newY = spaceship.position.y + (dy/distance) * speed
            
            let padding: CGFloat = 20
            spaceship.position = CGPoint(
                x: max(padding, min(frame.width - padding, newX)),
                y: max(padding, min(frame.height - padding, newY))
            )
            
            if lastUpdateTime - lastFireTime > GameConfig.fireRate {
                fireLaser()
                lastFireTime = lastUpdateTime
            }
        }
    }
    
    // Separate enemy spawning logic
    private func updateEnemySpawning(_ currentTime: TimeInterval) {
        if isGameOver || isBossActive { return }
        
        // Trigger boss every 5 levels
        if level % 5 == 0 && lastBossLevel < level && score >= (level - 1) * 1000 + 300 {
            spawnBoss()
            return
        }
        
        if currentTime - lastEnemySpawnTime > enemySpawnRate {
            spawnEnemy()
            lastEnemySpawnTime = currentTime
        }
    }
    
    private func createLaserNode() -> SKShapeNode {
        let laser = SKShapeNode(rectOf: CGSize(width: 4, height: 25))
        laser.fillColor = .cyan
        laser.strokeColor = .white
        laser.glowWidth = 3
        laser.name = "laser"
        
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 4, height: 25))
        physicsBody.categoryBitMask = GameConfig.Physics.laser
        physicsBody.contactTestBitMask = GameConfig.Physics.enemy | GameConfig.Physics.boss
        physicsBody.collisionBitMask = 0
        laser.physicsBody = physicsBody
        
        return laser
    }
    
    private func createEnemyLaserNode() -> SKShapeNode {
        let laser = SKShapeNode(rectOf: CGSize(width: 4, height: 18))
        laser.fillColor = .red
        laser.strokeColor = .orange
        laser.name = "enemyLaser"
        
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 4, height: 18))
        physicsBody.categoryBitMask = GameConfig.Physics.enemyLaser
        physicsBody.contactTestBitMask = GameConfig.Physics.ship
        physicsBody.collisionBitMask = 0
        laser.physicsBody = physicsBody
        
        return laser
    }
    
    private func fireEnemyLaser(from position: CGPoint) {
        guard !isGameOver, let laser = enemyLaserPool.get() else { return }
        
        laser.position = position
        laser.isHidden = false
        
        let moveAction = SKAction.moveBy(x: 0, y: -frame.height, duration: 1.5)
        let hideAction = SKAction.run { laser.isHidden = true }
        
        laser.run(SKAction.sequence([moveAction, hideAction]))
    }
    
    private func fireLaser() {
        if hasTripleShot {
            fireSingleLaser(offset: CGPoint(x: -15, y: 10), angle: 0.15)
            fireSingleLaser(offset: CGPoint(x: 0, y: 30), angle: 0)
            fireSingleLaser(offset: CGPoint(x: 15, y: 10), angle: -0.15)
        } else {
            fireSingleLaser(offset: CGPoint(x: 0, y: 30), angle: 0)
        }
        
        // Trigger haptic for shooting
        lightHaptic.impactOccurred()
    }
    
    private func fireSingleLaser(offset: CGPoint, angle: CGFloat) {
        // Get a laser from the pool
        guard let laser = laserPool.get() else { return }
        
        // Position and show the laser
        laser.position = CGPoint(x: spaceship.position.x + offset.x, y: spaceship.position.y + offset.y)
        laser.zRotation = angle
        laser.isHidden = false
        
        // Create actions for the laser - calculate trajectory based on angle
        let dx = -sin(angle) * frame.height
        let dy = cos(angle) * frame.height
        let moveAction = SKAction.moveBy(x: dx, y: dy, duration: 0.3)
        let hideAction = SKAction.run { laser.isHidden = true }
        
        // Add the actions
        laser.run(SKAction.sequence([moveAction, hideAction]))
    }
    
    private func createEnemyNode() -> SKNode {
        let enemy = SKNode()
        let body = SKShapeNode(path: enemyShipPath())
        body.fillColor = .red
        body.strokeColor = .orange
        body.lineWidth = 2
        body.addGlow(radius: 8, color: .red)
        enemy.addChild(body)
        
        let physicsBody = SKPhysicsBody(polygonFrom: enemyShipPath())
        physicsBody.categoryBitMask = GameConfig.Physics.enemy
        physicsBody.contactTestBitMask = GameConfig.Physics.laser | GameConfig.Physics.ship
        physicsBody.collisionBitMask = 0
        enemy.physicsBody = physicsBody
        
        return enemy
    }
    
    private func enemyShipPath() -> CGPath {
        let path = CGMutablePath()
        
        // Evil-looking ship pointing downward
        path.move(to: CGPoint(x: 0, y: -25))      // Bottom point
        path.addLine(to: CGPoint(x: 25, y: 15))   // Right wing
        path.addLine(to: CGPoint(x: 15, y: 20))   // Right indent
        path.addLine(to: CGPoint(x: 0, y: 10))    // Top center
        path.addLine(to: CGPoint(x: -15, y: 20))  // Left indent
        path.addLine(to: CGPoint(x: -25, y: 15))  // Left wing
        path.closeSubpath()
        
        return path
    }
    
    // Update enemy spawning with varied patterns and improved speeds
    private func spawnEnemy() {
        guard !isGameOver,
              let enemy = enemyPool.get() else { return }
        
        enemy.removeAllActions()
        
        let xPos = CGFloat.random(in: 40...(frame.width - 40))
        enemy.position = CGPoint(x: xPos, y: frame.height + 40)
        enemy.isHidden = false
        var actions: [SKAction] = []
        let pattern = Int.random(in: 0...2)
        
        switch pattern {
        case 0: // Straight
            actions = [SKAction.moveBy(x: 0, y: -(frame.height + 100), duration: 4.0)]
        case 1: // Zig-zag
            actions = [
                SKAction.moveBy(x: -100, y: -200, duration: 1.0),
                SKAction.moveBy(x: 100, y: -200, duration: 1.0),
                SKAction.moveBy(x: -100, y: -(frame.height - 600), duration: 1.0)
            ]
        default: // Curved
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addCurve(
                to: CGPoint(x: 0, y: -(frame.height + 100)),
                control1: CGPoint(x: 100, y: -(frame.height/3)),
                control2: CGPoint(x: -100, y: -(frame.height*2/3))
            )
            actions = [SKAction.follow(path, asOffset: true, orientToPath: false, duration: 4.0)]
        }
        
        // Add hide action at the end
        actions.append(SKAction.run { [weak enemy] in
            enemy?.isHidden = true
        })
        
        // Run the sequence
        enemy.run(SKAction.sequence(actions))
        
        // Enemy shooting logic (random interval)
        let wait = SKAction.wait(forDuration: Double.random(in: 1.0...3.0))
        let fire = SKAction.run { [weak self, weak enemy] in
            guard let self = self, let enemy = enemy, !enemy.isHidden else { return }
            self.fireEnemyLaser(from: enemy.position)
        }
        let shootingSequence = SKAction.repeatForever(SKAction.sequence([wait, fire]))
        enemy.run(shootingSequence)
    }
    
    // Handle collisions
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch contactMask {
        case GameConfig.Physics.laser | GameConfig.Physics.enemy:
            handleLaserEnemyCollision(contact)
        case GameConfig.Physics.ship | GameConfig.Physics.enemy:
            handleShipEnemyCollision(contact)
        case GameConfig.Physics.ship | GameConfig.Physics.powerup:
            handleShipPowerupCollision(contact)
        case GameConfig.Physics.ship | GameConfig.Physics.enemyLaser:
            handleShipEnemyLaserCollision(contact)
        case GameConfig.Physics.laser | GameConfig.Physics.boss:
            handleLaserBossCollision(contact)
        default:
            break
        }
    }
    
    private func handleLaserBossCollision(_ contact: SKPhysicsContact) {
        let laserNode = (contact.bodyA.categoryBitMask == GameConfig.Physics.laser) ? contact.bodyA.node : contact.bodyB.node
        guard let laser = laserNode, !laser.isHidden else { return }
        
        laser.isHidden = true
        bossHealth -= 1
        updateBossHealthBar()
        
        // Visual feedback on boss
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.05),
            SKAction.colorize(with: .red, colorBlendFactor: 0.0, duration: 0.05)
        ])
        bossNode?.run(flash)
        
        if bossHealth <= 0 {
            defeatBoss()
        }
        
        mediumHaptic.impactOccurred()
    }
    
    private func defeatBoss() {
        guard isBossActive, let boss = bossNode else { return }
        isBossActive = false
        
        createBigExplosion(at: boss.position)
        shakeScreen(duration: 0.5)
        heavyHaptic.impactOccurred()
        
        boss.removeFromParent()
        bossNode = nil
        
        score += 2000 // Boss bonus
        showAnnouncement("BOSS DEFEATED!")
        
        // Spawn guaranteed powerups
        for _ in 0..<3 {
            let offset = CGPoint(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -50...50))
            spawnPowerup(at: CGPoint(x: boss.position.x + offset.x, y: boss.position.y + offset.y))
        }
    }
    
    private func handleShipEnemyLaserCollision(_ contact: SKPhysicsContact) {
        let laserNode = (contact.bodyA.categoryBitMask == GameConfig.Physics.enemyLaser) ? contact.bodyA.node : contact.bodyB.node
        guard let laser = laserNode, !laser.isHidden else { return }
        
        laser.isHidden = true
        
        if hasShield {
            deactivateShield()
            shakeScreen(duration: 0.2)
            return
        }
        
        createExplosion(at: spaceship.position)
        heavyHaptic.impactOccurred()
        handleShipDestroyed()
    }
    
    private func handleLaserEnemyCollision(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node,
              let nodeB = contact.bodyB.node else { return }
        
        let laser = (contact.bodyA.categoryBitMask == GameConfig.Physics.laser) ? nodeA : nodeB
        let enemy = (contact.bodyA.categoryBitMask == GameConfig.Physics.enemy) ? nodeA : nodeB
        
        // Ensure nodes haven't been dealt with already
        guard !laser.isHidden && !enemy.isHidden else { return }
        
        // Hide both laser and enemy
        laser.isHidden = true
        enemy.isHidden = true
        
        // Stop enemy actions
        enemy.removeAllActions()
        
        // Create visual effects
        createFlash(at: enemy.position)
        createExplosion(at: enemy.position)
        shakeScreen(duration: 0.1)
        
        // Check combo
        let now = lastUpdateTime
        if now - lastHitTime < GameConfig.comboGracePeriod {
            comboCount += 1
        } else {
            comboCount = 1
        }
        lastHitTime = now
        
        // Add score with combo multiplier
        let comboBonus = min(comboCount, 5) // Cap multiplier at 5x
        let points = 100 * comboBonus
        score += points
        
        // Show combo feedback
        if comboCount > 1 {
            showComboText(at: enemy.position, combo: comboCount)
        }
        
        // Trigger haptic for enemy destruction
        mediumHaptic.impactOccurred()
        
        // Potential Power-up drop (15% chance)
        if Int.random(in: 1...100) <= 15 {
            spawnPowerup(at: enemy.position)
        }
        
        // Check for level up
        checkLevelUp()
    }
    
    private func handleShipEnemyCollision(_ contact: SKPhysicsContact) {
        if hasShield {
            deactivateShield()
            shakeScreen(duration: 0.3)
            return
        }
        
        let enemy = (contact.bodyA.categoryBitMask == GameConfig.Physics.enemy) ? contact.bodyA.node : contact.bodyB.node
        guard let enemy = enemy, !enemy.isHidden else { return }
        
        // Ensure enemy hasn't been dealt with already
        guard !enemy.isHidden else { return }
        
        // Hide enemy
        enemy.isHidden = true
        
        // Stop enemy actions
        enemy.removeAllActions()
        
        // Create explosions
        createExplosion(at: enemy.position)
        createExplosion(at: spaceship.position)
        
        // Handle ship destruction
        heavyHaptic.impactOccurred()
        handleShipDestroyed()
    }
    
    private func createExplosion(at position: CGPoint) {
        // Create main explosion
        let explosion = SKEmitterNode()
        // Create a circle shape for particles
        let circle = SKShapeNode(circleOfRadius: 1)
        circle.fillColor = .red
        circle.strokeColor = .clear
        
        // Convert shape to texture
        let texture = SKView().texture(from: circle)
        explosion.particleTexture = texture
        explosion.particleBirthRate = 500
        explosion.numParticlesToEmit = 15
        explosion.particleLifetime = 0.7
        explosion.particleSpeed = 150
        explosion.particleSpeedRange = 100
        explosion.particleAlpha = 1
        explosion.particleAlphaSpeed = -1.5
        explosion.particleScale = 0.4
        explosion.particleScaleRange = 0.3
        explosion.particleScaleSpeed = -0.3
        explosion.particleColorBlendFactor = 1.0
        explosion.particleColor = .red
        explosion.position = position
        
        // Add secondary explosion with different color
        let secondaryExplosion = explosion.copy() as! SKEmitterNode
        secondaryExplosion.particleColor = .orange
        secondaryExplosion.particleSpeed = 100
        secondaryExplosion.particleScale = 0.3
        
        addChild(explosion)
        addChild(secondaryExplosion)
        
        // Remove explosion nodes after delay
        let wait = SKAction.wait(forDuration: 0.7)
        let remove = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([wait, remove]))
        secondaryExplosion.run(SKAction.sequence([wait, remove]))
    }
    
    private func createFlash(at position: CGPoint) {
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.position = position
        flash.alpha = 0.7
        
        addChild(flash)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let remove = SKAction.removeFromParent()
        flash.run(SKAction.sequence([fadeOut, remove]))
    }
    
    private func setupUI() {
        // Create UI container
        let uiContainer = SKNode()
        
        // Top bar for level
        let topBar = SKShapeNode(rect: CGRect(x: 0, y: frame.height - 10, width: frame.width, height: 50))
        topBar.fillColor = .black
        topBar.strokeColor = .clear
        topBar.alpha = 0.3
        uiContainer.addChild(topBar)
        
        // Profile indicator (top left)
        if let currentUser = AuthManager.shared.currentUser {
            let pilotLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            pilotLabel.text = "PILOT: \(currentUser.email.prefix(upTo: currentUser.email.firstIndex(of: "@") ?? currentUser.email.endIndex))"
            pilotLabel.fontSize = 12
            pilotLabel.fontColor = .white
            pilotLabel.alpha = 0.5
            pilotLabel.verticalAlignmentMode = .center
            pilotLabel.position = CGPoint(x: 80, y: frame.height - 65)
            uiContainer.addChild(pilotLabel)
        }

        // Level indicator (top center)
        levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelLabel.text = "Level \(level)"
        levelLabel.fontSize = 25
        levelLabel.fontColor = .cyan
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: frame.midX, y: frame.height - 65)
        uiContainer.addChild(levelLabel)
        
        // Logout Button (top right)
        let logoutButton = SKLabelNode(fontNamed: "AvenirNext-Bold")
        logoutButton.text = "EXIT"
        logoutButton.name = "logoutButton"
        logoutButton.fontSize = 24
        logoutButton.fontColor = .systemRed
        logoutButton.verticalAlignmentMode = .center
        logoutButton.position = CGPoint(x: frame.width - 55, y: frame.height - 65)
        logoutButton.zPosition = 101
        
        // Add a larger invisible hit area for better touch reliability
        let hitBuffer = SKShapeNode(rectOf: CGSize(width: 80, height: 50), cornerRadius: 5)
        hitBuffer.fillColor = .clear
        hitBuffer.strokeColor = .clear
        hitBuffer.name = "logoutButton" // Same name so both trigger the same logic
        logoutButton.addChild(hitBuffer)
        
        uiContainer.addChild(logoutButton)
        
        uiContainer.zPosition = 100
        
        // Bottom bar
        let bottomBar = SKShapeNode(rect: CGRect(x: 0, y: 0, width: frame.width, height: 50))
        bottomBar.fillColor = .black
        bottomBar.strokeColor = .clear
        bottomBar.alpha = 0.3
        uiContainer.addChild(bottomBar)
        
        // Score (bottom right)
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: frame.midX, y: 75)
        uiContainer.addChild(scoreLabel)
        
        // High score (bottom center)
        highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        highScoreLabel.text = "Best: \(highScore)"
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = .white
        highScoreLabel.verticalAlignmentMode = .center
        highScoreLabel.position = CGPoint(x: frame.midX, y: 45)
        uiContainer.addChild(highScoreLabel)
        
        // Lives (bottom left)
        let livesContainer = SKNode()
        livesContainer.position = CGPoint(x: frame.midX, y: -25)
        setupLivesDisplay(livesContainer)
        uiContainer.addChild(livesContainer)
        
        addChild(uiContainer)
    }
    
    private func setupShipPhysics() {
        let physicsBody = SKPhysicsBody(polygonFrom: spaceshipPath())
        physicsBody.categoryBitMask = GameConfig.Physics.ship
        physicsBody.contactTestBitMask = GameConfig.Physics.enemy | GameConfig.Physics.enemyLaser | GameConfig.Physics.powerup
        physicsBody.collisionBitMask = 0
        spaceship.physicsBody = physicsBody
    }
    
    private func handleShipDestroyed() {
        guard !spaceship.isHidden else { return }
        
        lives -= 1
        updateLifeIcons()  // Update the visual representation of lives
        
        // Create big explosion
        createBigExplosion(at: spaceship.position)
        
        // Show game over screen if no lives left
        if lives <= 0 {
            gameOver()
        }
    }
    
    private func createBigExplosion(at position: CGPoint) {
        let explosion = SKEmitterNode()
        // Create a circle shape for particles
        let circle = SKShapeNode(circleOfRadius: 1)
        circle.fillColor = .white
        circle.strokeColor = .clear
        
        // Convert shape to texture
        let texture = SKView().texture(from: circle)
        explosion.particleTexture = texture
        explosion.particleBirthRate = 1000
        explosion.numParticlesToEmit = 50
        explosion.particleLifetime = 1.0
        explosion.particleSpeed = 200
        explosion.particleSpeedRange = 150
        explosion.particleAlpha = 1
        explosion.particleAlphaSpeed = -1.0
        explosion.particleScale = 0.5
        explosion.particleScaleRange = 0.5
        explosion.particleScaleSpeed = -0.3
        explosion.particleColorBlendFactor = 1.0
        explosion.particleColor = .white
        explosion.position = position
        
        addChild(explosion)
        
        let wait = SKAction.wait(forDuration: 1.0)
        let remove = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([wait, remove]))
    }
    
    private func gameOver() {
        // Set game over state first
        isGameOver = true
        
        // Hide the ship
        spaceship.isHidden = true
        
        // Stop all enemy movements
        enemyPool.reset()
        
        // Update high score in AuthManager
        AuthManager.shared.updateHighScore(score)
        
        // Refresh local label
        if let currentUser = AuthManager.shared.currentUser {
            highScore = currentUser.highScore
        }
        
        // Create game over screen with animation
        let gameOverNode = SKNode()
        gameOverNode.name = "gameOverNode"
        
        // Background overlay with fade in
        let overlay = SKShapeNode(rect: CGRect(origin: .zero, size: frame.size))
        overlay.fillColor = .black
        overlay.strokeColor = .clear
        overlay.alpha = 0
        let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.5)
        overlay.run(fadeIn)
        gameOverNode.addChild(overlay)
        
        // Game Over text with scale effect
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        gameOverLabel.setScale(0)
        gameOverNode.addChild(gameOverLabel)
        
        // Final score
        let finalScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        finalScoreLabel.text = "Final Score: \(score)"
        finalScoreLabel.fontSize = 32
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        finalScoreLabel.alpha = 0
        gameOverNode.addChild(finalScoreLabel)
        
        // Tap to restart text
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel.text = "Tap to Restart"
        restartLabel.fontSize = 24
        restartLabel.fontColor = .cyan
        restartLabel.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        restartLabel.alpha = 0
        gameOverNode.addChild(restartLabel)
        
        addChild(gameOverNode)
        
        // Animate elements
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let fadeInText = SKAction.fadeIn(withDuration: 0.3)
        
        gameOverLabel.run(scaleUp)
        finalScoreLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            fadeInText
        ]))
        
        // Add blinking animation to restart text after fade in
        restartLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            fadeInText,
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.fadeIn(withDuration: 0.5)
            ]))
        ]))
    }
    
    private func restartGame() {
        let transition = SKTransition.crossFade(withDuration: 0.5)
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = self.scaleMode
        newScene.gameDelegate = self.gameDelegate
        self.view?.presentScene(newScene, transition: transition)
    }
    
    private func showComboText(at position: CGPoint, combo: Int) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "\(combo)X COMBO!"
        label.fontSize = 18 + CGFloat(combo * 2) // Grow with combo
        label.fontColor = .orange
        label.position = CGPoint(x: position.x, y: position.y + 20)
        label.zPosition = 10
        addChild(label)
        
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([scaleUp, SKAction.group([fadeOut, moveUp]), remove]))
    }
    
    private func checkLevelUp() {
        if score >= level * 1000 {  // Level up every 1000 points
            level += 1
            showLevelUpMessage()
        }
    }
    
    private func showLevelUpMessage() {
        let levelUpLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelUpLabel.text = "Level Up!"
        levelUpLabel.fontSize = 36
        levelUpLabel.fontColor = .cyan
        levelUpLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        
        addChild(levelUpLabel)
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        levelUpLabel.run(SKAction.sequence([scaleUp, fadeOut, remove]))
    }
    
    private func updateLifeIcons() {
        for i in 0..<3 {
            if let lifeContainer = childNode(withName: "lifeIcon\(i)") {
                // Update heart color
                if let heart = lifeContainer.children.last as? SKShapeNode {
                    heart.fillColor = i < lives ? .red : .gray
                }
                // Update glow color
                if let glow = lifeContainer.children.first as? SKEffectNode,
                   let glowHeart = glow.children.first as? SKShapeNode {
                    glowHeart.fillColor = i < lives ? .red : .gray
                }
                
                // Remove or add pulse animation
                lifeContainer.removeAllActions()
                if i < lives {
                    let pulseAction = SKAction.sequence([
                        SKAction.scale(to: 1.2, duration: 0.5),
                        SKAction.scale(to: 1.0, duration: 0.5)
                    ])
                    lifeContainer.run(SKAction.repeatForever(pulseAction))
                } else {
                    lifeContainer.setScale(1.0)
                }
            }
        }
    }
    
    // Add this new function for life icon path
    private func lifeIconPath() -> CGPath {
        let path = CGMutablePath()
        
        // Create a heart-shaped path
        path.move(to: CGPoint(x: 0, y: -5))
        path.addCurve(
            to: CGPoint(x: 0, y: 7),
            control1: CGPoint(x: 8, y: 4),
            control2: CGPoint(x: 0, y: 7)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: -5),
            control1: CGPoint(x: 0, y: 7),
            control2: CGPoint(x: -8, y: 4)
        )
        
        return path
    }
    
    // Update the lives display in setupUI
    private func setupLivesDisplay(_ livesContainer: SKNode) {
        // Container for life icons
        let iconsContainer = SKNode()
        iconsContainer.position = CGPoint(x: 0, y: 0)
        
        for i in 0..<3 {
            let lifeContainer = SKNode()
            lifeContainer.position = CGPoint(x: CGFloat(i * 30) - 30, y: 0)
            lifeContainer.name = "lifeIcon\(i)"
            
            // Create the heart shape
            let heart = SKShapeNode(path: lifeIconPath())
            heart.fillColor = i < lives ? .red : .gray
            heart.strokeColor = .white
            heart.lineWidth = 1
            heart.setScale(1.5)
            
            // Add glow effect
            let glow = SKEffectNode()
            let filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 2.0])
            glow.filter = filter
            glow.shouldRasterize = true
            
            let glowHeart = heart.copy() as! SKShapeNode
            glowHeart.fillColor = i < lives ? .red : .gray
            glowHeart.strokeColor = .clear
            glowHeart.alpha = 0.5
            
            glow.addChild(glowHeart)
            
            // Add pulse animation
            let pulseAction = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            
            if i < lives {
                lifeContainer.run(SKAction.repeatForever(pulseAction))
            }
            
            lifeContainer.addChild(glow)
            lifeContainer.addChild(heart)
            iconsContainer.addChild(lifeContainer)
        }
        
        livesContainer.addChild(iconsContainer)
    }
    
    // Parallax Starfield Logic
    private func createStarfield() {
        // Create 3 layers of stars with different speeds
        addStarLayer(count: 60, speed: 20, size: 1, alpha: 0.3)  // Background (slow)
        addStarLayer(count: 40, speed: 40, size: 1.5, alpha: 0.5) // Midground
        addStarLayer(count: 20, speed: 80, size: 2, alpha: 0.8)   // Foreground (fast)
    }
    
    private func addStarLayer(count: Int, speed: CGFloat, size: CGFloat, alpha: CGFloat) {
        for _ in 0..<count {
            let star = SKShapeNode(circleOfRadius: size)
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = alpha
            
            let xPos = CGFloat.random(in: 0...frame.width)
            let yPos = CGFloat.random(in: 0...frame.height)
            star.position = CGPoint(x: xPos, y: yPos)
            star.zPosition = -1 // Ensure stars are behind game entities
            addChild(star)
            
            // Endless scrolling action - safety guard for 0 duration
            let scrollHeight = frame.height > 0 ? frame.height : UIScreen.main.bounds.height
            let duration = max(0.1, scrollHeight / speed)
            
            let moveDown = SKAction.moveBy(x: 0, y: -(scrollHeight + 20), duration: duration)
            let resetPos = SKAction.moveBy(x: 0, y: (scrollHeight + 20), duration: 0)
            star.run(SKAction.repeatForever(SKAction.sequence([moveDown, resetPos])))
        }
    }
    
    // MARK: - Game "Juiciness" Effects
    
    private func shakeScreen(duration: Float = 0.2) {
        let shakeAction = SKAction.shake(duration: duration, amplitudeX: 10, amplitudeY: 10)
        cameraNode.run(shakeAction)
    }
    
    private func activateShield() {
        guard !hasShield else { return }
        hasShield = true
        
        // Create shield visual
        let shield = SKShapeNode(circleOfRadius: 40)
        shield.strokeColor = .cyan
        shield.fillColor = UIColor.cyan.withAlphaComponent(0.2)
        shield.lineWidth = 2
        shield.name = "shield"
        
        // Pulse animation
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.5),
            SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        ])
        shield.run(SKAction.repeatForever(pulse))
        
        spaceship.addChild(shield)
        self.shieldNode = shield
    }
    
    private func deactivateShield() {
        hasShield = false
        shieldNode?.removeFromParent()
        shieldNode = nil
        
        // Visual feedback for breaking
        createFlash(at: spaceship.position)
        mediumHaptic.impactOccurred()
    }
    
    private func handleShipPowerupCollision(_ contact: SKPhysicsContact) {
        let powerupNode = (contact.bodyA.categoryBitMask == GameConfig.Physics.powerup) ? contact.bodyA.node : contact.bodyB.node
        
        if let typeString = powerupNode?.userData?["type"] as? String,
           let type = PowerupType(rawValue: typeString) {
            
            switch type {
            case .shield:
                activateShield()
            case .tripleShot:
                activateTripleShot()
            }
        } else {
            // Default to shield if type is missing
            activateShield()
        }
        
        powerupNode?.removeFromParent()
        
        // Visual/Haptic Feedback
        mediumHaptic.impactOccurred()
        
        // Show floating text
        showPowerupText(at: spaceship.position)
    }
    
    private func activateTripleShot() {
        hasTripleShot = true
        tripleShotEndTime = lastUpdateTime + GameConfig.powerupDuration
        
        // Visual feedback
        let flash = SKAction.sequence([
            SKAction.colorize(with: .cyan, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.1)
        ])
        spaceship.run(SKAction.repeat(flash, count: 3))
    }
    
    private func showPowerupText(at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "POWER UP!"
        label.fontSize = 20
        label.fontColor = .cyan
        label.position = position
        label.zPosition = 10
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove]))
    }
    
    private func spawnPowerup(at position: CGPoint) {
        let type: PowerupType = Bool.random() ? .shield : .tripleShot
        
        let powerup = SKShapeNode(circleOfRadius: 18)
        powerup.fillColor = type == .shield ? .cyan : .purple
        powerup.strokeColor = .white
        powerup.lineWidth = 2
        powerup.position = position
        powerup.name = "powerup"
        
        // Store type in userData
        powerup.userData = ["type": type.rawValue]
        
        // Add icon
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = type == .shield ? "S" : "T"
        label.fontSize = 14
        label.verticalAlignmentMode = .center
        label.fontColor = .white
        powerup.addChild(label)
        
        let physicsBody = SKPhysicsBody(circleOfRadius: 18)
        physicsBody.categoryBitMask = GameConfig.Physics.powerup
        physicsBody.contactTestBitMask = GameConfig.Physics.ship
        physicsBody.collisionBitMask = 0
        powerup.physicsBody = physicsBody
        
        addChild(powerup)
        
        // Floating animation
        let scrollHeight = UIScreen.main.bounds.height
        let moveDown = SKAction.moveBy(x: 0, y: -(scrollHeight + 100), duration: 6.0)
        let remove = SKAction.removeFromParent()
        powerup.run(SKAction.sequence([moveDown, remove]))
        
        // Glow
        powerup.addGlow(radius: 12, color: type == .shield ? .cyan : .purple)
    }
}

extension SKAction {
    static func shake(duration: Float, amplitudeX: Int, amplitudeY: Int) -> SKAction {
        let numberOfShakes = Int(duration * 60)
        var actionsArray: [SKAction] = []
        for _ in 0..<numberOfShakes {
            let dx = CGFloat(Int.random(in: -amplitudeX...amplitudeX))
            let dy = CGFloat(Int.random(in: -amplitudeY...amplitudeY))
            let shakeAction = SKAction.moveBy(x: dx, y: dy, duration: 0.01)
            actionsArray.append(shakeAction.reversed())
            actionsArray.append(shakeAction)
        }
        return SKAction.sequence(actionsArray)
    }
}

// Extension to add glow effect
extension SKShapeNode {
    func addGlow(radius: CGFloat, color: SKColor) {
        let effectNode = SKEffectNode()
        let filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": radius])
        effectNode.filter = filter
        effectNode.shouldRasterize = true
        
        let glow = self.copy() as! SKShapeNode
        glow.strokeColor = color
        glow.fillColor = color
        glow.alpha = 0.3
        
        effectNode.addChild(glow)
        self.addChild(effectNode)
    }
}

// Add this helper function for gradient textures
extension GameScene {
    private func spawnBoss() {
        isBossActive = true
        lastBossLevel = level
        bossHealth = 20 + (level * 2) // Boss health scales
        bossMaxHealth = bossHealth
        
        let boss = createBossNode()
        boss.position = CGPoint(x: frame.midX, y: frame.height + 150)
        addChild(boss)
        self.bossNode = boss
        
        // Announce Boss
        showAnnouncement("BOSS WARNING!")
        
        // Boss Entrance Action
        let entrance = SKAction.moveTo(y: frame.height * 0.75, duration: 3.0)
        let shooting = SKAction.run { [weak self] in
            self?.bossAttackPattern()
        }
        let sequence = SKAction.sequence([entrance, SKAction.repeatForever(SKAction.sequence([shooting, SKAction.wait(forDuration: 2.5)]))])
        boss.run(sequence)
        
        // Add health bar
        setupBossHealthBar(for: boss)
    }
    
    private func createBossNode() -> SKNode {
        let boss = SKNode()
        
        // Body (Main hull)
        let hull = SKShapeNode(rectOf: CGSize(width: 120, height: 80), cornerRadius: 10)
        hull.fillColor = .darkGray
        hull.strokeColor = .red
        hull.lineWidth = 4
        boss.addChild(hull)
        
        // Wings
        let leftWing = SKShapeNode(rectOf: CGSize(width: 40, height: 100), cornerRadius: 5)
        leftWing.position = CGPoint(x: -80, y: 0)
        leftWing.fillColor = .red
        boss.addChild(leftWing)
        
        let rightWing = SKShapeNode(rectOf: CGSize(width: 40, height: 100), cornerRadius: 5)
        rightWing.position = CGPoint(x: 80, y: 0)
        rightWing.fillColor = .red
        boss.addChild(rightWing)
        
        // Physics
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 200, height: 100))
        physicsBody.categoryBitMask = GameConfig.Physics.boss
        physicsBody.contactTestBitMask = GameConfig.Physics.laser | GameConfig.Physics.ship
        physicsBody.collisionBitMask = 0
        boss.physicsBody = physicsBody
        
        return boss
    }
    
    private func setupBossHealthBar(for boss: SKNode) {
        let barWidth: CGFloat = 150
        let barHeight: CGFloat = 10
        
        let background = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 2)
        background.fillColor = .black
        background.alpha = 0.5
        background.position = CGPoint(x: 0, y: 70)
        boss.addChild(background)
        
        let bar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 2)
        bar.fillColor = .red
        bar.position = CGPoint(x: 0, y: 70)
        boss.addChild(bar)
        self.bossHealthBar = bar
    }
    
    private func updateBossHealthBar() {
        guard let bar = bossHealthBar else { return }
        let healthRatio = CGFloat(bossHealth) / CGFloat(bossMaxHealth)
        bar.xScale = max(0, healthRatio)
    }
    
    private func bossAttackPattern() {
        guard let boss = bossNode, !boss.isHidden else { return }
        
        // Radial burst
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4
            let dx = -sin(angle) * 1.5
            let dy = -cos(angle) * 1.5
            
            fireCustomLaser(from: boss.position, direction: CGPoint(x: dx, y: dy))
        }
    }
    
    private func fireCustomLaser(from pos: CGPoint, direction: CGPoint) {
        guard let laser = enemyLaserPool.get() else { return }
        laser.position = pos
        laser.isHidden = false
        laser.removeAllActions()
        
        let moveAction = SKAction.moveBy(x: direction.x * frame.height, y: direction.y * frame.height, duration: 2.0)
        let hideAction = SKAction.run { laser.isHidden = true }
        laser.run(SKAction.sequence([moveAction, hideAction]))
    }
    
    private func showAnnouncement(_ text: String) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 40
        label.fontColor = .red
        label.position = CGPoint(x: frame.midX, y: frame.midY)
        label.zPosition = 50
        label.alpha = 0
        addChild(label)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
}

extension SKTexture {
    convenience init(size: CGSize, _ draw: (CGContext) -> Void) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            draw(context.cgContext)
        }
        self.init(image: image)
    }
}
