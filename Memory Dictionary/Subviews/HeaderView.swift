import SwiftUI

struct HeaderView: View {
  
  let items: [Item]
  
  var body: some View {
    HStack {
      Text("Words:")
      Text("\(items.count)")
      
      Text("Right:")
        .foregroundColor(.green)
      Text("\(items.filter { $0.shown && $0.answer }.count)")
      
      Text("Wrong:")
        .foregroundColor(.red)
      Text("\(items.filter { $0.shown && !$0.answer }.count)")
    }
    .font(.headline)
    .padding(.horizontal, 16)
  }
}

// MARK: - Preview

#Preview {
  HeaderView(items: [])
}
