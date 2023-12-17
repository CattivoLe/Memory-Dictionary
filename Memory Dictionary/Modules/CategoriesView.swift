import SwiftUI

struct CategoriesView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.timestamp, ascending: true)], animation: .default)
  private var categories: FetchedResults<Category>
  
  @ObservedObject private var settingsStorage = SettingsStorage()
  
  @State private var toShowAddItemAlert: Bool = false
  @State private var toShowClearResultsAlert: Bool = false
  @State private var newCategoryTitle: String = String()
  
  @State private var itemsCount = 0
  @State private var rightCount = 0
  @State private var wrongCount = 0
  
  // MARK: - Body
  
  var body: some View {
    NavigationView {
      VStack {
        HeaderView(
          itemsCount: $itemsCount,
          rightCount: $rightCount,
          wrongCount: $wrongCount
        )
          .padding(.top)
          .padding(.horizontal, 25)
        
        List {
          ForEach(categories) { category in
            NavigationLink {
              ElementsView(category: category, onElementChanged: { makeHeaderViewData() })
                .environment(\.managedObjectContext, viewContext)
            } label: {
              Text(category.title ?? "")
            }
          }
          .onDelete(perform: deleteCategory)
        }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            NavigationLink {
              SettingsView()
            } label: {
              Label(
                title: { Text("Settings") },
                icon: { Image(systemName: "gearshape") }
              )
            }
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button(
              action: {
                toShowAddItemAlert.toggle()
              }, label: {
                Label(
                  title: { Text("Add") },
                  icon: { Image(systemName: "plus.circle") }
                )
              }
            )
          }
          ToolbarItem() {
            Button(
              action: {
                toShowClearResultsAlert.toggle()
              },
              label: {
                Label(
                  title: { Text("Clear") },
                  icon: { Image(systemName: "clear") }
                )
              }
            )
          }
        }
        .alert("Enter category name", isPresented: $toShowAddItemAlert) {
          TextField("Enter name", text: $newCategoryTitle)
          Button("Save", action: {
            toShowAddItemAlert.toggle()
            addNewCategory(newCategoryTitle)
          })
          Button("Cancel", action: {
            toShowAddItemAlert = false
          })
        }
        .alert(isPresented: $toShowClearResultsAlert) {
          Alert(
            title: Text("Attention"),
            message: Text("All saved results will be reset and this action cannot be rewert."),
            primaryButton: .default(Text("Do it")) { clearResults() },
            secondaryButton: .cancel()
          )
        }
      
        let items = categories.compactMap { $0.items?.compactMap { $0 as? Item } }.flatMap { $0 }
        let gameItems = settingsStorage.isOnlyWrongs
        ? items.filter { !$0.answer }
        : items
        
        if !gameItems.isEmpty {
          NavigationLink {
            GameView(title: "All words", items: gameItems) { element, answer, time in
              changeItem(element, answer: answer, time: time)
            }
          } label: {
            Text("Play")
              .frame(maxWidth: .infinity, maxHeight: 40)
          }
          .buttonStyle(.borderedProminent)
          .padding(.horizontal, 16)
        }
      }
    }
    .onAppear {
      makeHeaderViewData()
    }
  }
  
  // MARK: - Add New Category
  
  private func addNewCategory(_ title: String) {
    withAnimation {
      let newCategory = Category(context: viewContext)
      newCategory.timestamp = Date()
      newCategory.title = title
      saveContext()
    }
  }
  
  // MARK: - Delete Category
  
  private func deleteCategory(offsets: IndexSet) {
    withAnimation {
      offsets.map { categories[$0] }
        .forEach(viewContext.delete)
      saveContext()
    }
  }
  
  // MARK: - Change Item
  
  private func changeItem(_ item: FetchedResults<Item>.Element?, answer: Bool, time: String) {
    withAnimation {
      item?.answer = answer
      item?.answerTime = time
      item?.shown = true
      if answer {
        item?.rightCount += 1
      } else {
        item?.wrongCount += 1
      }
    }
    saveContext()
  }
  
  // MARK: - Clear Results
  
  private func clearResults() {
    categories.forEach { category in
      category.items?.forEach { element in
        (element as? Item)?.answer = false
        (element as? Item)?.shown = false
      }
    }
    saveContext()
  }
  
  // MARK: - Save Context
  
  private func saveContext() {
    do {
      try viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
    makeHeaderViewData()
  }
  
  // MARK: - Make header viewData
  
  private func makeHeaderViewData() {
    let items = categories.compactMap { $0.items?.compactMap { $0 as? Item } }.flatMap { $0 }
    itemsCount = items.count
    rightCount = items.filter { $0.shown && $0.answer }.count
    wrongCount = items.filter { $0.shown && !$0.answer }.count
  }
}

// MARK: - Preview

#Preview {
  CategoriesView()
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
