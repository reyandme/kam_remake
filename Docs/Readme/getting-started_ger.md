**Präsentiert von Krom, Lewin and Rey**

---

[Systemanforderungen](#-systemanforderungen) · [Installation](#-installation) · [Gameplay](#-gameplay) · [Häufig gestellte Fragen](#-häufig-gestellte-fragen) · [Community und feedback](#-community-und-feedback) · [Bekannte Fehler](#-bekannte-fehler-und-einschränkungen) · [Quelltext](#-quelltext) · [Credits](#-credits) · [Impressum](#-impressum)

---

### 🌳 Systemanforderungen

- Microsoft Windows oder Linux mit Wine;
- jeder Dual-Core-Prozessor;
- 512MB oder mehr RAM;
- 3D Grafikkarte OpenGL 1.5 fähig

### 🗡️ Installation

1. Besitze das originale Spiel (Knights and Merchants: The Peasants Rebellion):
	- Installer von der originalen CD und GOG.com sollten einfach funktionieren.
	- Falls du TPR von Steam erworben hast, musst du TPR mindestens ein mal ausgeführt haben, ansonsten kann es der Installer des Remakes nicht finden.
	- Falls du Linux verwendest, siehe <https://github.com/reyandme/kam_remake/wiki/Game-installation-on-Linux>
1. Führe den Remake Installer aus und folge den Anweisungen.
    - In case it shows error "Setup hat ermittelt, dass Knights and Merchants: The Peasants Rebellion nicht installiert ist.", but you already installed TPR long time ago, try installing TPR again, as it is possible it got corrupted over time.
    - In case the installer window is not shown at all: right click "KaM Remake installer.exe" -> tab General -> Security: set [v] Unblock
1. Das KaM Remake verwendet OpenGL für die Grafiken. Falls es visuelle Probleme gibt oder das Spiel nicht gestartet werden kann, besuche die Webseite deiner Grafikkarte und hole dir den aktuellsten Treiber.
1. Launch the mod - KaM_Remake.exe or from the Desktop/Start Menu if you chose to create shortcuts.

### 🪓 Gameplay

#### Mehrspieler
Um ein Spiel zu starten, klicke auf Multiplayerspielt. Dort kannst du einen beliebigen unbenutzten Server auswählen, falls du eine neue Lobby erstellen willst, oder du kannst einer bestehenden Lobby beitreten.

Du kannst auch einen lokalen (LAN) server erstellen, über den "Erstelle Server" Knopf.

Falls du einen dedizierten Server für die Community erstellen möchtest, siehe hier für Details: <https://github.com/reyandme/kam_remake/blob/master/Docs/Readme/technical.md>

#### Tastenkürzel
**Folgende Tastenkürzel sind verfügbar:**

- **Esc** schließt eine offene Nachricht oder Auswahl
- **F1-F4** öffnet die jeweilige Auswahl im Spielmenü
- **F5-F8** erhöht die Spielgeschwindigkeit um x1 / x3 / x6 / x10 (speedup multiplier can be changed in game's XML settings file)
- **F11** zeigt Menü und Debugging Panel an
- **0-9** wählt Einheiten oder Häuser aus, die den Tastenkombinationen Strg + 0-9 zugewiesen wurden
- **B** platziert eine Markierung auf der Karte, die von Verbündeten gesehen werden kann
- **Spacebar** bewegt das Sichtfeld zum Ort der letzten Nachricht
- **P** pausiert das Spiel
- Holding the **T** button in multiplayer mode, will show player nicknames over their units
- **Enf** löscht die angezeigte Nachricht
- **←↑→↓** Pfeiltasten bewegen das Sichtfeld
- Drehen des **Mausrads** zoomt heran und heraus
- **Backspace ←** setzt den Zoom auf 100% zurück

Für mehr detailiertere Informationen über Tastenkürzel, bitte besuche unsere Wiki-Seite:
<https://github.com/reyandme/kam_remake/wiki/Controls>

#### Installieren von Zusatzkarten:
Karten sollten (im Remake-Verzeichnis) zu Maps/ (für Einzelspieler), MapsMP/ (für Mehrspieler); ebenso gibt es einen Ordner für Kampagnen.

Man kann weitere von der Community erstellen Karten unter <https://knights-tavern.com> finden.

#### Hinzufügen benutzerdefinierter Musik:
Du kannst deine MP3/OGG-Dateien in den Musikordner des des KaM Remake-Verzeichnisses legen und sie werden automatisch in die Wiedergabe aufgenommen.

# 🛡️ Häufig gestellte Fragen
**Abstürze ohne Benachrichtigung:**  
Wenn das KaM Remake ohne Meldung während des Startens abstürzt, sendet uns bitte die Log-Datei auf unserem Discord-Kanal, sowie alle anderen Informationen, die ihr finden könnt und uns nützlich sein könnten.

**Niedrige Framerate:**  
Falls das Programm eine niedrige Framerate hat, könnte es sein, dass die OpenGL-Treiber nicht mehr aktuell sind. Ihr könnt die OpenGL-Version in der Ecke links oben im Hauptmenü sehen. Es sollte mindestens Version 1.5.x sein.  

**Fehler im Spiel:**  
Manchmal, wenn etwas unerwartetes passiert, bekommt man eine "Ein Fehler ist in der Applikation passiert" Nachricht. Bitte klick den "Send Bug Report" Knopf, damit der Please click the "Send Bug Report" button, um uns den Absturzbericht zu senden, was uns darauf aufmerksam macht und ermöglicht den Fehler zu beheben. Gib gerne deinen Namen und E-Mail an, falls du möchtest, dass wir dich kontaktieren können bezüglich des Absturzes.

**Irgendetwas anderes:**  
Siehe diesen Link: <https://www.kamremake.com/faq/>

## 🏰 Community und Feedback

Trete unserer Community bei <https://discord.gg/UkkYceR>. Wir freuen uns über Kommentare, Anregungen, Danksagungen, etc.
Wenn ihr etwas Hilfe in Sachen Delphi, Dokumentation, Spielgrafik, Geräusche, Übersetzung oder Ideen für Verbesserungen habt - sende uns bitte eine E-Mail oder schreibe im Discord. Lesen Sie auch <https://github.com/reyandme/kam_remake/wiki/Contributions>.

# ⛏️ Bekannte Fehler und Einschränkungen

Kriegswerkstatt ist nicht funktionsfähig.  

# 🏹 Quelltext

Der KaM Remake-Quelltext ist auf unserer Projektseite verfügbar:  
<https://github.com/reyandme/kam_remake>  
Hier kann man unsere Spiel-Wiki finden:
<https://github.com/reyandme/kam_remake/wiki>  
Hier könnt ihr uns Fehler berichten:  
<https://github.com/reyandme/kam_remake/issues>  
oder auf unserem Discord-Kanal.

# 📖 Credits

Leitender Programmierer  - Krom (<mailto:kromster80@gmail.com>)  
Programmierer - Rey (<mailto:kamremake.rey@gmail.com>)  
Programmierer - Lewin (<mailto:lewinjh@gmail.com>)  
Programmierer - Toxic (Fortgeschrittene KI und Zufallskarten-Generator)
und viele mehr...  
 
Danke an Alex, der uns 2008 in das Core Design eingewiesen hat.  
Danke an StarGazer, der neue Grafiken erstellt hat, auch an Malin welcher Marktplatz-Waren malte.
Großen Dank an die KaM Community und an ihre aktiven Mitglieder (Free_sms_kam, Harold, Humbelum, JBSnorro, The Knight, Litude (Real Hotdog), Merchator, Nick, Thunderwolf, Vas, andreus, ZblCoder und viele mehr) dafür dass sie uns beim Decodieren halfen, uns Ratschläge gaben und für ihr Engagement.  
Icons von famfamfam und FatCow wurden im KaM Remake benutzt.

# ⚔️ Impressum

Kommerzieller Gebrauch ist verboten.  
Alle benutzten Namen, Symbole oder andere, mit einem Copyright versehene, Materialien sind Eigentum des jeweiligen Besitzers.  
Wir nehmen keine Verantwortung für mögliche Hardwareschäden.  
Weitergabe oder Ähnliches dieser Modifikation ist ohne diese beiliegende Read-Me nicht erlaubt.  
Ihr könnt das Remake auf euren Server hochladen und veröffentlichen, aber bitte lasst es uns wissen.  
Wir gehen davon aus, dass ihr eine eigene lizensierte Kopie des Spiels Knights and Merchants habt, andernfalls solltet ihr das Spiel kaufen bevor ihr diese Modifikation benutzt. Andernfalls verstoßen Sie gegen die Lizenzvereinbarung.  
