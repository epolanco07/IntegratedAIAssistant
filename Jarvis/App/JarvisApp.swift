import SwiftUI

// Only @main in the project. Remove @main from (or delete) the old MyApp.swift.
@main
struct JarvisApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .preferredColorScheme(.dark)
                .frame(minWidth: 960, minHeight: 620)
        }
        .windowToolbarStyle(.unified)
    }
}
