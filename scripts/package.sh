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
name="runtime-$(date +%Y-%m-%d_%H.%M).zip"
toolchains/bin/7za a -Tzip "$name" \
	dependencies/recipes \
	forte/ \
	Modules/ \
	scripts/ \
	toolchains/etc \
	toolchains/*.sh \
	toolchains/*.cmd \
	toolchains/README.rst \
	README.rst \
	configurations/native-toolchain.txt \
	configurations/debug.txt \
	configurations/inc \
	configurations/test \
	Types/ \
	-xr'!*@*' \
	-xr'!.breakpoints' \
	-xr'!.ccls-cache'
