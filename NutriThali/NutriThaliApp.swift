//
//  NutriThaliApp.swift
//  NutriThali
//
//  Created by Tejas Kale on 07/12/25.
//

import SwiftUI
import CoreData

@main
struct NutriThaliApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
