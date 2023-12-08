import SwiftUI

struct CategoriesView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.timestamp, ascending: true)], animation: .default)
  private var categories: FetchedResults<Category>
  
  @ObservedObject private var settingsStorage = SettingsStorage()
  @State private var toShowAddItemAlert: Bool = false
  @State private var newCategoryTitle: String = String()
  
  // MARK: - Body
  
  var body: some View {
    NavigationView {
      VStack {
        List {
          ForEach(categories) { category in
            NavigationLink {
              ContentView(category: category, language: settingsStorage.language)
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
            .alert("Enter category name", isPresented: $toShowAddItemAlert) {
              TextField("Enter name", text: $newCategoryTitle)
              Button("Save", action: {
                toShowAddItemAlert.toggle()
                addNewItem(newCategoryTitle)
              })
            }
          }
        }
        
        NavigationLink {
          GameView(language: settingsStorage.language) { element, answer in
            changeItem(element, answer: answer)
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
      do {
        try viewContext.save()
      } catch {
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
      }
    }
  }
  
  // MARK: - DeleteItems
  
  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      offsets.map { categories[$0] }.forEach(viewContext.delete)
      do {
        try viewContext.save()
      } catch {
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
      }
    }
  }
  
  // MARK: - ChangeItem
  
  private func changeItem(_ item: FetchedResults<Item>.Element?, answer: Bool) {
    withAnimation {
      item?.answer = answer
      do {
        try viewContext.save()
      } catch {
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
      }
    }
  }
}

// MARK: - Preview

#Preview {
  CategoriesView()
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
