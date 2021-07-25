//
//  GameScene.swift
//  Bounce
//
//  Created by Luca on 09.02.21.
//

import SpriteKit
import GameplayKit

enum GameState {
    case showingLogo
    case playing
    case dead
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var backgroundMusic: SKAudioNode!
    
    var logo: SKSpriteNode!
    var gameOver: SKSpriteNode!
    var gameState = GameState.showingLogo
    
    var scoreLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
        }
    }
    override func didMove(to view: SKView) {
        createPlayer()
        createGround()
        createScore()
        createLogos()
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        physicsWorld.contactDelegate = self
        
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .showingLogo:
            gameState = .playing

            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let wait = SKAction.wait(forDuration: 0.5)
            let activatePlayer = SKAction.run { [unowned self] in
                self.player.physicsBody?.isDynamic = true
                self.startRocks()
            }

            let sequence = SKAction.sequence([fadeOut, wait, activatePlayer, remove])
            logo.run(sequence)

        case .playing:
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))

        case .dead:
            let scene = GameScene(fileNamed: "GameScene")!
            let transition = SKTransition.moveIn(with: SKTransitionDirection.right, duration: 1)
            self.view?.presentScene(scene, transition: transition)
        }
    }
    
    func createPlayer() {
        player = SKSpriteNode(color: .red, size: CGSize(width: 32, height: 32))
        player.zPosition = 10
        player.position = CGPoint(x: frame.width / 2, y: frame.height * 0.75)

        addChild(player)

        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 32, height: 32))
        player.physicsBody!.contactTestBitMask = player.physicsBody!.collisionBitMask
        player.physicsBody?.isDynamic = false

        player.physicsBody?.collisionBitMask = player.physicsBody!.collisionBitMask
    }
    
    func createGround() {
        let groundTexture = SKTexture(imageNamed: "ground")

        for i in 0 ... 1 {
            let ground = SKSpriteNode(texture: groundTexture)
            ground.zPosition = -10
            ground.position = CGPoint(x: (groundTexture.size().width / 2.0 + (groundTexture.size().width * CGFloat(i))), y: groundTexture.size().height / 2)

            ground.physicsBody = SKPhysicsBody(texture: ground.texture!, size: ground.texture!.size())
            ground.physicsBody?.isDynamic = false
            ground.physicsBody?.restitution = 0
            
            let sky = SKSpriteNode(color: .black, size: CGSize(width: 1000, height: 600))
            sky.zPosition = -50
            sky.position = CGPoint(x: 200, y: groundTexture.size().height)
            addChild(sky)
            addChild(ground)
        }
    }
    
    func createScore() {
        scoreLabel = SKLabelNode(fontNamed: "Futura")
        scoreLabel.fontSize = 24

        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontColor = UIColor.white

        addChild(scoreLabel)
    }
    
    func createLogos() {
        logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logo)

        gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOver.alpha = 0
        addChild(gameOver)
    }

    func createRocks() {
        // 1
        let randomHeight = Int.random(in: 25...60)
        let bottomRock = SKSpriteNode(color: .yellow, size: CGSize(width: 25, height: randomHeight))
        bottomRock.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 25, height: randomHeight))
        bottomRock.physicsBody?.isDynamic = false
        bottomRock.zPosition = -20
        bottomRock.zRotation = .pi * 2
        bottomRock.name = "rock"
        // 2
        let rockCollision = SKSpriteNode(imageNamed: "2")
        rockCollision.physicsBody = SKPhysicsBody(rectangleOf: rockCollision.size)
        rockCollision.physicsBody?.isDynamic = false
        rockCollision.size = CGSize(width: 30, height: 30)
        rockCollision.name = "scoreDetect"

        
        addChild(bottomRock)
        addChild(rockCollision)


        // 3
        let randomX = CGFloat.random(in: 0.5...3)
        let xPosition = frame.width + (bottomRock.frame.width * randomX)

        let yPosition = CGFloat(83)

        // this next value affects the width of the gap between rocks
        // make it smaller to make your game harder – if you're feeling evil!
        

        // 4
        bottomRock.position = CGPoint(x: xPosition, y: yPosition)
        rockCollision.position = CGPoint(x: xPosition + (rockCollision.size.width * 2), y: frame.midY)

        let endPosition = frame.width + (bottomRock.frame.width * 2)

        let moveAction = SKAction.moveBy(x: -endPosition, y: 0, duration: 6.2)
        let moveSequence = SKAction.sequence([moveAction, SKAction.removeFromParent()])
        bottomRock.run(moveSequence)
        rockCollision.run(moveSequence)
    }

    func startRocks() {
        let create = SKAction.run { [unowned self] in
            self.createRocks()
        }

        let wait = SKAction.wait(forDuration: 2)
        let sequence = SKAction.sequence([create, wait])
        let repeatForever = SKAction.repeatForever(sequence)

        run(repeatForever)
    }
    override func update(_ currentTime: TimeInterval) {
        guard player != nil else { return }

    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.name == "scoreDetect" || contact.bodyB.node?.name == "scoreDetect" {
            if contact.bodyA.node == player {
                contact.bodyB.node?.removeFromParent()
            } else {
                contact.bodyA.node?.removeFromParent()
            }
            let sound = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
            run(sound)
            
            score += 1

            return
        }

        guard contact.bodyA.node != nil && contact.bodyB.node != nil else {
            return
        }

        if contact.bodyA.node?.name == "rock" || contact.bodyB.node?.name == "rock"  {
            if let explosion = SKEmitterNode(fileNamed: "explosion") {
                explosion.position = player.position
                addChild(explosion)
            }


            gameOver.alpha = 1
            gameState = .dead
            backgroundMusic.run(SKAction.stop())

            player.removeFromParent()
            speed = 0
        }

    }
}
