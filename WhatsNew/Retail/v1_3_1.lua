-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

local _, ns = ...

ns.WhatsNewContent = ns.WhatsNewContent or { versions = {} }

-- title/body may be a plain string or a table keyed by locale
-- (e.g. { enUS = [[...]], ruRU = [[...]] }). WhatsNew:LocalizeField resolves the
-- active locale and falls back to enUS, so adding a translation is purely
-- additive: drop a ruRU key alongside enUS below.
ns.WhatsNewContent.versions["1.3.1"] = {
    hasNew = true,
    title = { enUS = "Epithet 1.3.1" },
    body = {
        enUS = [[
## Guten Tag!

Epithet now speaks German too, alongside French and Russian. If you spot a translation issue, or want to help translate Epithet into more languages, take a look at:

- [Locale Wiki](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [Language Issues](https://github.com/Grimmsforge/Epithet/issues)

## Settings, reorganized

Title Spotting and Achievements now each get their own settings tab instead of sharing one long page. Achievement notification and popup-anchor settings work whether or not title spotting itself is switched on, since achievements built around your own title collection don't need it enabled to keep progressing. Turn title spotting off and a note on the Achievements tab explains which achievements pause until it's back on. There's also a new "Show What's New after an update" toggle on the main settings page, if you'd rather this window stayed out of your way.

## Fewer false alarms

Fixed a bug where certain NPC, critter, or item names could be misread as a player wearing a title they don't actually have.

## Tip

Missed all this? Use /epithet whatsnew to bring this window back any time.
                ]],
        deDE = [[
## Guten Tag!

Epithet spricht jetzt auch Deutsch, zusätzlich zu Französisch und Russisch. Wenn du einen Übersetzungsfehler findest oder helfen möchtest, Epithet in weitere Sprachen zu übersetzen, wirf einen Blick hierauf:

- [Lokalisierungs-Wiki](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [Sprachprobleme melden](https://github.com/Grimmsforge/Epithet/issues)

## Einstellungen, neu geordnet

Titelsichtung und Erfolge haben jetzt jeweils einen eigenen Einstellungsreiter, statt sich eine lange Seite zu teilen. Benachrichtigungs- und Popup-Verankerungseinstellungen für Erfolge funktionieren unabhängig davon, ob die Titelsichtung selbst aktiviert ist, denn Erfolge, die auf deiner eigenen Titelsammlung basieren, brauchen sie nicht, um weiter voranzuschreiten. Schaltest du die Titelsichtung aus, erklärt dir ein Hinweis im Reiter Erfolge, welche Erfolge bis zur erneuten Aktivierung pausieren. Neu ist außerdem ein Schalter „Was ist neu nach einem Update anzeigen" auf der Haupt-Einstellungsseite, falls dir dieses Fenster lieber nicht automatisch begegnen soll.

## Weniger Fehlalarme

Ein Fehler wurde behoben, bei dem bestimmte NPC-, Kreaturen- oder Gegenstandsnamen fälschlicherweise als von einem Spieler getragener Titel erkannt wurden.

## Tipp

Das hier verpasst? Mit /epithet whatsnew kannst du dieses Fenster jederzeit erneut öffnen.
                ]],
        frFR = [[
## Guten Tag !

Epithet parle désormais aussi allemand, en plus du français et du russe. Si vous repérez un problème de traduction, ou si vous souhaitez aider à traduire Epithet dans d'autres langues, consultez :

- [Wiki de localisation](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [Problèmes de langue](https://github.com/Grimmsforge/Epithet/issues)

## Paramètres réorganisés

Le repérage de titres et les hauts faits ont désormais chacun leur propre onglet de paramètres, au lieu de partager une seule longue page. Les réglages de notification et d'ancrage des popups de hauts faits fonctionnent que le repérage de titres soit activé ou non, car les hauts faits basés sur votre propre collection de titres n'ont pas besoin qu'il le soit pour progresser. Désactivez le repérage de titres et une note dans l'onglet Hauts faits vous indiquera lesquels sont mis en pause jusqu'à sa réactivation. Autre nouveauté : une option « Afficher les nouveautés après une mise à jour » sur la page principale des paramètres, si vous préférez que cette fenêtre ne s'affiche pas automatiquement.

## Moins de fausses alertes

Correction d'un bug où certains noms de PNJ, de créatures ou d'objets pouvaient être confondus avec un titre porté par un joueur.

## Astuce

Vous avez raté tout ça ? Tapez /epithet whatsnew pour rouvrir cette fenêtre à tout moment.
                ]],
        ruRU = [[
## Guten Tag!

Теперь Epithet говорит и по-немецки, в дополнение к французскому и русскому. Если вы заметили ошибку перевода или хотите помочь с переводом Epithet на другие языки, загляните сюда:

- [Вики по локализации](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [Языковые вопросы](https://github.com/Grimmsforge/Epithet/issues)

## Настройки реорганизованы

Распознавание званий и достижения теперь получили собственные вкладки настроек, вместо того чтобы делить одну длинную страницу. Настройки уведомлений и привязки всплывающих окон для достижений работают независимо от того, включено ли само распознавание званий, ведь достижения, основанные на вашей собственной коллекции званий, не нуждаются в нём для прогресса. Если вы отключите распознавание званий, подсказка на вкладке «Достижения» объяснит, какие достижения приостановлены до его повторного включения. Также появился новый переключатель «Показывать «Что нового» после обновления» на главной странице настроек — если вы предпочитаете, чтобы это окно не открывалось само.

## Меньше ложных срабатываний

Исправлена ошибка, из-за которой некоторые имена НИП, существ или предметов могли ошибочно приниматься за звание, которое носит игрок.

## Совет

Пропустили это окно? Наберите /epithet whatsnew, чтобы открыть его снова в любой момент.
                ]],
    },
}
