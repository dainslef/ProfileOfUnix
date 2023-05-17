#! /usr/bin/env fish

if [ (whoami) != root ]
    set sudo sudo
end

# Check OS type and use different command.
if type -q apt

    set packages (apt-mark showmanual)
    set default_count 0
    set set_dep_cmd "apt-mark auto"

    function check_dep_cmd
        set deps_count (apt-cache rdepends --important --installed $argv[1] | wc -l)
        echo (math $deps_count - 2)
    end
else if type -q pacman

    set packages (pacman -Qeq)
    set default_count 1
    set set_dep_cmd "pacman -D --asdeps"

    if not type -q pactree then
        echo The tool \"pactree\" is not installed, please install it first:
        echo pacman -S pacman-contrib
        exit 1
    end

    function check_dep_cmd
        pactree -r $argv[1] | wc -l
    end
else
    echo Your OS is not supported!
    exit
end

echo -e Start calculate the depends..."\n"

for package in $packages
    set count (check_dep_cmd $package)
    if [ $count -gt $default_count ]
        echo Package name: $package
        echo Rdepends: (math $count - $default_count)
        echo -e "\n===========================================\n"
        set explicit $explicit $package
    end
end

if [ -n "$explicit" ]

    echo -e "\nPackages can be installed as depends:"
    echo -e "$explicit\n"

    while [ true ]
        # Show select menu.
        read -P "Do you want to change the install reason? yes/NO"\n -l selection
        if string match -q $selection yes; or string match -q $selection y
            eval "$sudo $set_dep_cmd $explicit"
        end
        echo
        break
    end
else
    echo -e "No package can change install reason.\nYour depends are clean.\n"
end

# Check no needed packages.
echo -e Start calculate the packages which are no longer needed..."\n"
if type -q apt
    eval "$sudo apt autoremove --purge"
else
    set remove (pacman -Qdqtt)
    if [ -n "$remove" ]
        echo -e "Find package can be removed:\n$remove\n"
        eval "$sudo pacman -Rsnc $remove"
    else
        echo -e "No package can be removed.\nYour system is clean."
    end
end
