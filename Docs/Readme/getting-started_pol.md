**Dla was od: Krom, Lewin, Rey**

---

[Wymagania sprzętowe](#-wymagania-sprzętowe) · [Instalacja](#-instalacja) · [Rozgrywka](#-rozgrywka) · [F.A.Q.](#-najczęściej-zadawane-pytania) · [Społeczność i twoja opinia](#-społeczność-i-twoja-opinia) · [Znane problemy](#-znane-problemy) · [Kod źródłowy](#-kod-źródłowy) · [Twórcy](#-twórcy) · [Nota prawna](#-nota-prawna)

---

### 🌳 Wymagania sprzętowe

- Microsoft Windows lub Linux z Wine;
- dowolny procesor dwurdzeniowy;
- 512MB lub więcej pamięci RAM;
- karta graficzna zgodna z OpenGL 1.5

### 🗡️ Instalacja

1. Zdobądź oryginalną grę (Knights and Merchants: The Peasants Rebellion):
	- Instalatory z oryginalnych płyt CD oraz GOG.com działają bez dodatkowych kroków.
	- Jeśli twoja kopia TPR została kupiona w sklepie Steam, musisz uruchomić TPR przynajmniej jeden raz - inaczej instalator Remake nie będzie w stanie wykryć gry.
	- Jeśli używasz Linuksa, zobacz: <https://github.com/reyandme/kam_remake/wiki/Game-installation-on-Linux>
1. Uruchom instalator Remake i podążaj za krokami.
    - W przypadku błędu "Kreator instalacji wykrył że nie masz zainstalowanego Knights and Merchants: The Peasants Rebellion.", mimo tego że dawno temu instalowałeś/aś TPR, spróbuj zainstalować TPR ponownie, ponieważ istnieje duża możliwość, że instalacja z czasem została uszkodzona.
    - Jeśli okno instalatora w ogóle się nie pojawiło: kliknij prawym przyciskiem na "KaM Remake installer.exe" -> karta General -> Zabezpieczenia: zaznacz [v] Odblokuj
1. KaM Remake używa OpenGL do renderowania grafiki. Jeśli masz problemy wizualne lub gra się nie włącza, odwiedź stronę internetową dostawcy twojej karty graficznej i zainstaluj do niej najnowsze sterowniki.
1. Uruchom moda - KaM_Remake.exe lub klikając na skrót na Pulpicie lub w Menu Start (jeśli zaznaczyłeś opcję tworzenia skrótów).

### 🪓 Rozgrywka

#### Gra wieloosobowa
Aby rozpocząć rozgrywkę, kliknij na "Gra w sieci". Możesz wybrac dowolny nieużywany serwer, jeśli chcesz założyć nową poczekalnię ("lobby"), lub możesz dołączyć do już istniejącej.

Możesz również utworzyć własny serwer lokalny (LAN), używając przycisku "Utwórz serwer".

Jeśli chcesz utworzyć nowy serwer dedykowany dla naszej społeczności, szczegóły tutaj: <https://github.com/reyandme/kam_remake/blob/master/Docs/Readme/technical.md>

#### Skróty klawiaturowe
**Możesz uzywać następujących skrótów klawiszowych w grze:**

- **Esc** zamyka otwartą wiadomość, lub kartę w menu gry
- **F1-F4** otwiera odpowiednią kartę menu (buduj/podział/statystyki/opcje) w trakcie gry
- **F5-F8** ustawia prędkość gry na x1 / x3 / x6 / x10 (mnożnik prędkości może być zmieniony w pliku XML z ustawieniami gry)
- **F11** pokazuje panel i menu z opcjami dla programistów
- **0-9** zaznacza jednostki lub budynki, przypisane przez gracza przy użyciu kombinacji klawiszy Ctrl + 0-9
- **B** umieści na mapie sygnał, który zobaczą i usłyszą twoi sojusznicy
- **Spacja** przenosi widok do ostatniego sygnału/wiadomości
- **P** pauzuje grę
- Przytrzymanie klawisza **T** w grze wieloosobowej, pokaże pseudonimy graczy nad ich jednostkami
- **Delete** usuwa otwartą wiadomość w grze
- Klawisze strzałek **←↑→↓** przesuwają widok po mapie
- Przewijając **kółko myszy** przybliżysz lub oddalisz widok
- **Backspace ←** przywróci przybliżenie do 100%

Więcej szczegółów o skrótach klawiszowych znajdziesz na naszej stronie Wiki:  
<https://github.com/reyandme/kam_remake/wiki/Controls>

#### Instalacja dodatkowych map:
Mapy powinny być dodawane (w folderze z Remake) do katalogu Maps (dla gry jednoosobowej), MapsMP (dla gry wieloosobowej); jest również katalog dla kampanii - Campaigns.

Dodatkowe mapy możesz znaleźć na stronie <https://knights-tavern.com>.

#### Dodawanie własnej muzyki:
Możesz wrzucić własne pliki MP3/OGG do folderu Music w katalogu z KaM Remake, i zostaną one automatycznie dodane do listy piosenek.

# 🛡️ Najczęściej zadawane pytania
**Ciche awarie:**  
Jeśli KaM Remake doznał awarii i sie wyłączył, wyślij plik z logami na nasz kanał Discord, razem ze wszystkimi informacjami, które moga pomóc w zrozumieniu problemu.

**Mała ilość klatek:**  
Jeśli masz małą ilośc klatek na sekundę (FPS), być może twoje sterowniki OpenGL są za stare. Informacja w głównym menu gry, w lewym górnym rogu, powinna mówić że twój komputer obsługuje przynajmniej OpenGL 1.5.x. W przeciwnym wypadku zaktualizuj swoje sterowniki karty graficznej (ze strony jej producenta).

**Błędy gry:**  
Czasami, gdy coś nieprzewidzianego się wydarzy, zobaczysz błąd "An error has occurred in the application" (wydarzył się błąd w aplikacji). Prosimy o kliknięcie przycisku Send Bug Report (wyślij raport błędu), aby wysłać do nas raport, który umożliwi zauważenie i rozwiązanie błędu. Wpisz swój pseudonim i email, jeśli chcesz byśmy byli w stanie się z tobą skontaktować.

**Wszystko inne:**  
Zobacz <https://www.kamremake.com/faq/>

## 🏰 Społeczność i twoja opinia

Dołącz do naszej społeczności na <https://discord.gg/UkkYceR>. Chcemy usłyszeć twoje komentarze, sugestie, podziękowania, itd.  
Zawsze szukamy osób chętnych pomóc nam z programowaniem (Delphi), dokumentacją, grafikami gry, dźwiękami, tłumaczeniem lub pomysłami na ulepszenia - wyślij nam maila lub napisz na Discordzie. Sprawdź również <https://github.com/reyandme/kam_remake/wiki/Contributions>. 

# ⛏️ Znane problemy

Warsztat wojenny nie działa.

# 🏹 Kod źródłowy

Kod źródłowy KaM Remake jest dostępny na stronie naszego projektu:  
<https://github.com/reyandme/kam_remake>  
Wiki projektu:  
<https://github.com/reyandme/kam_remake/wiki>  
Możesz informowac nas o problemach tutaj:  
<https://github.com/reyandme/kam_remake/issues>  
lub na kanale Discord.

# 📖 Twórcy

Główny programista - Krom (<mailto:kromster80@gmail.com>)  
Programista - Rey (<mailto:kamremake.rey@gmail.com>)  
Programista - Lewin (<mailto:lewinjh@gmail.com>)  
Programista - Toxic (Lepsza SI i generator map losowych)  
i wielu innych...  

Podziękowania dla Alex'a który opracował początkowy model projektu już w 2008  
Podziękowania dla StarGazer, który sporządził nowe kursory i ikony dla interfejsu użytkownika, równiez dla Malin, który narysował surowce dla targu.  
Ogromne podziękowanie dla społeczności KaM i jej aktywnych członków (Free_sms_kam, Harold, JBSnorro, The Knight, Litude (Real Hotdog), Merchator, Nick, Thunderwolf, Humbelum, Vas, andreus, ZblCoder and many others) którzy pomagali nam w dekodowaniu, dawali porady, pomysły i zachęcali nas do działania.  
Ikony z famfamfam oraz FatCow są używane w KaM Remake.  

# ⚔️ Nota prawna

Komercyjne użycie jest surowo zabronione.  
Wszelkie użyte nazwy, symbole i inne materiały chronione prawem autorskim są własnością poszczególnych właścicieli.  
Nie bierzemy żadnej odpowiedzialności, jeśli ten mod uszkodzi twoje oprogramowanie lub sprzęt.  
Z oczywistych względów publikowanie i/lub udostępnianie tego moda w jakiejkolwiek formie nie jest dozwolone bez tego pliku Readme.  
Możesz zamieścić tego moda na stronie/serwerze/serwisie, ale prosimy abyś nas wcześniej o tym powiadomił.  
Zakładamy że posiadasz własna licencjonowaną kopię gry KaM, w przeciwnym razie powinieneś kupić grę przed użyciem tego moda. W przeciwnym razie będzie to naruszeniem umowy licencyjnej.  
