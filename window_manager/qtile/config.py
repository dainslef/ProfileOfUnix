# Qtile configuration
# Link this file to the path ~/.config/qtile/config.py.
# Qtile will log in the path ~/.local/share/qtile/qtile.log.

# Import library
from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen, ScratchPad, DropDown
from libqtile.backend.base import Window
from libqtile.core.manager import Qtile
from libqtile.lazy import lazy
from libqtile.log_utils import logger

import os, subprocess
from typing import Callable
from enum import Enum, auto


# Qtile most useful API:
# qtile.current_window
# qtile.current_layout
# qtile.current_group
#
# Common Functions:
# Focus specific window: qtile.current_group.focus(widnow)
# Get all windows in current group: qtile.current_group.windows
#
# Command API:
# lazy.xxx.cmd_xxx
#
# Main source files:
# libqtile/core/manager.py => Qtile
# libqtile/backend/base.py => Window
# libqtile/layout/base.py => Layout
# libqtile/group.py => Group


# Log start message.
# logger for debug, logger level should large than "warnning".
logger.warn("Qtile start ...")


# Qtile pre-define config variables
follow_mouse_focus = False
auto_fullscreen = True
reconfigure_screens = True
bring_front_click = True
focus_on_window_activation = "focus"

# User custom variables.
mod = "mod4"


# Set auto start commands.
# Currently autorun by systemd service.
once_cmds = [
    # "nm-applet",  # Show network status.
    # "picom",  # Compositing manager, for transparent support.
    # "fcitx5", # Fcitx5 is provided by systemd service.
    # "clash-premium",  # Clash proxy is provided by systemd service.
]
normal_cmds = [
    "systemctl --user start pulseaudio",  # In NixOS PulseAudio should restart during window manager startup, otherwise command can't get PulseAudio volume correctly.
    "xset +dpms",
    "xset dpms 0 0 1800",
    "xset s 1800",
]
run_once = lambda cmd: os.system(f"fish -c 'pgrep -u $USER -x {cmd}; or {cmd} &'")
[run_once(cmd) for cmd in once_cmds]
[os.system(cmd) for cmd in normal_cmds]


# Notification Types
class NotificationType(Enum):
    CHANGE_VOLUME = 1000
    CHANGE_BRIGHTNESS = auto()
    CHANGE_LAYOUT = auto()
    TAKE_SCREENSHOT = auto()


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


# Get command ouput
def get_command_output(command: str) -> str:
    return subprocess.check_output(
        command,
        shell=True,
        text=True,
    ).strip()  # Some reponse content contains '\n', clear special charactor


# Color settings
class Color:
    CLOCK = "#00FFFF"
    BAR = "#001122"

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

    # Find the next normal window (Skip the minimized window).
    def next_normal_window(qtile: Qtile):
        w = qtile.current_window  # Save current window.
        if w:
            # Skip minimized windows when switch windows.
            while qtile.current_window.minimized:
                qtile.current_group.cmd_next_window()
                if qtile.current_window == w:
                    # If current window is saved window,
                    # means all window had been traversed (all windows are minimized),
                    # break the loop to avoid the dead loop.
                    break

    # Bind the method to Qtile class
    Qtile.next_normal_window = next_normal_window

    class Terminal:
        WM_CLASS = "Terminal"
        GROUP_NAME = ""
        MATCH_RULE = Match(wm_class=WM_CLASS)
        __command = "vte-2.91"
        __args = " -g 120x40 -n 5000 -T 10 --no-decorations --no-scrollbar"  # --reverse

        # Add method to Window class.
        Window.is_terminal = lambda c: c and c.match(Application.Terminal.MATCH_RULE)

        @staticmethod
        def generate_command(
            run_background: bool = False, run_other_command: str = None
        ) -> str:
            backgroud = "&" if run_background else ""
            other_command = f"-c {run_other_command}" if run_other_command else ""
            return f"{Application.Terminal.__command} {Application.Terminal.__args} {backgroud} {other_command}"


# Sound control settings
class VolumeControl:
    # Check if system enabled PulseAudio.
    IS_PULSE_AUDIO_ENABLED = os.system("pacmd stat") == 0
    logger.warning(f"IS_PULSE_AUDIO_ENABLED: {IS_PULSE_AUDIO_ENABLED}")

    # Set up the commands
    if IS_PULSE_AUDIO_ENABLED:
        # PulseAudio commands
        SINK = int(
            # Get SINK device index, the current used sound device will have '*' mark.
            get_command_output("pacmd list-sinks | grep -Po '(?<=\\* index:) \\d+'")
        )
        GET_VOLUME = (
            # Get volume (when a computer has multi sinks, get the output from the device which has '*' mark)
            f"pacmd list-sinks | grep -Po '(?<=volume: front-left: \\d{{5}} /) +\\d+(?=% /)' | sed -n {SINK + 1}p"
        )
        CHECK_MUTE = (
            f"pacmd list-sinks | grep -Po '(?<=muted: )\\S+' | sed -n {SINK + 1}p"
        )
        MUTE_STATUS = "yes"
        # "pacmd" doesn't have "toggle" subcommand, so need use "pactl" to toggle mute.
        MUTE_TOGGLE = f"pactl set-sink-mute {SINK} toggle"
    else:
        # ALSA commands
        GET_VOLUME = "amixer get Master | grep -Po '\d+(?=%)'"
        CHECK_MUTE = "amixer get Master | grep -Po '\[(o|n|f)+\]'"
        MUTE_STATUS = "[off]"
        MUTE_TOGGLE = "amixer set Master toggle"

    def __get_volume() -> int:
        return int(get_command_output(VolumeControl.GET_VOLUME))

    def __is_mute() -> bool:
        status = get_command_output(VolumeControl.CHECK_MUTE)
        return status == VolumeControl.MUTE_STATUS

    @staticmethod
    def get_volume_text() -> str:
        percent = VolumeControl.__get_volume()
        not_mute = not VolumeControl.__is_mute()
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

    @staticmethod
    @lazy.function
    def change_mute(_):
        state = "🔊 ON" if VolumeControl.__is_mute() else "🔇 OFF"
        os.system(VolumeControl.MUTE_TOGGLE)
        send_notification(
            "🔈 Volume State Changed",
            f"Sound state has been changed ...\nCurrent sound state is [{state}]!",
            NotificationType.CHANGE_VOLUME,
        )

    @staticmethod
    @lazy.function
    def change_volume(_, volume: int):
        op, volume_change = ("+", "rise up ⬆️") if volume > 0 else ("-", "lower ⬇️")
        if VolumeControl.IS_PULSE_AUDIO_ENABLED:
            if volume > 0:
                change = (
                    "100"
                    if VolumeControl.__get_volume() + volume > 100
                    else f"{op}{volume}"
                )  # Prevent the volume break 100% limit
            else:
                change = volume
                op = ""
            os.system(f"pactl set-sink-volume {VolumeControl.SINK} {change}%")
        else:
            os.system(f"amixer set Master {abs(volume)}%{op}")
        new_volume = VolumeControl.__get_volume()
        send_notification(
            "🔈 Volume Changed",
            f"Volume {volume_change} ({new_volume}%)",
            NotificationType.CHANGE_VOLUME,
            new_volume,
        )


@lazy.function
def change_brightness(_, value: int):
    # Check if 'brightnessctl' tool exist.
    if os.system("brightnessctl") > 0:
        send_notification(
            "Tool not found!",
            'Change brightness need tool "brightnessctl".\nPlease install this tool.',
        )
    if value > 0:
        prefix, suffix, content = "+", "", "up ⬆️"
    else:
        prefix, suffix, content = "", "-", "down ⬇️"
    os.system(f"brightnessctl set {prefix}{abs(value)}%{suffix}")
    brightness = int(get_command_output("brightnessctl | grep -Po '\\d+(?=\\%\\))'"))
    send_notification(
        "💡 Brightness Changed",
        f"Background brightness {content} ({brightness}%)",
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
        "🔁 Layout Changed",
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
def toggle_window(
    qtile: Qtile,
    operate: Callable[[Window], None],
    check_state: Callable[[Window], bool],
):
    w = qtile.current_window
    if w:
        # The default toggle operation (like fullscreen/minimize) will make floating mark useless.
        operate(w)
        # Skip minimized windows when switch windows.
        qtile.next_normal_window()  # Custom method.
        # Check if the current window is terminal, terminal window need to restore floating state.
        if w.is_terminal() and not check_state(w):
            w.floating = True
            # Qtile has been started to provide the cmd_center() method in Window class since v0.21.
            # In Qtile early version, you need impelement center window function manually.
            w.cmd_center()  # Put the terminal window back to the screen center.


@lazy.function
def hide_floating_terminals(qtile: Qtile):
    terminals = [
        w for w in qtile.current_group.windows if w.floating and w.is_terminal()
    ]
    terminals.reverse()  # Reverse terminal windows' order, then move to terminal group.
    [w.togroup(Application.Terminal.GROUP_NAME) for w in terminals]


@lazy.function
def next_window(qtile: Qtile):
    w = qtile.current_window
    if w and not w.fullscreen:
        # Only switch window when the current window isn't fullscreen
        qtile.current_group.cmd_next_window()
        # Skip minimized windows when switch windows.
        qtile.next_normal_window()  # Custom method.


@lazy.function
def prev_window(qtile: Qtile):
    w = qtile.current_window
    if w and not w.fullscreen:
        qtile.current_group.cmd_prev_window()
        # Skip minimized windows when switch windows.
        qtile.next_normal_window()  # Custom method.


@lazy.function
def restore_minimized_window(qtile: Qtile):
    for w in qtile.current_group.windows:
        if w.minimized:
            w.toggle_minimize()
            qtile.current_group.focus(w)
            break  # Only restore one window each time.


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
        [mod, "control"], "b", restore_minimized_window, desc="Restore minimized window"
    ),
    Key(
        [mod, "control"],
        "m",
        toggle_window(lambda w: w.toggle_fullscreen(), lambda w: w.fullscreen),
        desc="Maxmize the current window",
    ),
    Key(
        [mod, "control"],
        "n",
        toggle_window(lambda w: w.toggle_minimize(), lambda w: w.minimized),
        desc="Minimize the current window",
    ),
    Key(
        [mod, "control"],
        "f",
        # Qtile built-in floating toggle function with xcompmgr will cause window freeze
        # Use 'picom' instead
        lazy.window.toggle_floating(),
        desc="Floating the focused window",
    ),
    Key(
        [mod, "control"],
        "h",
        hide_floating_terminals,
        desc="Hide all floating windows",
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
        lazy.spawn("flameshot screen"),
        desc="Take screenshot for full screen",
    ),
    Key(
        [mod],
        "Print",
        lazy.spawn("flameshot gui"),
        desc="Take screenshot for current window",
    ),
    # Volume keybings
    Key(
        [],
        "XF86AudioMute",
        VolumeControl.change_mute,
        desc="Change audio state",
    ),
    *[
        Key(
            m,
            f"XF86Audio{d}Volume",
            VolumeControl.change_volume(v),
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

# Add groups.
groups = [Group(i) for i in f"➊➋➌➍"]
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


# Get system current DPI, than caculate the scaling factor.
standard_dpi = 96
current_dpi = int(
    get_command_output("grep -Po '(?<=DPI set to \\()\\d+' /var/log/X*.0.log")
)
logger.warn(f"Current DPI is {current_dpi}")

# Caculate the border and font size with scaling factor.
scaling_factor = current_dpi / standard_dpi
icon_size, icon_padding = int(20 * scaling_factor), int(5 * scaling_factor)
font_size, font_padding = int(12 * scaling_factor), int(2 * scaling_factor)
bar_height = int(25 * scaling_factor)
margin, border_width = int(5 * scaling_factor), int(4 * scaling_factor)

# Set widget default config and screen widgets.
widget_defaults = dict(
    font="Cascadia Code PL", fontsize=font_size, padding=font_padding
)
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
                widget.WindowCount(text_format="⎛{num}⎠"),
                widget.WindowTabs(),
                widget.Net(format="🌐 {down}"),
                widget.Battery(
                    format="🔋 {percent:2.0%}({char})",
                    update_interval=10,
                    show_short_text=False,  # Make battery plugin show full format text in Full/Empty status
                ),
                widget.GenPollText(
                    func=VolumeControl.get_volume_text, update_interval=1
                ),
                widget.Systray(icon_size=icon_size, paddling=icon_padding),
                widget.Clock(format="%b/%d/%Y %a %H:%M", foreground=Color.CLOCK),
            ],
            bar_height,
            opacity=0.7,
            # [N E S W]
            margin=[0, 0, margin, 0],
            border_color=Color.BAR,
            background=Color.BAR,
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
        border_on_single=True,
    )
    for l in [layout.Columns, layout.MonadThreeCol, layout.Zoomy]
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
        lazy.window.set_position(),  # Use set_position_floating() will make any window floating.
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

# Hooks
@hook.subscribe.client_focus
def client_focus(c: Window):
    if c.floating:
        c.cmd_bring_to_front()  # Bring the floating focus window to front
    else:
        terminals = [w for w in c.group.windows if w.floating and w.is_terminal()]
        terminals.reverse()  # Reverse terminal windows' order, then move to terminal group.
        [w.togroup(Application.Terminal.GROUP_NAME) for w in terminals]
