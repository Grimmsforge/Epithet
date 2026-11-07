-- The theme: tokens, Ref roles, Apply, skins, bordered buttons, textures, and
-- the WoW Forever override. Run by theme.test.js, which provides FILES (repo
-- files by path) and check().

local printed = {}
local realPrint = print
print = function(s) printed[#printed + 1] = tostring(s) end

local function loadTheme()
    local ns = {}
    assert(load(FILES["Core/Theme.lua"], "=Theme.lua"))("Epithet", ns)
    return ns, ns.Theme
end

-- ---- Apply: in-place, partial, validated --------------------------------
do
    local ns, T = loadTheme()
    local held = T.col.gold                -- what a UI file captures at load
    local beforeHover = T.col.btnBgHover.r
    T.Apply({ col = { gold = "102030", btnBg = { 0.5, 0.25, 0.125 }, surface = { "abcdef", 0.5 } } })
    check(held == T.col.gold, "Apply keeps the same token table")
    check(math.abs(held.r - 0x10 / 255) < 1e-9 and held.hex == "102030", "captured reference sees the new gold")
    check(T.col.btnBg.r == 0.5 and T.col.btnBg.hex == "804020", "array form + hex derived (" .. T.col.btnBg.hex .. ")")
    check(T.col.surface.a == 0.5 and T.col.surface.hex == "abcdef", "{hex, alpha} form")
    check(T.col.btnBgHover.r == beforeHover, "tokens not named are untouched")
    check(T.col.btnBorder ~= T.col.goldDeep and T.col.btnBorder.hex == "7c5e26", "role tokens are separate tables from the palette")

    printed = {}
    T.Apply({ col = { notAToken = "000000", gold = "zzzzzz" }, quality = { [5] = { text = "ffb04a", label = "x" }, [9] = {} } })
    check(T.col.notAToken == nil, "unknown token is not created")
    check(held.hex == "102030", "invalid value leaves the token alone")
    check(T.quality[5].text.hex == "ffb04a", "quality override applied")
    check(T.quality[5].label == "Legendary", "quality label is not overridable")
    local joined = table.concat(printed, "\n")
    check(joined:find("unknown colour token col.notAToken", 1, true), "warns on unknown token")
    check(joined:find("invalid colour for col.gold", 1, true), "warns on invalid value")
    check(joined:find("quality[5].label", 1, true) and joined:find("quality tier 9", 1, true), "warns on bad quality keys")

    printed = {}
    T.Seal()
    T.Apply({ col = { gold = "e8c873" } })
    check(table.concat(printed):find("after the UI was built", 1, true), "warns after Seal")
    check(held.hex == "e8c873", "still applies after Seal")
end

-- ---- RGBA / Paint / ApplySkin -----------------------------------------
do
    local ns, T = loadTheme()
    local r, g, b, a = T.RGBA(T.col.line)
    check(a == 0.22, "RGBA uses token alpha by default")
    r, g, b, a = T.RGBA(T.col.line, 0.5)
    check(a == 0.5, "RGBA alpha override")
    check(not pcall(T.RGBA, nil), "RGBA errors on a missing token")

    local calls = {}
    local function region(name)
        local reg = {}
        for _, m in ipairs({ "SetTextColor", "SetColorTexture", "SetVertexColor", "SetStatusBarColor",
                             "SetShadowColor", "SetBackdropColor", "SetBackdropBorderColor" }) do
            reg[m] = function(_, r_, g_, b_, a_) calls[#calls + 1] = { name, m, r_, g_, b_, a_ } end
        end
        return reg
    end
    local root = region("root")
    root.TitleBar = region("TitleBar")
    root.TitleBar.BG = region("TitleBar.BG")
    root.TitleBar.Title = region("TitleBar.Title")
    root.Bar = region("Bar")
    T.ApplySkin(root, {
        { "TitleBar.BG", "fill", "surface", 0.92 },
        { "TitleBar.Title", "text", "gold" },
        { "Bar", "bar", "gold" },
        { "Missing.Path", "fill", "gold" },   -- absent region: skipped, no error
        { "", "backdrop", "bg0", 0.97 },
    })
    check(#calls == 4, "skin painted 4 regions (got " .. #calls .. ")")
    check(calls[1][1] == "TitleBar.BG" and calls[1][2] == "SetColorTexture" and calls[1][6] == 0.92, "fill -> SetColorTexture with alpha")
    check(calls[2][2] == "SetTextColor" and calls[2][3] == T.col.gold.r, "text -> SetTextColor")
    check(calls[3][2] == "SetStatusBarColor", "bar -> SetStatusBarColor")
    check(calls[4][1] == "root" and calls[4][2] == "SetBackdropColor", "empty path paints the root")
    check(not pcall(T.ApplySkin, root, { { "Bar", "fill", "noSuchToken" } }), "skin errors on unknown token")
    check(not pcall(T.Paint, root, "glow", T.col.gold), "Paint errors on unknown kind")
    check(T.Wrap(T.col.gold, "x") == "|cffe8c873x|r" and T.Wrap("123456", "y") == "|cff123456y|r", "Wrap takes a token or hex")
end

-- ---- the Forever override file loads quietly ----------------------------
do
    local ns, T = loadTheme()
    local snapshot = {}
    for k, v in pairs(T.col) do snapshot[k] = v.hex .. "/" .. v.a end
    printed = {}
    assert(load(FILES["Flavors/Forever/Theme.lua"], "=Flavors/Forever/Theme.lua"))("Epithet", ns)
    local changed = 0
    for k, v in pairs(T.col) do if snapshot[k] ~= v.hex .. "/" .. v.a then changed = changed + 1 end end
    check(#printed == 0, "Forever theme loads with no warnings (" .. table.concat(printed, " / ") .. ")")
    check(changed == 103, "Verdigris changes 103 colours (got " .. changed .. ")")
    local _, R = loadTheme()
    local rarityKept = true
    for i = 1, 5 do
        if T.quality[i].text.hex ~= R.quality[i].text.hex or T.quality[i].pip.hex ~= R.quality[i].pip.hex then rarityKept = false end
    end
    check(rarityKept, "Forever keeps the rarity colours")
    check(T.col.alliance.hex == "5b9be6" and T.RefSource("alliance") == nil, "Alliance detached from gold")
    check(T.RefSource("btnText") == "gold" and T.col.btnText.hex == "e6c47e", "Refs follow the Forever gold")
    check(T.tex.portraitRing:find("epithet%-portrait%-ring%-forever$") ~= nil, "portrait ring swapped on Forever")
    local H = T.HeaderPortraitRing
    check(H.tex == "headerPortraitRing" and H.overPortrait == true and H.tint == nil and H.size == 68,
        "the header ring is the compass ring, untinted, over the portrait")
    check(T.tex.headerPortraitRing:find("epithet%-portrait%-ring%-forever$") ~= nil, "Forever's header ring is the verdigris compass")
    check(R.tex.headerPortraitRing:find("epithet%-portrait%-ring%-compass$") ~= nil, "Retail's header ring is the gold compass")
    check(R.TitleBadge == nil, "no title bar badge by default (Retail)")
    local B = T.TitleBadge
    check(B and B.texture == T.tex.badgeForever and B.width == 128 and B.height == 32, "Forever's title bar badge is set")
    check(R.tex.portraitRing:find("epithet%-portrait%-ring$") ~= nil, "shared ring unchanged")
end

-- ---- Ref: roles follow palette tokens ----------------------------------
do
    local ns, T = loadTheme()
    check(T.RefSource("btnText") == "gold", "btnText follows gold")
    check(T.RefSource("frameBorder") == nil, "frameBorder has its own value")
    check(T.col.btnText ~= T.col.gold, "a Ref is its own table")
    check(T.col.btnBorderSoft.a == 0.5 and T.col.btnBorderSoft.hex == T.col.gold.hex, "Ref with its own alpha")
    check(T.col.lineSoft.a == 0.12 and T.col.titleBtnBorder.a == 1 and T.col.line.a == 0.22, "line family alphas preserved")

    local heldText = T.col.btnText
    printed = {}
    T.Apply({ col = { gold = "102030" } })
    check(heldText.hex == "102030" and T.col.alliance.hex == "102030" and T.col.btnBorderHover.hex == "102030",
        "overriding gold restyles every role that follows it")
    check(T.col.btnBorderSoft.hex == "102030" and T.col.btnBorderSoft.a == 0.5, "followed alpha kept on cascade")
    check(T.col.goldBright.hex == "f6e2a6", "unrelated palette untouched")

    T.Apply({ col = { btnText = "abcdef" } })
    check(T.RefSource("btnText") == nil and T.col.btnText.hex == "abcdef", "overriding a role detaches it")
    T.Apply({ col = { gold = "e8c873" } })
    check(T.col.btnText.hex == "abcdef" and T.col.btnBorderHover.hex == "e8c873", "a detached role ignores its old source")

    T.Apply({ col = { btnBg = "zzzzzz" } })
    check(T.RefSource("btnBg") == "bg1", "an invalid override does not detach the role")
    check(#printed >= 1, "invalid override reported")
end

-- ---- Ref validation at load ----------------------------------------------
do
    local bad = FILES["Core/Theme.lua"]:gsub('btnText          = Ref%("gold"%)', 'btnText          = Ref("btnBorder")', 1)
    check(bad ~= FILES["Core/Theme.lua"], "test setup: chained Ref injected")
    local ok, err = pcall(function() assert(load(bad, "=Theme.lua"))("Epithet", {}) end)
    check(not ok and tostring(err):find("itself a Ref", 1, true), "a Ref to a Ref fails at load")
    local bad2 = FILES["Core/Theme.lua"]:gsub('btnText          = Ref%("gold"%)', 'btnText          = Ref("nope")', 1)
    local ok2, err2 = pcall(function() assert(load(bad2, "=Theme.lua"))("Epithet", {}) end)
    check(not ok2 and tostring(err2):find("unknown token", 1, true), "a Ref to an unknown token fails at load")
end

-- ---- Bordered buttons: every site, every state, against the committed colours
do
    local ns, T = loadTheme()
    local q = function(v) return math.floor(v * 255 + 0.5) end
    local maxStep = 0
    local function near(label, got, want)
        if not got then check(false, label .. ": never painted"); return end
        local d = 0
        for i = 1, 4 do d = math.max(d, math.abs(q(got[i]) - q(want[i] or 1))) end
        if d > maxStep then maxStep = d end
        check(d <= 2, string.format("%s: got %d,%d,%d,%d want %d,%d,%d,%d", label,
            q(got[1]), q(got[2]), q(got[3]), q(got[4] or 1), q(want[1]), q(want[2]), q(want[3]), q(want[4] or 1)))
    end
    local function region()
        local r = {}
        local function set(self, R, G, B, A) self.c = { R, G, B, A or 1 } end
        r.SetColorTexture, r.SetVertexColor, r.SetTextColor = set, set, set
        r.SetAllPoints, r.SetPoint, r.SetHeight, r.SetWidth = function() end, function() end, function() end, function() end
        return r
    end
    local function button(withText, withIcon)
        local b = { scripts = {} }
        b.CreateTexture = function() return region() end
        b.HookScript = function(self, ev, fn)
            local prev = self.scripts[ev]
            self.scripts[ev] = prev and function(...) prev(...); fn(...) end or fn
        end
        b.fire = function(self, ev) if self.scripts[ev] then self.scripts[ev](self) end end
        if withText then b.text = region(); b.text.c = { 9, 9, 9, 9 } end   -- sentinel: "not painted"
        if withIcon then b.icon = region(); b.icon.c = { 9, 9, 9, 9 } end
        return b
    end
    -- Committed (HEAD) values, transcribed from the old hand-written code.
    local H = {
        bg = { 0.11, 0.08, 0.04 }, bgHover = { 0.16, 0.12, 0.07 }, bgSel = { 0.20, 0.15, 0.08 },
        border = { 0.49, 0.37, 0.15 }, borderHover = { 0.91, 0.78, 0.45 }, borderSel = { 0.95, 0.82, 0.48 },
        text = { 0.91, 0.78, 0.45 }, textHover = { 0.96, 0.89, 0.65 }, textSel = { 1.0, 0.92, 0.70 },
        gold = { 232 / 255, 200 / 255, 115 / 255 }, ink = { 12 / 255, 10 / 255, 6 / 255 },
        disBg = { 0.07, 0.05, 0.03 }, disText = { 0.36, 0.33, 0.27 }, disBorder = { 0.20, 0.16, 0.10 },
        goldDim = { 185 / 255, 146 / 255, 63 / 255 }, aboutHover = { 1.0, 0.92, 0.6 },
    }
    local function expect(site, b, state, want)
        near(site .. " " .. state .. " bg", b.bg.c, want.bg)
        for i = 1, 4 do near(site .. " " .. state .. " border" .. i, b.borders[i].c, want.border) end
        if want.text then near(site .. " " .. state .. " text", b.text.c, want.text) end
        if want.icon then near(site .. " " .. state .. " icon", b.icon.c, want.icon) end
        if want.textUntouched then check(b.text.c[1] == 9, site .. " " .. state .. ": text left to the site") end
    end
    local alpha = function(c, a) return { c[1], c[2], c[3], a } end
    local S = T.ButtonLooks.standard

    -- Logbook tabs / Detail action: standard
    local b = button(true)
    T.SkinButton(b, S)
    expect("standard", b, "idle", { bg = H.bg, border = H.border, text = H.text })
    b:fire("OnEnter"); expect("standard", b, "hover", { bg = H.bgHover, border = H.borderHover, text = H.textHover })
    b:fire("OnLeave"); expect("standard", b, "leave", { bg = H.bg, border = H.border, text = H.text })
    b:SetLook("selected"); expect("standard", b, "selected", { bg = H.bgSel, border = H.borderSel, text = H.textSel })
    b:fire("OnEnter"); expect("standard", b, "selected+hover (ignored)", { bg = H.bgSel, border = H.borderSel, text = H.textSel })
    b:fire("OnLeave"); expect("standard", b, "selected+leave (ignored)", { bg = H.bgSel, border = H.borderSel, text = H.textSel })
    b:SetLook("active"); expect("detail", b, "active", { bg = H.gold, border = H.gold, text = H.ink })
    b:fire("OnEnter"); expect("detail", b, "active+hover (ignored)", { bg = H.gold, border = H.gold, text = H.ink })
    b:SetLook("disabled"); expect("detail", b, "disabled", { bg = H.disBg, border = H.disBorder, text = H.disText })
    b:SetLook("idle"); expect("detail", b, "earned", { bg = H.bg, border = H.border, text = H.text })

    -- Settings reset: icon goldDim -> gold
    b = button(true, true)
    T.SkinButton(b, T.ButtonVariant(S, { idle = { icon = { "goldDim" } }, hover = { icon = { "gold" } } }))
    expect("settings", b, "idle", { bg = H.bg, border = H.border, text = H.gold, icon = H.goldDim })
    b:fire("OnEnter"); expect("settings", b, "hover", { bg = H.bgHover, border = H.borderHover, text = H.textHover, icon = H.gold })
    b:fire("OnLeave"); expect("settings", b, "leave", { bg = H.bg, border = H.border, text = H.gold, icon = H.goldDim })

    -- What's New icon button: border constant, icon gold -> goldBright
    b = button(false, true)
    T.SkinButton(b, T.ButtonVariant(S, { idle = { text = false, icon = { "gold" } }, hover = { text = false, icon = { "goldBright" }, border = false } }))
    expect("whatsnew-icon", b, "idle", { bg = H.bg, border = H.border, icon = H.gold })
    b:fire("OnEnter"); expect("whatsnew-icon", b, "hover", { bg = H.bgHover, border = H.border, icon = H.textHover })
    b:fire("OnLeave"); expect("whatsnew-icon", b, "leave", { bg = H.bg, border = H.border, icon = H.gold })

    -- What's New label button: border constant
    b = button(true)
    T.SkinButton(b, T.ButtonVariant(S, { hover = { border = false } }))
    b:fire("OnEnter"); expect("whatsnew-label", b, "hover", { bg = H.bgHover, border = H.border, text = H.textHover })
    b:fire("OnLeave"); expect("whatsnew-label", b, "leave", { bg = H.bg, border = H.border, text = H.text })

    -- Detail favourite: text/icon left to RefreshFavButton
    b = button(true, true)
    T.SkinButton(b, T.ButtonVariant(S, { idle = { text = false }, hover = { text = false } }))
    expect("favourite", b, "idle", { bg = H.bg, border = H.border, textUntouched = true })
    b:fire("OnEnter"); expect("favourite", b, "hover", { bg = H.bgHover, border = H.borderHover, textUntouched = true })
    check(b.icon.c[1] == 9, "favourite: icon left to the site")

    -- About close: soft constant edge, text -> textHover
    b = button(true)
    T.SkinButton(b, T.ButtonVariant(S, { idle = { border = { "btnBorderSoft" } }, hover = { border = false, text = { "textHover" } } }))
    expect("about", b, "idle", { bg = H.bg, border = alpha(H.gold, 0.5), text = H.gold })
    b:fire("OnEnter"); expect("about", b, "hover", { bg = H.bgHover, border = alpha(H.gold, 0.5), text = H.aboutHover })
    b:fire("OnLeave"); expect("about", b, "leave", { bg = H.bg, border = alpha(H.gold, 0.5), text = H.gold })

    -- A flavour override reaches every button through the roles.
    T.Apply({ col = { btnBg = "203040" } })
    b = button(true)
    T.SkinButton(b, S)
    check(b.bg.c[1] == 0x20 / 255, "btnBg override reaches a new button")

    check(not pcall(T.SkinButton, button(true), { idle = { bg = { "nope" } } }), "unknown token in a look errors")
    check(not pcall(T.SkinButton, button(true), { idle = { glow = { "gold" } } }), "unknown part in a look errors")
    check(maxStep <= 2, "buttons within 2 8-bit steps of the original colours (largest " .. maxStep .. ")")
end

-- ---- Theme.tex ------------------------------------------------------------
do
    local ns, T = loadTheme()
    local gems = T.RarityGems32               -- what a UI file captures at load
    local before = gems[3]
    check(before == T.tex.rarity3 and T.RarityGems64[5] == T.tex.rarity5Large, "gem arrays built from Theme.tex")
    check(T.InlineTex("star", 12) == "|T" .. T.tex.star .. ":12:12|t", "InlineTex")
    check(not pcall(T.InlineTex, "nope"), "InlineTex errors on an unknown name")

    printed = {}
    T.Apply({ tex = { rarity3 = "Interface\\AddOns\\Epithet\\icons\\rarity\\x", lock = "Interface\\x\\lock",
                      notATexture = "a", star = 5, check = "" } })
    check(gems == T.RarityGems32 and gems[3] == "Interface\\AddOns\\Epithet\\icons\\rarity\\x", "gem override reaches the held array")
    check(T.tex.lock == "Interface\\x\\lock", "texture override applied")
    check(T.tex.notATexture == nil, "unknown texture not created")
    check(type(T.tex.star) == "string" and T.tex.check ~= "", "invalid texture values rejected")
    local joined = table.concat(printed, "\n")
    check(joined:find("unknown texture tex.notATexture", 1, true) and joined:find("invalid path for tex.star", 1, true)
        and joined:find("invalid path for tex.check", 1, true), "texture override problems reported")
end

print = realPrint
