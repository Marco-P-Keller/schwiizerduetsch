# In-App-Käufe – Setup in App Store Connect

Die Produkt-IDs sind im Code fest verdrahtet (`PurchaseManager.swift`) und in `Products.storekit` für lokale Tests hinterlegt.

## Abo-Gruppe «Premium» (bereits angelegt, ID 22428993)

| Referenzname | Produkt-ID | Dauer | Preis (USD, Basis) | Einführungsangebot |
|---|---|---|---|---|
| Premium Yearly | `com.connexa.schweizerdeutsch.premium.yearly` | 1 Jahr | 29.99 | Gratis-Testphase 1 Woche (neue Abonnent:innen) |
| Premium Monthly | `com.connexa.schweizerdeutsch.premium.monthly` | 1 Monat | 6.99 | – |

Reihenfolge in der Gruppe: Yearly (Stufe 1), Monthly (Stufe 2). Family Sharing: aktivieren.

Lokalisierungen (Abo-Gruppe + Produkte):
- **de:** Gruppe «Schwiizerdüütsch Premium» · Jahr: «Premium Jahr» / «Alle Kapitel, Dialekt-Explorer und smarte Wiederholung.» · Monat: «Premium Monat» / gleiche Beschreibung.
- **en-US:** Group «Schwiizerdüütsch Premium» · «Premium Yearly» / «All chapters, dialect explorer and smart review.» · «Premium Monthly» / same description.

## Nicht-verbrauchbarer In-App-Kauf

| Referenzname | Produkt-ID | Preis (USD) |
|---|---|---|
| Premium Lifetime | `com.connexa.schweizerdeutsch.premium.lifetime` | 59.99 |

- de: «Premium Lifetime» / «Einmal zahlen, für immer alle Kapitel und Funktionen.»
- en-US: «Premium Lifetime» / «Pay once, unlock every chapter and feature forever.»
- Family Sharing: aktivieren.

## Review-Screenshot (für alle drei Produkte)
`Store/screens/review/paywall_de.png` bzw. `paywall_en.png` (1284×2778).

## Hinweis
Der erste In-App-Kauf / das erste Abo muss zusammen mit einer App-Version zur Prüfung eingereicht werden.
