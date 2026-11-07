-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

local _, ns = ...

ns.WhatsNewContent = ns.WhatsNewContent or { versions = {} }

-- title/body may be a plain string or a table keyed by locale
-- (e.g. { enUS = [[...]], ruRU = [[...]] }). WhatsNew:LocalizeField resolves the
-- active locale and falls back to enUS, so adding a translation is purely
-- additive: drop a ruRU key alongside enUS below.
ns.WhatsNewContent.versions["1.3.0"] = {
    hasNew = true,
    title = { enUS = "Epithet 1.3.0" },
    body = {
        enUS = [[
## Bonjour, Привет, Hello!

Epithet now speaks French and Russian, locales are probably one of the more challenging aspects to properly put in place and test. This is largely because of the effort required to go through and ensure full coverage, especially when Epithet focuses so heavily on text presentation. 

If you spot a translation issue, or you want to contribute to translating Epithet into more languages, see the below project areas

- [Locale Wiki](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [Language Issues](https://github.com/Grimmsforge/Epithet/issues)

## Epithet Options and Nameplate hints.

Epithat has an options section, you can access this through the 'escape' menu, 'Options', then select 'add-ons' and scroll to 'Epithet', here you can change and amend all aspects of the title spotting meta-game and language settings for the main Epithet UI.

Both Namplates and Achievements can be turned off, set to not appear in Combat, or when you're in groups, or not to show at all. The flexibility is there for you to decide how you want title spotting to work for you.

## Tip

Missed all this? Use /epithet whatsnew to bring this window back any time.
                ]],
        ruRU = [[
## Bonjour, Привет, Hello!

Теперь Epithet говорит по-французски и по-русски. Локализация - пожалуй, одна из самых сложных вещей, которую нужно правильно внедрить и протестировать. Во многом это связано с тем, сколько усилий уходит на то, чтобы обеспечить полное покрытие, особенно учитывая, насколько сильно Epithet завязан на подаче текста.

Если вы заметили ошибку перевода или хотите помочь с переводом Epithet на другие языки, загляните в разделы проекта ниже:

- [Вики по локализации](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [Языковые вопросы](https://github.com/Grimmsforge/Epithet/issues)

## Настройки Epithet и подсказки на индикаторах

У Epithet есть собственный раздел настроек. Чтобы его найти, откройте меню на 'Esc', выберите 'Настройки' (Options), затем 'Дополнения' (AddOns) и пролистайте до 'Epithet' - здесь можно настроить все аспекты меты распознавания званий, а также язык основного интерфейса Epithet.

И индикаторы над головами, и достижения можно полностью отключить, настроить так, чтобы они не появлялись в бою или в группе, либо скрыть насовсем. Вы сами решаете, как распознавание званий будет работать именно для вас.

## Совет

Пропустили это окно? Наберите /epithet whatsnew, чтобы открыть его снова в любой момент.
                ]],
        frFR = [[
## Bonjour, Привет, Hello !

Epithet parle désormais français et russe. La localisation est sans doute l'un des aspects les plus difficiles à mettre en place et à tester correctement, en grande partie à cause de l'effort nécessaire pour garantir une couverture complète, surtout quand Epithet repose autant sur la présentation du texte.

Si vous repérez un problème de traduction, ou si vous souhaitez aider à traduire Epithet dans d'autres langues, consultez les ressources du projet ci-dessous :

- [Wiki de localisation](https://github.com/Grimmsforge/Epithet/wiki/Locales-and-Translations)
- [Problèmes de langue](https://github.com/Grimmsforge/Epithet/issues)

## Options d'Epithet et infobulles sur la barre d'infos

Epithet dispose de sa propre section d'options. Pour y accéder, ouvrez le menu 'Échap', 'Options', puis sélectionnez 'Modules complémentaires' et faites défiler jusqu'à 'Epithet' - vous pourrez y régler tous les aspects du méta-jeu de repérage de titres, ainsi que la langue de l'interface principale d'Epithet.

Les barres d'infos comme les hauts faits peuvent être désactivés, configurés pour ne pas apparaître en combat ou en groupe, ou simplement masqués en permanence. Vous êtes libre de décider comment le repérage de titres doit fonctionner pour vous.

## Astuce

Vous avez raté tout ça ? Tapez /epithet whatsnew pour rouvrir cette fenêtre à tout moment.
                ]],
    },
}
