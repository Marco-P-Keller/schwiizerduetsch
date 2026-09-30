import SwiftUI

/// All learning content. Swiss German is written in Zürich dialect (Züridüütsch).
enum ContentData {
    private struct Builder {
        let id: String
        var items: [Phrase] = []
        mutating func add(_ ch: String, _ de: String, _ en: String, _ noteDE: String? = nil, _ noteEN: String? = nil) {
            items.append(Phrase(id: "\(id)-\(items.count + 1)", ch: ch, de: de, en: en, noteDE: noteDE, noteEN: noteEN))
        }
    }

    private static func unit(_ id: String, _ emoji: String, _ titleDE: String, _ titleEN: String,
                             _ subDE: String, _ subEN: String, _ color: UInt32, free: Bool = false,
                             _ fill: (inout Builder) -> Void) -> Unit {
        var b = Builder(id: id)
        fill(&b)
        return Unit(id: id, emoji: emoji, titleDE: titleDE, titleEN: titleEN, subtitleDE: subDE, subtitleEN: subEN,
                    color: Color(hex: color), isFree: free, phrases: b.items)
    }

    static func build() -> [Unit] {
        [
            unit("hello", "👋", "Grüessä & Basics", "Greetings & Basics", "Hallo, Danke, Tschüss", "Hello, thanks, goodbye", 0xE5202E, free: true) { b in
                b.add("Grüezi", "Guten Tag (formell)", "Hello (formal)", "«Grüezi» sagst du zu Fremden, Älteren und im Laden.", "Use «Grüezi» with strangers, older people and in shops.")
                b.add("Hoi", "Hallo (locker)", "Hi (casual)", "Das lockere «Hallo» in Zürich – unter Freunden.", "The casual «hi» in Zurich – among friends.")
                b.add("Hoi zäme", "Hallo zusammen", "Hi everyone", "«zäme» = zusammen. Ein Klassiker beim Betreten eines Raums.", "«zäme» = together. A classic when entering a room.")
                b.add("Guete Morge", "Guten Morgen", "Good morning")
                b.add("Guete Abig", "Guten Abend", "Good evening")
                b.add("Gueti Nacht", "Gute Nacht", "Good night")
                b.add("Wie gaht's?", "Wie geht's?", "How are you?", "In Bern hörst du «Wie geit's?», in Basel «Wie goht's?».", "In Bern you'll hear «Wie geit's?», in Basel «Wie goht's?».")
                b.add("Guet, merci!", "Gut, danke!", "Good, thanks!", "«Merci» kommt aus dem Französischen – und ist in der Deutschschweiz Alltag.", "«Merci» comes from French – and is everyday Swiss German.")
                b.add("Merci vilmal", "Vielen Dank", "Thanks a lot", "Noch herzlicher: «Tuusig Dank!» (Tausend Dank).", "Even warmer: «Tuusig Dank!» (a thousand thanks).")
                b.add("Bitte", "Bitte / Gern geschehen", "You're welcome", "Im Dialekt wird «Bitte» auch fürs «Gern geschehen» genutzt.", "In dialect «Bitte» also means «you're welcome».")
                b.add("Äxgüsi", "Entschuldigung", "Excuse me / Sorry", "Vom französischen «excusez». Perfekt, um sich im Tram durchzudrängen.", "From French «excusez». Perfect for squeezing through on the tram.")
                b.add("Uf Widerluege", "Auf Wiedersehen", "Goodbye (formal)", "Wörtlich: «Auf Wiederschauen». Höflich beim Verlassen von Läden.", "Literally «until we look again». Polite when leaving shops.")
                b.add("Tschau", "Tschüss (locker)", "Bye (casual)", "«Ciao» – sehr verbreitet. Auch «Ade» hört man oft.", "«Ciao» – very common. You'll also hear «Ade».")
            },
            unit("intro", "🙋", "Sich vorstellä", "Introducing Yourself", "Namen, Herkunft, Verständigung", "Names, origins, getting understood", 0xFF8A3D, free: true) { b in
                b.add("Ich heisse Anna.", "Ich heisse Anna.", "My name is Anna.", "In der Schweiz gibt es kein «ß» – man schreibt immer «ss».", "There is no «ß» in Swiss writing – it's always «ss».")
                b.add("Wie heissisch du?", "Wie heisst du?", "What's your name?", "Die du-Form endet oft auf «-sch»: heissisch, hesch, bisch.", "The du-form often ends in «-sch»: heissisch, hesch, bisch.")
                b.add("Freut mi!", "Freut mich!", "Nice to meet you!")
                b.add("Woher chunnsch du?", "Woher kommst du?", "Where are you from?", "«ch» am Wortanfang ist ein hartes «kch» – wie in «Chuchi» (Küche).", "A word-initial «ch» is a hard «kch» – like in «Chuchi» (kitchen).")
                b.add("Ich chume us Dütschland.", "Ich komme aus Deutschland.", "I'm from Germany.")
                b.add("Ich läbe i Züri.", "Ich lebe in Zürich.", "I live in Zurich.", "«i» ersetzt «in», «us» ersetzt «aus».", "«i» replaces «in», «us» replaces «aus».")
                b.add("Ich lehre Schwiizerdüütsch.", "Ich lerne Schweizerdeutsch.", "I'm learning Swiss German.", "«lehre» heisst im Dialekt «lernen».", "In dialect «lehre» means «to learn».")
                b.add("Verstahsch du mi?", "Verstehst du mich?", "Do you understand me?")
                b.add("Ich verstah nöd.", "Ich verstehe nicht.", "I don't understand.", "«nöd» ist das Dialekt-Wort für «nicht».", "«nöd» is the dialect word for «not».")
                b.add("Chasch das bitte widerhole?", "Kannst du das bitte wiederholen?", "Can you repeat that, please?")
                b.add("Chasch bitte langsamer rede?", "Kannst du bitte langsamer sprechen?", "Can you speak more slowly, please?", "«rede» = sprechen. Eine der wichtigsten Fragen für Neuankömmlinge!", "«rede» = to speak. One of the most useful questions for newcomers!")
                b.add("Sprichsch du Änglisch?", "Sprichst du Englisch?", "Do you speak English?")
            },
            unit("numbers", "🔢", "Zahle", "Numbers", "Von eis bis hundert", "From one to a hundred", 0x2F80ED) { b in
                b.add("eis", "eins (1)", "one (1)")
                b.add("zwöi", "zwei (2)", "two (2)")
                b.add("drü", "drei (3)", "three (3)")
                b.add("vier", "vier (4)", "four (4)")
                b.add("föif", "fünf (5)", "five (5)")
                b.add("sächs", "sechs (6)", "six (6)")
                b.add("sibe", "sieben (7)", "seven (7)")
                b.add("acht", "acht (8)", "eight (8)")
                b.add("nüün", "neun (9)", "nine (9)")
                b.add("zää", "zehn (10)", "ten (10)")
                b.add("zwänzg", "zwanzig (20)", "twenty (20)")
                b.add("hundert", "hundert (100)", "one hundred (100)")
            },
            unit("time", "🗓️", "Ziit & Wuchetäg", "Time & Weekdays", "Wochentage und Uhrzeit", "Weekdays and telling time", 0x8E5CF7) { b in
                b.add("Määntig", "Montag", "Monday")
                b.add("Ziischtig", "Dienstag", "Tuesday", "«Ziischtig» – das klingt fast nach «Zischeln».", "«Ziischtig» – sounds a bit like whispering.")
                b.add("Mittwuch", "Mittwoch", "Wednesday")
                b.add("Dunschtig", "Donnerstag", "Thursday")
                b.add("Friitig", "Freitag", "Friday")
                b.add("Samschtig", "Samstag", "Saturday")
                b.add("Sunntig", "Sonntag", "Sunday")
                b.add("hüt", "heute", "today")
                b.add("morn", "morgen", "tomorrow")
                b.add("geschter", "gestern", "yesterday")
                b.add("Wie spaat isch es?", "Wie spät ist es?", "What time is it?", "«spaat» wird mit langem «aa» gesprochen.", "«spaat» is pronounced with a long «aa».")
                b.add("Es isch halbi zwei.", "Es ist halb zwei.", "It's half past one.", "Wie im Deutschen: «halbi zwei» = 1:30 Uhr.", "Like in German: «halbi zwei» = 1:30.")
            },
            unit("food", "🧀", "Ässe & Trinke", "Food & Drinks", "Fondue, Kafi und Prost", "Fondue, coffee and cheers", 0xF5B335) { b in
                b.add("Ich hätt gärn en Kafi.", "Ich hätte gern einen Kaffee.", "I'd like a coffee.", "«Kafi» ist der Schweizer Kaffee – «Kafi Crème» ist der Klassiker.", "«Kafi» is the Swiss coffee – «Kafi Crème» is the classic.")
                b.add("Es Wasser, bitte.", "Ein Wasser, bitte.", "A water, please.", "«Es» statt «ein» – Wasser ist im Dialekt sächlich: es Wasser.", "«Es» instead of «ein» – in dialect water is neuter: es Wasser.")
                b.add("Es Bier, bitte.", "Ein Bier, bitte.", "A beer, please.")
                b.add("Ich han Hunger.", "Ich habe Hunger.", "I'm hungry.", "«han» = habe. Ein Wort, das du hundertmal brauchst.", "«han» = have. A word you'll use a hundred times.")
                b.add("Ich han Durscht.", "Ich habe Durst.", "I'm thirsty.")
                b.add("En Guete!", "Guten Appetit!", "Enjoy your meal!", "Wird vor dem Essen gesagt – und auch, wenn du an fremden Tischen vorbeigehst.", "Said before eating – even to strangers you walk past.")
                b.add("Das schmöckt guet!", "Das schmeckt gut!", "That tastes good!")
                b.add("Proscht!", "Prost!", "Cheers!", "Beim Anstossen schaut man sich in die Augen!", "When clinking glasses, look each other in the eye!")
                b.add("Zmorge, Zmittag, Znacht", "Frühstück, Mittagessen, Abendessen", "Breakfast, lunch, dinner", "Dazu: «Znüni» (Snack am Vormittag) und «Zvieri» (Nachmittags-Snack).", "Plus «Znüni» (mid-morning snack) and «Zvieri» (afternoon snack).")
                b.add("Ich nimm es Fondue.", "Ich nehme ein Fondue.", "I'll have a fondue.")
                b.add("Ich bi Vegetarier.", "Ich bin Vegetarier.", "I'm vegetarian.")
                b.add("Ohni Fleisch, bitte.", "Ohne Fleisch, bitte.", "Without meat, please.")
            },
            unit("restaurant", "🍽️", "Im Restaurant", "At the Restaurant", "Bestellen, zahlen, Trinkgeld", "Ordering, paying, tipping", 0xEB5757) { b in
                b.add("Händ Sie en Tisch frei?", "Haben Sie einen Tisch frei?", "Do you have a table free?", "Im Restaurant sagt man meist «Sie» – nicht «du».", "In restaurants people usually use the formal «Sie».")
                b.add("D Charte, bitte.", "Die Speisekarte, bitte.", "The menu, please.")
                b.add("Was chönd Sie empfehle?", "Was können Sie empfehlen?", "What do you recommend?")
                b.add("Ich nimm s Menü.", "Ich nehme das Menü.", "I'll take the set menu.")
                b.add("Isch da no frei?", "Ist hier noch frei?", "Is this seat taken?")
                b.add("Nonemal es Wasser, bitte.", "Noch ein Wasser, bitte.", "Another water, please.", "«nonemal» = noch einmal.", "«nonemal» = once more.")
                b.add("Es isch fein gsi.", "Es war sehr lecker.", "It was delicious.", "«fein» heisst in der Schweiz auch «lecker».", "«fein» also means «tasty» in Swiss usage.")
                b.add("Chönd mir zahle?", "Können wir zahlen?", "Can we pay?")
                b.add("Zäme oder einzeln?", "Zusammen oder getrennt?", "Together or separate?")
                b.add("D Rächnig, bitte.", "Die Rechnung, bitte.", "The bill, please.")
                b.add("Schtimmt so.", "Stimmt so.", "Keep the change.", "Trinkgeld ist in der Schweiz freiwillig – aufrunden ist üblich.", "Tipping is optional in Switzerland – rounding up is common.")
                b.add("Es het super gschmöckt.", "Es hat super geschmeckt.", "It tasted great.")
            },
            unit("shopping", "🛍️", "Poschte & Chaufe", "Shopping", "Preise, Kasse, Tüte", "Prices, checkout, bags", 0x27AE60) { b in
                b.add("Was choschtet das?", "Was kostet das?", "How much is this?")
                b.add("Das isch mer z tüür.", "Das ist mir zu teuer.", "That's too expensive for me.", "«z tüür» = zu teuer. Schweizer Preise… ja, wir wissen es.", "«z tüür» = too expensive. Swiss prices… yes, we know.")
                b.add("Ich luege nu.", "Ich schaue nur.", "I'm just looking.", "«luege» = schauen.", "«luege» = to look.")
                b.add("Ich nimm das.", "Ich nehme das.", "I'll take it.")
                b.add("Chan ich mit Charte zahle?", "Kann ich mit Karte zahlen?", "Can I pay by card?")
                b.add("Bar oder Charte?", "Bar oder Karte?", "Cash or card?")
                b.add("Händ Sie das au i grösser?", "Haben Sie das auch in grösser?", "Do you have this in a bigger size?")
                b.add("Wo isch d Chasse?", "Wo ist die Kasse?", "Where is the checkout?")
                b.add("Chan ich en Quittig ha?", "Kann ich einen Beleg haben?", "Can I have a receipt?", "«Quittig» = Quittung / Beleg.", "«Quittig» = receipt.")
                b.add("Bruuched Sie en Sack?", "Brauchen Sie eine Tüte?", "Do you need a bag?", "Ein «Sack» ist in der Schweiz auch die Tüte.", "A «Sack» is what Swiss people call a bag.")
                b.add("Es isch im Aagebot.", "Es ist im Angebot.", "It's on sale.")
                b.add("Wänn gönd Sie zue?", "Wann schliessen Sie?", "When do you close?")
            },
            unit("transport", "🚆", "Underwägs", "Getting Around", "Zug, Tram, Billett", "Trains, trams, tickets", 0x00A3AD) { b in
                b.add("Wo isch de Bahnhof?", "Wo ist der Bahnhof?", "Where is the train station?")
                b.add("Wänn fahrt de nächscht Zug?", "Wann fährt der nächste Zug?", "When does the next train leave?")
                b.add("Es Billett nach Bärn, bitte.", "Ein Ticket nach Bern, bitte.", "A ticket to Bern, please.", "Das Ticket heisst in der Schweiz «Billett».", "A ticket is called «Billett» in Switzerland.")
                b.add("Uf wellem Gleis?", "Auf welchem Gleis?", "Which platform?")
                b.add("De Zug het Verspötig.", "Der Zug hat Verspätung.", "The train is delayed.", "Selten, aber es kommt vor…", "Rare, but it happens…")
                b.add("Wo mues ich umstige?", "Wo muss ich umsteigen?", "Where do I have to change?")
                b.add("Ich mues do usstige.", "Ich muss hier aussteigen.", "I have to get off here.")
                b.add("Händ Sie es Halbtax?", "Haben Sie ein Halbtax?", "Do you have a Half Fare card?", "Das Halbtax gibt 50 % Rabatt auf ÖV-Billette.", "The Half Fare card gives 50 % off public transport.")
                b.add("linggs", "links", "left")
                b.add("rächts", "rechts", "right")
                b.add("geradus", "geradeaus", "straight ahead")
                b.add("Wo isch d Tramhaltestell?", "Wo ist die Tramhaltestelle?", "Where is the tram stop?")
            },
            unit("smalltalk", "☀️", "Smalltalk & Wätter", "Small Talk & Weather", "Über Gott und die Wälder", "Chatting like a local", 0xF2994A) { b in
                b.add("Schöns Wätter hüt, gäll?", "Schönes Wetter heute, nicht wahr?", "Nice weather today, isn't it?", "«gäll» ist das typische Schweizer «nicht wahr?».", "«gäll» is the typical Swiss «right?».")
                b.add("Es regnet.", "Es regnet.", "It's raining.")
                b.add("Es schneit.", "Es schneit.", "It's snowing.")
                b.add("Es isch chalt.", "Es ist kalt.", "It's cold.")
                b.add("Was machsch am Wucheänd?", "Was machst du am Wochenende?", "What are you doing at the weekend?")
                b.add("Ich gaa id Bärge.", "Ich gehe in die Berge.", "I'm going to the mountains.", "Die Schweizer und ihre Berge: Am Wochenende ist der Zug voller Wanderer.", "Swiss people and their mountains: weekend trains are full of hikers.")
                b.add("Hesch Ziit?", "Hast du Zeit?", "Do you have time?")
                b.add("Gärn gscheh!", "Gern geschehen!", "My pleasure!")
                b.add("Kei Ahnig.", "Keine Ahnung.", "No idea.")
                b.add("Kei Stress!", "Kein Stress!", "No stress!")
                b.add("Mega!", "Mega! / Super!", "Awesome!")
                b.add("Nüt für unguet.", "Nichts für ungut.", "No offence.")
            },
            unit("work", "💼", "Büez & Alltag", "Work & Daily Life", "Sitzig, Homeoffice, Fiirabig", "Meetings, home office, clocking out", 0x4F5D75) { b in
                b.add("Ich schaffe bi ere Firma.", "Ich arbeite bei einer Firma.", "I work at a company.", "«schaffe» = arbeiten. Im Dialekt ist das das Alltagswort für «arbeiten».", "«schaffe» = to work. It's the everyday dialect word for working.")
                b.add("Ich bi im Homeoffice.", "Ich bin im Homeoffice.", "I'm working from home.")
                b.add("Mir händ e Sitzig.", "Wir haben eine Sitzung.", "We have a meeting.", "«Sitzig» = Meeting. Ganz typisch schweizerisch.", "«Sitzig» = meeting. Very Swiss.")
                b.add("Ich schick dir es Mail.", "Ich schicke dir eine Mail.", "I'll send you an email.")
                b.add("Chönd mir das churz bespräche?", "Können wir das kurz besprechen?", "Can we quickly discuss this?")
                b.add("Isch das dringend?", "Ist das dringend?", "Is that urgent?")
                b.add("Ich mues churz telefoniere.", "Ich muss kurz telefonieren.", "I need to make a quick call.")
                b.add("Fiirabig!", "Feierabend!", "Done for the day!", "Nach der Arbeit: «Fiirabigbierli» – das Feierabendbier.", "After work: «Fiirabigbierli» – the after-work beer.")
                b.add("Ich han Ferie.", "Ich habe Ferien.", "I'm on holiday.")
                b.add("Ich bi chrank.", "Ich bin krank.", "I'm sick.")
                b.add("Mir gsehnd üs am Määntig.", "Wir sehen uns am Montag.", "See you on Monday.")
                b.add("Schöns Wucheänd!", "Schönes Wochenende!", "Have a nice weekend!")
            },
            unit("health", "🩺", "Gsundheit & Notfall", "Health & Emergencies", "Für den Ernstfall gerüstet", "Prepared for the worst", 0xD63E5C) { b in
                b.add("Ich bruuche Hilf.", "Ich brauche Hilfe.", "I need help.")
                b.add("Rüef en Ambulanz!", "Ruf einen Krankenwagen!", "Call an ambulance!")
                b.add("Rüef d Polizei!", "Ruf die Polizei!", "Call the police!")
                b.add("De Notruef isch eis-vier-vier.", "Der Notruf ist 144.", "The emergency number is 144.", "144 Sanität · 117 Polizei · 118 Feuerwehr · 112 europäischer Notruf.", "144 ambulance · 117 police · 118 fire brigade · 112 European emergency number.")
                b.add("Ich mues zum Dokter.", "Ich muss zum Arzt.", "I need to see a doctor.")
                b.add("Ich han Chopfwee.", "Ich habe Kopfschmerzen.", "I have a headache.", "«wee» = weh: Chopfwee, Buchwee, Zahnwee.", "«wee» = pain: Chopfwee, Buchwee, Zahnwee.")
                b.add("Ich han Buchwee.", "Ich habe Bauchschmerzen.", "I have a stomach ache.")
                b.add("Ich han Zahnwee.", "Ich habe Zahnschmerzen.", "I have a toothache.")
                b.add("Mir isch schlächt.", "Mir ist schlecht.", "I feel sick.")
                b.add("Wo isch d Apothek?", "Wo ist die Apotheke?", "Where is the pharmacy?")
                b.add("Ich bi allergisch gäge Nüss.", "Ich bin allergisch gegen Nüsse.", "I'm allergic to nuts.")
                b.add("Gsundheit!", "Gesundheit!", "Bless you!")
            },
            unit("culture", "🎉", "Fiire & Bruuchtum", "Celebrations & Traditions", "Fäschte, Wünsch, Jass", "Festivities, wishes, Jass", 0x9B51E0) { b in
                b.add("Frohi Wiehnachte!", "Frohe Weihnachten!", "Merry Christmas!")
                b.add("Es guets Neus!", "Ein gutes neues Jahr!", "Happy New Year!")
                b.add("Schöni Oschtere!", "Schöne Ostern!", "Happy Easter!")
                b.add("Alles Gueti zum Geburi!", "Alles Gute zum Geburtstag!", "Happy birthday!", "«Geburi» ist die Kurzform von Geburtstag.", "«Geburi» is the short form of «Geburtstag».")
                b.add("Gratuliere!", "Glückwunsch!", "Congratulations!")
                b.add("En guete Rutsch!", "Einen guten Rutsch!", "Have a good start to the year!")
                b.add("Mir fiired de eis Auguscht.", "Wir feiern den 1. August.", "We celebrate the 1st of August.", "Der 1. August ist der Schweizer Nationalfeiertag – mit Feuerwerk und Lampions.", "August 1st is Swiss National Day – with fireworks and lanterns.")
                b.add("Mir gönd go wandere.", "Wir gehen wandern.", "We're going hiking.")
                b.add("Mir gönd go Ski fahre.", "Wir gehen Ski fahren.", "We're going skiing.")
                b.add("Mir jasset am Abig.", "Wir jassen am Abend.", "We're playing Jass tonight.", "Jass ist das Schweizer Nationalkartenspiel.", "Jass is Switzerland's national card game.")
                b.add("Ich mag Schoggi.", "Ich mag Schokolade.", "I like chocolate.")
                b.add("Du bisch härzig!", "Du bist süss!", "You're adorable!", "«härzig» ist das Schweizer Wort für süss, herzig.", "«härzig» is the Swiss word for sweet or cute.")
            },
            unit("slang", "😎", "Slang & Umgangssprach", "Slang & Everyday Talk", "Wie Einheimische sprechen", "Talk like a local", 0x1E1E22) { b in
                b.add("Lässig!", "Cool!", "Cool!")
                b.add("Mega guet!", "Mega gut!", "Really good!")
                b.add("Es isch huere guet.", "Es ist verdammt gut.", "It's damn good.", "«huere» verstärkt fast alles – ein milder Kraftausdruck, der in der Schweiz Alltag ist.", "«huere» intensifies almost anything – a mild expletive that's everyday Swiss talk.")
                b.add("Ich han kei Luscht.", "Ich habe keine Lust.", "I don't feel like it.")
                b.add("Das isch mer wurscht.", "Das ist mir egal.", "I don't care.")
                b.add("Gopf!", "Verflixt!", "Darn!", "Ein milder Fluch – kurz für «Gott».", "A mild curse – short for «God».")
                b.add("Tuusig Dank!", "Tausend Dank!", "A thousand thanks!")
                b.add("Stress di nöd!", "Stress dich nicht!", "Don't stress!")
                b.add("Ich bi todmüed.", "Ich bin todmüde.", "I'm dead tired.")
                b.add("Chumm, mir gönd es Bierli neh.", "Komm, wir gehen ein Bierchen trinken.", "Come on, let's grab a beer.", "«-li» macht alles klein und nett: Bierli, Kafi-Päuseli, Meitli.", "«-li» makes everything small and cute: Bierli, Kafi-Päuseli, Meitli.")
                b.add("Nei, sicher nöd!", "Nein, sicher nicht!", "No way!")
                b.add("Es isch gmüetlich do.", "Es ist gemütlich hier.", "It's cosy here.", "«gmüetlich» ist ein Schweizer Lieblingswort – und ein Lebensgefühl.", "«gmüetlich» is a Swiss favourite – and a way of life.")
            },
            unit("family", "👨‍👩‍👧", "Familie & Fründe", "Family & Friends", "Mami, Papi, Grosi", "Mum, dad, grandma", 0x56CCF2) { b in
                b.add("Mami und Papi", "Mama und Papa", "Mum and dad")
                b.add("Grosi und Grosspapi", "Oma und Opa", "Grandma and grandpa")
                b.add("Ich han en Brüeder und e Schwöschter.", "Ich habe einen Bruder und eine Schwester.", "I have a brother and a sister.")
                b.add("Hesch du Gschwüschterti?", "Hast du Geschwister?", "Do you have siblings?")
                b.add("Das isch min Fründ.", "Das ist mein Freund.", "This is my friend / boyfriend.")
                b.add("Das isch mini Fründin.", "Das ist meine Freundin.", "This is my friend / girlfriend.")
                b.add("Mir sind verhüratet.", "Wir sind verheiratet.", "We're married.")
                b.add("Ich han zwöi Chind.", "Ich habe zwei Kinder.", "I have two children.")
                b.add("Wie alt bisch du?", "Wie alt bist du?", "How old are you?")
                b.add("Ich bi driissg Jahr alt.", "Ich bin dreissig Jahre alt.", "I'm thirty years old.")
                b.add("Wo wohnsch du?", "Wo wohnst du?", "Where do you live?")
                b.add("Chumm doch verbii!", "Komm doch vorbei!", "Come over!")
            },
            unit("leisure", "🏔️", "Freizit & Bärge", "Leisure & Mountains", "Wandere, Velo, Chino", "Hiking, cycling, cinema", 0x3D8B6E) { b in
                b.add("Ich gaa gärn wandere.", "Ich gehe gern wandern.", "I like going hiking.")
                b.add("Chunnsch mit id Bärge?", "Kommst du mit in die Berge?", "Are you coming to the mountains?")
                b.add("Wo isch de nächscht Wanderwäg?", "Wo ist der nächste Wanderweg?", "Where is the nearest hiking trail?")
                b.add("De Bärg isch huere höch.", "Der Berg ist verdammt hoch.", "The mountain is damn high.")
                b.add("Ich fahr mit em Velo.", "Ich fahre mit dem Fahrrad.", "I go by bike.", "Ein Fahrrad heisst in der Schweiz immer «Velo».", "In Switzerland a bicycle is always a «Velo».")
                b.add("Mir gönd go schwümme.", "Wir gehen schwimmen.", "We're going swimming.", "Im Sommer: Aare, Limmat und Rhein – Fluss-Schwimmen ist Kult!", "In summer: the Aare, Limmat and Rhine – river swimming is a cult!")
                b.add("Mir gönd go grilliere.", "Wir gehen grillieren.", "We're going for a barbecue.")
                b.add("Hesch Luscht uf en Film?", "Hast du Lust auf einen Film?", "Do you fancy a film?")
                b.add("Mir gönd is Chino.", "Wir gehen ins Kino.", "We're going to the cinema.")
                b.add("Ich gaa go jogge.", "Ich gehe joggen.", "I'm going for a run.")
                b.add("Es isch en schöne See.", "Das ist ein schöner See.", "It's a beautiful lake.")
                b.add("Ich lise es Buech.", "Ich lese ein Buch.", "I'm reading a book.")
            },
        ]
    }
}
