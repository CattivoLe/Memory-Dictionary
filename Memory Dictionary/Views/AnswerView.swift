import SwiftUI

struct AnswerView: View {
  @State private var showEditView = false
  
  let element: Element
  let language: Language
  let onEditTap: ((Element) -> Void)
  
  // MARK: - Body
  
  var body: some View {
    VStack {
      var text: String {
        switch language {
        case .eng: return element.russian
        case .rus: return element.english
        }
      }
      Text(text)
        .multilineTextAlignment(.center)
        .font(.largeTitle)
    }
    .padding()
    .toolbar {
      ToolbarItem {
        Button(
          action: {
            showEditView.toggle()
          }, label: {
            Text("Изменить")
          }
        )
        .sheet(isPresented: $showEditView) {
          ItemView(
            title: "Изменить",
            buttonTitle: "Сохранить",
            englishValue: element.english,
            russianValue: element.russian
          ) { result in
            onEditTap(result)
            showEditView.toggle()
          }
          .presentationDetents([.medium])
        }
      }
    }
  }
}

// MARK: - Preview

#Preview {
  AnswerView(
    element: Element(english: "Cat", russian: "Кот", answer: false),
    language: .eng,
    onEditTap: { _ in }
  )
}
