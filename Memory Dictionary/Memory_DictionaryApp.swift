//
//  Memory_DictionaryApp.swift
//  Memory Dictionary
//
//  Created by Alexander Omelchuk on 6.12.23..
//

import SwiftUI

@main
struct Memory_DictionaryApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
