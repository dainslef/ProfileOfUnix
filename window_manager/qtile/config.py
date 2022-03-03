# Qtile configuration
# Place this file in the path ~/.config/qtile/config.py
# Qtile will log in the path ~/.local/share/qtile/qtile.log

# Import library
from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen, ScratchPad, DropDown
from libqtile.backend.base import Window
from libqtile.core.manager import Qtile
from libqtile.lazy import lazy

import os, subprocess
from enum import Enum, auto

# Qtile pre-define config variables
follow_mouse_focus = False
auto_fullscreen = True
reconfigure_screens = True
bring_front_click = True
focus_on_window_activation = "focus"

# User custom variables
mod = "mod4"

# Notification Types
class NotificationType(Enum):
    CHANGE_PLUSE_VOLUME = 1000
    CHANGE_BRIGHTNESS = auto()
    CHANGE_LAYOUT = auto()
    TAKE_SCREENSHOT = auto()


# Color settings
class Color:
    CLOCK = "#00FFFF"

    class Border:
        NORMAL = "#999999"
        FOCUS = "#556677"
        FLOATING_FOCUS = "#667788"


# Application settings
class Application:
    MAIL = "thunderbird"
    BROWSER = "google-chrome-stable"
    DICTIONARY = "goldendict"
    FILE_MANAGER = "ranger"
    LOCK_SCREEN = "dm-tool lock"

    class Terminal:
        WM_CLASS = "Terminal"
        GROUP_NAME = "T"
        MATCH_RULE = Match(wm_class=WM_CLASS)
        __command = "vte-2.91"
        __args = " -W -P never -g 120x40 -n 5000 -T 20 --reverse --no-decorations --no-scrollbar"

        # Add method to Window class
        Window.is_terminal = lambda c: c and c.match(Application.Terminal.MATCH_RULE)

        @staticmethod
        def generate_command(
            run_background: bool = False, run_other_command: str = None
        ) -> str:
            backgroud = "&" if run_background else ""
            other_command = f"-c {run_other_command}" if run_other_command else ""
            return f"{Application.Terminal.__command} {Application.Terminal.__args} {backgroud} {other_command}"


# Send the notification
def send_notification(
    title: str,
    content: str,
    replace_id: NotificationType = None,
    percent_value: int = None,
):
    replace = f"-r {replace_id.value}" if replace_id else ""
    percent = f"-h int:value:{percent_value}" if percent_value else ""
    os.system(f"dunstify '{title}' '{content}' {replace} {percent}")


# Util functions
def pulse_volume() -> int:
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
def pulse_volume_text() -> str:
    percent = pulse_volume()
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
        change = "100" if pulse_volume() + volume > 100 else f"{op}{volume}"
    else:
        op, volume_change = "", "lower ⬇️"
        change = volume
    os.system(f"pactl set-sink-volume {sink} {change}%")
    send_notification(
        "🔈 Volume Change",
        f"Volume {volume_change}",
        NotificationType.CHANGE_PLUSE_VOLUME,
        pulse_volume(),
    )


@lazy.function
def change_pulse_mute(_):
    sink = 0
    state = "🔊 ON" if is_pulse_mute() else "🔇 OFF"
    os.system(f"pactl set-sink-mute {sink} toggle")
    send_notification(
        "🔈 Volume changed",
        f"Sound state has been changed ...\nCurrent sound state is [{state}]!",
        NotificationType.CHANGE_PLUSE_VOLUME,
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
    send_notification(
        "💡 Brightness Change",
        f"Background brightness {content} {brightness}%",
        NotificationType.CHANGE_BRIGHTNESS,
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
    send_notification(
        "🔁 Layout Change",
        f"Change to {state} layout ...\nThe current layout is [{qtile.current_layout.name}]!",
        NotificationType.CHANGE_LAYOUT,
    )


# Custom functions for key bindings
# Don't use lazy api in lazy function
@lazy.function
def open_terminal_by_need(qtile: Qtile):
    next_terminal = None
    # First try to get terminal window from terminal group
    for w in qtile.groups_map.get(Application.Terminal.GROUP_NAME).windows:
        if w.is_terminal():
            next_terminal = w
    if next_terminal:
        # Move terminal window from terminal group to current group
        next_terminal.togroup(qtile.current_group.name, switch_group=True)
    else:
        first_other_terminal, after_current = None, False
        # If no terminal window in terminal group, then try to find window in current group
        for w in qtile.current_group.windows:
            if w.is_terminal():
                if after_current:
                    next_terminal = w
                    break
                if w != qtile.current_window:
                    if not first_other_terminal:
                        # Backup the first other terminal window
                        first_other_terminal = w
                else:
                    # Mark if the index is after current terminal window
                    after_current = True
        if next_terminal or first_other_terminal:
            # Should use Group API to change the window focus,
            # change focus with Window API won't change window border color
            qtile.current_group.focus(next_terminal or first_other_terminal, True)
        elif not qtile.current_window or not qtile.current_window.is_terminal():
            os.system(Application.Terminal.generate_command(run_background=True))


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
        if w.is_terminal() and not w.minimized:
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


@lazy.function
def next_window(qtile: Qtile):
    w = qtile.current_window
    if w and not w.fullscreen:
        # Only switch window when the current window isn't fullscreen
        qtile.current_group.cmd_next_window()


@lazy.function
def prev_window(qtile: Qtile):
    w = qtile.current_window
    if w and not w.fullscreen:
        qtile.current_group.cmd_prev_window()


keys = [
    # Move focus by arrow keys
    Key([mod], "Left", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "Right", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "Up", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "Down", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "Tab", next_window, desc="Move focus to next window"),
    Key([mod], "quoteleft", prev_window, desc="Move focus to prev window (mod + `)"),
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
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod], "space", change_layout, desc="Toggle between layouts"),
    Key(
        [mod, "control"],
        "space",
        change_layout(True),
        desc="Toggle between layouts",
    ),
    # Window operation
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod, "control"],
        "m",
        lazy.window.toggle_fullscreen(),
        desc="Maxmize the current window",
    ),
    Key([mod, "control"], "n", minimize_window, desc="Minimize the current window"),
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
    Key([mod], "m", lazy.spawn(Application.MAIL), desc="Mail"),
    Key([mod], "b", lazy.spawn(Application.BROWSER), desc="Google Chrome Browser"),
    Key([mod], "d", lazy.spawn(Application.DICTIONARY), desc="Golden Dict"),
    Key([mod], "l", lazy.spawn(Application.LOCK_SCREEN), desc="Lock Screen"),
    Key(
        [mod],
        "f",
        lazy.spawn(
            Application.Terminal.generate_command(
                run_other_command=Application.FILE_MANAGER
            )
        ),
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
        lazy.spawn(Application.Terminal.generate_command()),
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
    # Volume keybings
    Key(
        [],
        "XF86AudioMute",
        change_pulse_mute,
        desc="Change audio state",
    ),
    *[
        Key(
            m,
            f"XF86Audio{d}Volume",
            change_pulse_volume(v),
            desc="Change the volume",
        )
        for (m, d, v) in [
            ([], "Raise", 5),
            ([], "Lower", -5),
            ([mod], "Raise", 1),
            ([mod], "Lower", -1),
        ]
    ],
    # Brightness key bindings
    *[
        Key(
            m,
            f"XF86MonBrightness{d}",
            change_brightness(v),
            desc="Change the brightness",
        )
        for (m, d, v) in [
            ([], "Up", 5),
            ([], "Down", -5),
            ([mod], "Up", 1),
            ([mod], "Down", -1),
        ]
    ],
]

# Add groups
groups = [Group(i) for i in f"❶❷❸❹"]
# Set up group keys
for i in range(len(groups)):
    group_key, group_name = str(i + 1), groups[i].name
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
groups.extend(
    [
        Group(Application.Terminal.GROUP_NAME),
        ScratchPad(
            "Scratchpad",
            # define a drop down terminal.
            # it is placed in the upper third of screen by default.
            [DropDown("DropDown", Application.Terminal.generate_command(), height=0.5)],
        ),
    ]
)
keys.extend([Key([mod], "s", lazy.group["Scratchpad"].dropdown_toggle("DropDown"))])

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
                widget.Battery(
                    format="🔋 {percent:2.0%}({char})",
                    update_interval=10,
                    show_short_text=False,  # Make battery plugin show full format text in Full/Empty status
                ),
                widget.GenPollText(func=pulse_volume_text, update_interval=1),
                widget.Systray(),
                widget.Clock(format=" %Y-%m-%d %a %I:%M %p ", foreground=Color.CLOCK),
            ],
            25,
            opacity=0.6,
            # [N E S W]
            margin=[0, 0, margin, 0],
            # Set up bar inner content gap
            border_width=[margin, margin, margin, margin],
        ),
        bottom=bar.Gap(margin),
        left=bar.Gap(margin),
        right=bar.Gap(margin),
    )
]
layouts = [
    l(
        margin=margin,
        border_width=border_width,
        border_focus=Color.Border.FOCUS,
        border_normal=Color.Border.NORMAL,
    )
    for l in [layout.Bsp, layout.Columns, layout.Max]
]
floating_layout = layout.Floating(
    border_width=border_width,
    border_focus=Color.Border.FLOATING_FOCUS,
    border_normal=Color.Border.NORMAL,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        # Custom rules
        Application.Terminal.MATCH_RULE,
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
        terminals = [w for w in c.group.windows if w.floating and w.is_terminal()]
        terminals.reverse()  # Reverse terminal windows' order, then move to terminal group
        [w.togroup(Application.Terminal.GROUP_NAME) for w in terminals]
