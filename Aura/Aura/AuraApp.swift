//
//  AuraApp.swift
//  Granola
//

import SwiftUI

@main
struct AuraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 960, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Start Meeting") {
                    // Start meeting action
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        
        MenuBarExtra("Aura", systemImage: "mic.bubble") {
            VStack {
                Text("Aura Meeting Memory")
                    .font(.headline)
                Divider()
                Button("Start Meeting (⌘Enter)") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}
