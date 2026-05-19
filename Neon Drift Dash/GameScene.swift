import SpriteKit

final class GameScene: SKScene {
    var onStatsChanged: ((RunStats) -> Void)?
    var onGameOver: ((RunSummary) -> Void)?

    private let boardStyle: BoardStyle
    private let settings: GameSettings
    private let gameState: GameState

    private let player = SKSpriteNode()
    private let cameraNode = SKCameraNode()
    private var targetPosition = CGPoint.zero
    private var playableRect = CGRect.zero

    private var lastUpdateTime: TimeInterval = 0
    private var runTime: TimeInterval = 0
    private var nextObstacleTime: TimeInterval = 0.7
    private var nextShardTime: TimeInterval = 1.1
    private var lastStatsPush: TimeInterval = 0
    private var invulnerableUntil: TimeInterval = 0
    private var scoreAccumulator: Double = 0
    private var currentPose: PlayerPose = .idle

    private var score = 0
    private var shards = 0
    private var combo = 1
    private var comboStreak = 0
    private var bestCombo = 1
    private var shields = 3
    private var wave = 1
    private var missedShards = 0
    private var gameEnded = false

    init(size: CGSize, boardStyle: BoardStyle, settings: GameSettings, gameState: GameState) {
        self.boardStyle = boardStyle
        self.settings = settings
        self.gameState = gameState
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.02, green: 0.00, blue: 0.07, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("GameScene must be created in code.")
    }

    override func didMove(to view: SKView) {
        guard player.parent == nil else { return }

        view.ignoresSiblingOrder = true
        setupScene()
        HapticsManager.shared.play(.start, enabled: settings.hapticsEnabled)
        AudioManager.shared.play(.start, enabled: settings.soundEnabled)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutScene()
    }

    private func setupScene() {
        camera = cameraNode
        addChild(cameraNode)

        setupBackground()
        setupPlayer()
        showWaveBanner("Wave 1: Rooftop Run")
        layoutScene()
        pushStats(force: true)
    }

    private func layoutScene() {
        playableRect = CGRect(
            x: 44,
            y: 110,
            width: max(0, size.width - 88),
            height: max(0, size.height - 260)
        )
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)

        if player.position == .zero {
            targetPosition = CGPoint(x: size.width / 2, y: max(160, size.height * 0.24))
            player.position = targetPosition
        } else {
            targetPosition = clamp(player.position)
            player.position = targetPosition
        }

        enumerateChildNodes(withName: "bgLayer") { node, _ in
            guard let sprite = node as? SKSpriteNode, let texture = sprite.texture else { return }
            let scale = max(self.size.width / texture.size().width, self.size.height / texture.size().height)
            sprite.size = CGSize(width: texture.size().width * scale, height: texture.size().height * scale)
            sprite.position.x = self.size.width / 2
        }
    }

    private func setupBackground() {
        addBackgroundLayer(named: "NightSky", speed: 18, z: -120, fallbackColor: SKColor(red: 0.03, green: 0.0, blue: 0.10, alpha: 1))
        addBackgroundLayer(named: "FarSkyline", speed: 28, z: -105, fallbackColor: SKColor(red: 0.06, green: 0.02, blue: 0.16, alpha: 1))
        addBackgroundLayer(named: "MidBuildings", speed: 42, z: -90, fallbackColor: SKColor(red: 0.08, green: 0.03, blue: 0.20, alpha: 1))
        addBackgroundLayer(named: "RooftopForeground", speed: 76, z: -75, fallbackColor: SKColor(red: 0.08, green: 0.06, blue: 0.13, alpha: 1))

        for index in 0..<8 {
            let line = SKShapeNode(rectOf: CGSize(width: 2, height: size.height * 1.4), cornerRadius: 1)
            line.name = "laneLine"
            line.fillColor = index.isMultiple(of: 2) ? boardStyle.skPrimaryColor.withAlphaComponent(0.18) : boardStyle.skSecondaryColor.withAlphaComponent(0.14)
            line.strokeColor = .clear
            line.zPosition = -55
            line.position = CGPoint(x: CGFloat(index) / 7 * size.width, y: size.height * 0.5)
            line.zRotation = index < 4 ? -0.12 : 0.12
            line.userData = ["speed": 110 + index * 8]
            addChild(line)
        }
    }

    private func addBackgroundLayer(named name: String, speed: CGFloat, z: CGFloat, fallbackColor: SKColor) {
        let texture = AssetManager.textureIfAvailable(name)
        let layerHeight = size.height * 1.08
        for copy in 0..<2 {
            let sprite: SKSpriteNode
            if let texture {
                sprite = SKSpriteNode(texture: texture)
                let scale = max(size.width / texture.size().width, layerHeight / texture.size().height)
                sprite.size = CGSize(width: texture.size().width * scale, height: texture.size().height * scale)
            } else {
                sprite = SKSpriteNode(color: fallbackColor, size: CGSize(width: size.width, height: layerHeight))
            }
            sprite.name = "bgLayer"
            sprite.zPosition = z
            sprite.position = CGPoint(x: size.width / 2, y: size.height / 2 + CGFloat(copy) * sprite.size.height)
            sprite.userData = ["speed": speed]
            addChild(sprite)
        }
    }

    private func setupPlayer() {
        player.texture = AssetManager.playerTexture(pose: .idle, board: boardStyle)
        player.size = CGSize(width: 82, height: 122)
        player.name = "player"
        player.zPosition = 20
        player.position = CGPoint(x: size.width / 2, y: max(160, size.height * 0.24))
        player.color = .white
        addChild(player)

        let boardGlow = SKShapeNode(ellipseOf: CGSize(width: 92, height: 22))
        boardGlow.name = "boardGlow"
        boardGlow.fillColor = boardStyle.skPrimaryColor.withAlphaComponent(0.35)
        boardGlow.strokeColor = boardStyle.skSecondaryColor.withAlphaComponent(0.8)
        boardGlow.lineWidth = 2
        boardGlow.zPosition = -1
        boardGlow.position = CGPoint(x: 0, y: -46)
        player.addChild(boardGlow)

        let trail = SKEmitterNode()
        trail.name = "playerTrail"
        trail.particleTexture = AssetManager.trailTexture(board: boardStyle)
        trail.particleBirthRate = 75
        trail.particleLifetime = 0.42
        trail.particleLifetimeRange = 0.2
        trail.particleSpeed = 36
        trail.particleSpeedRange = 22
        trail.particleScale = 0.22
        trail.particleScaleRange = 0.12
        trail.particleAlpha = 0.75
        trail.particleAlphaSpeed = -1.4
        trail.emissionAngle = -.pi / 2
        trail.emissionAngleRange = .pi / 8
        trail.position = CGPoint(x: 0, y: -58)
        trail.targetNode = self
        player.addChild(trail)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTarget(from: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTarget(from: touches)
    }

    private func updateTarget(from touches: Set<UITouch>) {
        guard !gameEnded, let touch = touches.first else { return }
        targetPosition = clamp(touch.location(in: self))
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, playableRect.minX), playableRect.maxX),
            y: min(max(point.y, playableRect.minY), playableRect.maxY)
        )
    }

    override func update(_ currentTime: TimeInterval) {
        guard !gameEnded else { return }
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let dt = min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime
        runTime += dt

        updateWave()
        updatePlayer(dt: dt)
        updateScrollingNodes(dt: dt)
        updateScore(dt: dt)
        spawnIfNeeded()
        updateHazardsAndCollectibles(dt: dt)
        pushStats(force: false)
    }

    private func updatePlayer(dt: TimeInterval) {
        let smoothing = CGFloat(1 - pow(0.0009, dt))
        let oldX = player.position.x
        player.position.x += (targetPosition.x - player.position.x) * smoothing
        player.position.y += (targetPosition.y - player.position.y) * smoothing

        let velocityX = player.position.x - oldX
        let tilt = min(max(velocityX * 0.035, -0.26), 0.26)
        player.zRotation += (tilt - player.zRotation) * 0.22

        let pose: PlayerPose
        if runTime < invulnerableUntil {
            pose = .hit
        } else if tilt < -0.05 {
            pose = .leanLeft
        } else if tilt > 0.05 {
            pose = .leanRight
        } else {
            pose = .idle
        }
        if currentPose != pose {
            currentPose = pose
            player.texture = AssetManager.playerTexture(pose: pose, board: boardStyle)
        }
    }

    private func updateScrollingNodes(dt: TimeInterval) {
        enumerateChildNodes(withName: "bgLayer") { node, _ in
            let speed = node.userData?["speed"] as? CGFloat ?? 0
            node.position.y -= speed * CGFloat(dt)
            guard let sprite = node as? SKSpriteNode else { return }
            if node.position.y < -sprite.size.height / 2 {
                node.position.y += sprite.size.height * 2
            }
        }

        enumerateChildNodes(withName: "laneLine") { node, _ in
            let speed = node.userData?["speed"] as? CGFloat ?? 100
            node.position.y -= speed * CGFloat(dt)
            if node.position.y < -self.size.height * 0.2 {
                node.position.y += self.size.height * 1.35
            }
        }
    }

    private func updateScore(dt: TimeInterval) {
        scoreAccumulator += dt * Double(18 + wave * 7)
        if scoreAccumulator >= 1 {
            let points = Int(scoreAccumulator)
            score += points
            scoreAccumulator -= Double(points)
        }
    }

    private func updateWave() {
        let nextWave = min(6, Int(runTime / 25) + 1)
        guard nextWave > wave else { return }
        wave = nextWave
        showWaveBanner(waveTitle(for: wave))
        HapticsManager.shared.play(.tap, enabled: settings.hapticsEnabled)
    }

    private func waveTitle(for wave: Int) -> String {
        switch wave {
        case 1: "Wave 1: Rooftop Run"
        case 2: "Wave 2: Faster Traffic"
        case 3: "Wave 3: Drone Swarm"
        case 4: "Wave 4: Neon Storm"
        case 5: "Wave 5: Static Rush"
        default: "Wave 6: Overdrive"
        }
    }

    private func spawnIfNeeded() {
        if runTime >= nextObstacleTime {
            spawnObstaclePattern()
            let interval = max(0.34, 1.08 - Double(wave) * 0.105)
            nextObstacleTime = runTime + Double.random(in: interval * 0.68...interval * 1.14)
        }

        if runTime >= nextShardTime {
            spawnShard()
            nextShardTime = runTime + Double.random(in: 0.55...1.05)
        }
    }

    private func spawnObstaclePattern() {
        let count: Int
        if wave >= 4 && Int.random(in: 0...100) < 34 {
            count = 2
        } else if wave >= 3 && Int.random(in: 0...100) < 22 {
            count = 2
        } else {
            count = 1
        }

        var usedX: [CGFloat] = []
        for _ in 0..<count {
            let allowedKinds: [ObstacleKind] = {
                switch wave {
                case 1: [.cone, .drone]
                case 2: [.cone, .drone, .barrier]
                case 3: [.drone, .drone, .cone, .mine]
                default: ObstacleKind.allCases
                }
            }()
            let kind = allowedKinds.randomElement() ?? .drone
            var x = CGFloat.random(in: playableRect.minX...playableRect.maxX)
            for existing in usedX where abs(existing - x) < 72 {
                x = min(max(x + 86, playableRect.minX), playableRect.maxX)
            }
            usedX.append(x)

            let node = SKSpriteNode(texture: AssetManager.obstacleTexture(kind: kind))
            let scale = CGFloat.random(in: 0.88...1.08)
            node.size = CGSize(width: kind.baseSize.width * scale, height: kind.baseSize.height * scale)
            node.name = "obstacle"
            node.zPosition = 18

            let sideSpawn = wave >= 3 && kind == .drone && Bool.random()
            if sideSpawn {
                node.position = CGPoint(x: size.width + 72, y: CGFloat.random(in: playableRect.midY...playableRect.maxY))
                node.userData = [
                    "vx": -CGFloat(165 + wave * 28),
                    "vy": -CGFloat.random(in: 35...80),
                    "radius": kind.collisionRadius * scale
                ]
            } else {
                node.position = CGPoint(x: x, y: size.height + 90)
                node.userData = [
                    "vx": CGFloat.random(in: -18...18),
                    "vy": -CGFloat(180 + wave * 34) * scale,
                    "radius": kind.collisionRadius * scale
                ]
            }

            node.run(.repeatForever(.sequence([
                .scale(to: 1.05, duration: 0.32),
                .scale(to: 0.96, duration: 0.32)
            ])))
            addChild(node)
        }
    }

    private func spawnShard() {
        let node = SKSpriteNode(texture: AssetManager.shardTexture())
        node.name = "shard"
        node.size = CGSize(width: 36, height: 46)
        node.zPosition = 16
        node.position = CGPoint(
            x: CGFloat.random(in: playableRect.minX...playableRect.maxX),
            y: size.height + 70
        )
        node.userData = [
            "vx": CGFloat.random(in: -16...16),
            "vy": -CGFloat(150 + wave * 22),
            "radius": CGFloat(27)
        ]
        node.run(.repeatForever(.sequence([
            .rotate(byAngle: .pi * 2, duration: 1.2),
            .wait(forDuration: 0.05)
        ])))
        addChild(node)
    }

    private func updateHazardsAndCollectibles(dt: TimeInterval) {
        var nodesToRemove: [SKNode] = []
        let playerRadius: CGFloat = 34

        enumerateChildNodes(withName: "obstacle") { node, _ in
            let vx = node.userData?["vx"] as? CGFloat ?? 0
            let vy = node.userData?["vy"] as? CGFloat ?? -190
            node.position.x += vx * CGFloat(dt)
            node.position.y += vy * CGFloat(dt)

            let radius = node.userData?["radius"] as? CGFloat ?? 32
            if self.distance(self.player.position, node.position) < playerRadius + radius {
                if self.runTime > self.invulnerableUntil {
                    self.handleHit()
                    nodesToRemove.append(node)
                }
            } else if node.position.y < -130 || node.position.x < -140 {
                nodesToRemove.append(node)
            }
        }

        enumerateChildNodes(withName: "shard") { node, _ in
            let vx = node.userData?["vx"] as? CGFloat ?? 0
            let vy = node.userData?["vy"] as? CGFloat ?? -160
            node.position.x += vx * CGFloat(dt)
            node.position.y += vy * CGFloat(dt)

            let radius = node.userData?["radius"] as? CGFloat ?? 25
            if self.distance(self.player.position, node.position) < playerRadius + radius {
                self.collectShard(node)
                nodesToRemove.append(node)
            } else if node.position.y < -80 {
                self.missedShards += 1
                if self.missedShards >= 4 {
                    self.resetCombo()
                    self.missedShards = 0
                }
                nodesToRemove.append(node)
            }
        }

        nodesToRemove.forEach { $0.removeFromParent() }
    }

    private func collectShard(_ node: SKNode) {
        shards += 1
        missedShards = 0
        comboStreak += 1
        if comboStreak % 3 == 0 {
            combo = min(combo + 1, 12)
            bestCombo = max(bestCombo, combo)
            showFloatingText("COMBO x\(combo)", at: node.position, color: boardStyle.skSecondaryColor)
        } else {
            showFloatingText("+\(100 * combo)", at: node.position, color: boardStyle.skPrimaryColor)
        }
        score += 100 * combo
        HapticsManager.shared.play(.collect, enabled: settings.hapticsEnabled)
        AudioManager.shared.play(.collect, enabled: settings.soundEnabled)
        burst(at: node.position, color: boardStyle.skPrimaryColor)
    }

    private func handleHit() {
        shields -= 1
        invulnerableUntil = runTime + 1.35
        resetCombo()
        showFloatingText("SHIELD -1", at: player.position + CGPoint(x: 0, y: 54), color: SKColor(red: 1, green: 0.28, blue: 0.18, alpha: 1))
        burst(at: player.position, color: SKColor(red: 1, green: 0.12, blue: 0.42, alpha: 1))
        shake()

        player.run(.sequence([
            .colorize(with: .white, colorBlendFactor: 0.92, duration: 0.04),
            .wait(forDuration: 0.05),
            .colorize(withColorBlendFactor: 0.0, duration: 0.22),
            .repeat(.sequence([
                .fadeAlpha(to: 0.36, duration: 0.08),
                .fadeAlpha(to: 1.0, duration: 0.08)
            ]), count: 5),
            .fadeAlpha(to: 1.0, duration: 0.02)
        ]))

        HapticsManager.shared.play(.hit, enabled: settings.hapticsEnabled)
        AudioManager.shared.play(.hit, enabled: settings.soundEnabled)

        if shields <= 0 {
            endGame()
        }
    }

    private func resetCombo() {
        combo = 1
        comboStreak = 0
    }

    private func endGame() {
        guard !gameEnded else { return }
        gameEnded = true
        removeAllActions()
        player.removeAllActions()
        HapticsManager.shared.play(.gameOver, enabled: settings.hapticsEnabled)
        AudioManager.shared.play(.gameOver, enabled: settings.soundEnabled)

        let summary = gameState.finishRun(score: score, shards: shards, bestCombo: bestCombo, wave: wave)
        if summary.unlockedBoard != nil {
            HapticsManager.shared.play(.unlock, enabled: settings.hapticsEnabled)
            AudioManager.shared.play(.unlock, enabled: settings.soundEnabled)
        }

        pushStats(force: true, isGameOver: true)
        onGameOver?(summary)
    }

    private func pushStats(force: Bool, isGameOver: Bool = false) {
        guard force || runTime - lastStatsPush > 0.08 else { return }
        lastStatsPush = runTime
        onStatsChanged?(
            RunStats(
                score: score,
                shards: shards,
                combo: combo,
                bestCombo: bestCombo,
                shields: max(0, shields),
                wave: wave,
                waveTitle: waveTitle(for: wave),
                isGameOver: isGameOver
            )
        )
    }

    private func showWaveBanner(_ text: String) {
        let label = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        label.text = text
        label.fontSize = 28
        label.fontColor = .white
        label.zPosition = 80
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        label.alpha = 0
        label.setScale(0.86)

        let glow = label.copy() as? SKLabelNode
        glow?.fontColor = boardStyle.skPrimaryColor
        glow?.alpha = 0.5
        glow?.zPosition = 79
        glow?.position = CGPoint(x: 0, y: -2)
        if let glow {
            label.addChild(glow)
        }

        addChild(label)
        label.run(.sequence([
            .group([.fadeIn(withDuration: 0.18), .scale(to: 1.0, duration: 0.18)]),
            .wait(forDuration: 1.05),
            .group([.fadeOut(withDuration: 0.35), .moveBy(x: 0, y: 18, duration: 0.35)]),
            .removeFromParent()
        ]))
    }

    private func showFloatingText(_ text: String, at position: CGPoint, color: SKColor) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = text.contains("COMBO") ? 22 : 18
        label.fontColor = color
        label.zPosition = 70
        label.position = position
        label.setScale(0.8)
        addChild(label)
        label.run(.sequence([
            .group([.fadeIn(withDuration: 0.05), .scale(to: 1.18, duration: 0.12)]),
            .group([.moveBy(x: 0, y: 52, duration: 0.55), .fadeOut(withDuration: 0.55)]),
            .removeFromParent()
        ]))
    }

    private func burst(at position: CGPoint, color: SKColor) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = AssetManager.trailTexture(board: boardStyle)
        emitter.particleBirthRate = 140
        emitter.numParticlesToEmit = 26
        emitter.particleLifetime = 0.42
        emitter.particleSpeed = 120
        emitter.particleSpeedRange = 80
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.12
        emitter.particleScaleRange = 0.08
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 0.9
        emitter.particleAlphaSpeed = -1.8
        emitter.position = position
        emitter.zPosition = 60
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.8), .removeFromParent()]))
    }

    private func shake() {
        cameraNode.removeAction(forKey: "shake")
        let actions: [SKAction] = (0..<8).map { _ in
            .moveBy(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -6...6), duration: 0.035)
        }
        let reset = SKAction.move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: 0.08)
        cameraNode.run(.sequence(actions + [reset]), withKey: "shake")
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}

private func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}
