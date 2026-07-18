local wezterm = require("wezterm")
local act = wezterm.action

-- =========================================================
-- copy_mode で Vim風の数字プレフィックス(count)を扱うヘルパ
--   例: 40j で下に40行移動
-- =========================================================
-- モジュールローカルに count を保持 (configリロードでリセットされる)
local copy_mode_count = ""
local COPY_MODE_COUNT_MAX = 10000

-- 数字キーを押したら count に積む action
local function count_digit(d)
	return wezterm.action_callback(function()
		copy_mode_count = copy_mode_count .. d
	end)
end

-- 貯めた count の回数だけ movement を実行してリセットする action
local function repeatable(movement)
	return wezterm.action_callback(function(window, pane)
		local n = tonumber(copy_mode_count) or 1
		copy_mode_count = ""
		if n < 1 then
			n = 1
		elseif n > COPY_MODE_COUNT_MAX then
			n = COPY_MODE_COUNT_MAX
		end
		for _ = 1, n do
			window:perform_action(act.CopyMode(movement), pane)
		end
	end)
end

-- count を捨てる (movement以外のキーで pending な数字をクリアする)
local function reset_count(action)
	return wezterm.action_callback(function(window, pane)
		copy_mode_count = ""
		window:perform_action(action, pane)
	end)
end

-- Show which key table is active in the status area
wezterm.on("update-right-status", function(window, pane)
	local name = window:active_key_table()
	if name then
		name = "TABLE: " .. name
	end
	window:set_right_status(name or "")
end)

return {

	keys = {
		-- =========================================================
		-- tmux風 <leader>(Ctrl+G) 操作
		-- =========================================================
		-- ペイン分割: <leader> | で左右分割 / <leader> - または " で上下分割
		{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = '"', mods = "LEADER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

		-- ペイン移動: <leader> → hjkl (vim風)
		{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
		{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
		{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

		-- ペインを閉じる / ズーム切替
		{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

		-- ペインサイズ調整モードへ (<leader> r → hjklで調整、Esc/Enterで抜ける)
		{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

		-- タブ操作 (tmuxのwindow相当): <leader> c で新規、n/p で前後移動
		{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
		{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },

		-- コピーモード: <leader> [ (tmux準拠) / 入る時に count をリセット
		{ key = "[", mods = "LEADER", action = reset_count(act.ActivateCopyMode) },

		-- SSHドメインに接続: <leader> a (Attach)
		-- ここで SSH:d59 を選ぶと、以降その pane を分割してもリモートの CWD を引き継ぐ
		{
			key = "a",
			mods = "LEADER",
			action = act.ShowLauncherArgs({ flags = "FUZZY|DOMAINS", title = "Attach domain" }),
		},

		-- =========================================================
		-- ワークスペース操作
		-- =========================================================
		{
			-- Cmd + Shift + s: ワークスペース選択
			key = "s",
			mods = "SUPER|SHIFT",
			action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Select workspace" }),
		},
		{
			-- Cmd + Shift + r: ワークスペース名変更 (Rename)
			key = "r",
			mods = "SUPER|SHIFT",
			action = act.PromptInputLine({
				description = "(wezterm) Set workspace title:",
				action = wezterm.action_callback(function(win, pane, line)
					if line then
						wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
					end
				end),
			}),
		},
		{
			-- Cmd + Shift + n: 新規ワークスペース作成 (New)
			key = "n",
			mods = "SUPER|SHIFT",
			action = act.PromptInputLine({
				description = "(wezterm) Create new workspace:",
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
					end
				end),
			}),
		},

		-- =========================================================
		-- ペイン(画面)操作
		-- =========================================================
		-- Cmd + d: 右に分割 (Duplicate/Divide)
		{ key = "d", mods = "SUPER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		-- Cmd + Shift + d: 下に分割
		{ key = "d", mods = "SUPER|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

		-- Cmd + Shift + w: ペインを閉じる
		{ key = "w", mods = "SUPER|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },

		-- Cmd + z: ズーム切替 (現在のペインを最大化)
		{ key = "z", mods = "SUPER", action = act.TogglePaneZoomState },

		-- ペイン移動: Cmd + Ctrl + hjkl
		-- (Cmd+hなどはOSショートカットと被るためCtrlを追加)
		{ key = "h", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Left") },
		{ key = "l", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Right") },
		{ key = "k", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Up") },
		{ key = "j", mods = "SUPER|CTRL", action = act.ActivatePaneDirection("Down") },

		-- ペインサイズ調整モードへ (Cmd + r)
		{ key = "r", mods = "SUPER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

		-- =========================================================
		-- タブ操作
		-- =========================================================
		-- Cmd + t: 新規タブ
		{ key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },
		-- Cmd + w: タブを閉じる
		{ key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = true }) },

		-- タブ移動 (Cmd + Shift + [ / ]) ブラウザ準拠
		{ key = "[", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(-1) },
		{ key = "]", mods = "SUPER|SHIFT", action = act.ActivateTabRelative(1) },
		-- タブ移動 (Ctrl + Tab)
		{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
		{ key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },

		-- タブ入れ替え (Cmd + Ctrl + [ / ])
		{ key = "[", mods = "SUPER|CTRL", action = act.MoveTabRelative(-1) },
		{ key = "]", mods = "SUPER|CTRL", action = act.MoveTabRelative(1) },

		-- タブ切り替え Cmd + 1~9
		{ key = "1", mods = "SUPER", action = act.ActivateTab(0) },
		{ key = "2", mods = "SUPER", action = act.ActivateTab(1) },
		{ key = "3", mods = "SUPER", action = act.ActivateTab(2) },
		{ key = "4", mods = "SUPER", action = act.ActivateTab(3) },
		{ key = "5", mods = "SUPER", action = act.ActivateTab(4) },
		{ key = "6", mods = "SUPER", action = act.ActivateTab(5) },
		{ key = "7", mods = "SUPER", action = act.ActivateTab(6) },
		{ key = "8", mods = "SUPER", action = act.ActivateTab(7) },
		{ key = "9", mods = "SUPER", action = act.ActivateTab(-1) },

		-- =========================================================
		-- その他便利機能
		-- =========================================================
		-- コピーモード: Cmd + x (eXtract のイメージ)
		{ key = "x", mods = "SUPER", action = reset_count(act.ActivateCopyMode) },

		-- フルスクリーン: Cmd + Enter
		{ key = "Enter", mods = "SUPER", action = act.ToggleFullScreen },

		-- コマンドパレット: Cmd + p
		{ key = "p", mods = "SUPER", action = act.ActivateCommandPalette },

		-- ペイン選択モード: Cmd + Shift + p
		{ key = "p", mods = "SUPER|SHIFT", action = act.PaneSelect },

		-- フォントサイズ
		{ key = "+", mods = "SUPER", action = act.IncreaseFontSize },
		{ key = "-", mods = "SUPER", action = act.DecreaseFontSize },
		{ key = "0", mods = "SUPER", action = act.ResetFontSize },

		-- 設定リロード: Cmd + Ctrl + r
		{ key = "r", mods = "SHIFT|CTRL", action = act.ReloadConfiguration },

		-- クリップボード
		{ key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
	},

	-- =========================================================
	-- キーテーブル
	-- =========================================================
	key_tables = {
		-- Resize mode (Cmd+r で入る)
		resize_pane = {
			{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "Escape", action = "PopKeyTable" },
		},
		-- Copy mode (Cmd+x で入る)
		copy_mode = {
			-- 数字プレフィックス(count): 1-9 を貯める。0 は count 継続中のみ数字扱い
			{ key = "1", mods = "NONE", action = count_digit("1") },
			{ key = "2", mods = "NONE", action = count_digit("2") },
			{ key = "3", mods = "NONE", action = count_digit("3") },
			{ key = "4", mods = "NONE", action = count_digit("4") },
			{ key = "5", mods = "NONE", action = count_digit("5") },
			{ key = "6", mods = "NONE", action = count_digit("6") },
			{ key = "7", mods = "NONE", action = count_digit("7") },
			{ key = "8", mods = "NONE", action = count_digit("8") },
			{ key = "9", mods = "NONE", action = count_digit("9") },

			-- カーソル移動 (count 対応)
			{ key = "h", mods = "NONE", action = repeatable("MoveLeft") },
			{ key = "j", mods = "NONE", action = repeatable("MoveDown") },
			{ key = "k", mods = "NONE", action = repeatable("MoveUp") },
			{ key = "l", mods = "NONE", action = repeatable("MoveRight") },
			{ key = "^", mods = "NONE", action = reset_count(act.CopyMode("MoveToStartOfLineContent")) },
			{ key = "$", mods = "NONE", action = reset_count(act.CopyMode("MoveToEndOfLineContent")) },
			-- 0: count 継続中なら数字、そうでなければ行頭へ (vim準拠)
			{
				key = "0",
				mods = "NONE",
				action = wezterm.action_callback(function(window, pane)
					if copy_mode_count == "" then
						window:perform_action(act.CopyMode("MoveToStartOfLine"), pane)
					else
						copy_mode_count = copy_mode_count .. "0"
					end
				end),
			},
			{ key = "o", mods = "NONE", action = reset_count(act.CopyMode("MoveToSelectionOtherEnd")) },
			{ key = "O", mods = "NONE", action = reset_count(act.CopyMode("MoveToSelectionOtherEndHoriz")) },
			{ key = ";", mods = "NONE", action = reset_count(act.CopyMode("JumpAgain")) },
			{ key = "w", mods = "NONE", action = repeatable("MoveForwardWord") },
			{ key = "b", mods = "NONE", action = repeatable("MoveBackwardWord") },
			{ key = "e", mods = "NONE", action = repeatable("MoveForwardWordEnd") },
			{ key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
			{ key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
			{ key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
			{ key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
			{ key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
			{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
			{ key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
			{ key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
			{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
			{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			-- y: ヤンクしてコピーモードを抜ける (vim/tmux準拠)
			{
				key = "y",
				mods = "NONE",
				action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
			},
			{
				key = "Enter",
				mods = "NONE",
				action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
			},
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "c", mods = "CTRL", action = act.CopyMode("Close") },
			{ key = "q", mods = "NONE", action = act.CopyMode("Close") },
		},
	},
}
