//
//  Neon_Drift_DashApp.swift
//  Neon Drift Dash
//
//  Created by Sebastien Lato on 2026-05-19.
//

import SwiftUI

@main
struct Neon_Drift_DashApp: App {
    @StateObject private var gameState = GameState()
    @StateObject private var settings = GameSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
        }
    }
}
