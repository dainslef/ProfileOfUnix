-- AwesomeWM configuration
-- Link this file to the path ~/.config/awesome/rc.lua


-- Load library
require("awful.autofocus") -- Need to load "autofocus" module, if not window will lost focus when change workspace(tag).
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")
local menubar = require("menubar")
local beautiful = require("beautiful")

-- Load vicious widgets
local vicious = require("vicious")
vicious.contrib = require("vicious.contrib")



-- Utils function

-- Run command sync, and get command shell output.
function get_command_output(command)
	local command_pipe = io.popen(command) -- Create a pipe
	local command_output = command_pipe:read("*all"):gsub("%s+", "") -- Get output
	command_pipe:close() -- Close the pipe
	return command_output
end



-- Init
do
	function run_once(cmd)
		awful.spawn.with_shell("pgrep -u $USER -x " .. cmd .. "; or " .. cmd)
	end

	function auto_run(tasks, once)
		local once = once or true
		for i = 1, #tasks do
			if once then run_once(tasks[i]) else awful.spawn.with_shell(tasks[i]) end
		end
	end

	auto_run({
		"systemctl --user restart pulseaudio", -- In NixOS PulseAudio should restart during window manager startup, otherwise the PulseAudio plugin won't work
		"xset +dpms", -- Use the power manager
		"xset dpms 0 0 1800", -- Set the power manager timeout to 30 minutes
		"xset s 1800" -- Set screensaver timeout to 30 mintues
	}, false)

	-- These service should only run once
	auto_run {
		-- PulseAudio, Fcitx5 and Clash can auto run by systemd service
		"picom", -- For transparent support
		"nm-applet", -- Show network status
		-- "clash-premium" -- Clash proxy provided by custom systemd service
		-- "blueman-applet", -- Use bluetooth
	}
end



-- Error handling
do
	-- Check if awesome encountered an error during startup and fell back to
	-- another config (This code will only ever execute for the fallback config)
	if awesome.startup_errors then
		naughty.notify {
			preset = naughty.config.presets.critical,
			title = "Oops, there were errors during startup!",
			text = awesome.startup_errors
		}
	end

	-- Handle runtime errors after startup
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure we don't go into an endless error loop
		if in_error then return end
		in_error = true
		naughty.notify {
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = err
		}
		in_error = false
	end)
end



-- Variable definitions

-- Theme config

-- Init theme
beautiful.init(awful.util.get_themes_dir() .. "default/theme.lua")
local gap_size = 10
do
	-- Custom theme settings, border and font
	beautiful.font = "DejaVu Sans 10"
	beautiful.border_width = 4
	beautiful.master_width_factor = 0.6 -- Set the master window percent
	beautiful.useless_gap = 5 -- Set the window Gap size

	-- Color settings, the last two bits are alpha channels
	beautiful.bg_normal = "#00000000" -- Set background transparent
	beautiful.bg_minimize = beautiful.bg_normal -- Set the minimize color of taskbar
	beautiful.fg_normal = "#FFFFFF99"
	beautiful.fg_minimize = "#55555500"
	beautiful.bg_systray = "#AAAAAA00"
	beautiful.border_focus = "#778899EE"
	beautiful.border_normal = "#00000022"
	beautiful.menu_bg_normal = "#33445566"
	beautiful.menu_fg_normal = beautiful.fg_focus
	beautiful.menu_border_color = beautiful.border_focus
	beautiful.taglist_bg_focus = "#55667788"
	beautiful.tasklist_bg_focus = beautiful.taglist_bg_focus
	beautiful.tasklist_bg_normal = beautiful.bg_normal
	beautiful.tasklist_fg_normal = beautiful.fg_minimize
	beautiful.notification_bg = "#33445599"

	-- Wallpaper
	local wall_paper = "/boot/background.jpg"
	for s = 1, screen.count() do
		gears.wallpaper.maximized(wall_paper, s, true)
	end
end

-- This is used later as the default terminal and editor to run
local mail = "thunderbird"
local browser = "google-chrome-stable"
local dictionary = "goldendict"
local file_manager = "ranger"
local terminal = "vte-2.91"
local terminal_instance = "Terminal" -- Set the instance name of Terminal App, use xprop WM_CLASS
local terminal_args = " -g 120x40 -n 5000 -T 20 --no-decorations --no-scrollbar" -- --reverse -f 'DejaVu Sans Mono 10'

-- Set default editor
local editor = os.getenv("EDITOR") or "vim"
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



-- Menu

-- Add menu items to main menu
local main_menu = awful.menu {
	items = {
		{ "Awesome", {
			{ "RestartWM", awesome.restart },
			{ "QuitWM", function() awesome.quit() end },
			{ "Suspend", "systemctl suspend" },
			{ "PowerOff", "poweroff" }
		}, beautiful.awesome_icon },
		{ "Develop",  {
			{ "VSCode", "code" },
			{ "IDEA", "idea-ultimate" }
		}},
		{ "Tools", {
			{ "Browser", browser },
			{ "Dictionary", dictionary },
			{ "VLC", "vlc" }
		}},
		{ "System", {
			{ "Terminal", terminal .. terminal_args },
			{ "Top", terminal .. terminal_args .. " -k -- top" },
			{ "GParted", "gparted" }
		}},
		{ "Mail", mail },
		{ "Files", terminal .. terminal_args  .. " -k -- " .. file_manager },
		{ "Browser", browser }
	}
}

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it



-- Wibox

-- Create widgetbox
local widget_box, prompt_box, layout_box, tag_list, task_list = {}, {}, {}, {}, {}

-- Create a textclock widget
local text_clock = wibox.widget.textclock("<span font='Dejavu Sans 10' color='white'>" ..
	"[<span color='yellow'>%a</span>] %b/%d <span color='cyan'>%H:%M</span> </span>")

do -- Attach a cleandar widget to text_colock widget.
	local month_calendar = awful.widget.calendar_popup.month()
	month_calendar.bg = beautiful.taglist_bg_focus
	month_calendar:attach(text_clock, "tr")
end

-- Mouse bindings
-- Muse moudle https://awesomewm.org/doc/api/libraries/mouse.html

-- Mouse Key definition.
MouseButtons = {
	LEFT = 1,
	MIDDLE = 2,
	RIGHT = 3,
	SCROLL_UP = 4,
	SCROLL_DOWN = 5
}

-- Mouse action on empty desktop.
root.buttons(
	awful.util.table.join(
		awful.button({}, MouseButtons.RIGHT, function() main_menu:toggle() end),
		awful.button({}, MouseButtons.SCROLL_UP, awful.tag.viewprev),
		awful.button({}, MouseButtons.SCROLL_DOWN, awful.tag.viewnext)
	)
)

-- Set buttons in widgetbox
tag_list.buttons = awful.util.table.join(
	awful.button({}, MouseButtons.LEFT, awful.tag.viewonly),
	awful.button({}, MouseButtons.RIGHT, awful.tag.viewtoggle),
	awful.button({}, MouseButtons.SCROLL_UP, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end),
	awful.button({}, MouseButtons.SCROLL_DOWN, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
	awful.button({ mod_key }, MouseButtons.LEFT, awful.client.movetotag),
	awful.button({ mod_key }, MouseButtons.RIGHT, awful.client.toggletag)
)
task_list.buttons = awful.util.table.join(
	awful.button({}, MouseButtons.LEFT, function(c)
		if c == client.focus then
			c.minimized = true
		else
			-- This will also un-minimize the client, if need
			c.minimized = false
			if not c:isvisible() then c.first_tag:view_only() end
			client.focus = c
		end
	end),
	awful.button({}, MouseButtons.RIGHT, function()
		if task_menu then
			task_menu:hide()
		else
			task_menu = awful.menu.clients { theme = { width = 250 } }
		end
	end),
	awful.button({}, MouseButtons.SCROLL_UP, function() awful.client.focus.byidx(1) end),
	awful.button({}, MouseButtons.SCROLL_DOWN, function() awful.client.focus.byidx(-1) end)
)



-- Vicious Plugins

local net_widget, battery_widget, volume_widget =
	wibox.widget.textbox(), wibox.widget.textbox(), wibox.widget.textbox()

-- Vicious plugin basic usage:
-- vicious.register(widget, wtype, format, interval, warg)

-- These variables need to place at global scope, some other function need these variables.
local volume_zero_span = 0
-- Get the last SINK device index
local volume_device_index = tonumber(get_command_output("pactl list sinks short | wc -l"))

do
	-- Net state
	local net_refresh_span = 2
	-- Get default net device name, sometimes there are more than one default route, so use "tail -n 1"
	local net_device = get_command_output("ip route | grep default | tail -n 1 | grep -Po '(?<=dev )(\\S+)'")
	local net_format = "🌐 <span color='white'>${" .. net_device .. " down_kb} KB </span>"
	vicious.register(net_widget, vicious.widgets.net, net_format, net_refresh_span)

	-- Battery state
	local battery_refresh_span = 10 -- Time span for refresh battery widget (seconds)
	local battery_name = "BAT0"
	-- Register battery widget
	vicious.register(battery_widget, vicious.widgets.bat, function(_, args)
		local status, percent = args[1], args[2]
		return "🔋 <span color='white'>" .. percent .. "%(" .. status .. ") </span>"
	end, battery_refresh_span, battery_name)

	-- Volume state
	local volume_refresh_span = 1
	-- Register volume widget
	vicious.register(volume_widget, vicious.contrib.pulse, function(_, args)
		local percent, status = args[1], args[2]
		local emoji = percent >= 60 and "🔊" or percent >= 20 and "🔉" or percent > 0 and "🔈" or "🔇"
		return emoji .. " <span color='white'>" .. percent .. "%(" .. status .. ") </span>"
	end, volume_refresh_span, volume_device_index)
end



-- Tags

-- Define a tag table which hold all screen tags.
local tags, tag_properties = {}, {
	{ "❶", layouts[1] },
	{ "❷", layouts[2] },
	{ "❸", layouts[2] },
	{ "❹", layouts[3] }
}

-- Add widgetboxs in each screen
for s = 1, screen.count() do

	-- Each screen has its own tag table.
	-- Use operate # to get lua table's size.
	for i = 1, #tag_properties do
		tags[i] = awful.tag.add(tag_properties[i][1], {
			screen = s,
			layout = tag_properties[i][2],
			selected = i == 1 and true or false -- Only focus on index one.
		})
	end

	-- Create a promptbox for each screen
	prompt_box[s] = awful.widget.prompt()

	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	layout_box[s] = awful.widget.layoutbox(s)

	-- Create a taglist widget
	tag_list[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, tag_list.buttons)

	-- Create a tasklist widget
	task_list[s] = awful.widget.tasklist {
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = task_list.buttons,
		style = { -- change the task list style
			shape_border_width = 2,
			shape = gears.shape.rounded_bar
		},
		layout = {
			spacing = gap_size,
			layout  = wibox.layout.flex.horizontal
		}
	}

	function create_bar_layout(widget)
		return wibox.container.background(
			wibox.container.margin(widget, gap_size, gap_size),
			beautiful.menu_bg_normal, gears.shape.rounded_bar)
	end

	-- Widgets that are aligned to the left
	local left_layout = create_bar_layout(wibox.widget {
		layout_box[s], prompt_box[s], tag_list[s],
		layout = wibox.layout.fixed.horizontal
	})

	-- Widgets that are aligned to the right
	local right_layout = create_bar_layout(wibox.widget {
		net_widget, battery_widget, volume_widget, wibox.widget.systray(), text_clock,
		layout = wibox.layout.fixed.horizontal
	})

	-- Now bring it all together (with the tasklist in the middle)
	local middle_layout =
		-- margin container args: widget, left padding, right padding
		wibox.container.margin(
			-- place container args: widget, horizontal alignment
			wibox.container.place(task_list[s], "left"), gap_size, gap_size)

	-- Create the wibar
	widget_box[s] = awful.wibar {
		position = "top",
		screen = s,
		height = 35,
		widget = wibox.container.margin(wibox.widget {
			left_layout, middle_layout, right_layout,
			layout = wibox.layout.align.horizontal
		}, gap_size, gap_size, gap_size) -- Set top bar gap.
	}

end



-- Global key bindings

-- Brightness change function
function brightness_change(change)
	local is_brightness_up = change > 0
	local prefix = is_brightness_up and "+" or ""
	local suffix = is_brightness_up and "" or "-"
	os.execute("brightnessctl set " .. prefix .. math.abs(change) .. "%" .. suffix)

	-- Execute async brightness config (need run command with shell)
	awful.spawn.easy_async_with_shell("brightnessctl | grep -P '\\d+%' -o | sed 's/\\%//'", function(brightness, _, _, _)
		local status = ""
		for i = 1, 20 do
			status = i <= brightness / 5 and status .. " |" or status .. " -"
		end

		-- Use 'destroy' instead of 'replaces_id' (replaces_id api sometimes doesn't take effects)
		naughty.destroy(brightness_notify)
		brightness_notify = naughty.notify {
			title = "💡 Brightness Change",
			text = "Background brightness "
					.. (is_brightness_up and "up ⬆️" or "down ⬇️") .. "\n"
					.. "[" .. status ..  " ] "
					.. string.format("%.f", tonumber(brightness)) .. "%"
		}
	end)
end

-- Volume change function
function volume_change(change)
	vicious.contrib.pulse.add(change, volume_device_index)
	local volume, status = vicious.contrib.pulse(volume_zero_span, volume_device_index)[1], ""

	for i = 1, 20 do
		status = i <= volume / 5 and status .. " |" or status .. " -"
	end

	naughty.destroy(volume_notify)
	volume_notify = naughty.notify {
		title = "🔈 Volume Change",
		text = "Volume " .. (change > 0 and "rise up ⬆️" or "lower ⬇️") .. "\n"
				.. "[" .. status ..  " ] " .. volume .. "%"
	}
end

-- Layout change function
function layout_change(change)
	awful.layout.inc(layouts, change)
	layout_notify_id = naughty.notify {
		title = "🔁 Layout Change",
		text = "Layout has been changed ...\n"
			.. "The current layout is [" .. awful.layout.getname() .. "]!",
		replaces_id = layout_notify_id
	}.id
end

local global_keys = awful.util.table.join(

	awful.key({ mod_key }, "Left", function() awful.client.focus.bydirection("left") end),
	awful.key({ mod_key }, "Right", function() awful.client.focus.bydirection("right") end),
	awful.key({ mod_key }, "Up", function() awful.client.focus.bydirection("up") end),
	awful.key({ mod_key }, "Down", function() awful.client.focus.bydirection("down") end),
	awful.key({ mod_key, "Control"}, "Left", function() awful.client.swap.byidx(1) end),
	awful.key({ mod_key, "Control"}, "Right", function() awful.client.swap.byidx(-1) end),

	awful.key({ mod_key }, "Escape", awful.tag.history.restore),
	awful.key({ mod_key }, "BackSpace", naughty.destroy_all_notifications),

	-- Layout manipulation
	awful.key({ mod_key }, "j", awful.client.urgent.jumpto),
	awful.key({ mod_key }, "Tab", function() awful.client.focus.byidx(1) end),
	awful.key({ mod_key }, "`", function() awful.client.focus.byidx(-1) end),

	-- Standard program
	awful.key({ mod_key }, "Return", function()
		local last_terminal, last_unfocus_terminal, find_last_unfocus_terminal
		-- Only find the terminal instance in current tag (workspace)
		for _, c in pairs(awful.screen.focused().selected_tag:clients()) do
			-- Find the last unfocused terminal window in current tag
			if c.instance == terminal_instance then
				last_terminal = c
				-- The last unfocus window should before the current window
				if c ~= client.focus and not find_last_unfocus_terminal then
					last_unfocus_terminal = c
				else
					find_last_unfocus_terminal = true
				end
			end
		end
		if last_unfocus_terminal or last_terminal then
			-- Use the existed terminal if possible
			client.focus = last_unfocus_terminal or last_terminal
		else
			-- Create a terminal if there is no terminal
			awful.spawn.spawn(terminal .. terminal_args)
		end
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
	awful.key({ mod_key }, "l", function() awful.spawn("dm-tool lock") end), -- Lock screen
	awful.key({ mod_key }, "h", function()
		-- Minimize all floating windows in current tag (workspace)
		for _, c in pairs(awful.screen.focused().selected_tag:clients()) do
			if c.floating then c.minimized = true end
		end
	end),
	awful.key({ mod_key, "Control" }, "h", function()
		-- Unminimize all floating windows
		for _, c in pairs(awful.screen.focused().selected_tag:clients()) do
			if c.floating then c.minimized = false; client.focus = c end
		end
	end),
	awful.key({ mod_key }, "b", function() awful.spawn(browser) end),
	awful.key({ mod_key }, "d", function() awful.spawn(dictionary) end),
	awful.key({ mod_key }, "f", function()
		awful.spawn(terminal .. terminal_args  .. " -c " .. file_manager)
	end),
	awful.key({ mod_key, "Control" }, "n", function()
		local c_restore = awful.client.restore() -- Restore the minimize window and focus it
		if c_restore then client.focus = c_restore; c_restore:raise() end
	end),

	-- Screen shot key bindings
	awful.key({}, "Print", function()
		awful.spawn.with_shell("scrot ~/Pictures/screenshot-fullscreen-(date -Ins).png")
		naughty.notify {
			title = "📸 Screen Shot",
			text = "Take the fullscreen screenshot success!\n"
					.. "Screenshot saved in dir ~/Pictures."
		}
	end),
	awful.key({ mod_key }, "Print", function()
		awful.spawn.with_shell("scrot -u ~/Pictures/screenshot-window-(date -Ins).png")
		naughty.notify {
			title = "📸 Screen Shot",
			text = "Take the window screenshot success!\n"
					.. "Screenshot saved in dir ~/Pictures."
		}
	end),

	-- Brightness key bindings
	awful.key({}, "XF86MonBrightnessUp", function() brightness_change(5) end),
	awful.key({}, "XF86MonBrightnessDown", function() brightness_change(-5) end),
	awful.key({ mod_key }, "XF86MonBrightnessUp", function() brightness_change(1) end),
	awful.key({ mod_key }, "XF86MonBrightnessDown", function() brightness_change(-1) end),

	-- Volume key bindings
	awful.key({}, "XF86AudioMute", function()
		vicious.contrib.pulse.toggle(volume_device_index)
		naughty.destroy(volume_notify_id)
		local volume = vicious.contrib.pulse(volume_zero_span, volume_device_index)[1]
		volume_notify_id = naughty.notify {
			title = "🔈 Volume changed",
			text = "Sound state has been changed ...\n"
					.. "Current sound state is ["
					.. (volume > 0 and "🔊 ON" or "🔇 OFF") .. "] !"
		}
	end),
	awful.key({}, "XF86AudioRaiseVolume", function() volume_change(5) end),
	awful.key({}, "XF86AudioLowerVolume", function() volume_change(-5) end),
	awful.key({ mod_key }, "XF86AudioRaiseVolume", function() volume_change(1) end),
	awful.key({ mod_key }, "XF86AudioLowerVolume", function() volume_change(-1) end)
)

-- Bind all key numbers to tags (Work Space)
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



-- Rules

-- Rules to apply to new clients (through the "manage" signal)
-- Get X-Client props need to install tool "xorg-prop", use command "xprop" to check window props
awful.rules.rules = {
	{
		-- All clients will match this rule
		rule = {},
		properties = {
			raise = true,
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			keys = awful.util.table.join(
				awful.key({ mod_key }, "w", function(c) c:kill() end),
				awful.key({ mod_key }, "m", function(c) c.fullscreen = not c.fullscreen end),
				awful.key({ mod_key }, "n", function(c) c.minimized = true end),
				awful.key({ mod_key, "Control" }, "t", function(c) c.ontop = not c.ontop end),
				awful.key({ mod_key, "Control" }, "m", function(c) awful.client.setmaster(c) end),
				awful.key({ mod_key, "Control" }, "f", awful.client.floating.toggle)
			),
			-- Use mod_key with mouse key to move/resize the window
			buttons = awful.util.table.join(
				awful.button({}, 1, function(c) client.focus = c; c:raise() end),
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
		}
	}, {
		rule = { instance = terminal_instance },
		properties = {
			floating = true,
			-- Make terminal open at mouse position
			callback = function(c) awful.placement.under_mouse(c) end
		}
	}, {
		rule = { class = "jetbrains-idea" },
		properties = { tag = tags[4] }
	}
}



-- Signals

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
			-- if window.floating then window:lower() end
			if window.floating and not window.ontop then window.minimized = true end
		end
	else
		c:raise() -- Raise the floating window
	end
	-- Set the border color when window is focused
	c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)

client.connect_signal("mouse::enter", function(c)
	main_menu:hide() -- Hide main menu when focus other window
	if task_menu then task_menu:hide() end -- Hide task menu when focus other window
end)
