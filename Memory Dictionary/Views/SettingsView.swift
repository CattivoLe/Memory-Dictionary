import SwiftUI
import UserNotifications

struct SettingsView: View {
  @ObservedObject private var settingsStorage = SettingsStorage()
  
  @State private var toShowRequestPermissionAlert: Bool = false
  @State private var toShowClearResultsAlert: Bool = false
  @State private var languages: [Language] = [.rus, .eng]
  
  var onClearResults: (() -> Void)?
  
  // MARK: - Body
  
  var body: some View {
    Form {
      Section("Notification") {
        HStack(spacing: .zero) {
          DatePicker("Time",selection: $settingsStorage.reminderMessageDate, displayedComponents: [.hourAndMinute])
          
          Toggle("", isOn: $settingsStorage.isNeedToNotfication)
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        
        TextField("Message text", text: $settingsStorage.reminderMessageText)
      }
      
      Section("Settings") {
        Picker("Language", selection: $settingsStorage.language) {
          ForEach(languages, id: \.self) { language in
            Text(language.rawValue)
              .tag(language)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
      }
      
      Button(
        action: {
          toShowClearResultsAlert.toggle()
        },
        label: {
          Text("Clear all results")
        }
      )
    }
    .navigationTitle("Settings")
    .onAppear {
      UISegmentedControl.appearance().selectedSegmentTintColor = .systemBlue
      NotificationHandler.shared.requestPermission(onDeny: {
        toShowRequestPermissionAlert.toggle()
      })
    }
    .alert(isPresented: $toShowRequestPermissionAlert) {
      Alert(
        title: Text("Notification has been disabled for this app"),
        message: Text("Please go to settings to enable it now"),
        primaryButton: .default(Text("Go To Settings")) { goToSettings() },
        secondaryButton: .cancel()
      )
    }
    .alert(isPresented: $toShowClearResultsAlert) {
      Alert(
        title: Text("Attention"),
        message: Text("All saved results will be reset and this action cannot be rewert."),
        primaryButton: .default(Text("Do it")) { onClearResults?() },
        secondaryButton: .cancel()
      )
    }
  }
  
  // MARK: - GoToSettings
  
  private func goToSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}

// MARK: - Preview

#Preview {
  SettingsView()
}
