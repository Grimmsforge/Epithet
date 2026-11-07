-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

-- WoW Forever's What's New for 1.4.1. Loaded on Forever only (Epithet.toc:
-- [AllowLoadGameType camelot]), after v1_4_0.lua.
--
-- 1.4.1 shows the 1.4.0 welcome again, since it is still what a new Forever
-- player needs, with the compass ring that now frames your portrait in the
-- main window shown after the opening paragraph.

local _, ns = ...

local versions = ns.WhatsNewContent.versions
local welcome = versions["1.4.0"]

-- Images name a Theme.tex texture ("tex:<name>"), so no file path is spelled out.
local RING = "![](tex:headerPortraitRing =96x96)"

-- The body with the ring after its first paragraph (before its second heading).
local function WithRing(body)
    local first = body:find("## ", 1, true)
    local second = first and body:find("\n## ", first + 3, true)
    if not second then
        return body .. "\n" .. RING .. "\n"
    end
    return body:sub(1, second) .. RING .. "\n" .. body:sub(second)
end

local body = {}
for locale, text in pairs(welcome.body) do
    body[locale] = WithRing(text)
end

versions["1.4.1"] = {
    hasNew = true,
    title = welcome.title,
    body = body,
}
