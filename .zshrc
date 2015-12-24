# Check OS type and set the different enviorment variables.
if [ $(uname) = "Darwin" ]; then # Darwin kernel means in OS X
	export ZSH=/Users/dainslef/.oh-my-zsh # Path to your oh-my-zsh installation.
	local show_os_version="$(uname -srnm)"
	local normal_uid=500 # In OS X, the normal user's uid start with 500.
	plugins=(sudo osx brew sublime scala)
elif [ $(uname) = "Linux" ]; then
	export ZSH=/home/dainslef/.oh-my-zsh
	local show_os_version="$(uname -ornm)"
	local normal_uid=1000 # In Linux, the normal user's uid start with 1000.
	plugins=(sudo systemd scala)
fi

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(sudo systemd) # load plugins at first

source $ZSH/oh-my-zsh.sh

# User configuration

export PATH=$HOME/bin:/usr/local/bin:$PATH
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# ------------------------------------------------------------------------------
# -- theme --

# Cheak if you are root user
if [ $(whoami) != "root" ]
then
	echo $show_os_version
	echo $(date)
	echo --- Welcome, $(whoami). Try your best everyday! ---
	case $[$RANDOM % 4] in
		0) echo "--- 夢に描けることなら、実現できる。 ---\n" ;;
		1) echo "--- 一日は貴い一生である。これを空費してはならない。 ---\n" ;;
		2) echo "--- 完璧などはありえない。この世界は不完全だ。だから、美しい。 ---\n" ;;
		3) echo "--- 春は夜桜、夏には星、秋に満月、冬には雪。 ---\n" ;;
	esac
fi

# Check the UID
if [ $UID -ge $normal_uid ]; then # normal_user
	local start_status="%{$fg_bold[green]%}▶"
	local mid1_status="%{$fg_bold[yellow]%}%n"
	local mid2_status="%{$fg_bold[cyan]%}➜"
	local end2_status="%{$fg_bold[blue]%}%T"
elif [ $UID -eq 0 ]; then # root
	local start_status="%{$fg_bold[blue]%}▶"
	local mid1_status="%{$fg_bold[red]%}%n"
	local mid2_status="%{$fg_bold[yellow]%}➜"
	local end2_status="%{$fg_bold[cyan]%}%T"
fi

# Show the Command Execute Result with Different Color and Icon
local end_status="%(?:%{$fg_bold[green]%}☀:%{$fg_bold[red]%}⚡)"

PROMPT='${start_status} ${mid1_status} %{$fg[magenta]%}%2~%{$fg_bold[blue]%}$(git_prompt_info) ${mid2_status} '
RPROMPT='${end_status} ${end2_status}%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="|"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%}⬆%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[red]%}𝝙%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}⚑%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}✚"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%}✹"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✖"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%}❤"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%}♒"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}✭"

# ------------------------------------------------------------------------------
#
# List of vcs_info format strings:
#
# %b => current branch
# %a => current action (rebase/merge)
# %s => current version control system
# %r => name of the root directory of the repository
# %S => current path relative to the repository root directory
# %m => in case of Git, show information about stashes
# %u => show unstaged changes in the repository
# %c => show staged changes in the repository
#
# List of prompt format strings:
#
# prompt:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)
#
# ------------------------------------------------------------------------------

# More symbols to choose from:
# ☀ ✹ ☄ ♆ ♀ ♁ ♐ ♇ ♈ ♉ ♚ ♛ ♜ ♝ ♞ ♟ ♠ ♣ ⚢ ⚲ ⚳ ⚴ ⚥ ⚤ ⚦ ⚒ ⚑ ⚐ ♺ ♻ ♼ ☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷
# ✡ ✔ ✖ ✚ ✱ ✤ ✦ ❤ ➜ ➟ ➼ ✂ ✎ ✐ ⨀ ⨁ ⨂ ⨍ ⨎ ⨏ ⨷ ⩚ ⩛ ⩡ ⩱ ⩲ ⩵  ⩶ ⨠ 
# ➦ ⬅ ⬆ ⬇ ⬈ ⬉ ⬊ ⬋ ⬒ ⬓ ⬔ ⬕ ⬖ ⬗ ⬘ ⬙ ⬟  ⬤ 〒 ǀ ǁ ǂ ĭ Ť Ŧ  
