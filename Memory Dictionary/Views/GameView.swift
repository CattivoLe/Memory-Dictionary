import SwiftUI

struct GameView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default)
  private var items: FetchedResults<Item>
  
  let language: Language
  let onAnswerTap: ((FetchedResults<Item>.Element?, Bool) -> Void)
  
  @State private var isShowTranslation: Bool = false
  @State private var newElement: FetchedResults<Item>.Element?
  @State private var currentElement: FetchedResults<Item>.Element?
  
  // MARK: - Body
  
  var body: some View {
    VStack(spacing: .zero) {
      HStack {
        Text("Всего слов:")
        Text("\(items.count)")
        Spacer()
      }
      .font(.headline)
      HStack {
        Text("Угадано:")
          .foregroundColor(.green)
        Text("\(items.filter { $0.shown && $0.answer }.count)")
        Spacer()
      }
      .font(.headline)
      HStack {
        Text("Ошибок:")
          .foregroundColor(.red)
        Text("\(items.filter { $0.shown && !$0.answer }.count)")
        Spacer()
      }
      .font(.headline)
      
      VStack {
        if let element = currentElement {
          var text: String {
            if language == .eng {
              isShowTranslation ? element.russian ?? "" : element.english ?? ""
            } else {
              isShowTranslation ? element.english ?? "" : element.russian ?? ""
            }
          }
          Text(text)
            .multilineTextAlignment(.center)
            .font(.largeTitle)
            .padding(.top, 200)
        }
        
        Spacer()
        
        Button(
          action: {
            isShowTranslation.toggle()
          },
          label: {
            let title = isShowTranslation ? "Скрыть перевод" :  "Показать перевод"
            Text(title)
              .font(.title)
          }
        )
        
        HStack(spacing: 20) {
          Button(
            action: {
              buttonTap(answer: true)
            },
            label: {
              Text("Угадал")
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, maxHeight: 40)
            }
          )
          .buttonStyle(.bordered)
          
          Button(
            action: {
              buttonTap(answer: false)
            },
            label: {
              Text("Ошибся")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight: 40)
            }
          )
          .buttonStyle(.bordered)
        }
//        .frame(maxWidth: .infinity, maxHeight: 40)
      }
    }
    .padding()
    .navigationTitle("Все слова")
    .onAppear {
      random()
    }
  }
  
  private func buttonTap(answer: Bool) {
    isShowTranslation = false
    onAnswerTap(currentElement, answer)
    shownItem(currentElement)
    random()
  }
  
  // MARK: - Random
  
  private func random() {
    newElement = items.randomElement()
    if newElement == currentElement {
      currentElement = newElement
    } else {
      currentElement = items.randomElement()
    }
  }
  
  // MARK: - ShownItem
  
  private func shownItem(_ item: FetchedResults<Item>.Element?) {
    withAnimation {
      item?.shown = true
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
  GameView(language: .eng, onAnswerTap: { _, _ in })
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
