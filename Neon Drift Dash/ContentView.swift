import SwiftUI

struct ContentView: View {
    var body: some View {
        GameRootView()
    }
}

#Preview {
    ContentView()
        .environmentObject(GameState())
        .environmentObject(GameSettings())
}
