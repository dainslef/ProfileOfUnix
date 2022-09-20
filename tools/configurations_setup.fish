# Get base repo path by plantform.
if [ (uname) = Linux ]
    set HOME_PATH /home/dainslef
else if [ (uname) = Darwin ]
    set HOME_PATH /Users/dainslef
end

# Set the repo base path.
set REPO_PATH $HOME_PATH/Public/Syncthing/Work/Codes/GitRepo/ProfileOfUnix

# Git configurations
echo -n "Set up git config ... "
ln -sf $REPO_PATH/.gitconfig ~/.gitconfig
ln -sf $REPO_PATH/.gitignore ~/.gitignore
echo OK

# SSH configurations.
echo -n "Set up SSH config ... "
mkdir ~/.ssh
ln -sf $REPO_PATH/ssh_config ~/.ssh/config
echo OK

# VIM
echo -n "Set up VIM ... "
if ! [ -e ~/.vim/bundle/Vundle.vim ]
    git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
end
ln -sf $REPO_PATH/.vimrc ~/.vimrc
echo OK

# Ansible
echo -n "Set up Ansible ... "
mkdir ~/.ansible
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
    echo -n "Set up Ranger ... "
    mkdir -p ~/.config/ranger
    ln -sf $REPO_PATH/ranger/rc.conf ~/.config/ranger/rc.conf
    ln -sf $REPO_PATH/ranger/rifle.conf ~/.config/ranger/rifle.conf
    echo OK
end

# Kitty terminal
if type -q kitty
    echo -n "Set up Kitty ... "
    mkdir -p ~/.config/kitty
    ln -sf $REPO_PATH/shell/kitty.conf ~/.config/kitty/kitty.conf
    echo OK
end

if type -q btop
    echo -n "Set up Btop ... "
    mkdir -p ~/.config/btop
    ln -sf $REPO_PATH/btop.conf ~/.config/btop/btop.conf
    # Btop process will try to overwrite config, so lock file write permisson.
    chmod 400 ~/.config/btop/btop.conf
    echo OK
end

# Oh ny fish
echo -ne "Set up Fish shell ... "
if ! [ -e ~/.config/omf ] # Check if OMF has areadly downloaded.
    curl -L https://get.oh-my.fish | nohup fish >/dev/null
    source .local/share/omf/init.fish
    omf install bobthefish
end
ln -sf $REPO_PATH/shell/config.fish ~/.config/fish/config.fish
echo OK

# Check if current plantform is Linux.
if [ (uname) = Linux ]
    # Extra setup for Arch Linux.
    set os_name (grep -Po '(?<=NAME=\\")\\w+ \\w+' /etc/os-release | tail -n 1)
    if [ $os_name = "Arch Linux" ]
        echo "Current OS is Arch Linux, set up addition configuration ..."
        mkdir -p ~/.config/fontconfig
        ln -sf $REPO_PATH/xorg/fonts.xml ~/.config/fontconfig/fonts.conf # Fonts configurations.

        # Create systemd user service dir if not exist.
        mkdir -p ~/.config/systemd/user/

        ln -sf $REPO_PATH/systemd/fcitx5.service ~/.config/systemd/user/fcitx5.service
        systemctl --user enable fcitx5
        systemctl --user start fcitx5

        ln -sf $REPO_PATH/systemd/nm-applet.service ~/.config/systemd/user/nm-applet.service
        systemctl --user enable nm-applet
        systemctl --user start nm-applet

        ln -sf $REPO_PATH/systemd/picom.service ~/.config/systemd/user/picom.service
        systemctl --user enable picom
        systemctl --user start picom
    end
end
