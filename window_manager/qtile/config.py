# Qtile configuration
# Place this file in the path ~/.config/qtile/config.py

# Import library
from libqtile import bar, layout, widget, hook, qtile
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
    sink = 0
    return int(
        # Get the command output
        subprocess.check_output(
            "pactl list sinks | grep '^[[:space:]]Volume:' |"
            + f"head -n {sink + 1} | tail -n 1 | sed -e 's,.* \\([0-9][0-9]*\\)%.*,\\1,'",
            shell=True,
            text=True,
        )
    )


def is_pulse_mute() -> bool:
    status = subprocess.check_output(
        "pacmd list-sinks | awk '/muted/ { print $2 }'",
        shell=True,
        text=True,
    ).strip()  # Reponse content contains '\n', clear special charactor
    return status == "yes"


# Generate the volume info
def show_pulse_volume() -> str:
    percent = get_pulse_volume()
    is_mute = is_pulse_mute()
    status = "OFF" if is_mute else "ON"
    volume_emoji = (
        "🔇"
        if is_mute
        else "🔊"
        if percent >= 60
        else "🔉"
        if percent >= 20
        else "🔈"
        if percent > 0
        else "🔇"
    )
    return f"{volume_emoji} {percent}%({status})"


def change_pulse_volume(_, volume: int, plus: bool = True):
    sink = 0
    op = "+" if plus else "-"
    # Prevent the volume break 100% limit
    change = "100" if (plus and get_pulse_volume() + volume > 100) else f"{op}{volume}"
    os.system(f"pactl set-sink-volume {sink} {change}%")
    volume_change = "rise up ⬆️" if plus else "lower ⬇️"
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
def change_layout(qtile: Qtile):
    layout_change_notification_id = 1000
    qtile.cmd_next_layout()
    l = qtile.current_layout
    send_notification(
        "🔁 Layout Change",
        f"Layout has been changed ...\nThe current layout is [{l.name}]!",
        layout_change_notification_id,
    )


@lazy.function
def minimize_window(qtile: Qtile):
    w = qtile.current_window
    if w:
        w.cmd_toggle_minimize()
        if is_terminal(w):
            w.floating = True


keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod, "control"], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod, "control"], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod, "control"], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod, "control"], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "Tab", lazy.group.next_window(), desc="Move focus to next window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to right"),
    # Layout operation
    Key([mod, "control"], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod], "space", change_layout, desc="Toggle between layouts"),
    # Window operation
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
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
    # Special key bindings
    Key(
        [],
        "XF86AudioRaiseVolume",
        lazy.function(change_pulse_volume, 10),
        desc="Change the volume",
    ),
    Key(
        [],
        "XF86AudioLowerVolume",
        lazy.function(change_pulse_volume, 10, False),
        desc="Change the volume",
    ),
    Key(
        [mod],
        "XF86AudioRaiseVolume",
        lazy.function(change_pulse_volume, 1),
        desc="Change the volume",
    ),
    Key(
        [mod],
        "XF86AudioLowerVolume",
        lazy.function(change_pulse_volume, 1, False),
        desc="Change the volume",
    ),
    Key(
        [],
        "XF86AudioMute",
        change_pulse_mute,
        desc="Change audio state",
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

margin, border_width = 10, 4
layouts = [
    layout.Columns(margin=margin, border_width=border_width),
    # layout.Max(),
    # layout.Stack(num_stacks=3, margin=5),
    # layout.Bsp(),
    # layout.Matrix(margin=5),
    layout.MonadTall(margin=margin, border_width=border_width),
    # layout.MonadWide(),
    # layout.RatioTile(),
    layout.Tile(margin=margin, border_width=border_width),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
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

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayout(),
                widget.GroupBox(),
                widget.Prompt(),
                widget.WindowTabs(),
                widget.Net(format="🌐 {down}"),
                # widget.TextBox("|"),
                widget.Battery(format="🔋 {percent:2.0%}({char})"),
                # widget.TextBox("|"),
                widget.GenPollText(func=show_pulse_volume, update_interval=2),
                widget.Systray(),
                widget.Clock(format=" %Y-%m-%d %a %I:%M %p ", foreground="#d75f5f"),
            ],
            25,
            opacity=0.6,
            border_width=[5, 5, 5, 5],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        )
    )
]

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
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

# Set auto start commands
once_cmds = [
    "picom",  # Compositing manager, for transparent support
    "clash-premium",  # Clash proxy
    "fctix",  # Use input methods
    "nm-applet",  # Show network status
]
normal_cmds = [
    # "pulseaudio --start",  # For sound system
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
