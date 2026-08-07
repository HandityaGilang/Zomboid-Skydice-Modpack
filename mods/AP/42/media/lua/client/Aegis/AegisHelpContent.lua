-- Help and changelog texts for the in game help window (AegisHelp.lua).
-- Long prose lives here instead of the translation JSONs: full articles
-- in 13 languages are not maintainable, so DE and EN carry the content
-- and every other game language falls back to EN. Each help section is
-- { title, lines = { ... } }, each changelog entry { version, date,
-- points = { ... } }. Newest changelog first.
-- NOTE: the engine reads Lua sources as ASCII, run the escape script
-- over this file after editing German text (umlauts become \ddd).

AegisHelpContent = {}

AegisHelpContent.DE = {
    help = {
        { title = "Erste Schritte", lines = {
            "\195\150ffnen: Klick auf den goldenen Wappen-Knopf neben der Ausr\195\188stungsleiste oben links, oder Taste F7. Die Taste l\195\164sst sich unter Optionen im Reiter Mods \195\164ndern.",
            "Das goldene Panel sehen nur echte Admins des Servers. Welche Seiten ein einzelner Admin benutzen darf, legst du auf der Rollen-Seite fest.",
            "F7 klappt das Fenster nur zusammen: alle Listen, Auswahlen und Eingaben bleiben erhalten, F7 holt alles unver\195\164ndert zur\195\188ck. Erst das X oben rechts schlie\195\159t das Panel wirklich.",
            "Das Fenster packst du am Kopfbereich mit gedr\195\188ckter Maustaste und ziehst es frei an jede Stelle des Bildschirms.",
            "Der Minus-Knopf verwandelt das Panel in eine kleine Leiste, die du frei verschieben kannst. Das Plus auf der Leiste bringt das Panel an dieser Stelle zur\195\188ck.",
            "Unten rechts sitzt ein kleines Punkte-Dreieck: daran ziehst du das Fenster auf jede gew\195\188nschte Gr\195\182\195\159e. Die Gr\195\182\195\159e bleibt auch nach einem Neustart erhalten. Wird das Fenster zu klein f\195\188r eine Seite, erscheint rechts ein Balken zum Rollen.",
            "In der Seitenleiste unten sitzt ein kleines Schloss: ge\195\182ffnet ziehst du die Eintr\195\164ge mit gedr\195\188ckter Maustaste an eine neue Stelle, die goldene Linie zeigt dabei die Einf\195\188gestelle. Danach das Schloss wieder schlie\195\159en, dann sitzt die Reihenfolge fest.",
            "Auch dieses Hilfe-Fenster l\195\164sst sich am Kopf verschieben und unten rechts auf jede Gr\195\182\195\159e ziehen.",
        } },
        { title = "Kr\195\164fte", lines = {
            "Jede Karte ist ein Schalter, der sofort wirkt: Gottmodus (kein Schaden), Unsichtbar (Zombies und Spieler sehen dich nicht), Durch W\195\164nde gehen, Schnelle Bewegung, Sofortige Aktionen, Unbegrenzt tragen, Unbegrenzte Ausdauer, Nachtsicht und mehr.",
            "Der Spectator-Schalter oben rechts aktiviert Gottmodus, Unsichtbar, Durch W\195\164nde und Schnelle Bewegung in einem Zug. Ideal, um unbemerkt zu beobachten.",
            "Alle Kr\195\164fte aus schaltet s\195\164mtliche Schalter auf einmal zur\195\188ck, auch den Spectator.",
            "Admin-Tag blendet die rote Admin-Kennzeichnung \195\188ber deinem Kopf ein oder aus. Die Wahl \195\188bersteht Neustarts.",
        } },
        { title = "\195\156bersicht", lines = {
            "Die Startseite ist ein Baukasten aus Karten. Der Knopf oben rechts schaltet den Umbaumodus ein: Karten mit gedr\195\188ckter Maustaste an eine andere Stelle ziehen, das Kreuz oben rechts an einer Karte nimmt sie weg, die Plus-Kachel unten \195\182ffnet den Katalog.",
            "Der Katalog enth\195\164lt alles, was du sehen darfst: die Kr\195\164fte-Schnellschalter, Heilen und Versorgen, dein Aktionsprotokoll, Uhrzeit, Puls des Servers, Neustart-Countdown, Wetter, deine Rolle, die Funktions-Schalter, die Online-Spieler und die Karte Zeit und Wetter.",
            "Dazu liegt f\195\188r jede Panel-Seite eine Kachel bereit, von Welt \195\188ber Werkzeuge und Zonen bis zu den Serveroptionen. Ein Klick darauf springt direkt dorthin. So legst du dir genau das auf die Startseite, was du am h\195\164ufigsten brauchst.",
            "Die Karte Zeit und Wetter setzt die Tageszeit auf Morgen, Mittag, Abend oder Mitternacht und beendet ein laufendes Unwetter, ohne dass du auf die Welt-Seite wechseln musst.",
            "Standard wiederherstellen im Umbaumodus baut die Startseite wieder so auf wie beim ersten \195\150ffnen. Dein Layout gilt nur f\195\188r dich und wird gespeichert, andere Admins haben ihr eigenes.",
            "Heilen entfernt hier auch Bisse, Kratzer und die Zombie-Infektion.",
        } },
        { title = "Spieler", lines = {
            "Links die Liste aller verbundenen Spieler mit ihren Steam-Bildern. Der Schalter oben blendet zus\195\164tzlich alle jemals gesehenen Offline-Spieler ein.",
            "Rechts die Aktionen f\195\188r den ausgew\195\164hlten Spieler. Sie funktionieren \195\188ber jede Entfernung: Hinteleportieren, Zu mir holen, Heilen, Grundbed\195\188rfnisse stillen, Gegenstand geben, Gottmodus und Unsichtbar f\195\188r den Spieler schalten.",
            "Folgen (Geist-Symbol) heftet deine Kamera dauerhaft an den Spieler, egal wie weit er entfernt ist. Du bewegst dich dabei unsichtbar mit. Erneuter Klick auf Folgen beendet es.",
            "Nur zwei Dinge brauchen einen Spieler in deiner N\195\164he: Werte \195\182ffnen (das gro\195\159e Werte-Fenster) und die 3D-Vorschau links. Steht der Spieler zu weit weg, zeigt die Vorschau Au\195\159er Reichweite.",
            "Verwarnen und Stummschalten fragen nach einem Grund. Kicken wirft den Spieler sofort vom Server. Bannen und Zeitbann verlangen einen Grund, der im Protokoll landet. Entbannen erscheint nur bei tats\195\164chlich gebannten Spielern.",
            "Beziehungs-Radar zeigt, mit wem der Spieler in den letzten sieben Tagen am meisten Zeit verbracht hat. Tragelast setzt sein maximales Tragegewicht bis 1000.",
        } },
        { title = "Gegenst\195\164nde", lines = {
            "Oben das Suchfeld: einfach einen Teil des Namens tippen, die Liste filtert sofort. Daneben die Kategorie-Auswahl zum Eingrenzen.",
            "Die Mengen-Kn\195\182pfe (1, 5, 10 und so weiter) bestimmen, wie viele St\195\188ck vergeben werden. Ziel ist entweder dein eigenes Inventar oder ein ausgew\195\164hlter Spieler.",
            "Unten merkt sich das Panel deine zuletzt vergebenen Gegenst\195\164nde als Verlaufs-Kn\195\182pfe f\195\188r schnellen Zugriff.",
        } },
        { title = "Fahrzeuge", lines = {
            "Fahrzeug ausw\195\164hlen, im Vorschaufenster mit den Dreh-Kn\195\182pfen ausrichten, dann Hier spawnen: das Fahrzeug erscheint vor dir in genau dieser Blickrichtung.",
            "Doppelklick auf ein Fahrzeug in der Welt (oder der Knopf im Panel) \195\182ffnet das Detail-Fenster: Tank f\195\188llen, Batterie laden, Schl\195\188ssel ins Z\195\188ndschloss legen, jeden einzelnen Teil reparieren, Farbe und Zustand \195\164ndern.",
            "Fahrzeug-Teleport bringt das Fahrzeug samt Anh\195\164nger und kompletter Ladung zu dir oder dich zu ihm.",
        } },
        { title = "Welt", lines = {
            "Tageszeit: die vier Presets (Morgen, Mittag, Abend, Mitternacht) oder der Schieberegler setzen die Uhrzeit sofort f\195\188r alle Spieler. IG-Datum und IG-Uhrzeit stellen den kompletten Kalender um.",
            "Wetter: Gewitter, Tropensturm und Schneesturm bauen sich \195\188ber etwa eine Spielstunde auf, die Dauer bestimmt der Regler. Wetter stoppen beendet alles sofort. Sofort-Regen wirkt ohne Aufbauzeit.",
            "Der Wetter-Designer unten mischt eigenes Wetter aus Wolken, Regen, Nebel und Wind, auf Wunsch mit Donner-Takt. Als Vorlage speichern merkt sich die Mischung dauerhaft unter eigenem Namen.",
            "Ereignisse: Donnerschlag, Schuss und Feuerwerk erzeugen Ger\195\164usche an deiner Position, der L\195\164rm-Regler bestimmt den Radius. Zombies in der Umgebung reagieren darauf.",
        } },
        { title = "Zonen", lines = {
            "Hier verwaltest du Safehouses und erweiterst sie \195\188ber die Vanilla-Grenzen hinaus. Egal aus wie vielen Teilen eine Zone besteht, sie z\195\164hlt immer als ein Ganzes.",
            "Neue Zone legt ein Safehouse f\195\188r einen beliebigen Spieler an: Besitzer w\195\164hlen, dann Rechtecke ziehen oder die Fl\195\164che malen. Mehrere Rechtecke lassen sich vor dem \195\156bernehmen zusammensetzen, jedes weitere muss an die Form anschlie\195\159en.",
            "Grenzen bearbeiten f\195\188gt einer Zone weitere Rechtecke an: Linksklick-Ziehen f\195\188gt an, Rechtsklick-Ziehen entfernt Angef\195\188gtes wieder, die urspr\195\188ngliche Fl\195\164che bleibt dabei gesch\195\188tzt. Der Editor bleibt offen, bis Enter alles auf einmal \195\188bernimmt oder ESC verwirft. Die Vorschau zeigt immer die entstehende Gesamtform.",
            "Fl\195\164che malen ist das Feinwerkzeug f\195\188r einzelne Kacheln am Rand: Linksklick malt, Rechtsklick radiert, auch auf der bestehenden Fl\195\164che. Zum Verkleinern einer Zone ist das der Weg. Zum Malen musst du innerhalb der Zone stehen.",
            "Ber\195\188hren sich Fl\195\164chen desselben Besitzers, werden sie zu einer Zone. Zonen einblenden zeichnet alle Zonen sichtbar in die Welt. Sicherung legt eine Kopie der kompletten Zone an, die sich sp\195\164ter wiederherstellen l\195\164sst, etwa nach einem Griefer-Angriff.",
        } },
        { title = "Horde und Tiere", lines = {
            "Horde: Anzahl und Radius einstellen, dann spawnen die Zombies um die gew\195\164hlte Position. Aufr\195\164umen entfernt Zombies im Radius wieder.",
            "Belagerung l\195\164sst die Horde aus der Ferne auf einen Punkt zumarschieren, mit Vorwarnung durch einen Schuss. Die Feinheiten (Wellen, Anzahl, Distanz) stellst du in der Sandbox unter Aegis Ereignisse ein.",
            "Tiere: Art und Rasse w\195\164hlen, in der Vorschau drehen, dann in der Welt platzieren, genau wie bei Fahrzeugen.",
        } },
        { title = "Server", lines = {
            "Neustart: die Minuten-Kn\195\182pfe starten einen Countdown, den alle Spieler als Banner sehen. Uhrzeit und Datum planen einen Neustart zu einem festen Zeitpunkt, die Automatik wiederholt ihn im gew\195\164hlten Takt.",
            "So l\195\164uft der Neustart ab: der Server kann sich nicht selbst beenden, das gibt das Spiel nicht her. Am Stichtag reicht er den Befehl deshalb an einen berechtigten Spieler weiter, also an jeden, dessen Rolle das Herunterfahren erlaubt, und probiert das jede Minute erneut, bis es klappt oder nach zehn Minuten aufgegeben wird. Es muss also zum Stichtag jemand Berechtigtes online sein. Das Wiederhochfahren \195\188bernimmt dein Hoster-Panel, dort sollte Neustart nach Stopp aktiv sein. Jeder Versuch steht in der Server-Konsole, samt der Zahl der berechtigten Spieler, die gerade online sind.",
            "Welt sichern speichert den kompletten Spielstand sofort.",
            "Stromnetz und Wassernetz schalten die Versorgung der ganzen Karte an oder aus.",
            "Event-Regie: fertige Schauspiele mit einem Klick an deiner Position, etwa Unwetter-Show, Belagerung, Heli-Alarm, Luftlandung, Feuersturm oder Kriechende Gefahr.",
            "Die Funktions-Schalter bestimmen, was Spieler d\195\188rfen: Spielerbereich, Spieler-Claims und Spieler-Kits. Der Server setzt das durch, es ist nicht nur eine Anzeige. Dieselben Schalter stehen in der Sandbox und als Karte auf der Startseite.",
            "Server-Branding rechts daneben setzt den Namen, den beide Panels im Kopf zeigen. Leer lassen bringt AEGIS zur\195\188ck.",
            "Ansage schickt eine Nachricht in den Chat aller Spieler.",
        } },
        { title = "Serveroptionen", lines = {
            "Eine eigene Seite mit allen Einstellungen der Server-INI, nach Themen gruppiert und \195\188ber das Suchfeld durchsuchbar. Unter jedem Namen steht der Standardwert.",
            "\195\132nderungen sammelst du und schickst sie mit \195\156bernehmen ab. Sie wirken sofort und landen zugleich in der INI. Ein Uhr-Symbol markiert Optionen, die erst nach einem Neustart greifen.",
            "Andere Admins sehen deine \195\132nderung erst nach einem Reconnect oder nach /reloadoptions, das ist eine Eigenart des Spiels und keine Fehlfunktion.",
            "Passwort, RCON und die Discord-Felder erscheinen nur als verborgen und ohne Wert: der Server schickt sie nie an einen Client. Ports, Karte und die Spieler-ID sind fest gesperrt.",
            "Mods und Workshop-Objekte \195\182ffnen sich nur nach zwei ausdr\195\188cklichen Warnungen und gelten dann bis zum Schlie\195\159en des Panels. Ein Tippfehler dort kann den Server lautlos unbrauchbar machen.",
            "Serveroptionen ist ein eigener Bereich in den Rollen: du kannst einem Admin die Server-Seite geben und die Optionen trotzdem vorenthalten.",
        } },
        { title = "Bau-Werkzeuge", lines = {
            "Bau-Pinsel: ein Bauteil aus der Palette w\195\164hlen und mit gedr\195\188ckter Maustaste \195\188ber die Kacheln ziehen. R dreht das Teil. B\195\182den f\195\188llen die Fl\195\164che, W\195\164nde folgen der gezogenen Linie. Eigene Bauteile nimmst du mit dem Sprite-Inspektor auf.",
            "Sprite-Inspektor: zeigt zu jedem angeklickten Objekt in der Welt den internen Namen und \195\188bernimmt es auf Wunsch in die Pinsel-Palette.",
            "Bau-Radar: beim \195\156berfahren von gebauten Objekten erscheint, wer sie wann gebaut hat.",
            "Bau-Protokoll: jede Bau- und Abriss-Aktion mit Uhrzeit, Spieler und Ort. Klick auf eine Zeile bietet den Sprung zum Ort an. Bei Abrissen zeigt der Wiederherstellen-Knopf zuerst eine durchscheinende Vorschau des abgerissenen Bauwerks an seiner alten Stelle, erst deine Best\195\164tigung baut es wirklich nach. Treppen und Garagentore werden dabei komplett mit allen Teilen nachgebaut.",
            "Bereich roden: Rechteck aufziehen, der erste Durchgang entfernt nur Pflanzen, ein zweiter auf derselben Fl\195\164che entfernt alles bis auf den Boden. R\195\188ckg\195\164ngig stellt die letzte Rodung wieder her.",
        } },
        { title = "Protokoll und Todesf\195\164lle", lines = {
            "Das Protokoll sammelt jede Admin-Aktion dauerhaft, geordnet nach Bereichen: Aktionen, Bans, Kicks, Verwarnungen, Chat-Moderation, Admin- und Spieler-Sitzungen, Bau und Todesf\195\164lle. Links Bereich w\195\164hlen, in der Mitte den Eintrag, rechts steht der volle Inhalt.",
            "Todesf\195\164lle: bei jedem Spielertod entsteht automatisch ein ausf\195\188hrlicher Bericht: wer oder was get\195\182tet hat (samt Waffe), alle Verletzungen, Infektionsstatus, Ort samt Raum, wie viele Zombies in der N\195\164he waren und welche Spieler in der Umgebung standen. Alle Admins bekommen beim Tod sofort eine Kurzmeldung.",
        } },
        { title = "Rollen", lines = {
            "Rollen legen fest, welche Panel-Seiten ein Admin benutzen darf: Rolle anlegen, H\195\164kchen bei den erlaubten Bereichen setzen, dann unten einem Spieler zuweisen.",
            "So gibst du jemandem eingeschr\195\164nkte Adminrechte. Erstens: Vanilla-Stufe auf observer setzen, also /setaccesslevel \"Name\" observer. Aegis zeigt das Panel nur Stufen mit Admin-Werkzeug, observer ist die niedrigste, die funktioniert, und gibt f\195\188r sich allein noch keine Aegis-Rechte. Zweitens: hier eine Rolle anlegen, nur die erlaubten Bereiche anhaken, speichern. Drittens: die Rolle unten dem Spieler zuweisen.",
            "L\195\164sst du den Bereich Rollen unangehakt, kann er keine Rechte mehr \195\164ndern, auch nicht seine eigenen. Nur die Vanilla-Stufe admin beh\195\164lt die Rollenverwaltung in jedem Fall, damit sich niemand selbst aussperren kann.",
            "F\195\164hrst du mit der Maus \195\188ber einen Bereich, steht dort, welche Seiten er umfasst, sobald es mehr als eine ist.",
            "Serveroptionen und Sandbox sind eigene Bereiche. Wer die Server-Seite bekommt, hat damit nicht automatisch Zugriff auf die INI-Einstellungen oder die Sandbox-Regler.",
            "Wichtig: eine Rolle macht niemanden zum Admin. Wer kein Admin des Servers ist, bekommt durch eine Rolle keinerlei Admin-Rechte, nur den farbigen Namen \195\188ber dem Kopf.",
            "Die Rollenfarbe bestimmt die Farbe des Namens-Tags. Vor der Zuweisung sagt eine Nachfrage in klaren Worten, ob die Rolle nur den Namens-Tag bringt oder echte Rechte.",
            "Der Kopf-Tag \195\188bernimmt die F\195\164higkeiten der bisherigen Rolle: ein Admin mit Tag bleibt funktional Admin. Willst du etwas aus Sicht eines normalen Spielers pr\195\188fen, nimm einen Zweit-Account.",
        } },
        { title = "Spieler-Panel (blau)", lines = {
            "Das blaue Panel ist das Gegenst\195\188ck f\195\188r normale Spieler. Jeder der den Server betritt bekommt es automatisch als eigenen blauen Knopf, Admins eingeschlossen, ganz ohne Rollen-Zuweisung.",
            "Rollen vergeben nur noch die Extras: auf der Rollen-Seite stellst du pro Rolle Claim-Kacheln (0 bedeutet kein eigener Zonen-Claim) und Kit-Zugang ein. Mehr steuert eine Rolle am Spieler-Panel nicht, abschalten l\195\164sst es sich nicht. Donatoren l\195\182st du elegant \195\188ber eigene Rollen mit gr\195\182\195\159erem Budget.",
            "Der Spieler sieht: seinen Charakter in 3D mit Werten und Lieblingswaffe, seine Statistiken (Tode, Zombie- und Banditen-Kills, gelaufene Kilometer, l\195\164ngstes Leben, Spielzeit) samt Server-Bestenliste, seine Gesundheit mit Verbinden direkt im Panel, seine eigenen Fahrzeuge mit Zustandsbalken und Navi, sein Safehouse mit Warnung vor dem Verfall, die Kits zum Abholen, seinen eigenen Zonen-Claim und einen Notruf-Knopf.",
            "Der Notruf erreicht alle Admins, die gerade online sind, mit Name, Position und Nachricht des Spielers. Danach zwei Minuten Sperre gegen Spam.",
            "Kilometer, Tode und Banditen-Kills z\195\164hlen ab dem Einbau dieser Version. Die Spielzeit wird r\195\188ckwirkend aus den Sitzungs-Protokollen berechnet.",
            "Hinweis f\195\188r den Betreiber: das Vanilla-Beanspruchen von Safehouses (Serveroption PlayerSafehouse) sollte aus sein, wenn du die eigenen Claims des Spieler-Panels nutzt, sonst gibt es zwei konkurrierende Wege.",
        } },
        { title = "Kits", lines = {
            "Auf der Kits-Seite stellst du Pakete zusammen, die Spieler im blauen Panel abholen k\195\182nnen: Namen vergeben, \195\188ber die Suche Gegenst\195\164nde hinzuf\195\188gen, Menge setzen, Modus w\195\164hlen (einmalig, t\195\164glich, w\195\182chentlich, monatlich).",
            "Rollen sind freiwillig. W\195\164hlst du KEINE Rolle aus, ist das Kit offen und jeder Spieler auf dem Server kann es abholen, auch wer gar keine Rolle hat. Das ist der Normalfall, den du f\195\188r ein Startpaket willst.",
            "Erst wenn du eine oder mehrere Rollen anhakst, wird das Kit auf deren Tr\195\164ger eingeschr\195\164nkt. Im blauen Panel steht dann klein hinter dem Kit-Namen, \195\188ber welche Rolle oder \195\188ber den Booster-Status der Spieler es bekommt.",
            "Der Anspruch wird pro Spieler gespeichert, Tod und Wiedereinstieg \195\164ndern daran nichts. Nur Anspr\195\188che zur\195\188cksetzen beim Kit hebt das wieder auf.",
            "Der Bereich Kits l\195\164sst sich \195\188ber die Rollen-Seite an einzelne Admin-Rollen delegieren. Ob Spieler \195\188berhaupt an Kits kommen, entscheidet der Schalter Spieler-Kits auf der Server-Seite.",
        } },
        { title = "Praktische Hinweise", lines = {
            "Rechtsklick auf die Weltkarte (Taste M) bietet Hierher teleportieren an.",
            "R\195\188ckmeldungen erscheinen als goldene Kurzmeldung oben im Panel. Ist das Panel gerade verborgen (etwa w\195\164hrend einer Vorschau), erscheint die Meldung stattdessen als schwebender Text an deinem Charakter.",
            "Wirkt eine Liste leer, l\195\164dt der runde Pfeil-Knopf sie neu.",
            "Fast jede Aktion landet im Protokoll. Wenn etwas nicht geklappt hat, lohnt dort der erste Blick.",
        } },
    },
    changelog = {
        { version = "2.3.5", date = "August 2026", sections = {
            { title = "Neu hinzugef\195\188gt", points = {
                "Die Zahl der gemerkten Fahrzeuge je Spieler ist jetzt eine Sandbox-Option (Aegis Ereignisse, \"Gemerkte Fahrzeuge je Spieler\"). Vorher waren es fest f\195\188nf. 0 schaltet das Merken ab, das H\195\182chstma\195\159 ist 20. Auf Servern mit Knox Claim z\195\164hlt weiterhin dessen eigene Grenze. Wer den Wert senkt, nimmt niemandem etwas weg: bereits gemerkte Fahrzeuge bleiben, es kommen nur keine neuen dazu.",
            } },
            { title = "Behoben", points = {
                "Prozentzeichen in den Texten auf 42.20.1 umgestellt. Der Hotfix vom 5. August hat die Behandlung des Zeichens in \195\156bersetzungsdateien ge\195\164ndert, ein dargestelltes Prozent muss jetzt doppelt geschrieben werden. Betraf vier Texte in allen 13 Sprachen, darunter \"Zustand: 95%\" auf der Gesundheitsseite und der Fortschritt beim Sichern.",
                "Der geplante Neustart lief ab: der Zeitgeber z\195\164hlte herunter, am Ende stand nur \"Unknown command restart\" im Chat und der Server blieb oben. Der Takt, in dem der Server den Auftrag wiederholte, h\195\164ngt an der Spielzeit und lief auf kurzen Tagen etwa alle sieben Sekunden. Damit kam die Wiederholung immer der eigenen Absicherung zuvor, die nach acht Sekunden den Befehl h\195\164tte schicken sollen, der wirklich existiert. Der Server wartet jetzt echte Minuten zwischen zwei Versuchen, und ein zweiter Anlauf geht sofort auf den funktionierenden Befehl.",
            } },
        } },
        { version = "2.3.4", date = "August 2026", sections = {
            { title = "Neu hinzugef\195\188gt", points = {
                "Die Safehouse-Seite im Spielerpanel zeigt jetzt den Weg nach Hause (Entfernung und Richtung, live) und bietet den Vanilla-Schalter zum Wiederbeleben im Safehouse an, sofern der Server das erlaubt.",
                "Auf Servern mit Knox Claim zeigt die Fahrzeuge-Seite im Spielerpanel jetzt deine dort eingetragenen Fahrzeuge, samt 3D-Vorschau. Entfernung, Navi und Zustandsbalken gibt es, sobald der Wagen in deiner N\195\164he geladen ist. Freigeben l\195\164uft weiter \195\188ber das Knox-Claim-Fenster, deshalb bleibt der Vergessen-Knopf f\195\188r diese Eintr\195\164ge aus.",
            } },
            { title = "Behoben", points = {
                "Der automatische Neustart konnte verpuffen: der Server kann sich nicht selbst beenden und reicht den Befehl an einen berechtigten Admin-Client weiter, tat das aber genau EINMAL. War in dieser Sekunde niemand empfangsbereit, liefen alle Warnungen und nichts passierte (Community-Meldung). Jetzt klopft der Server jede Minute erneut, bis der Neustart wirklich greift, gibt nach zehn Minuten mit Protokolleintrag auf, und sowohl das Senden als auch das Ausf\195\188hren stehen ab jetzt im Protokoll.",
                "Gemerkte Fahrzeuge wurden nach einem Server-Neustart zu leeren H\195\188llen: keine Position, keine Balken, kein Navi. Der Bestand hing an der Fahrzeug-Nummer, die das Spiel nach jedem Neustart neu vergibt. Beim Merken wandert jetzt eine feste Kennung ans Fahrzeug, \195\188ber die Server und Panel es immer wiederfinden, die Nummer heilt sich dabei von selbst. Eintr\195\164ge aus fr\195\188heren Versionen ohne Kennung bleiben leider H\195\188llen, einmal Vergessen und neu Merken r\195\188stet sie um.",
                "Die 3D-Vorschau im Spielerpanel wurde \195\188berarbeitet: sie startet bei jedem Fahrzeugwechsel frisch, blendet dabei ohne Zucken um, und das Fahrzeug sitzt tiefer und damit besser im Rahmen. Zoom und Verschieben mit Shift gelten f\195\188r das gerade gew\195\164hlte Fahrzeug und werden beim Wechsel zur\195\188ckgesetzt. Manche Mod-Fahrzeuge sind schief um ihren Modell-Ursprung gebaut und sitzen deshalb in JEDER Vorschau des Spiels schief, dagegen hilft nur das Verschieben von Hand.",
                "Der Weg nach Hause auf der Safehouse-Seite ist jetzt golden und anklickbar: ein Klick richtet den Bildschirm-Pfeil aufs Zuhause, ein zweiter schaltet ihn ab.",
                "Beim Wiederbeleben im Safehouse landete man neben dem Haus statt darin: das Spiel vertauscht bei der Berechnung des Punkts Breite und H\195\182he der Zone, bei l\195\164nglichen Zonen liegt er dadurch drau\195\159en. Aegis rechnet den Punkt jetzt selbst richtig.",
                "Bei Fahrzeugen aus Knox Claim fehlten nach einem Neuanmelden Entfernung, Himmelsrichtung, die Zustandsbalken und die Einzelteil-Liste. Die Zuordnung lief \195\188ber die Netz-Nummer des Fahrzeugs, und die vergibt das Spiel nach jedem Neustart neu. Gesucht wird jetzt \195\188ber die Kennung am Fahrzeug selbst.",
                "Aegis hat zweimal je Sekunde versucht, dem K\195\182rper-Inventar eine Kapazit\195\164t zu setzen, wenn eine Tragkraft zugewiesen war. Das f\195\188llte das Server-Protokoll mit Warnungen, ohne Wirkung. Der K\195\182rper wird jetzt nur noch \195\188ber den vorgesehenen Weg bedient.",
                "Zugewiesener Stauraum wirkte f\195\188r normale Spieler nur bis 100, obwohl das Panel den vollen Wert zeigte (Community-Meldung). Bei Kisten fiel das kaum auf, weil deren Vorgabe darunter liegt, bei Arbeitsplatten und H\195\164ngeschr\195\164nken ging gar nichts mehr, denn die sitzen schon auf dieser Grenze. Das Spiel deckelt Welt-Beh\195\164lter beim Lesen hart, und die Pr\195\188fung beim Verschieben l\195\164uft an unserer Vorgabe vorbei. Bisher hatten nur Admins den Umweg \195\188ber den Server, jetzt nimmt ihn jeder, sobald der Beh\195\164lter einen zugewiesenen Stauraum hat. Der Server pr\195\188ft dabei weiterhin Reichweite, Gegenstand und genau diesen Wert.",
                "Neustart zu fester Uhrzeit und die Automatik-Verankerung rechneten in Weltzeit statt in deiner Ortszeit: wer 00:11 eintrug, bekam den Neustart um 02:11. Eingabe und Anzeige laufen jetzt \195\188ber deine lokale Uhr.",
                "Hilfe und Changelog liefen beim Verkleinern des Fensters mit dem alten Zeilenumbruch weiter und der Text verschwand rechts unter der Bildlaufleiste. Der Umbruch pr\195\188ft jetzt vor jedem Zeichnen, ob er noch zur Fensterbreite passt.",
                "Der Mod-Filter im Gegenst\195\164nde-Katalog ist jetzt immer sichtbar. Ohne installierte Item-Mods hat er sich versteckt und dabei ein Loch in der Filterzeile hinterlassen, das nach einem Fehler aussah. Jetzt steht dann eben nur Project Zomboid darin.",
                "Der Hinweistext auf der leeren Fahrzeuge-Seite war breiter als die Spalte und vorne abgeschnitten.",
                "Der Knopf unter der Fahrzeugliste hei\195\159t jetzt \195\188berall Freigeben: ein gemerktes Fahrzeug verl\195\164sst die Liste, ein Knox-Claim-Fahrzeug wird wirklich freigegeben. Und die Ankunft zuhause begr\195\188\195\159t dich nicht mehr mit Fahrzeug gefunden.",
                "Der Knopf zum Merken eines Fahrzeugs verschwand auf Servern mit Knox Claim doch nicht. Der Server hat das Merkmal richtig geschickt, aber das Spielerpanel baut seinen Zustand Feld f\195\188r Feld neu auf und kannte das neue Feld nicht, also fiel es beim Empfang lautlos weg. Aus 2.3.3, sofort behoben.",
                "Die feste Zeile powered by Aegis in der Fu\195\159leiste ist raus, aus beiden Panels. Sie hat dort nur Platz gekostet.",
            } },
        } },
        { version = "2.3.3", date = "August 2026", sections = {
            { title = "Neu hinzugef\195\188gt", points = {
                "Gegenst\195\164nde nach Herkunfts-Mod filtern (Community-Wunsch): neben dem Kategorie-Filter w\195\164hlst du jetzt den Mod, und bei Mod-Gegenst\195\164nden steht klein hinter dem Namen, woher sie stammen. Auch die Suche findet Mod-Namen. Ohne Mods bleibt der Filter verborgen.",
                "Zusammenspiel mit Knox Claim: l\195\164uft dieser Mod auf dem Server, verwaltet er die Fahrzeuge. Aegis zieht dann seinen eigenen Knopf zum Merken eines Fahrzeugs im Spielerpanel zur\195\188ck, damit nicht zwei Listen nebeneinander laufen, von denen jede nur ihre H\195\164lfte kennt. Der Knopf zum Vergessen bleibt, damit alte Eintr\195\164ge verschwinden k\195\182nnen. Ohne Knox Claim \195\164ndert sich nichts.",
            } },
            { title = "Behoben", points = {
                "RECHTE-L\195\156CKE: auf Servern mit eigenen Rang-Rollen (Kopftags wie \"Veteran\") galt jeder Traeger einer solchen Rolle als Serverpersonal und hatte damit das volle Panel, auch ohne Admin-Werkzeug und ohne zugewiesene Aegis-Rolle. Aegis hat jede benannte Zugangsstufe im Zweifel als Personal gewertet, und da eine Aegis-Rolle Rechte nur einschraenkt und nie vergibt, bedeutete das vollen Zugriff, serverseitig durchgesetzt. Jetzt zaehlt nur noch, wer nachweislich das Admin-Werkzeug traegt. Die vier Vanilla-Stufen Admin, Moderator, GM und Beobachter kommen weiterhin unabhaengig vom Rollen-Verzeichnis herein, und wenn das Verzeichnis gar nicht lesbar ist, bleibt der alte Notausgang, damit sich kein echter Admin aussperrt. Jede Entscheidung steht ab jetzt mit Begruendung im Server-Protokoll.",
                "Die eingestellte Tragkraft hat auch die harte Aufheb-Grenze auf denselben Wert gezogen. Das Spiel kennt zwei Grenzen: ab der Tragkraft bist du \195\188berladen, erst an der harten Grenze (fest bei 50) verweigert es das Aufheben ganz. Wer eine kleine Tragkraft zugewiesen bekam, konnte am Limit gar nichts mehr aufheben, und der Wert kam nach dem Tod \195\188ber die gespeicherte Liste zur\195\188ck. Jetzt bleibt unterhalb von 50 das normale \195\156berladen erhalten, nur gr\195\182\195\159ere Werte heben die harte Grenze weiter an. Betroffene Charaktere werden beim n\195\164chsten Einstieg von selbst bereinigt.",
                "Die Bed\195\188rfnis-Regler im Wertefenster wirken jetzt schon w\195\164hrend des Ziehens statt erst beim Loslassen. Der Wert wandert dabei viermal je Sekunde zum Server, ohne je Schritt eine Meldung auszul\195\182sen, und im Protokoll steht weiterhin nur der Wert, bei dem du losl\195\164sst.",
                "Die Safehouse-Karte im Spielerpanel blieb leer, obwohl die Zone auf der Zonen-Seite des Adminpanels stand. Sie hat die Liste auf dem eigenen Rechner gelesen, und eine Zone, die auf dem Server entsteht, muss dort nicht auftauchen. Sie fragt jetzt den Server, so wie die Zonen-Seite es immer getan hat, und zieht bei offener Seite von selbst nach.",
            } },
        } },
        { version = "2.3.2", date = "August 2026", sections = {
            { title = "Neu hinzugef\195\188gt", points = {
                "Bed\195\188rfnisse frei einstellen (Community-Wunsch): im Wertefenster \195\182ffnet der neue Knopf oben rechts Regler f\195\188r Hunger, Durst, M\195\188digkeit, Ausdauer, Stress, Panik, Langeweile, Unzufriedenheit, Schmerz, \195\156belkeit, Rausch und N\195\164sse. Bisher konnte das Panel diese Werte nur alle auf einmal zur\195\188cksetzen, jetzt stellst du jeden einzeln ein, auch nach oben. Die Grenzen kommen aus dem Spiel selbst, geschickt wird erst beim Loslassen des Reglers.",
                "Die Hilfe erkl\195\164rt unter Rollen jetzt Schritt f\195\188r Schritt, wie du jemandem eingeschr\195\164nkte Adminrechte gibst.",
            } },
            { title = "Behoben", points = {
                "RECHTE-L\195\156CKE: wer eine Vanilla-Stufe mit Admin-Werkzeug hatte, also auch Observer, GM und Moderator, konnte die Rollen-Seite immer \195\182ffnen und sich selbst jeden Bereich geben. Der Aussperr-Schutz h\195\164ngt jetzt an der Vanilla-F\195\164higkeit RolesWrite, die nur die Stufe Admin hat. Ein echter Admin kann sich weiterhin nicht selbst aussperren, alle anderen brauchen den Bereich Rollen ausdr\195\188cklich in ihrer Aegis-Rolle.",
                "Die Eigenschaft Organisiert wirkte in jedem Beh\195\164lter nicht mehr, dem ein Admin einmal einen Stauraum zugewiesen hatte. Das Spiel rechnet den Bonus auf den Stauraum obendrauf, unsere Vorgabe hat ihn dabei verschluckt. Betroffene Spieler konnten nichts mehr einr\195\164umen, sobald der normale Stauraum ohne Bonus erreicht war. Organisiert und Unordentlich wirken jetzt auch auf zugewiesene Werte.",
                "Die Bildlaufleiste der \195\156bersicht lag auf dem Ziehgriff unten rechts und lie\195\159 sich nicht mehr greifen, sobald das Fenster klein genug zum Scrollen war.",
            } },
        } },
        { version = "2.3.1", date = "August 2026", sections = {
            { title = "Behoben", points = {
                "Der goldene Knopf und der blaue Spieler-Knopf fehlten bei manchen Mod-Zusammenstellungen vollst\195\164ndig. Aegis setzt sich unter alle anderen Symbole der Ausr\195\188stungsleiste, hat dabei aber auch Fl\195\164chen mitgemessen, die gar keine Symbole sind, und rutschte so unter den Bildschirmrand. Jetzt z\195\164hlen nur noch symbolgro\195\159e Nachbarn, und der Knopf bleibt in jedem Fall sichtbar.",
                "Ein Mod, der die Ausr\195\188stungsleiste komplett \195\188bernimmt, kann die Aegis-Kn\195\182pfe nicht mehr verschwinden lassen. Fehlen sie, werden sie nachgesetzt.",
                "Fehler anderer Mods im Inventar werden nicht mehr f\195\164lschlich als Aegis-Fehler gemeldet. Aegis h\195\164ngt sich daf\195\188r nicht mehr in die Vanilla-Rucksackleiste ein.",
                "Aegis schreibt keine Diagnosezeilen mehr ins Log, wenn eine Tasche zu voll ist.",
            } },
        } },
        { version = "2.3", date = "Juli 2026", sections = {
            { title = "Neu hinzugef\195\188gt", points = {
                "Seiten ausblenden: das Schloss unten in der Leiste zeigt im offenen Zustand ein Auge an jedem Eintrag. Was du nie benutzt, blendest du aus, das Plus daneben holt es zur\195\188ck. Gilt nur f\195\188r dich und \195\164ndert keine Rechte.",
                "Die \195\156bersicht ist jetzt ein Baukasten: der Bearbeiten-Knopf oben rechts schaltet den Umbaumodus, Karten lassen sich ziehen, entfernen und aus dem Katalog erg\195\164nzen. Jeder Admin beh\195\164lt sein eigenes Layout, ohne Umbau sieht alles aus wie bisher.",
                "Der Katalog reicht \195\188ber alle Bereiche, auf die du Zugriff hast: neben Online-Spielern und den Funktions-Schaltern legst du dir eine Kachel f\195\188r jede Seite hin, von Welt \195\188ber Werkzeuge und Zonen bis zu den Serveroptionen. Ein Klick darauf springt dorthin.",
                "Neue Karte Zeit und Wetter: Morgen, Mittag, Abend und Mitternacht direkt auf der \195\156bersicht, dazu der Knopf, der ein laufendes Unwetter beendet.",
                "Im Umbaumodus steht neben dem Bearbeiten-Knopf Standard wiederherstellen. Das baut die \195\156bersicht wieder so auf wie beim ersten \195\150ffnen.",
                "Neue Seite Serveroptionen: alle Einstellungen der Server-INI durchsuchbar und direkt im Panel \195\164nderbar, mit Kennzeichnung, was erst nach einem Neustart greift. \195\132nderungen wirken live und landen sofort in der INI. Mods und Workshop-Objekte sind gesperrt und lassen sich nur nach doppelter Warnung auf eigene Verantwortung bearbeiten.",
                "Dein Servername statt AEGIS: auf der Server-Seite tr\195\164gst du ihn ein, beide Panels zeigen ihn bei allen Spielern, darunter steht fest powered by Aegis. Leer lassen bringt AEGIS zur\195\188ck.",
                "Neue Schalterkarte auf der Server-Seite: Spielerbereich, Spieler-Claims und Spieler-Kits lassen sich dort und in der Sandbox an- und abschalten, live und f\195\188r alle. Der Server setzt es durch, nicht nur die Anzeige.",
                "Kits ohne Rollenbindung kann jetzt wirklich jeder abholen. Bisher kamen Spieler ohne Rolle gar nicht erst an die Kits-Seite, deshalb wirkte die Rolle wie Pflicht.",
                "Neuer Handwerk-Cheat neben dem Bau-Cheat: Rezepte herstellbar ohne Material, K\195\182nnen und Werkbank. Wer auch unbekannte Rezepte in der Liste will, schaltet zus\195\164tzlich Alle Rezepte kennen dazu, die beiden Schalter sind unabh\195\164ngig. Der Bau-Cheat bleibt wie er war.",
                "Der Spielerbereich zeigt Zeit und Datum nur noch mit getragener Uhr: jede Uhr bringt die Zeit, erst eine Digitaluhr auch das Datum.",
                "Serveroptionen sind ein eigener Bereich in den Rollen geworden: du kannst einem Admin die Server-Seite geben und die INI-Einstellungen trotzdem vorenthalten. Bestehende Rollen behalten den Zugang, nachtragen musst du nichts.",
                "Beim Hinzuf\195\188gen einer Eigenschaft im Wertefenster steht beim \195\156berfahren, was sie bewirkt, dazu die Punkte und der Grund, falls die Zeile rot ist.",
            } },
            { title = "Behoben", points = {
                "Die Fahrzeugwerte im Spielerbereich sind live: Tanken und Reparieren neben dem Wagen zeigt sich sofort, nicht erst nach einer halben Minute.",
                "Server-Branding sitzt jetzt rechts neben den Funktions-Schaltern statt darunter, die rechte Seite war dort leer.",
                "Die Werte-Spalte der Serveroptionen l\195\164uft nicht mehr in die Bildlaufleiste.",
                "Die Seitenleiste l\195\164uft bei vielen Seiten und niedrigem Fenster nicht mehr \195\188ber die Fu\195\159zeile. Passt die Liste trotz enger Packung nicht mehr, l\195\164sst sie sich mit dem Mausrad schieben.",
            } },
        } },
        { version = "2.2", date = "Juli 2026", sections = {
            { title = "Neu hinzugef\195\188gt", points = {
                "Die Spielerwerte sind jetzt ein Aegis-Fenster statt des Vanilla-Fensters. Es steckt hinter demselben Knopf auf der Spieler-Seite und l\195\164sst sich verschieben und in der Gr\195\182\195\159e ziehen wie die anderen Aegis-Fenster.",
                "Alles darin wirkt sofort. Eigenschaften, Beruf, Namen, Gewicht, Stufen und Erfahrung greifen beim Ziel unmittelbar, ohne neu zu verbinden. Das Vanilla-Fenster \195\164nderte deine eigene Kopie dieses Spielers und konnte dabei Fertigkeiten zur\195\188cksetzen, die er seit dem Beitritt gelernt hatte.",
                "Fertigkeiten zeigen Stufe, Erfahrung und den Bonus, den der Charakter wirklich bekommt. Du kannst Erfahrung geben, eine Stufe anheben oder senken oder sie direkt setzen.",
                "Jede Eigenschaft sitzt in einem eigenen kleinen Feld mit einem Kreuz, ein Klick darauf nimmt sie weg. Beim Hinzuf\195\188gen kennzeichnet die Liste in Rot, was sich mit einer Eigenschaft \195\188berschneidet, die der Spieler schon hat.",
                "Bei den Namen gibt es Vorname, Nachname und Anzeigename samt Weg zur\195\188ck zum automatischen. Eine Gewichts-Eigenschaft zieht das Gewicht mit, sonst dreht der Server die \195\132nderung binnen Minuten zur\195\188ck.",
            } },
            { title = "Behoben", points = {
                "M\195\182bel aus dem Bau-Pinsel lassen sich wieder abr\195\164umen. Sie entstanden bisher so, dass die Engine das Entfernen verweigerte, weshalb weder Roden noch der Vorschlaghammer daran kamen.",
                "Auch ein Boden aus dem Bau-Pinsel l\195\164sst sich roden. Karten-B\195\182den bleiben gesch\195\188tzt, die zu entfernen w\195\188rde L\195\182cher in die Welt rei\195\159en.",
                "Das Speichern von Rollenrechten meldet keinen Fehler mehr, wenn ein Tr\195\164ger der Rolle offline ist.",
                "Beim Scrollen einer Karte bleiben keine alten Zeilen mehr hinter den Bedienelementen stehen.",
            } },
        } },
        { version = "2.1", date = "Juli 2026", points = {
            "Kit-Anspr\195\188che zur\195\188cksetzen: ein Knopf beim gew\195\164hlten Kit l\195\182scht alle Anspr\195\188che darauf und nennt die Zahl der betroffenen Spieler. Diese k\195\182nnen das Kit danach wieder abholen, ohne Serverneustart.",
            "Das Uhr-Symbol in der Kopfzeile des Editors \195\182ffnet die Liste der Spieler mit Anspruch samt Abholzeitpunkt. Dort setzt du einzelne Spieler zur\195\188ck, wenn nur einer sein Kit braucht.",
            "Abgesetzt am Ende dieser Liste steht Alle Anspr\195\188che l\195\182schen: das entfernt die Anspr\195\188che auf allen Kits f\195\188r jeden Spieler und verlangt einen getippten Grund f\195\188rs Protokoll.",
            "Gedacht ist das f\195\188r den Start einer frischen Welt: die Anspr\195\188che liegen getrennt vom Weltspeicher und \195\188berstehen dadurch einen Reset. Sonst gelten alle Kits als abgeholt und niemand kommt an seins.",
            "Lie\195\159 sich die Anspruchsliste nicht vollst\195\164ndig lesen, bleibt jedes Zur\195\188cksetzen gesperrt und ausgegraut, damit kein halber Stand gel\195\182scht wird.",
            "Folgen l\195\164uft jetzt fl\195\188ssig: du gleitest gleichm\195\164\195\159ig mit dem Ziel mit und h\195\164ltst festen Abstand dahinter, statt kurz still zu stehen und dann ein St\195\188ck zu springen.",
            "Beim Folgen bleibt die Kamera auf der richtigen Etage, auf Treppen sprang sie vorher um ein ganzes Stockwerk. Im Erdgeschoss schwebst du auch nicht mehr knapp \195\188ber dem Boden.",
            "Best\195\164tigungsfenster passen sich jetzt dem Text an: sie werden breiter und lange S\195\164tze brechen sauber um. Vorher stand in manchen Sprachen der halbe Satz unlesbar auf dem Hintergrund.",
        } },
        { version = "2.0", date = "Juli 2026", points = {
            "Vertr\195\164gt sich mit anderen Seitenleisten-Mods: Aegis erkennt fremde Kn\195\182pfe und ordnet sich darunter ein, statt sie zu \195\188berdecken. Faction Framework beh\195\164lt seinen Platz.",
            "Fraktionen aus Faction Framework erscheinen jetzt mit in der Liste, gekennzeichnet mit FF. Bearbeiten kann Aegis sie nicht, das macht der andere Mod selbst.",
            "Spielerbereich abschaltbar: in den Sandbox-Einstellungen unter Aegis Ereignisse steht ein Schalter, der das blaue Panel serverweit ausblendet. Das Admin-Panel bleibt davon unber\195\188hrt.",
            "Zonen komplett neu: Grenze bearbeiten setzt jetzt Rechteck an Rechteck, der Editor bleibt dabei offen und alles wird EINE Zone. Fl\195\164che malen bleibt f\195\188r einzelne Kacheln.",
            "Zonen verschmelzen: zwei Zonen desselben Besitzers werden bei der n\195\164chsten Bearbeitung zu einer, sobald sie sich ber\195\188hren. Angesetzte Fl\195\164chen m\195\188ssen anschlie\195\159en, lose Fetzen lehnt der Editor sofort ab.",
            "Zonen laufen fl\195\188ssiger: Umrisse als lange Linien statt Kachelkanten, unver\195\164nderte Teile bleiben beim Umbau stehen, veraltete Rechtecke r\195\164umt der Client von selbst weg.",
            "Kits pro Rolle freischaltbar: das Donator-Kit sieht nur der Donator, gepr\195\188ft wird auf dem Server. Neuer Monats-Modus neben Einmalig und Abklingzeit.",
            "Discord-Booster (optional, braucht einen EIGENEN Discord-Bot): der Bot gibt einen Code aus, den der Spieler einl\195\182st, der Status l\195\164uft bis Monatsende. Ohne gesetzten Schl\195\188ssel bleibt der Bereich unsichtbar. Ein Bot wird nicht mitgeliefert, das Rechenverfahren f\195\188r die Codes gibt es auf Anfrage.",
            "Kopftag h\195\164ngt jetzt an der Rolle und l\195\164sst sich dort jederzeit an und ausschalten, die \195\132nderung greift sofort bei allen Tr\195\164gern.",
            "Safehouse-Liste auf der Fraktions-Seite je Spieler aufklappbar statt einer langen Liste aller Rechtecke.",
            "Todes-Berichte: jeder Spielertod wird vollst\195\164ndig dokumentiert (Angreifer, Waffe, Wunden, Umgebung), neuer Bereich Todesf\195\164lle im Protokoll.",
            "Folgen: Kamera heftet sich an einen Spieler, \195\188ber beliebige Entfernung.",
            "Fenstergr\195\182\195\159e frei ziehbar, Gr\195\182\195\159e wird gespeichert, Inhalt l\195\164uft beim Ziehen mit. Seiten rollen, wenn das Fenster zu klein wird.",
            "Seiten-Reihenfolge per Ziehen \195\164nderbar, mit Schloss in der Seitenleiste. Minimieren als kleine frei bewegliche Leiste.",
            "Durchscheinende Vorschau vor dem Wiederherstellen abgerissener Bauten, die Karte dazu ist frei verschiebbar.",
            "Entfernungs-Sperre der Spieler-Aktionen entfernt, fast alles wirkt jetzt \195\188ber jede Distanz.",
            "Rechte: Wer einen Bereich zugewiesen bekommt, darf alles darin. Rollen vergeben ohne Admin-Status keine Admin-Rechte mehr.",
            "Warenkorb bleibt beim \195\132ndern der Fenstergr\195\182\195\159e erhalten, Eintr\195\164ge lassen sich per Klick wieder entfernen.",
            "Hilfe und Changelog direkt im Panel.",
            "Neu f\195\188r deine Spieler: der Spielerbereich, ein eigenes blaues Panel f\195\188r jeden auf dem Server. \195\156ber Rollen vergibst du dort Kit-Zugang und Zonen-Kacheln. Was er kann, steht im Changelog dieses Panels.",
            "Absturz behoben, der beim Aufheben oder Verschrotten von M\195\182beln den Server-Handler zerlegte. Gepr\195\188ft auf 42.20.",
            "Diverse Fehlerbehebungen, unter anderem beim Zeit-Setzen und der Rechte-Pr\195\188fung.",
        } },
        { version = "1.1", date = "Juli 2026", points = {
            "Fahrzeug-Detail-Fenster mit Tank, Schl\195\188sseln, Teilen, Farbe und Zustand.",
            "Fahrzeug-Teleport samt Anh\195\164nger und Ladung.",
            "Sprite-Inspektor und Bau-Pinsel mit eigener Palette.",
            "Bau-Protokoll mit Wiederherstellen, auch f\195\188r Treppen und Garagentore.",
            "Tragelast und Stauraum bis 1000, Vollheilung kuriert Bisse.",
            "Admin-Tag manuell schaltbar, Rollen-Zuweisung mit Namens-Tag in Rollenfarbe.",
            "Kompatibilit\195\164t mit FactionFramework.",
        } },
        { version = "1.0", date = "Juli 2026", points = {
            "Erste Ver\195\182ffentlichung: Kr\195\164fte, \195\156bersicht, Spieler, Gegenst\195\164nde, Fahrzeuge, Welt, Zonen, Horde, Server, Sandbox, Protokoll, Rollen, Tiere, Fraktionen, Werkzeuge.",
        } },
    },
}

AegisHelpContent.EN = {
    help = {
        { title = "Getting started", lines = {
            "Open the panel with the golden crest button next to the equipment bar in the top left, or press F7. The key can be changed under Options in the Mods tab.",
            "Only real server admins see the golden panel. Which pages an individual admin may use is set on the Roles page.",
            "F7 only collapses the window: every list, selection and input survives, F7 brings everything back unchanged. Only the X in the top right really closes the panel.",
            "Grab the window by its header with the mouse held down and drag it anywhere on the screen.",
            "The minus button turns the panel into a small movable bar. The plus on the bar brings the panel back at that spot.",
            "The small dot triangle in the bottom right resizes the window to any size you like. The size survives restarts. If the window gets too small for a page, a scroll bar appears on the right.",
            "At the bottom of the sidebar sits a small padlock: open it and drag the entries to a new spot with the mouse held down, the golden line shows where they will land. Close the padlock again to fix the order.",
            "This help window can also be moved by its header and resized in the bottom right to any size.",
        } },
        { title = "Powers", lines = {
            "Every card is a switch that acts immediately: god mode (no damage), invisible (zombies and players cannot see you), walk through walls, fast movement, instant actions, unlimited carry, unlimited endurance, night vision and more.",
            "The spectator switch in the top right enables god mode, invisible, walk through walls and fast movement in one go. Ideal for observing unnoticed.",
            "All powers off resets every switch at once, spectator included.",
            "Admin tag shows or hides the red admin marker above your head. The choice survives restarts.",
        } },
        { title = "Overview", lines = {
            "The start page is a board of cards. The button at the top right enters rearrange mode: drag cards to another spot, the cross on a card removes it, the plus tile at the bottom opens the catalog.",
            "The catalog holds everything you are allowed to see: the quick power switches, heal and care, your action log, the clock, the server pulse, the restart countdown, weather, your role, the feature switches, the online players and the Time and weather card.",
            "On top of that there is a tile for every panel page, from world through tools and zones to the server options. One click on it takes you straight there, so you can put exactly what you use most on the start page.",
            "The Time and weather card sets the time of day to morning, noon, evening or midnight and ends a running weather event without switching to the world page.",
            "Restore the default in rearrange mode rebuilds the start page the way it looked the first time. Your layout is yours alone and is remembered, other admins keep their own.",
            "Healing here also clears bites, scratches and the zombie infection.",
        } },
        { title = "Players", lines = {
            "The list on the left shows every connected player with their Steam picture. The switch at the top additionally shows every offline player the server has ever seen.",
            "On the right the actions for the selected player. They work at any distance: teleport to, bring to me, heal, satisfy needs, give item, toggle god mode and invisibility for that player.",
            "Follow (ghost symbol) pins your camera to the player no matter how far away. You travel along invisibly. Clicking follow again ends it.",
            "Only two things need the player close to you: open stats (the big stats window) and the 3D preview on the left. If the player is too far away the preview shows out of range.",
            "Warn and mute ask for a reason. Kick removes the player from the server immediately. Ban and temp ban require a reason that lands in the log. Unban only appears for players who are actually banned.",
            "The relations radar shows who the player spent the most time with over the last seven days. Carry weight sets their maximum carry capacity up to 1000.",
        } },
        { title = "Items", lines = {
            "The search field at the top filters instantly while you type part of a name. The category box next to it narrows the list further.",
            "The amount buttons (1, 5, 10 and so on) decide how many are handed out. The target is either your own inventory or a selected player.",
            "At the bottom the panel remembers your recently given items as quick access buttons.",
        } },
        { title = "Vehicles", lines = {
            "Pick a vehicle, align it with the rotate buttons in the preview, then spawn here: the vehicle appears in front of you facing exactly that way.",
            "Double click a vehicle in the world (or use the panel button) to open the detail window: fill the tank, charge the battery, put a key into the ignition, repair every single part, change color and condition.",
            "Vehicle teleport moves the vehicle including trailer and full cargo to you, or you to it.",
        } },
        { title = "World", lines = {
            "Time of day: the four presets (morning, noon, evening, midnight) or the slider set the time immediately for everyone. IG date and IG time change the whole calendar.",
            "Weather: thunderstorm, tropical storm and blizzard build up over roughly one game hour, the slider sets the duration. Stop weather ends everything immediately. Instant rain works without buildup.",
            "The weather designer at the bottom mixes custom weather from clouds, rain, fog and wind, with an optional thunder cadence. Save as preset stores the mix permanently under its own name.",
            "Events: thunderclap, gunshot and fireworks create sounds at your position, the noise slider sets the radius. Zombies react to it.",
        } },
        { title = "Zones", lines = {
            "This page manages safehouses and extends them beyond the vanilla limits. However many pieces a zone is made of, it always counts as one whole.",
            "New zone creates a safehouse for any player: pick the owner, then drag rectangles or paint the area. Several rectangles can be put together before applying, every further one has to connect to the shape.",
            "Edit bounds attaches further rectangles to a zone: dragging with the left button attaches, dragging with the right button removes attached area again, the original zone stays protected. The editor stays open until Enter applies everything at once or ESC discards. The preview always shows the resulting overall shape.",
            "Paint area is the fine tool for single tiles along the border: left click paints, right click erases, on the existing area too. This is the way to shrink a zone. Painting requires standing inside the zone.",
            "Areas of the same owner that touch become one zone. Show zones draws all zones visibly into the world. Backup stores a copy of the whole zone that can be restored later, for example after griefing.",
        } },
        { title = "Horde and animals", lines = {
            "Horde: set count and radius, the zombies spawn around the chosen position. Clean up removes zombies within the radius.",
            "Siege makes a horde march toward a point from a distance, announced by a gunshot. The details (waves, count, distance) live in sandbox under Aegis Events.",
            "Animals: choose species and breed, rotate in the preview, then place in the world, exactly like vehicles.",
        } },
        { title = "Server", lines = {
            "Restart: the minute buttons start a countdown every player sees as a banner. Time and date schedule a restart for a fixed moment, the automatic mode repeats it at the chosen interval.",
            "How the restart works: the server cannot stop itself, the game does not allow it. At the deadline it hands the command to an authorized player instead, meaning anyone whose role permits shutting down, and it retries every minute until it works or gives up after ten minutes. So someone authorized has to be online at the deadline. Bringing the server back up is your host panel's job, restart-after-stop should be enabled there. Every attempt is written to the server console, including how many authorized players are online at that moment.",
            "Save world writes the whole save right away.",
            "Power grid and water grid switch the supply for the entire map on or off.",
            "Directing: ready made shows at your position with one click, such as storm show, siege, helicopter alarm, airdrop, firestorm or creeping danger.",
            "The feature switches decide what players may do: player area, player claims and player kits. The server enforces it, this is not just a display. The same switches live in the sandbox and as a card on the start page.",
            "Server branding next to them sets the name both panels show in their header. Leave it empty to get AEGIS back.",
            "Announce sends a message to the chat of every player.",
        } },
        { title = "Server options", lines = {
            "A page of its own with every setting of the server INI, grouped by topic and searchable. The default value sits under each name.",
            "You collect changes and send them with Apply. They take effect right away and are written to the INI at the same time. A clock marker flags options that only take hold after a restart.",
            "Other admins see your change only after a reconnect or after /reloadoptions. That is how the game works, not a fault of the panel.",
            "Password, RCON and the Discord fields only show as hidden and without a value: the server never sends them to a client. Ports, map and the player id are locked for good.",
            "Mods and workshop items only open after two explicit warnings and stay open until the panel is closed. A typo there can silently ruin the server.",
            "Server options is its own area in the roles: you can hand an admin the server page and still keep the INI settings from them.",
        } },
        { title = "Build tools", lines = {
            "Build brush: pick a piece from the palette and drag across tiles with the mouse held down. R rotates. Floors fill the area, walls follow the dragged line. Capture your own pieces with the sprite inspector.",
            "Sprite inspector: shows the internal name of any clicked object in the world and can add it to the brush palette.",
            "Build radar: hovering built objects shows who built them and when.",
            "Build log: every build and demolition with time, player and place. Clicking a row offers a jump to the place. For demolitions the restore button first shows a translucent preview of the demolished structure at its old spot, only your confirmation really rebuilds it. Stairs and garage doors are rebuilt completely with all parts.",
            "Clear area: drag a rectangle, the first pass removes only vegetation, a second pass on the same area removes everything down to the floor. Undo restores the last clearing.",
        } },
        { title = "Log and deaths", lines = {
            "The log stores every admin action permanently, ordered by areas: actions, bans, kicks, warnings, chat moderation, admin and player sessions, construction and deaths. Pick the area on the left, the entry in the middle, the full content appears on the right.",
            "Deaths: every player death automatically produces a detailed report: who or what killed (including the weapon), all injuries, infection state, place including the room, how many zombies were around and which players stood nearby. All admins get a short notice the moment it happens.",
        } },
        { title = "Roles", lines = {
            "Roles decide which panel pages an admin may use: create a role, tick the allowed areas, then assign it to a player below.",
            "How to give someone limited admin access. One: set their vanilla level to observer, /setaccesslevel \"name\" observer. Aegis only shows the panel to levels that carry the admin tool, observer is the lowest one that works, and on its own it grants no Aegis rights. Two: create a role here, tick only the areas they should have, save. Three: assign the role to the player below.",
            "Leave the roles area unticked and they cannot change any permissions, not even their own. Only the vanilla admin level keeps role management no matter what, so nobody can lock themselves out.",
            "Hovering an area tells you which pages it covers, as soon as it is more than one.",
            "Server options and sandbox are areas of their own. Handing out the server page does not automatically grant the INI settings or the sandbox sliders.",
            "Important: a role does not make anyone an admin. Someone who is not a server admin gains no admin rights from a role, only the coloured name above their head.",
            "The role colour is the colour of the name tag. Before assigning, a prompt states in plain words whether the role only brings the name tag or real rights.",
            "The head tag inherits the abilities of the previous role: an admin with a tag stays an admin in function. To check something from a normal player's view, use a second account.",
        } },
        { title = "Player panel (blue)", lines = {
            "The blue panel is the counterpart for normal players. Everyone who joins the server gets it automatically as their own blue button, admins included, no role assignment needed.",
            "Roles only hand out the extras: on the Roles page you set claim tiles (0 means no own zone claim) and kit access per role. That is all a role does to the player panel, it can never be switched off. Donators are handled elegantly through own roles with a bigger budget.",
            "The player sees: their character in 3D with vitals and favourite weapon, their statistics (deaths, zombie and bandit kills, kilometres walked, longest life, playtime) including the server leaderboard, their health with bandaging right inside the panel, their own vehicles with condition bars and nav, their safehouse with an expiry warning, the kits to collect, their own zone claim and a distress call button.",
            "The distress call reaches every admin currently online with the player's name, position and message. A two minute cooldown prevents spam.",
            "Kilometres, deaths and bandit kills count from the moment this version is installed. Playtime is calculated retroactively from the session logs.",
            "Note for the operator: vanilla safehouse claiming (server option PlayerSafehouse) should be off when using the player panel's own claims, otherwise two competing paths exist.",
        } },
        { title = "Kits", lines = {
            "On the kits page you build packages players can collect in the blue panel: give it a name, add items through the search, set the amount, pick the mode (one time, daily, weekly, monthly).",
            "Roles are optional. If you select NO role, the kit is open and every player on the server can collect it, including anyone without a role at all. That is the normal case for a starter package.",
            "Only once you tick one or more roles does the kit narrow down to their holders. The blue panel then shows a small tag behind the kit name telling the player which role or booster status grants it.",
            "The claim is stored per player, death and rejoining change nothing about it. Only Reset claims on the kit lifts it again.",
            "The kits area can be delegated to individual admin roles on the roles page. Whether players reach kits at all is decided by the Player kits switch on the server page.",
        } },
        { title = "Practical notes", lines = {
            "Right clicking the world map (key M) offers teleport here.",
            "Feedback appears as a golden short notice at the top of the panel. If the panel is hidden at that moment (during a preview for example), the notice appears as floating text on your character instead.",
            "If a list looks empty, the round arrow button reloads it.",
            "Almost every action lands in the log. If something did not work, that is the first place to look.",
        } },
    },
    changelog = {
        { version = "2.3.5", date = "August 2026", sections = {
            { title = "New", points = {
                "The number of remembered vehicles per player is a sandbox option now (Aegis Events, \"Remembered vehicles per player\"). It used to be a fixed five. 0 turns remembering off, the maximum is 20. Where Knox Claim runs, its own limit still counts. Lowering the value takes nothing away: vehicles already remembered stay, only new ones are refused.",
            } },
            { title = "Fixed", points = {
                "Percent signs in the texts brought in line with 42.20.1. The hotfix of August 5th changed how the symbol is handled in translation files, a displayed percent has to be written twice now. Four texts in all 13 languages were affected, among them \"Condition: 95%\" on the health page and the backup progress.",
                "The scheduled restart ran out: the timer counted down, the chat ended on \"Unknown command restart\" and the server stayed up. The rate at which the server repeated the order runs on game time and fired roughly every seven seconds on short days. That repeat always beat its own safety net, which should have sent the command that really exists eight seconds later. The server now waits real minutes between attempts, and a second attempt goes straight to the working command.",
            } },
        } },
        { version = "2.3.4", date = "August 2026", sections = {
            { title = "New", points = {
                "The safehouse page of the player panel now shows the way home (distance and heading, live) and offers the vanilla respawn-in-safehouse switch where the server allows it.",
                "On servers running Knox Claim the vehicles page of the player panel now lists the vehicles you registered there, 3D preview included. Distance, navi and condition bars appear once the car is loaded near you. Releasing still happens in the Knox Claim window, which is why the forget button stays off for those entries.",
            } },
            { title = "Fixed", points = {
                "The automatic restart could fizzle: the server cannot quit itself and hands the command to an authorized admin client, but it did so exactly ONCE. If nobody was ready to receive in that second, all the warnings ran and nothing happened (community report). The server now knocks again every minute until the restart really lands, gives up after ten minutes with a log entry, and both the handover and the execution are written to the log from now on.",
                "Remembered vehicles turned into empty husks after a server restart: no position, no bars, no navi. The ledger hung on the vehicle number, which the game hands out anew after every restart. Saving now attaches a fixed tag to the vehicle that server and panel always find it by, the number heals itself along the way. Entries from earlier versions without the tag stay husks, forgetting and re-saving once upgrades them.",
                "The 3D preview in the player panel was reworked: it starts fresh on every vehicle switch, cross fades without a flicker, and the vehicle sits lower and better in the frame. Zoom and shift-drag apply to the selected vehicle and reset on a switch. Some modded vehicles are built off centre around their model origin and therefore sit off centre in EVERY preview the game has, only panning by hand helps there.",
                "The way home on the safehouse page is golden and clickable now: one click points the screen arrow at your home, a second turns it off.",
                "The button under the vehicle list is called Release everywhere now: a remembered vehicle leaves the list, a Knox Claim vehicle is truly released. And arriving at home no longer greets you with vehicle found.",
                "Respawning in the safehouse placed you next to the house instead of inside: the game swaps width and height of the zone when computing the spot, which lands outside on elongated zones. Aegis computes the spot correctly itself now.",
                "Vehicles from Knox Claim lost distance, heading, the condition bars and the part list after a relog. They were matched by the vehicle's net number, and the game hands out new ones after every restart. They are now found by the claim tag on the vehicle itself.",
                "Aegis tried to set a capacity on the body inventory twice a second whenever a carry weight was assigned. That filled the server log with warnings and did nothing. The body is served through the proper path only now.",
                "Assigned storage capacity only worked up to 100 for ordinary players even though the panel showed the full value (community report). On crates it was easy to miss because their default sits below that, on counter tops and floating cabinets nothing worked at all since they already sit at the limit. The game clamps world containers hard when reading them, and the check while moving items bypasses our own value. Until now only admins had the detour through the server, now everyone takes it as soon as the container has an assigned capacity. The server still checks range, item and exactly that value.",
                "Restart at a fixed time and the automatic anchor calculated in world time instead of your local time: entering 00:11 got you a restart at 02:11. Input and display now run on your local clock.",
                "Help and changelog kept the old line wrap when the window was shrunk and the text vanished under the scrollbar on the right. The wrap now checks before every draw that it still matches the window width.",
                "The mod filter in the item catalog is always visible now. Without any item mods installed it hid itself and left a hole in the filter row that looked like something broke. It simply reads Project Zomboid then.",
                "The hint text on the empty vehicles page was wider than the column and cut off at the front.",
                "The remember button for vehicles did not disappear on servers running Knox Claim after all. The server sent the flag correctly, but the player panel rebuilds its state field by field and did not know the new field, so it was dropped on arrival without a word. From 2.3.3, fixed right away.",
                "The fixed powered by Aegis line in the footer is gone, in both panels. It only took up space there.",
            } },
        } },
        { version = "2.3.3", date = "August 2026", sections = {
            { title = "New", points = {
                "Filter items by source mod (community request): next to the category filter you can now pick a mod, and mod items show in small print behind the name where they come from. The search finds mod names too. Without mods the filter stays hidden.",
                "Plays along with Knox Claim: where that mod runs on the server, it owns the vehicles. Aegis then pulls its own remember button in the player panel, so two lists are not kept side by side with each one knowing only its half. The forget button stays so older entries can still be removed. Without Knox Claim nothing changes.",
            } },
            { title = "Fixed", points = {
                "PERMISSION HOLE: on servers with custom rank roles (head tags like \"Veteran\") everyone holding such a role counted as staff and got the full panel, without the admin tool and without an assigned Aegis role. Aegis treated any named access level as staff when in doubt, and since an Aegis role only narrows access and never grants it, that meant full access, enforced server side as well. Only a role that provably carries the admin tool counts now. The four vanilla levels admin, moderator, gm and observer still get in regardless of the role registry, and if the registry cannot be read at all the old way out remains so no real admin locks themselves out. Every verdict is now written to the server log with its reason.",
                "Setting a carry weight also dragged the hard pickup cap onto the same value. The game keeps two limits apart: past your carry weight you are overencumbered, and only at the hard cap (fixed at 50) does it refuse picking up entirely. Anyone given a small carry weight could not pick up anything once at the limit, and the value came back after death through the stored list. Below 50 normal overloading works again, only larger values keep raising the hard cap. Affected characters are cleaned up on their next login by themselves.",
                "The need sliders in the values window now take effect while you drag instead of only when you let go. The value travels to the server four times a second without raising a notice per step, and the log still records only the value you release on.",
                "The safehouse card in the player panel stayed empty although the zone was listed on the zone page of the admin panel. It read the list on the player's own machine, and a zone created on the server does not have to be in that copy. It now asks the server, the way the zone page always has, and keeps itself up to date while the page is open.",
            } },
        } },
        { version = "2.3.2", date = "August 2026", sections = {
            { title = "New", points = {
                "Set needs freely (community request): in the values window the new button at the top right opens sliders for hunger, thirst, fatigue, endurance, stress, panic, boredom, unhappiness, pain, sickness, intoxication and wetness. The panel could only reset all of them at once before, now you set each one individually, upwards as well. The bounds come from the game itself and the value is only sent when you let go of the slider.",
                "The help now explains step by step under Roles how to give someone limited admin access.",
            } },
            { title = "Fixed", points = {
                "PERMISSION HOLE: anyone on a vanilla level that carries the admin tool, which includes observer, gm and moderator, could always open the roles page and grant themselves every area. The lockout protection now keys on the vanilla RolesWrite capability, which only the admin level has. A real admin still cannot lock themselves out, everyone else needs the roles area granted explicitly in their Aegis role.",
                "The Organized trait stopped working in every container an admin had ever given a capacity to. The game adds that bonus on top of the capacity, and our own value swallowed it, so affected players could not store anything once the plain capacity without the bonus was reached. Organized and Disorganized now apply to assigned values as well.",
                "The scroll bar of the overview sat on top of the resize grip in the bottom right corner and could not be grabbed once the window was small enough to scroll.",
            } },
        } },
        { version = "2.3.1", date = "August 2026", sections = {
            { title = "Fixed", points = {
                "The golden button and the blue player button were missing entirely with some mod combinations. Aegis places itself below every other icon in the equipped item bar, but it also measured elements that are not icons at all and slid off the bottom of the screen. Only icon sized neighbours count now, and the button always stays visible.",
                "A mod that takes over the equipped item bar can no longer make the Aegis buttons disappear. If they are missing, they are put back.",
                "Errors from other mods in the inventory are no longer reported as Aegis errors. Aegis no longer hooks into the vanilla backpack bar for that.",
                "Aegis no longer writes diagnostic lines to the log when a bag is too full.",
            } },
        } },
        { version = "2.3", date = "July 2026", sections = {
            { title = "New", points = {
                "Hide pages: with the padlock at the bottom of the sidebar open, every entry shows an eye. Hide what you never use, the plus next to it brings pages back. Applies only to you and changes no rights.",
                "The overview is a board now: the edit button at the top right enters rearrange mode, cards can be dragged, removed and added from the catalog. Every admin keeps their own layout, and without touching it everything looks as before.",
                "The catalog reaches across every area you have access to: next to online players and the feature switches you can drop in a tile for any page, from world through tools and zones to the server options. One click on it takes you there.",
                "New Time and weather card: morning, noon, evening and midnight right on the overview, plus the button that ends a running weather event.",
                "Rearrange mode has a Restore the default button next to the edit button. It rebuilds the overview the way it looked the first time you opened it.",
                "New Server Options page: every server INI setting searchable and editable right in the panel, with markers for what only takes effect after a restart. Changes apply live and are written to the INI right away. Mods and workshop items are locked and can only be edited after a double warning, at your own risk.",
                "Your server name instead of AEGIS: set it on the server page, both panels show it to every player, with powered by Aegis fixed underneath. Leave it empty to get AEGIS back.",
                "New switch card on the server page: player area, player claims and player kits can be turned on and off there and in the sandbox, live and for everyone. The server enforces it, not just the display.",
                "Kits with no role attached can now really be claimed by everyone. Players without a role never reached the kits page before, which made the role feel mandatory.",
                "New crafting cheat next to the build cheat: recipes craftable without materials, skills or a workstation. If you also want unknown recipes in the list, turn on Know all recipes as well, the two switches are independent. The build cheat stays as it was.",
                "The player area shows time and date only with a worn watch: any watch brings the time, only a digital one adds the date.",
                "Server options became an area of its own in the roles: you can hand an admin the server page and still keep the INI settings from them. Existing roles keep their access, there is nothing to add by hand.",
                "Adding a trait in the values window now explains on hover what the trait does, along with its points and the reason when the row is red.",
            } },
            { title = "Fixed", points = {
                "Vehicle values in the player area are live: refuelling and repairing next to the car shows up right away, not half a minute later.",
                "Server branding now sits to the right of the feature switches instead of below them, that side of the page was empty.",
                "The value column of the server options no longer runs into the scroll bar.",
                "With many pages on a short window the sidebar no longer runs across the footer. If the list still does not fit after packing, the wheel scrolls it.",
            } },
        } },
        { version = "2.2", date = "July 2026", sections = {
            { title = "New", points = {
                "Player values are now an Aegis window instead of the vanilla one. It replaces the old Player stats screen behind the same button on the players page, and it can be moved and resized like every other Aegis window.",
                "Everything in it changes live. Traits, profession, names, weight, skill levels and experience take effect right away on the target, no reconnect needed. The vanilla screen edited your own copy of that player, which could roll back skills they had learned since joining.",
                "Skills come with level, experience and the boost the character really gets, and you can grant experience, raise or lower a level, or set one outright.",
                "Every trait sits in its own small box with a cross, one click removes it. When adding one, the list marks in red what collides with a trait the player already has.",
                "Names cover forename, surname and the display name, with a way back to the automatic one. A weight trait pulls the weight along with it, otherwise the server would undo the change within minutes.",
            } },
            { title = "Fixed", points = {
                "Furniture from the build brush can be cleared again. It used to be placed in a way that made the engine refuse to remove it, so neither clearing nor the sledgehammer worked on it.",
                "A floor placed with the build brush can be cleared too. Map floors stay protected, removing those would tear holes into the world.",
                "Saving role rights no longer reports an error when a member of that role is offline.",
                "Scrolling a card no longer leaves old rows standing behind the controls.",
            } },
        } },
        { version = "2.1", date = "July 2026", points = {
            "Reset kit claims: a button on the selected kit drops every claim on it and shows how many players are affected. Those players can collect the kit again right away, no server restart.",
            "The clock symbol in the editor header opens the list of players holding a claim, with the time they claimed it. From there you reset individual players when only one of them needs their kit.",
            "At the bottom of that list, set apart, sits Wipe all claims. It removes the claims on every kit for every player and asks for a typed reason, which goes into the log.",
            "It exists for starting over with a fresh world: claims live apart from the world save and therefore survive a reset. Otherwise every kit still counts as collected and nobody gets theirs.",
            "If the claim list could not be read completely, every reset stays greyed out, so a partial list never gets wiped.",
            "Follow runs smoothly now: you glide along with your target and keep a fixed distance behind it, instead of standing still for a moment and then lurching forward.",
            "While following, the camera stays on the right floor, stairs used to throw it off by a whole storey. On the ground floor you no longer hover just above the ground either.",
            "Confirmation windows now fit their text: they grow wider and long sentences wrap properly. In some languages half the sentence used to sit unreadable on the darkened background.",
        } },
        { version = "2.0", date = "July 2026", points = {
            "Plays nice with other sidebar mods: Aegis spots foreign buttons and lines up below them instead of covering them. Faction Framework keeps its spot.",
            "Factions from Faction Framework now show up in the list, marked with FF. Aegis cannot edit them, that mod handles them itself.",
            "Player area can be switched off: a toggle in the sandbox settings under Aegis Events hides the blue panel server wide. The admin panel is untouched.",
            "Zones rebuilt: editing bounds now attaches rectangle after rectangle, the editor stays open and everything becomes ONE zone. Painting is still there for single tiles.",
            "Zones merge: two zones of the same owner become one on the next edit as soon as they touch. Attached areas have to connect, loose pieces are refused right away.",
            "Zones run smoother: outlines as long lines instead of tile borders, unchanged parts stay put during a rebuild, stale rectangles are cleaned up by the client itself.",
            "Kits can be tied to roles: only the donator sees the donator kit, enforced on the server. New monthly mode next to once and cooldown.",
            "Discord boosters (optional, needs your OWN Discord bot): the bot hands out a code, the player redeems it, the status runs until the end of the month. Without a key set the section stays hidden. No bot is provided, the code recipe is available on request.",
            "Head tag now belongs to the role and can be switched on or off there at any time, the change applies to every wearer instantly.",
            "Safehouse list on the factions page groups per player instead of one long list of every rectangle.",
            "Death reports: every player death fully documented (attacker, weapon, wounds, surroundings), new deaths area in the log.",
            "Follow: pin the camera to a player at any distance.",
            "Window freely resizable, size remembered, content follows the drag. Pages scroll when the window gets too small.",
            "Page order changeable by dragging, with a padlock in the sidebar. Minimize turns into a small movable bar.",
            "Translucent preview before restoring demolished builds, its card is draggable.",
            "Range lock on player actions removed, almost everything works at any distance.",
            "Rights: whoever gets an area assigned may do everything in it. Roles without admin status no longer grant admin rights.",
            "The cart survives a window resize, entries can be removed with a click.",
            "Help and changelog inside the panel.",
            "New for your players: the player area, a blue panel of their own for everyone on the server. Roles hand out kit access and claim tiles. What it does is listed in that panel's changelog.",
            "Fixed a crash that broke the server handler when picking up or scrapping furniture. Tested on 42.20.",
            "Various fixes, among them time setting and the rights check.",
        } },
        { version = "1.1", date = "July 2026", points = {
            "Vehicle detail window with fuel, keys, parts, color and condition.",
            "Vehicle teleport including trailer and cargo.",
            "Sprite inspector and build brush with custom palette.",
            "Build log with restore, stairs and garage doors included.",
            "Carry weight and container capacity up to 1000, full heal cures bites.",
            "Admin tag manually switchable, role assignment with name tag in role color.",
            "FactionFramework compatibility.",
        } },
        { version = "1.0", date = "July 2026", points = {
            "First release: powers, overview, players, items, vehicles, world, zones, horde, server, sandbox, log, roles, animals, factions, tools.",
        } },
    },
}

-- player mode: the manual of the blue player panel, written strictly from
-- the player's point of view, changelog only with player visible points

AegisHelpContent.PLAYER_DE = {
    help = {
        { title = "\195\156bersicht", lines = {
            "Das blaue Panel ist dein pers\195\182nlicher Bereich auf dem Server. Du \195\182ffnest es \195\188ber den blauen Knopf neben der Ausr\195\188stungsleiste oben links.",
            "Die Startseite zeigt deinen Charakter als drehbare 3D-Figur, daneben deine wichtigsten Werte und deine Lieblingswaffe.",
            "Das Panel hat jeder auf dem Server automatisch, vom neuen Spieler bis zum Admin. Extras wie der Zonen-Claim oder Kits h\195\164ngen von deiner Rolle ab: fehlt so ein Bereich, ist er f\195\188r deine Rolle nicht freigeschaltet.",
        } },
        { title = "Statistiken und Bestenliste", lines = {
            "Die Statistik-Seite sammelt deine Laufbahn: Tode, get\195\182tete Zombies und Banditen, gelaufene Kilometer, dein l\195\164ngstes Leben und die gesamte Spielzeit.",
            "Darunter steht die Server-Bestenliste. Dein eigener Eintrag ist farbig hervorgehoben, so siehst du sofort, wo du stehst.",
            "Kilometer, Tode und Banditen-Kills z\195\164hlen ab dem Einbau des Panels auf dem Server. Die Spielzeit wird auch r\195\188ckwirkend aus den Sitzungs-Protokollen berechnet.",
        } },
        { title = "Gesundheit", lines = {
            "Die Gesundheits-Ansicht zeigt deinen Zustand auf einen Blick: Verletzungen je K\195\182rperteil, Blutungen und alles, was gerade versorgt werden will.",
            "Verbinden geht direkt auf dieser Seite, ohne den Umweg \195\188ber das normale Gesundheits-Fenster. Voraussetzung ist wie immer passendes Verbandsmaterial im Gep\195\164ck.",
            "So erkennst du fr\195\188h, wo es brennt, bevor aus einem Kratzer ein echtes Problem wird.",
        } },
        { title = "Safehouse", lines = {
            "Die Safehouse-Seite zeigt dein Zuhause: Lage, Gr\195\182\195\159e und wer dazugeh\195\182rt.",
            "Droht dein Safehouse zu verfallen, warnt dich das Panel rechtzeitig. Nach einer l\195\164ngeren Pause lohnt hier der erste Blick.",
        } },
        { title = "Eigene Fahrzeuge", lines = {
            "Die Fahrzeug-Seite listet deine eigenen Fahrzeuge mit Zustand und Standort.",
            "Unter der 3D-Vorschau zeigen Zustandsbalken auf einen Blick, wie gut dein Wagen noch beieinander ist.",
            "Das Navi markiert das gew\195\164hlte Fahrzeug, damit du es in der Welt wiederfindest. Praktisch, wenn du nach einer wilden Flucht nicht mehr wei\195\159t, wo der Wagen steht.",
            "Das Navi l\195\164uft dabei einfach nebenher und blockiert keine anderen Aktionen: k\195\164mpfen, looten und bauen gehen ganz normal weiter.",
        } },
        { title = "Zonen-Claim", lines = {
            "Mit dem Zonen-Claim sicherst du dir ein gesch\195\188tztes St\195\188ck Land direkt an deinem Haus, ganz ohne Admin.",
            "Wie viele Kacheln du beanspruchen darfst, legt deine Rolle fest, ohne Rolle sind es keine. Das Panel zeigt dein Budget und wie viel davon schon belegt ist.",
            "Zum Setzen musst du bei deinem Haus stehen. Innerhalb deiner Zone gelten danach die Schutzregeln des Servers.",
        } },
        { title = "Kits abholen", lines = {
            "Kits sind fertig gepackte Pakete der Admins, etwa ein Starter-Paket oder Event-Belohnungen.",
            "Jede Karte zeigt, was drin ist und ob das Kit einmalig oder mit Abklingzeit verf\195\188gbar ist. Abholen legt den Inhalt direkt in dein Inventar.",
            "Einmalige Kits bleiben abgeholt, auch nach Tod und Wiedereinstieg.",
        } },
        { title = "Notruf", lines = {
            "Der Notruf erreicht alle Admins, die gerade online sind, mit deinem Namen, deiner Position und deiner Nachricht.",
            "Beschreibe kurz, was passiert ist, dann k\195\182nnen die Admins direkt zu dir kommen. Nach einem Notruf gilt eine kurze Sperre gegen Spam.",
            "Der Notruf ist f\195\188r echte Probleme gedacht, etwa Griefer oder festgefahrene Situationen, nicht f\195\188r Wunschlisten.",
        } },
        { title = "Fenster und Bedienung", lines = {
            "Das Panel l\195\164sst sich am Kopfbereich mit gedr\195\188ckter Maustaste frei \195\188ber den Bildschirm ziehen.",
            "Der blaue Knopf \195\182ffnet und schlie\195\159t das Panel, das X im Fenster schlie\195\159t es ebenfalls.",
            "Wo unten rechts ein kleines Punkte-Dreieck sitzt, ziehst du das Fenster daran auf jede gew\195\188nschte Gr\195\182\195\159e.",
            "In der Seitenleiste unten sitzt ein kleines Schloss: ge\195\182ffnet ziehst du die Eintr\195\164ge mit gedr\195\188ckter Maustaste an eine neue Stelle, die blaue Linie zeigt dabei die Einf\195\188gestelle. Danach das Schloss wieder schlie\195\159en.",
            "Auch dieses Hilfe-Fenster l\195\164sst sich am Kopf verschieben und unten rechts an der Punkte-Ecke auf jede Gr\195\182\195\159e ziehen, die Gr\195\182\195\159e bleibt gespeichert.",
        } },
    },
    changelog = {
        { version = "1.2.1", date = "August 2026", sections = {
            { title = "Behoben", points = {
                "Deine Safehouse-Karte blieb leer, obwohl du ein Grundst\195\188ck hattest. Sie hat die Zonen auf deinem eigenen Rechner nachgeschlagen, und eine Zone, die auf dem Server entsteht, muss dort nicht ankommen. Sie fragt jetzt den Server und zieht bei offener Seite von selbst nach.",
                "L\195\164uft auf dem Server der Mod Knox Claim, verwaltet der die Fahrzeuge. Der Knopf zum Merken eines Fahrzeugs verschwindet dann hier, damit du deine Wagen nicht an zwei Stellen pflegen musst. Der Knopf zum Vergessen bleibt, damit du alte Eintr\195\164ge loswirst.",
            } },
        } },
        { version = "1.2", date = "Juli 2026", sections = {
            { title = "Neu hinzugef\195\188gt", points = {
                "Seiten ausblenden: das Schloss unten in der Leiste zeigt im offenen Zustand ein Auge an jedem Eintrag. Was dich nicht interessiert, blendest du aus, das Plus daneben holt es zur\195\188ck.",
                "Kits zeigen ihre Herkunft: hinter dem Namen steht klein, \195\188ber welche Rolle oder den Booster-Status du das Kit bekommst. Offene Kits tragen nichts, die geh\195\182ren allen.",
            } },
        } },
        { version = "1.1", date = "Juli 2026", sections = {
            { title = "Neu hinzugef\195\188gt", points = {
                "Die Admins k\195\182nnen deinen Anspruch auf ein Kit zur\195\188cksetzen, meist beim Start einer frischen Welt. Danach holst du auch ein einmaliges Kit erneut ab. Ob und wann, entscheiden sie.",
            } },
            { title = "Behoben", points = {
                "Best\195\164tigungsfenster passen sich dem Text an: lange Hinweise brechen sauber um, statt rechts hinauszulaufen. Betroffen sind der Zonen-Anspruch und die Fahrzeug-Seite.",
            } },
        } },
        { version = "1.0", date = "Juli 2026", points = {
            "Taste F6 \195\182ffnet und schlie\195\159t den Spielerbereich, der blaue Knopf unten links geht nat\195\188rlich weiter. Die Taste kannst du in den Mod-Einstellungen umlegen.",
            "Neu: dieser Spielerbereich. Ein eigenes Panel f\195\188r dich mit Charakter in 3D, Werten und Lieblingswaffe, f\195\188r jeden auf dem Server.",
            "Statistiken mit Server-Bestenliste: Tode, Zombie- und Banditen-Kills, Kilometer, l\195\164ngstes Leben, Spielzeit.",
            "Gesundheits-Ansicht mit allen Verletzungen auf einen Blick, Verbinden und Desinfizieren direkt hier. Die Figur w\195\164chst mit der Fenstergr\195\182\195\159e mit.",
            "Safehouse-Ansicht mit Warnung vor dem Verfall.",
            "Fahrzeuge: deine Autos mit 3D-Vorschau, Navi-Pfeil zum verlorenen Wagen und jedem Teil nach Kategorie. Ein platter Reifen steht als platt da.",
            "Eigener Zonen-Anspruch am Haus, Umfang je nach Rolle. Er muss am eigenen Haus anschlie\195\159en und darf nichts \195\188berlappen.",
            "Kits zum Abholen, einmalig oder mit Abklingzeit. Du siehst nur die, die f\195\188r deine Rolle freigeschaltet sind.",
            "Discord-Booster: falls dein Server das anbietet, holst du den Code in Discord und l\195\182st ihn unten auf der Kits-Seite ein.",
            "Notruf an alle Admins, die gerade online sind.",
            "Fenster frei verschieb- und skalierbar, Seiten sortierbar, Hilfe-Fenster direkt im Panel.",
        } },
    },
}

AegisHelpContent.PLAYER_EN = {
    help = {
        { title = "Overview", lines = {
            "The blue panel is your personal area on the server. Open it with the blue button next to the equipment bar in the top left.",
            "The start page shows your character as a rotatable 3D figure, next to it your most important vitals and your favourite weapon.",
            "Everyone on the server has the panel automatically, from the fresh player to the admin. Extras like the zone claim or kits depend on your role: if such an area is missing, it is not enabled for your role.",
        } },
        { title = "Statistics and leaderboard", lines = {
            "The statistics page collects your career: deaths, zombies and bandits killed, kilometres walked, your longest life and total playtime.",
            "Below it sits the server leaderboard. Your own entry is highlighted, so you see at a glance where you stand.",
            "Kilometres, deaths and bandit kills count from the moment the panel was installed on the server. Playtime is also calculated retroactively from the session logs.",
        } },
        { title = "Health", lines = {
            "The health view shows your condition at a glance: injuries per body part, bleeding and everything that wants treatment right now.",
            "Bandaging works right on this page, no detour through the normal health window. As always you need suitable bandage material in your bags.",
            "That way you spot trouble early, before a scratch turns into a real problem.",
        } },
        { title = "Safehouse", lines = {
            "The safehouse page shows your home: location, size and who belongs to it.",
            "If your safehouse is about to expire, the panel warns you in time. After a longer break this is the first place to look.",
        } },
        { title = "Own vehicles", lines = {
            "The vehicle page lists your own vehicles with condition and location.",
            "Under the 3D preview, condition bars show at a glance how well your car is holding together.",
            "The nav marks the selected vehicle so you can find it in the world again. Handy when you no longer remember where you left the car after a wild escape.",
            "The nav simply runs alongside and blocks no other actions: fighting, looting and building continue as normal.",
        } },
        { title = "Zone claim", lines = {
            "The zone claim secures a protected piece of land right at your house, no admin needed.",
            "How many tiles you may claim is set by your role, without a role there are none. The panel shows your budget and how much of it is already used.",
            "You need to stand at your house to place it. Inside your zone the server's protection rules apply.",
        } },
        { title = "Collecting kits", lines = {
            "Kits are ready made packages from the admins, a starter package or event rewards for example.",
            "Every card shows what is inside and whether the kit is one time or on a cooldown. Collect puts the content straight into your inventory.",
            "One time kits stay collected, even after dying and rejoining.",
        } },
        { title = "Distress call", lines = {
            "The distress call reaches every admin currently online with your name, your position and your message.",
            "Describe briefly what happened, then the admins can come straight to you. After a call a short cooldown prevents spam.",
            "The distress call is meant for real problems, griefers or stuck situations for example, not for wish lists.",
        } },
        { title = "Window and controls", lines = {
            "The panel can be dragged freely across the screen by its header.",
            "The blue button opens and closes the panel, the X in the window closes it as well.",
            "Wherever a small dot triangle sits in the bottom right, drag it to resize the window to any size you like.",
            "At the bottom of the sidebar sits a small padlock: open it and drag the entries to a new spot with the mouse held down, the blue line shows where they will land. Close the padlock again afterwards.",
            "This help window can also be moved by its header and resized at the dot corner in the bottom right, the size is remembered.",
        } },
    },
    changelog = {
        { version = "1.2.1", date = "August 2026", sections = {
            { title = "Fixed", points = {
                "Your safehouse card stayed empty although you owned a claim. It looked the zones up on your own machine, and a zone created on the server does not have to arrive there. It now asks the server and keeps itself up to date while the page is open.",
                "Where the server runs the Knox Claim mod, that mod owns the vehicles. The button for remembering a vehicle disappears here in that case, so you do not have to keep your cars in two places. The forget button stays so you can clear out older entries.",
            } },
        } },
        { version = "1.2", date = "July 2026", sections = {
            { title = "New", points = {
                "Hide pages: with the padlock at the bottom of the sidebar open, every entry shows an eye. Hide what you do not care about, the plus next to it brings pages back.",
                "Kits show where they come from: next to the name a small tag tells you which role or booster status grants you the kit. Open kits carry nothing, they belong to everyone.",
            } },
        } },
        { version = "1.1", date = "July 2026", sections = {
            { title = "New", points = {
                "The admins can reset your claim on a kit, usually when a fresh world starts. After that you can collect a one-time kit once more. Whether and when is their call.",
            } },
            { title = "Fixed", points = {
                "Confirmation windows now fit their text: long notices wrap instead of running off the right edge. That affects the zone claim and the vehicle page.",
            } },
        } },
        { version = "1.0", date = "July 2026", points = {
            "F6 opens and closes the player area, the blue button in the bottom left still works too. The key can be changed in the mod options.",
            "New: this player area. A panel of your own with your character in 3D, vitals and favourite weapon, for everyone on the server.",
            "Statistics with server leaderboard: deaths, zombie and bandit kills, kilometres, longest life, playtime.",
            "Health view with every injury at a glance, bandaging and disinfecting right here. The figure grows with the window size.",
            "Safehouse view with expiry warning.",
            "Vehicles: your cars with a 3D preview, a nav arrow to a lost one and every part by category. A flat tire shows up as flat.",
            "Your own zone claim at your house, extent depending on your role. It has to connect to your house and may not overlap anything.",
            "Kits to collect, one time or on a cooldown. You only see the ones unlocked for your role.",
            "Discord boosters: if your server offers it, grab the code in Discord and redeem it at the bottom of the kits page.",
            "Distress call to every admin currently online.",
            "Window freely movable and resizable, pages sortable, help window right inside the panel.",
        } },
    },
}

function AegisHelpContent.get(mode)
    local lang = nil
    pcall(function() lang = Translator.getLanguage():name() end)
    if mode == "player" then
        if lang == "DE" then return AegisHelpContent.PLAYER_DE end
        return AegisHelpContent.PLAYER_EN
    end
    if lang == "DE" then return AegisHelpContent.DE end
    return AegisHelpContent.EN
end
