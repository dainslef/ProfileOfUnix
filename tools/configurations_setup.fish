# Get base repo path by plantform
if [ (uname) = Linux ]
    set HOME_PATH /home/dainslef
else if [ (uname) = Darwin ]
    set HOME_PATH /Users/dainslef
end

# Set repo path
set REPO_PATH $HOME_PATH/Public/Syncthing/Work/Codes/GitRepo/ProfileOfUnix

# Git configurations
echo -n "Set up git config ... "
ln -sf $REPO_PATH/.gitconfig ~/.gitconfig
ln -sf $REPO_PATH/.gitignore ~/.gitignore
echo OK

# Fish
echo -ne "Set up Fish shell ... "
if ! [ -e ~/.config/omf ] # Check if OMF has areadly downloaded.
    curl -L https://get.oh-my.fish | fish
end
omf install bobthefish
ln -sf $REPO_PATH/shell/config.fish ~/.config/fish/config.fish
echo OK

# VIM
echo -n "Set up VIM ... "
if ! [ -e ~/.vim/bundle/Vundle.vim ]
    git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
end
ln -sf $REPO_PATH/editor/.vimrc ~/.vimrc
echo OK

# Ansible
echo -n "Set up Ansible ... "
if ! [ -e ~/.ansible/hosts ]
    cp $REPO_PATH/ansible/hosts ~/.ansible/hosts
end
ln -sf $REPO_PATH/ansible/ansible.cfg ~/.ansible.cfg
echo OK

# Window Manager
if type -q qtile
    # Link the Qtile configuration.
    echo -n "Set up Qtile ... "
    mkdir -p ~/.config/qtile
    ln -sf $REPO_PATH/window_manager/qtile/config.py ~/.config/qtile/config.py
    echo OK

    # Link the Dunst configuration.
    echo -n "Set up Dunst ... "
    mkdir -p ~/.config/dunst
    ln -sf $REPO_PATH/dunstrc ~/.config/dunst/dunstrc
    echo OK
end
if type -q awesome
    echo -n "Set up AwesomeWM ... "
    mkdir -p ~/.config/awesome
    ln -sf $REPO_PATH/window_manager/awesome/rc.lua ~/.config/awesome/rc.lua
    echo OK
end

# Link the theme configuration manually only if use Window Manager
if type -q qtile || type -q awesome
    # GTK theme
    echo -ne "Set up GTK theme ... "
    mkdir -p ~/.config/gtk-3.0
    ln -sf $REPO_PATH/theme/settings.ini ~/.config/gtk-3.0/settings.ini
    ln -sf $REPO_PATH/theme/.gtkrc-2.0 ~/.gtkrc-2.0
    echo OK

    # Cursor theme
    echo -n "Set up Cursor theme ... "
    mkdir -p ~/.icons/default
    ln -sf $REPO_PATH/theme/index.theme ~/.icons/default/index.theme
    echo OK
end

# File manager
if type -q ranger
    echo -n "Set up ranger ... "
    mkdir -p ~/.config/ranger
    ln -sf $REPO_PATH/ranger/rc.conf ~/.config/ranger/rc.conf
    echo OK
end
