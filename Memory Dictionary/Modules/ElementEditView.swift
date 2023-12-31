import SwiftUI

struct ElementEditView: View {
  let title: String
  let buttonTitle: String
  let englishValue: String?
  let russianValue: String?
  
  init(
    title: String,
    buttonTitle: String,
    englishValue: String? = nil,
    russianValue: String? = nil,
    onButtonTap: ((Element) -> Void)? = nil
  ) {
    self.title = title
    self.buttonTitle = buttonTitle
    self.englishValue = englishValue
    self.russianValue = russianValue
    self.onButtonTap = onButtonTap
  }
  
  var onButtonTap: ((Element) -> Void)?
  
  @State private var englishField = String()
  @State private var russianField = String()
  
  // MARK: - Body
  
  var body: some View {
    VStack(spacing: 16) {
      Text(title)
        .font(.title)
      
      TextField(text: $englishField) {
        Text("In English")
      }
      .textFieldStyle(.roundedBorder)
      .padding(.top, 20)
      
      TextField(text: $russianField) {
        Text("In Russian")
      }
      .textFieldStyle(.roundedBorder)
      
      Button(
        action: {
          let result = Element(
            english: englishField,
            russian: russianField,
            answer: false,
            right: 0,
            wrong: 0, 
            answerTime: nil
          )
          onButtonTap?(result)
        }, 
        label: {
          Text(buttonTitle)
            .frame(maxWidth: .infinity, maxHeight: 40)
        }
      )
      .buttonStyle(.borderedProminent)
      
      Spacer()
    }
    .padding()
    .onAppear {
      englishField = englishValue ?? String()
      russianField = russianValue ?? String()
    }
  }
}

// MARK: - Preview

#Preview {
  ElementEditView(title: "Title", buttonTitle: "Button title")
}
