local wezterm = require("wezterm")
local config = wezterm.config_builder()

----------------------------------------------------
-- 基本
----------------------------------------------------
config.automatically_reload_config = true
config.font_size = 14.0
config.use_ime = true
config.font = wezterm.font_with_fallback({
	"MesloLGS Nerd Font Mono",
	"Hiragino Kaku Gothic ProN",
})

----------------------------------------------------
-- 色・背景
----------------------------------------------------
-- kanagawa-paper (neovim) と揃えた配色
-- colors/*.toml は kanagawa-paper.nvim の extras/wezterm から取得
-- canvas (light) に切り替える場合は "kanagawa-paper-canvas" を指定
config.color_scheme = "kanagawa-paper-ink"

-- 以前の配色に戻す場合は下記のコメントを解除し、config.color_scheme を削除する
-- (config.colors は color_scheme より優先されるため、併用不可)
-- config.colors = {
-- 	foreground = "#CBE0F0",
-- 	background = "#011423",
-- 	cursor_bg = "#47FF9C",
-- 	cursor_border = "#47FF9C",
-- 	cursor_fg = "#011423",
-- 	selection_bg = "#033259",
-- 	selection_fg = "#CBE0F0",
-- 	ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
-- 	brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
-- }

-- Kanagawa (neovim) - wave palette
-- config.color_scheme = "Kanagawa (Gogh)"

config.window_background_opacity = 0.95
-- config.macos_window_background_blur = 20

----------------------------------------------------
-- タブ・ウィンドウ
----------------------------------------------------
-- タイトルバーを非表示
config.window_decorations = "RESIZE"
-- タブバーの表示
config.show_tabs_in_tab_bar = true
-- タブが一つの時は非表示
config.hide_tab_bar_if_only_one_tab = true
-- falseにするとタブバーの透過が効かなくなる
-- config.use_fancy_tab_bar = false

-- タブバーの透過
config.window_frame = {
	inactive_titlebar_bg = "none",
	active_titlebar_bg = "none",
}

-- タブバーを背景色に合わせる
config.window_background_gradient = {
	-- kanagawa-paper-ink の background
	colors = { "#1F1F28" },
	-- colors = { "#011423" },
}

-- タブの追加ボタンを非表示
config.show_new_tab_button_in_tab_bar = false
-- nightlyのみ使用可能

----------------------------------------------------
-- タブ表示のカスタム
----------------------------------------------------
-- タブの形をカスタマイズ
-- タブの左側の装飾
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
-- タブの右側の装飾
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	-- kanagawa-paper-ink のタブバー配色
	local background = "#2A2A37"
	local foreground = "#9e9b93"
	local edge_background = "none"
	if tab.is_active then
		background = "#c4b28a"
		foreground = "#1F1F28"
	end
	-- 以前の配色:
	-- local background = "#5c6d74"
	-- local foreground = "#FFFFFF"
	-- if tab.is_active then
	-- 	background = "#ae8b2d"
	-- 	foreground = "#FFFFFF"
	-- end
	local edge_foreground = background
	local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "
	return {
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_LEFT_ARROW },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_RIGHT_ARROW },
	}
end)

----------------------------------------------------
-- SSH ドメイン
----------------------------------------------------
-- ~/.ssh/config の Host エントリから SSH:<host> / SSHMUX:<host> を自動生成する。
-- SSH:<host>    = multiplexing "None" (リモートに wezterm 不要)
-- SSHMUX:<host> = multiplexing "WezTerm" (リモートに wezterm-mux-server が必要)
config.ssh_domains = wezterm.default_ssh_domains()

for _, dom in ipairs(config.ssh_domains) do
	-- リモートが POSIX shell である前提を置くと、pane 分割/タブ生成の際に
	-- OSC 7 で報告された CWD へ cd してからコマンドを起動してくれる。
	-- (multiplexing = "None" のドメインでのみ効く。リモート側の OSC 7 設定が前提)
	dom.assume_shell = "Posix"
end

----------------------------------------------------
-- keybinds
----------------------------------------------------
config.disable_default_key_bindings = true
config.keys = require("keybinds").keys
config.key_tables = require("keybinds").key_tables
config.leader = { key = "g", mods = "CTRL", timeout_milliseconds = 2000 }

return config
