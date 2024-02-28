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

grep "            " "$1".cpulog | sed -e 's/.* /0x/' | ./toolchains/arm-none-eabi/bin/arm-none-eabi-addr2line -Cafip -e "$1" > "$1".trace
