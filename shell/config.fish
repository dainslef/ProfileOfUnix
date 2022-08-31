# Link this file to the path '~/.config/fish/config.fish'

# This fish config need to install "Oh-My-Fish" and "bobthefish" theme:
# $ curl -L https://get.oh-my.fish | fish
# $ omf install bobthefish

# Fish shell and Oh-My-Fish file directory:
# ~/.local/share/omf
# ~/.local/share/fish
# ~/.cache/omf
# ~/.config/fish



# --- Define custom functions---

# Set the default user
function set_default_user
    # Use "set" to create a variable, use "-g" to create a global variable
    set -g default_user $argv[1]
end

# Check user, set the custom environment variables
function env_config

    set PATH $PATH /usr/local/bin /usr/local/sbin

    if [ (whoami) = "$default_user" ]

        # Check OS type and set the different environment variables
        if [ (uname) = Darwin ] # Darwin kernel means in macOS

            # Set Python PIP binary path.
            set python_version (python3 -V | awk -F' ' '{ print $2 }' | awk -F'.' '{ print $1 "." $2 }')
            set pip_bin ~/Library/Python/$python_version/bin

            # From macOS 12 (Monterey), command 'ls' don't print with color,
            # need to set the 'CLICOLOR' for color output.
            set -gx CLICOLOR 1 # Use ANSI color sequences to distinguish file types

            # Set the environment variable for Homebrew Bottles mirror (no longer need when use clash tun)
            # set -xg HOMEBREW_BOTTLE_DOMAIN https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/bottles
            # set -xg HOMEBREW_BOTTLE_DOMAIN https://mirrors.ustc.edu.cn/homebrew-bottles

        else if [ (uname) = Linux ]

            # Set Python Pip binary path.
            set pip_bin ~/Public/Python/bin

            # Remember "alias" is synatx candy for "function" in fish shell,
            # alias command can not run at background like "xxx &".
            # function idea
            #     ~/Public/idea-IU/bin/idea.sh $argv &
            # end

            # Select input method by desktop environment.
            # Gnome XDG_SESSION_DESKTOP will be gnome-xorg or gnome-wayland
            # By default, string match will return match content to standard output,
            # use output redirection to ignore this output.
            string match 'gnome*' "$XDG_SESSION_DESKTOP" >/dev/null # match return 0 (normal)
            if [ $status = 0 ] || [ "$DESKTOP_SESSION" = pantheon ]
                set input_method ibus
            else
                set input_method fcitx
            end

            # Set the input environment variables.
            set -gx GTK_IM_MODULE $input_method
            set -gx QT_IM_MODULE $input_method
            set -gx XMODIFIERS "@im=$input_method"
            set -gx CLASSPATH $CLASSPATH:.

            # Disable Qt auto scaling, to fix VLC UI scaling problem.
            set -gx QT_AUTO_SCREEN_SCALE_FACTOR 0

            # Set language environment variables.
            set -gx LANG en_US.UTF-8
            set -gx LC_ALL en_US.UTF-8

            # Set terminfo for Kitty.
            set -gx TERM xterm-256color

            # Set Qt style
            if [ "$XDG_SESSION_DESKTOP" = xfce ]
                # Need to set both environment variables,
                # only set QT_STYLE_OVERRIDE=gtk2 will cause application crash.
                set -gx QT_STYLE_OVERRIDE gtk2
                set -gx QT_QPA_PLATFORMTHEME gtk2
            end

        end

        # Set the local binary path
        if [ -e ~/.local/bin ]
            set PATH $PATH ~/.local/bin
        end

        # Set python pip package binary path
        if [ -e "$pip_bin" ]
            set PATH $PATH $pip_bin
        end

        # Set Haskell GHCup path
        if [ -e ~/.ghcup/bin ]
            set PATH $PATH ~/.ghcup/bin
        end

        # Set the environment variable for rustup mirror (no longer need when use clash tun)
        # Install rust stable toolchain: $ rustup toolchain install stable
        set -xg RUSTUP_DIST_SERVER https://mirrors.ustc.edu.cn/rust-static

        # Set cargo binary path
        if [ -e ~/.cargo/bin ]
            set PATH $PATH ~/.cargo/bin
        end

        # Set language environment
        # Use "set -x" to create a environment variable
        # Use "-xg" to set this environment variable as a global environment variable
        set -xg LANG en_US.UTF-8
        set -xg LC_ALL en_US.UTF-8

        # Preferred editor for local and remote sessions
        if [ -n "$SSH_CONNECTION" ]
            set -xg EDITOR nano
        else
            set -xg EDITOR vim
        end

    end

end

# Set the theme config
function theme_config

    # Set the theme, only in Linux GUI and macOS
    if [ -n "$DISPLAY" -o (uname) = Darwin ]
        omf theme bobthefish
        # Set theme color for bobthefish
        # Override the default greeting at ~/.config/fish/functions/fish_greeting.fish or refine function
        set -g theme_color_scheme dark
        set -g theme_date_format "+%b/%d/%Y [%a] %R:%S"
    else # Use default in Non-GUI environment
        omf theme default
    end

end

# Call function if oh-my-fish is installed
if [ -n "$OMF_PATH" ]
    set_default_user dainslef
    env_config
    theme_config
end



# --- Override functions  ---

# In fish shell, function which named with "fish_greeting" will override default greeting
function fish_greeting

    if [ (whoami) = "$default_user" ]
        if [ (uname) = Darwin ]
            set show_os_version (uname -srnm)
        else if [ -n "$DISPLAY" ]
            set show_os_version (uname -ornm)
        end
    end

    # Print welcome message in macOS or Linux GUI
    if [ -n "$show_os_version" ]
        set_color $fish_color_autosuggestion # Set greet color
        echo (uptime)
        echo " $show_os_version"
        echo --- Welcome, (whoami)! Today is (date +"%B %d %Y, %A"). ---
        switch (random 1 7)
            case 1
                echo "--- あなたもきっと、誰かの奇跡。 ---"
            case 2
                echo "--- 一日は貴い一生である。これを空費してはならない。 ---"
            case 3
                echo "--- 世界は美しくなんかない。そしてそれ故に、美しい。 ---"
            case 4
                echo "--- 春は夜桜、夏には星、秋に満月、冬には雪。 ---"
            case 5
                echo "--- 井の中の蛙大海を知らず、されど空の青さを知る。 ---"
            case 6
                echo "--- 前を向けばきっと会える。 ---"
            case 7
                echo "--- 周りの人や時代に流されず、自分らしく生きるだけでいい。 ---"
        end
        echo "" # Add a empty new line
        set_color $fish_color_normal # Reset color
    end

end



# --- Clean the environment  ---

# Delete defined functions and variables
# Use "-e" means to erase a function/variable
functions -e set_default_user
functions -e env_config
functions -e theme_config
