import SwiftUI

struct GameView: View {
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default)
  private var items: FetchedResults<Item>
  
  let language: Language
  let onAnswerTap: ((FetchedResults<Item>.Element?, Bool) -> Void)
  
  @ObservedObject private var settingsStorage = SettingsStorage()
  
  @State private var isShowTranslation: Bool = false
  @State private var newElement: FetchedResults<Item>.Element?
  @State private var currentElement: FetchedResults<Item>.Element?
  @State private var translationFieldValue: String = String()
  @State private var backgroundColor: Color = Color(UIColor.systemBackground)
  @State private var isVerified: Bool = false
  
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
        Text("\(items.filter { $0.shown && $0.answer }.count)")
        Spacer()
      }
      .font(.headline)
      HStack {
        Text("Ошибок:")
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
            .padding(.top, 100)
        }
        
        Spacer()
        
        // MARK: - isHardMode
        
        if settingsStorage.isHardMode {
          VStack(spacing: 50) {
            TextField("Translation", text: $translationFieldValue)
              .textFieldStyle(.roundedBorder)
            
            HStack {
              Button(
                action: {
                  checkButtonTap(answer: compare())
                },
                label: {
                  Text("Сheck")
                    .font(.title)
                }
              )
              .disabled(translationFieldValue.isEmpty || isVerified)
              
              Spacer()
              
              Button(
                action: {
                  isVerified = false
                  translationFieldValue = String()
                  buttonTap(answer: compare())
                },
                label: {
                  Text("Next")
                    .font(.title)
                }
              )
            }
            .buttonStyle(.bordered)
          }
        } else {
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
        }
      }
    }
    .padding()
    .background(backgroundColor)
    .navigationTitle("Все слова")
    .onAppear {
      random()
    }
    .animation(.easeInOut(duration: 0.3).repeatCount(1, autoreverses: true), value: backgroundColor)
  }
  
  private func buttonTap(answer: Bool) {
    isShowTranslation = false
    onAnswerTap(currentElement, answer)
    shownItem(currentElement)
    random()
  }
  
  private func checkButtonTap(answer: Bool) {
    withAnimation {
      backgroundColor = answer ? .green : .red
    }
    backgroundColor = Color(UIColor.systemBackground)
    isShowTranslation = true
    isVerified = true
    onAnswerTap(currentElement, answer)
    shownItem(currentElement)
  }
  
  private func compare() -> Bool {
    let original = (
      language == .eng
      ? currentElement?.russian ?? ""
      : currentElement?.english ?? ""
    )
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return translationFieldValue
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased() == original.lowercased()
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
