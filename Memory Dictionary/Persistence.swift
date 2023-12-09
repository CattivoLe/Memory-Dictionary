import CoreData

struct PersistenceController {
  static let shared = PersistenceController()
  
  static var preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext
    let category = Category(context: viewContext)
    category.title = "Category"
    category.timestamp = Date()
    let catItem = Item(context: viewContext)
    catItem.timestamp = Date()
    catItem.english = "Cat"
    catItem.russian = "Кот"
    
    let dogItem = Item(context: viewContext)
    dogItem.timestamp = Date()
    dogItem.english = "Dog"
    dogItem.russian = "Собака"
    
    category.items = [catItem, dogItem]
    
    do {
      try viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
    return result
  }()
  
  let container: NSPersistentCloudKitContainer
  
  init(inMemory: Bool = false) {
    container = NSPersistentCloudKitContainer(name: "Memory_Dictionary")
    if inMemory {
      container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    container.viewContext.automaticallyMergesChangesFromParent = true
  }
}
