-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

-- Retail's What's New for 1.4.0. Loaded on Retail and PTR only (Epithet.toc:
-- [AllowLoadGameType standard]); WoW Forever's entries are in WhatsNew/Forever/.
-- hasNew = false: little changes on Retail, so the window does not open by
-- itself; /epithet whatsnew still shows it.

local _, ns = ...

ns.WhatsNewContent = ns.WhatsNewContent or { versions = {} }

ns.WhatsNewContent.versions["1.4.0"] = {
    hasNew = false,
    title = {
        enUS = "Epithet 1.4",
        deDE = "Epithet 1.4",
        frFR = "Epithet 1.4",
        ruRU = "Epithet 1.4",
        zhCN = "Epithet 1.4",
    },
    body = {
        enUS = [[
## Now on WoW Forever too

Epithet now also runs on WoW Forever, with its own titles, look and achievements there. On Retail, everything looks and works as before.

## Changes

- **A reachable secret** — One secret achievement asked you to spot more titles than exist. It now asks for 650.
- **Your character's achievements** — Per-character achievements and owned titles are now saved under your character's ID, so they stay with you through a name change. They move across by themselves the first time you log in.
- **Title reading** — A title that exists as both a prefix and a suffix is now read by where it appears in the name.

## Tip

Use /epithet whatsnew to bring this window back any time.
        ]],
        deDE = [[
## Jetzt auch auf WoW Forever

Epithet läuft jetzt auch auf WoW Forever, dort mit eigenen Titeln, eigenem Look und eigenen Erfolgen. Auf Retail sieht alles so aus und funktioniert so wie bisher.

## Änderungen

- **Ein erreichbares Geheimnis** — Ein geheimer Erfolg verlangte mehr gesichtete Titel, als es gibt. Jetzt sind es 650.
- **Erfolge deines Charakters** — Charakterbezogene Erfolge und Titel im Besitz werden jetzt unter der ID deines Charakters gespeichert und bleiben so auch nach einer Namensänderung erhalten. Sie werden beim ersten Einloggen automatisch übernommen.
- **Titelerkennung** — Ein Titel, den es als Präfix und als Suffix gibt, wird jetzt danach erkannt, wo er im Namen steht.

## Tipp

Mit /epithet whatsnew kannst du dieses Fenster jederzeit erneut öffnen.
        ]],
        frFR = [[
## Désormais aussi sur WoW Forever

Epithet fonctionne désormais aussi sur WoW Forever, avec ses propres titres, son style et ses hauts faits. Sur Retail, tout reste comme avant.

## Changements

- **Un secret accessible** — Un haut fait secret demandait de repérer plus de titres qu'il n'en existe. Il en demande désormais 650.
- **Les hauts faits de votre personnage** — Les hauts faits par personnage et les titres possédés sont désormais enregistrés sous l'identifiant de votre personnage : ils vous suivent même après un changement de nom. Ils sont transférés automatiquement à votre première connexion.
- **Lecture des titres** — Un titre qui existe à la fois en préfixe et en suffixe est désormais lu selon sa place dans le nom.

## Astuce

Utilisez /epithet whatsnew pour rouvrir cette fenêtre à tout moment.
        ]],
        ruRU = [[
## Теперь и в WoW Forever

Epithet теперь работает и в WoW Forever — там у него свои звания, облик и достижения. В Retail всё выглядит и работает как прежде.

## Изменения

- **Достижимый секрет** — Одно секретное достижение требовало распознать больше званий, чем существует. Теперь нужно 650.
- **Достижения вашего персонажа** — Достижения персонажа и полученные звания теперь сохраняются по идентификатору персонажа и остаются с вами даже после смены имени. Они переносятся автоматически при первом входе в игру.
- **Распознавание званий** — Звание, которое существует и как префикс, и как суффикс, теперь распознаётся по его месту в имени.

## Совет

Используйте /epithet whatsnew, чтобы снова открыть это окно в любой момент.
        ]],
        zhCN = [[
## 现已同时支持 WoW Forever

Epithet 现在也能在 WoW Forever 上运行，并拥有专属的头衔、外观和成就。在正式服上，一切外观和功能都与以前相同。

## 更新内容

- **可达成的隐藏成就** — 有一个隐藏成就要求发现的头衔数量超过了实际存在的数量，现在改为 650 个。
- **角色成就** — 角色专属成就和已拥有的头衔现在按角色 ID 保存，即使改名也会保留。首次登录时会自动迁移。
- **头衔识别** — 同时作为前缀和后缀存在的头衔，现在会根据它在名字中的位置来识别。

## 提示

随时使用 /epithet whatsnew 重新打开此窗口。
        ]],
    },
}