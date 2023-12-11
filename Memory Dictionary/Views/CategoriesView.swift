import SwiftUI

struct CategoriesView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.timestamp, ascending: true)], animation: .default)
  private var categories: FetchedResults<Category>
  
  @State private var toShowAddItemAlert: Bool = false
  @State private var newCategoryTitle: String = String()
  
  // MARK: - Body
  
  var body: some View {
    NavigationView {
      VStack {
        let items = categories.compactMap { $0.items?.compactMap { $0 as? Item } }.flatMap { $0 }
        HeaderView(items: items)
        
        List {
          ForEach(categories) { category in
            NavigationLink {
              ContentView(category: category)
                .environment(\.managedObjectContext, viewContext)
            } label: {
              Text(category.title ?? "")
            }
          }
          .onDelete(perform: deleteItems)
        }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            NavigationLink {
              SettingsView(onClearResults: {
                clearResults()
              })
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
            .alert("Enter category name", isPresented: $toShowAddItemAlert) {
              TextField("Enter name", text: $newCategoryTitle)
              Button("Save", action: {
                toShowAddItemAlert.toggle()
                addNewItem(newCategoryTitle)
              })
              Button("Cancel", action: {
                toShowAddItemAlert = false
              })
            }
          }
        }
        
        let mistakenesItems = items.filter { !$0.answer && $0.shown }
        if !mistakenesItems.isEmpty {
          NavigationLink {
            GameView(title: "All words", items: mistakenesItems) { element, answer, time in
              changeItem(element, answer: answer, time: time)
            }
          } label: {
            Text("Mistakenes")
              .frame(maxWidth: .infinity, maxHeight: 20)
          }
          .buttonStyle(.borderedProminent)
          .padding(.horizontal, 16)
        }
        
        NavigationLink {
          GameView(title: "All words", items: items) { element, answer, time in
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
  
  // MARK: - AddNewItem
  
  private func addNewItem(_ title: String) {
    withAnimation {
      let newItem = Category(context: viewContext)
      newItem.timestamp = Date()
      newItem.title = title
      saveContext()
    }
  }
  
  // MARK: - DeleteItems
  
  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      offsets.map { categories[$0] }
        .forEach(viewContext.delete)
      saveContext()
    }
  }
  
  // MARK: - ChangeItem
  
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
      saveContext()
    }
  }
  
  private func clearResults() {
    categories.forEach { category in
      category.items?.forEach { element in
        (element as? Item)?.shown = false
        (element as? Item)?.answerTime = ""
        (element as? Item)?.answer = false
      }
    }
    saveContext()
  }
  
  private func saveContext() {
    do {
      try viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
  }
}

// MARK: - Preview

#Preview {
  CategoriesView()
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
