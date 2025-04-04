import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var feedbackURL: URL? = nil // Will be set later
    
    var body: some View {
        NavigationView {
            List {
                // Appearance section
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $darkModeEnabled) {
                        Label {
                            Text("Dark Mode")
                        } icon: {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                        }
                    }
                    .onChange(of: darkModeEnabled) { _, newValue in
                        setAppearance(darkMode: newValue)
                    }
                }
                
                // Notifications section
                Section(header: Text("Notifications")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label {
                            Text("Daily Puzzle Reminder")
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        } else {
                            cancelScheduledNotifications()
                        }
                    }
                }
                
                // Support section
                Section(header: Text("Support")) {
                    Button(action: {
                        // Placeholder URL - replace with actual form URL later
                        if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfPZ_yo9cVLVqPulNHXXrgiM56s06Yj2X-svNiDQOeYH8pYYQ/viewform?usp=dialog") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label {
                            Text("Submit Feedback")
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // About section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func setAppearance(darkMode: Bool) {
        // In a full implementation, you would set the app's appearance here
        // For now, we're just storing the preference
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                scheduleNotification()
            } else {
                // Handle the case where user denied notification permissions
                DispatchQueue.main.async {
                    self.notificationsEnabled = false
                }
            }
        }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Your Daily MashUp"
        content.body = "A new word puzzle is waiting for you!"
        content.sound = .default
        
        // Configure the trigger for 8 AM daily (changed from 9 AM)
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(identifier: "dailyPuzzle", content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelScheduledNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

#Preview {
    SettingsView()
}
