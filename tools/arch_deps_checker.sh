#! /usr/bin/bash

explicit=""
packages=$(pacman -Qeq)

# In windows, pacman can use directly
if [ $(uname -o) == "Msys" ]; then
	sudo=""
else
	sudo="sudo"
fi

echo -e Start calculate the depends..."\n"

for package in $packages
do
	deps=$(pactree -r $package)
	eval `echo $deps | awk -F' ' '{ print "count="NF }'`
	if [ $count -gt 1 ]; then
		echo Package name: $package
		echo Depends: $[$count-1]
		eval "pactree -r $package"
		echo ===========================================
		explicit+=" "$package
	fi
done

if [ -n "$explicit" ]; then

	echo -e "\n"Packages can be installed as depends:
	echo -e $explicit"\n"
	echo Do you want to change the install reason?

	# Show select menu
	select ch in "YES" "NO"
	do
		if [ "$ch" = "YES" ]; then
			$sudo pacman -S --asdeps $explicit
		fi
		echo
		break
	done

else
	echo -e No package can change install reason.'\n'Your depends are clean.'\n'
fi

# Check no needed package
echo -e Start calculate the packages which are no longer needed..."\n"
remove=$(pacman -Qdqtt)
if [ -n "$remove" ]; then
	echo -e Find package can be removed:"\n"$remove"\n"
	$sudo pacman -Rsnc $remove
else
	echo -e No package can be removed.'\n'Your system is clean.
fi