import SwiftUI

@main
struct Memory_DictionaryApp: App {
  private let persistenceController = PersistenceController.shared
  
  var body: some Scene {
    WindowGroup {
      CategoriesView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
  }
}
