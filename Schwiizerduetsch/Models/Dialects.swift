import SwiftUI

struct DialectRegion: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let blurbDE: String
    let blurbEN: String
    var blurb: String { AppLanguage.current == .de ? blurbDE : blurbEN }
}

struct DialectConcept: Identifiable {
    let id: String
    let de: String
    let en: String
    /// region id -> dialect word
    let words: [String: String]
    var meaning: String { AppLanguage.current == .de ? de : en }
}

enum Dialects {
    static let regions: [DialectRegion] = [
        DialectRegion(id: "zh", name: "Züri", emoji: "🦁",
                      blurbDE: "Züridüütsch – das «Standard»-Schweizerdeutsch aus Radio, Werbung und Serien. Diese App bringt dir diesen Dialekt bei.",
                      blurbEN: "Zürich German – the «default» Swiss German from radio, ads and TV. This is the dialect the app teaches you."),
        DialectRegion(id: "be", name: "Bärn", emoji: "🐻",
                      blurbDE: "Bärndütsch klingt gemütlich und langsam. Typisch: das «l» wird zu «u» – aus «Milch» wird «Miuch».",
                      blurbEN: "Bernese German sounds cosy and slow. Typical: the «l» turns into «u» – «Milch» becomes «Miuch»."),
        DialectRegion(id: "bs", name: "Basel", emoji: "🎭",
                      blurbDE: "Baseldytsch ist melodisch und hat viele Einflüsse aus dem Französischen und Elsässischen. Sehr eigen – und sehr charmant.",
                      blurbEN: "Basel German is melodic, with French and Alsatian influences. Very distinctive – and very charming."),
    ]

    static let concepts: [DialectConcept] = [
        DialectConcept(id: "howareyou", de: "Wie geht's?", en: "How are you?",
                       words: ["zh": "Wie gaht's?", "be": "Wie geit's?", "bs": "Wie goht's?"]),
        DialectConcept(id: "hello", de: "Guten Tag (formell)", en: "Hello (formal)",
                       words: ["zh": "Grüezi", "be": "Grüessech", "bs": "Salü / Grüezi"]),
        DialectConcept(id: "roll", de: "Brötchen", en: "Bread roll",
                       words: ["zh": "Bürli", "be": "Mütschli", "bs": "Weggli"]),
        DialectConcept(id: "boy", de: "Junge", en: "Boy",
                       words: ["zh": "Bueb", "be": "Giel", "bs": "Bueb"]),
        DialectConcept(id: "girl", de: "Mädchen", en: "Girl",
                       words: ["zh": "Meitli", "be": "Meitschi", "bs": "Meitli"]),
        DialectConcept(id: "milk", de: "Milch", en: "Milk",
                       words: ["zh": "Milch", "be": "Miuch", "bs": "Milch"]),
        DialectConcept(id: "school", de: "Schule", en: "School",
                       words: ["zh": "Schuel", "be": "Schueu", "bs": "Schuel"]),
        DialectConcept(id: "potato", de: "Kartoffel", en: "Potato",
                       words: ["zh": "Härdöpfel", "be": "Härdöpfu", "bs": "Herdöpfel"]),
        DialectConcept(id: "yes", de: "Ja", en: "Yes",
                       words: ["zh": "Jo", "be": "Ja / Jou", "bs": "Jo"]),
        DialectConcept(id: "goodbye", de: "Tschüss", en: "Bye",
                       words: ["zh": "Tschau / Ade", "be": "Tschüss / Adiö", "bs": "Adie / Tschüss"]),
    ]
}

struct QuizQuestion: Identifiable {
    let id: Int
    let questionDE: String
    let questionEN: String
    let optionsDE: [String]
    let optionsEN: [String]
    let answer: Int
    let explainDE: String
    let explainEN: String

    var question: String { AppLanguage.current == .de ? questionDE : questionEN }
    var options: [String] { AppLanguage.current == .de ? optionsDE : optionsEN }
    var explain: String { AppLanguage.current == .de ? explainDE : explainEN }
}

enum Quiz {
    static let questions: [QuizQuestion] = [
        QuizQuestion(id: 1, questionDE: "Was bedeutet «Merci vilmal»?", questionEN: "What does «Merci vilmal» mean?",
                     optionsDE: ["Vielen Dank", "Entschuldigung", "Gute Nacht", "Guten Appetit"],
                     optionsEN: ["Thanks a lot", "Excuse me", "Good night", "Enjoy your meal"], answer: 0,
                     explainDE: "«Merci» kommt aus dem Französischen und ist in der Deutschschweiz ganz normal.",
                     explainEN: "«Merci» comes from French and is perfectly normal in German-speaking Switzerland."),
        QuizQuestion(id: 2, questionDE: "Was ist ein «Znüni»?", questionEN: "What is a «Znüni»?",
                     optionsDE: ["Ein Zug um neun", "Eine Zwischenmahlzeit am Vormittag", "Ein Feiertag", "Eine Kartenspielregel"],
                     optionsEN: ["A train at nine", "A mid-morning snack", "A public holiday", "A card game rule"], answer: 1,
                     explainDE: "Znüni = «Zu neun» Uhr – die kleine Pause am Vormittag.",
                     explainEN: "Znüni = «at nine» – the little break in the morning."),
        QuizQuestion(id: 3, questionDE: "Wie sagt man in der Schweiz zum Fahrrad?", questionEN: "What do Swiss people call a bicycle?",
                     optionsDE: ["Rad", "Velo", "Drahtesel", "Bike"], optionsEN: ["Rad", "Velo", "Drahtesel", "Bike"], answer: 1,
                     explainDE: "Velo – vom französischen «vélocipède».", explainEN: "Velo – from the French «vélocipède»."),
        QuizQuestion(id: 4, questionDE: "Wie viele Landessprachen hat die Schweiz?", questionEN: "How many national languages does Switzerland have?",
                     optionsDE: ["2", "3", "4", "5"], optionsEN: ["2", "3", "4", "5"], answer: 2,
                     explainDE: "Deutsch, Französisch, Italienisch und Rätoromanisch.", explainEN: "German, French, Italian and Romansh."),
        QuizQuestion(id: 5, questionDE: "Was bedeutet «Uf Widerluege»?", questionEN: "What does «Uf Widerluege» mean?",
                     optionsDE: ["Guten Morgen", "Auf Wiedersehen", "Willkommen", "Viel Glück"],
                     optionsEN: ["Good morning", "Goodbye", "Welcome", "Good luck"], answer: 1,
                     explainDE: "Wörtlich: «Auf Wiederschauen».", explainEN: "Literally «until we look again»."),
        QuizQuestion(id: 6, questionDE: "Welche Notrufnummer gilt für die Polizei?", questionEN: "Which number do you call for the police?",
                     optionsDE: ["112", "117", "144", "118"], optionsEN: ["112", "117", "144", "118"], answer: 1,
                     explainDE: "117 Polizei · 118 Feuerwehr · 144 Sanität.", explainEN: "117 police · 118 fire brigade · 144 ambulance."),
        QuizQuestion(id: 7, questionDE: "Was ist «Jass»?", questionEN: "What is «Jass»?",
                     optionsDE: ["Ein Käsegericht", "Ein Kartenspiel", "Eine Bergbahn", "Ein Tanz"],
                     optionsEN: ["A cheese dish", "A card game", "A mountain railway", "A dance"], answer: 1,
                     explainDE: "Jass ist das Schweizer Nationalkartenspiel.", explainEN: "Jass is Switzerland's national card game."),
        QuizQuestion(id: 8, questionDE: "Was ist der «Röstigraben»?", questionEN: "What is the «Röstigraben»?",
                     optionsDE: ["Ein Graben in den Alpen", "Die kulturelle Grenze zwischen Deutsch- und Westschweiz", "Ein Restaurant", "Ein Fluss"],
                     optionsEN: ["A trench in the Alps", "The cultural divide between German- and French-speaking Switzerland", "A restaurant", "A river"], answer: 1,
                     explainDE: "Ein humorvoller Begriff – benannt nach dem Deutschschweizer Rösti.", explainEN: "A humorous term – named after the German-Swiss Rösti."),
        QuizQuestion(id: 9, questionDE: "Was heisst «Grosi»?", questionEN: "What does «Grosi» mean?",
                     optionsDE: ["Grossvater", "Grossmutter", "Grosses Haus", "Grosse Schwester"],
                     optionsEN: ["Grandfather", "Grandmother", "Big house", "Big sister"], answer: 1,
                     explainDE: "Grosi = Oma.", explainEN: "Grosi = grandma."),
        QuizQuestion(id: 10, questionDE: "Wie heisst die Hauptstadt der Schweiz?", questionEN: "What is the capital of Switzerland?",
                     optionsDE: ["Zürich", "Genf", "Bern", "Basel"], optionsEN: ["Zurich", "Geneva", "Bern", "Basel"], answer: 2,
                     explainDE: "Bern – offiziell «Bundesstadt».", explainEN: "Bern – officially the «federal city»."),
    ]

    struct Rank {
        let emoji: String
        let titleDE: String
        let titleEN: String
        var title: String { AppLanguage.current == .de ? titleDE : titleEN }
    }

    static func rank(score: Int) -> Rank {
        switch score {
        case 9...: return Rank(emoji: "🏔️", titleDE: "Waschächte Eidgenoss", titleEN: "True Swiss Native")
        case 7...8: return Rank(emoji: "🧀", titleDE: "Fondue-Profi", titleEN: "Fondue Pro")
        case 5...6: return Rank(emoji: "🚆", titleDE: "Pendler mit Halbtax", titleEN: "Commuter with a Half Fare")
        case 3...4: return Rank(emoji: "🧳", titleDE: "Frischer Expat", titleEN: "Fresh Expat")
        default: return Rank(emoji: "📷", titleDE: "Matterhorn-Tourist", titleEN: "Matterhorn Tourist")
        }
    }
}
