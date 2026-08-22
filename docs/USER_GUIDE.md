# Desk Test - Nutzerhandbuch

> **Version:** 1.0  
> **Stand:** Juni 2026  
> **Status:** Pilotbetrieb  
> **Zielgruppe:** Pilotnutzer der Philipps-Universität Marburg

## Einführung

Willkommen bei **Desk Test** (desk-test.uni-marburg.de) - Ihrem digitalen souveränen Arbeitsplatz!

Desk Test bietet eine integrierte Umgebung für Produktivität, Kollaboration und Kommunikation. Alle Daten bleiben on-premises im HRZ und unterliegen den Datenschutzbestimmungen der Philipps-Universität Marburg.

---

## Voraussetzungen

Um Desk Test zu nutzen, benötigen Sie:

1. **Uni-Account** der Philipps-Universität Marburg (wie für next.hessenbox)
2. **Internetverbindung**
3. **Moderner Browser**: Chrome, Firefox, Edge oder Safari
4. **Zugangsberechtigung**: Sie müssen als Pilotnutzer freigeschaltet sein

---

## Zugang erhalten

### Schritt 1: Freischaltung beantragen

Der Zugang zu Desk Test ist aktuell auf Pilotnutzer beschränkt. Um freigeschaltet zu werden:

1. Wenden Sie sich an Ihr **Dezernat oder Ihre Einrichtung**
2. Oder kontaktieren Sie direkt das **Projektteam**:
   - E-Mail: helpdesk@hrz.uni-marburg.de
   - Matrix-Chat: `#desk-test:matrix.hrz.uni-marburg.de`

### Schritt 2: Willkommens-E-Mail

Nach der Freischaltung erhalten Sie eine E-Mail mit:
- Ihrem Benutzernamen
- Informationen zum ersten Login
- Links zu Schulungsmaterialien

### Schritt 3: Erstes Login

1. Besuchen Sie: **https://desk-test.uni-marburg.de**
2. Klicken Sie auf "Anmelden"
3. Wählen Sie "Login mit Uni-Account" (Shibboleth)
4. Melanie Sie sich mit Ihrem Uni-Account an
5. Akzeptieren Sie ggf. die Nutzungsbedingungen

---

## Portal - Ihr zentraler Zugang

Nach dem Login landen Sie im **Portal** - der zentralen Oberflächer von Desk Test.

### Portal-Übersicht

| Tile | Beschreibung | Link |
|------|--------------|------|
| **openCloud** | Dateiablage (50 GB Speicher) | https://cloud.desk-test.uni-marburg.de |
| **Mail** | E-Mail (SOGo Groupware) | https://mail.desk-test.uni-marburg.de |
| **Kalender** | Termine und Kalender | https://mail.desk-test.uni-marburg.de/calendar |
| **Kontakte** | Adressbuch | https://mail.desk-test.uni-marburg.de/contacts |
| **Chat** | Messenger (Element/Matrix) | https://chat.desk-test.uni-marburg.de |
| **Pad** | Kollaboratives Editieren | https://pad.desk-test.uni-marburg.de |
| **BBB** | Videokonferenzen | https://bbb.desk-test.uni-marburg.de |

### Portal-Funktionen

- **Suchfunktion**: Suche über alle Dienste
- **Benachrichtigungen**: Zentrale Anzeige von Nachrichten
- **Profil**: Ihre Benutzerdaten verwalten
- **Einstellungen**: Portal-Einstellungen anpassen

---

## Dienste im Detail

### 📁 openCloud - Dateiablage

**Zugang:** https://cloud.desk-test.uni-marburg.de

 openCloud ist Ihre zentrale Dateiablage mit 50 GB Speicherplatz.

#### Grundfunktionen

- **Dateien hochladen**: Ziehen Sie Dateien per Drag & Drop in den Browser
- **Ordner erstellen**: Klicken Sie auf "Neuer Ordner"
- **Dateien bearbeiten**: Online-Editor für Text, Tabellen, Präsentationen
- **Dateien teilen**: Mit anderen Nutzern oder über öffentliche Links

#### Dateien teilen

1. Navigieren Sie zur Datei/Ordner
2. Klicken Sie auf die drei Punkte (⋮) neben der Datei
3. Wählen Sie "Teilen"
4. Wählen Sie einen Nutzer oder erstellen Sie einen öffentlichen Link
5. Optional: Setzen Sie Berechtigungen (Lesen/Bearbeiten)

#### Desktop- und Mobile-Apps

- **Desktop**: [Nextcloud Client](https://nextcloud.com/install/#install-clients) (Windows, macOS, Linux)
- **Mobile**: Nextcloud App (iOS, Android)

**Server-Adresse:** `https://cloud.desk-test.uni-marburg.de`

#### Synchronisation einrichten

1. Installieren Sie den Nextcloud Client
2. Öffnen Sie den Client und klicken Sie auf "Hinzufügen"
3. Geben Sie die Server-Adresse ein: `https://cloud.desk-test.uni-marburg.de`
4. Melden Sie sich mit Ihrem Uni-Account an
5. Wählen Sie die zu synchronisierenden Ordner aus

---

### 📧 Mail - E-Mail (SOGo Groupware)

**Zugang:** https://mail.desk-test.uni-marburg.de

SOGo bietet E-Mail, Kalender und Kontakte in einer integrierten Oberfläche.

#### E-Mail

- **E-Mails schreiben**: Klicken Sie auf "Neu"
- **Anhänge**: Fügen Sie Dateien bis 25 MB hinzu
- **Ordner**: Organisieren Sie Ihre E-Mails in Ordnern
- **Filter**: Automatische Regel für eingehende E-Mails

**E-Mail-Adresse:** `vorname.nachname@desk-test.uni-marburg.de`

#### Server-Einstellungen für E-Mail-Clients

| Protokoll | Server | Port | Verschlüsselung |
|-----------|--------|------|----------------|
| IMAP | mail.desk-test.uni-marburg.de | 993 | SSL/TLS |
| SMTP | mail.desk-test.uni-marburg.de | 587 | STARTTLS |
| POP3 | mail.desk-test.uni-marburg.de | 995 | SSL/TLS |

**Benutzername:** Ihr Uni-Account-Benutzername  
**Passwort:** Ihr Uni-Account-Passwort

#### Thunderbird einrichten

1. Öffnen Sie Thunderbird
2. Klicken Sie auf "Datei" → "Neu" → "Existierendes Mail-Konto..."
3. Geben Sie Ihren Namen, E-Mail-Adresse und Passwort ein
4. Thunderbird erkennt die Server automatisch
5. Klicken Sie auf "Fertig"

#### Outlook einrichten

1. Öffnen Sie Outlook
2. Klicken Sie auf "Datei" → "Konto hinzufügen"
3. Geben Sie Ihre E-Mail-Adresse ein
4. Wählen Sie "IMAP"
5. Geben Sie die Server-Einstellungen manuell ein (siehe Tabelle oben)

---

### 📅 Kalender

**Zugang:** https://mail.desk-test.uni-marburg.de/calendar

- **Termine erstellen**: Klicken Sie auf "Neuer Termin"
- **Wiederkehrende Termine**: Einstellen unter "Wiederholung"
- **Einladungen senden**: Fügen Sie Teilnehmer hinzu
- **Termine teilen**: Öffentliche oder private Kalender

#### Kalender in Clients einbinden

**CalDAV-URL:** `https://mail.desk-test.uni-marburg.de/SOGo/dav/vorname.nachname/Calendar/personal/`

**Thunderbird:**
1. Installieren Sie das Add-on "SOGo Connector"
2. Klicken Sie auf "Datei" → "Neu" → "Kalender"
3. Wählen Sie "Im Netzwerk" → "CalDAV"
4. Geben Sie die CalDAV-URL ein

---

### 👥 Kontakte

**Zugang:** https://mail.desk-test.uni-marburg.de/contacts

- **Kontakte anlegen**: Klicken Sie auf "Neuer Kontakt"
- **Kontaktgruppen**: Organisieren Sie Ihre Kontakte
- **Import/Export**: vCard-Format

#### Kontakte in Clients einbinden

**CardDAV-URL:** `https://mail.desk-test.uni-marburg.de/SOGo/dav/vorname.nachname/Contacts/personal/`

---

### 💬 Chat - Element/Matrix

**Zugang:** https://chat.desk-test.uni-marburg.de

Element/Matrix ist ein dezentraler Messenger für sichere Kommunikation.

#### Erste Schritte

1. Melden Sie sich mit Ihrem Uni-Account an
2. Ihr Benutzername: `@vorname.nachname:matrix.hrz.uni-marburg.de`
3. Erstellen Sie Räume oder treten Sie bestehenden bei

#### Räume

- **Erstellen**: Klicken Sie auf "+" → "Raum erstellen"
- **Einladen**: Fügen Sie Nutzer per Matrix-ID hinzu
- **Öffentliche Räume**: Durchsuchen Sie das Verzeichnis

#### Apps

- **Desktop**: [Element Desktop](https://element.io/get-started)
- **Mobile**: Element App (iOS, Android)

---

### 📝 Pad - Etherpad

**Zugang:** https://pad.desk-test.uni-marburg.de

Etherpad ermöglicht das Echtzeit-kollaborative Bearbeiten von Texten.

#### Funktionen

- **Pad erstellen**: Klicken Sie auf "Neues Pad"
- **Teilen**: Kopieren Sie den Pad-Link
- **Echtzeit-Bearbeitung**: Mehrere Nutzer können gleichzeitig editieren
- **Versionsgeschichte**: Sehen Sie, wer was geändert hat

---

### 🎥 BBB - BigBlueButton (Videokonferenzen)

**Zugang:** https://bbb.desk-test.uni-marburg.de

BigBlueButton ist eine Videokonferenzlösung für Online-Meetings, Webinare und Unterricht.

> **Hinweis:** BBB wird extern von **infra.run** betrieben. Die Integration in Desk Test erfolgt über Single Sign-On.

#### Meetings erstellen

1. Melden Sie sich bei BBB an
2. Klicken Sie auf "Neues Meeting"
3. Geben Sie einen Namen und optional eine Beschreibung ein
4. Wählen Sie die Einstellungen (Dauer, Teilnehmerlimit, etc.)
5. Klicken Sie auf "Meeting erstellen"

#### Meeting-Beitritt

- Sie erhalten einen Link zum Meeting
- Teilen Sie diesen Link mit den Teilnehmern
- Nutzer können via Browser beitreten (keine Installation nötig)

#### Funktionen

- **Video/Audio**: Kamera und Mikrofon freigeben
- **Präsentation**: Bildschirm teilen oder Dateien hochladen
- **Whiteboard**: Gemeinsam zeichnen und Notizen machen
- **Chat**: Textbasierte Kommunikation
- **Aufzeichnung**: Meetings können aufgezeichnet werden (mit Zustimmung)

---

## Mobile Nutzung

### Empfohlene Apps

| Dienst | App | Download |
|--------|-----|----------|
| openCloud | Nextcloud | [iOS](https://apps.apple.com/de/app/nextcloud/id1115815867) / [Android](https://play.google.com/store/apps/details?id=com.nextcloud.client) |
| Mail/Kalender/Kontakte | SOGo | - |
| Mail | Thunderbird | [iOS](https://apps.apple.com/de/app/thunderbird/id1542255237) / [Android](https://play.google.com/store/apps/details?id=org.mozilla.thunderbird) |
| Chat | Element | [iOS](https://apps.apple.com/de/app/element-messenger/id1010524423) / [Android](https://play.google.com/store/apps/details?id=im.vector.app) |

---

## Tipps und Tricks

### Dateien zwischen Diensten nutzen

Sie können Dateien aus openCloud einfach in andere Dienste einbinden:

1. **In Etherpad**: Laden Sie eine Datei hoch oder fügen Sie einen Link ein
2. **In E-Mails**: Fügen Sie Dateien als Anhang aus openCloud bei
3. **In BBB**: Lacey Sie eine Präsentation aus openCloud hoch

### Benachrichtigungen verwalten

- **E-Mail-Benachrichtigungen**: In SOGo unter "Einstellungen" → "Benachrichtigungen"
- **openCloud-Benachrichtigungen**: Klicken Sie auf Ihr Profilbild → "Benachrichtigungen"

### Passwort ändern

Ihr Passwort ist mit Ihrem Uni-Account verknüpft. Um es zu ändern:

1. Besuchen Sie: https://idm.uni-marburg.de
2. Melden Sie sich an
3. Navigieren Sie zu "Passwort ändern"

---

## Häufige Probleme

### Ich kann mich nicht anmelden

- **Lösung**: Stellen Sie sicher, dass Sie als Pilotnutzer freigeschaltet sind
- **Kontakt**: helpdesk@hrz.uni-marburg.de

### Ich sehe nicht alle Dienste

- **Lösung**: Sie haben möglicherweise nicht alle Berechtigungen. Kontaktieren Sie Ihr Dezernat.

### Dateien werden nicht synchronisiert

- **Lösung**: Überprüfen Sie Ihre Internetverbindung und Starten Sie den Nextcloud Client neu

### E-Mails werden nicht empfangen/gesendet

- **Lösung**: Überprüfen Sie Ihre Server-Einstellungen und Passwort

### Mein Passwort funktioniert nicht

- **Lösung**: Ändern Sie Ihr Uni-Account-Passwort unter https://idm.uni-marburg.de

---

## Support und Hilfe

### Selbsthilfe

- **Dokumentation**: https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/USER_GUIDE.md
- **Häufige Fragen**: Siehe Abschnitt "Häufige Probleme" oben

### Kontakt

| Problem | Kontakt |
|---------|---------|
| **Allgemeine Fragen** | helpdesk@hrz.uni-marburg.de |
| **Technische Probleme** | helpdesk@hrz.uni-marburg.de |
| **Nutzung** | Ihr Dezernat oder Einrichtung |
| **Matrix-Chat** | #desk-test:matrix.hrz.uni-marburg.de |

### Reaktionszeiten

- **P1 (Kritisch)**: <2 Stunden (24/7)
- **P2 (Dringend)**: <4 Stunden (Geschäftszeiten)
- **P3 (Standard)**: <2 Werktage

---

## Feedback

Wir freuen uns über Ihr Feedback zur Pilotumgebung! bitte teilen Sie uns mit:

- Was funktioniert gut?
- Was könnte verbessert werden?
- Welche Funktionen fehlen Ihnen?

**Feedback-Formular**: [ Link wird bereitgestellt ]

**E-Mail**: desk-test-feedback@hrz.uni-marburg.de

---

## Impressum und Datenschutz

### Betreiber

Philipps-Universität Marburg  
Hochschulrechenzentrum (HRZ)  
Biegenstraße 10  
35032 Marburg

### Datenschutz

- [Datenschutzerklärung der Uni Marburg](https://www.uni-marburg.de/de/grundordnung/datenschutz)
- Alle Daten bleiben on-premises im HRZ
- Keine Weitergabe an Dritte

### Nutzungsbedingungen

- [IT-Nutzungsordnung der Uni Marburg](https://www.uni-marburg.de/de/hrz/ueber-uns/it-management/it-nutzungsordnung)
- Spezifische Bedingungen für die Testumgebung siehe Anmeldung

---

*Dieses Handbuch wird regelmäßig aktualisiert. Letzte Änderung: Juni 2026*
