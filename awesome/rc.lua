-- Load library
require("awful.autofocus")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local awful = require("awful")
awful.rules = require("awful.rules")



-- {{{ Init
-- Custom init command
-- awful.util.spawn_with_shell("synclient VertScrollDelta=-66") -- Mate-settings-daemon offer touchpad setting, it's not necessary.
awful.util.spawn_with_shell("xset s 1800") -- Set screensaver timeout to 30 mintues
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

-- Use theme
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- Custom theme settings, border and font
theme.border_width = 2
theme.font = "Dejavu Sans 10"

-- Color settings, the last two bits are alpha channels
local color_transparent = "#00000000"
local color_menu_bg = "#33445566"
local color_task_tag_focus = "#55667788"

theme.bg_normal = color_transparent -- Set background transparent
theme.bg_minimize = color_transparent -- Set the minimize color of taskbar
theme.menu_bg_normal = color_menu_bg
theme.menu_fg_normal = theme.fg_focus
theme.taglist_bg_focus = color_task_tag_focus -- Set the focus color of taglist
theme.tasklist_bg_focus = color_task_tag_focus -- Set the focus color of taskbar

-- This is used later as the default terminal and editor to run
local mail = "thunderbird"
local terminal = "mate-terminal"
local browser = "google-chrome-stable"
local dictionary = "stardict"
local file_manager = "caja"

-- Set default editor
local editor = os.getenv("EDITOR") or "nano"

-- Set main key
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts = {
	-- awful.layout.suit.floating,
	-- awful.layout.suit.magnifier, -- focus in center
	awful.layout.suit.spiral, -- master in left
	-- awful.layout.suit.spiral.dwindle,
	awful.layout.suit.fair, -- equal division
	-- awful.layout.suit.fair.horizontal,
	-- awful.layout.suit.tile,
	-- awful.layout.suit.tile.left,
	awful.layout.suit.tile.bottom, -- master in top
	-- awful.layout.suit.tile.top,
	-- awful.layout.suit.max,
	-- awful.layout.suit.max.fullscreen
}
-- }}}



-- {{{ Load auto run apps.
do
	function run_once(prg)
		awful.util.spawn_with_shell("pgrep -u $USER -x " .. prg .. " || (" .. prg .. ")")
	end

	local auto_run_list = {
		"fcitx", -- Use input method
		"xcompmgr", -- For transparent support
		"nm-applet", -- Show network status
		"light-locker", -- Lock screen need to load it first
		-- "blueman-applet", -- Use bluetooth
		"mate-power-manager", -- Show power and set backlights
		"mate-volume-control-applet",
		"/usr/lib/mate-settings-daemon/mate-settings-daemon", -- For keyboard binding support
		"/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"
	}

	for _, cmd in pairs(auto_run_list) do
		run_once(cmd)
	end
end
-- }}}



-- {{{ Wallpaper
if beautiful.wallpaper then
	for s = 1, screen.count() do
		gears.wallpaper.maximized("/home/dainslef/Pictures/34844544_p0.png", s, true)
	end
end
-- }}}



-- {{{ Tags
-- Define a tag table which hold all screen tags.
local tags = {
	names = { "❶", "❷", "❸", "❹" },
	-- names = { "①", "②", "③", "④" },
	layouts = { layouts[1], layouts[2], layouts[2], layouts[3] }
}
for s = 1, screen.count() do
	-- Each screen has its own tag table.
	tags[s] = awful.tag(tags.names, s, tags.layouts)
end
-- }}}



-- {{{ Menu

-- Create menu items
local myawesomemenu = {
	{ "Suspend", "systemctl suspend" },
	{ "RestartWM", awesome.restart },
	{ "QuitWM", awesome.quit },
	{ "PowerOff", "poweroff" }
}
local developmenu = {
	{ "QtCreator", "qtcreator" },
	{ "QtAssistant", "assistant-qt5" },
	{ "QtDesigner", "designer-qt5" },
	{ "Emacs", "emacs" },
	{ "GVIM", "gvim" },
	{ "VSCode", "/home/dainslef/Public/VSCode-linux-x64/code" },
	{ "NetBeans", "/home/dainslef/Public/netbeans/bin/netbeans" },
	{ "Eclipse", "/home/dainslef/Public/eclipse/eclipse" },
	{ "IDEA", "/home/dainslef/Public/idea-IU/bin/idea.sh" }
}
local toolsmenu = {
	{ "StarDict", dictionary },
	{ "VLC", "vlc" },
	{ "GIMP", "gimp" }
}
local systemmenu = {
	{ "Terminal", terminal },
	{ "VirtualBox", "virtualbox" },
	{ "GParted", "gparted" }
}

-- Add menu items to main menu
local mymainmenu = awful.menu({
	items = {
		{ "Awesome", myawesomemenu, beautiful.awesome_icon },
		{ "Develop", developmenu },
		{ "Tools", toolsmenu },
		{ "System", systemmenu },
		{ "Mail", mail },
		{ "Files", file_manager },
		{ "Browser", browser }
	}
})

-- Create launcher and set menu
local mylauncher = awful.widget.launcher({
	image = beautiful.awesome_icon,
	menu = mymainmenu
})

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}



-- {{{ Wibox

-- Create a textclock widget
local mytextclock = awful.widget.textclock(" <span font='Dejavu Sans 10'>[ %b %d -<span color='green'>%a</span>-"
	.. " ☪ <span color='yellow'>%H:%M</span> ]</span> ")

-- Create widgetbox
local mywidgetbox = {}
local mypromptbox = {}
local mylayoutbox = {}
local mytaglist = {}
local mytasklist = {}

-- Set buttons in widgetbox
mytaglist.buttons = awful.util.table.join(
	awful.button({ }, 1, awful.tag.viewonly),
	awful.button({ modkey }, 1, awful.client.movetotag),
	awful.button({ }, 3, awful.tag.viewtoggle),
	awful.button({ modkey }, 3, awful.client.toggletag),
	awful.button({ }, 4, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end),
	awful.button({ }, 5, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end)
)
mytasklist.buttons = awful.util.table.join(
	awful.button({ }, 1, function(c)
			if c == client.focus then
				c.minimized = true
			else
				-- Without this, the following
				-- :isvisible() makes no sense
				c.minimized = false
				if not c:isvisible() then awful.tag.viewonly(c:tags()[1]) end
				-- This will also un-minimize
				-- the client, if needed
				client.focus = c
				c:raise()
			end
		end),
	awful.button({ }, 3, function()
			if instance then
				instance:hide()
				instance = nil
			else
				instance = awful.menu.clients({ theme = { width = 250 } })
			end
		end),
	awful.button({ }, 4, function()
			awful.client.focus.byidx(1)
			if client.focus then client.focus:raise() end
		end),
	awful.button({ }, 5, function()
			awful.client.focus.byidx(-1)
			if client.focus then client.focus:raise() end
		end)
)

-- Add widgetboxs in each screen
for s = 1, screen.count() do

	-- Create a promptbox for each screen
	mypromptbox[s] = awful.widget.prompt()

	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	mylayoutbox[s] = awful.widget.layoutbox(s)
	mylayoutbox[s]:buttons(awful.util.table.join(
		awful.button({ }, 1, function() awful.layout.inc(layouts, 1) end),
		awful.button({ }, 3, function() awful.layout.inc(layouts, -1) end),
		awful.button({ }, 4, function() awful.layout.inc(layouts, 1) end),
		awful.button({ }, 5, function() awful.layout.inc(layouts, -1) end)
	))

	-- Create a taglist widget
	mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

	-- Create a tasklist widget
	mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

	-- Create the wibox
	mywidgetbox[s] = awful.wibox({ position = "top", screen = s, height = 25 })

	-- Widgets that are aligned to the right
	local right_layout = wibox.layout.fixed.horizontal()
	right_layout:add(mytaglist[s])
	right_layout:add(mytextclock)
	right_layout:add(mylayoutbox[s])
	right_layout:add(wibox.widget.systray())

	-- Now bring it all together (with the tasklist in the middle)
	local layout = wibox.layout.align.horizontal()
	layout:set_left(mypromptbox[s])
	layout:set_middle(mytasklist[s])
	layout:set_right(right_layout)

	mywidgetbox[s]:set_widget(layout)

end
-- }}}



-- {{{ Mouse bindings
root.buttons(
	awful.util.table.join(
		awful.button({ }, 3, function() mymainmenu:toggle() end),
		awful.button({ }, 4, awful.tag.viewprev),
		awful.button({ }, 5, awful.tag.viewnext)
	)
)
-- }}}



-- {{{ Key bindings
local globalkeys = awful.util.table.join(

	awful.key({ modkey }, "Left", awful.tag.viewprev),
	awful.key({ modkey }, "Right", awful.tag.viewnext),
	awful.key({ modkey }, "Escape", awful.tag.history.restore),

	awful.key({ modkey }, "j", function()
			awful.client.focus.byidx(1)
			if client.focus then client.focus:raise() end
		end),
	awful.key({ modkey }, "k", function()
			awful.client.focus.byidx(-1)
			if client.focus then client.focus:raise() end
		end),
	awful.key({ modkey }, "w", function() mymainmenu:show() end),

	-- Layout manipulation
	awful.key({ modkey, "Shift"  }, "j", function() awful.client.swap.byidx(1) end),
	awful.key({ modkey, "Shift"  }, "k", function() awful.client.swap.byidx( -1) end),
	awful.key({ modkey, "Control" }, "j", function() awful.screen.focus_relative( 1) end),
	awful.key({ modkey, "Control" }, "k", function() awful.screen.focus_relative(-1) end),
	awful.key({ modkey }, "u", awful.client.urgent.jumpto),
	awful.key({ modkey }, "Tab", function()
			awful.client.focus.history.previous()
			if client.focus then client.focus:raise() end
		end),

	-- Standard program
	awful.key({ modkey }, "Return", function() awful.util.spawn(terminal) end),
	awful.key({ modkey, "Control" }, "r", awesome.restart),
	awful.key({ modkey, "Shift"   }, "q", awesome.quit),

	awful.key({ modkey }, "l", function() awful.tag.incmwfact(0.05) end),
	awful.key({ modkey }, "h", function() awful.tag.incmwfact(-0.05) end),
	awful.key({ modkey, "Shift" }, "h", function() awful.tag.incnmaster(1) end),
	awful.key({ modkey, "Shift" }, "l", function() awful.tag.incnmaster(-1) end),
	awful.key({ modkey, "Control" }, "h", function() awful.tag.incncol(1) end),
	awful.key({ modkey, "Control" }, "l", function() awful.tag.incncol(-1) end),

	awful.key({ modkey }, "space", function()
			awful.layout.inc(layouts, 1)
			naughty.notify({
				title = 'Layout Change',
				text = "The current layout is " .. awful.layout.getname() .. ".",
				timeout = 1,
				bg = beautiful.menu_bg_normal,
				fg = beautiful.fg_focus
			})
		end),
	awful.key({ modkey, "Shift" }, "space", function()
			awful.layout.inc(layouts, -1)
			naughty.notify({
				title = 'Layout Change',
				text = "The current layout is " .. awful.layout.getname() .. ".",
				timeout = 1,
				bg = beautiful.menu_bg_normal,
				fg = beautiful.fg_focus
			})
		end),

	-- Prompt
	awful.key({ modkey }, "r", function() mypromptbox[mouse.screen]:run() end),
	awful.key({ modkey }, "x", function()
			awful.prompt.run({ prompt = "Run Lua code: " },
			mypromptbox[mouse.screen].widget,
			awful.util.eval, nil,
			awful.util.getdir("cache") .. "/history_eval")
		end),

	-- Menubar
	awful.key({ modkey }, "p", function() menubar.show() end),

	-- Custom key bindings
	awful.key({ modkey, "Control" }, "l", function() awful.util.spawn("xdg-screensaver lock") end),
	awful.key({ modkey }, "b", function() awful.util.spawn(browser) end),
	awful.key({ modkey }, "d", function() awful.util.spawn(dictionary) end),
	-- awful.key({ }, "XF86AudioRaiseVolume", function() end),
	-- awful.key({ }, "XF86AudioLowerVolume", function() end),
	awful.key({ modkey, "Control" }, "n", function()
			local c_restore = awful.client.restore() -- Restore the minimize window and focus it
			if c_restore then client.focus = c_restore; c_restore:raise() end
		end),
	awful.key({ }, "Print", function()
			os.execute("import -window root ~/Pictures/$(date -Iseconds).png") -- Use imagemagick tools
			naughty.notify({
				title = "Screen Shot",
				text = "Take the fullscreen screenshot success!\n"
					.. "Screenshot saved in ~/Pictures.",
				bg = beautiful.menu_bg_normal,
				fg = beautiful.fg_focus
			})
		end),
	awful.key({ modkey }, "Print", function()
			awful.util.spawn_with_shell("import ~/Pictures/$(date -Iseconds).png")
			naughty.notify({
				title = "Screen Shot",
				text = "Please select window to take the screenshot...\n"
					.. "Screenshot will be saved in ~/Pictures.",
				bg = beautiful.menu_bg_normal,
				fg = beautiful.fg_focus
			})
		end)
)

local clientkeys = awful.util.table.join(
	awful.key({ modkey }, "f", function(c) c.fullscreen = not c.fullscreen end),
	awful.key({ modkey, "Shift" }, "c", function(c) c:kill() end),
	awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle),
	awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end),
	awful.key({ modkey }, "o", awful.client.movetoscreen),
	awful.key({ modkey }, "t", function(c) c.ontop = not c.ontop end),
	awful.key({ modkey }, "n", function(c) c.minimized = true end),
	awful.key({ modkey }, "m", function(c)
			c.maximized_horizontal = not c.maximized_horizontal
			c.maximized_vertical   = not c.maximized_vertical
		end)
)

-- Bind all key numbers to tags
-- Be careful: we use keycodes to make it works on any keyboard layout
-- This should map on the top row of your keyboard, usually 1 to 9
for i = 1, 4 do
	globalkeys = awful.util.table.join(globalkeys,
		-- View tag only
		awful.key({ modkey }, "#" .. i + 9, function()
				local screen = mouse.screen
				local tag = awful.tag.gettags(screen)[i]
				if tag then awful.tag.viewonly(tag) end
			end),
		-- Toggle tag
		awful.key({ modkey, "Control" }, "#" .. i + 9, function()
				local screen = mouse.screen
				local tag = awful.tag.gettags(screen)[i]
				if tag then awful.tag.viewtoggle(tag) end
			end),
		-- Move client to tag
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
				if client.focus then
					local tag = awful.tag.gettags(client.focus.screen)[i]
					if tag then awful.client.movetotag(tag) end
				end
			end),
		-- Toggle tag
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
				if client.focus then
					local tag = awful.tag.gettags(client.focus.screen)[i]
					if tag then awful.client.toggletag(tag) end
				end
			end))
end

-- Use modkey with mouse key to move/resize the window
local clientbuttons = awful.util.table.join(
	awful.button({ }, 1, function(c) client.focus = c; c:raise() end),
	awful.button({ modkey }, 1, function(c)
			c:raise()
			client.focus = c
			awful.mouse.client.move()
		end),
	awful.button({ modkey }, 3, function(c)
			c:raise()
			client.focus = c
			awful.mouse.client.resize()
		end)
)

-- Set keys
root.keys(globalkeys)
-- }}}



-- {{{ Rules
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
			keys = clientkeys,
			buttons = clientbuttons
		}
	}, {
	-- Start up terminal in floating mode
		rule = { instance = terminal },
		properties = { floating = true }
	}, {
		rule = { class = "jetbrains-idea" },
		properties = { tag = tags[1][4] }
	}, {
		rule = { class = "NetBeans IDE 8.1" },
		properties = { tag = tags[1][4] }
	}, {
		rule = { class = "QtCreator" },
		properties = { tag = tags[1][4] }
	}, {
		rule = { class = "Eclipse" },
		properties = { tag = tags[1][4] }
	}
	-- Set Firefox to always map on tags number 2 of screen 1
	-- { rule = { class = "Firefox" },
	--	 properties = { tag = tags[1][2] } },
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

		-- Minimize all floating windows when change the focus to other normal window in tiles layout
		if awful.layout.get() ~= awful.layout.suit.magnifier
				and not awful.client.floating.get(c.focus) then
			for _, window in pairs(awful.client.visible(c.screen)) do
				if awful.client.floating.get(window)
						and not window.ontop then  -- Ingnore when floating window is ontop
					window.minimized = true
				end
			end
		end

		c.border_color = beautiful.border_focus

	end)

client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
