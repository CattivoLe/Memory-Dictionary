import SwiftUI

struct HeaderView: View {
  @Binding var itemsCount: Int
  @Binding var rightCount: Int
  @Binding var wrongCount: Int
  
  // MARK: - Body
  
  var body: some View {
    HStack {
      Image(systemName: "book")
      Text("\(itemsCount)")
      
      Spacer()
      
      Image(systemName: "brain")
        .foregroundColor(.green)
      Text("\(rightCount)")
      
      Spacer()
      
      Image(systemName: "xmark.circle")
        .foregroundColor(.red)
      Text("\(wrongCount)")
    }
    .font(.headline)
  }
}

// MARK: - Preview

#Preview {
  HeaderView(
    itemsCount: .constant(350),
    rightCount: .constant(300),
    wrongCount: .constant(50)
  )
}
