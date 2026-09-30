# -*- coding: utf-8 -*-
import json
TERMS="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
PRIV="https://marco-p-keller.github.io/schwiizerduetsch/privacy.html"
MARK="https://marco-p-keller.github.io/schwiizerduetsch/"
SUP="https://marco-p-keller.github.io/schwiizerduetsch/support.html"

en = dict(
 name="Swiss German: Schwiizerdüütsch",
 subtitle="Dialect Lessons for Expats",
 promo="Learn Swiss German in 5 minutes a day. Chapters 1–2 are free: audio, real-life phrases, a dialect explorer and the “How Swiss are you?” quiz.",
 keywords="learn,language,zurich,bern,basel,switzerland,phrases,words,vocabulary,speak,course,beginner,grüezi",
 description=f"""Learn Swiss German the fun way – in just 5 minutes a day.

Moving to Zurich? Dating someone Swiss? Starting a job in Switzerland? Or simply curious about “Grüezi”, “Znüni” and “Merci vilmal”? Schwiizerdüütsch teaches you the everyday Swiss German you actually hear on the street, on the tram and at the office.

★ SHORT, ADDICTIVE LESSONS
Bite-sized lessons with listening, translation, matching pairs and sentence building. Earn XP, keep your streak alive and reach your daily goal.

★ 15 CHAPTERS · 180+ REAL-LIFE PHRASES
Greetings, introductions, numbers, restaurant, shopping, public transport, small talk, work, health & emergencies, celebrations, slang, family and the mountains – the phrases you really need.

★ HEAR IT, SAY IT
Audio for every phrase, at normal and slow speed. (Pronunciation is approximated with your device’s built-in voice as a learning aid.)

★ DIALECT EXPLORER
Zürich, Bern or Basel? Compare how the same word sounds in different regions of Switzerland.

★ “HOW SWISS ARE YOU?” QUIZ
Test your Swissness and share your result with friends.

★ CULTURE TIPS & SMART REVIEW
Every phrase comes with a tip, and the smart review brings back exactly what you struggle with. Set a daily reminder and never lose your streak.

★ PRIVATE BY DESIGN
No account, no ads, no tracking. Your progress stays on your device.

FREE & PREMIUM
Chapters 1 and 2 are free forever. Unlock all chapters, the dialect explorer and smart review with Schwiizerdüütsch Premium:
• Yearly – with a 7-day free trial for new subscribers
• Monthly
• Lifetime – one-time purchase, no subscription

Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple ID settings. Any unused portion of a free trial is forfeited when you purchase a subscription.

Terms of Use: {TERMS}
Privacy Policy: {PRIV}

Grüezi and welcome – let’s get started!""",
)
de = dict(
 name="Schweizerdeutsch lernen",
 subtitle="Schwiizerdüütsch: Dialekt-Kurs",
 promo="Lerne Schweizerdeutsch in 5 Minuten am Tag. Kapitel 1–2 sind gratis: Audio, Alltagssätze, Dialekt-Explorer und das Quiz «Wie schweizerisch bist du?»",
 keywords="Züri,Bern,Basel,Sprache,Vokabeln,Wörter,Expats,Schweiz,Sprachkurs,Alltag,Sätze,Quiz,Anfänger",
 description=f"""Schweizerdeutsch lernen – spielerisch, in nur 5 Minuten am Tag.

Du ziehst nach Zürich? Dein Partner oder deine Partnerin ist Schweizer:in? Neuer Job in der Schweiz? Oder du willst einfach wissen, was «Grüezi», «Znüni» und «Merci vilmal» bedeuten? Schwiizerdüütsch bringt dir das Schweizerdeutsch bei, das du im Alltag wirklich hörst – auf der Strasse, im Tram und im Büro.

★ KURZE LEKTIONEN, DIE SÜCHTIG MACHEN
Kleine Lektionen mit Hören, Übersetzen, Paare finden und Sätze bauen. Sammle XP, halte deine Serie am Leben und erreiche dein Tagesziel.

★ 15 KAPITEL · 180+ ALLTAGSSÄTZE
Begrüssung, Vorstellen, Zahlen, Restaurant, Einkaufen, ÖV, Smalltalk, Arbeit, Gesundheit & Notfall, Feste, Slang, Familie und Berge – genau die Sätze, die du brauchst.

★ HÖREN UND NACHSPRECHEN
Audio zu jedem Ausdruck, in normalem und langsamem Tempo. (Die Aussprache wird mit der Systemstimme deines Geräts angenähert und dient als Lernhilfe.)

★ DIALEKT-EXPLORER
Zürich, Bern oder Basel? Vergleiche, wie dasselbe Wort in verschiedenen Regionen klingt.

★ QUIZ «WIE SCHWEIZERISCH BIST DU?»
Teste deine Swissness und teile dein Resultat mit Freunden.

★ KULTUR-TIPPS & SMARTE WIEDERHOLUNG
Zu jedem Ausdruck gibt es einen Tipp, und die smarte Wiederholung holt genau das zurück, was dir schwerfällt. Mit täglicher Erinnerung verlierst du deine Serie nie.

★ PRIVATSPHÄRE ZUERST
Kein Konto, keine Werbung, kein Tracking. Dein Fortschritt bleibt auf deinem Gerät.

GRATIS & PREMIUM
Die Kapitel 1 und 2 sind für immer gratis. Mit Schwiizerdüütsch Premium schaltest du alle Kapitel, den Dialekt-Explorer und die smarte Wiederholung frei:
• Jahresabo – mit 7 Tagen gratis testen für neue Abonnent:innen
• Monatsabo
• Lifetime – einmaliger Kauf, kein Abo

Die Zahlung wird bei Kaufbestätigung deiner Apple-ID belastet. Abos verlängern sich automatisch, sofern sie nicht mindestens 24 Stunden vor Ablauf der aktuellen Laufzeit gekündigt werden. Verwalten und kündigen kannst du jederzeit in den Apple-ID-Einstellungen. Ein ungenutzter Teil der Testphase verfällt, sobald du ein Abo abschliesst.

Nutzungsbedingungen: {TERMS}
Datenschutz: {PRIV}

Grüezi und willkommen – los geht’s!""",
)
limits=dict(name=30,subtitle=30,promo=170,keywords=100,description=4000)
for L,d in (("en",en),("de",de)):
    for k,m in limits.items():
        n=len(d[k]); print(L,k,n,"OK" if n<=m else "TOO LONG")
json.dump(dict(en=en,de=de,support=SUP,marketing=MARK,privacy=PRIV,terms=TERMS,copyright="2026 Connexa GmbH"),open("metadata.json","w"),ensure_ascii=False,indent=1)
