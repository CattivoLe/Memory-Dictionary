import SwiftUI

struct GameView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default)
  private var items: FetchedResults<Item>
  
  let language: Language
  let onAnswerTap: ((FetchedResults<Item>.Element?, Bool) -> Void)
  
  @State private var showTranslation: Bool = false
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
              showTranslation ? element.russian ?? "" : element.english ?? ""
            } else {
              showTranslation ? element.english ?? "" : element.russian ?? ""
            }
          }
          Text(text)
            .multilineTextAlignment(.center)
            .font(.largeTitle)
            .padding(.top, 200)
        }
        
        Spacer()
        
        HStack(spacing: 20) {
          Button(
            action: {
              onAnswerTap(currentElement, true)
              shownItem(currentElement)
            },
            label: {
              Text("Угадал")
                .foregroundColor(.green)
            }
          )
          .buttonStyle(.bordered)
          
          Button(
            action: {
              onAnswerTap(currentElement, false)
              shownItem(currentElement)
            },
            label: {
              Text("Ошибся")
                .foregroundColor(.red)
            }
          )
          .buttonStyle(.bordered)
        }
        
        Button(
          action: {
            showTranslation.toggle()
          },
          label: {
            let title = showTranslation ? "Скрыть перевод" :  "Показать перевод"
            Text(title)
              .font(.title)
          }
        )
        
        Button(
          action: {
            showTranslation = false
            random()
          },
          label: {
            Text("Следующее слово")
              .frame(maxWidth: .infinity, maxHeight: 40)
          }
        )
        .padding(.top, 50)
        .buttonStyle(.borderedProminent)
      }
    }
    .padding()
    .onAppear {
      random()
    }
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
