-- =============================================================================
-- Epithet — Locale: Translator Alextend
-- NOTE: WoW Lua 5.1 does NOT support \xNN hex escapes. Use decimal byte escapes
--       (e.g. \226\128\148 = em dash) or plain ASCII.
-- =============================================================================
local _, ns = ...

-- Register the Simplified Chinese table into the locale registry. It is always loaded (no
-- GetLocale guard) so the language picker can offer it on any client; the active locale is
-- chosen by ns.ApplyLocale, and untranslated keys fall back to the English base
-- automatically (see enGB.lua). LocaleManager.lua loads first; this file just registers
-- its strings into ns.Locales.
ns.Locales = ns.Locales or {}

local L = {}
ns.Locales.zhCN = L

-- Shared punctuation glyphs (defined once in LocaleManager.lua).
local DOT, DASH = ns.Glyphs.DOT, ns.Glyphs.DASH

-- Window
L["WINDOW_TITLE"] = "头衔"
L["CLOSE"] = "关闭"

-- Header band
L["TITLES_EARNED"] = "已获得头衔"
L["TITLES_EARNED_OBTAINABLE"] = "已获得可获取头衔"
L["TOGGLE_ALL_TITLES"] = "在计数中显示所有头衔"
L["TOGGLE_OBTAINABLE_ONLY"] = "在计数中仅显示当前可获取的头衔"
L["TOGGLE_OBTAINABLE_LABEL"] = "仅限可获取"

-- Filter sidebar
L["SEARCH_PLACEHOLDER"] = "搜索头衔或来源..."
L["STATUS"] = "状态"
L["STATUS_ALL"] = "全部"
L["STATUS_EARNED"] = "已获得"
L["STATUS_UNEARNED"] = "未获得"
L["RARITY_TIER"] = "稀有程度"
L["TYPE"] = "类型"
L["EXPANSION"] = "资料片"
L["ADDITIONAL_FILTERS"] = "附加过滤"
L["RESET_ALL_FILTERS"] = "重置所有过滤"
L["FAVOURITES_ONLY"] = "仅收藏"
L["ADD_FAVOURITE"] = "添加到收藏"
L["REMOVE_FAVOURITE"] = "取消收藏"
L["PREFIX"] = "前缀"
L["SUFFIX"] = "后缀"

-- Rarity names
L["COMMON"] = "普通"
L["UNCOMMON"] = "优秀"
L["RARE"] = "精良"
L["EPIC"] = "史诗"
L["LEGENDARY"] = "传说"
L["UNRANKED"] = "未分级"

-- List header
L["N_TITLES"] = "%d 个头衔"
L["SORT_COLLECTED_FIRST"] = "已收集优先"
L["SORT_BY_EXPANSION"] = "按资料片"
L["SORT_ALPHABETICAL"] = "按首字母"
L["SORT_BY_QUALITY"] = "按品质"
L["SORT_BY_CATEGORY"] = "按分类"

-- Group headers
L["GROUP_COLLECTED"] = "已收集"
L["GROUP_NOT_COLLECTED"] = "未收集"

-- Detail panel
L["PREVIEW_HOVERING"] = "预览 " .. DASH .. " 悬停中"
L["PREFIX_TITLE"] = "前缀头衔"
L["SUFFIX_TITLE"] = "后缀头衔"
L["HOW_TO_OBTAIN"] = "如何获取"
-- Shown under the source card during hover preview when its content is taller
-- than the card, since the preview cannot be scrolled.
L["DETAIL_MORE_ON_SELECT"] = "选择此头衔以查看更多信息"
L["HELD_BY_ESTIMATE"] = "预计约有 %s%% 的活跃角色拥有此头衔。"
L["EXPANSION_LABEL"] = "资料片"
L["CATEGORY_LABEL"] = "分类"
L["AVAILABILITY_LABEL"] = "获取途径"
L["ACCOUNT_WIDE"] = "全账号通用"
L["NO_LONGER_OBTAINABLE"] = "绝版"
L["CURRENT_PATCH"] = "当前补丁 " .. DOT .. " 12.0.5"
L["EARNED_DATE"] = "获得于 %s"
L["NOT_YET_EARNED"] = "尚未获得"

-- Action footer
L["SET_AS_MY_TITLE"] = "设为我的头衔"
L["SET_NOTE"] = "在其他玩家眼中的名字下方显示。"
L["CURRENT_TITLE"] = "当前头衔"
L["CURRENT_NOTE"] = "该头衔会显示在你角色的上方。"
L["LOCKED_BUTTON"] = "尚未获得"
L["LOCKED_NOTE"] = "获得此头衔后即可将其设为自己的头衔。"

-- Empty states
L["NO_MATCH"] = "没有符合这些过滤条件的头衔。"
L["NO_SELECTION"] = "选择一个头衔以查看其来源和稀有度。"

-- Bottom bar / rarity legend
L["RARITY"] = "稀有度"
L["SOURCE_LEGEND"] = "来源"

-- Rarity explanation shown in the rarity info modal. Keep the wording in sync
-- with the rarity algorithm (TitlesDBCollector rarity.js).
L["RARITY_NOTE"] = "稀有度是一个 0-100 的百分比，用于估算该头衔在"..
    "活跃玩家群体中的普及程度。100 表示持有率最高，<1 表示极其稀有。根据外部" ..
    "角色统计数据（在线流行度数据源）计算得出。品质层级 (q) 反映了其声望度：" ..
    "由来源背景决定（如竞技场角斗士=5，团队副本成就=3等），并对极少数" ..
    "玩家持有的永久绝版头衔进行稀有度提档（绝版 + <2% 持有率 = 史诗" ..
    "起步，<5% = 精良起步）。"

-- Minimap
L["MINIMAP_TOOLTIP_TITLE"] = "Epithet"
L["MINIMAP_TOOLTIP_LEFT"] = "左键点击打开头衔浏览器。"
L["MINIMAP_TOOLTIP_RIGHT"] = "右键点击隐藏此按钮。"
L["MINIMAP_HIDDEN"] = "小地图按钮已隐藏。输入 /epithet minimap 可再次显示。"
L["MINIMAP_SHOWN"] = "小地图按钮已显示。"

-- What's New
L["WHATS_NEW_HEADING"] = "更新内容"
L["WHATS_NEW_CLOSE"] = "关闭"
L["WHATS_NEW_LINK_PROMPT"] = "复制此链接：\n下方已自动选中 - 按 Ctrl+C 复制。"

-- Social layer / title spotting
L["SOCIAL_LAYER"] = "头衔发现"
L["SOCIAL_LAYER_DESC"] = "观察路过的陌生人早已是一项核心乐趣。现在把视角延伸到他们的头衔上吧：发现其他玩家选择佩戴的头衔，并直接在 Epithet 中了解它的获取方式。"
L["SOCIAL_ENABLED"] = "启用头衔发现"
L["SOCIAL_STATE_SECTION"] = "功能状态"
L["SOCIAL_TARGET_UNLOCK"] = "解锁目标姓名板（拖动可移动）"
L["SOCIAL_TARGET_RESET"] = "重置目标姓名板位置"
L["SOCIAL_TARGET_EDIT_HINT"] = "编辑模式 · 左键拖动移动 · 右键点击锁定"
L["SOCIAL_TARGET_EDIT_TOP"] = "编辑模式"
L["SOCIAL_TARGET_EDIT_BOTTOM"] = "左键拖动移动 · 右键点击锁定"
L["SOCIAL_TARGET_TOOLTIP_LEFT"] = "左键点击在 Epithet 中查看此头衔。"
L["SOCIAL_TARGET_TOOLTIP_RIGHT"] = "右键点击解锁并移动此姓名板。"
L["SOCIAL_TARGET_PLACEHOLDER_TITLE"] = "示例头衔"
L["SOCIAL_TARGET_PLACEHOLDER_RARITY"] = "精良"
L["SOCIAL_PRESTIGE_FORMAT"] = "%s %s"
L["SOCIAL_LAYOUT_SECTION"] = "姓名板布局"
L["SOCIAL_LAYOUT_CLASSIC"] = "精简"
L["SOCIAL_LAYOUT_PORTRAIT"] = "头像卡片"
L["SOCIAL_LAYOUT_PREVIEW"] = "布局预览"
L["SOCIAL_LAYOUT_PREVIEW_NOTE"] = "预览使用的是示例数据。"
L["SOCIAL_LAYOUT_FUNNY_TOGGLE"] = "显示搞笑长头衔预览"
L["SOCIAL_LAYOUT_PORTRAIT_MODE"] = "目标头像模式"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_3D"] = "3D (动画)"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_2D"] = "2D (静态)"
L["SOCIAL_LAYOUT_PORTRAIT_MODE_NOTE"] = "3D 使用动态模型，2D 使用静态头像材质。"
L["SOCIAL_BEHAVIOUR_SECTION"] = "显示规则"
L["SOCIAL_FADE_SECTION"] = "淡出"
L["SOCIAL_FADE_ENABLE"] = "延迟后淡出目标姓名板"
L["SOCIAL_FADE_DURATION"] = "淡出延迟"
L["SOCIAL_FADE_DURATION_FMT"] = "%.1f 秒后淡出"
L["SOCIAL_SHOW_SELF_TARGET"] = "选中自己时显示目标姓名板"
L["SOCIAL_SELF_TARGET_NOTE"] = "显示自己的目标姓名板仅为视觉效果，选中自己绝不计入头衔发现成就。"
L["SOCIAL_SPOTTING_NOTIFY"] = "在聊天框显示头衔发现确认"
L["SOCIAL_ACHIEVEMENT_SECTION"] = "成就"
L["SOCIAL_ACHIEVEMENT_LAYER_DESC"] = "成就弹窗涵盖了你自己的头衔收集以及你在他人身上发现的头衔。在此处配置弹窗提醒方式 — 头衔发现功能本身可在下方区域开启。"
L["SOCIAL_ACHIEVEMENT_SPOTTING_DISABLED_NOTE"] = "头衔发现功能已关闭，因此发现相关成就无法推进。基于你自己头衔收集的成就仍会继续追踪。"
L["SOCIAL_ACHIEVEMENT_NOTIFY"] = "成就通知"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE"] = "成就通知模式"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_FULL"] = "弹窗 + 音效"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_SILENT"] = "仅弹窗（静音）"
L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_OFF"] = "关闭"
L["SOCIAL_ACHIEVEMENT_ANCHOR_MODE"] = "成就弹窗锚点"
L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT"] = "屏幕顶部 (UIParent)"
L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME"] = "匹配暴雪 AlertFrame"
L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT_DESC"] = "固定在屏幕顶部中央。如果 AlertFrame 被界面插件移动或隐藏，此选项最为可靠。"
L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME_DESC"] = "跟随暴雪成就/拾取提示区域。如果其他插件移动或隐藏了 AlertFrame，该弹窗也会随之移动。"
L["SOCIAL_POSITION_SECTION"] = "位置"

L["SPOTTING_NEW_SPOT_FMT"] = "发现头衔：%s"
L["SPOTTING_LOG_TOOLTIP"] = "头衔发现日志（已找到 %d 个）"
L["SPOTTING_LOG_TOOLTIP_LEFT"] = "左键点击：打开头衔发现日志。"
L["SPOTTING_LOG_TOOLTIP_RIGHT"] = "右键点击：在 /s 频道喊出你的发现统计。"
L["SPOTTING_LOG_SHOUT_FMT_1"] = "我已经以非常理智和正常的态度注视了 %d 位陌生人！"
L["SPOTTING_LOG_SHOUT_FMT_2"] = "我已经在 %d 位陌生人完全不知情且未许可的情况下观察了他们！"
L["SPOTTING_LOG_SHOUT_FMT_3"] = "我一直在暗中评判 %d 位陌生人的头衔！"
L["SPOTTING_LOG_SHOUT_FMT_4"] = "已经观察了 %d 位陌生人，没有一个人察觉。完美。"
L["SPOTTING_LOG_SHOUT_FMT_5"] = "我已经仅仅为了头衔跟踪了 %d 位毫无防备的冒险者！"
L["SPOTTING_LOG_HEADING"] = "头衔发现日志"
L["SPOTTING_LOG_COUNT_FMT"] = "已发现 %d 个头衔"
L["SPOTTING_LOG_COUNT_PROGRESS_FMT"] = "已发现 %d / %d 个头衔"
L["SPOTTING_LOG_COUNT_REMAINING_FMT"] = "剩余 %d 个头衔"
L["SPOTTING_LOG_EMPTY"] = "尚未发现任何头衔。在野外选中玩家作为目标，即可记录他们佩戴的头衔。"
L["SPOTTING_LOG_EMPTY_REMAINING"] = "当前图鉴中没有剩余未发现的头衔。"
L["SPOTTING_LOG_GATED"] = "头衔发现功能已关闭，未在记录任何目击信息。"
L["SPOTTING_LOG_OPEN_SETTINGS"] = "前往设置开启"
L["SPOTTING_SCOPE_SPOTTED"] = "已发现"
L["SPOTTING_SCOPE_REMAINING"] = "未发现"
L["SPOTTING_VIEW_LIST"] = "列表"
L["SPOTTING_VIEW_GRID"] = "网格"
L["SPOTTING_EXPORT_BUTTON"] = "导出"
L["SPOTTING_IMPORT_BUTTON"] = "导入"
L["SPOTTING_EXPORT_TITLE"] = "导出的头衔发现日志"
L["SPOTTING_IMPORT_TITLE"] = "导入头衔发现日志"
L["SPOTTING_TRANSFER_NOTE"] = "在下方复制或粘贴完整的有效载荷数据。"
L["SPOTTING_TRANSFER_COPY"] = "全选"
L["SPOTTING_TRANSFER_IMPORT"] = "导入"
L["SPOTTING_TRANSFER_CLOSE"] = "关闭"
L["SPOTTING_IMPORT_SUCCESS_FMT"] = "已成功导入 %d 条发现记录。"
L["SPOTTING_IMPORT_FAILED_FMT"] = "导入失败：%s"
L["SPOTTING_NOT_SPOTTED"] = "未发现"
L["SPOTTING_NOT_SPOTTED_YET"] = "尚未发现。"
L["SPOTTING_TOOLTIP_FIRST_FMT"] = "首次于 %3$s 在 %2$s 见于 %1$s"
L["SPOTTING_TOOLTIP_RACE_FMT"] = "种族：%s"
L["SPOTTING_TOOLTIP_RACE_UNKNOWN"] = "未知"
L["SPOTTING_TOOLTIP_COUNT_FMT"] = "已目击 %d 次"
L["SPOTTING_TOOLTIP_LAST_FMT"] = "最近一次见于 %s（角色：%s）"

L["SPOT_ACHV_MODE"] = "成就"
L["SPOT_ACHV_HEADING"] = "Epithet 成就"
L["SPOT_ACHV_TOOLTIP"] = "Epithet 成就"
L["SPOT_ACHV_TOOLTIP_LEFT"] = "左键点击：打开 Epithet 成就。"
L["SPOT_ACHV_EMPTY"] = "暂无可用的 Epithet 成就。"
L["SPOT_ACHV_META_TITLE"] = "成就追逐指南"
L["SPOT_ACHV_META_DESC"] = "要完成所有成就，你可能需要在不同职业、阵营、节日活动期间协调你的头衔发现，甚至需要与朋友或公会成员反复互动。"
L["SPOT_ACHV_COUNT_FMT"] = "已获得 %d / %d"
L["SPOT_ACHV_GROUP_SPOTTING"] = "头衔发现"
L["SPOT_ACHV_GROUP_COLLECTION"] = "头衔收集"
L["SPOT_ACHV_GROUP_CROSSOVERS"] = "联动互通"
L["SPOT_ACHV_SECRET_NAME"] = "？？？"
L["SPOT_ACHV_SECRET_DESC"] = "隐藏成就"
L["SPOT_ACHV_PROGRESS_FMT"] = "%d / %d"
L["SPOT_ACHV_PROGRESS_ON_CHAR_FMT"] = "当前角色进度 %d / %d"
L["SPOT_ACHV_EARNED_FMT"] = "获得于 %s"
L["SPOT_ACHV_ALERT_HEADER"] = "Epithet 成就"
L["SPOT_ACHV_CHAT_EARNED_FMT"] = "获得成就 — %s！"
L["SPOT_ACHV_DETAIL_WITH_FMT"] = "与 %s 共同达成"
L["SPOT_ACHV_DETAIL_CLASSES_FMT"] = "跨越 %s 个职业达成"
L["SPOT_ACHV_DETAIL_ZONE_FMT"] = "在 %s 达成"
L["SPOT_ACHV_DETAIL_TITLE_FMT"] = "由 %s 触发"
L["SPOT_ACHV_DETAIL_EXPANSIONS_FMT"] = "跨越 %s 个资料片达成"
L["SPOT_ACHV_DETAIL_SECRETS_FMT"] = "探索 %s 个秘密达成"
L["SPOT_ACHV_FWENDS_HINT"] = "仅统计你在他们身上第一次发现的头衔。"
L["SPOT_ACHV_DETAIL_TITLE"] = "成就详情"
L["SPOT_ACHV_DETAIL_CLOSE"] = "关闭"
L["SPOT_ACHV_DETAIL_SECRET_STATUS"] = "达成此成就以揭示详细信息。"
L["SPOT_ACHV_ADMIN_TEST_NAME"] = "管理员测试成就"
L["SPOT_ACHV_ADMIN_TEST_DESC"] = "手动由管理员触发的弹窗测试。"

L["SPOT_ACHV_NAME_COUNT_1"] = "初次目击"
L["SPOT_ACHV_DESC_COUNT_1"] = "在野外发现 1 个不同的头衔。"
L["SPOT_ACHV_NAME_COUNT_10"] = "火眼金睛"
L["SPOT_ACHV_DESC_COUNT_10"] = "在野外发现 10 个不同的头衔。"
L["SPOT_ACHV_NAME_COUNT_25"] = "田野笔记"
L["SPOT_ACHV_DESC_COUNT_25"] = "在野外发现 25 个不同的头衔。"
L["SPOT_ACHV_NAME_COUNT_50"] = "经验丰富的观察者"
L["SPOT_ACHV_DESC_COUNT_50"] = "在野外发现 50 个不同的头衔。"
L["SPOT_ACHV_NAME_COUNT_100"] = "社交距离不存在"
L["SPOT_ACHV_DESC_COUNT_100"] = "在野外发现 100 个不同的头衔。"
L["SPOT_ACHV_NAME_COUNT_200"] = "爱打听的老好人"
L["SPOT_ACHV_DESC_COUNT_200"] = "在野外发现 200 个不同的头衔。"
L["SPOT_ACHV_NAME_COUNT_350"] = "强迫症监视者"
L["SPOT_ACHV_DESC_COUNT_350"] = "在野外发现 350 个不同的头衔。"
L["SPOT_ACHV_NAME_COUNT_500"] = "活名录"
L["SPOT_ACHV_DESC_COUNT_500"] = "在野外发现 500 个不同的头衔。"
L["SPOT_ACHV_NAME_COUNT_700"] = "百鸟朝凤"
L["SPOT_ACHV_DESC_COUNT_700"] = "在野外发现 700 个不同的头衔。"

L["SPOT_ACHV_NAME_ROLL_CALL"] = "全员到齐"
L["SPOT_ACHV_DESC_ROLL_CALL"] = "在所有职业的角色身上都首次发现过头衔。"
L["SPOT_ACHV_NAME_FULL_SPECTRUM"] = "全谱系"
L["SPOT_ACHV_DESC_FULL_SPECTRUM"] = "在每个稀有度层级中都至少发现过一个头衔。"
L["SPOT_ACHV_NAME_BOTH_ENDS"] = "首尾呼应"
L["SPOT_ACHV_DESC_BOTH_ENDS"] = "至少发现过一个前缀头衔和一个后缀头衔。"
L["SPOT_ACHV_NAME_GRAND_TOUR"] = "壮游"
L["SPOT_ACHV_DESC_GRAND_TOUR"] = "在 10 个不同的区域中首次发现头衔。"
L["SPOT_ACHV_NAME_TITLE_FWENDS"] = "哦！头衔密友！"
L["SPOT_ACHV_DESC_TITLE_FWENDS"] = "在同一个玩家身上首次发现 10 个不同的头衔。"
L["SPOT_ACHV_NAME_HAVENT_WE_MET"] = "我们是不是在哪见过？"
L["SPOT_ACHV_DESC_HAVENT_WE_MET"] = "同一个头衔目击至少 10 次。"
L["SPOT_ACHV_NAME_LONG_CON"] = "放长线钓大鱼"
L["SPOT_ACHV_DESC_LONG_CON"] = "在首次发现某头衔至少 30 天后，再次目击该头衔。"
L["SPOT_ACHV_NAME_NIGHT_SHIFT"] = "夜班守候"
L["SPOT_ACHV_DESC_NIGHT_SHIFT"] = "在当地时间 03:00 至 04:59 之间首次发现一个头衔。"
L["SPOT_ACHV_NAME_BUSY_DAY"] = "忙碌的一天"
L["SPOT_ACHV_DESC_BUSY_DAY"] = "在同一个当地日期内首次发现至少 5 个头衔。"
L["SPOT_ACHV_NAME_CAPITAL_OFFENCE"] = "主城违法行动"
L["SPOT_ACHV_DESC_CAPITAL_OFFENCE"] = "在同一个区域内首次发现至少 10 个头衔。"
L["SPOT_ACHV_NAME_OLD_MONEY"] = "老派贵族"
L["SPOT_ACHV_DESC_OLD_MONEY"] = "发现一个已经绝版的头衔。"
L["SPOT_ACHV_NAME_LEGENDARY_SPOT"] = "收集癖的噩梦"
L["SPOT_ACHV_DESC_LEGENDARY_SPOT"] = "在野外发现一个传说品质的头衔。"
L["SPOT_ACHV_NAME_POTTED_HISTORY"] = "简明历史"
L["SPOT_ACHV_DESC_POTTED_HISTORY"] = "在每个资料片中都至少发现过一个头衔。"
L["SPOT_ACHV_NAME_DIPLOMATIC_IMMUNITY"] = "外交豁免权"
L["SPOT_ACHV_DESC_DIPLOMATIC_IMMUNITY"] = "至少发现一个联盟专属和一个部落专属的头衔。"
L["SPOT_ACHV_NAME_SMALL_WORLD"] = "世界真小"
L["SPOT_ACHV_DESC_SMALL_WORLD"] = "在两个不同的玩家身上看到同一个头衔。"
L["SPOT_ACHV_NAME_CREATURE_OF_HABIT"] = "习惯成自然"
L["SPOT_ACHV_DESC_CREATURE_OF_HABIT"] = "连续 7 个当地日期内，每天都首次发现至少一个头衔。"
L["SPOT_ACHV_NAME_SEEING_STARS"] = "眼冒金星"
L["SPOT_ACHV_DESC_SEEING_STARS"] = "发现 5 个传说品质的头衔。"
L["SPOT_ACHV_NAME_MUSEUM_CURATOR"] = "博物馆馆长"
L["SPOT_ACHV_DESC_MUSEUM_CURATOR"] = "发现 5 个来自已移除内容的头衔。"
L["SPOT_ACHV_NAME_GNOME_SPOTTER"] = "袖珍人口普查"
L["SPOT_ACHV_DESC_GNOME_SPOTTER"] = "发现 5 个首次在侏儒身上见到的头衔。"
L["SPOT_ACHV_NAME_AT_LEAST_CHICKEN"] = "至少我还有炸鸡"
L["SPOT_ACHV_DESC_AT_LEAST_CHICKEN"] = "发现有人佩戴“李洛伊 / 詹金斯”头衔。"
L["SPOT_ACHV_NAME_CERTIFIED"] = "精神正常认证"
L["SPOT_ACHV_DESC_CERTIFIED"] = "发现有人佩戴“疯子”头衔。"
L["SPOT_ACHV_NAME_OVERACHIEVER"] = "成就狂人"
L["SPOT_ACHV_DESC_OVERACHIEVER"] = "在头衔发现与收集分类中累计获得 15 个 Epithet 成就。"
L["SPOT_ACHV_NAME_GUISING"] = "万圣伪装"
L["SPOT_ACHV_DESC_GUISING"] = "在当地时间 10 月 31 日首次发现任意头衔。"
L["SPOT_ACHV_NAME_QUITE_A_MOUTHFUL"] = "相当拗口"
L["SPOT_ACHV_DESC_QUITE_A_MOUTHFUL"] = "发现一个图鉴文本长度在 25 个字符以上的头衔。"
L["SPOT_ACHV_NAME_TERSE"] = "简明扼要"
L["SPOT_ACHV_DESC_TERSE"] = "发现一个图鉴文本长度在 5 个字符或更短的头衔。"
L["SPOT_ACHV_NAME_LORD_OF_LORDS"] = "领主中的领主"
L["SPOT_ACHV_DESC_LORD_OF_LORDS"] = "发现 5 个包含“领主”或“Lord”的不同头衔。"
L["SPOT_ACHV_NAME_MASTERCLASS"] = "大师课"
L["SPOT_ACHV_DESC_MASTERCLASS"] = "发现 5 个包含“大师”或“Master”的不同头衔。"
L["SPOT_ACHV_NAME_SLAY"] = "屠戮殆尽"
L["SPOT_ACHV_DESC_SLAY"] = "发现 5 个包含“终结者/屠手”或“Slayer”的不同头衔。"
L["SPOT_ACHV_NAME_GLADIATOR_GROUPIE"] = "角斗士追随者"
L["SPOT_ACHV_DESC_GLADIATOR_GROUPIE"] = "发现 5 个来自 PvP 途径的头衔。"
L["SPOT_ACHV_NAME_RAID_SPECTATOR"] = "团队副本观战者"
L["SPOT_ACHV_DESC_RAID_SPECTATOR"] = "发现 5 个来自团队副本途径的头衔。"
L["SPOT_ACHV_NAME_BROWN_NOSER"] = "马屁精"
L["SPOT_ACHV_DESC_BROWN_NOSER"] = "发现 5 个来自声望途径的头衔。"
L["SPOT_ACHV_NAME_HOW_ITS_MADE"] = "造物探秘"
L["SPOT_ACHV_DESC_HOW_ITS_MADE"] = "分别发现来自成就、任务和物品途径的头衔。"
L["SPOT_ACHV_NAME_PEOPLE_WATCHER"] = "吃瓜群众"
L["SPOT_ACHV_DESC_PEOPLE_WATCHER"] = "累计记录 500 次目击。"
L["SPOT_ACHV_NAME_PROFESSIONAL_LURKER"] = "专业窥屏者"
L["SPOT_ACHV_DESC_PROFESSIONAL_LURKER"] = "累计记录 2,000 次目击。"
L["SPOT_ACHV_NAME_DOUBLE_TAKE"] = "恍然大悟"
L["SPOT_ACHV_DESC_DOUBLE_TAKE"] = "在首次发现某头衔后的 1 小时内再次目击该头衔。"
L["SPOT_ACHV_NAME_EARLY_BIRD"] = "早起的鸟儿"
L["SPOT_ACHV_DESC_EARLY_BIRD"] = "在当地时间 05:00 至 08:59 之间首次发现一个头衔。"
L["SPOT_ACHV_NAME_WEEKEND_WARRIOR"] = "周末战士"
L["SPOT_ACHV_DESC_WEEKEND_WARRIOR"] = "在周六或周日累计记录 10 次首次发现。"
L["SPOT_ACHV_NAME_FULL_WEEK"] = "完整的一周"
L["SPOT_ACHV_DESC_FULL_WEEK"] = "在一周的 7 天中每天都有记录首次发现。"
L["SPOT_ACHV_NAME_YEAR_IN_FIELD"] = "田野调查一整年"
L["SPOT_ACHV_DESC_YEAR_IN_FIELD"] = "在一年的 12 个月份中每个月都有记录首次发现。"
L["SPOT_ACHV_NAME_WELCOME_BACK"] = "欢迎回来"
L["SPOT_ACHV_DESC_WELCOME_BACK"] = "两次连续的首次发现记录之间至少间隔 90 天。"
L["SPOT_ACHV_NAME_FEAST_YOUR_EYES"] = "大饱眼福"
L["SPOT_ACHV_DESC_FEAST_YOUR_EYES"] = "在当地时间 12 月 25 日首次发现一个头衔。"
L["SPOT_ACHV_NAME_PARTICIPATION_AWARD"] = "阳光普照奖"
L["SPOT_ACHV_DESC_PARTICIPATION_AWARD"] = "在野外发现一个普通品质的头衔。"
L["SPOT_ACHV_NAME_SNEAKY_BEAKY"] = "鬼鬼祟祟"
L["SPOT_ACHV_DESC_SNEAKY_BEAKY"] = "首次在潜行者身上发现一个头衔。"
L["SPOT_ACHV_NAME_DEAD_MAN_WALKING"] = "行尸走肉"
L["SPOT_ACHV_DESC_DEAD_MAN_WALKING"] = "首次在死亡骑士身上发现一个头衔。"
L["SPOT_ACHV_NAME_OLD_SCHOOL"] = "复古怀旧"
L["SPOT_ACHV_DESC_OLD_SCHOOL"] = "发现一个经典旧世时期的头衔。"
L["SPOT_ACHV_NAME_POPULAR"] = "交际花"
L["SPOT_ACHV_DESC_POPULAR"] = "有 3 位不同的玩家，每个人都贡献了 5 次及以上的首次发现。"
L["SPOT_ACHV_NAME_RESTRAINING_ORDER"] = "限制令"
L["SPOT_ACHV_DESC_RESTRAINING_ORDER"] = "同一个头衔目击至少 25 次。"
L["SPOT_ACHV_NAME_BEYOND_THE_GRAVE"] = "跨越生死"
L["SPOT_ACHV_DESC_BEYOND_THE_GRAVE"] = "在自己处于死亡或灵魂状态时记录一次目击。"
L["SPOT_ACHV_NAME_KNOW_THY_ENEMY"] = "知己知彼"
L["SPOT_ACHV_DESC_KNOW_THY_ENEMY"] = "在敌对阵营玩家身上记录一次目击。"
L["SPOT_ACHV_NAME_SECRET_KEEPER"] = "秘密守护者"
L["SPOT_ACHV_DESC_SECRET_KEEPER"] = "达成当前定义的每一个隐藏成就。"

L["SPOT_ACHV_NAME_OWNED_1"] = "行不更名"
L["SPOT_ACHV_DESC_OWNED_1"] = "当前角色拥有 1 个头衔。"
L["SPOT_ACHV_NAME_OWNED_10"] = "名头响亮"
L["SPOT_ACHV_DESC_OWNED_10"] = "当前角色拥有 10 个头衔。"
L["SPOT_ACHV_NAME_OWNED_25"] = "地头蛇"
L["SPOT_ACHV_DESC_OWNED_25"] = "当前角色拥有 25 个头衔。"
L["SPOT_ACHV_NAME_OWNED_50"] = "显赫贵族"
L["SPOT_ACHV_DESC_OWNED_50"] = "当前角色拥有 50 个头衔。"
L["SPOT_ACHV_NAME_OWNED_100"] = "宏大妄想"
L["SPOT_ACHV_DESC_OWNED_100"] = "当前角色拥有 100 个头衔。"
L["SPOT_ACHV_NAME_OWNED_SPECTRUM"] = "盛装盛宴"
L["SPOT_ACHV_DESC_OWNED_SPECTRUM"] = "在每个稀有度层级中都至少拥有一个头衔。"
L["SPOT_ACHV_NAME_OWNED_BOTH_ENDS"] = "名实相符"
L["SPOT_ACHV_DESC_OWNED_BOTH_ENDS"] = "至少拥有一个前缀头衔和一个后缀头衔。"
L["SPOT_ACHV_NAME_OWNED_LEGENDARY"] = "身价翻倍"
L["SPOT_ACHV_DESC_OWNED_LEGENDARY"] = "拥有一个传说品质的头衔。"
L["SPOT_ACHV_NAME_OWNED_REMOVED"] = "绝版收藏"
L["SPOT_ACHV_DESC_OWNED_REMOVED"] = "拥有一个来自已移除内容的头衔。"
L["SPOT_ACHV_NAME_IMPULSE_PURCHASE"] = "冲动消费"
L["SPOT_ACHV_DESC_IMPULSE_PURCHASE"] = "在首次发现某头衔后的 7 天内获得了该头衔。"
L["SPOT_ACHV_NAME_CURRICULUM_VITAE"] = "履历表"
L["SPOT_ACHV_DESC_CURRICULUM_VITAE"] = "当前角色在每个资料片中都至少拥有一个头衔。"
L["SPOT_ACHV_NAME_DECORATED_VETERAN"] = "身经百战"
L["SPOT_ACHV_DESC_DECORATED_VETERAN"] = "当前角色拥有 5 个来自 PvP 途径的头衔。"
L["SPOT_ACHV_NAME_NOTHING_NEW"] = "太阳底下无新事"
L["SPOT_ACHV_DESC_NOTHING_NEW"] = "在拥有至少 10 个头衔的前提下，这些头衔全都在野外被人佩戴并发现过。"
L["SPOT_ACHV_NAME_MATCHING_SET"] = "成套搭配"
L["SPOT_ACHV_DESC_MATCHING_SET"] = "在每个稀有度层级中，都至少同时拥有并发现过一个该层级的头衔。"

L["SPOT_ACHV_NAME_TAKES_ONE"] = "半斤八两"
L["SPOT_ACHV_DESC_TAKES_ONE"] = "在野外发现一个当前角色已经拥有的头衔。"
L["SPOT_ACHV_NAME_WINDOW_SHOPPER"] = "橱窗顾客"
L["SPOT_ACHV_DESC_WINDOW_SHOPPER"] = "获得了你最初在其他人身上发现的头衔。"
L["SPOT_ACHV_NAME_TWINSIES"] = "撞衫啦"
L["SPOT_ACHV_DESC_TWINSIES"] = "在你和对方佩戴完全相同的头衔时目击了对方。"

-- Source kinds
L["KIND_ACHIEVEMENT"] = "成就"
L["KIND_QUEST"] = "任务"
L["KIND_REPUTATION"] = "声望"
L["KIND_PVP_RANK"] = "PvP 等级"
L["KIND_FEAT"] = "光辉事迹"
L["KIND_ITEM"] = "物品"
L["KIND_PROMOTION"] = "促销/联动"

-- Filter facets (new)
L["CATEGORY"] = "分类"
L["KIND"] = "来源类型"
L["FACTION"] = "阵营"
L["FACTION_ALLIANCE"] = "联盟"
L["FACTION_HORDE"] = "部落"
L["FACTION_BOTH"] = "双阵营"
L["AVAILABILITY"] = "获取途径"
L["HIDE_UNOBTAINABLE"] = "隐藏绝版"
L["HIDE_TIME_SENSITIVE"] = "隐藏限时"
L["UNKNOWN_SOURCE"] = "未知来源"
L["FEAT_OF_STRENGTH"] = "光辉事迹（可能绝版）"

-- Source descriptions
L["SOURCE_ACHIEVEMENT_DESC"] = "由成就 %s 奖励"
L["SOURCE_QUEST_DESC"] = "在任务 %s 期间获得"
L["SOURCE_ITEM_DESC"] = "由 %s 赋予"

-- Meta grid
L["LAST_ASSESSED"] = "上次评估"

-- Availability labels
L["AVAILABILITY_SEASONAL"] = "季节性"
L["AVAILABILITY_LIMITED"] = "限时"
L["AVAILABILITY_PROMOTIONAL"] = "活动/促销"
L["AVAILABILITY_TEMPORARY"] = "临时"
L["AVAILABILITY_REMOVED"] = "已移除"
L["AVAILABILITY_PERMANENT"] = "常驻"

-- Previously-missing keys (had inline English fallbacks in code)
L["SOCIAL_HIDE_IN_COMBAT"] = "战斗中隐藏目标姓名板"
L["SOCIAL_HIDE_IN_GROUP"] = "组队时隐藏目标姓名板"
L["SPOTTING_META_TITLE"] = "发现笔记"
L["SPOTTING_META_DESC"] = "在开放世界中选中玩家，记录他们佩戴的头衔。"
L["SPOT_ACHV_SECRET_EARNED_SUFFIX"] = "（隐藏）"
L["SPOT_ACHV_SECRET_EARNED_NOTE"] = "你揭开了独立隐藏成就。"

-- Window banner (main frame title bar)
L["BANNER_LEFT"] = "EPITHET"
L["BANNER_RIGHT"] = "头衔展台"

-- Type tags (uppercase pills on title rows)
L["TYPE_TAG_PREFIX"] = "前缀"
L["TYPE_TAG_SUFFIX"] = "后缀"

-- Rarity fallback
L["RARITY_UNKNOWN"] = "未知"

-- Minimap tooltip collected line
L["MINIMAP_TOOLTIP_COLLECTED"] = "已收集：%d / %d"

-- Slash command feedback
L["SLASH_SCAN_COMPLETE"] = "头衔扫描完成：%d / %d"

-- Version footer (two rows). %s placeholders filled at runtime.
L["VERSION_LINE1_FMT"] = "Epithet v%s  " .. DOT .. "  Interface %s"
L["VERSION_LINE2_FMT"] = "TitlesDB v%s  " .. DOT .. "  更新于 %s"
L["VERSION_DATE_UNKNOWN"] = "未知"

-- Source-kind legend (bottom bar hover labels)
L["LEGEND_ACHIEVEMENT"] = "成就"
L["LEGEND_QUEST"] = "任务"
L["LEGEND_REPUTATION"] = "声望"
L["LEGEND_PVP"] = "PvP"
L["LEGEND_FEAT"] = "光辉事迹"
L["LEGEND_EXPLORATION"] = "探索"
L["LEGEND_RAID"] = "团队副本"

-- Layout preview sample data
L["SAMPLE_TITLE"] = "垃圾大师"
L["SAMPLE_RARITY"] = "传说"
L["SAMPLE_FUNNY_TITLE"] = "愚蠢、无能和令人失望的仆从的终结者"

-- Fade slider bound labels
L["FADE_SLIDER_LOW"] = "0.5秒"
L["FADE_SLIDER_HIGH"] = "20秒"

-- Month names (used to format achievement earned dates: "dd Month yyyy")
L["MONTH_1"] = "1月"
L["MONTH_2"] = "2月"
L["MONTH_3"] = "3月"
L["MONTH_4"] = "4月"
L["MONTH_5"] = "5月"
L["MONTH_6"] = "6月"
L["MONTH_7"] = "7月"
L["MONTH_8"] = "8月"
L["MONTH_9"] = "9月"
L["MONTH_10"] = "10月"
L["MONTH_11"] = "11月"
L["MONTH_12"] = "12月"

-- Expansion names (filter sidebar, detail panel, list rows). Keyed to match
-- the DB's stable expansion codes uppercased, e.g. "tbc" -> EXPANSION_TBC.
L["EXPANSION_CLASSIC"] = "经典旧世"
L["EXPANSION_TBC"] = "燃烧的远征"
L["EXPANSION_WRATH"] = "巫妖王之怒"
L["EXPANSION_CATA"] = "大地的裂变"
L["EXPANSION_MOP"] = "熊猫人之谜"
L["EXPANSION_WOD"] = "德拉诺之王"
L["EXPANSION_LEGION"] = "军团再临"
L["EXPANSION_BFA"] = "争霸艾泽拉斯"
L["EXPANSION_SL"] = "暗影国度"
L["EXPANSION_DF"] = "巨龙时代"
L["EXPANSION_TWW"] = "地心之战"
L["EXPANSION_MID"] = "至暗之夜"

-- Category names (filter sidebar, detail panel, list rows, group headers).
-- Keyed to match the DB's stable category codes uppercased, e.g. "PvP" -> CAT_PVP.
L["CAT_PVP"] = "PvP"
L["CAT_RAID"] = "团队副本"
L["CAT_REPUTATION"] = "声望"
L["CAT_QUEST"] = "任务"
L["CAT_PROFESSION"] = "专业技能"
L["CAT_HOLIDAY"] = "节日"
L["CAT_EXPLORATION"] = "探索"
L["CAT_ACHIEVEMENT"] = "成就"
L["CAT_CAMPAIGN"] = "战役"
L["CATEGORY_UNCATEGORIZED"] = "未分类"

-- Detail panel meta-grid row labels
L["EARNED_LABEL"] = "获得"
L["STATUS_LABEL"] = "状态"

-- "ACTIVE" chip on the currently-equipped title's list row
L["ACTIVE_TITLE"] = "使用中"

-- About / info modal ("Grimmsforge" and "World of Warcraft" stay as-is: brands)
L["ABOUT_CRAFTED"] = "Epithet 由 Grimmsforge 精心打造。"
L["ABOUT_TAGLINE"] = "适用于《魔兽世界》的开源工具与插件。"

-- Title-bar settings button
L["SETTINGS_BUTTON_TOOLTIP"] = "打开 Epithet 设置"
L["INFO_BUTTON_TOOLTIP"] = "关于 Epithet"

-- Language names (shown in the picker, in the active language)
L["LANGUAGE_ENGLISH"] = "英语"
L["LANGUAGE_RUSSIAN"] = "俄语"
L["LANGUAGE_GERMAN"] = "德语"
L["LANGUAGE_FRENCH"] = "法语"
L["LANGUAGE_SIMPLIFIED_CHINESE"] = "简体中文"

-- Options: general section (main Epithet settings page)
L["OPTIONS_GENERAL_SECTION"] = "常规"
L["OPTIONS_GENERAL_DESC"] = "应用于 Epithet 全局的设置。"
L["OPTIONS_STARTUP_SECTION"] = "启动"
L["OPTIONS_WHATSNEW_STARTUP_TOGGLE"] = "更新后显示“更新内容”"
L["OPTIONS_WHATSNEW_STARTUP_NOTE"] = "仅在登录新版本时显示一次。你随时可以通过输入 /epithet whatsnew 重新打开它。"

-- Options: language section
L["OPTIONS_LANGUAGE_SECTION"] = "语言"
L["OPTIONS_LANGUAGE_LABEL"] = "插件语言"
L["OPTIONS_LANGUAGE_AUTO"] = "自动（客户端默认）"
L["OPTIONS_LANGUAGE_NOTE"] = "设置 Epithet 使用的语言，独立于你的游戏客户端。更改后需要重新加载界面。"
L["OPTIONS_LANGUAGE_RELOAD_PROMPT"] = "是否立即更改 Epithet 的语言并重新加载界面？"
L["RELOAD_NOW"] = "立即重载"
L["LATER"] = "稍后"

-- The locale registry, ns.L proxy, and resolution API live in LocaleManager.lua.
