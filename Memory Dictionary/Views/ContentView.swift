import SwiftUI
import CoreData

struct ContentView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default)
  private var items: FetchedResults<Item>
  
  @ObservedObject private var settingsStorage = SettingsStorage()
  
  @State private var toShowAddItemView = false
  
  let category: FetchedResults<Category>.Element
  
  // MARK: - Body
  
  var body: some View {
    VStack {
      let items = items.filter { $0.category?.title == category.title }
      HeaderView(items: items)
      
      List {
        ForEach(items) { item in
          NavigationLink {
            let element = Element(
              english: item.english ?? "",
              russian: item.russian ?? "",
              answer: item.answer,
              right: item.rightCount,
              wrong: item.wrongCount, 
              answerTime: item.answerTime
            )
            ItemView(
              recordData: item.voiceRecord,
              element: element,
              language: settingsStorage.language,
              onEditTap: { element in
                changeItem(item, element: element)
              }, 
              onSaveRecord: { data in
                saveSountRecord(item: item, data: data)
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
              switch settingsStorage.language {
              case .eng: return item.english ?? ""
              case .rus: return item.russian ?? ""
              }
            }
            Text(title)
          }
        }
        .onDelete(perform: deleteItems)
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
        GameView(title: category.title ?? "", items: items) { element, answer, time in
          changeItem(element, answer: answer, time: time)
        }
      } label: {
        Text("Play")
          .frame(maxWidth: .infinity, maxHeight: 40)
      }
      .buttonStyle(.borderedProminent)
      .padding(.horizontal, 16)
    }
    .navigationTitle(category.title ?? "")
    .toolbar {
      ToolbarItem {
        Button(
          action: {
            toShowAddItemView.toggle()
          },
          label: {
            Label(
              title: { Text("Add") },
              icon: { Image(systemName: "plus.circle") }
            )
          }
        )
        .sheet(isPresented: $toShowAddItemView) {
          ItemEditView(
            title: "Add new word",
            buttonTitle: "Add"
          ) { result in
            addNewItem(result)
            toShowAddItemView.toggle()
          }
          .presentationDetents([.medium])
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
      saveContext()
    }
  }
  
  // MARK: - ChangeItem
  
  private func changeItem(_ item: FetchedResults<Item>.Element, element: Element) {
    withAnimation {
      item.english = element.english
      item.russian = element.russian
      saveContext()
    }
  }
  
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
  
  // MARK: - DeleteItems
  
  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      offsets.map { items[$0] }.forEach(viewContext.delete)
      saveContext()
    }
  }
  
  // MARK: - Save record
  
  private func saveSountRecord(item: FetchedResults<Item>.Element, data: Data) {
    item.voiceRecord = data
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
  let category = Category(context: PersistenceController.preview.container.viewContext)
  category.title = "Title"
  let newItem = Item(context: PersistenceController.preview.container.viewContext)
  newItem.timestamp = Date()
  newItem.english = "cat"
  newItem.russian = "Кот"
  
  category.items = [newItem]
  return ContentView(category: category)
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
