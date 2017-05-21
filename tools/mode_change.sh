#! /bin/bash

set_file_mode() {

	for file in $2/*; do
		if [ "$file" != "." ] && [ "$file" != ".." ]; then
			if [ -f $file ]; then
				chmod $1 $file
			elif [ -d $file ]; then
				set_file_mode $1 $file
			fi
		fi
	done

	for file in $2/.*; do
		if [ "$file" != "." ] && [ "$file" != ".." ]; then
			if [ -f $file ]; then
				chmod $1 $file
			fi
		fi
	done

}

if [ $# == 0 ]; then
	echo "usage: [file_path] [file_mod]"
else
	set_file_mode $1 $2
fi
