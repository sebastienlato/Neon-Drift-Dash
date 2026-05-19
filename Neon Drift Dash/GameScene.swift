import SpriteKit

final class GameScene: SKScene {
    var onStatsChanged: ((RunStats) -> Void)?
    var onGameOver: ((RunSummary) -> Void)?

    private let boardStyle: BoardStyle
    private let settings: GameSettings
    private let gameState: GameState

    private let player = SKSpriteNode()
    private let cameraNode = SKCameraNode()
    private let playerAura = SKShapeNode()
    private let shieldBubble = SKShapeNode()
    private var targetPosition = CGPoint.zero
    private var playableRect = CGRect.zero
    private var dragOffset = CGPoint.zero
    private var hasActiveDrag = false

    private var lastUpdateTime: TimeInterval = 0
    private var runTime: TimeInterval = 0
    private var nextObstacleTime: TimeInterval = 1.05
    private var nextShardTime: TimeInterval = 0.85
    private var lastStatsPush: TimeInterval = 0
    private var invulnerableUntil: TimeInterval = 0
    private var lastHitTime: TimeInterval = -10
    private var scoreAccumulator: Double = 0
    private var currentPose: PlayerPose = .idle
    private var recentObstacleXs: [(x: CGFloat, expires: TimeInterval)] = []

    private var score = 0
    private var shards = 0
    private var combo = 1
    private var comboStreak = 0
    private var bestCombo = 1
    private var shields = 3
    private var wave = 1
    private var missedShards = 0
    private var gameEnded = false

    private var laneXs: [CGFloat] {
        guard playableRect.width > 0 else { return [size.width / 2] }
        let laneCount = 5
        return (0..<laneCount).map { index in
            let progress = CGFloat(index) / CGFloat(laneCount - 1)
            return playableRect.minX + playableRect.width * progress
        }
    }

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

    func shutdown() {
        isPaused = true
        onStatsChanged = nil
        onGameOver = nil
        hasActiveDrag = false
        removeAllActions()
        removeAllChildren()
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
        let horizontalInset = max(34, size.width * 0.105)
        let bottomInset = max(126, size.height * 0.16)
        let topInset = max(184, size.height * 0.235)
        let maxY = max(bottomInset + 180, size.height - topInset)
        playableRect = CGRect(
            x: horizontalInset,
            y: bottomInset,
            width: max(0, size.width - horizontalInset * 2),
            height: max(180, maxY - bottomInset)
        )
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)

        let playerWidth = min(92, max(76, size.width * 0.21))
        player.size = CGSize(width: playerWidth, height: playerWidth * 1.48)
        playerAura.path = CGPath(ellipseIn: CGRect(x: -playerWidth * 0.62, y: -playerWidth * 0.92, width: playerWidth * 1.24, height: playerWidth * 1.7), transform: nil)
        shieldBubble.path = CGPath(ellipseIn: CGRect(x: -playerWidth * 0.70, y: -playerWidth * 1.02, width: playerWidth * 1.4, height: playerWidth * 1.88), transform: nil)

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
        addBackgroundLayer(named: "NightSky", speed: 10, sway: 5, z: -120, fallbackColor: SKColor(red: 0.03, green: 0.0, blue: 0.10, alpha: 1))
        addBackgroundLayer(named: "FarSkyline", speed: 22, sway: 10, z: -105, fallbackColor: SKColor(red: 0.06, green: 0.02, blue: 0.16, alpha: 1))
        addBackgroundLayer(named: "MidBuildings", speed: 38, sway: 16, z: -90, fallbackColor: SKColor(red: 0.08, green: 0.03, blue: 0.20, alpha: 1))
        addBackgroundLayer(named: "RooftopForeground", speed: 82, sway: 6, z: -75, fallbackColor: SKColor(red: 0.08, green: 0.06, blue: 0.13, alpha: 1))

        for index in 0..<8 {
            let line = SKShapeNode(rectOf: CGSize(width: 2, height: size.height * 1.4), cornerRadius: 1)
            line.name = "laneLine"
            line.fillColor = index.isMultiple(of: 2) ? boardStyle.skPrimaryColor.withAlphaComponent(0.22) : boardStyle.skSecondaryColor.withAlphaComponent(0.17)
            line.strokeColor = .clear
            line.glowWidth = 4
            line.blendMode = .add
            line.zPosition = -55
            line.position = CGPoint(x: CGFloat(index) / 7 * size.width, y: size.height * 0.5)
            line.zRotation = index < 4 ? -0.12 : 0.12
            line.userData = ["speed": 110 + index * 8]
            addChild(line)
        }

        addAmbientStreaks()
    }

    private func addBackgroundLayer(named name: String, speed: CGFloat, sway: CGFloat, z: CGFloat, fallbackColor: SKColor) {
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
            sprite.userData = ["speed": speed, "sway": sway, "phase": CGFloat(copy) * 1.9 + abs(z) * 0.03]
            addChild(sprite)
        }
    }

    private func addAmbientStreaks() {
        let emitter = SKEmitterNode()
        emitter.name = "ambientStreaks"
        emitter.particleTexture = AssetManager.trailTexture(board: boardStyle)
        emitter.particleBirthRate = 22
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.4
        emitter.particlePositionRange = CGVector(dx: size.width * 1.3, dy: 20)
        emitter.particleSpeed = 260
        emitter.particleSpeedRange = 90
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 10
        emitter.particleScale = 0.08
        emitter.particleScaleRange = 0.05
        emitter.particleAlpha = 0.28
        emitter.particleAlphaRange = 0.16
        emitter.particleAlphaSpeed = -0.22
        emitter.particleBlendMode = .add
        emitter.position = CGPoint(x: size.width / 2, y: size.height + 80)
        emitter.zPosition = -62
        emitter.targetNode = self
        addChild(emitter)
    }

    private func setupPlayer() {
        player.texture = AssetManager.playerTexture(pose: .idle, board: boardStyle)
        player.name = "player"
        player.zPosition = 20
        player.position = CGPoint(x: size.width / 2, y: max(160, size.height * 0.24))
        player.color = .white
        addChild(player)

        playerAura.name = "playerAura"
        playerAura.fillColor = boardStyle.skPrimaryColor.withAlphaComponent(0.13)
        playerAura.strokeColor = boardStyle.skSecondaryColor.withAlphaComponent(0.36)
        playerAura.lineWidth = 2
        playerAura.glowWidth = 12
        playerAura.blendMode = .add
        playerAura.zPosition = -3
        playerAura.run(.repeatForever(.sequence([
            .group([.fadeAlpha(to: 0.42, duration: 0.56), .scale(to: 1.08, duration: 0.56)]),
            .group([.fadeAlpha(to: 0.24, duration: 0.56), .scale(to: 0.98, duration: 0.56)])
        ])))
        player.addChild(playerAura)

        shieldBubble.name = "shieldBubble"
        shieldBubble.fillColor = .clear
        shieldBubble.strokeColor = boardStyle.skPrimaryColor.withAlphaComponent(0.78)
        shieldBubble.lineWidth = 2.5
        shieldBubble.glowWidth = 10
        shieldBubble.blendMode = .add
        shieldBubble.zPosition = 3
        shieldBubble.alpha = 0
        player.addChild(shieldBubble)

        let boardGlow = SKShapeNode(ellipseOf: CGSize(width: 92, height: 22))
        boardGlow.name = "boardGlow"
        boardGlow.fillColor = boardStyle.skPrimaryColor.withAlphaComponent(0.42)
        boardGlow.strokeColor = boardStyle.skSecondaryColor.withAlphaComponent(0.8)
        boardGlow.lineWidth = 2
        boardGlow.glowWidth = 10
        boardGlow.blendMode = .add
        boardGlow.zPosition = -1
        boardGlow.position = CGPoint(x: 0, y: -46)
        player.addChild(boardGlow)

        let trail = SKEmitterNode()
        trail.name = "playerTrail"
        trail.particleTexture = AssetManager.trailTexture(board: boardStyle)
        trail.particleBirthRate = 120
        trail.particleLifetime = 0.56
        trail.particleLifetimeRange = 0.22
        trail.particleSpeed = 56
        trail.particleSpeedRange = 32
        trail.particleScale = 0.28
        trail.particleScaleRange = 0.14
        trail.particleAlpha = 0.88
        trail.particleAlphaSpeed = -1.6
        trail.particleBlendMode = .add
        trail.emissionAngle = -.pi / 2
        trail.emissionAngleRange = .pi / 7
        trail.position = CGPoint(x: 0, y: -50)
        trail.targetNode = self
        player.addChild(trail)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameEnded, let touch = touches.first else { return }
        hasActiveDrag = true
        let location = touch.location(in: self)
        dragOffset = distance(location, player.position) < 150 ? player.position - location : .zero
        updateTarget(from: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTarget(from: touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        hasActiveDrag = false
        dragOffset = .zero
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        hasActiveDrag = false
        dragOffset = .zero
    }

    private func updateTarget(from touches: Set<UITouch>) {
        guard !gameEnded, let touch = touches.first else { return }
        targetPosition = clamp(touch.location(in: self) + dragOffset)
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
        let smoothing = CGFloat(1 - pow(hasActiveDrag ? 0.000035 : 0.00055, dt))
        let oldX = player.position.x
        player.position.x += (targetPosition.x - player.position.x) * smoothing
        player.position.y += (targetPosition.y - player.position.y) * smoothing

        let velocityX = player.position.x - oldX
        let steering = (targetPosition.x - player.position.x) * 0.004
        let tilt = min(max(velocityX * 0.04 + steering, -0.34), 0.34)
        player.zRotation += (tilt - player.zRotation) * 0.24
        playerAura.zRotation = -player.zRotation * 0.45

        if runTime < invulnerableUntil {
            let pulse = 0.42 + 0.32 * abs(sin(runTime * 14))
            shieldBubble.alpha = pulse
            shieldBubble.setScale(1.0 + 0.04 * CGFloat(abs(sin(runTime * 10))))
        } else {
            shieldBubble.alpha = max(0, shieldBubble.alpha - CGFloat(dt) * 2.4)
        }

        let pose: PlayerPose
        if runTime - lastHitTime < 0.30 {
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
            let sway = node.userData?["sway"] as? CGFloat ?? 0
            let phase = node.userData?["phase"] as? CGFloat ?? 0
            node.position.y -= speed * CGFloat(dt)
            node.position.x = self.size.width / 2 + sin(CGFloat(self.runTime) * 0.36 + phase) * sway
            guard let sprite = node as? SKSpriteNode else { return }
            if node.position.y < -sprite.size.height / 2 {
                node.position.y += sprite.size.height * 2
            }
        }

        enumerateChildNodes(withName: "laneLine") { node, _ in
            let speed = node.userData?["speed"] as? CGFloat ?? 100
            node.position.y -= (speed + CGFloat(self.wave * 9)) * CGFloat(dt)
            if node.position.y < -self.size.height * 0.2 {
                node.position.y += self.size.height * 1.35
            }
        }
    }

    private func updateScore(dt: TimeInterval) {
        scoreAccumulator += dt * Double(22 + wave * 8)
        if scoreAccumulator >= 1 {
            let points = Int(scoreAccumulator)
            score += points
            scoreAccumulator -= Double(points)
        }
    }

    private func updateWave() {
        let nextWave = min(6, Int(runTime / 28) + 1)
        guard nextWave > wave else { return }
        wave = nextWave
        showWaveBanner(waveTitle(for: wave))
        HapticsManager.shared.play(.tap, enabled: settings.hapticsEnabled)
        AudioManager.shared.play(.waveStart, enabled: settings.soundEnabled)
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
        recentObstacleXs.removeAll { $0.expires < runTime }

        if runTime >= nextObstacleTime, activeNodeCount(named: "obstacle") < min(10, 5 + wave) {
            spawnObstaclePattern()
            let interval = max(0.43, 1.12 - Double(wave) * 0.09)
            nextObstacleTime = runTime + Double.random(in: interval * 0.78...interval * 1.18)
        }

        if runTime >= nextShardTime, activeNodeCount(named: "shard") < 7 {
            spawnShard()
            nextShardTime = runTime + Double.random(in: 0.62...1.05)
        }
    }

    private func spawnObstaclePattern() {
        let count: Int
        if wave >= 5 && Int.random(in: 0...100) < 32 {
            count = 2
        } else if wave >= 3 && Int.random(in: 0...100) < 18 {
            count = 2
        } else {
            count = 1
        }

        var usedLaneIndexes: [Int] = []
        for spawnIndex in 0..<count {
            let allowedKinds: [ObstacleKind] = {
                switch wave {
                case 1: [.cone, .drone]
                case 2: [.cone, .drone, .barrier]
                case 3: [.drone, .drone, .cone, .mine]
                default: ObstacleKind.allCases
                }
            }()
            let kind = allowedKinds.randomElement() ?? .drone
            let laneIndex = pickObstacleLane(used: usedLaneIndexes, avoidPlayerLane: wave <= 2 && spawnIndex == 0)
            usedLaneIndexes.append(laneIndex)
            let x = laneXs[laneIndex] + CGFloat.random(in: -12...12)
            recentObstacleXs.append((x: x, expires: runTime + 1.75))

            let node = SKSpriteNode(texture: AssetManager.obstacleTexture(kind: kind))
            let scale = CGFloat.random(in: 0.88...1.08)
            node.size = CGSize(width: kind.baseSize.width * scale, height: kind.baseSize.height * scale)
            node.name = "obstacle"
            node.zPosition = 18

            let sideSpawn = wave >= 3 && kind == .drone && Bool.random() && count == 1
            if sideSpawn {
                let sideY = pickSideSpawnY()
                node.position = CGPoint(x: size.width + 118, y: sideY)
                node.userData = [
                    "vx": -CGFloat(155 + wave * 24),
                    "vy": -CGFloat.random(in: 22...56),
                    "radius": kind.collisionRadius * scale,
                    "armedAt": runTime + 0.34
                ]
                showSpawnWarning(at: CGPoint(x: size.width - 26, y: sideY), sideWarning: true)
            } else {
                node.position = CGPoint(x: x, y: size.height + 126 + CGFloat(spawnIndex) * 34)
                node.userData = [
                    "vx": CGFloat.random(in: -12...12),
                    "vy": -CGFloat(168 + wave * 30) * scale,
                    "radius": kind.collisionRadius * scale,
                    "armedAt": runTime + 0.32
                ]
                showSpawnWarning(at: CGPoint(x: x, y: size.height - 82), sideWarning: false)
            }

            node.alpha = 0.82
            node.setScale(0.9)
            node.run(.repeatForever(.sequence([
                .scale(to: 1.05, duration: 0.32),
                .scale(to: 0.96, duration: 0.32)
            ])))
            node.run(.fadeAlpha(to: 1, duration: 0.22))
            addChild(node)
        }
    }

    private func spawnShard() {
        let node = SKSpriteNode(texture: AssetManager.shardTexture())
        node.name = "shard"
        node.size = CGSize(width: 42, height: 54)
        node.zPosition = 16
        let x = pickShardX()
        node.position = CGPoint(
            x: x,
            y: size.height + 82
        )
        node.userData = [
            "vx": CGFloat.random(in: -10...10),
            "vy": -CGFloat(142 + wave * 20),
            "radius": CGFloat(39)
        ]
        node.blendMode = .add
        node.run(.repeatForever(.sequence([
            .scale(to: 1.12, duration: 0.38),
            .scale(to: 0.94, duration: 0.38)
        ])), withKey: "pulse")
        node.run(.repeatForever(.sequence([
            .rotate(byAngle: .pi * 2, duration: 1.2),
            .wait(forDuration: 0.05)
        ])), withKey: "spin")
        addChild(node)
    }

    private func pickObstacleLane(used: [Int], avoidPlayerLane: Bool) -> Int {
        let lanes = laneXs
        guard lanes.count > 1 else { return 0 }
        let playerLane = lanes.enumerated().min(by: { abs($0.element - player.position.x) < abs($1.element - player.position.x) })?.offset ?? lanes.count / 2

        var candidates = Array(lanes.indices)
        candidates.removeAll { lane in
            used.contains(lane) || used.contains(where: { abs($0 - lane) <= 1 })
        }
        if avoidPlayerLane, candidates.count > 1 {
            candidates.removeAll { $0 == playerLane }
        }
        if candidates.isEmpty {
            candidates = Array(lanes.indices).filter { !used.contains($0) }
        }
        return candidates.randomElement() ?? playerLane
    }

    private func pickSideSpawnY() -> CGFloat {
        var candidates = stride(from: playableRect.minY + 44, through: playableRect.maxY - 20, by: max(58, playableRect.height / 6)).map { CGFloat($0) }
        candidates.removeAll { abs($0 - player.position.y) < 118 }
        return candidates.randomElement() ?? min(max(player.position.y + 138, playableRect.minY + 50), playableRect.maxY - 10)
    }

    private func pickShardX() -> CGFloat {
        let lanes = laneXs
        let safeLanes = lanes.filter { laneX in
            !recentObstacleXs.contains { abs($0.x - laneX) < 58 }
        }
        if Bool.random(), let nearPlayer = lanes.min(by: { abs($0 - player.position.x) < abs($1 - player.position.x) }), !recentObstacleXs.contains(where: { abs($0.x - nearPlayer) < 58 }) {
            return nearPlayer + CGFloat.random(in: -16...16)
        }
        return (safeLanes.randomElement() ?? lanes.randomElement() ?? size.width / 2) + CGFloat.random(in: -16...16)
    }

    private func showSpawnWarning(at position: CGPoint, sideWarning: Bool) {
        let container = SKNode()
        container.name = "warning"
        container.zPosition = 55
        container.position = position

        let marker = SKShapeNode()
        let path = CGMutablePath()
        if sideWarning {
            path.move(to: CGPoint(x: -18, y: 0))
            path.addLine(to: CGPoint(x: 14, y: 18))
            path.addLine(to: CGPoint(x: 14, y: -18))
        } else {
            path.move(to: CGPoint(x: 0, y: -18))
            path.addLine(to: CGPoint(x: -20, y: 16))
            path.addLine(to: CGPoint(x: 20, y: 16))
        }
        path.closeSubpath()
        marker.path = path
        marker.fillColor = boardStyle.skSecondaryColor.withAlphaComponent(0.72)
        marker.strokeColor = .white.withAlphaComponent(0.88)
        marker.lineWidth = 2
        marker.glowWidth = 8
        marker.blendMode = .add
        container.addChild(marker)

        let line = SKShapeNode(rectOf: CGSize(width: sideWarning ? 5 : 54, height: sideWarning ? 64 : 4), cornerRadius: 2)
        line.fillColor = boardStyle.skPrimaryColor.withAlphaComponent(0.52)
        line.strokeColor = .clear
        line.glowWidth = 7
        line.blendMode = .add
        line.position = sideWarning ? CGPoint(x: 20, y: 0) : CGPoint(x: 0, y: 24)
        container.addChild(line)

        addChild(container)
        container.run(.sequence([
            .repeat(.sequence([
                .fadeAlpha(to: 0.25, duration: 0.10),
                .fadeAlpha(to: 1.0, duration: 0.10)
            ]), count: 3),
            .fadeOut(withDuration: 0.16),
            .removeFromParent()
        ]))
    }

    private func updateHazardsAndCollectibles(dt: TimeInterval) {
        var nodesToRemove: [SKNode] = []
        let playerRadius = min(player.size.width, player.size.height) * 0.31

        enumerateChildNodes(withName: "obstacle") { node, _ in
            let vx = node.userData?["vx"] as? CGFloat ?? 0
            let vy = node.userData?["vy"] as? CGFloat ?? -190
            node.position.x += vx * CGFloat(dt)
            node.position.y += vy * CGFloat(dt)

            let radius = node.userData?["radius"] as? CGFloat ?? 32
            let armedAt = node.userData?["armedAt"] as? TimeInterval ?? 0
            let isReadable = self.runTime >= armedAt && node.position.y < self.size.height - 18 && node.position.x < self.size.width + 24
            if isReadable && self.distance(self.player.position, node.position) < playerRadius + radius {
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
            showComboPulse()
            AudioManager.shared.play(.comboIncrease, enabled: settings.soundEnabled)
        } else {
            showFloatingText("+\(100 * combo)", at: node.position, color: boardStyle.skPrimaryColor)
        }
        score += 100 * combo
        HapticsManager.shared.play(.collect, enabled: settings.hapticsEnabled)
        AudioManager.shared.play(.collect, enabled: settings.soundEnabled)
        collectBurst(at: node.position)
        pushStats(force: true)
    }

    private func handleHit() {
        shields -= 1
        invulnerableUntil = runTime + 1.35
        lastHitTime = runTime
        resetCombo()
        showFloatingText("SHIELD -1", at: player.position + CGPoint(x: 0, y: 54), color: SKColor(red: 1, green: 0.28, blue: 0.18, alpha: 1))
        hitBurst(at: player.position)
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
            AudioManager.shared.play(.shieldBreak, enabled: settings.soundEnabled)
            endGame()
        } else {
            pushStats(force: true)
        }
    }

    private func resetCombo() {
        combo = 1
        comboStreak = 0
    }

    private func endGame() {
        guard !gameEnded else { return }
        gameEnded = true
        hasActiveDrag = false
        enumerateChildNodes(withName: "obstacle") { node, _ in
            node.userData?["vx"] = CGFloat.zero
            node.userData?["vy"] = CGFloat.zero
        }
        enumerateChildNodes(withName: "shard") { node, _ in
            node.userData?["vx"] = CGFloat.zero
            node.userData?["vy"] = CGFloat.zero
        }
        HapticsManager.shared.play(.gameOver, enabled: settings.hapticsEnabled)
        AudioManager.shared.play(.gameOver, enabled: settings.soundEnabled)

        let summary = gameState.finishRun(score: score, shards: shards, bestCombo: bestCombo, wave: wave)
        if summary.unlockedBoard != nil {
            HapticsManager.shared.play(.unlock, enabled: settings.hapticsEnabled)
            AudioManager.shared.play(.unlock, enabled: settings.soundEnabled)
        }

        showFloatingText("DASH ENDED", at: player.position + CGPoint(x: 0, y: 86), color: .white)
        ringFlash(at: player.position, color: boardStyle.skSecondaryColor, radius: 88)
        run(.sequence([
            .wait(forDuration: 0.45),
            .run { [weak self] in
                self?.pushStats(force: true, isGameOver: true)
                self?.onGameOver?(summary)
            }
        ]), withKey: "gameOverPacing")
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
        let container = SKNode()
        container.name = "popup"
        container.zPosition = 82
        container.position = CGPoint(x: size.width / 2, y: size.height * 0.73)
        container.alpha = 0
        container.setScale(0.84)

        let plateWidth = min(size.width - 42, 338)
        let plate = SKShapeNode(rectOf: CGSize(width: plateWidth, height: 70), cornerRadius: 16)
        plate.fillColor = SKColor(red: 0.05, green: 0.02, blue: 0.12, alpha: 0.78)
        plate.strokeColor = boardStyle.skPrimaryColor.withAlphaComponent(0.7)
        plate.lineWidth = 1.6
        plate.glowWidth = 12
        plate.blendMode = .add
        container.addChild(plate)

        let label = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        label.text = text
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 4)
        container.addChild(label)

        let glow = label.copy() as? SKLabelNode
        glow?.fontColor = boardStyle.skPrimaryColor
        glow?.alpha = 0.44
        glow?.zPosition = -1
        glow?.position = CGPoint(x: 0, y: -2)
        if let glow {
            label.addChild(glow)
        }

        addChild(container)
        limitTransientNodes(named: "popup", maxCount: 18)
        container.run(.sequence([
            .group([.fadeIn(withDuration: 0.16), .scale(to: 1.04, duration: 0.16), .moveBy(x: 0, y: -8, duration: 0.16)]),
            .scale(to: 1.0, duration: 0.10),
            .wait(forDuration: 1.0),
            .group([.fadeOut(withDuration: 0.35), .moveBy(x: 0, y: 22, duration: 0.35)]),
            .removeFromParent()
        ]))
    }

    private func showFloatingText(_ text: String, at position: CGPoint, color: SKColor) {
        limitTransientNodes(named: "popup", maxCount: 18)
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.name = "popup"
        label.text = text
        label.fontSize = text.contains("COMBO") ? 24 : 19
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 70
        label.position = position
        label.setScale(0.8)

        let shadow = label.copy() as? SKLabelNode
        shadow?.name = nil
        shadow?.fontColor = .black.withAlphaComponent(0.72)
        shadow?.position = CGPoint(x: 2, y: -2)
        shadow?.zPosition = -1
        if let shadow {
            label.addChild(shadow)
        }

        addChild(label)
        label.run(.sequence([
            .group([.fadeIn(withDuration: 0.05), .scale(to: text.contains("COMBO") ? 1.28 : 1.14, duration: 0.12)]),
            .scale(to: 1.0, duration: 0.08),
            .group([.moveBy(x: 0, y: text.contains("COMBO") ? 64 : 50, duration: 0.62), .fadeOut(withDuration: 0.62)]),
            .removeFromParent()
        ]))
    }

    private func showComboPulse() {
        ringFlash(at: player.position, color: boardStyle.skSecondaryColor, radius: 64)
        let label = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        label.name = "popup"
        label.text = "PERFECT STREAK"
        label.fontSize = 16
        label.fontColor = boardStyle.skSecondaryColor
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: player.position.x, y: player.position.y + 74)
        label.zPosition = 72
        label.setScale(0.75)
        addChild(label)
        label.run(.sequence([
            .group([.fadeIn(withDuration: 0.06), .scale(to: 1.08, duration: 0.14)]),
            .wait(forDuration: 0.22),
            .group([.moveBy(x: 0, y: 30, duration: 0.42), .fadeOut(withDuration: 0.42)]),
            .removeFromParent()
        ]))
    }

    private func collectBurst(at position: CGPoint) {
        burst(at: position, color: boardStyle.skPrimaryColor, count: 36, speed: 150, scale: 0.13)
        ringFlash(at: position, color: boardStyle.skPrimaryColor, radius: 36)
    }

    private func hitBurst(at position: CGPoint) {
        burst(at: position, color: SKColor(red: 1, green: 0.12, blue: 0.42, alpha: 1), count: 44, speed: 185, scale: 0.16)
        ringFlash(at: position, color: SKColor(red: 1, green: 0.18, blue: 0.12, alpha: 1), radius: 72)
    }

    private func burst(at position: CGPoint, color: SKColor, count: Int, speed: CGFloat, scale: CGFloat) {
        let emitter = SKEmitterNode()
        emitter.name = "burst"
        emitter.particleTexture = AssetManager.trailTexture(board: boardStyle)
        emitter.particleBirthRate = 220
        emitter.numParticlesToEmit = count
        emitter.particleLifetime = 0.48
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.55
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = scale
        emitter.particleScaleRange = scale * 0.7
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 0.9
        emitter.particleAlpha = 0.92
        emitter.particleAlphaSpeed = -1.9
        emitter.particleBlendMode = .add
        emitter.position = position
        emitter.zPosition = 60
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.85), .removeFromParent()]))
    }

    private func ringFlash(at position: CGPoint, color: SKColor, radius: CGFloat) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.name = "popup"
        ring.position = position
        ring.zPosition = 58
        ring.fillColor = .clear
        ring.strokeColor = color.withAlphaComponent(0.85)
        ring.lineWidth = 3
        ring.glowWidth = 12
        ring.blendMode = .add
        ring.setScale(0.25)
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 1.1, duration: 0.34), .fadeOut(withDuration: 0.34)]),
            .removeFromParent()
        ]))
    }

    private func shake() {
        cameraNode.removeAction(forKey: "shake")
        let actions: [SKAction] = (0..<8).map { _ in
            .moveBy(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: -4...4), duration: 0.032)
        }
        let reset = SKAction.move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: 0.08)
        cameraNode.run(.sequence(actions + [reset]), withKey: "shake")
    }

    private func activeNodeCount(named name: String) -> Int {
        var count = 0
        enumerateChildNodes(withName: name) { _, _ in count += 1 }
        return count
    }

    private func limitTransientNodes(named name: String, maxCount: Int) {
        var nodes: [SKNode] = []
        enumerateChildNodes(withName: name) { node, _ in
            nodes.append(node)
        }
        guard nodes.count > maxCount else { return }
        nodes.prefix(nodes.count - maxCount).forEach { $0.removeFromParent() }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}

private func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

private func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}
