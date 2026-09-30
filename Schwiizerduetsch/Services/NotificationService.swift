import UserNotifications

enum NotificationService {
    private static var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func isAuthorized() async -> Bool {
        let s = await center.notificationSettings()
        return s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
    }

    private static var messages: [(String, String)] {
        [
            ("Grüezi! 🧀", tr("Zeit für deine Schwiizerdüütsch-Lektion – nur 5 Minuten.", "Time for your Swiss German lesson – just 5 minutes.")),
            (tr("Deine Serie wartet 🔥", "Your streak is waiting 🔥"), tr("Eine kleine Lektion hält deine Serie am Leben.", "One little lesson keeps your streak alive.")),
            ("Hoi! 👋", tr("Wie geht's? Schau, was heute auf dem Plan steht.", "How are you? Come see what's on today's plan.")),
            (tr("Ein Wort am Tag 🏔️", "A word a day 🏔️"), tr("Lerne heute ein neues Wort und überrasche deine Kollegen.", "Learn a new word today and surprise your colleagues.")),
            (tr("Gemütlich lernen ☕️", "Learn at your own pace ☕️"), tr("Gönn dir eine Kaffeepause für eine Lektion.", "Take a coffee break for a lesson.")),
            (tr("Fast geschafft 💪", "Almost there 💪"), tr("Dein Tagesziel ist näher, als du denkst.", "Your daily goal is closer than you think.")),
            (tr("Sonntags-Lektion 🇨🇭", "Sunday lesson 🇨🇭"), tr("Starte gemütlich in die Woche – mit einer schnellen Lektion.", "Start the week smoothly – with a quick lesson.")),
        ]
    }

    static func scheduleDailyReminders(hour: Int, minute: Int) async {
        cancelDailyReminders()
        guard await isAuthorized() else { return }
        let msgs = messages
        for weekday in 1...7 {
            let (title, body) = msgs[(weekday - 1) % msgs.count]
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            var comps = DateComponents()
            comps.weekday = weekday
            comps.hour = hour
            comps.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            try? await center.add(UNNotificationRequest(identifier: "daily-\(weekday)", content: content, trigger: trigger))
        }
    }

    static func cancelDailyReminders() {
        center.removePendingNotificationRequests(withIdentifiers: (1...7).map { "daily-\($0)" })
    }

    /// Friendly heads-up shortly before a free trial converts to a paid subscription.
    static func scheduleTrialReminder(afterDays days: Int = 5) async {
        guard await isAuthorized() else { return }
        let content = UNMutableNotificationContent()
        content.title = tr("Deine Testphase endet bald", "Your free trial ends soon")
        content.body = tr("In 2 Tagen startet dein Jahresabo. Du kannst jederzeit in den Apple-ID-Einstellungen kündigen.",
                          "Your yearly subscription starts in 2 days. You can cancel anytime in your Apple ID settings.")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(days * 86_400), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "trial-reminder", content: content, trigger: trigger))
    }
}
