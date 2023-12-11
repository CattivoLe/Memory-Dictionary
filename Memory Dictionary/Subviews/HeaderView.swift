import SwiftUI

struct HeaderView: View {  
  let items: [Item]
  
  var body: some View {
    HStack {
      Image(systemName: "book")
      Text("\(items.count)")
      
      Spacer()
      
      Image(systemName: "cat.fill")
        .foregroundColor(.green)
      Text("\(items.filter { $0.shown && $0.answer }.count)")
      
      Spacer()
      
      Image(systemName: "xmark.circle")
        .foregroundColor(.red)
      Text("\(items.filter { $0.shown && !$0.answer }.count)")
    }
    .font(.headline)
  }
}

// MARK: - Preview

#Preview {
  HeaderView(items: [])
}
