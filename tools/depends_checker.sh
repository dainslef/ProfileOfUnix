#! /bin/bash

if [ -e /etc/os-release ]; then
	sudo="sudo"
	eval `cat /etc/os-release | sed -n '1, 1p'` # Read the first line of the os-release file
elif [ `uname -o` == "Msys" ]; then # MYSY doesn't need root permission and use PACMAN package mamager
	NAME="Arch Linux"
fi

# Check OS type and use different command
if [ "$NAME" ==  "Ubuntu" ]; then
	packages=`apt-mark showmanual`
	default_count=0
	set_dep_cmd="apt-mark auto"
	check_dep_cmd() {
		local count=0
		local deps_all=`apt-cache rdepends $1 | grep -v '|'`
		for dep in $deps_all; do
			if [ `dpkg --status 2>/dev/null $dep | wc -l` -gt 0 ]; then count=$[$count+1]; fi
		done
		echo $count
	}
elif [ "$NAME" == "Arch Linux" ]; then
	packages=`pacman -Qeq`
	default_count=1
	set_dep_cmd="pacman -S --asdeps"
	check_dep_cmd() {
		pactree -r $1 | wc -l
	}
else
	echo Your OS is not supported!
	exit
fi

echo -e Start calculate the depends..."\n"

for package in $packages; do

	count=`check_dep_cmd $package`

	if [ $count -gt $default_count ]; then
		echo Package name: $package
		echo Rdepends: $[$count-$default_count]
		echo -e "\n"==========================================="\n"
		explicit+=" "$package
	fi

done

if [ -n "$explicit" ]; then

	echo -e "\n"Packages can be installed as depends:
	echo -e $explicit"\n"
	echo Do you want to change the install reason?

	# Show select menu
	select ch in "YES" "NO"; do
		if [ "$ch" == "YES" ]; then
			$sudo $set_dep_cmd $explicit
		fi
		echo
		break
	done

else
	echo -e No package can change install reason.'\n'Your depends are clean.'\n'
fi

# Check no needed package
echo -e Start calculate the packages which are no longer needed..."\n"
if [ "$NAME" == "Ubuntu" ]; then
	sudo apt autoremove --purge
else
	remove=`pacman -Qdqtt`
	if [ -n "$remove" ]; then
		echo -e Find package can be removed:"\n"$remove"\n"
		$sudo pacman -Rsnc $remove
	else
		echo -e No package can be removed.'\n'Your system is clean.
	fi
fi
