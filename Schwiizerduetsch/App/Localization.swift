import SwiftUI

/// UI language of the app. Learners see translations in German or English.
enum AppLanguage: String, CaseIterable, Identifiable {
    case de, en
    var id: String { rawValue }
    var label: String { self == .de ? "Deutsch" : "English" }

    static var system: AppLanguage {
        let code = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "de"
        return code == "de" ? .de : .en
    }

    /// Current language. Set by `ProgressStore` on launch and whenever the user changes it.
    nonisolated(unsafe) static var current: AppLanguage = .system
}

/// Inline translation helper: `tr("Weiter", "Continue")`.
func tr(_ de: String, _ en: String) -> String {
    AppLanguage.current == .de ? de : en
}

func trf(_ de: String, _ en: String, _ args: CVarArg...) -> String {
    String(format: tr(de, en), arguments: args)
}
