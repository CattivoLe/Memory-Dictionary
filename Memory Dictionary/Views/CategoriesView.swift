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
        HStack {
          let items = categories.compactMap { $0.items?.compactMap { $0 as? Item } }.flatMap { $0 }
          Text("Всего:")
          Text("\(items.count)")
          
          Text("Угадано:")
            .foregroundColor(.green)
          Text("\(items.filter { $0.shown && $0.answer }.count)")
          
          Text("Ошибок:")
            .foregroundColor(.red)
          Text("\(items.filter { $0.shown && !$0.answer }.count)")
        }
        .font(.headline)
        .padding(.horizontal, 16)
        
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
        
        NavigationLink {
          GameView() { element, answer, time in
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
