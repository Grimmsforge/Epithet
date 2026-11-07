-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

-- WoW Forever's What's New. Loaded on Forever only (Epithet.toc:
-- [AllowLoadGameType camelot]); Retail's entries are in WhatsNew/Retail/.

local _, ns = ...

ns.WhatsNewContent = ns.WhatsNewContent or { versions = {} }

ns.WhatsNewContent.versions["1.4.0"] = {
    hasNew = true,
    title = {
        enUS = "Epithet, now on WoW Forever",
        deDE = "Epithet, jetzt auf WoW Forever",
        frFR = "Epithet arrive sur WoW Forever",
        ruRU = "Epithet теперь в WoW Forever",
        zhCN = "Epithet 现已登陆 WoW Forever",
    },
    body = {
        enUS = [[
## Welcome to Epithet!

Epithet now runs on WoW Forever. It knows all 40 of Forever's titles: both factions' PvP rank ladders, the profession titles, the reputation titles, and one mystery.

## Made for Forever

- **A new look** — Verdigris takes its colours from the Forever logo: deep-sea panels, a bronze frame, and gold for what is yours. A bronze compass ring frames your portrait in the main window, and the portrait on other players' title cards.
- **First and last names** — The header shows your full name, and titles are read correctly on players with two-part names, so a surname is never mistaken for a title.
- **Faction colours** — Alliance and Horde ranks each have their own colour, so the two ladders are easy to tell apart.
- **Achievements of its own** — 64 achievements, 16 of them made for Forever: rank ladders, rival centaur clans, families, new race and class pairings, campfires and more. Some are secret.

## Tip

Missed this? Use /epithet whatsnew to bring this window back any time.
        ]],
        deDE = [[
## Willkommen bei Epithet!

Epithet läuft jetzt auf WoW Forever. Es kennt alle 40 Titel von Forever: die PvP-Rangleitern beider Fraktionen, die Berufstitel, die Ruftitel und ein Rätsel.

## Gemacht für Forever

- **Ein neuer Look** — Verdigris übernimmt die Farben des Forever-Logos: Tiefseeblau für die Flächen, ein Bronzerahmen und Gold für alles, was dir gehört. Ein bronzener Kompassring umrahmt dein Porträt im Hauptfenster und die Porträts auf den Titelkarten anderer Spieler.
- **Vor- und Nachnamen** — Die Kopfzeile zeigt deinen vollen Namen, und Titel werden bei Spielern mit zweiteiligen Namen richtig erkannt, sodass ein Nachname nie für einen Titel gehalten wird.
- **Fraktionsfarben** — Ränge der Allianz und der Horde haben jeweils eine eigene Farbe, damit die beiden Rangleitern leicht zu unterscheiden sind.
- **Eigene Erfolge** — 64 Erfolge, 16 davon speziell für Forever: Rangleitern, verfeindete Zentaurenklans, Familien, neue Kombinationen aus Volk und Klasse, Lagerfeuer und mehr. Einige sind geheim.

## Tipp

Das hier verpasst? Mit /epithet whatsnew kannst du dieses Fenster jederzeit erneut öffnen.
        ]],
        frFR = [[
## Bienvenue dans Epithet !

Epithet fonctionne désormais sur WoW Forever. Il connaît les 40 titres de Forever : les échelles de rangs JcJ des deux factions, les titres de métier, les titres de réputation, et un mystère.

## Pensé pour Forever

- **Un nouveau style** — Verdigris reprend les couleurs du logo de Forever : des panneaux bleu des profondeurs, un cadre de bronze et de l'or pour tout ce qui est à vous. Un anneau de boussole en bronze encadre votre portrait dans la fenêtre principale, ainsi que celui des autres joueurs sur leur carte de titre.
- **Prénom et nom** — L'en-tête affiche votre nom complet, et les titres sont bien lus sur les joueurs aux noms en deux parties : un nom de famille n'est jamais pris pour un titre.
- **Couleurs de faction** — Les rangs de l'Alliance et de la Horde ont chacun leur couleur, pour distinguer facilement les deux échelles.
- **Des hauts faits bien à lui** — 64 hauts faits, dont 16 créés pour Forever : échelles de rangs, clans centaures rivaux, familles, nouvelles combinaisons de race et de classe, feux de camp et plus encore. Certains sont secrets.

## Astuce

Vous l'avez manqué ? Utilisez /epithet whatsnew pour rouvrir cette fenêtre à tout moment.
        ]],
        ruRU = [[
## Добро пожаловать в Epithet!

Epithet теперь работает в WoW Forever. Он знает все 40 званий Forever: PvP-лестницы рангов обеих фракций, звания профессий, звания за репутацию и одну загадку.

## Создано для Forever

- **Новый облик** — Verdigris берёт цвета из логотипа Forever: глубоководные панели, бронзовая рамка и золото для всего, что принадлежит вам. Бронзовое кольцо компаса обрамляет ваш портрет в главном окне и портреты других игроков на их карточках званий.
- **Имя и фамилия** — В заголовке показано ваше полное имя, а звания правильно распознаются у игроков с именами из двух частей, так что фамилию никогда не примут за звание.
- **Цвета фракций** — У рангов Альянса и Орды свой цвет, поэтому две лестницы легко различить.
- **Собственные достижения** — 64 достижения, 16 из них созданы для Forever: лестницы рангов, враждующие кланы кентавров, семьи, новые сочетания расы и класса, костры и многое другое. Некоторые из них секретные.

## Совет

Пропустили? Используйте /epithet whatsnew, чтобы снова открыть это окно в любой момент.
        ]],
        zhCN = [[
## 欢迎使用 Epithet！

Epithet 现已支持 WoW Forever。它收录了 Forever 的全部 40 个头衔：两大阵营的 PvP 军衔、专业头衔、声望头衔，以及一个谜。

## 为 Forever 打造

- **全新外观** — Verdigris 的配色取自 Forever 标志：深海色面板、青铜边框，属于你的一切都以金色标示。主窗口中你的头像，以及其他玩家头衔卡片上的头像，都由一圈青铜罗盘环环绕。
- **名字和姓氏** — 标题栏显示你的完整姓名，双名玩家的头衔也能正确识别，姓氏绝不会被误认为头衔。
- **阵营颜色** — 联盟和部落的军衔各有自己的颜色，两条军衔线一目了然。
- **专属成就** — 共 64 个成就，其中 16 个专为 Forever 设计：军衔阶梯、敌对的半人马氏族、家族、新的种族与职业组合、篝火等等。其中一些是隐藏成就。

## 提示

错过了？随时使用 /epithet whatsnew 重新打开此窗口。
        ]],
    },
}