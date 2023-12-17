import SwiftUI
import CoreData

struct ElementsView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default)
  private var items: FetchedResults<Item>
  
  @ObservedObject private var settingsStorage = SettingsStorage()
  
  @State private var toShowAddItemView = false
  @State private var toShowClearResultsAlert: Bool = false
  
  @State private var itemsCount = 0
  @State private var rightCount = 0
  @State private var wrongCount = 0
  
  let category: FetchedResults<Category>.Element
  let onElementChanged: () -> Void
  
  // MARK: - Body
  
  var body: some View {
    VStack {
      let items = items.filter { $0.category?.title == category.title }
      HeaderView(
        itemsCount: $itemsCount,
        rightCount: $rightCount,
        wrongCount: $wrongCount
      )
        .padding(.top)
        .padding(.horizontal, 25)
      
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
            ElementView(
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
            var image: String {
              if item.shown {
                return item.answer ? "brain" : "xmark.circle"
              } else {
                return "circle"
              }
            }
            
            Image(systemName: image)
              .foregroundColor(color)
            
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
    .navigationTitle(category.title ?? "")
    .toolbar {
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
          ElementEditView(
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
    .alert(isPresented: $toShowClearResultsAlert) {
      Alert(
        title: Text("Attention"),
        message: Text("All saved results will be reset and this action cannot be rewert."),
        primaryButton: .default(Text("Do it")) { clearResults() },
        secondaryButton: .cancel()
      )
    }
    .onAppear {
      makeHeaderViewData()
    }
  }
  
  // MARK: - Add New Item
  
  private func addNewItem(_ item: Element) {
    withAnimation {
      let newItem = Item(context: viewContext)
      newItem.timestamp = Date()
      newItem.english = item.english
      newItem.russian = item.russian
      var categoryObjects = category.items?.allObjects as? [Item] ?? []
      categoryObjects.append(newItem)
      category.items = NSSet(array: categoryObjects)
    }
    saveContext()
  }
  
  // MARK: - ChangeItem
  
  private func changeItem(_ item: FetchedResults<Item>.Element, element: Element) {
    withAnimation {
      item.english = element.english
      item.russian = element.russian
    }
    saveContext()
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
    }
    saveContext()
  }
  
  // MARK: - DeleteItems
  
  private func deleteItems(offsets: IndexSet) {
    let items = items.filter { $0.category?.title == category.title }
    withAnimation {
      offsets.map { items[$0] }.forEach(viewContext.delete)
    }
    saveContext()
  }
  
  // MARK: - Clear Results
  
  private func clearResults() {
    let items = items.filter { $0.category?.title == category.title }
    items.forEach { item in
      item.answer = false
      item.shown = false
    }
    saveContext()
  }
  
  // MARK: - Save record
  
  private func saveSountRecord(item: FetchedResults<Item>.Element, data: Data) {
    item.voiceRecord = data
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
    let items = items.filter { $0.category?.title == category.title }
    itemsCount = items.count
    rightCount = items.filter { $0.shown && $0.answer }.count
    wrongCount = items.filter { $0.shown && !$0.answer }.count
    onElementChanged()
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
  return ElementsView(category: category, onElementChanged: {})
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
