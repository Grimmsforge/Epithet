-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

local _, ns = ...

ns.WhatsNewContent = ns.WhatsNewContent or { versions = {} }

ns.WhatsNewContent.versions["1.3.2"] = {
    hasNew = true,
    title = {
        enUS = "Hello!",
        deDE = "Hallo!",
        frFR = "Bonjour !",
        ruRU = "Привет! ",
        zhCN = "你好！",
    },
    body = {
        enUS = [[
## Hello!

Epithet now speaks Simplified Chinese. The interface, settings, What's New content, and title database source details are localized for zhCN clients.

## Bug fixes

- **Safer unit comparisons** — Protected or secret `UnitIsUnit` results no longer cause errors during combat. Self-target overlays, portrait updates, and title spotting capture now handle unit comparisons safely.
- **Achievement source links** — Achievement links now fall back across client API variants and handle unavailable achievement IDs safely.
- **Chinese font selection** — The Chinese UI now uses the client game font when appropriate, improving glyph rendering on zhCN clients.
- **Settings previews** — Title Spotting previews now refresh immediately when the relevant settings change.

If you spot a translation issue, or want to help translate Epithet into more languages, take a look at:

- [Locale Wiki](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [Language Issues](https://github.com/Grimmsforge/Epithet/issues)

## Tip

Missed this? Use /epithet whatsnew to bring this window back any time.
                ]],
                deDE = [[
            ## Hallo!

             Epithet unterstützt jetzt vereinfachtes Chinesisch. Benutzeroberfläche, Einstellungen, What's-New-Inhalte und Quellenangaben in der Titeldatenbank sind für zhCN-Clients lokalisiert.

            ## Fehlerbehebungen

            - **Sicherere Einheitenvergleiche** — Geschützte oder geheime Ergebnisse von `UnitIsUnit` verursachen im Kampf keine Fehler mehr. Overlays für das eigene Ziel, Porträtaktualisierungen und die Titelerfassung behandeln Einheitenvergleiche jetzt sicher.
            - **Quellenlinks für Erfolge** — Links zu Erfolgen verwenden jetzt Fallbacks für unterschiedliche Client-API-Varianten und behandeln nicht verfügbare Erfolgs-IDs sicher.
            - **Chinesische Schriftauswahl** — Die chinesische Benutzeroberfläche verwendet jetzt bei Bedarf die Spielschrift des Clients, wodurch Glyphen auf zhCN-Clients besser dargestellt werden.
            - **Einstellungs-Vorschauen** — Vorschauen für die Titelsichtung werden jetzt sofort aktualisiert, wenn sich die entsprechenden Einstellungen ändern.

            Wenn du einen Übersetzungsfehler findest oder helfen möchtest, Epithet in weitere Sprachen zu übersetzen, wirf einen Blick hierauf:

            - [Lokalisierungs-Wiki](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
            - [Sprachprobleme melden](https://github.com/Grimmsforge/Epithet/issues)

            ## Tipp

            Das hier verpasst? Mit /epithet whatsnew kannst du dieses Fenster jederzeit erneut öffnen.
                    ]],
                frFR = [[
            ## Bonjour !

            Epithet parle désormais chinois simplifié. L'interface, les paramètres, le contenu des nouveautés et les informations de source de la base de titres sont localisés pour les clients zhCN.

            ## Corrections de bugs

            - **Comparaisons d'unités plus sûres** — Les résultats protégés ou secrets de `UnitIsUnit` ne provoquent plus d'erreurs en combat. Les overlays sur sa propre cible, les mises à jour des portraits et la capture des titres gèrent désormais les comparaisons d'unités en toute sécurité.
            - **Liens vers les hauts faits** — Les liens vers les hauts faits utilisent maintenant des solutions de secours selon les variantes de l'API du client et gèrent correctement les identifiants indisponibles.
            - **Sélection de la police chinoise** — L'interface chinoise utilise désormais la police du jeu du client lorsque c'est nécessaire, ce qui améliore l'affichage des glyphes sur les clients zhCN.
            - **Aperçus des paramètres** — Les aperçus du repérage des titres sont maintenant actualisés immédiatement lorsque les paramètres concernés changent.

            Si vous repérez un problème de traduction, ou si vous souhaitez aider à traduire Epithet dans d'autres langues, consultez :

            - [Wiki de localisation](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
            - [Problèmes de langue](https://github.com/Grimmsforge/Epithet/issues)

            ## Astuce

            Vous avez raté tout ça ? Tapez /epithet whatsnew pour rouvrir cette fenêtre à tout moment.
                    ]],
                ruRU = [[
            ## Привет!

            Теперь Epithet поддерживает упрощённый китайский. Интерфейс, настройки, содержимое окна «Что нового» и сведения об источниках в базе званий локализованы для клиентов zhCN.

            ## Исправления

            - **Безопасные сравнения юнитов** — Защищённые или секретные результаты `UnitIsUnit` больше не вызывают ошибок в бою. Индикаторы на собственной цели, обновление портретов и захват званий теперь безопасно обрабатывают сравнения юнитов.
            - **Ссылки на достижения** — Ссылки на достижения теперь используют запасные варианты для разных API клиента и безопасно обрабатывают недоступные идентификаторы достижений.
            - **Выбор китайского шрифта** — Китайский интерфейс теперь при необходимости использует игровой шрифт клиента, улучшая отображение символов на клиентах zhCN.
            - **Предпросмотр настроек** — Предпросмотр распознавания званий теперь сразу обновляется при изменении соответствующих настроек.

            Если вы заметили ошибку перевода или хотите помочь с переводом Epithet на другие языки, загляните сюда:

            - [Вики по локализации](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
            - [Языковые вопросы](https://github.com/Grimmsforge/Epithet/issues)

            ## Совет

            Пропустили это окно? Наберите /epithet whatsnew, чтобы открыть его снова в любой момент.
                    ]],
        zhCN = [[
            ## 你好！

Epithet 现在支持简体中文。界面、设置、“新功能介绍”内容以及头衔数据库中的来源说明都已为 zhCN 客户端完成本地化。

            ## 问题修复

            - **更安全的单位比较** — 受保护或保密的 `UnitIsUnit` 结果不再在战斗中导致错误。自身目标的头衔覆盖、肖像更新和头衔记录现在都能安全处理单位比较。
            - **成就来源链接** — 成就链接现在可以兼容不同客户端 API，并安全处理不可用的成就 ID。
            - **中文字体选择** — 中文界面现在会在适当情况下使用客户端游戏字体，改善 zhCN 客户端上的字形显示。
            - **设置预览** — 更改相关设置后，头衔侦测预览现在会立即刷新。

如果您发现翻译问题，或者希望帮助 Epithet 支持更多语言，请查看：

- [本地化 Wiki](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [语言问题](https://github.com/Grimmsforge/Epithet/issues)

## 提示

错过了这些内容？使用 /epithet whatsnew 可随时重新打开此窗口。
                ]],
    },
}