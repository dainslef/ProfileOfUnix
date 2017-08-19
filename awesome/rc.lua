-- Load library
require("awful.autofocus")
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")
local menubar = require("menubar")
local beautiful = require("beautiful")

-- Load vicious widgets
local vicious = require("vicious")
vicious.contrib = require("vicious.contrib")



-- {{{ Init

-- Custom init command
awful.spawn.with_shell("xset +dpms") -- Use the power manager
awful.spawn.with_shell("xset dpms 0 0 1800") -- Set the power manager timeout to 30 minutes
awful.spawn.with_shell("xset s 1800") -- Set screensaver timeout to 30 mintues

-- }}}



-- {{{ Error handling

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors
	})
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure we don't go into an endless error loop
		if in_error then return end
		in_error = true
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = err
		})
		in_error = false
	end)
end

-- }}}



-- {{{ Variable definitions

-- Init theme
beautiful.init(awful.util.get_themes_dir() .. "default/theme.lua")
local theme = beautiful.get()

-- Custom theme settings, border and font
theme.border_width = 2
theme.font = "Dejavu Sans 10"
theme.master_width_factor = 0.6 -- Set the master window percent
theme.useless_gap = 5 -- Set the window gap

-- Color settings, the last two bits are alpha channels
local color_transparent = "#00000000"
local color_menu_bg = "#33445566"
local color_task_tag_focus = "#55667788"
local color_naughty_bg = "#00112288"

theme.bg_normal = color_transparent -- Set background transparent
theme.bg_minimize = color_transparent -- Set the minimize color of taskbar
theme.menu_bg_normal = color_menu_bg
theme.menu_fg_normal = theme.fg_focus
theme.menu_border_color = theme.border_focus
theme.taglist_bg_focus = color_task_tag_focus -- Set the focus color of taglist
theme.tasklist_bg_focus = color_task_tag_focus -- Set the focus color of taskbar
theme.notification_bg = color_naughty_bg
theme.notification_fg = theme.fg_focus

-- This is used later as the default terminal and editor to run
local mail = "thunderbird"
local terminal = "vte"
local browser = "google-chrome-stable"
local dictionary = "stardict"
local file_manager = "ranger"
local terminal_args = " -W -P never -g 120x40 -f \"Monaco 10\" -n 5000 --reverse"

-- Set default editor
local editor = os.getenv("EDITOR") or "nano"

-- Set main key
local mod_key = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts = {
	-- awful.layout.suit.floating,
	awful.layout.suit.spiral, -- master in left
	-- awful.layout.suit.magnifier, -- focus in center
	-- awful.layout.suit.corner.nw,
	-- awful.layout.suit.corner.ne,
	awful.layout.suit.corner.sw,
	-- awful.layout.suit.corner.se,
	-- awful.layout.suit.spiral.dwindle,
	-- awful.layout.suit.fair, -- equal division
	-- awful.layout.suit.fair.horizontal,
	-- awful.layout.suit.tile,
	-- awful.layout.suit.tile.left,
	awful.layout.suit.tile.bottom, -- master in top
	-- awful.layout.suit.tile.top,
	-- awful.layout.suit.max,
	-- awful.layout.suit.max.fullscreen,
}

-- }}}



-- {{{ Load auto run apps.

function run_once(cmd)
	awful.spawn.with_shell("pgrep -u $USER -x " .. cmd .. "; or " .. cmd)
end

local auto_run_list = {
	"fcitx", -- Use input method
	"xcompmgr", -- For transparent support
	"light-locker", -- Lock screen need to load it first
	"nm-applet", -- Show network status
	-- "blueman-applet", -- Use bluetooth
}

for i = 1, #auto_run_list do
	run_once(auto_run_list[i])
end

-- }}}



-- {{{ Wallpaper

local wall_paper = "/home/dainslef/Pictures/34844544_p0.png"
if beautiful.wallpaper then
	for s = 1, screen.count() do
		gears.wallpaper.maximized(wall_paper, s, true)
	end
end

-- }}}



-- {{{ Tags

-- Define a tag table which hold all screen tags.
-- local tag_names = { "①", "②", "③", "④" }
local tags = {}
local tag_properties = {
	{ "❶", layouts[1] },
	{ "❷", layouts[2] },
	{ "❸", layouts[2] },
	{ "❹", layouts[3] }
}

-- Each screen has its own tag table.
for s = 1, screen.count() do
	-- Use operate # to get lua table's size.
	for i = 1, #tag_properties do
		tags[i] = awful.tag.add(tag_properties[i][1], {
			screen = s,
			layout = tag_properties[i][2],
			selected = i == 1 and true or false -- Only focus on index one.
		})
	end
end

-- }}}



-- {{{ Menu

-- Create menu items
local home_path = "/home/dainslef"
local awesome_menu = {
	{ "RestartWM", awesome.restart },
	{ "QuitWM", awesome.quit },
	{ "Suspend", "systemctl suspend" },
	{ "PowerOff", "poweroff" }
}
local develop_menu = {
	{ "QtCreator", "qtcreator" },
	{ "QtAssistant", "assistant-qt5" },
	{ "QtDesigner", "designer-qt5" },
	{ "GVIM", "gvim" },
	{ "VSCode", home_path .. "/Public/VSCode-linux-x64/code" },
	{ "IDEA", home_path .. "/Public/idea-IU/bin/idea.sh" }
}
local tools_menu = {
	{ "Files", file_manager },
	{ "Browser", browser },
	{ "StarDict", dictionary },
	{ "VLC", "vlc" }
}
local system_menu = {
	{ "Terminal", terminal },
	{ "VirtualBox", "virtualbox" },
	{ "GParted", "gparted" }
}

-- Add menu items to main menu
local main_menu = awful.menu({
	items = {
		{ "Awesome", awesome_menu, beautiful.awesome_icon },
		{ "Develop", develop_menu },
		{ "Tools", tools_menu },
		{ "System", system_menu },
		{ "Mail", mail },
		{ "Files", terminal .. terminal_args  .. " -c " .. file_manager },
		{ "Browser", browser }
	}
})

-- Create launcher and set menu
local launcher = awful.widget.launcher({
	image = beautiful.awesome_icon,
	menu = main_menu
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it

-- }}}



-- {{{ Wibox

-- Create a textclock widget
local text_clock = wibox.widget.textclock(" <span font='Dejavu Sans 10'>" ..
	"[ %b %d <span color='red'>%a</span> ⇔ <span color='yellow'>%H:%M</span> ]</span> ")

-- Create widgetbox
local widget_box = {}
local prompt_box = {}
local layout_box = {}
local tag_list = {}
local task_list = {}

-- Set buttons in widgetbox
tag_list.buttons = awful.util.table.join(
	awful.button({ }, 1, awful.tag.viewonly),
	awful.button({ mod_key }, 1, awful.client.movetotag),
	awful.button({ }, 3, awful.tag.viewtoggle),
	awful.button({ mod_key }, 3, awful.client.toggletag),
	awful.button({ }, 4, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end),
	awful.button({ }, 5, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end)
)
task_list.buttons = awful.util.table.join(
	awful.button({ }, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			-- Without this, the following
			-- :isvisible() makes no sense
			c.minimized = false
			if not c:isvisible() then c.first_tag:view_only() end
			-- This will also un-minimize
			-- the client, if needed
			client.focus = c
		end
	end),
	awful.button({ }, 3, function()
		if task_menu then
			task_menu:hide()
			task_menu = nil
		else
			task_menu = awful.menu.clients({ theme = { width = 250 } })
		end
	end),
	awful.button({ }, 4, function() awful.client.focus.byidx(1) end),
	awful.button({ }, 5, function() awful.client.focus.byidx(-1) end)
)

-- {{ Vicious

-- Battery state
local battery_widget = wibox.widget.textbox()
local battery_fresh_span = 29 -- Time span for refresh battery widget (seconds)
local battery_name = "BAT0"

-- Register battery widget
vicious.register(battery_widget, vicious.widgets.bat,
	function(_, args)
		local status, percent = args[1], args[2]
		local color = percent >= 60 and "green" or percent >= 20 and "yellow" or "red"
		return "<span color='" .. color .. "'>" .. percent .. "%(" .. status .. ")</span> "
	end, battery_fresh_span, battery_name
)

-- Volume state
local volume_widget = wibox.widget.textbox()

-- Register volume widget
vicious.register(volume_widget, vicious.contrib.pulse,
	function(_, args)
		local percent, status = args[1], args[2]
		return "<span color='white'>" .. percent .. "%(" .. status .. ")</span> "
	end
)

-- }}

-- Add widgetboxs in each screen
for s = 1, screen.count() do

	-- Create a promptbox for each screen
	prompt_box[s] = awful.widget.prompt()

	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	layout_box[s] = awful.widget.layoutbox(s)

	-- Create a taglist widget
	tag_list[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, tag_list.buttons)

	-- Create a tasklist widget
	task_list[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, task_list.buttons)

	-- Create the wibar
	widget_box[s] = awful.wibar({ position = "top", screen = s, height = 25 })

	-- Widgets that are aligned to the left
	local left_layout = wibox.layout.fixed.horizontal()
	left_layout:add(layout_box[s])
	left_layout:add(prompt_box[s])

	-- Widgets that are aligned to the right
	local right_layout = wibox.layout.fixed.horizontal()
	right_layout:add(tag_list[s])
	right_layout:add(text_clock)
	right_layout:add(battery_widget)
	right_layout:add(volume_widget)
	right_layout:add(wibox.widget.systray())

	-- Now bring it all together (with the tasklist in the middle)
	local layout = wibox.layout.align.horizontal()
	layout.left = left_layout
	layout.middle = task_list[s]
	layout.right = right_layout

	widget_box[s].widget = layout

end

-- }}}



-- {{{ Mouse bindings

root.buttons(
	awful.util.table.join(
		awful.button({ }, 3, function() main_menu:toggle() end),
		awful.button({ }, 4, awful.tag.viewprev),
		awful.button({ }, 5, awful.tag.viewnext)
	)
)

-- }}}



-- {{{ Global key bindings

-- Brightness change function
function brightness_change(change)

	isBrightnessUp = change > 0
	operate = isBrightnessUp and "+" or ""
	os.execute("xbacklight " .. operate .. change)

	-- Execute async brightness config
	awful.spawn.easy_async("xbacklight -get", function(brightness, _, _, _)

		local status = ""

		for i = 1, 20 do
			status = i <= brightness / 5 and status .. " |" or status .. " -"
		end

		brightness_notify_id = naughty.notify({
			title = "☀️ Brightness Change",
			text = "Background brightness "
					.. (isBrightnessUp and "up ⬆️" or "down ⬇") .. "\n"
					.. "[" .. status ..  " ] "
					.. string.format("%.f", tonumber(brightness)) .. "%",
			replaces_id = brightness_notify_id
		}).id

	end)

end

-- Volume change function
function volume_change(change)

	vicious.contrib.pulse.add(change)
	local volume, status = vicious.contrib.pulse()[1], ""

	for i = 1, 20 do
		status = i <= volume / 5 and status .. " |" or status .. " -"
	end

	volume_notify_id = naughty.notify({
		title = " Volume Change",
		text = "Volume " .. (change > 0 and "rise up ⬆️" or "lower ⬇") .. "\n"
				.. "[" .. status ..  " ] " .. volume .. "%",
		replaces_id = volume_notify_id
	}).id

end

-- Layout change function
function layout_change(change)

	awful.layout.inc(layouts, change)

	layout_notify_id = naughty.notify({
		title = " Layout Change",
		text = "Layout has been changed ...\n"
			.. "The current layout is [" .. awful.layout.getname() .. "]!",
		replaces_id = layout_notify_id
	}).id

end

local global_keys = awful.util.table.join(

	awful.key({ mod_key }, "Left", awful.tag.viewprev),
	awful.key({ mod_key }, "Right", awful.tag.viewnext),
	awful.key({ mod_key }, "Escape", awful.tag.history.restore),

	awful.key({ mod_key }, "j", function() awful.client.focus.byidx(1) end),
	awful.key({ mod_key }, "k", function() awful.client.focus.byidx(-1) end),

	-- Layout manipulation
	awful.key({ mod_key, "Shift" }, "j", function() awful.client.swap.byidx(1) end),
	awful.key({ mod_key, "Shift" }, "k", function() awful.client.swap.byidx(-1) end),
	awful.key({ mod_key, "Control" }, "j", function() awful.screen.focus_relative(1) end),
	awful.key({ mod_key, "Control" }, "k", function() awful.screen.focus_relative(-1) end),
	awful.key({ mod_key }, "u", awful.client.urgent.jumpto),
	awful.key({ mod_key }, "Tab", function() awful.client.focus.history.previous() end),

	-- Standard program
	awful.key({ mod_key }, "Return", function()
		awful.client.run_or_raise(terminal .. terminal_args, function(c)
			return awful.rules.match(c, { instance = terminal }, true)
		end)
	end),
	awful.key({ mod_key, "Control" }, "Return", function() awful.spawn(terminal .. terminal_args) end),
	awful.key({ mod_key, "Control" }, "r", awesome.restart),
	awful.key({ mod_key, "Control" }, "q", awesome.quit),

	-- Change layout
	awful.key({ mod_key }, "space", function() layout_change(1) end),
	awful.key({ mod_key, "Control" }, "space", function() layout_change(-1) end),

	-- Prompt
	awful.key({ mod_key }, "r", function() prompt_box[mouse.screen.index]:run() end, {
		description = "run prompt", group = "launcher"
	}),
	awful.key({ mod_key }, "x", function()
		awful.prompt.run({ prompt = "Run Lua code: " },
		prompt_box[mouse.screen.index].widget,
		awful.util.eval, nil,
		awful.util.getdir("cache") .. "/history_eval")
	end),

	-- Menu and menubar
	awful.key({ mod_key }, "o", function() main_menu:show() end),
	awful.key({ mod_key }, "p", function() menubar.show() end),

	-- Custom key bindings
	awful.key({ mod_key }, "l", function()
		-- Lock screen when use AC Power, suspend system when use Battery
		local power_status = vicious.call(vicious.widgets.bat, "$1", "BAT0")
		awful.spawn(power_status == "−" and "systemctl suspend" or "xdg-screensaver lock")
	end),
	awful.key({ mod_key }, "b", function() awful.spawn(browser) end),
	awful.key({ mod_key }, "d", function() awful.spawn(dictionary) end),
	awful.key({ mod_key }, "f", function()
		awful.spawn(terminal .. terminal_args  .. " -c " .. file_manager)
	end),
	awful.key({ mod_key, "Control" }, "n", function()
		local c_restore = awful.client.restore() -- Restore the minimize window and focus it
		if c_restore then
			client.focus = c_restore
			c_restore:raise()
		end
	end),

	-- Screen shot key bindings
	awful.key({ }, "Print", function()
		awful.spawn.with_shell("scrot ~/Pictures/(date -Iseconds).png")
		naughty.notify({
			title = " Screen Shot",
			text = "Take the fullscreen screenshot success!\n"
					.. "Screenshot saved in dir ~/Pictures."
		})
	end),
	awful.key({ mod_key }, "Print", function()
		awful.spawn.with_shell("scrot -u ~/Pictures/(date -Iseconds).png")
		naughty.notify({
			title = " Screen Shot",
			text = "Take the window screenshot success!\n"
					.. "Screenshot saved in dir ~/Pictures."
		})
	end),

	-- Brightness key bindings
	awful.key({ }, "XF86MonBrightnessUp", function() brightness_change(5) end),
	awful.key({ }, "XF86MonBrightnessDown", function() brightness_change(-5) end),

	-- Volume key bindings
	awful.key({ }, "XF86AudioMute", function()
		vicious.contrib.pulse.toggle()
		volume_notify_id = naughty.notify({
			title = " Volume changed",
			text = "Sound state has been changed ...\n"
					.. "Current sound state is ["
					.. (vicious.contrib.pulse()[1] > 0 and "ON" or "OFF") .. "] !",
			replaces_id = volume_notify_id
		}).id
	end),
	awful.key({ }, "XF86AudioRaiseVolume", function() volume_change(5) end),
	awful.key({ }, "XF86AudioLowerVolume", function() volume_change(-5) end),
	awful.key({ mod_key }, "XF86AudioRaiseVolume", function() volume_change(1) end),
	awful.key({ mod_key }, "XF86AudioLowerVolume", function() volume_change(-1) end)
)

-- Bind all key numbers to tags
-- Be careful: we use keycodes to make it works on any keyboard layout
-- This should map on the top row of your keyboard, usually 1 to 9
for i = 1, #tags do

	global_keys = awful.util.table.join(global_keys,
		-- View tag only
		awful.key({ mod_key }, "#" .. i + 9, function()
			local tag = mouse.screen.tags[i]
			if tag then tag:view_only() end
		end),
		-- Toggle tag
		awful.key({ mod_key, "Shift" }, "#" .. i + 9, function()
			local tag = mouse.screen.tags[i]
			if tag then awful.tag.viewtoggle(tag) end
		end),
		-- Move client to tag
		awful.key({ mod_key, "Control" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then client.focus:move_to_tag(tag) end
			end
		end),
		-- Toggle tag
		awful.key({ mod_key, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then client.focus:toggle_tag(tag) end
			end
		end)
	)

end

-- Set global keys
root.keys(global_keys)

-- }}}



-- {{{ Rules

-- Use mod_key with mouse key to move/resize the window
local client_buttons = awful.util.table.join(
	awful.button({ }, 1, function(c) client.focus = c; c:raise() end),
	awful.button({ mod_key }, 1, function(c)
		c:raise()
		client.focus = c
		awful.mouse.client.move()
	end),
	awful.button({ mod_key, "Control" }, 1, function(c)
		c:raise()
		client.focus = c
		awful.mouse.client.resize()
	end)
)

local client_keys = awful.util.table.join(
	awful.key({ mod_key }, "w", function(c) c:kill() end),
	awful.key({ mod_key }, "t", function(c) c.ontop = not c.ontop end),
	awful.key({ mod_key }, "s", function(c) c.maximized = not c.maximized end),
	awful.key({ mod_key }, "m", function(c) c.fullscreen = not c.fullscreen end),
	awful.key({ mod_key }, "n", function(c) c.minimized = true end),
	awful.key({ mod_key, "Control" }, "m", function(c) awful.client.setmaster(c) end),
	awful.key({ mod_key, "Control" }, "f", awful.client.floating.toggle)
)

-- Rules to apply to new clients (through the "manage" signal)
awful.rules.rules = {
	{
		-- All clients will match this rule
		rule = { },
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = client_keys,
			buttons = client_buttons
		}
	}, {
		rule = { instance = terminal },
		properties = { floating = true }
	}, {
		rule = { class = "jetbrains-idea" },
		properties = { tag = tags[4] }
	}, {
		rule = { class = "QtCreator" },
		properties = { tag = tags[4] }
	}, {
		rule = { class = "Eclipse" },
		properties = { tag = tags[4] }
	}
}

-- }}}



-- {{{ Signals

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c, startup)

	-- Set the dialog always on the top
	if c.type == "dialog" then c.ontop = true end

	if not startup then
		-- Set the windows at the slave,
		-- i.e. put it at the end of others instead of setting it master
		awful.client.setslave(c)
		-- Put windows in a smart way, only if they does not set an initial position
		if not c.size_hints.user_position
				and not c.size_hints.program_position then
			awful.placement.no_overlap(c)
			awful.placement.no_offscreen(c)
		end
	end

end)

client.connect_signal("focus", function(c)

	if not c.floating then
		-- Set all floating windows lower when focus to a unfloating window
		for _, window in pairs(c.screen.clients) do
			if window.floating then window:lower() end
		end
	else
		-- Raise the floating window
		c:raise()
	end

	-- Set the border color when window is focused
	c.border_color = beautiful.border_focus

end)

client.connect_signal("unfocus", function(c)

	c.border_color = beautiful.border_normal

end)

client.connect_signal("mouse::enter", function(c)

	-- Hide main menu when focus other window
	main_menu:hide()

	-- Hide task menu when focus other window
	if task_menu then
		task_menu:hide()
		task_menu = nil
	end

end)

-- }}}
