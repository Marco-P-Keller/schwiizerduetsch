# In-App-Käufe – Setup in App Store Connect

Die Produkt-IDs sind im Code fest verdrahtet (`PurchaseManager.swift`) und in `Products.storekit` für lokale Tests hinterlegt.

## Status: alle drei Produkte sind in App Store Connect angelegt (Preise, Texte DE/EN, Review-Screenshot). Basispreis der Abos: Schweiz/CHF.

## Abo-Gruppe «Premium» (ID 22428993)

| Referenzname | Produkt-ID | Dauer | Preis (USD, Basis) | Einführungsangebot |
|---|---|---|---|---|
| Premium Yearly | `com.connexa.schweizerdeutsch.premium.yearly` | 1 Jahr | CHF 24.90 (≈ 29.99 $ / 34.99 €) | Gratis-Testphase 1 Woche (neue Abonnent:innen) |
| Premium Monthly | `com.connexa.schweizerdeutsch.premium.monthly` | 1 Monat | CHF 5.90 (≈ 6.99 $ / 7.99 €) | – |

Reihenfolge in der Gruppe: Yearly (Stufe 1), Monthly (Stufe 2). Family Sharing: bewusst NICHT aktiviert (nicht rückgängig zu machen, würde Verkäufe pro Familie teilen).

Lokalisierungen (Abo-Gruppe + Produkte):
- **de:** Gruppe «Schwiizerdüütsch Premium» · Jahr: «Premium Jahr» / «Alle Kapitel, Dialekt-Explorer und smarte Wiederholung.» · Monat: «Premium Monat» / gleiche Beschreibung.
- **en-US:** Group «Schwiizerdüütsch Premium» · «Premium Yearly» / «All chapters, dialect explorer and smart review.» · «Premium Monthly» / same description.

## Nicht-verbrauchbarer In-App-Kauf

| Referenzname | Produkt-ID | Preis (USD) |
|---|---|---|
| Premium Lifetime | `com.connexa.schweizerdeutsch.premium.lifetime` | 49.99 |

- de: «Premium Lifetime» / «Einmal zahlen, für immer alle Kapitel und Funktionen.»
- en-US: «Premium Lifetime» / «Pay once, unlock every chapter and feature forever.»
- Family Sharing: nicht aktiviert.

## Review-Screenshot (für alle drei Produkte)
`Store/screens/review/paywall_de.png` bzw. `paywall_en.png` (1284×2778).

## Hinweis
Der erste In-App-Kauf / das erste Abo muss zusammen mit einer App-Version zur Prüfung eingereicht werden.
