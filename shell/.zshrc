# Place this file at the place: ~/.zshrc

# This zsh config need to set up Oh-My-Zsh:
# $ git clone git://github.com/robbyrussell/oh-my-zsh ~/.oh-my-zsh
# $ git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
# $ git clone git://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting



# ------------------------------------------------------------------------------
# --- Function define ---

# Set the default user
function set_default_user()
{
	DEFAULT_USER=$1
}

# Print the welcome message
function show_welcome()
{
	if [ $UID -gt 0 ]; then
		if [ $(uname) = "Darwin" ]; then
			local show_os_version="$(uname -srnm)"
		elif [ -n "$DISPLAY" ]; then
			local show_os_version="$(uname -ornm)"
		fi
	fi

	if [ -n "$show_os_version" ]; then # Print welcome message in macOS or Linux GUI
		echo -ne "\033[1;30m" # Set greet color
		echo $(uptime)
		echo $show_os_version
		echo --- Welcome, $(whoami)! Today is $(date +"%B %d %Y, %A"). ---
		case $[$RANDOM % 5] in
			0) echo "--- 夢に描けることなら、実現できる。 ---\n" ;;
			1) echo "--- 一日は貴い一生である。これを空費してはならない。 ---\n" ;;
			2) echo "--- 世界は美しくなんかない。そしてそれ故に、美しい。 ---\n" ;;
			3) echo "--- 春は夜桜、夏には星、秋に満月、冬には雪。 ---\n" ;;
			4) echo "--- あなたもきっと、誰かの奇跡。 ---\n" ;;
		esac
		echo -ne "\033[0m" # Reset color
	fi
}

# Check user, set the custom environment variables
function env_config()
{
	if [ $(whoami) = $DEFAULT_USER ]; then

		# Check OS type and set the different environment variables
		if [ $(uname) = "Darwin" ]; then # Darwin kernel means in macOS

			local python_version=`echo $(python3 -V) | awk -F' ' '{ print $2 }' | awk -F'.' '{ print $1 "." $2 }'`
			local pip_bin=~/Library/Python/$python_version/bin

			# Set environment variable for Homebrew Bottles mirror (use USTC mirror)
			export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles

		elif [ $(uname) = "Linux" ]; then

			local pip_bin=~/.local/bin

			# For custom tools alias in Linux
			alias stack=~/Public/stack-linux-x86_64-static/stack
			alias code=~/Public/VSCode-linux-x64/code
			alias idea=~/Public/idea-IU/bin/idea.sh

		fi

		# Set golang path
		export GOPATH=~/Public/Go

		# Set python pip package path
		if [ -e $pip_bin ]; then
			PATH+=:$pip_bin
		fi

		# Set language environment
		export LANG=en_US.UTF-8
		export LC_ALL=en_US.UTF-8

		# Preferred editor for local and remote sessions
		if [[ -n $SSH_CONNECTION ]]; then
			export EDITOR="nano"
		else
			export EDITOR="vim"
		fi

	fi
}

# Set the file type alias
function type_alias_config()
{
	local extract="7z x"

	if [ $(uname) = "Darwin" ] || [ -n "$DISPLAY" ]; then
		local editor="code"
	else
		local editor=$EDITOR
	fi

	alias -s cpp=$editor
	alias -s cc=$editor
	alias -s c=$editor
	alias -s cs=$editor
	alias -s m=$editor
	alias -s mm=$editor
	alias -s scala=$editor
	alias -s java=$editor
	alias -s html=$editor
	alias -s xml=$editor
	alias -s md=$editor
	alias -s zip=$extract
	alias -s gz=$extract
	alias -s bz2=$extract
	alias -s rar=$extract
	alias -s tar=$extract
}

# Set the Oh-My-Zsh config:
function oh_my_zsh_config()
{
	# Set the Oh-My-Zsh path and plantform plugins
	if [ -e "/home/$DEFAULT_USER" ]; then
		local ZSH="/home/$DEFAULT_USER/.oh-my-zsh"
		plugins=(systemd)
	elif [ -e "/Users/$DEFAULT_USER" ]; then
		local ZSH="/Users/$DEFAULT_USER/.oh-my-zsh"
		plugins=(osx)
	else
		local ZSH="~/.oh-my-zsh"
	fi

	# Uncomment the following line to disable bi-weekly auto-update checks
	DISABLE_AUTO_UPDATE="true"

	# Stamp shown in the history command output
	# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
	HIST_STAMPS="yyyy-mm-dd"

	# Set common plugins
	plugins+=(sudo scala pip django gem golang mvn zsh-syntax-highlighting zsh-autosuggestions)

	# Set the theme, only in Linux GUI and macOS
	if [ -n "$DISPLAY" ] || [ $(uname) = "Darwin" ]; then
		local ZSH_THEME="agnoster" # Use ZSH theme "agnoster"
	fi

	source $ZSH/oh-my-zsh.sh
}

# Call function
set_default_user "dainslef"
show_welcome
env_config
type_alias_config
oh_my_zsh_config

# Delete defined functions
unset -f set_default_user show_welcome env_config type_alias_config oh_my_zsh_config



# ------------------------------------------------------------------------------
# --- Custom theme ---

# if [ $UID -eq 0 ]; then # root
# 	local start_status="%{$fg_bold[red]%}%n"
# 	local path_status="%{$fg_bold[cyan]%}%2~"
# 	local end_status="%{$fg_bold[yellow]%}#"
# else # normal_user
# 	local start_status="%{$fg_bold[yellow]%}%n"
# 	local path_status="%{$fg_bold[green]%}%2~"
# 	local end_status="%{$fg_bold[cyan]%}$"
# fi

# # Show the command execute result with different color and icon
# local result_status="%(?:%{$fg_bold[green]%}✔:%{$fg_bold[red]%}✘)"

# PROMPT='${start_status}%{$fg[magenta]%}[$(git_prompt_info)${path_status}%{$fg_bold[magenta]%}] ${end_status} '
# RPROMPT='${result_status} %{$fg_bold[blue]%}%T%{$reset_color%}'

# ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}"
# ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg_bold[yellow]%} ⇔ %f"
# ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%}⬆%f"
# ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[red]%}𝝙%f"
# ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}⚑%f"

# ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚"
# ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%}✹"
# ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✖"
# ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}❤"
# ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%}↹"
# ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}✭"



# ------------------------------------------------------------------------------
# --- Format string ---

# List of vcs_info format strings:
# %b => current branch
# %a => current action (rebase/merge)
# %s => current version control system
# %r => name of the root directory of the repository
# %S => current path relative to the repository root directory
# %m => in case of Git, show information about stashes
# %u => show unstaged changes in the repository
# %c => show staged changes in the repository

# List of prompt format strings:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)
