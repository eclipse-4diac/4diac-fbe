#!/bin/sh
#********************************************************************************
# Copyright (c) 2018, 2024 OFFIS e.V.
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

cd "$(dirname "$0")"

# After download, this script will not be in the `scripts` subdirectory. It will be distributed outside of
# the archive files.
if [ "${PWD##*/}" = "scripts" ]; then
	echo "This script is not supposed to be run in an already installed build environment" >&2
	sleep 1
	exit 1
fi

if [ ! -x compile.sh ]; then
	if [ ! -f runtime-20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9].[0-9][0-9].zip ] || \
		   [ ! -f Linux/Linux-toolchain-x86_64-linux-musl.tar.gz ]; then
		echo "" >&2
		echo "======================================================================" >&2
		echo "" >&2
		echo "ERROR: Copy all runtime files and the Linux subdirectory to an empty folder" >&2
		echo "       and run this script again." >&2
		echo "" >&2
		echo "======================================================================" >&2
		echo "" >&2
		sleep 1
		exit 1
	fi
	if [ "${PWD% *}" != "$PWD" ]; then
		# FIXME: CMake 3.27 will contain an important fix that may finally allow such install directories
		echo "" >&2
		echo "======================================================================" >&2
		echo "" >&2
		echo "ERROR: Please install this in a path without spaces in the path name." >&2
		echo "" >&2
		echo "======================================================================" >&2
		echo "" >&2
		sleep 1
		exit 1
	fi
	if ! type unzip >/dev/null 2>&1; then
		mkdir toolchains
		cd toolchains
		tar xzf ../Linux/Linux-toolchain-x86_64-linux-musl.tar.gz bin/busybox
		cd ..
		unzip() { ./toolchains/bin/busybox unzip "$@"; }
	fi
	unzip -o runtime-20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9].[0-9][0-9].zip || {
		echo "" >&2
		echo "======================================================================" >&2
		echo "" >&2
		echo "ERROR: Initial installation failed. Please check the error message above." >&2
		echo "" >&2
		echo "======================================================================" >&2
		echo "" >&2
		sleep 1
		exit 1
	}
fi
mv Linux/* toolchains/
rmdir Linux
/bin/sh ./toolchains/install-toolchain.sh
cp scripts/compile.sh .
rm install.sh
exec ./compile.sh ""
