import SwiftUI

struct CategoriesView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Category.timestamp, ascending: true)], animation: .default)
  private var categories: FetchedResults<Category>
  
  @State private var selectedlanguage: Language = .eng
  @State private var showAddItemAlert: Bool = false
  @State private var newCategoryTitle: String = String()
  
  // MARK: - Body
  
  var body: some View {
    NavigationView {
      VStack {
        List {
          ForEach(categories) { category in
            NavigationLink {
              ContentView(category: category, language: selectedlanguage)
                .environment(\.managedObjectContext, viewContext)
            } label: {
              Text(category.title ?? "")
            }
          }
          .onDelete(perform: deleteItems)
        }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Picker("Язык", selection: $selectedlanguage) {
              Text("Русский")
                .tag(Language.rus)
              Text("Английский")
                .tag(Language.eng)
            }
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button(
              action: {
                showAddItemAlert.toggle()
              }, label: {
                Text("Добавить")
              }
            )
            .alert("Enter category name", isPresented: $showAddItemAlert) {
              TextField("Enter name", text: $newCategoryTitle)
              Button("Save", action: {
                showAddItemAlert.toggle()
                addNewItem(newCategoryTitle)
              })
            }
          }
        }
        
        NavigationLink {
          GameView(language: selectedlanguage) { element, answer in
            changeItem(element, answer: answer)
          }
        } label: {
          Text("Играть")
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
