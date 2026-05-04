//
//  LunarGlassApp.swift
//  LunarGlass
//
//  Created by York on 2026/5/5.
//

import SwiftUI
import EventKit

@main
struct LunarGlassApp: App {
    private let store = EKEventStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    let status = EKEventStore.authorizationStatus(for: .event)
                    if status == .notDetermined {
                        _ = try? await store.requestFullAccessToEvents()
                    }
                }
        }
    }
}
