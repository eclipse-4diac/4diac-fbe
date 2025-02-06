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

cd "$(dirname "$0")/.."
dirname="${PWD##*/}"
[ "$dirname" = "4diac-fbe" ] || { echo "Toplevel directory must be called '4diac-fbe'" >&2; exit 1; }
name="$dirname-$(date +%Y-%m-%d_%H.%M).zip"
cd ..
"$dirname"/toolchains/bin/7za a -Tzip "$name" \
	"$dirname"/*.md \
	"$dirname"/*.cmd \
	"$dirname"/scripts/ \
	"$dirname"/dependencies/recipes \
	"$dirname"/forte/ \
	"$dirname"/modules/ \
	"$dirname"/types/ \
	"$dirname"/toolchains/etc/install.* \
	"$dirname"/configurations/native-toolchain.txt \
	"$dirname"/configurations/debug.txt \
	"$dirname"/configurations/inc \
	"$dirname"/configurations/test \
	-xr'!.breakpoints' \
	-xr'!.ccls-cache'
