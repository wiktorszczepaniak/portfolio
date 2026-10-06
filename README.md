# Portfolio Wiktora Szczepaniaka

Gotowa statyczna strona na GitHub Pages. Bez instalowania pakietów, frameworka, kompilacji i kluczy API.

## Publikacja

1. Rozpakuj ZIP.
2. Wgraj **zawartość** rozpakowanego folderu do repozytorium. `index.html`, `styles.css`, `app.js` i folder `assets` muszą być na głównym poziomie repozytorium. Nie wgrywaj samego ZIP-a.
3. Otwórz **Settings → Pages**.
4. W **Build and deployment → Source** wybierz **Deploy from a branch**.
5. Wybierz gałąź **main**, folder **/(root)** i kliknij **Save**.
6. Adres gotowej strony pojawi się w ustawieniach Pages po zakończeniu publikacji.

Instrukcja GitHuba: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site

Jeśli aktualizujesz istniejące portfolio, zastąp wszystkie pliki plikami z tej paczki — w tym cały folder `assets`, nie tylko `index.html`. Po publikacji odśwież stronę z pominięciem pamięci podręcznej (Ctrl+Shift+R / Cmd+Shift+R). Wszystkie adresy zasobów są względne, więc strona działa zarówno pod `nazwa.github.io`, jak i `nazwa.github.io/repozytorium/`. Paczka nie wymusza własnej domeny.

Najwygodniej wgrać całość przez GitHub Desktop. Przy wgrywaniu przez przeglądarkę dodaj najpierw pliki z głównego folderu, a następnie osobno każdy podfolder `assets` (slajdy, filmy, podglądy itd.). Plik `.nojekyll` może być ukryty przez system operacyjny; jest dołączony do ZIP-a.

## Podgląd na komputerze

Otwórz `index.html` w przeglądarce. Można też uruchomić w tym folderze `python -m http.server 8000` i wejść na http://localhost:8000.

## Zawartość i obsługa

- Wszystkie 26 slajdów, ich kolejność, teksty i kompozycje z dostarczonego PPTX.
- Plansze WebP 2880 × 1620 z oryginalnych slajdów oraz zapasowe pliki JPEG. Taka konstrukcja utrzymuje położenie i wygląd elementów niezależnie od systemu i fontów w przeglądarce. Tekst na planszach jest częścią obrazu; kopia tekstowa jest dostępna dla technologii asystujących i po wejściu klawiaturą w „Tekst slajdu”.
- Linki z prezentacji działają w swoich oryginalnych miejscach. Zewnętrzne witryny mogą wymagać logowania; dostępność samych publikacji zależy od ich właścicieli.
- Wszystkie 22 filmy mają własne pliki MP4 H.264/AAC, obraz podglądu i natywne sterowanie. Dźwięk jest zachowany, jeśli występował w oryginale. Startują po kliknięciu, nie pobierają się automatycznie i zatrzymują się po przewinięciu poza ekran.
- Pasek nawigacji, wybór slajdu, skok do kontaktu, powiększenie do 400%, klawisze ← / → / Page Up / Page Down / Home / End. Escape zamyka powiększenie.
- Dyskretne, jednorazowe pojawianie się slajdów. Preferencja systemowa „ogranicz ruch” wyłącza animacje i płynne przewijanie.
- Telefon zachowuje układ 16:9. Do czytania drobnego tekstu użyj przycisku **Powiększ**, gestu powiększania przeglądarki lub obróć telefon poziomo.

## Edycja

`styles.css` steruje nawigacją i efektami. `app.js` odpowiada za interakcje. `index.html` zawiera strukturę, linki i położenie filmów. `assets/slides` zawiera plansze, `assets/video` filmy, a `assets/posters` ich podglądy. `assets/comments` zawiera komentarze w naturalnych proporcjach, a `assets/decorations` ozdobne elementy zachowujące oryginalną kolejność nakładania. `assets/content.json` przechowuje teksty i współrzędne źródłowe jako materiał pomocniczy; strona nie pobiera go podczas działania.

Zmiany treści lub układu slajdów wykonuj w źródłowej prezentacji i ponownie eksportuj odpowiednie plansze. Zmiana samego `content.json` nie aktualizuje obrazów ani HTML. Oryginalny PPTX nie jest dołączony, aby nie powielać dużego pliku w repozytorium.

Brak analityki, cookies, zewnętrznych fontów i zależności CDN. Materiały portfolio pozostają własnością odpowiednich właścicieli.
