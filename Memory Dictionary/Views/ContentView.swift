import SwiftUI
import CoreData

struct ContentView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default)
  private var items: FetchedResults<Item>
  
  @State private var toShowAddItemView = false
  
  let category: FetchedResults<Category>.Element
  let language: Language
  
  // MARK: - Body
  
  var body: some View {
    let filtredItems = items.filter { $0.category?.title == category.title }
    VStack {
      HStack {
        Text("Всего:")
        Text("\(filtredItems.count)")
        
        Text("Угадано:")
          .foregroundColor(.green)
        Text("\(filtredItems.filter { $0.shown && $0.answer }.count)")
        
        Text("Ошибок:")
          .foregroundColor(.red)
        Text("\(filtredItems.filter { $0.shown && !$0.answer }.count)")
      }
      .font(.headline)
      .padding(.horizontal, 16)
      
      List {
        ForEach(filtredItems) { item in
          NavigationLink {
            let element = Element(
              english: item.english ?? "",
              russian: item.russian ?? "",
              answer: item.answer
            )
            AnswerView(
              element: element,
              language: language,
              onEditTap: { element in
                changeItem(item, element: element)
              }
            )
          } label: {
            var color: Color {
              if item.shown {
                return item.answer ? .green : .red
              } else {
                return .gray
              }
            }
            if item.answer {
              Image(systemName: "cat.fill")
                .foregroundColor(color)
            } else {
              Rectangle()
                .fill(color)
                .frame(width: 20, height: 20)
                .cornerRadius(10)
            }
            
            var title: String {
              switch language {
              case .eng: return item.english ?? ""
              case .rus: return item.russian ?? ""
              }
            }
            Text(title)
            if let time = item.answerTime, item.answer {
              Text(time)
                .foregroundColor(.green)
            }
            if item.hardMode {
              Text("HARD")
                .foregroundColor(.orange)
            }
          }
        }
        .onDelete(perform: deleteItems)
      }
      .navigationTitle(category.title ?? "")
      .toolbar {
        ToolbarItem {
          Button(
            action: {
              toShowAddItemView.toggle()
            },
            label: {
              Text("Добавить")
            }
          )
          .sheet(isPresented: $toShowAddItemView) {
            ItemView(
              title: "Добавить новое слово",
              buttonTitle: "Добавить"
            ) { result in
              addNewItem(result)
              toShowAddItemView.toggle()
            }
            .presentationDetents([.medium])
          }
        }
      }
    }
  }
  
  // MARK: - AddNewItem
  
  private func addNewItem(_ item: Element) {
    withAnimation {
      let newItem = Item(context: viewContext)
      newItem.timestamp = Date()
      newItem.english = item.english
      newItem.russian = item.russian
      var categoryObjects = category.items?.allObjects as? [Item] ?? []
      categoryObjects.append(newItem)
      category.items = NSSet(array: categoryObjects)
      do {
        try viewContext.save()
      } catch {
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
      }
    }
  }
  
  // MARK: - ChangeItem
  
  private func changeItem(_ item: FetchedResults<Item>.Element, element: Element) {
    withAnimation {
      item.english = element.english
      item.russian = element.russian
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
      offsets.map { items[$0] }.forEach(viewContext.delete)
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
  let category = Category(context: PersistenceController.preview.container.viewContext)
  category.title = "Title"
  let newItem = Item(context: PersistenceController.preview.container.viewContext)
  newItem.timestamp = Date()
  newItem.english = "cat"
  newItem.russian = "Кот"
  
  category.items = [newItem]
  return ContentView(category: category, language: .eng)
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
