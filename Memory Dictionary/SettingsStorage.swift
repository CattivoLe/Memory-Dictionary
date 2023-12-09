import Foundation
import UserNotifications

final class SettingsStorage: ObservableObject {
  var isNeedToNotfication: Bool = UserDefaults.isNeedToNotfication {
    willSet {
      UserDefaults.isNeedToNotfication = newValue
      manageMessageNotification(newValue)
    }
  }
  
  var reminderMessageText: String = UserDefaults.reminderMessageText {
    willSet {
      UserDefaults.reminderMessageText = newValue
    }
  }
  
  var reminderMessageDate: Date = UserDefaults.reminderMessageDate {
    willSet {
      UserDefaults.reminderMessageDate = newValue
    }
  }
  
  var language: Language = UserDefaults.language {
    willSet {
      UserDefaults.language = newValue
    }
  }
  
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

// MARK: - ReminderMessage

extension UserDefaults {
  static var isNeedToNotfication: Bool {
    get {
      UserDefaults.standard.bool(forKey: Keys.isNeedToNotfication)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Keys.isNeedToNotfication)
    }
  }
  
  static var reminderMessageText: String {
    get {
      UserDefaults.standard.string(forKey: Keys.reminderMessageText) ?? String()
    }
    set {
      UserDefaults.standard.set(newValue, forKey: Keys.reminderMessageText)
    }
  }
  
  static var reminderMessageDate: Date {
    get {
      if let value = UserDefaults.standard.object(forKey: Keys.reminderMessageDate) as? Data,
         let date = try? JSONDecoder().decode(Date.self, from: value) {
        return date
      } else {
        return Date()
      }
    }
    set {
      if let encoded = try? JSONEncoder().encode(newValue) {
        UserDefaults.standard.set(encoded, forKey: Keys.reminderMessageDate)
      }
    }
  }
}

// MARK: - Settings

extension UserDefaults {
  static var language: Language {
    get {
      if let value = UserDefaults.standard.object(forKey: Keys.selectedlanguage) as? String {
        return Language(rawValue: value) ?? .rus
      }
      else {
        return .rus
      }
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: Keys.selectedlanguage)
    }
  }
}

// MARK: - Keys

extension UserDefaults {
  private struct Keys {
    static let isNeedToNotfication = "isNeedToNotfication"
    static let reminderMessageText = "reminderMessageText"
    static let reminderMessageDate = "reminderMessageDate"
    static let selectedlanguage = "selectedlanguage"
  }
}
