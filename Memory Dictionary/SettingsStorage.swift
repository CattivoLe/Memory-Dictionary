import SwiftUI
import UserNotifications

final class SettingsStorage: ObservableObject {
  @AppStorage(Keys.isNeedToNotfication) var isNeedToNotfication: Bool = false {
    willSet {
      manageMessageNotification(newValue)
    }
  }
  
  @AppStorage(Keys.reminderMessageText) var reminderMessageText: String = String()
  @AppStorage(Keys.reminderMessageDate) var reminderMessageDate: Date = Date()
  @AppStorage(Keys.selectedlanguage) var language: Language = .rus
  
  // MARK: - Notification
  
  private func manageMessageNotification(_ addToNotification: Bool) {
    let notificationId = "cattivole.Memory-Dictionary"
    NotificationHandler.shared.removeNotifications([notificationId])
    guard addToNotification else { return }
    let date = Calendar.current.dateComponents([.hour, .minute], from: reminderMessageDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
    NotificationHandler.shared.addNotification(
      id: notificationId,
      title: "Memory Dictionary",
      subtitle: reminderMessageText,
      trigger: trigger
    )
  }
}

extension Date: RawRepresentable {
  public var rawValue: String {
    self.timeIntervalSinceReferenceDate.description
  }
  
  public init?(rawValue: String) {
    self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
  }
}

// MARK: - Keys

extension SettingsStorage {
  private struct Keys {
    static let isNeedToNotfication = "isNeedToNotfication"
    static let reminderMessageText = "reminderMessageText"
    static let reminderMessageDate = "reminderMessageDate"
    static let selectedlanguage = "selectedlanguage"
  }
}
