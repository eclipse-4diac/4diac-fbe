#!/bin/sh
#********************************************************************************
# Copyright (c) 2018, 2025 OFFIS e.V.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#    Jörg Walter - initial implementation
# *******************************************************************************/
#

if [ ! -d configurations ]; then
	echo "Run this in a 4diac FBE directory."
	exit 1
fi

common_clean() {
	for i in forte 4diac-forte "$(dirname "$0")"/../forte; do
		[ -d "$i.cget_lock" ] && rmdir "$i.cget_lock"
		[ -f "$i/__cget_sh_CMakeLists.txt" ] && mv "$i/__cget_sh_CMakeLists.txt" "$i/CMakeLists.txt"
	done
	rm -rf build/testroot.*
}

case "$1" in
--help)
	echo "Usage: $0 [--all|<config>|<config>/forte|--package]"
	echo
	echo "* Without arguments, cleans 4diac forte build dirs but not dependencies. This"
	echo "  should resolve build problems related to 4diac forte itself."
	echo
	echo "* With --all, clears all build files. Use this to start over from scratch."
	echo "  Before submitting a bug report, do this and test your build again."
	echo
       	echo "* With a config name, cleans build files for that config only. Append /forte"
	echo "  to leave dependencies in place and just clean 4diac forte itself."
	echo
	echo "* With --package, clears all build files and all caches. Only ever use this"
	echo "  when you want to package and upload/send the fbe directory for troubleshooting."
        echo "	This will make the next build extremely slow, triggering a full redownload!"
	exit 1
	;;
"")
	echo "Cleaning to rebuild 4diac FORTE from scratch in all existing builds..."
	echo "To also rebuild dependencies, run clean.cmd --all"
	common_clean
	rm -rf build/*/forte
	rm -rf build/*/forte.cget_lock
	rm -rf build/*/cget/build/*/
	;;
--all)
	echo "cleaning to rebuild everything from scratch..."
	common_clean
	rm -rf build compile_commands.json
	;;
--package)
	echo "Preparing for packaging..."
	common_clean
	rm -rf build
	rm -rf toolchains/.cache toolchains/download-cache
	cp toolchains/bin/sh* toolchains/etc
	toolchains/etc/sh toolchains/etc/bootstrap/clean.sh
	rm toolchains/etc/sh*
	;;
*/forte)
	echo "Cleaning to rebuild 4diac FORTE from scratch in config '$1'..."
	common_clean
	if [ -d "build/$1/../cget" ]; then
		rm -rf build/"$1" build/"$1".cget_lock
	else
		echo "$1 seems to be cleaned already"
	fi
	;;
*)
	if [ -d "$1/cget/../../../build" ]; then
		echo "Cleaning to rebuild '$1' from scratch..."
		rm -rf "$1"
	elif [ -d "build/$1/cget" ]; then
		echo "Cleaning to rebuild config '$1' from scratch..."
		rm -rf build/"$1"
	else
	        echo "$1 is not a build prefix or is cleaned already"
	fi
	;;
esac
