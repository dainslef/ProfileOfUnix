# Place this file at the path: ~/.config/fish/config.fish

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

    if [ (whoami) = "$default_user" ]

        # Check OS type and set the different environment variables
        if [ (uname) = "Darwin" ] # Darwin kernel means in macOS

            set PATH $PATH /usr/local/sbin
            set python_version (python3 -V | awk -F' ' '{ print $2 }' | awk -F'.' '{ print $1 "." $2 }')
            set pip_bin ~/Library/Python/$python_version/bin

            # set -xg HOMEBREW_BOTTLE_DOMAIN https://mirrors.ustc.edu.cn/homebrew-bottles
            # Set environment variable for Homebrew Bottles mirror (use TUNA mirror)
            set -xg HOMEBREW_BOTTLE_DOMAIN https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/

        else if [ (uname) = "Linux" ]

            # Remember "alias" is synatx candy for "function" in fish shell,
            # alias command can not run at background like "xxx &".
            function idea
                ~/Public/idea-IU/bin/idea.sh $argv &
            end

        end

        # Set haskell stack GHC compiler path
        set PATH $PATH (stack path --compiler-bin)

        # Set python pip package binary path
        if [ -e "$pip_bin" ]
            set PATH $PATH $pip_bin
        end

        # Set the local binary path
        if [ -e ~/.local/bin ]
            set PATH $PATH ~/.local/bin
        end

        # Set the rustup mirror and cargo binary path
        set -xg RUSTUP_DIST_SERVER https://mirrors.tuna.tsinghua.edu.cn/rustup
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
            set -xg EDITOR "nano"
        else
            set -xg EDITOR "vim"
        end

    end

end

# Set the theme config
function theme_config

    # Set the theme, only in Linux GUI and macOS
    if [ -n "$DISPLAY" -o (uname) = "Darwin" ]
        omf theme "bobthefish"
        # Set theme color for bobthefish
        # Override the default greeting at ~/.config/fish/functions/fish_greeting.fish or refine function
        if [ (uname) = "Darwin" ]
            set -g theme_color_scheme dark
        else if [ (uname) = "Linux" ]
            set -g theme_color_scheme light
        end
        set -g theme_date_format "+%b-%d [%a] %R:%S"
    else # Use default in Non-GUI environment
        omf theme "default"
    end

end

# Call function if oh-my-fish is installed
if [ -n "$OMF_PATH" ]
    set_default_user "dainslef"
    env_config
    theme_config
end



# --- Override functions  ---

# In fish shell, function which named with "fish_greeting" will override default greeting
function fish_greeting

    if [ (whoami) = "$default_user" ]
        if [ (uname) = "Darwin" ]
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
