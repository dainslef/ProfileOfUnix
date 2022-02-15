# Qtile configuration
# Place this file in the path ~/.config/qtile/config.py

# Import library
from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.backend.base import Window
from libqtile.core.manager import Qtile
from libqtile.lazy import lazy
import os, subprocess

# Qtile pre-define config variables
follow_mouse_focus = False
auto_fullscreen = True
reconfigure_screens = True
bring_front_click = True
focus_on_window_activation = "focus"

# User custom variables
mod = "mod4"
mail = "thunderbird"
browser = "google-chrome-stable"
dictionary = "goldendict"
file_manager = "ranger"
terminal_group_name = "T"
terminal = "vte-2.91"
terminal_wm_class = "Terminal"
terminal_args = (
    " -W -P never -g 120x40 -n 5000 -T 20 --reverse --no-decorations --no-scrollbar"
)

# Utils function
def is_terminal(c: Window):
    return c and c.match(Match(wm_class=terminal_wm_class))


# Send the notification
def send_notification(
    title: str, content: str, replace_id: int = None, percent_value: int = None
):
    replace = f"-r {replace_id}" if replace_id else ""
    percent = f"-h int:value:{percent_value}" if percent_value else ""
    os.system(f"dunstify '{title}' '{content}' {replace} {percent}")


def get_pulse_volume() -> int:
    return int(
        # Get the command output
        subprocess.check_output(
            "pactl list sinks | grep '^[[:space:]]Volume:' |"
            + f"head -n 1 | tail -n 1 | sed -e 's,.* \\([0-9][0-9]*\\)%.*,\\1,'",
            shell=True,
            text=True,
        )
    )


def is_pulse_mute() -> bool:
    status = subprocess.check_output(
        "pactl list sinks | awk '/Mute/ { print $2 }'",
        shell=True,
        text=True,
    ).strip()  # Reponse content contains '\n', clear special charactor
    return status == "yes"


# Generate the volume info
def show_pulse_volume() -> str:
    percent = get_pulse_volume()
    not_mute = not is_pulse_mute()
    status = "ON" if not_mute else "OFF"
    volume_emoji = (
        "🔊"
        if percent >= 60 and not_mute
        else "🔉"
        if percent >= 20 and not_mute
        else "🔈"
        if percent > 0 and not_mute
        else "🔇"
    )
    return f"{volume_emoji} {percent}%({status})"


@lazy.function
def change_pulse_volume(_, volume: int):
    sink = 0
    if volume > 0:
        op, volume_change = "+", "rise up ⬆️"
        # Prevent the volume break 100% limit
        change = "100" if get_pulse_volume() + volume > 100 else f"{op}{volume}"
    else:
        op, volume_change = "", "lower ⬇️"
        change = volume
    os.system(f"pactl set-sink-volume {sink} {change}%")
    volume_change_id = 1001
    send_notification(
        "🔈 Volume Change",
        f"Volume {volume_change}",
        volume_change_id,
        get_pulse_volume(),
    )


@lazy.function
def change_pulse_mute(_):
    sink = 0
    state = "🔊 ON" if is_pulse_mute() else "🔇 OFF"
    os.system(f"pactl set-sink-mute {sink} toggle")
    volume_change_id = 1001
    send_notification(
        "🔈 Volume changed",
        f"Sound state has been changed ...\nCurrent sound state is [{state}]!",
        volume_change_id,
    )


@lazy.function
def change_brightness(_, value: int):
    if value > 0:
        operate, content = "+", "up ⬆️"
    else:
        operate, content = "", "down ⬇️"
    os.system(f"xbacklight {operate}{value}")
    brightness = int(
        float(subprocess.check_output("xbacklight", shell=True, text=True).strip())
    )
    brightness_change_id = 1002
    send_notification(
        "💡 Brightness Change",
        f"Background brightness {content}: {brightness}%",
        brightness_change_id,
        brightness,
    )


@lazy.function
def change_layout(qtile: Qtile, prev: bool = False):
    if prev:
        state = "prev"
        qtile.cmd_prev_layout()
    else:
        state = "next"
        qtile.cmd_next_layout()
    layout_change_notification_id = 1000
    send_notification(
        "🔁 Layout Change",
        f"Change to {state} layout ...\nThe current layout is [{qtile.current_layout.name}]!",
        layout_change_notification_id,
    )


# Custom functions for key bindings
@lazy.function
def open_terminal_by_need(qtile: Qtile):
    # Don't use lazy api in lazy function
    terminal_group = qtile.groups_map.get(terminal_group_name)
    last_terminal = None
    for w in terminal_group.windows:
        if is_terminal(w):
            last_terminal = w
    if last_terminal:
        last_terminal.togroup(qtile.current_group.name, switch_group=True)
    else:
        for w in qtile.current_group.windows:
            if is_terminal(w):
                last_terminal = w
        if not last_terminal:
            os.system(terminal + terminal_args + " &")


@lazy.function
def take_screenshot(_, window: bool = False):
    if window:
        arg, desc = "", "window"
    else:
        arg, desc = "-u", "fullscreen"
    os.system(f"scrot {arg} ~/Pictures/screenshot-{desc}-$(date -Ins).png")
    screenshot_id = 1003
    send_notification(
        "📸 Screen Shot",
        f"Take the {desc} screenshot success!\nScreenshot saved in dir ~/Pictures.",
        screenshot_id,
    )


@lazy.function
def minimize_window(qtile: Qtile):
    w = qtile.current_window
    if w:
        w.toggle_minimize()
        if is_terminal(w) and not w.minimized:
            w.floating = True
            # Place window to the screen center
            screen = w.group.screen
            x = (screen.width - w.width) // 2  # type: ignore
            y = (screen.height - w.height) // 2  # type: ignore
            w.place(
                x,
                y,
                w.width,  # type: ignore
                w.height,  # type: ignore
                w.borderwidth,
                w.bordercolor,  # type: ignore
            )


keys = [
    # Move focus by arrow keys
    Key([mod], "Left", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "Right", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "Up", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "Down", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "Tab", lazy.group.next_window(), desc="Move focus to next window"),
    Key(
        [mod],
        "quoteleft",
        lazy.group.prev_window(),
        desc="Move focus to prev window (mod + `)",
    ),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key(
        [mod, "control"], "Left", lazy.layout.shuffle_left(), desc="Move window to left"
    ),
    Key(
        [mod, "control"],
        "Right",
        lazy.layout.shuffle_right(),
        desc="Move window to right",
    ),
    Key([mod, "control"], "Up", lazy.layout.shuffle_up(), desc="Move window to up"),
    Key(
        [mod, "control"], "Down", lazy.layout.shuffle_down(), desc="Move window to down"
    ),
    # Layout operation
    Key([mod, "control"], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod], "space", change_layout, desc="Toggle between layouts"),
    Key(
        [mod, "control"],
        "space",
        change_layout(True),
        desc="Toggle between layouts",
    ),
    # Window operation
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "m", lazy.window.toggle_maximize(), desc="Maxmize the current window"),
    Key([mod], "n", minimize_window, desc="Minimize the current window"),
    Key(
        [mod, "control"],
        "f",
        # Qtile built-in floating toggle function with xcompmgr will cause window freeze
        # Use 'picom' instead
        lazy.window.toggle_floating(),
        desc="Floating the focused window",
    ),
    # System operation
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a procodmpt widget"),
    # Open custom apps
    Key([mod], "b", lazy.spawn(browser), desc="Google Chrome Browser"),
    Key([mod], "d", lazy.spawn(dictionary), desc="Golden Dict"),
    Key([mod], "l", lazy.spawn("dm-tool lock"), desc="Lock Screen"),
    Key(
        [mod],
        "f",
        lazy.spawn(terminal + terminal_args + " -c " + file_manager),
        desc="Ranger file manager",
    ),
    Key(
        [mod],  # Open a existed terminal or create a new terminal
        "Return",
        open_terminal_by_need,
        desc="Launch terminal",
    ),
    Key(
        [mod, "control"],  # Launch a new terminal
        "Return",
        lazy.spawn(terminal + terminal_args),
        desc="Launch terminal",
    ),
    Key(
        [mod],  # Clear all notifications
        "BackSpace",
        lazy.spawn("dunstctl close-all"),
        desc="Close all notifications",
    ),
    # Screenshot
    Key(
        [],
        "Print",
        take_screenshot,
        desc="Take screenshot for full screen",
    ),
    Key(
        [mod],
        "Print",
        take_screenshot(True),
        desc="Take screenshot for current window",
    ),
    # Special key bindings
    Key(
        [],
        "XF86AudioMute",
        change_pulse_mute,
        desc="Change audio state",
    ),
    Key(
        [],
        "XF86AudioRaiseVolume",
        change_pulse_volume(5),
        desc="Change the volume",
    ),
    Key(
        [],
        "XF86AudioLowerVolume",
        change_pulse_volume(-5),
        desc="Change the volume",
    ),
    Key(
        [mod],
        "XF86AudioRaiseVolume",
        change_pulse_volume(1),
        desc="Change the volume",
    ),
    Key(
        [mod],
        "XF86AudioLowerVolume",
        change_pulse_volume(-1),
        desc="Change the volume",
    ),
    Key(
        [],
        "XF86MonBrightnessUp",
        change_brightness(5),
        desc="Change the brightness",
    ),
    Key(
        [],
        "XF86MonBrightnessDown",
        change_brightness(-5),
        desc="Change the brightness",
    ),
    Key(
        [mod],
        "XF86MonBrightnessUp",
        change_brightness(1),
        desc="Change the brightness",
    ),
    Key(
        [mod],
        "XF86MonBrightnessDown",
        change_brightness(-1),
        desc="Change the brightness",
    ),
]

# Add groups
groups = [Group(i) for i in f"❶❷❸❹{terminal_group_name}"]
# Set up group keys
for i in range(len(groups)):
    group_key, group_name = str(i + 1), groups[i].name
    if group_name != terminal_group_name:
        keys.extend(
            [
                # mod1 + letter of group = switch to group
                Key(
                    [mod],
                    group_key,
                    lazy.group[group_name].toscreen(),
                    desc=f"Switch to group {group_name}",
                ),
                # mod1 + shift + letter of group = switch to & move focused window to group
                Key(
                    [mod, "control"],
                    group_key,
                    lazy.window.togroup(group_name, switch_group=True),
                    desc=f"Switch to & move focused window to group {group_name}",
                ),
            ]
        )

margin, border_width = 5, 4
screens = [
    # By default, Qtile layout window margin will cause the gap between two window double size,
    # should use Screen gap to fill the remaining width.
    # Screen gap + Window margin == 2 * Window margin
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayoutIcon(scale=0.8),
                widget.GroupBox(),
                widget.Prompt(),
                widget.WindowCount(text_format="[{num}]"),
                widget.WindowTabs(),
                widget.Net(format="🌐 {down}"),
                widget.Battery(format="🔋 {percent:2.0%}({char})", update_interval=10),
                widget.GenPollText(func=show_pulse_volume, update_interval=1),
                widget.Systray(),
                widget.Clock(format=" %Y-%m-%d %a %I:%M %p ", foreground="#d75f5f"),
            ],
            25,
            opacity=0.5,
            # [N E S W]
            margin=[0, 0, margin, 0],
            # Set up bar inner content gap
            border_width=[5, 2 * margin, 5, 2 * margin],
        ),
        bottom=bar.Gap(margin),
        left=bar.Gap(margin),
        right=bar.Gap(margin),
    )
]
layouts = [
    layout.Bsp(margin=margin, border_width=border_width),
    layout.Columns(margin=margin, border_width=border_width),
    layout.Max(),
]
floating_layout = layout.Floating(
    border_width=border_width,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        # Custom rules
        Match(wm_class=terminal_wm_class),
    ],
)

# Drag floating layouts.
mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod, "control"],
        "Button1",
        lazy.window.set_size_floating(),
        start=lazy.window.get_size(),
    ),
    Click([mod], "Button3", lazy.window.bring_to_front()),
]

# Set auto start commands
# PulseAudio and Fcitx 5 can autorun by systemd service
once_cmds = [
    "picom",  # Compositing manager, for transparent support
    "clash-premium",  # Clash proxy
    "nm-applet",  # Show network status
]
normal_cmds = [
    "xset +dpms",
    "xset dpms 0 0 1800",
    "xset s 1800",
]
run_once = lambda cmd: os.system(f"fish -c 'pgrep -u $USER -x {cmd}; or {cmd} &'")
[run_once(cmd) for cmd in once_cmds]
[os.system(cmd) for cmd in normal_cmds]


# Hooks
@hook.subscribe.client_focus
def client_focus(c: Window):
    if c.floating:
        c.cmd_bring_to_front()  # Bring the floating focus window to front
    else:
        for w in c.group.windows:
            if w.floating and is_terminal(w):
                w.togroup(terminal_group_name)
