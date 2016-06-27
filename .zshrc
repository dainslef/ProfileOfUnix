# ------------------------------------------------------------------------------
# --- User configuration ---

# Set the ZSH path
if [ -e "/home/dainslef" ]; then
	export ZSH=/home/dainslef/.oh-my-zsh
elif [ -e "/Users/dainslef" ]; then
	export ZSH=/Users/dainslef/.oh-my-zsh
else
	export ZSH=~/.oh-my-zsh
fi

# Check OS type and set the different enviornment variables
if [ $(uname) = "Darwin" ]; then # Darwin kernel means in macOS
	local show_os_version="$(uname -srnm)"
	local normal_uid=500 # In macOS, the normal user's uid start with 500.
	local vscode="/Users/dainslef/Applications/Develop/Visual\ Studio\ Code.app/Contents/MacOS/Electron"
	local python_version=`echo $(python3 -V) | awk -F' ' '{ print $2 }' | awk -F'.' '{ print $1 "." $2 }'`
	local pip_bin=~/Library/Python/$python_version/bin
	plugins=(osx sublime)
elif [ $(uname) = "Linux" ]; then
	local show_os_version="$(uname -ornm)"
	local normal_uid=1000 # In Linux, the normal user's uid start with 1000.
	local vscode=/home/dainslef/Public/VSCode-linux-x64/code
	local pip_bin=~/.local/bin
	plugins=(systemd)
fi

# Check user, show login info and load custom environment variables
if [ $(whoami) != "root" ]
then

	echo $(uptime)
	echo $show_os_version
	echo $(date)
	echo --- Welcome, $(whoami). Try your best everyday! ---
	case $[$RANDOM % 5] in
		0) echo "--- 夢に描けることなら、実現できる。 ---\n" ;;
		1) echo "--- 一日は貴い一生である。これを空費してはならない。 ---\n" ;;
		2) echo "--- 世界は美しくなんかない。そしてそれ故に、美しい。 ---\n" ;;
		3) echo "--- 春は夜桜、夏には星、秋に満月、冬には雪。 ---\n" ;;
		4) echo "--- あなたもきっと、誰かの奇跡。 ---\n" ;;
	esac

	if [ $(whoami) = "dainslef" ]; then

		# For golang
		export GOPATH=~/Public/Go
		PATH+=:$GOPATH/bin

		# For scala activator
		alias activator=~/Public/activator-dist/bin/activator

		# For visual studio code
		alias code=$vscode

		# For python pip
		if [ -e $pip_bin ]; then
			PATH+=:$pip_bin
		fi

		# Load special config under Linux
		if [ $(uname) = "Linux" ]; then

			# For custom IDE path in Linux
			alias netbeans=~/Public/netbeans/bin/netbeans
			alias idea=~/Public/idea-IU/bin/idea.sh
			alias eclipse=~/Public/eclipse/eclipse

			# Set the default user(for theme "agnoster")
			DEFAULT_USER="dainslef"

			# Use theme "agnoster"
			ZSH_THEME="agnoster"
		fi

	fi

fi

# Add common widgets
plugins+=(gem pip django sudo scala golang mvn)

# Uncomment the following line to disable bi-weekly auto-update checks
DISABLE_AUTO_UPDATE="true"

# Stamp shown in the history command output
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Set language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
	export EDITOR="nano"
else
	export EDITOR="vim"
fi

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# Load plugins and themes
source $ZSH/oh-my-zsh.sh



# ------------------------------------------------------------------------------
# --- Custom theme ---

# Only use custom them uder macOS
if [ $(uname) = "Darwin" ]; then

	# Check the UID
	if [ $UID -ge $normal_uid ]; then # normal_user
		local start_status="%{$fg_bold[yellow]%}%n"
		local path_status="%{$fg_bold[green]%}%2~"
		local end_status="%{$fg_bold[cyan]%}$"
	elif [ $UID -eq 0 ]; then # root
		local start_status="%{$fg_bold[red]%}%n"
		local path_status="%{$fg_bold[cyan]%}%2~"
		local end_status="%{$fg_bold[yellow]%}#"
	fi

	# Show the command execute result with different color and icon
	local result_status="%(?:%{$fg_bold[green]%}✔:%{$fg_bold[red]%}✘)"

	PROMPT='${start_status}%{$fg[magenta]%}[$(git_prompt_info)${path_status}%{$fg_bold[magenta]%}] ${end_status} '
	RPROMPT='${result_status} %{$fg_bold[blue]%}%T%{$reset_color%}'

	ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}"
	ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg_bold[yellow]%} ⇔ %f"
	ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%}⬆%f"
	ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[red]%}𝝙%f"
	ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}⚑%f"

	ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚"
	ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%}✹"
	ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✖"
	ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}❤"
	ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%}↹"
	ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}✭"

fi



# ------------------------------------------------------------------------------
# --- Clean custom variables ---

unset show_os_version
unset python_version
unset normal_uid
unset pip_bin
unset plugins
unset vscode



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



# ------------------------------------------------------------------------------
# --- Symbols ---

# ☀ ✹ ☄ ♆ ♀ ♁ ♐ ♇ ♈ ♉ ♚ ♛ ♜ ♝ ♞ ♟ ♠ ♣ ⚢ ⚲ ⚳ ⚴ ⚥ ⚤ ⚦ ⚒ ⚑ ⚐ ♺ ♻ ♼ ☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷
# ✡ ✔ ✘ ✖ ✚ ✱ ✤ ✦ ❤ ➼ ✂ ✎ ✐ ⨀ ⨁ ⨂ ⨍ ⨎ ⨏ ⨷ ⩚ ⩛ ⩡ ⩱ ⩲ ⩵  ⩶ ⨠
# ➦ ⬅ ⬆ ⬇ ⬈ ⬉ ⬊ ⬋ ⬒ ⬓ ⬔ ⬕ ⬖ ⬗ ⬘ ⬙ ⬟ ⬤ 〒 ǀ ǁ ǂ ĭ Ť Ŧ  
# ➢ ➣ ➤ ⇒ ⇓ ⇔ ⇖ ⇗ ⇘ ⇙ ⇐ ⇑ ➩ ⇦ ⇧ ⇨ ⇩ ⇪ ➪ ➫ ➬ ➭ ➮ ➯ ➱ ➲ ➾ ➔ ➘ ➙ ➚ ➛ ➜ ➝ ➞ ➟ ➠ ➡
# ↭ ↮ ↯ ↰↱ ↲ ↳ ↴ ↵ ↶ ↷ ↸ ↹ ↺ ↻ ↼ ↽ ↾ ↿ ⇀ ⇁ ⇂ ⇃ ⇚ ⇛ ⇜ ⇝ ⇞ ⇟ ⇠ ⇡ ⇢ ⇣ ⇤ ⇥ ⇇ ⇈ ⇉ ⇊
