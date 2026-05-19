import SpriteKit
import UIKit

enum PlayerPose: Equatable {
    case idle
    case leanLeft
    case leanRight
    case hit

    var assetName: String {
        switch self {
        case .idle: "PlayerIdle"
        case .leanLeft: "PlayerLeanLeft"
        case .leanRight: "PlayerLeanRight"
        case .hit: "PlayerHit"
        }
    }
}

enum ObstacleKind: CaseIterable {
    case drone
    case barrier
    case cone
    case mine

    var assetName: String {
        switch self {
        case .drone: "ObstacleDrone"
        case .barrier: "ObstacleBarrier"
        case .cone: "ObstacleCone"
        case .mine: "ObstacleMine"
        }
    }

    var displayName: String {
        switch self {
        case .drone: "Drone"
        case .barrier: "Barrier"
        case .cone: "Hazard Cone"
        case .mine: "Neon Mine"
        }
    }

    var baseSize: CGSize {
        switch self {
        case .drone: CGSize(width: 70, height: 58)
        case .barrier: CGSize(width: 62, height: 130)
        case .cone: CGSize(width: 58, height: 72)
        case .mine: CGSize(width: 62, height: 62)
        }
    }

    var collisionRadius: CGFloat {
        switch self {
        case .drone: 30
        case .barrier: 44
        case .cone: 28
        case .mine: 29
        }
    }
}

enum AssetManager {
    static func textureIfAvailable(_ name: String) -> SKTexture? {
        guard let image = UIImage(named: name) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    static func playerTexture(pose: PlayerPose, board: BoardStyle) -> SKTexture {
        textureIfAvailable(pose.assetName) ?? texture(from: fallbackPlayerImage(pose: pose, board: board))
    }

    static func trailTexture(board: BoardStyle) -> SKTexture {
        textureIfAvailable("TrailStreak") ?? texture(from: fallbackTrailImage(board: board))
    }

    static func shardTexture() -> SKTexture {
        textureIfAvailable("EnergyShard") ?? texture(from: fallbackShardImage())
    }

    static func obstacleTexture(kind: ObstacleKind) -> SKTexture {
        textureIfAvailable(kind.assetName) ?? texture(from: fallbackObstacleImage(kind: kind))
    }

    private static func texture(from image: UIImage) -> SKTexture {
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func fallbackPlayerImage(pose: PlayerPose, board: BoardStyle) -> UIImage {
        let size = CGSize(width: 180, height: 240)
        return UIGraphicsImageRenderer(size: size).image { context in
            let cg = context.cgContext
            cg.clear(CGRect(origin: .zero, size: size))

            let tilt: CGFloat = {
                switch pose {
                case .idle: 0
                case .leanLeft: -0.12
                case .leanRight: 0.12
                case .hit: 0.06
                }
            }()

            cg.saveGState()
            cg.translateBy(x: size.width / 2, y: size.height / 2)
            cg.rotate(by: tilt)
            cg.translateBy(x: -size.width / 2, y: -size.height / 2)

            board.skPrimaryColor.withAlphaComponent(0.55).setFill()
            UIBezierPath(ovalIn: CGRect(x: 33, y: 196, width: 116, height: 26)).fill()

            let boardPath = UIBezierPath(roundedRect: CGRect(x: 26, y: 184, width: 128, height: 24), cornerRadius: 12)
            UIColor(red: 0.04, green: 0.03, blue: 0.09, alpha: 1).setFill()
            boardPath.fill()
            board.skPrimaryColor.setStroke()
            boardPath.lineWidth = 4
            boardPath.stroke()

            board.skSecondaryColor.setStroke()
            let streak = UIBezierPath()
            streak.move(to: CGPoint(x: 45, y: 201))
            streak.addLine(to: CGPoint(x: 138, y: 191))
            streak.lineWidth = 5
            streak.stroke()

            UIColor(red: 0.05, green: 0.05, blue: 0.10, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 68, y: 87, width: 44, height: 78), cornerRadius: 18).fill()
            UIColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: 55, y: 72, width: 70, height: 62), cornerRadius: 22).fill()

            board.skSecondaryColor.withAlphaComponent(0.9).setStroke()
            let hoodieLine = UIBezierPath()
            hoodieLine.move(to: CGPoint(x: 63, y: 103))
            hoodieLine.addLine(to: CGPoint(x: 113, y: 132))
            hoodieLine.lineWidth = 4
            hoodieLine.stroke()

            UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 65, y: 38, width: 52, height: 52)).fill()
            board.skPrimaryColor.setFill()
            UIBezierPath(roundedRect: CGRect(x: 68, y: 54, width: 48, height: 11), cornerRadius: 5).fill()

            UIColor(red: 0.03, green: 0.03, blue: 0.08, alpha: 1).setStroke()
            let leftLeg = UIBezierPath()
            leftLeg.move(to: CGPoint(x: 80, y: 155))
            leftLeg.addLine(to: CGPoint(x: 62, y: 191))
            leftLeg.lineWidth = 13
            leftLeg.stroke()
            let rightLeg = UIBezierPath()
            rightLeg.move(to: CGPoint(x: 102, y: 154))
            rightLeg.addLine(to: CGPoint(x: 124, y: 189))
            rightLeg.lineWidth = 13
            rightLeg.stroke()

            board.skPrimaryColor.setStroke()
            leftLeg.lineWidth = 3
            leftLeg.stroke()
            rightLeg.lineWidth = 3
            rightLeg.stroke()

            if pose == .hit {
                UIColor.white.withAlphaComponent(0.7).setStroke()
                let spark = UIBezierPath()
                spark.move(to: CGPoint(x: 128, y: 75))
                spark.addLine(to: CGPoint(x: 143, y: 62))
                spark.move(to: CGPoint(x: 135, y: 88))
                spark.addLine(to: CGPoint(x: 154, y: 91))
                spark.lineWidth = 4
                spark.stroke()
            }

            cg.restoreGState()
        }
    }

    private static func fallbackTrailImage(board: BoardStyle) -> UIImage {
        let size = CGSize(width: 220, height: 80)
        return UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.clear.setFill()
            UIRectFill(rect)

            let colors = [board.skSecondaryColor.cgColor, board.skPrimaryColor.cgColor, UIColor.clear.cgColor] as CFArray
            let locations: [CGFloat] = [0, 0.45, 1]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
            let cg = UIGraphicsGetCurrentContext()
            cg?.drawLinearGradient(gradient, start: CGPoint(x: size.width, y: size.height / 2), end: CGPoint(x: 0, y: size.height / 2), options: [])
        }
    }

    private static func fallbackShardImage() -> UIImage {
        let size = CGSize(width: 90, height: 120)
        return UIGraphicsImageRenderer(size: size).image { context in
            let cg = context.cgContext
            cg.clear(CGRect(origin: .zero, size: size))

            UIColor(red: 0.1, green: 0.84, blue: 1, alpha: 0.3).setFill()
            UIBezierPath(ovalIn: CGRect(x: 8, y: 20, width: 74, height: 84)).fill()

            let shard = UIBezierPath()
            shard.move(to: CGPoint(x: 45, y: 8))
            shard.addLine(to: CGPoint(x: 76, y: 48))
            shard.addLine(to: CGPoint(x: 51, y: 112))
            shard.addLine(to: CGPoint(x: 15, y: 58))
            shard.close()
            UIColor(red: 0.11, green: 0.9, blue: 1, alpha: 1).setFill()
            shard.fill()
            UIColor.white.withAlphaComponent(0.8).setStroke()
            shard.lineWidth = 4
            shard.stroke()
        }
    }

    private static func fallbackObstacleImage(kind: ObstacleKind) -> UIImage {
        let size = CGSize(width: 150, height: 150)
        return UIGraphicsImageRenderer(size: size).image { context in
            let cg = context.cgContext
            cg.clear(CGRect(origin: .zero, size: size))

            switch kind {
            case .drone:
                UIColor(red: 0.05, green: 0.06, blue: 0.12, alpha: 1).setFill()
                UIBezierPath(roundedRect: CGRect(x: 38, y: 52, width: 74, height: 42), cornerRadius: 16).fill()
                UIColor(red: 1, green: 0.08, blue: 0.35, alpha: 1).setFill()
                UIBezierPath(ovalIn: CGRect(x: 58, y: 64, width: 34, height: 12)).fill()
                UIColor(red: 0.1, green: 0.82, blue: 1, alpha: 1).setStroke()
                let wing = UIBezierPath()
                wing.move(to: CGPoint(x: 37, y: 72))
                wing.addLine(to: CGPoint(x: 8, y: 54))
                wing.move(to: CGPoint(x: 113, y: 72))
                wing.addLine(to: CGPoint(x: 142, y: 54))
                wing.lineWidth = 7
                wing.stroke()
            case .barrier:
                UIColor(red: 0.12, green: 0.86, blue: 1, alpha: 0.35).setStroke()
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 45, y: 18))
                path.addLine(to: CGPoint(x: 105, y: 18))
                path.addLine(to: CGPoint(x: 45, y: 132))
                path.addLine(to: CGPoint(x: 105, y: 132))
                path.lineWidth = 10
                path.stroke()
                UIColor(red: 1, green: 0.12, blue: 0.72, alpha: 1).setStroke()
                let bolt = UIBezierPath()
                bolt.move(to: CGPoint(x: 82, y: 25))
                bolt.addLine(to: CGPoint(x: 58, y: 69))
                bolt.addLine(to: CGPoint(x: 92, y: 68))
                bolt.addLine(to: CGPoint(x: 66, y: 126))
                bolt.lineWidth = 7
                bolt.stroke()
            case .cone:
                UIColor(red: 1, green: 0.38, blue: 0.12, alpha: 1).setFill()
                let cone = UIBezierPath()
                cone.move(to: CGPoint(x: 75, y: 28))
                cone.addLine(to: CGPoint(x: 113, y: 118))
                cone.addLine(to: CGPoint(x: 37, y: 118))
                cone.close()
                cone.fill()
                UIColor(red: 0.13, green: 0.88, blue: 1, alpha: 1).setStroke()
                cone.lineWidth = 4
                cone.stroke()
            case .mine:
                UIColor(red: 0.05, green: 0.04, blue: 0.10, alpha: 1).setFill()
                UIBezierPath(ovalIn: CGRect(x: 43, y: 43, width: 64, height: 64)).fill()
                UIColor(red: 1, green: 0.09, blue: 0.45, alpha: 1).setStroke()
                for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
                    let start = CGPoint(x: 75 + cos(angle) * 26, y: 75 + sin(angle) * 26)
                    let end = CGPoint(x: 75 + cos(angle) * 57, y: 75 + sin(angle) * 57)
                    let spike = UIBezierPath()
                    spike.move(to: start)
                    spike.addLine(to: end)
                    spike.lineWidth = 6
                    spike.stroke()
                }
            }
        }
    }
}
