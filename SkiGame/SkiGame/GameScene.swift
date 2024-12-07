import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Categories for collision detection
    struct PhysicsCategory {
        static let none      : UInt32 = 0
        static let skier     : UInt32 = 0b1      // 1
        static let obstacle  : UInt32 = 0b10     // 2
        static let monster   : UInt32 = 0b100    // 4
    }
    
    // Game elements
    private var skier: SKSpriteNode!
    private var obstacles: [SKSpriteNode] = []
    private var monster: SKSpriteNode?
    private var scoreLabel: SKLabelNode!
    private var startButton: SKSpriteNode!
    private var background: SKSpriteNode!
    
    // Game state
    private var isMonsterChasing = false
    private var score = 0
    private var highScore = UserDefaults.standard.integer(forKey: "HighScore")
    private var gameSpeed: CGFloat = 300.0
    private var isGameRunning = false
    
    // Obstacle types
    enum ObstacleType: CaseIterable {
        case tree
        case rock
        case skier
        case pole
        
        var size: CGSize {
            switch self {
            case .tree:
                return CGSize(width: 40, height: 60)
            case .rock:
                return CGSize(width: 50, height: 40)
            case .skier:
                return CGSize(width: 45, height: 60)  // Aumentato da 30x40 a 45x60
            case .pole:
                return CGSize(width: 25, height: 90)  // Aumentato da 15x70 a 25x90
            }
        }
        
        var color: UIColor {
            switch self {
            case .tree:
                return .green
            case .rock:
                return .gray
            case .skier:
                return .orange
            case .pole:
                return .yellow
            }
        }
    }
    
    private var obstacleGenerationAction: SKAction?
    private var obstacleGenerationNode: SKNode?
    
    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        setupPhysics()
        setupSkier()
        setupStartScreen()
    }
    
    private func setupPhysics() {
        physicsWorld.gravity = .zero  // Remove gravity since we're controlling movement
        physicsWorld.contactDelegate = self
    }
    
    private func setupSkier() {
        skier = SKSpriteNode(imageNamed: "skier_front-min")
        skier.size = CGSize(width: 40, height: 40)
        skier.position = CGPoint(x: frame.midX, y: frame.height * 0.7)  // Position skier higher
        skier.physicsBody = SKPhysicsBody(rectangleOf: skier.size)
        skier.physicsBody?.categoryBitMask = PhysicsCategory.skier
        skier.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.monster
        skier.physicsBody?.collisionBitMask = PhysicsCategory.none
        skier.physicsBody?.allowsRotation = false
        skier.physicsBody?.isDynamic = true
        skier.zPosition = 10
        skier.isHidden = true  // Hide skier until game starts
        addChild(skier)
    }
    
    private func setupStartScreen() {
        // Add background image for start screen
        background = SKSpriteNode(imageNamed: "frosty_background")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.size = self.size
        background.zPosition = -1
        addChild(background)
        
        // Create a rounded rectangle shape for the button
        let buttonPath = CGPath(roundedRect: CGRect(x: -120, y: -35, 
                                                   width: 240, height: 70),
                              cornerWidth: 20,
                              cornerHeight: 20,
                              transform: nil)
        
        // Setup start button with dark blue semi-transparent background
        let buttonShape = SKShapeNode(path: buttonPath)
        buttonShape.fillColor = UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 0.6)
        buttonShape.strokeColor = .white
        buttonShape.lineWidth = 2
        buttonShape.glowWidth = 3
        buttonShape.alpha = 1.0
        
        startButton = SKSpriteNode()
        startButton.position = CGPoint(x: frame.midX, y: frame.height * 0.15)
        startButton.zPosition = 15
        startButton.name = "startButton"
        startButton.addChild(buttonShape)
        
        // Setup del testo del pulsante
        let buttonLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        buttonLabel.text = "Start Game"
        buttonLabel.fontSize = 30
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.horizontalAlignmentMode = .center
        buttonLabel.position = CGPoint(x: 0, y: 0)  // Centro del pulsante
        buttonLabel.zPosition = 16
        
        startButton.addChild(buttonLabel)
        
        // Aggiungi effetto di movimento leggero
        let moveUp = SKAction.moveBy(x: 0, y: 3, duration: 2)
        let moveDown = SKAction.moveBy(x: 0, y: -3, duration: 2)
        let moveSequence = SKAction.sequence([moveUp, moveDown])
        startButton.run(SKAction.repeatForever(moveSequence))
        
        addChild(startButton)
        
        // Hide score label and skier initially
        scoreLabel?.isHidden = true
        skier.isHidden = true
    }
    
    private func setupGameScreen() {
        // Change background to slope background when game starts
        background.texture = SKTexture(imageNamed: "slope_bg-min")
        
        // Reset game difficulty variables
        gameSpeed = 300.0  // Reset alla velocità iniziale
        
        // Setup and show score label with larger font
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 30  // Aumentato da 24 a 30
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.height - 100)
        scoreLabel.zPosition = 15
        scoreLabel.horizontalAlignmentMode = .center
        addChild(scoreLabel)
        
        // Show skier
        skier.isHidden = false
    }
    
    private func startGame() {
        isGameRunning = true
        score = 0
        gameSpeed = 300.0
        
        // Hide start button
        startButton.isHidden = true
        
        // Setup game screen
        setupGameScreen()
        
        // Reset any existing obstacles
        obstacles.forEach { $0.removeFromParent() }
        obstacles.removeAll()
        
        // Start generating obstacles
        startGeneratingObstacles()
    }
    
    private var gameOverNode: SKNode?
    private var gameOverLabel: SKSpriteNode?
    private var finalScoreLabel: SKSpriteNode?
    private var highScoreLabel: SKSpriteNode?
    
    private func createLabelNode(text: String, fontSize: CGFloat, color: UIColor) -> SKSpriteNode {
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont(name: "AvenirNext-Bold", size: fontSize)!,
                .foregroundColor: color
            ]
        )
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 1000, height: 200))
        label.attributedText = attributedString
        label.textAlignment = .center
        label.sizeToFit()
        
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return SKSpriteNode(texture: SKTexture(image: image))
    }
    
    private func gameOver() {
        isGameRunning = false
        skier.isPaused = true
        
        // Ferma la generazione degli ostacoli
        stopGeneratingObstacles()
        
        // Nascondi il punteggio in alto
        scoreLabel?.isHidden = true
        
        // Rimuovi nodi precedenti se esistono
        gameOverNode?.removeFromParent()
        
        // Crea un nuovo nodo contenitore
        gameOverNode = SKNode()
        guard let gameOverNode = gameOverNode else { return }
        
        // Crea lo sfondo sfumato grigio scuro
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = UIColor(white: 0.2, alpha: 0.9)  // Grigio scuro con alpha 0.9
        overlay.strokeColor = .clear
        overlay.zPosition = 14
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverNode.addChild(overlay)
        
        // Game Over Label
        let gameOver = createLabelNode(text: "Game Over!", fontSize: 30, color: .white)
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        gameOver.zPosition = 15
        gameOverNode.addChild(gameOver)
        
        // Final Score Label
        let finalScore = createLabelNode(text: "Final Score: \(score)", fontSize: 30, color: .white)
        finalScore.position = CGPoint(x: frame.midX, y: frame.midY)
        finalScore.zPosition = 15
        gameOverNode.addChild(finalScore)
        
        // High Score Label
        let highScore = createLabelNode(
            text: score > highScore ? "New Record: \(score)!" : "Record: \(highScore)",
            fontSize: 30,
            color: score > highScore ? .systemGreen : .white
        )
        highScore.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        highScore.zPosition = 15
        gameOverNode.addChild(highScore)
        
        // Retry Button
        startButton.position = CGPoint(x: frame.midX, y: frame.height * 0.15)
        startButton.isHidden = false
        if let buttonLabel = startButton.children.first(where: { $0 is SKLabelNode }) as? SKLabelNode {
            buttonLabel.text = "Retry"
            buttonLabel.fontSize = 30
            buttonLabel.fontColor = .white
        }
        
        addChild(gameOverNode)
    }

    // Funzione di utilità per aggiungere ombra ai testi
    private func addDropShadow(to label: SKLabelNode) {
        label.attributedText = NSAttributedString(
            string: label.text ?? "",
            attributes: [
                NSAttributedString.Key.strokeColor: UIColor.black,
                NSAttributedString.Key.strokeWidth: -2.0,
                NSAttributedString.Key.foregroundColor: label.fontColor ?? .white
            ]
        )
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        if let startButton = touchedNodes.first(where: { $0.name == "startButton" }) {
            if !isGameRunning {
                // Rimuovi tutti i nodi della schermata di game over
                children.forEach { node in
                    if node != startButton && node != background && node != skier {
                        node.removeFromParent()
                    }
                }
                
                // Reset game state
                score = 0
                scoreLabel?.isHidden = false
                scoreLabel?.text = "Score: 0"
                
                // Rimuovi tutti gli ostacoli esistenti
                obstacles.forEach { $0.removeFromParent() }
                obstacles.removeAll()
                
                // Rimuovi il mostro se presente
                monster?.removeFromParent()
                monster = nil
                
                // Nascondi il pulsante start
                startButton.isHidden = true
                
                // Assicurati che lo sciatore sia visibile e nella posizione corretta
                skier.isHidden = false
                skier.position = CGPoint(x: frame.midX, y: frame.height * 0.7)
                skier.texture = SKTexture(imageNamed: "skier_front-min")
                
                // Avvia il gioco
                isGameRunning = true
                setupGameScreen()
                startGameLoop()
            }
        } else if isGameRunning {
            // Determina la direzione del movimento basata su dove l'utente tocca lo schermo
            if location.x > frame.midX {
                isMovingRight = true
                isMovingLeft = false
                skier.texture = SKTexture(imageNamed: "right_turn-min")
            } else {
                isMovingLeft = true
                isMovingRight = false
                skier.texture = SKTexture(imageNamed: "left_turn-min")
            }
        }
    }
    
    private var lastUpdateTime: TimeInterval = 0
    private var isMovingRight = false
    private var isMovingLeft = false
    private let moveSpeed: CGFloat = 400.0 // Velocità di movimento laterale
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isGameRunning else { return }
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        
        // Aggiorna la direzione del movimento se l'utente attraversa il centro dello schermo
        if location.x > frame.midX {
            isMovingRight = true
            isMovingLeft = false
            skier.texture = SKTexture(imageNamed: "right_turn-min")
        } else {
            isMovingLeft = true
            isMovingRight = false
            skier.texture = SKTexture(imageNamed: "left_turn-min")
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ferma il movimento quando l'utente rilascia il tocco
        isMovingRight = false
        isMovingLeft = false
        skier.texture = SKTexture(imageNamed: "skier_front-min")
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ferma il movimento anche se il tocco viene cancellato
        isMovingRight = false
        isMovingLeft = false
        skier.texture = SKTexture(imageNamed: "skier_front-min")
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameRunning else { return }
        
        let deltaTime = currentTime - lastUpdateTime
        
        // Movimento laterale dello sciatore
        if isMovingRight {
            let newX = min(skier.position.x + moveSpeed * CGFloat(deltaTime), frame.width - skier.size.width/2)
            skier.position.x = newX
        } else if isMovingLeft {
            let newX = max(skier.position.x - moveSpeed * CGFloat(deltaTime), skier.size.width/2)
            skier.position.x = newX
        }
        
        lastUpdateTime = currentTime
        
        // Increase game speed over time (ridotta la velocità di incremento)
        gameSpeed += 0.1  // Ridotto da 0.2 a 0.1 per una progressione più graduale
        
        // Update score based on game speed
        score += Int(gameSpeed/50)  // Increased score gain
        scoreLabel.text = "Score: \(score)"
        
        // Spawn monster occasionally
        if !isMonsterChasing && Int.random(in: 0...1000) < 2 {
            isMonsterChasing = true
            spawnMonster()
        }
    }
    
    // MARK: - Game Logic
    private func startGeneratingObstacles() {
        // Rimuovi eventuali azioni precedenti
        obstacleGenerationNode?.removeFromParent()
        
        // Crea un nuovo nodo per le azioni
        obstacleGenerationNode = SKNode()
        addChild(obstacleGenerationNode!)
        
        let wait = SKAction.wait(forDuration: 1.5)
        let generate = SKAction.run { [weak self] in
            self?.generateObstacle()
        }
        let sequence = SKAction.sequence([generate, wait])
        obstacleGenerationAction = SKAction.repeatForever(sequence)
        
        // Esegui l'azione sul nodo dedicato
        obstacleGenerationNode?.run(obstacleGenerationAction!)
    }
    
    private func stopGeneratingObstacles() {
        obstacleGenerationNode?.removeFromParent()
        obstacleGenerationNode = nil
    }
    
    private func generateObstacle() {
        let obstacleType = ObstacleType.allCases.randomElement()!
        
        // Create obstacle with appropriate image
        let imageName: String
        switch obstacleType {
        case .tree:
            imageName = "tree-min"
        case .rock:
            imageName = "rock-min"
        case .pole:
            imageName = "pole-min"
        case .skier:
            imageName = "skier-min"
        }
        
        let obstacle = SKSpriteNode(imageNamed: imageName)
        obstacle.size = obstacleType.size
        
        // Position obstacle at bottom of screen
        let randomX = CGFloat.random(in: obstacle.size.width/2...frame.width-obstacle.size.width/2)
        obstacle.position = CGPoint(x: randomX, y: -obstacle.size.height)
        
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        obstacle.physicsBody?.contactTestBitMask = PhysicsCategory.skier
        obstacle.physicsBody?.collisionBitMask = PhysicsCategory.none
        obstacle.physicsBody?.isDynamic = false  // Obstacles don't need physics simulation
        obstacle.zPosition = 5  // Below skier but above background
        
        obstacle.name = String(describing: obstacleType)
        
        addChild(obstacle)
        obstacles.append(obstacle)
        
        // Move obstacle upward
        let moveUp = SKAction.moveBy(x: 0, y: frame.height + obstacle.size.height * 2, duration: Double(frame.height/gameSpeed))
        let remove = SKAction.removeFromParent()
        obstacle.run(SKAction.sequence([moveUp, remove])) { [weak self] in
            self?.obstacles.removeAll { $0 == obstacle }
        }
    }
    
    // MARK: - Monster Logic
    private func spawnMonster() {
        monster = SKSpriteNode(color: .purple, size: CGSize(width: 50, height: 50))
        guard let monster = monster else { return }
        
        monster.position = CGPoint(x: frame.midX, y: -monster.size.height)
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.skier
        monster.physicsBody?.collisionBitMask = PhysicsCategory.none
        monster.physicsBody?.isDynamic = true
        monster.zPosition = 8  // Above obstacles but below skier
        
        addChild(monster)
        chasePlayer()
    }
    
    private func chasePlayer() {
        guard let monster = monster else { return }
        
        let duration: TimeInterval = 5.0  // Chase duration
        let moveUp = SKAction.moveBy(x: 0, y: frame.height + monster.size.height * 2, duration: duration)
        let followSkier = SKAction.run { [weak self] in
            guard let self = self else { return }
            let moveAction = SKAction.moveTo(x: self.skier.position.x, duration: 0.5)
            self.monster?.run(moveAction)
        }
        
        let sequence = SKAction.sequence([
            SKAction.repeat(SKAction.sequence([followSkier, SKAction.wait(forDuration: 0.5)]), count: Int(duration * 2)),
            SKAction.removeFromParent()
        ])
        
        monster.run(sequence) { [weak self] in
            self?.monster = nil
            self?.isMonsterChasing = false
        }
    }
    
    // MARK: - Collision Detection
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.skier | PhysicsCategory.obstacle ||
           collision == PhysicsCategory.skier | PhysicsCategory.monster {
            gameOver()
        }
    }
    
    private func startGameLoop() {
        startGeneratingObstacles()
    }
}